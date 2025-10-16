# Hysteria - Pentest Menu 

A safe, beginner-friendly Bash menu that shows examples of common pentest tasks (network scanning, web testing, fuzzing, payload templates, exploitation handlers). This repository is for educational purposes — do **not** run intrusive commands without explicit written authorization.

## Quickstart
```bash
git clone https://github.com/Hysteria127/hysteria-hub.git
cd hysteria-hub
chmod +x hysteria-hub.sh
./hysteria-hub.sh


🧠 Troubleshooting
If you see this error when trying to run the script:

./hysteria-hub.sh
env: ‘bash\r’: No such file or directory
-----------------------------------------
It means your script file has Windows-style (CRLF) line endings instead of Unix-style (LF).
Linux and macOS expect LF line endings — when the script is saved with CRLF,
the shebang line (#!/usr/bin/env bash) breaks, and the system looks for an interpreter called bash\r (with a hidden carriage return), which doesn’t exist.
----------------
How to Fix It:
sed -i 's/\r$//' hysteria-hub.sh
chmod +x hysteria-hub.sh

Then run it again:
./hysteria-hub.sh
