# UCPROTECT Realtime Blackhole List Checker V1 for BGN Internal

## Requirements
- Prips.
- Bash.
- Wget.

## Installation
- Make sure to installed Prips first by running the command ``apt install prips -y``.
- Make sure to download and place the tool in the ``/usr/bin`` directory.
- Download the tool source code by running the command: ``sudo wget https://raw.githubusercontent.com/madfxr/UCPROTECT-RBL-Checker/refs/heads/main/UCPROTECT-RBL-Checker``.
- Grant access rights to the ``/usr/bin/UCPROTECT-RBL-Checker`` file by running the command: ``sudo chmod +x /usr/bin/UCPROTECT-RBL-Checker``.
- To run the tool use the command ``UCPROTECT-RBL-Checker``.

## Notes
- UCPROTECT-RBL-Checker is still tried on Ubuntu 22.04.5 LTS x86-64 only.
- If you want to customize this tool for other RBLs, you can make changes to the sections:
  ```
BLISTS="
dnsbl-0.uceprotect.net
dnsbl-1.uceprotect.net
dnsbl-2.uceprotect.net
dnsbl-3.uceprotect.net
"
  ```

## References
- MultiRBL: https://multirbl.valli.org/list.
- MxToolbox Blacklist: https://github.com/heximcz/mxtoolbox-blacklists/blob/master/blacklistsAlive.txt.
