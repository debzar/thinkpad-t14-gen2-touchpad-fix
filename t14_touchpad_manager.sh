#!/bin/bash
# =================================================================
# ThinkPad T14 Gen 2 Touchpad Fix - REVISADO Y SEGURO
# =================================================================

if [[ $EUID -ne 0 ]]; then
   echo "❌ Ejecuta con sudo."
   exit 1
fi

echo "🚀 Iniciando configuración quirúrgica..."

# 1. PARAMETROS DEL KERNEL (La base de la velocidad)
MODS="psmouse.synaptics_intertouch=1 i2c_designware.disable_ps=1"

# 2. CONFIGURACIÓN DE MODPROBE
echo "options psmouse synaptics_intertouch=1 elantech_smbus=1" > /etc/modprobe.d/psmouse.conf

# 3. QUIRKS DE SENSIBILIDAD (Toque de pluma)
cat <<EOF > /etc/libinput/local-overrides.quirks
[ThinkPad T14 Gen 2 Touchpad]
MatchUdevType=touchpad
MatchName=Synaptics TM3471-030
AttrPressureRange=1:0
AttrThumbPressureThreshold=10
AttrPalmPressureThreshold=254

[ThinkPad T14 Gen 2 TrackPoint Fix]
MatchUdevType=pointingstick
AttrTrackpointMultiplier=0.01
EOF

# 4. ACTUALIZACIÓN INTELIGENTE DEL GRUB
# Este bloque extrae la línea, limpia los parámetros si ya existen y los añade de nuevo.
echo "🖥️  Actualizando GRUB de forma segura..."

# Obtener la línea actual
CURRENT_LINE=$(grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub)

# Limpiar parámetros previos para evitar duplicados
CLEAN_LINE=$(echo "$CURRENT_LINE" | sed -e 's/psmouse.synaptics_intertouch=1 //g' \
                                     -e 's/i2c_designware.disable_ps=1 //g' \
                                     -e 's/psmouse.resetafter=1 //g')

# Insertar los nuevos parámetros justo después de la primera comilla
FINAL_LINE=$(echo "$CLEAN_LINE" | sed 's/="/="'"$MODS"' /')

# Aplicar el cambio al archivo
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT.*|$FINAL_LINE|" /etc/default/grub

# 5. REGENERAR TODO
echo "🔄 Regenerando imágenes de arranque y GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P

echo "✅ ¡HECHO! El script ha configurado el modo RMI4 y la sensibilidad máxima."
echo "⚠️  REINICIA para aplicar los cambios."
