#!/usr/bin/env python3
import subprocess
import os
import sys
import json
from datetime import datetime

# --- Configurações ---
DRIVERS_FILE = os.path.join(os.path.dirname(os.path.realpath(__file__)), "drivers.json")
LOG_FILE = os.path.join(os.path.dirname(os.path.realpath(__file__)), "mei-git.log")

# --- Funções utilitárias ---
def log(msg):
    time_stamp = datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")
    entry = f"{time_stamp} {msg}"
    print(entry)
    with open(LOG_FILE, "a") as f:
        f.write(entry + "\n")

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT).decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8').strip()

def check_internet():
    try:
        subprocess.check_output("ping -c 1 github.com", shell=True, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

# --- Detecção robusta de hardware ---
def detect_hardware():
    log("Detectando hardware...")
    pci_output = run_cmd("lspci -nnk")
    usb_output = run_cmd("lsusb")

    # Keywords Wi-Fi
    wifi_keywords = ["Wireless", "Network controller", "Wi-Fi", "WLAN",
                     "RTL8811AU", "AC600", "RTL8188", "RTL8192", "Realtek", "Intel", "Broadcom"]
    # Keywords Bluetooth
    bt_keywords = ["Bluetooth", "BT", "BlueZ", "RTL", "Intel", "Broadcom"]

    # Wi-Fi
    wifi_hw = [line for line in pci_output.splitlines() if any(k.lower() in line.lower() for k in wifi_keywords)]
    wifi_hw += [line for line in usb_output.splitlines() if any(k.lower() in line.lower() for k in wifi_keywords)]

    # Bluetooth
    bt_hw = [line for line in pci_output.splitlines() if any(k.lower() in line.lower() for k in bt_keywords)]
    bt_hw += [line for line in usb_output.splitlines() if any(k.lower() in line.lower() for k in bt_keywords)]

    log(f"Wi-Fi detectado: {wifi_hw if wifi_hw else 'Nenhum'}")
    log(f"Bluetooth detectado: {bt_hw if bt_hw else 'Nenhum'}")
    return wifi_hw, bt_hw

# --- Drivers ---
def is_driver_loaded(module):
    # Checa lsmod
    if module in run_cmd("lsmod"):
        return True
    # Checa se driver existe no kernel
    driver_path = f"/lib/modules/{run_cmd('uname -r')}/kernel/drivers/"
    if any(module in root for root, dirs, files in os.walk(driver_path) for file in files):
        return True
    return False

def install_driver(repo, module):
    tmp_dir = "/tmp/mei_driver"
    if os.path.exists(tmp_dir):
        run_cmd(f"rm -rf {tmp_dir}")
    if not check_internet():
        log(f"Sem internet. Não é possível clonar {repo}")
        return
    log(f"Clonando repo: {repo}")
    run_cmd(f"git clone {repo} {tmp_dir}")
    os.chdir(tmp_dir)
    if os.path.exists("Makefile"):
        log(f"Compilando driver {module}...")
        print(run_cmd("make"))
        log(f"Instalando driver {module}...")
        run_cmd(f"sudo make install")
        log(f"Driver {module} instalado!")
    else:
        log(f"Makefile não encontrado para {module}. Instale manualmente.")
    run_cmd(f"rm -rf {tmp_dir}")

def identify_fabricante(hw_list):
    for line in hw_list:
        if "Realtek" in line or "RTL" in line:
            return "Realtek"
        elif "Intel" in line:
            return "Intel"
        elif "Broadcom" in line or "BCM" in line:
            return "Broadcom"
    return "Generic"

# --- Seleção de dispositivo ---
def choose_device(devices, dev_type):
    if len(devices) == 1:
        return devices[0]
    print(f"Encontrados {len(devices)} dispositivos {dev_type}:")
    for i, d in enumerate(devices, 1):
        print(f"{i}) {d}")
    choice = input(f"Escolha qual deseja instalar [1-{len(devices)}] ou 'all' para todos: ").strip().lower()
    if choice == "all":
        return devices
    try:
        idx = int(choice) - 1
        return devices[idx]
    except:
        print("Escolha inválida, pulando...")
        return None

# --- CLI ---
def main():
    if len(sys.argv) < 3 or sys.argv[1] != "install":
        print("Uso: mei-git install [wifi|bluetooth]")
        sys.exit(1)

    targets = sys.argv[2:]
    wifi_hw, bt_hw = detect_hardware()

    # Carrega drivers
    with open(DRIVERS_FILE) as f:
        drivers = json.load(f)

    for t in targets:
        if t == "wifi":
            if not wifi_hw:
                log("Nenhum Wi-Fi detectado")
                continue
            devices = choose_device(wifi_hw, "Wi-Fi")
            if not devices:
                continue
            if isinstance(devices, str):
                devices = [devices]
            for d in devices:
                fab = identify_fabricante([d])
                module = drivers["wifi"].get(fab, drivers["wifi"]["Generic"])["module"]
                if is_driver_loaded(module):
                    log(f"Driver Wi-Fi ({module}) já carregado")
                else:
                    ans = input(f"O driver {module} para Wi-Fi não está carregado. Deseja instalar? [S/n]: ").strip().lower()
                    if ans in ["s", ""]:
                        install_driver(drivers["wifi"].get(fab, drivers["wifi"]["Generic"])["repo"], module)
                    else:
                        log(f"Instalação de Wi-Fi cancelada pelo usuário.")
        elif t == "bluetooth":
            if not bt_hw:
                log("Nenhum Bluetooth detectado")
                continue
            devices = choose_device(bt_hw, "Bluetooth")
            if not devices:
                continue
            if isinstance(devices, str):
                devices = [devices]
            for d in devices:
                fab = identify_fabricante([d])
                module = drivers["bluetooth"].get(fab, drivers["bluetooth"]["Generic"])["module"]
                if is_driver_loaded(module):
                    log(f"Driver Bluetooth ({module}) já carregado")
                else:
                    ans = input(f"O driver {module} para Bluetooth não está carregado. Deseja instalar? [S/n]: ").strip().lower()
                    if ans in ["s", ""]:
                        install_driver(drivers["bluetooth"].get(fab, drivers["bluetooth"]["Generic"])["repo"], module)
                    else:
                        log(f"Instalação de Bluetooth cancelada pelo usuário.")
        else:
            log(f"Tipo de driver desconhecido: {t}")

if __name__ == "__main__":
    main()

