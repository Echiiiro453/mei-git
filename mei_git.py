#!/usr/bin/env python3
import subprocess
import os
import sys
import json

DRIVERS_FILE = "drivers.json"

# --- Funções utilitárias ---
def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT).decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8').strip()

# --- Detecção robusta de hardware ---
def detect_hardware():
    print("Detectando hardware...")
    pci_output = run_cmd("lspci -nnk")
    usb_output = run_cmd("lsusb")

    # Wi-Fi
    wifi_keywords = ["Wireless", "Network controller", "Wi-Fi", "WLAN"]
    wifi_hw = [line for line in pci_output.splitlines() if any(k.lower() in line.lower() for k in wifi_keywords)]

    # Bluetooth
    bt_keywords = ["Bluetooth", "BT", "BlueZ"]
    bt_hw = [line for line in pci_output.splitlines() if any(k.lower() in line.lower() for k in bt_keywords)]
    bt_hw += [line for line in usb_output.splitlines() if any(k.lower() in line.lower() for k in bt_keywords)]

    print(f"Wi-Fi detectado: {wifi_hw if wifi_hw else 'Nenhum'}")
    print(f"Bluetooth detectado: {bt_hw if bt_hw else 'Nenhum'}")
    return wifi_hw, bt_hw

def is_driver_loaded(module):
    return module in run_cmd("lsmod")

def install_driver(repo, module):
    tmp_dir = "/tmp/mei_driver"
    if os.path.exists(tmp_dir):
        run_cmd(f"rm -rf {tmp_dir}")
    print(f"Clonando repo: {repo}")
    run_cmd(f"git clone {repo} {tmp_dir}")
    os.chdir(tmp_dir)
    if os.path.exists("Makefile"):
        print("Compilando driver...")
        print(run_cmd("make"))
        print("Instalando driver...")
        run_cmd(f"sudo make install")
        print(f"Driver {module} instalado!")
    else:
        print("Makefile não encontrado. Instale manualmente.")
    run_cmd(f"rm -rf {tmp_dir}")

def identify_fabricante(hw_list, hw_type):
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
                print("Nenhum Wi-Fi detectado")
                continue
            fab = identify_fabricante(wifi_hw, "wifi")
            module = drivers["wifi"][fab]["module"]
            if is_driver_loaded(module):
                print(f"Driver Wi-Fi ({module}) já carregado")
            else:
                install_driver(drivers["wifi"][fab]["repo"], module)
        elif t == "bluetooth":
            if not bt_hw:
                print("Nenhum Bluetooth detectado")
                continue
            fab = identify_fabricante(bt_hw, "bluetooth")
            module = drivers["bluetooth"][fab]["module"]
            if is_driver_loaded(module):
                print(f"Driver Bluetooth ({module}) já carregado")
            else:
                install_driver(drivers["bluetooth"][fab]["repo"], module)
        else:
            print(f"Tipo de driver desconhecido: {t}")

if __name__ == "__main__":
    main()

