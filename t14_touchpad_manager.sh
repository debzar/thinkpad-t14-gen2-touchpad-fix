#!/bin/bash

# =================================================================
# ThinkPad T14 Gen 2 Touchpad & Input Manager - ULTIMATE FIX
# Optimized for CachyOS / GNOME / Arch
# =================================================================

if [[ $EUID -ne 0 ]]; then
   echo "❌ Este script debe ejecutarse como root (usa sudo)."
   exit 1
fi

QUIRKS_FILE="/etc/libinput/local-overrides.quirks"
UDEV_RULE="/etc/udev/rules.d/99-touchpad-no-sleep.rules"
MODPROBE_FILE="/etc/modprobe.d/psmouse.conf"
RESUME_SCRIPT="/usr/local/bin/touchpad-resume-fix.sh"
SYSTEMD_SERVICE="/etc/systemd/system/touchpad-resume.service"

install_fix() {
    echo "🚀 Instalando Fix de Sensibilidad Extrema y Resurrección..."

    # 1. Forzar Protocolo RMI4
    echo "📡 Paso 1: Configurando protocolo RMI4 (SMBus)..."
    echo "options psmouse synaptics_intertouch=1" > "$MODPROBE_FILE"

    # 2. Quirks de Sensibilidad (2:1) y Anti-Jitter
    echo "🎯 Paso 2: Aplicando sensibilidad 2:1 y bloqueo de movimiento fantasma..."
    mkdir -p /etc/libinput
    cat <<EOF > "$QUIRKS_FILE"
[ThinkPad T14 Gen 2 Touchpad]
MatchUdevType=touchpad
MatchName=Synaptics TM3471-030
AttrPressureRange=2:1
AttrThumbPressureThreshold=20
AttrPalmPressureThreshold=254
AttrTappingPointingStickThreshold=0.0
AttrTappingTerminatorThreshold=0.01

[ThinkPad T14 Gen 2 TrackPoint Fix]
MatchUdevType=pointingstick
AttrTrackpointMultiplier=0.0
EOF

    # 3. Regla Anti-Freeze
    echo "⚡ Paso 3: Desactivando ahorro de energía en el bus (Anti-Freeze)..."
    cat <<EOF > "$UDEV_RULE"
ACTION=="add", SUBSYSTEM=="serio", DRIVERS=="psmouse", ATTR{description}=="Synaptics*", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="i2c", DRIVERS=="i2c_designware", ATTR{power/control}="on"
EOF

    # 4. Fix de Suspensión (Resurrección automática)
    echo "💤 Paso 4: Instalando servicio de recuperación post-suspensión..."
    cat <<EOF > "$RESUME_SCRIPT"
#!/bin/bash
modprobe -r psmouse
modprobe psmouse synaptics_intertouch=1
udevadm control --reload-rules && udevadm trigger
EOF
    chmod +x "$RESUME_SCRIPT"

    cat <<EOF > "$SYSTEMD_SERVICE"
[Unit]
Description=Fix Touchpad sensitivity after suspend
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=$RESUME_SCRIPT

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
EOF
    systemctl enable touchpad-resume.service

    echo "✅ ¡Todo instalado! Reinicia para aplicar los cambios del Kernel."
}

uninstall_fix() {
    echo "🔄 Eliminando todas las modificaciones..."
    systemctl disable touchpad-resume.service
    rm -f "$QUIRKS_FILE" "$UDEV_RULE" "$MODPROBE_FILE" "$RESUME_SCRIPT" "$SYSTEMD_SERVICE"
    echo "✅ Sistema restaurado. Por favor, reinicia."
}

echo "1) Instalar Fix Completo (Sensibilidad + Suspensión)"
echo "2) Desinstalar"
read -p "Opción: " choice
case $choice in
    1) install_fix ;;
    2) uninstall_fix ;;
esac
