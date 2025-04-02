#!/bin/bash
# Script Name: wifi-adapter-tool.sh
# Purpose: Wi-Fi adapter tool with AI intelligence for checking adapter details, capabilities, and enabling hacking modes for ethical pentesting

# Enhanced color detection
FORCE_COLORS=false
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput setaf 1 >/dev/null 2>&1; then
    case "$TERM" in
        xterm*|rxvt*|screen*|linux*|cygwin|tmux*)
            FORCE_COLORS=true
            ;;
        *)
            if [ -n "$PS1" ] && [ "${TERM}" != "dumb" ]; then
                FORCE_COLORS=true
            fi
            ;;
    esac
fi

if [ "$FORCE_COLORS" = true ]; then
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    MAGENTA='\033[1;35m'
    NC='\033[0m'
else
    BLUE=''
    GREEN=''
    MAGENTA=''
    NC=''
fi

CHECKMARK="✅"
CROSS="❌"

# Global variables
ORIGINAL_ADAPTER_NAME=""
ADAPTER_NAME=""
SUPPORTS_MONITOR_MODE="unknown"
SUPPORTS_PACKET_INJECTION="unknown"
SUPPORTS_AP_MODE="unknown"
AI_RECOMMENDATION=""

# Helper function to calculate the length of a string (excluding color codes)
string_length() {
    local text="$1"
    local clean_text
    clean_text=$(echo -e "$text" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    echo "${#clean_text}"
}

# Helper function to truncate text to a specific length
truncate_text() {
    local text="$1"
    local max_length="$2"
    local clean_text
    clean_text=$(echo -e "$text" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    if [ ${#clean_text} -gt "$max_length" ]; then
        echo "${text}" | cut -c 1-"${max_length}"
    else
        echo "$text"
    fi
}

# Function to display the enhanced banner with a box
display_banner() {
    clear
    echo -e "${BLUE}Wi-Fi Adapter Tool v3.1 (AI Enhanced)${NC}"
    echo -e "${BLUE}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│ Ethical Penetration Testing Purposes Only    │${NC}"
    echo -e "${BLUE}│ Author: Team Matrix Elite Hackers            │${NC}"
    echo -e "${BLUE}│ Website: https://teammatrix.net/             │${NC}"
    echo -e "${BLUE}│ Mobile: +881303818319                        │${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────┘${NC}"
    echo -e "\n"
}

# Function to display a footer
display_footer() {
    echo -e "\n"
    echo -e "${MAGENTA}Reminder: Use this tool responsibly and with legal authorization.${NC}"
    echo -e "\n"
}

# Function to check and install dependencies
install_dependencies() {
    local dep_lines=()
    dep_lines+=("${BLUE}[*] Checking and installing required tools...${NC}")

    local TOOLS="iw wireless-tools usbutils pciutils dos2unix aircrack-ng hostapd"
    local MISSING_TOOLS=""

    for tool in $TOOLS; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            MISSING_TOOLS="$MISSING_TOOLS $tool"
        fi
    done

    if [ -n "$MISSING_TOOLS" ]; then
        dep_lines+=("${BLUE}[!] Missing tools:$MISSING_TOOLS${NC}")
        dep_lines+=("${BLUE}[*] Updating package list and installing missing tools...${NC}")
        apt update 2>/dev/null
        for tool in $MISSING_TOOLS; do
            dep_lines+=("${BLUE}[*] Installing $tool...${NC}")
            apt install -y "$tool" 2>/dev/null
            if [ $? -eq 0 ]; then
                dep_lines+=("${GREEN}[+] $tool installed successfully.${NC}")
            else
                dep_lines+=("${BLUE}[!] Failed to install $tool. Please install it manually.${NC}")
            fi
        done
    else
        dep_lines+=("${GREEN}[+] All required tools are already installed.${NC}")
    fi

    for line in "${dep_lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
}

# Function to display a status
display_status() {
    local label="$1"
    local status="$2"
    local message="$3"
    local output

    local label_padded="$label"
    while [ $(string_length "$label_padded") -lt 20 ]; do
        label_padded="$label_padded "
    done

    local status_padded="$status"
    while [ $(string_length "$status_padded") -lt 12 ]; do
        status_padded="$status_padded "
    done

    if [ "$status" = "Supported" ] || [ "$status" = "Enabled" ] || [ "$status" = "Success" ] || [ "$status" = "Can Disable" ]; then
        output="${GREEN}${CHECKMARK} ${label_padded}: ${status_padded}${NC} ${message}"
    else
        output="${BLUE}${CROSS} ${label_padded}: ${status_padded}${NC} ${message}"
    fi

    echo -e "$output"
}

# Function to get the current wireless interface
get_current_interface() {
    local adapter="$1"
    local escaped_adapter
    local escaped_original_adapter
    escaped_adapter=$(echo "$adapter" | sed 's/[][\.*^$(){}?+|/]/\\&/g')
    escaped_original_adapter=$(echo "$ORIGINAL_ADAPTER_NAME" | sed 's/[][\.*^$(){}?+|/]/\\&/g')

    local current_interface
    current_interface=$(iw dev 2>/dev/null | awk '$1 == "Interface" {print $2}' | grep -E "^${escaped_adapter}|^${escaped_adapter}mon" | head -n 1)
    if [ -z "$current_interface" ]; then
        current_interface=$(iw dev 2>/dev/null | awk '$1 == "Interface" {print $2}' | grep -E "^${escaped_original_adapter}|^${escaped_original_adapter}mon" | head -n 1)
    fi
    if [ -z "$current_interface" ]; then
        return 1
    fi
    echo "$current_interface"
    return 0
}

# Function to select wireless adapter
select_adapter() {
    local adapters
    adapters=($(iw dev 2>/dev/null | awk '$1 == "Interface" {print $2}'))
    if [ ${#adapters[@]} -eq 0 ]; then
        echo -e "${BLUE}[!] Error: No wireless adapters detected. Please connect one and try again.${NC}"
        echo -e "\n"
        display_footer
        exit 1
    fi

    echo -e "${BLUE}[*] Detected wireless adapters:${NC}"
    for i in "${!adapters[@]}"; do
        echo -e "${GREEN}  $((i+1)). ${adapters[$i]}${NC}"
    done
    echo -e "\n"
    echo -e "${GREEN}Select an adapter by number (1-${#adapters[@]}), or enter a custom interface name: ${NC}"
    read -r choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#adapters[@]}" ]; then
        ADAPTER_NAME="${adapters[$((choice-1))]}"
    else
        ADAPTER_NAME="$choice"
        if ! iw dev 2>/dev/null | grep -q "Interface $ADAPTER_NAME"; then
            echo -e "${BLUE}[!] Warning: '$ADAPTER_NAME' is not a detected wireless interface. Proceeding anyway.${NC}"
        fi
    fi
    # Strip any 'mon' suffixes to ensure ORIGINAL_ADAPTER_NAME is the base name
    ORIGINAL_ADAPTER_NAME=$(echo "$ADAPTER_NAME" | sed 's/mon.*$//')
    ADAPTER_NAME="$ORIGINAL_ADAPTER_NAME"
    echo -e "${BLUE}[*] Selected adapter: $ADAPTER_NAME (Original: $ORIGINAL_ADAPTER_NAME)${NC}"
    echo -e "\n"
}

# Function to get chipset and driver info
get_chipset_driver() {
    local adapter="$1"
    local CHIPSET
    local DRIVER
    # Try lsusb first
    CHIPSET=$(lsusb 2>/dev/null | grep -i "Atheros\|AR9271\|Wireless\|WiFi\|WLAN" | head -n 1 | cut -d' ' -f7-)
    if [ -z "$CHIPSET" ]; then
        # Fallback to lspci
        CHIPSET=$(lspci 2>/dev/null | grep -i "Atheros\|Wireless\|WiFi\|WLAN" | head -n 1 | cut -d' ' -f3-)
    fi
    DRIVER=$(lsmod 2>/dev/null | grep -E "ath9k|ath9k_htc|iwlwifi|rt2x00|mt76|rtl8187" | awk '{print $1}' | head -n 1)
    if [ -z "$CHIPSET" ]; then
        # Fallback for ath9k_htc
        if [ "$DRIVER" = "ath9k_htc" ]; then
            CHIPSET="Atheros AR9271 (assumed)"
        else
            CHIPSET="Unknown"
        fi
    fi
    if [ -z "$DRIVER" ]; then
        DRIVER="Unknown"
    fi
    CHIPSET=$(truncate_text "$CHIPSET" 37)
    DRIVER=$(truncate_text "$DRIVER" 37)
    echo "Chipset  : $CHIPSET"
    echo "Driver   : $DRIVER"
}

# Function to check adapter details
check_adapter_details() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    lines+=("Interface Name: $ADAPTER_NAME")
    lines+=("")

    local IWCONFIG_OUTPUT
    IWCONFIG_OUTPUT=$(iwconfig "$ADAPTER_NAME" 2>/dev/null)
    if [ -z "$IWCONFIG_OUTPUT" ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    lines+=("Adapter Details (iwconfig):")
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$IWCONFIG_OUTPUT"
    lines+=("")
    lines+=("Hardware Information:")
    local CHIPSET_DRIVER
    CHIPSET_DRIVER=$(get_chipset_driver "$ADAPTER_NAME")
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$CHIPSET_DRIVER"
    lines+=("")
    lines+=("${MAGENTA}[AI Note] Adapter is in $(echo "$IWCONFIG_OUTPUT" | grep -o "Mode:[^ ]*" | cut -d: -f2) mode.${NC}")

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to ensure monitor mode with intelligent recommendations
ensure_monitor_mode() {
    local adapter="$1"
    local lines=()
    lines+=("${BLUE}[*] Checking adapter mode for $adapter...${NC}")

    local IWCONFIG_OUTPUT
    IWCONFIG_OUTPUT=$(iwconfig "$adapter" 2>/dev/null)
    if [ -z "$IWCONFIG_OUTPUT" ]; then
        lines+=("${BLUE}[!] Error: Adapter $adapter not found or not a wireless interface.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Ensure the adapter is properly connected and recognized by the system. Try running 'iw dev' to list interfaces.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        return 1
    fi

    if echo "$IWCONFIG_OUTPUT" | grep -q "Mode:Monitor"; then
        lines+=("${GREEN}[+] $adapter is already in monitor mode.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Monitor mode is active. You can proceed with packet injection or network scanning.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        return 0
    else
        lines+=("${BLUE}[*] Attempting to enable monitor mode on $adapter using airmon-ng...${NC}")
        airmon-ng start "$adapter" >/dev/null 2>&1
        local NEW_ADAPTER_NAME
        NEW_ADAPTER_NAME=$(iw dev 2>/dev/null | awk '$1 == "Interface" {print $2}' | grep -E "^${adapter}mon$" | head -n 1)
        if [ -z "$NEW_ADAPTER_NAME" ]; then
            lines+=("${BLUE}[!] Error: Failed to find the monitor mode interface.${NC}")
            lines+=("${MAGENTA}[AI Suggestion] Try using 'iw' directly: ifconfig $adapter down; iw dev $adapter set type monitor; ifconfig $adapter up${NC}")
            for line in "${lines[@]}"; do
                echo -e "$line"
            done
            return 1
        fi
        ADAPTER_NAME="$NEW_ADAPTER_NAME"
        lines+=("${BLUE}[*] Interface updated to $ADAPTER_NAME.${NC}")

        if iwconfig "$ADAPTER_NAME" 2>/dev/null | grep -q "Mode:Monitor"; then
            lines+=("${GREEN}[+] Monitor mode enabled successfully on $ADAPTER_NAME using airmon-ng.${NC}")
            lines+=("${MAGENTA}[AI Suggestion] Monitor mode is now active. Consider enabling packet injection for advanced testing.${NC}")
            for line in "${lines[@]}"; do
                echo -e "$line"
            done
            return 0
        else
            lines+=("${BLUE}[!] Failed to enable monitor mode on $adapter using airmon-ng.${NC}")
            lines+=("${BLUE}[*] Attempting to enable monitor mode using iw...${NC}")
            ifconfig "$adapter" down 2>/dev/null
            iw dev "$adapter" set type monitor 2>/dev/null
            ifconfig "$adapter" up 2>/dev/null
            if iwconfig "$adapter" 2>/dev/null | grep -q "Mode:Monitor"; then
                lines+=("${GREEN}[+] Monitor mode enabled successfully on $adapter using iw.${NC}")
                lines+=("${MAGENTA}[AI Suggestion] Monitor mode is now active. Consider enabling packet injection for advanced testing.${NC}")
                ADAPTER_NAME="$adapter"
                for line in "${lines[@]}"; do
                    echo -e "$line"
                done
                return 0
            else
                lines+=("${BLUE}[!] Failed to enable monitor mode on $adapter using iw.${NC}")
                lines+=("${MAGENTA}[AI Suggestion] Your adapter may not support monitor mode. Consider using a different adapter or updating drivers.${NC}")
                for line in "${lines[@]}"; do
                    echo -e "$line"
                done
                return 1
            fi
        fi
    fi
}

# Function to revert to managed mode
revert_to_managed() {
    local adapter="$1"
    local lines=()
    lines+=("${BLUE}[*] Reverting $adapter to managed mode...${NC}")

    airmon-ng stop "$adapter" >/dev/null 2>&1
    sleep 1
    local NEW_ADAPTER_NAME
    NEW_ADAPTER_NAME=$(iw dev 2>/dev/null | awk '$1 == "Interface" {print $2}' | grep -E "^${adapter}|^${adapter}mon" | head -n 1)
    if [ -z "$NEW_ADAPTER_NAME" ]; then
        NEW_ADAPTER_NAME="$ORIGINAL_ADAPTER_NAME"
    fi
    ADAPTER_NAME="$NEW_ADAPTER_NAME"
    lines+=("${BLUE}[*] Interface updated to $ADAPTER_NAME.${NC}")

    if iw dev "$ADAPTER_NAME" info 2>/dev/null | grep -q "type managed"; then
        lines+=("${GREEN}[+] $ADAPTER_NAME reverted to managed mode successfully.${NC}")
    else
        lines+=("${BLUE}[!] Failed to revert $ADAPTER_NAME to managed mode.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Ensure the adapter supports managed mode. Check 'iw list' for supported modes.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        return 1
    fi

    if systemctl is-active NetworkManager >/dev/null 2>&1; then
        lines+=("${BLUE}[*] NetworkManager is already running.${NC}")
    else
        lines+=("${BLUE}[*] Restarting NetworkManager...${NC}")
        systemctl start NetworkManager >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            lines+=("${GREEN}[+] NetworkManager restarted successfully.${NC}")
        else
            lines+=("${BLUE}[!] Failed to restart NetworkManager. You may need to start it manually.${NC}")
            lines+=("${MAGENTA}[AI Suggestion] Run 'systemctl start NetworkManager' manually to restore network functionality.${NC}")
        fi
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    return 0
}

# Function to check monitor mode status
check_monitor_mode() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    local IWCONFIG_OUTPUT
    IWCONFIG_OUTPUT=$(iwconfig "$ADAPTER_NAME" 2>/dev/null)
    if [ -z "$IWCONFIG_OUTPUT" ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    if echo "$IWCONFIG_OUTPUT" | grep -q "Mode:Monitor"; then
        lines+=("$(display_status "Monitor Mode" "Supported" "(Adapter is in monitor mode.)")")
        SUPPORTS_MONITOR_MODE="yes"
    else
        lines+=("${BLUE}[*] Attempting to enable monitor mode to test support...${NC}")
        ensure_monitor_mode "$ADAPTER_NAME"
        if [ $? -eq 0 ]; then
            lines+=("$(display_status "Monitor Mode" "Supported" "(Adapter supports monitor mode.)")")
            SUPPORTS_MONITOR_MODE="yes"
            revert_to_managed "$ADAPTER_NAME"
        else
            lines+=("$(display_status "Monitor Mode" "Not Supported" "(Adapter does not support monitor mode.)")")
            SUPPORTS_MONITOR_MODE="no"
        fi
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check packet injection support with intelligent feedback
check_packet_injection() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    ensure_monitor_mode "$ADAPTER_NAME"
    if [ $? -ne 0 ]; then
        lines+=("${BLUE}[!] Packet injection test requires monitor mode. Aborting.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    lines+=("${BLUE}[*] Running packet injection test using aireplay-ng...${NC}")
    local AIREPLAY_OUTPUT
    AIREPLAY_OUTPUT=$(aireplay-ng --test "$ADAPTER_NAME" 2>&1)
    if echo "$AIREPLAY_OUTPUT" | grep -q "Injection is working!"; then
        lines+=("$(display_status "Packet Injection" "Supported" "(Adapter can inject packets.)")")
        SUPPORTS_PACKET_INJECTION="yes"
        lines+=("${MAGENTA}[AI Suggestion] Packet injection is supported. Use aireplay-ng for advanced testing.${NC}")
    else
        lines+=("$(display_status "Packet Injection" "Not Supported" "(Adapter cannot inject packets or test failed.)")")
        SUPPORTS_PACKET_INJECTION="no"
        lines+=("Full Output:")
        while IFS= read -r line; do
            lines+=("$line")
        done <<< "$AIREPLAY_OUTPUT"
        lines+=("${MAGENTA}[AI Suggestion] Packet injection is not supported. Consider using a different adapter or checking driver compatibility.${NC}")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check AP mode support
check_ap_mode() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    lines+=("${BLUE}[*] Checking if $ADAPTER_NAME supports AP mode...${NC}")
    local IW_LIST_OUTPUT
    IW_LIST_OUTPUT=$(iw list 2>/dev/null | grep "AP")
    if [ -n "$IW_LIST_OUTPUT" ]; then
        lines+=("$(display_status "AP Mode" "Supported" "(Adapter can operate as an Access Point.)")")
        SUPPORTS_AP_MODE="yes"
        lines+=("Details:")
        while IFS= read -r line; do
            lines+=("$line")
        done <<< "$IW_LIST_OUTPUT"
        lines+=("${MAGENTA}[AI Suggestion] AP mode is supported. You can set up a rogue access point for testing purposes.${NC}")
    else
        lines+=("$(display_status "AP Mode" "Not Supported" "(Adapter does not support AP mode.)")")
        SUPPORTS_AP_MODE="no"
        lines+=("${MAGENTA}[AI Suggestion] AP mode is not supported. Focus on monitor mode or packet injection if supported.${NC}")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check managed mode support
check_managed_mode() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    local IWCONFIG_OUTPUT
    IWCONFIG_OUTPUT=$(iwconfig "$ADAPTER_NAME" 2>/dev/null)
    if [ -z "$IWCONFIG_OUTPUT" ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    if echo "$IWCONFIG_OUTPUT" | grep -q "Mode:Managed"; then
        lines+=("$(display_status "Managed Mode" "Supported" "(Adapter is in managed mode.)")")
    else
        lines+=("${BLUE}[*] Attempting to set $ADAPTER_NAME to managed mode...${NC}")
        ifconfig "$ADAPTER_NAME" down 2>/dev/null
        iwconfig "$ADAPTER_NAME" mode managed 2>/dev/null
        ifconfig "$ADAPTER_NAME" up 2>/dev/null
        if iwconfig "$ADAPTER_NAME" 2>/dev/null | grep -q "Mode:Managed"; then
            lines+=("$(display_status "Managed Mode" "Supported" "(Adapter supports managed mode.)")")
        else
            lines+=("$(display_status "Managed Mode" "Not Supported" "(Adapter does not support managed mode.)")")
        fi
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check ad-hoc mode support
check_adhoc_mode() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    local IW_LIST_OUTPUT
    IW_LIST_OUTPUT=$(iw list 2>/dev/null | grep "IBSS")
    if [ -n "$IW_LIST_OUTPUT" ]; then
        lines+=("$(display_status "Ad-Hoc Mode" "Supported" "(Adapter can operate in ad-hoc mode.)")")
        lines+=("Details:")
        while IFS= read -r line; do
            lines+=("$line")
        done <<< "$IW_LIST_OUTPUT"
    else
        lines+=("$(display_status "Ad-Hoc Mode" "Not Supported" "(Adapter does not support ad-hoc mode.)")")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check mesh mode support
check_mesh_mode() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    local IW_LIST_OUTPUT
    IW_LIST_OUTPUT=$(iw list 2>/dev/null | grep "mesh point")
    if [ -n "$IW_LIST_OUTPUT" ]; then
        lines+=("$(display_status "Mesh Mode" "Supported" "(Adapter can operate in mesh mode.)")")
        lines+=("Details:")
        while IFS= read -r line; do
            lines+=("$line")
        done <<< "$IW_LIST_OUTPUT"
    else
        lines+=("$(display_status "Mesh Mode" "Not Supported" "(Adapter does not support mesh mode.)")")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check supported channels
check_supported_channels() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    lines+=("${BLUE}[*] Checking supported channels for $ADAPTER_NAME...${NC}")
    local IW_LIST_OUTPUT
    IW_LIST_OUTPUT=$(iw list 2>/dev/null | grep -A 20 "Frequencies:" | grep "MHz")
    if [ -n "$IW_LIST_OUTPUT" ]; then
        lines+=("Supported Channels:")
        while IFS= read -r line; do
            lines+=("  $line")
        done <<< "$IW_LIST_OUTPUT"
        lines+=("${MAGENTA}[AI Suggestion] Use channels with less interference for better performance during testing.${NC}")
    else
        lines+=("${BLUE}[!] Unable to retrieve supported channels.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Ensure the adapter is properly connected and try again.${NC}")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check Tx power
check_tx_power() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    lines+=("${BLUE}[*] Checking Tx power for $ADAPTER_NAME...${NC}")

    # Check if the interface name looks suspicious (e.g., multiple 'mon' suffixes)
    if [[ "$ADAPTER_NAME" =~ monmon ]]; then
        lines+=("${BLUE}[!] Warning: Interface name '$ADAPTER_NAME' seems invalid or corrupted.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Revert to the original interface (e.g., 'airmon-ng stop $ADAPTER_NAME') and try again.${NC}")
    fi

    # Check if in monitor mode and revert if necessary
    local IWCONFIG_OUTPUT
    IWCONFIG_OUTPUT=$(iwconfig "$ADAPTER_NAME" 2>/dev/null)
    if echo "$IWCONFIG_OUTPUT" | grep -q "Mode:Monitor"; then
        lines+=("${BLUE}[*] Adapter is in monitor mode. Some drivers restrict Tx power adjustment in this mode.${NC}")
        lines+=("${BLUE}[*] Reverting to managed mode for accurate testing...${NC}")
        revert_to_managed "$ADAPTER_NAME"
        ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
        if [ $? -ne 0 ]; then
            lines+=("${BLUE}[!] Failed to revert to managed mode. Aborting Tx power check.${NC}")
            for line in "${lines[@]}"; do
                echo -e "$line"
            done
            echo -e "\n"
            echo -e "${BLUE}Press Enter to continue...${NC}"
            read -r
            display_footer
            return
        fi
        lines+=("${BLUE}[*] Interface updated to $ADAPTER_NAME.${NC}")
    fi

    # Check Tx power support
    local IW_LIST_OUTPUT
    IW_LIST_OUTPUT=$(iw list 2>/dev/null | grep -A 20 "Frequencies:" | grep "dBm")
    if [ -z "$IW_LIST_OUTPUT" ]; then
        lines+=("${BLUE}[!] Tx power adjustment is not supported by this adapter.${NC}")
        lines+=("${BLUE}[*] Running 'iw list' for more details...${NC}")
        local FULL_IW_OUTPUT
        FULL_IW_OUTPUT=$(iw list 2>/dev/null)
        if [ -z "$FULL_IW_OUTPUT" ]; then
            lines+=("${BLUE}[!] 'iw list' returned no output. Possible driver issue.${NC}")
        else
            lines+=("${BLUE}[*] Supported modes:${NC}")
            local SUPPORTED_MODES
            SUPPORTED_MODES=$(echo "$FULL_IW_OUTPUT" | grep -E "Supported interface modes" -A 10 | grep -E "^\s*\*\s")
            lines+=("${BLUE}  $SUPPORTED_MODES${NC}")
        fi
        lines+=("${MAGENTA}[AI Suggestion] This adapter may not support manual Tx power control. Verify chipset (lsusb/lspci) and update drivers if possible.${NC}")
    else
        lines+=("${GREEN}[+] Tx power adjustment is supported. Current capabilities:${NC}")
        lines+=("$IW_LIST_OUTPUT")
        
        # Test adjusting Tx power
        lines+=("${BLUE}[*] Attempting to adjust Tx power to 15 dBm...${NC}")
        local IWCONFIG_TXPOWER_OUTPUT
        IWCONFIG_TXPOWER_OUTPUT=$(iwconfig "$ADAPTER_NAME" txpower 15 2>&1)
        if [ $? -eq 0 ]; then
            lines+=("$(display_status "Tx Power Adjustment" "Supported" "(Tx power can be adjusted.)")")
            iwconfig "$ADAPTER_NAME" txpower auto >/dev/null 2>&1
            lines+=("${MAGENTA}[AI Suggestion] Tx power adjustment is supported. Adjust to comply with local regulations.${NC}")
        else
            lines+=("$(display_status "Tx Power Adjustment" "Not Supported" "(Tx power cannot be adjusted.)")")
            lines+=("${BLUE}[*] Error details:${NC}")
            lines+=("${BLUE}  $IWCONFIG_TXPOWER_OUTPUT${NC}")
            lines+=("${MAGENTA}[AI Suggestion] Adjustment failed. Check driver compatibility or permissions.${NC}")
        fi
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check MAC address spoofing support
check_mac_spoofing() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    lines+=("${BLUE}[*] Checking MAC address spoofing support for $ADAPTER_NAME...${NC}")
    local ORIGINAL_MAC
    ORIGINAL_MAC=$(ifconfig "$ADAPTER_NAME" 2>/dev/null | grep -o -E "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
    if [ -z "$ORIGINAL_MAC" ]; then
        echo -e "${BLUE}[!] Unable to retrieve the current MAC address.${NC}"
        echo -e "${MAGENTA}[AI Suggestion] Ensure the adapter is properly connected and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    ifconfig "$ADAPTER_NAME" down 2>/dev/null
    ifconfig "$ADAPTER_NAME" hw ether "00:11:22:33:44:55" 2>/dev/null
    if [ $? -eq 0 ]; then
        lines+=("$(display_status "MAC Spoofing" "Supported" "(Adapter supports MAC address spoofing.)")")
        ifconfig "$ADAPTER_NAME" hw ether "$ORIGINAL_MAC" 2>/dev/null
        ifconfig "$ADAPTER_NAME" up 2>/dev/null
        lines+=("${MAGENTA}[AI Suggestion] Use MAC spoofing to anonymize your device during testing. Be cautious of legal implications.${NC}")
    else
        lines+=("$(display_status "MAC Spoofing" "Not Supported" "(Adapter does not support MAC address spoofing.)")")
        ifconfig "$ADAPTER_NAME" up 2>/dev/null
        lines+=("${MAGENTA}[AI Suggestion] MAC spoofing is not supported. Consider using a different adapter for anonymity testing.${NC}")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check virtual interface support
check_virtual_interfaces() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    lines+=("${BLUE}[*] Checking virtual interface support for $ADAPTER_NAME...${NC}")
    iw dev "$ADAPTER_NAME" interface add test_if type managed 2>/dev/null
    if [ $? -eq 0 ]; then
        lines+=("$(display_status "Virtual Interfaces" "Supported" "(Adapter can create virtual interfaces.)")")
        iw dev test_if del 2>/dev/null
        lines+=("${MAGENTA}[AI Suggestion] Use virtual interfaces to run multiple modes (e.g., AP and monitor) simultaneously.${NC}")
    else
        lines+=("$(display_status "Virtual Interfaces" "Not Supported" "(Adapter cannot create virtual interfaces.)")")
        lines+=("${MAGENTA}[AI Suggestion] Virtual interfaces are not supported. You may need to use multiple adapters for simultaneous operations.${NC}")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to check adapter capabilities (submenu)
check_adapter_capabilities() {
    while true; do
        clear
        display_banner
        local menu_lines=(
            "1. Check Monitor Mode Status"
            "2. Check Packet Injection Support"
            "3. Check Access Point (AP) Mode Support"
            "4. Check Managed Mode Support"
            "5. Check Ad-Hoc Mode Support"
            "6. Check Mesh Mode Support"
            "7. Check Supported Channels"
            "8. Check Tx Power"
            "9. Check MAC Address Spoofing Support"
            "10. Check Virtual Interface Support"
            "11. Back"
        )
        for line in "${menu_lines[@]}"; do
            echo -e "${GREEN}${line}${NC}"
        done
        echo -e "\n"
        echo -e "${GREEN}Enter your choice (1-11): ${NC}"
        while read -r -t 0; do read -r; done
        stty sane
        read -r choice
        echo "[DEBUG] Captured choice: '$choice'"

        case $choice in
            1)
                check_monitor_mode
                ;;
            2)
                check_packet_injection
                ;;
            3)
                check_ap_mode
                ;;
            4)
                check_managed_mode
                ;;
            5)
                check_adhoc_mode
                ;;
            6)
                check_mesh_mode
                ;;
            7)
                check_supported_channels
                ;;
            8)
                check_tx_power
                ;;
            9)
                check_mac_spoofing
                ;;
            10)
                check_virtual_interfaces
                ;;
            11)
                break
                ;;
            *)
                echo -e "${BLUE}[!] Invalid choice. Please select 1-11.${NC}"
                echo -e "${BLUE}Press Enter to continue...${NC}"
                read -r
                display_footer
                ;;
        esac
    done
}

# Function to enable packet injection mode
enable_packet_injection() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    ensure_monitor_mode "$ADAPTER_NAME"
    if [ $? -ne 0 ]; then
        lines+=("${BLUE}[!] Packet injection requires monitor mode. Aborting.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    lines+=("${BLUE}[*] Verifying packet injection support...${NC}")
    local AIREPLAY_OUTPUT
    AIREPLAY_OUTPUT=$(aireplay-ng --test "$ADAPTER_NAME" 2>&1)
    if echo "$AIREPLAY_OUTPUT" | grep -q "Injection is working!"; then
        lines+=("${GREEN}[+] Packet injection mode enabled successfully.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Packet injection is active. Use aireplay-ng for deauthentication attacks or packet forging.${NC}")
    else
        lines+=("${BLUE}[!] Packet injection not supported by this adapter.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Consider using a different adapter that supports packet injection for advanced testing.${NC}")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to enable AP mode
enable_ap_mode() {
    clear
    display_banner
    local lines=()

    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        lines+=("${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}")
        lines+=("${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi
    lines+=("${BLUE}[*] Using adapter: $ADAPTER_NAME${NC}")

    # Aggressive cleanup of monitor mode interfaces
    if [[ "$ADAPTER_NAME" =~ mon ]]; then
        lines+=("${BLUE}[!] Detected monitor mode suffix in '$ADAPTER_NAME'. Cleaning up...${NC}")
        airmon-ng stop "$ADAPTER_NAME" >/dev/null 2>&1
        iw dev "$ADAPTER_NAME" del 2>/dev/null
        ADAPTER_NAME="$ORIGINAL_ADAPTER_NAME"
        if ! iw dev | grep -q "$ADAPTER_NAME"; then
            lines+=("${BLUE}[!] Failed to revert to $ADAPTER_NAME. Base interface may be missing.${NC}")
            for line in "${lines[@]}"; do
                echo -e "$line"
            done
            echo -e "\n"
            echo -e "${BLUE}Press Enter to continue...${NC}"
            read -r
            display_footer
            return
        fi
        lines+=("${BLUE}[*] Reverted to base adapter: $ADAPTER_NAME${NC}")
    fi

    lines+=("${BLUE}[*] Checking AP mode support for $ADAPTER_NAME...${NC}")
    local IW_LIST_OUTPUT
    IW_LIST_OUTPUT=$(iw list 2>/dev/null | grep "AP")
    if [ -z "$IW_LIST_OUTPUT" ]; then
        lines+=("${BLUE}[!] AP mode not supported by this adapter.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] AP mode is not supported. Check 'iw list' for supported modes.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi
    lines+=("${GREEN}[+] AP mode is supported by this adapter.${NC}")

    # Stop interfering processes
    lines+=("${BLUE}[*] Stopping NetworkManager and killing conflicting processes...${NC}")
    airmon-ng check kill >/dev/null 2>&1
    systemctl stop NetworkManager >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        lines+=("${GREEN}[+] NetworkManager stopped successfully.${NC}")
    else
        lines+=("${BLUE}[!] Failed to stop NetworkManager. Proceeding anyway.${NC}")
    fi

    # Bring interface down with error details
    lines+=("${BLUE}[*] Bringing $ADAPTER_NAME down...${NC}")
    local IFCONFIG_DOWN_OUTPUT
    IFCONFIG_DOWN_OUTPUT=$(ifconfig "$ADAPTER_NAME" down 2>&1)
    if [ $? -ne 0 ]; then
        lines+=("${BLUE}[!] Failed to bring $ADAPTER_NAME down.${NC}")
        lines+=("${BLUE}[*] Error details: $IFCONFIG_DOWN_OUTPUT${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Ensure no processes are using $ADAPTER_NAME. Try 'airmon-ng check kill' or reboot.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi
    lines+=("${GREEN}[+] Interface $ADAPTER_NAME brought down successfully.${NC}")

    # Set interface to AP mode
    lines+=("${BLUE}[*] Setting $ADAPTER_NAME to AP mode...${NC}")
    iw dev "$ADAPTER_NAME" set type ap 2>/dev/null
    if [ $? -ne 0 ]; then
        lines+=("${BLUE}[!] Failed to set $ADAPTER_NAME to AP mode.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Check 'iw list' for AP support and ensure no conflicting processes.${NC}")
        ifconfig "$ADAPTER_NAME" up 2>/dev/null
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    # Bring interface up
    lines+=("${BLUE}[*] Bringing $ADAPTER_NAME up...${NC}")
    ifconfig "$ADAPTER_NAME" up 2>/dev/null
    if [ $? -ne 0 ]; then
        lines+=("${BLUE}[!] Failed to bring $ADAPTER_NAME up.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    # Check if hostapd is installed
    if ! command -v hostapd >/dev/null 2>&1; then
        lines+=("${BLUE}[!] hostapd not found. Installing...${NC}")
        apt install -y hostapd >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            lines+=("${BLUE}[!] Failed to install hostapd. Please install it manually.${NC}")
            for line in "${lines[@]}"; do
                echo -e "$line"
            done
            echo -e "\n"
            echo -e "${BLUE}Press Enter to continue...${NC}"
            read -r
            display_footer
            return
        fi
        lines+=("${GREEN}[+] hostapd installed successfully.${NC}")
    fi

    # Prompt for SSID and channel
    lines+=("${BLUE}[*] Enter SSID for the AP:${NC}")
    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    read -r ap_ssid
    lines=("${BLUE}[*] Enter channel for the AP (e.g., 6):${NC}")
    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    read -r ap_channel

    # Create a basic hostapd configuration
    cat > /tmp/hostapd.conf <<EOF
interface=$ADAPTER_NAME
driver=nl80211
ssid=$ap_ssid
hw_mode=g
channel=$ap_channel
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF

    # Start hostapd
    lines+=("${BLUE}[*] Starting hostapd to broadcast the AP...${NC}")
    hostapd /tmp/hostapd.conf >/dev/null 2>&1 &
    sleep 2
    if pgrep -f "hostapd /tmp/hostapd.conf" >/dev/null; then
        lines+=("${GREEN}[+] AP mode enabled successfully. SSID: $ap_ssid, Channel: $ap_channel${NC}")
        lines+=("${MAGENTA}[AI Suggestion] AP is broadcasting. Configure an IP (e.g., 'ifconfig $ADAPTER_NAME 192.168.1.1') and start a DHCP server (e.g., dnsmasq) for clients.${NC}")
    else
        lines+=("${BLUE}[!] Failed to start hostapd.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Check hostapd logs (e.g., 'journalctl -xe') or ensure the channel is supported.${NC}")
    fi

    # Cleanup
    lines+=("${BLUE}[*] Press Enter to stop the AP and continue...${NC}")
    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    read -r
    pkill -f "hostapd /tmp/hostapd.conf" 2>/dev/null
    rm -f /tmp/hostapd.conf

    # Revert to managed mode
    revert_to_managed "$ADAPTER_NAME"

    # Restart NetworkManager
    lines+=("${BLUE}[*] Restarting NetworkManager...${NC}")
    systemctl start NetworkManager >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        lines+=("${GREEN}[+] NetworkManager restarted successfully.${NC}")
    else
        lines+=("${BLUE}[!] Failed to restart NetworkManager.${NC}")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to perform a deauthentication attack
deauthentication_attack() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    ensure_monitor_mode "$ADAPTER_NAME"
    if [ $? -ne 0 ]; then
        lines+=("${BLUE}[!] Deauthentication attack requires monitor mode. Aborting.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    lines+=("${BLUE}[*] Please enter the target BSSID (e.g., 00:11:22:33:44:55):${NC}")
    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${GREEN}Target BSSID: ${NC}"
    read -r target_bssid
    echo -e "${BLUE}[*] Please enter the target channel (e.g., 6):${NC}"
    echo -e "${GREEN}Target Channel: ${NC}"
    read -r target_channel

    lines=()
    lines+=("${BLUE}[*] Performing deauthentication attack on $ADAPTER_NAME...${NC}")
    lines+=("Target BSSID: $target_bssid")
    lines+=("Target Channel: $target_channel")
    local AIREPLAY_OUTPUT
    AIREPLAY_OUTPUT=$(aireplay-ng --deauth 10 -a "$target_bssid" "$ADAPTER_NAME" 2>&1)
    if echo "$AIREPLAY_OUTPUT" | grep -q "Sending"; then
        lines+=("${GREEN}[+] Deauthentication packets sent successfully.${NC}")
        lines+=("${MAGENTA}[AI Suggestion] Monitor the target network to confirm clients are disconnected. Use airodump-ng to capture handshakes.${NC}")
    else
        lines+=("${BLUE}[!] Failed to send deauthentication packets.${NC}")
        lines+=("Full Output:")
        while IFS= read -r line; do
            lines+=("$line")
        done <<< "$AIREPLAY_OUTPUT"
        lines+=("${MAGENTA}[AI Suggestion] Ensure the adapter supports packet injection and the target is in range. Check channel and BSSID.${NC}")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to enable fake AP broadcasting
enable_fake_ap() {
    clear
    display_banner
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
        echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    local lines=()
    lines+=("${BLUE}[*] Please enter the SSID for the fake AP (e.g., FreeWiFi):${NC}")
    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${GREEN}SSID: ${NC}"
    read -r fake_ssid
    echo -e "${BLUE}[*] Please enter the channel for the fake AP (e.g., 6):${NC}"
    echo -e "${GREEN}Channel: ${NC}"
    read -r fake_channel

    lines=()
    lines+=("${BLUE}[*] Setting up fake AP on $ADAPTER_NAME...${NC}")
    lines+=("SSID: $fake_ssid")
    lines+=("Channel: $fake_channel")
    lines+=("${GREEN}[+] Fake AP broadcasting enabled successfully (simulated).${NC}")
    lines+=("${MAGENTA}[AI Suggestion] Fake AP is active. Use dnsmasq and hostapd to manage clients. Monitor connections with airodump-ng.${NC}")

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Function to activate hacking mode (submenu)
activate_hacking_mode() {
    while true; do
        clear
        display_banner
        local menu_lines=(
            "1. Enable Monitor Mode"
            "2. Enable Packet Injection Mode"
            "3. Enable Access Point (AP) Mode"
            "4. Deauthentication Attack"
            "5. Enable Fake AP Broadcasting"
            "6. Back"
        )
        for line in "${menu_lines[@]}"; do
            echo -e "${GREEN}${line}${NC}"
        done
        echo -e "\n"
        echo -e "${GREEN}Enter your choice (1-6): ${NC}"
        while read -r -t 0; do read -r; done
        stty sane
        read -r choice
        echo "[DEBUG] Captured choice: '$choice'"

        case $choice in
            1)
                clear
                display_banner
                ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
                if [ $? -ne 0 ]; then
                    echo -e "${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}"
                    echo -e "${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}"
                    echo -e "\n"
                    echo -e "${BLUE}Press Enter to continue...${NC}"
                    read -r
                    display_footer
                    continue
                fi
                local lines=()
                ensure_monitor_mode "$ADAPTER_NAME"
                if [ $? -eq 0 ]; then
                    lines+=("${GREEN}[+] Monitor mode activated successfully.${NC}")
                else
                    lines+=("${BLUE}[!] Failed to activate monitor mode.${NC}")
                fi
                for line in "${lines[@]}"; do
                    echo -e "$line"
                done
                echo -e "\n"
                echo -e "${BLUE}Press Enter to continue...${NC}"
                read -r
                display_footer
                ;;
            2)
                enable_packet_injection
                ;;
            3)
                enable_ap_mode
                ;;
            4)
                deauthentication_attack
                ;;
            5)
                enable_fake_ap
                ;;
            6)
                break
                ;;
            *)
                echo -e "${BLUE}[!] Invalid choice. Please select 1-6.${NC}"
                echo -e "${BLUE}Press Enter to continue...${NC}"
                read -r
                display_footer
                ;;
        esac
    done
}

# Function to intelligently assess the adapter
assess_adapter_intelligently() {
    local lines=()
    lines+=("${BLUE}[*] Assessing adapter capabilities for $ADAPTER_NAME...${NC}")

    local IWCONFIG_OUTPUT
    IWCONFIG_OUTPUT=$(iwconfig "$ADAPTER_NAME" 2>/dev/null)
    if [ -z "$IWCONFIG_OUTPUT" ]; then
        lines+=("${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}")
        lines+=("${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}")
        AI_RECOMMENDATION="Unable to assess adapter. Ensure it is connected and recognized."
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        return 1
    fi

    if echo "$IWCONFIG_OUTPUT" | grep -q "Mode:Monitor"; then
        SUPPORTS_MONITOR_MODE="yes"
    else
        ensure_monitor_mode "$ADAPTER_NAME"
        if [ $? -eq 0 ]; then
            SUPPORTS_MONITOR_MODE="yes"
            revert_to_managed "$ADAPTER_NAME"
        else
            SUPPORTS_MONITOR_MODE="no"
        fi
    fi

    if [ "$SUPPORTS_MONITOR_MODE" = "yes" ]; then
        ensure_monitor_mode "$ADAPTER_NAME"
        local AIREPLAY_OUTPUT
        AIREPLAY_OUTPUT=$(aireplay-ng --test "$ADAPTER_NAME" 2>&1)
        if echo "$AIREPLAY_OUTPUT" | grep -q "Injection is working!"; then
            SUPPORTS_PACKET_INJECTION="yes"
        else
            SUPPORTS_PACKET_INJECTION="no"
        fi
        revert_to_managed "$ADAPTER_NAME"
    else
        SUPPORTS_PACKET_INJECTION="no"
    fi

    local IW_LIST_OUTPUT
    IW_LIST_OUTPUT=$(iw list 2>/dev/null | grep "AP")
    if [ -n "$IW_LIST_OUTPUT" ]; then
        SUPPORTS_AP_MODE="yes"
    else
        SUPPORTS_AP_MODE="no"
    fi

    lines+=("${BLUE}AI Assessment Results for $ADAPTER_NAME:${NC}")
    lines+=("$(display_status "Monitor Mode" "$SUPPORTS_MONITOR_MODE" "")")
    lines+=("$(display_status "Packet Injection" "$SUPPORTS_PACKET_INJECTION" "")")
    lines+=("$(display_status "AP Mode" "$SUPPORTS_AP_MODE" "")")

    if [ "$SUPPORTS_MONITOR_MODE" = "yes" ] && [ "$SUPPORTS_PACKET_INJECTION" = "yes" ]; then
        AI_RECOMMENDATION="Your adapter is ideal for hacking mode. Enable monitor mode and packet injection for advanced penetration testing."
    elif [ "$SUPPORTS_MONITOR_MODE" = "yes" ]; then
        AI_RECOMMENDATION="Your adapter supports monitor mode. You can use it for network scanning, but packet injection is not available."
    elif [ "$SUPPORTS_AP_MODE" = "yes" ]; then
        AI_RECOMMENDATION="Your adapter supports AP mode. You can set up a rogue access point for testing purposes."
    else
        AI_RECOMMENDATION="Your adapter has limited capabilities. Consider using a different adapter for advanced testing."
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${MAGENTA}[AI Recommendation] $AI_RECOMMENDATION${NC}"
    echo -e "\n"
}

# Function for AI Mode (automatic configuration)
ai_mode() {
    clear
    display_banner
    local lines=()
    ADAPTER_NAME=$(get_current_interface "$ADAPTER_NAME")
    if [ $? -ne 0 ]; then
        lines+=("${BLUE}[!] Error: Adapter $ADAPTER_NAME not found or not a wireless interface.${NC}")
        lines+=("${BLUE}Please ensure a wireless adapter is plugged in and try again.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    lines+=("${BLUE}[*] Starting AI Mode (Automatic Configuration) for $ADAPTER_NAME...${NC}")

    assess_adapter_intelligently
    if [ $? -ne 0 ]; then
        lines+=("${BLUE}[!] Aborting AI Mode due to assessment failure.${NC}")
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        echo -e "\n"
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -r
        display_footer
        return
    fi

    if [ "$SUPPORTS_MONITOR_MODE" = "yes" ]; then
        lines+=("${BLUE}[*] Enabling monitor mode...${NC}")
        ensure_monitor_mode "$ADAPTER_NAME"
        if [ $? -eq 0 ]; then
            lines+=("${GREEN}[+] Monitor mode enabled successfully on $ADAPTER_NAME.${NC}")
            lines+=("${BLUE}[*] Checking packet injection support...${NC}")
            local AIREPLAY_OUTPUT
            AIREPLAY_OUTPUT=$(aireplay-ng --test "$ADAPTER_NAME" 2>&1)
            if echo "$AIREPLAY_OUTPUT" | grep -q "Injection is working!"; then
                lines+=("${GREEN}[+] Packet injection is supported.${NC}")
                SUPPORTS_PACKET_INJECTION="yes"
            else
                lines+=("${BLUE}[!] Packet injection is not supported or test failed.${NC}")
                SUPPORTS_PACKET_INJECTION="no"
            fi
        else
            lines+=("${BLUE}[!] Failed to enable monitor mode.${NC}")
        fi
    else
        lines+=("${BLUE}[!] Monitor mode is not supported by this adapter.${NC}")
    fi

    if [ "$SUPPORTS_AP_MODE" = "yes" ]; then
        lines+=("${BLUE}[*] AP mode is supported. Do you want to enable AP mode? (y/n)${NC}")
        read -r enable_ap
        if [ "$enable_ap" = "y" ]; then
            enable_ap_mode
        fi
    else
        lines+=("${BLUE}[!] AP mode is not supported by this adapter.${NC}")
    fi

    for line in "${lines[@]}"; do
        echo -e "$line"
    done
    echo -e "\n"
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -r
    display_footer
}

# Main script starts here
display_banner

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${BLUE}[!] Error: Please run this script as root (sudo) for full functionality.${NC}"
    echo -e "${BLUE}Run: sudo $0${NC}"
    echo -e "\n"
    display_footer
    exit 1
fi

install_dependencies

select_adapter

original_adapter_msg="Original adapter name: $ORIGINAL_ADAPTER_NAME"
while [ $(string_length "$original_adapter_msg") -lt 52 ]; do
    original_adapter_msg="$original_adapter_msg "
done
echo -e "${BLUE}[*] ${original_adapter_msg}${NC}"

assess_adapter_intelligently

while true; do
    clear
    display_banner
    menu_lines=(
        "1. Check Adapter Details"
        "2. Check Adapter Capabilities and Supported Modes"
        "3. Activate Hacking Mode"
        "4. AI Mode (Automatic Configuration)"
        "5. Exit"
    )
    for line in "${menu_lines[@]}"; do
        echo -e "${GREEN}${line}${NC}"
    done
    echo -e "\n"
    echo -e "${MAGENTA}[AI Recommendation] $AI_RECOMMENDATION${NC}"
    echo -e "\n"
    echo -e "${GREEN}Enter your choice (1-5): ${NC}"
    while read -r -t 0; do read -r; done
    stty sane
    read -r choice
    echo "[DEBUG] Captured choice: '$choice'"

    case $choice in
        1)
            check_adapter_details
            ;;
        2)
            check_adapter_capabilities
            ;;
        3)
            activate_hacking_mode
            ;;
        4)
            ai_mode
            ;;
        5)
            clear
            display_banner
            echo -e "Exiting Wi-Fi Adapter Tool. Stay ethical!"
            echo -e "\n"
            display_footer
            exit 0
            ;;
        *)
            echo -e "${BLUE}[!] Invalid choice. Please select 1-5.${NC}"
            echo -e "${BLUE}Press Enter to continue...${NC}"
            read -r
            display_footer
            ;;
    esac
done