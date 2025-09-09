#!/usr/bin/env python3
import subprocess
import os
import sys
import json
import glob

DRIVERS_FILE = os.path.join(os.path.dirname(os.path.realpath(__file__)), "drivers.json")

# --- Funções utilitárias ---
def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT).decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8').strip()

def detect_distro():
    try:
        with open("/etc/os-release") as f:
            info = f.read().lower()
        if "ubuntu" in info or "debian" in info or "deepin" in info:
            return "debian"
        elif "fedora" in info or "rhel" in info or "centos" in info or "rocky" in info:
            return "rpm"
        elif "arch" in info or "manjaro" in info or "endeavouros" in info:
            return "arch"
        else:
            return "generic"
    except:
        return "generic"

def install_deps():
    distro = detect_distro()
    print(f"➡️ Detectando distro: {distro}")
    if distro == "debian":
        run_cmd("sudo apt update && sudo apt install -y build-essential dkms git linux-headers-$(uname -r) lshw pciutils usbutils")
    elif distro == "rpm":
        run_cmd("sudo dnf install -y gcc make kernel-devel kernel-headers git lshw pciutils usbutils")
    elif distro == "arch":
        run_cmd("sudo pacman -Syu --needed base-devel git linux-headers lshw pciutils usbutils")
    else:
        print("⚠️ Distro não reconhecida, instale manualmente: gcc/make, headers do kernel, git, lshw, pciutils, usbutils")

# --- Detecção robusta de hardware ---
def detect_hardware():
    print("🔍 Detectando hardware...")
    pci_output = run_cmd("lspci -nnk")
    usb_output = run_cmd("lsusb")

    wifi_keywords = ["Wireless", "Network controller", "Wi-Fi", "WLAN", "RTL", "Realtek", "Intel", "Broadcom"]
    bt_keywords = ["Bluetooth", "BT", "BlueZ"]

    wifi_hw = [line for line in pci_output.splitlines() if any(k.lower() in line.lower() for k in wifi_keywords)]
    wifi_hw += [line for line in usb_output.splitlines() if any(k.lower() in line.lower() for k in wifi_keywords)]

    bt_hw = [line for line in pci_output.splitlines() if any(k.lower() in line.lower() for k in bt_keywords)]
    bt_hw += [line for line in usb_output.splitlines() if any(k.lower() in line.lower() for k in bt_keywords)]

    print(f"📡 Wi-Fi detectado: {wifi_hw if wifi_hw else 'Nenhum'}")
    print(f"🔵 Bluetooth detectado: {bt_hw if bt_hw else 'Nenhum'}")
    return wifi_hw, bt_hw

# --- Drivers ---
def is_driver_loaded(module):
    if module in run_cmd("lsmod"):
        return True
    path_pattern = f"/lib/modules/{run_cmd('uname -r')}/kernel/drivers/**/{module}.ko*"
    return bool(glob.glob(path_pattern, recursive=True))

def install_driver(repo, module):
    tmp_dir = "/tmp/mei_driver"
    if os.path.exists(tmp_dir):
        run_cmd(f"rm -rf {tmp_dir}")
    print(f"⬇️ Clonando repo: {repo}")
    run_cmd(f"git clone {repo} {tmp_dir}")
    os.chdir(tmp_dir)
    if os.path.exists("Makefile"):
        print("⚙️ Compilando driver...")
        print(run_cmd("make"))
        print("📥 Instalando driver...")
        run_cmd("sudo make install")
        print(f"✅ Driver {module} instalado!")
    else:
        print("❌ Makefile não encontrado. Instale manualmente.")
    run_cmd(f"rm -rf {tmp_dir}")

def identify_fabricante(hw_list):
    for line in hw_list:
        if "Realtek" in line:
            return "Realtek"
        elif "Intel" in line:
            return "Intel"
        elif "Broadcom" in line:
            return "Broadcom"
    return "Generic"

# --- CLI ---
def main():
    if len(sys.argv) < 2:
        print("Uso: mei-git install [wifi|bluetooth] | setup")
        sys.exit(1)

    if sys.argv[1] == "setup":
        install_deps()
        sys.exit(0)

    if sys.argv[1] != "install":
        print("Uso: mei-git install [wifi|bluetooth]")
        sys.exit(1)

    targets = sys.argv[2:]
    wifi_hw, bt_hw = detect_hardware()

    with open(DRIVERS_FILE) as f:
        drivers = json.load(f)

    for t in targets:
        if t == "wifi":
            if not wifi_hw:
                print("❌ Nenhum Wi-Fi detectado")
                continue
            fab = identify_fabricante(wifi_hw)
            module = drivers["wifi"].get(fab, drivers["wifi"]["Generic"])["module"]
            if is_driver_loaded(module):
                print(f"✅ Driver Wi-Fi ({module}) já está carregado")
            else:
                confirm = input(f"O driver {module} para Wi-Fi não está carregado. Deseja instalar? [S/n]: ").lower()
                if confirm == "s" or confirm == "":
                    install_driver(drivers["wifi"].get(fab, drivers["wifi"]["Generic"])["repo"], module)
                else:
                    print("🚫 Instalação de Wi-Fi cancelada.")
        elif t == "bluetooth":
            if not bt_hw:
                print("❌ Nenhum Bluetooth detectado")
                continue
            fab = identify_fabricante(bt_hw)
            module = drivers["bluetooth"].get(fab, drivers["bluetooth"]["Generic"])["module"]
            if is_driver_loaded(module):
                print(f"✅ Driver Bluetooth ({module}) já está carregado")
            else:
                confirm = input(f"O driver {module} para Bluetooth não está carregado. Deseja instalar? [S/n]: ").lower()
                if confirm == "s" or confirm == "":
                    install_driver(drivers["bluetooth"].get(fab, drivers["bluetooth"]["Generic"])["repo"], module)
                else:
                    print("🚫 Instalação de Bluetooth cancelada.")
        else:
            print(f"⚠️ Tipo de driver desconhecido: {t}")

if __name__ == "__main__":
    main()


