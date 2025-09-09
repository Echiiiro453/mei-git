#!/usr/bin/env python3
import subprocess, os, sys, json

DRIVERS_FILE = "drivers.json"

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT).decode('utf-8').strip()
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8').strip()

def detect_hardware():
    pci = run_cmd("lspci")
    usb = run_cmd("lsusb")
    wifi = [line for line in pci.splitlines() if "Wireless" in line or "Network controller" in line]
    bt = [line for line in usb.splitlines() if "Bluetooth" in line]
    return wifi, bt

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
    # Simples heurística, você pode expandir com regex por PCI ID
    for line in hw_list:
        if "Realtek" in line:
            return "Realtek"
        elif "Intel" in line:
            return "Intel"
        elif "Broadcom" in line:
            return "Broadcom"
    return "Generic"

def main():
    if len(sys.argv) < 3 or sys.argv[1] != "install":
        print("Uso: mei-git install [wifi|bluetooth]")
        sys.exit(1)

    targets = sys.argv[2:]
    wifi_hw, bt_hw = detect_hardware()
    
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
