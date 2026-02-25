#!/bin/bash

# =================================================================
# ThinkPad T14 Gen 2 Touchpad & Input Manager (CachyOS/GNOME Ready)
# ⚠️ TESTING STATE / ESTADO DE PRUEBA
# =================================================================

if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)."
   exit 1
fi

QUIRKS_FILE="/etc/libinput/local-overrides.quirks"
UDEV_RULE="/etc/udev/rules.d/99-touchpad-no-sleep.rules"
MODPROBE_FILE="/etc/modprobe.d/psmouse.conf"

install_fix() {
    echo "🚀 Starting installation of Hyper-Responsive Fix..."

    # 1. Force RMI4 Protocol (Better than PS/2)
    echo "📡 Step 1: Forcing RMI4 protocol via modprobe..."
    echo "options psmouse synaptics_intertouch=1" > "$MODPROBE_FILE"

    # 2. Hyper-Sensitive Quirks & Anti-Jitter
    echo "🎯 Step 2: Applying Extreme Sensitivity (2:1) & Button Fix..."
    mkdir -p /etc/libinput
    cat <<EOF > "$QUIRKS_FILE"
[ThinkPad T14 Gen 2 Touchpad]
MatchUdevType=touchpad
MatchName=Synaptics TM3471-030
# Ultra-light pressure (Fixes hard clicks/ignored taps)
AttrPressureRange=2:1
AttrThumbPressureThreshold=20
AttrPalmPressureThreshold=254
# Instant tap response (Zero delay)
AttrTappingPointingStickThreshold=0.0
AttrTappingTerminatorThreshold=0.01

[ThinkPad T14 Gen 2 TrackPoint Fix]
MatchUdevType=pointingstick
# This prevents the cursor from "going crazy" while keeping buttons active
AttrTrackpointMultiplier=0.0
EOF

    # 3. Anti-Freeze Udev Rule (Power Management)
    echo "⚡ Step 3: Disabling power-save for the bus to eliminate freezing..."
    cat <<EOF > "$UDEV_RULE"
# Keep the touchpad bus awake at all times
ACTION=="add", SUBSYSTEM=="serio", DRIVERS=="psmouse", ATTR{description}=="Synaptics*", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="i2c", DRIVERS=="i2c_designware", ATTR{power/control}="on"
EOF

    # 4. GNOME Specific Settings (if applicable)
    if command -v gsettings &> /dev/null; then
        echo "🎨 Step 4: Optimizing GNOME peripheral settings..."
        # Note: This runs for the user who called sudo if configured, otherwise apply manually
        sudo -u $(logname) gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
        sudo -u $(logname) gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true
    fi

    echo "✅ Fixes applied successfully!"
    echo "⚠️  REBOOT is required to apply kernel and power changes."
}

uninstall_fix() {
    echo "🔄 Rolling back changes..."
    rm -f "$QUIRKS_FILE"
    rm -f "$UDEV_RULE"
    rm -f "$MODPROBE_FILE"
    echo "✅ System restored to default. Please reboot."
}

# --- Menu ---
echo "------------------------------------------"
echo "ThinkPad T14 Gen 2 Input Manager"
echo "------------------------------------------"
echo "1) Install Hyper-Sensitive Fix (Recommended)"
echo "2) Uninstall / Rollback"
echo "3) Exit"
read -p "Select an option: " choice

case $choice in
    1) install_fix ;;
    2) uninstall_fix ;;
    3) exit 0 ;;
    *) echo "Invalid option." ;;
esac
