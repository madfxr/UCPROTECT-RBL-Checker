#!/bin/bash

# RBL List
BLISTS="
dnsbl-0.uceprotect.net
dnsbl-1.uceprotect.net
dnsbl-2.uceprotect.net
dnsbl-3.uceprotect.net
"

ERROR() {
  echo "$0 ERROR: $1" >&2
  exit 2
}

clear
echo -e "
█    ██  ▄████▄   ██▓███   ██▀███   ▒█████  ▄▄▄█████▓▓█████  ▄████▄  ▄▄▄█████▓
 ██  ▓██▒▒██▀ ▀█  ▓██░  ██▒▓██ ▒ ██▒▒██▒  ██▒▓  ██▒ ▓▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒
▓██  ▒██░▒▓█    ▄ ▓██░ ██▓▒▓██ ░▄█ ▒▒██░  ██▒▒ ▓██░ ▒░▒███   ▒▓█    ▄ ▒ ▓██░ ▒░
▓▓█  ░██░▒▓▓▄ ▄██▒▒██▄█▓▒ ▒▒██▀▀█▄  ▒██   ██░░ ▓██▓ ░ ▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░
▒▒█████▓ ▒ ▓███▀ ░▒██▒ ░  ░░██▓ ▒██▒░ ████▓▒░  ▒██▒ ░ ░▒████▒▒ ▓███▀ ░  ▒██▒ ░
░▒▓▒ ▒ ▒ ░ ░▒ ▒  ░▒▓▒░ ░  ░░ ▒▓ ░▒▓░░ ▒░▒░▒░   ▒ ░░   ░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░
░░▒░ ░ ░   ░  ▒   ░▒ ░       ░▒ ░ ▒░  ░ ▒ ▒░     ░     ░ ░  ░  ░  ▒       ░
 ░░░ ░ ░ ░        ░░         ░░   ░ ░ ░ ░ ▒    ░         ░   ░          ░
   ░     ░ ░                  ░         ░ ░              ░  ░░ ░
         ░                                                   ░
               - UCPROTECT Realtime Blackhole List Checker V1 -
"

read -p "Enter the IP Address or Subnet in CIDR (e.g.: 1.2.3.4 or 1.2.3.0,1.2.3.1 or 1.2.3.0/24): " INPUT_LIST
[ -z "$INPUT_LIST" ] && ERROR "No Input Provided."

# Setup Safe File Names
SAFE_NAME="${INPUT_LIST//[\/,]/-}"
OUTPUT_TXT="RBL-Output-${SAFE_NAME}.txt"
OUTPUT_JSON="RBL-Output-${SAFE_NAME}.json"

total_checked=0
total_listed=0
json_results="["

# Prepare Output File
echo "" | tee "$OUTPUT_TXT"
echo "Checking for: $INPUT_LIST" | tee -a "$OUTPUT_TXT"
echo "Started at: $(date)" | tee -a "$OUTPUT_TXT"
echo "" | tee -a "$OUTPUT_TXT"

# Loop Through Each IP Address/Subnet
IFS=',' read -ra ADDRS <<< "$INPUT_LIST"
for entry in "${ADDRS[@]}"; do
  if [[ "$entry" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    subnet_list="$entry"
  else
    subnet_list=$(prips "$entry" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$subnet_list" ]; then
      echo "Skipping Invalid Input: $entry" | tee -a "$OUTPUT_TXT"
      continue
    fi
  fi

  for ip in $subnet_list; do
    total_checked=$((total_checked + 1))
    is_listed_ip=0

    reverse=$(echo "$ip" | sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")
    [ -z "$reverse" ] && echo "Invalid IP Address: $ip" | tee -a "$OUTPUT_TXT" && continue

    ptr=$(dig +short -x "$ip")
    echo -e "\nIP Address: $ip | PTR: ${ptr:----}" | tee -a "$OUTPUT_TXT"

    json_ip="{\"ip\":\"$ip\",\"ptr\":\"${ptr:----}\",\"listed\":["
    first_list=1

    for BL in $BLISTS; do
      query="${reverse}.${BL}."
      listed=$(dig +short -t txt "$query")
      printf "  %-45s: " "$query" | tee -a "$OUTPUT_TXT"
      echo "${listed:----}" | tee -a "$OUTPUT_TXT"

      if [ -n "$listed" ]; then
        is_listed_ip=1
        esc_listed=$(echo "$listed" | sed 's/"/\\"/g')
        [ $first_list -eq 0 ] && json_ip+=","
        json_ip+="{\"rbl\":\"$BL\",\"txt\":\"$esc_listed\"}"
        first_list=0
      fi
    done

    json_ip+="]}"
    [ $total_checked -gt 1 ] && json_results+=","
    json_results+="$json_ip"

    [ "$is_listed_ip" -eq 1 ] && total_listed=$((total_listed + 1))
  done
done

echo -e "\nTotal IP Addresses Checked: $total_checked" | tee -a "$OUTPUT_TXT"
echo "Total IP Addresses Listed: $total_listed" | tee -a "$OUTPUT_TXT"
echo "Finished at: $(date)" | tee -a "$OUTPUT_TXT"

json_results+="]"

json_summary=$(cat <<EOF
{
  "input": "$INPUT_LIST",
  "total_checked": $total_checked,
  "total_listed": $total_listed,
  "checked_at": "$(date)"
}
EOF
)

echo "{
  \"results\": $json_results,
  \"summary\": $json_summary
}" > "$OUTPUT_JSON"

echo -e "\nOutput Saved:"
echo "  ➜ Text: $OUTPUT_TXT"
echo "  ➜ JSON: $OUTPUT_JSON"
