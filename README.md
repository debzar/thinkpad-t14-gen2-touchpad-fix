# ⚠️ WARNING: THIS SCRIPT IS CURRENTLY IN TESTING STATE / ESTADO DE PRUEBA ⚠️

# ThinkPad T14 Gen 2 Touchpad & Input Fixer 🚀

A professional automation script to eliminate touchpad lag, erratic cursor behavior, and restore physical button functionality on the **Lenovo ThinkPad T14 Gen 2** running Linux.

---

## 🔍 The Problem
On many Linux distributions (Arch, CachyOS, Fedora, Ubuntu), the ThinkPad T14 Gen 2 suffers from a frustrating input experience:
* **Initial Lag:** The cursor "jumps" or delays after a second of inactivity because the power management puts the bus to sleep.
* **Erratic Movement:** The shared bus between the TrackPoint and Touchpad causes electrical interference.
* **Dead Buttons:** Disabling the TrackPoint in BIOS often kills the three physical buttons above the touchpad.

## ✨ Features
This manager applies a "Zero-Lag" configuration by:
* **Forcing RMI4 Bus:** Switches from PS/2 to the modern, high-precision RMI4 protocol.
* **Anti-Lag Power Rules:** Disables autosuspend for PCI and Input buses, keeping the hardware "awake" and responsive.
* **TrackPoint Button Rescue:** Disables the stick's cursor movement (preventing jitters) while keeping the top physical buttons 100% active.
* **Pressure Tuning:** Sets optimized Libinput thresholds to ignore ghost touches and improve palm rejection.

---

## 🛠 Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YOUR_USERNAME/thinkpad-t14-gen2-touchpad-fix](https://github.com/YOUR_USERNAME/thinkpad-t14-gen2-touchpad-fix)
   cd thinkpad-t14-gen2-touchpad-fix
   
2. **Run the manager:**
   ```bash
   chmod +x t14_touchpad_manager.sh
   sudo ./t14_touchpad_manager.sh   
   
   
3. **Select Option 1 (Install Fixes).**

4. **Reboot your system.**
