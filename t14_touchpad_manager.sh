#!/bin/bash

# =================================================================
# FINAL FIX: ThinkPad T14 Gen 2 - Touchpad & TrackPoint Manager
# Description: Fixes initial lag, erratic jumps, and inactive buttons.
# Author: Diego Belalcazar
# =================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# File paths
QUIRKS_FILE="/etc/libinput/local-overrides.quirks"
UDEV_FILE="/etc/udev/rules.d/99-thinkpad-performance.rules"

if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}❌ Error: Please run as root: sudo $0${NC}"
  exit 1
fi

show_menu() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${YELLOW}   THINKPAD T14 GEN 2 INPUT MANAGER       ${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo -e "1) ${GREEN}INSTALL FIXES${NC} (Maximum Performance)"
    echo -e "2) ${RED}UNINSTALL / ROLLBACK${NC} (Factory State)"
    echo -e "3) Exit"
    echo -e "${BLUE}===========================================${NC}"
    echo -n "Select an option: "
}

install_fix() {
    echo -e "\n${BLUE}🚀 Starting optimization process...${NC}"

    # 1. Bus Configuration (GRUB)
    echo -e "📦 Step 1: Enabling RMI4 bus in GRUB..."
    if ! grep -q "psmouse.synaptics_intertouch=1" /etc/default/grub; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="psmouse.synaptics_intertouch=1 /' /etc/default/grub
        if [ -f /usr/bin/grub-mkconfig ]; then
            grub-mkconfig -o /boot/grub/grub.cfg
        elif [ -f /usr/bin/grub2-mkconfig ]; then
            grub2-mkconfig -o /etc/grub2.cfg
        fi
        echo -e "   ${GREEN}OK:${NC} GRUB updated successfully."
    else
        echo -e "   ${YELLOW}INFO:${NC} RMI4 bus was already enabled."
    fi

    # 2. Precision & Button Tuning (Quirks)
    echo -e "🎯 Step 2: Configuring precision and physical buttons..."
    mkdir -p /etc/libinput
    cat <<EOF > "$QUIRKS_FILE"
[ThinkPad T14 Gen 2 Touchpad]
MatchUdevType=touchpad
MatchName=Synaptics TM3471-030
AttrPressureRange=25:20
AttrThumbPressureThreshold=100
AttrPalmPressureThreshold=150

[ThinkPad T14 Gen 2 TrackPoint Buttons Fix]
MatchUdevType=pointingstick
# Disables stick movement to prevent jitter but keeps buttons active
AttrTrackpointMultiplier=0.0
EOF
    echo -e "   ${GREEN}OK:${NC} Libinput Quirks file created."

    # 3. Energy Rules (Udev)
    echo -e "⚡ Step 3: Eliminating power management latency (Anti-Lag)..."
    cat <<EOF > "$UDEV_FILE"
# Force PCI and Input buses to stay 'on'
ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="on", ATTR{power/autosuspend_delay_ms}="-1"
ACTION=="add", SUBSYSTEM=="serio", ATTR{power/control}="on", ATTR{power/autosuspend_delay_ms}="-1"
# Specific rules for Synaptics hardware and TrackPoint
ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Synaptics TM3471-030", ATTR{power/control}="on", ATTR{power/autosuspend_delay_ms}="-1"
ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="*TrackPoint*", ATTR{power/control}="on", ATTR{power/autosuspend_delay_ms}="-1"
EOF
    echo -e "   ${GREEN}OK:${NC} Udev rules installed."

    # 4. Immediate Energy Application
    echo -e "🔥 Step 4: Waking up hardware immediately..."
    find /sys/devices/platform/ /sys/devices/pci0000:00/ -name "control" 2>/dev/null | while read -r line; do
        echo "on" > "$line" 2>/dev/null
    done
    echo -e "   ${GREEN}OK:${NC} Buses forced to active mode."

    echo -e "\n${GREEN}✨ INSTALLATION FINISHED.${NC}"
    echo -e "${YELLOW}REQUIREMENT:${NC} TrackPoint must be ENABLED in BIOS."
    echo -e "${YELLOW}ACTION:${NC} Please REBOOT now to apply GRUB and Quirks changes."
}

uninstall_fix() {
    echo -e "\n${RED}🔄 Reverting changes to factory state...${NC}"

    # 1. Clean GRUB
    echo -e "🗑️  Cleaning GRUB parameters..."
    sed -i 's/psmouse.synaptics_intertouch=1 //' /etc/default/grub
    if [ -f /usr/bin/grub-mkconfig ]; then
        grub-mkconfig -o /boot/grub/grub.cfg
    elif [ -f /usr/bin/grub2-mkconfig ]; then
        grub2-mkconfig -o /etc/grub2.cfg
    fi

    # 2. Remove Files
    echo -e "🗑️  Deleting configuration files..."
    rm -f "$QUIRKS_FILE"
    rm -f "$UDEV_FILE"

    # 3. Restore Energy to Auto
    echo -e "⚡ Restoring automatic power management..."
    find /sys/devices/platform/ /sys/devices/pci0000:00/ -name "control" 2>/dev/null | while read -r line; do
        echo "auto" > "$line" 2>/dev/null
    done

    echo -e "\n${GREEN}✅ System restored. Please reboot to finalize.${NC}"
}

while true; do
    show_menu
    read -p "" opt
    case $opt in
        1) install_fix ; break ;;
        2) uninstall_fix ; break ;;
        3) exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
done
