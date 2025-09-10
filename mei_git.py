#!/usr/bin/env python3
import subprocess
import re
import sys # Importar a biblioteca 'sys' para ler os argumentos

def run_cmd(cmd):
    """Executa um comando no shell e retorna a saída."""
    return subprocess.getoutput(cmd)

def detect_hardware():
    """Detecta o hardware, exibe um resumo e salva um log completo."""
    print("🔍 Detectando hardware... (log completo em /tmp/mei-hw.log)")
    pci_output = run_cmd("lspci -nnk")
    usb_output = run_cmd("lsusb")
    # Usamos set para uma busca mais rápida
    loaded_modules = set(line.split()[0] for line in run_cmd("lsmod").splitlines()[1:])

    # ======== LISTAS DE KEYWORDS POR CATEGORIA ========
    # Mapeia palavras-chave para o nome do fabricante principal
    device_map = {
        "wifi": ["Wireless", "Wi-Fi", "WLAN", "RTL", "BCM", "Atheros", "QCA", "MT76", "Mediatek", "Ralink", "Intel"],
        "bluetooth": ["Bluetooth", "Intel", "Realtek", "Broadcom", "Qualcomm", "Cypress", "BT"],
        "ethernet": ["Ethernet", "Realtek", "Intel", "Broadcom", "Qualcomm", "Marvell", "Atheros", "Killer", "Mellanox"],
        "audio": ["Audio device", "HD Audio", "Realtek", "Intel", "NVIDIA", "AMD", "Creative"],
        "video": ["VGA compatible controller", "3D controller", "Display", "NVIDIA", "AMD", "ATI", "Intel"]
    }

    # ======== SUGESTÕES DE DRIVERS ========
    # Mapeia um nome de fabricante para os possíveis módulos do kernel
    driver_suggestions = {
        "Realtek": ["r8168", "r8169", "rtlwifi", "btusb"],
        "Intel": ["iwlwifi", "e1000e", "btintel", "snd_hda_intel"],
        "Broadcom": ["broadcom-wl", "b43", "brcmsmac", "bcm5974"],
        "Atheros": ["ath9k", "ath10k"],
        "Qualcomm": ["ath10k", "ath11k"],
        "Mediatek": ["mt76"],
        "Ralink": ["rt2800usb", "rt2870sta"],
        "NVIDIA": ["nvidia", "nouveau"],
        "AMD": ["amdgpu", "radeon"],
        "Creative": ["snd_emu10k1"],
        "Cypress": ["btusb"],
        "Mellanox": ["mlx4_en", "mlx5_core"],
        "Killer": ["ath10k", "alx"]
    }

    def get_main_vendor(line):
        """Identifica o fabricante principal na linha do dispositivo."""
        for vendor in driver_suggestions:
            if vendor.lower() in line.lower():
                return vendor
        return None

    def is_module_loaded(vendor):
        """Checa se algum módulo do fabricante está no lsmod."""
        if vendor and vendor in driver_suggestions:
            for module_name in driver_suggestions[vendor]:
                if module_name in loaded_modules:
                    return True
        return False

    def process_device_line(line):
        """Processa uma linha de lspci/lsusb e retorna a string formatada."""
        # Extrai VendorID:DeviceID com segurança
        vendor_match = re.search(r'\[(\w{4}:\w{4})\]', line)
        id_str = f" [ID: {vendor_match.group(1)}]" if vendor_match else ""
        
        main_vendor = get_main_vendor(line)

        if main_vendor:
            drivers = "/".join(driver_suggestions[main_vendor])
            status = "✅ Carregado" if is_module_loaded(main_vendor) else "❌ Não carregado"
            return f"{line.strip()}{id_str}\n      💡 Sugestão: {drivers} | Status: {status}"
        else:
            return f"{line.strip()}{id_str}\n      💡 Sugestão: Driver desconhecido, pesquise pelo ID."

    # ======== DETECÇÃO E AGRUPAMENTO ========
    hardware = {cat: [] for cat in device_map}
    
    # Processa PCI e USB
    full_output = pci_output + "\n" + usb_output
    for line in full_output.splitlines():
        for category, keywords in device_map.items():
            if any(k.lower() in line.lower() for k in keywords):
                hardware[category].append(process_device_line(line))
                break # Evita que um dispositivo seja classificado em múltiplas categorias
    
    hardware["usb"] = usb_output.splitlines()

    # ======== PRINT BONITO ========
    log_content = ""
    print("-" * 50)
    for title, hw_list in hardware.items():
        if title == 'usb': continue # Mostra USB por último e de forma simples
        print(f"📌 {title.capitalize()}:")
        if hw_list:
            for d in hw_list:
                print(f"    - {d}\n")
            log_content += f"## {title.capitalize()}\n" + "\n".join(hw_list) + "\n\n"
        else:
            print("    Nenhum dispositivo detectado.\n")

    # Mostra USB de forma simples
    print(f"📌 USB:")
    if hardware["usb"]:
        for d in hardware["usb"]:
            print(f"    - {d}")
    else:
        print("    Nenhum dispositivo detectado.")
    print("-" * 50)


    # Salva log completo
    with open("/tmp/mei-hw.log", "w") as f:
        f.write("==== SAÍDA BRUTA PCI ====\n")
        f.write(pci_output + "\n\n")
        f.write("==== SAÍDA BRUTA USB ====\n")
        f.write(usb_output + "\n\n")
        f.write("==== HARDWARE DETECTADO E PROCESSADO ====\n")
        f.write(log_content)
        f.write("## USB (Bruto)\n" + "\n".join(hardware["usb"]))
    
    print("\n📂 Log completo com detalhes técnicos salvo em /tmp/mei-hw.log")


def main():
    """Função principal para controlar o script via linha de comando."""
    # sys.argv é a lista de argumentos. sys.argv[0] é o nome do script.
    args = sys.argv[1:]

    if not args:
        print("Uso: mei-git <comando>")
        print("Comandos disponíveis: scan")
        sys.exit(1)

    command = args[0]

    if command == "scan":
        detect_hardware()
    # Futuramente, você pode adicionar outros comandos aqui
    # elif command == "install":
    #     package = args[1]
    #     install_driver(package)
    else:
        print(f"Comando desconhecido: '{command}'")
        print("Use 'mei-git scan' para detectar o hardware.")
        sys.exit(1)


if __name__ == "__main__":
    main()

