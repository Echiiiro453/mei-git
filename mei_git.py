import subprocess

def run_cmd(cmd):
    return subprocess.getoutput(cmd)

def detect_hardware():
    print("🔍 Detectando hardware...")
    pci_output = run_cmd("lspci -nnk")
    usb_output = run_cmd("lsusb")
    loaded_modules = run_cmd("lsmod").splitlines()

    # ======== LISTAS DE KEYWORDS POR CATEGORIA ========
    wifi_keywords = ["Wireless", "Wi-Fi", "WLAN", "RTL8811AU", "RTL8812AU", "RTL8821AU", "RTL8192",
                     "BCM43", "BCM435", "BCM436", "BCM43XX", "Atheros", "QCA", "MT76", "Mediatek",
                     "Ralink", "RT73", "RT3070", "RT5370"]
    bt_keywords = ["Bluetooth", "BT", "BCM", "Intel", "Realtek", "Qualcomm", "Cypress"]
    eth_keywords = ["Ethernet controller", "Realtek", "Intel", "Broadcom", "Qualcomm", "Marvell",
                    "Atheros", "Killer", "Mellanox"]
    audio_keywords = ["Audio device", "HD Audio", "VGA Audio", "Realtek", "Intel", "NVIDIA",
                      "AMD", "Creative", "Sound Blaster"]
    video_keywords = ["VGA compatible controller", "3D controller", "Display controller",
                      "NVIDIA", "AMD", "ATI", "Intel", "Matrox", "VIA", "SiS"]

    driver_suggestions = {
        "Realtek": "rtl*_driver ou r8169/r8168",
        "Intel": "intel_*_driver",
        "Broadcom": "broadcom-wl ou b43/b43legacy",
        "Atheros": "ath9k/ath10k",
        "Qualcomm": "ath10k",
        "Mediatek": "mt76",
        "Ralink": "rt2800usb/rt2870sta",
        "NVIDIA": "nvidia-driver",
        "AMD": "amdgpu ou radeon",
        "Creative": "snd-*_pcm",
        "Cypress": "cypress_bt_driver",
        "Mellanox": "mlx4/mlx5",
        "Killer": "alx/atl1c"
    }

    def filter_hw(lines, keywords):
        result = []
        for line in lines.splitlines():
            matched_driver = None
            for k in keywords:
                if k in line:
                    matched_driver = driver_suggestions.get(k.split()[0], None)
                    break
            if matched_driver:
                loaded = any(m in line for m in loaded_modules)
                status = "carregado no kernel" if loaded else "não carregado"
                result.append(f"{line} [Driver sugerido: {matched_driver}, {status}]")
            else:
                # Nenhum driver conhecido
                result.append(f"{line} [Driver desconhecido, pesquisar]")
        return result

    wifi_hw = filter_hw(pci_output, wifi_keywords) + filter_hw(usb_output, wifi_keywords)
    bt_hw = filter_hw(pci_output, bt_keywords) + filter_hw(usb_output, bt_keywords)
    eth_hw = filter_hw(pci_output, eth_keywords)
    audio_hw = filter_hw(pci_output, audio_keywords)
    video_hw = filter_hw(pci_output, video_keywords)
    usb_hw = usb_output.splitlines()  # lista todos os USBs

    def print_hw(title, hw_list):
        if hw_list:
            print(f"📌 {title}:")
            for d in hw_list:
                print(f"    - {d}")
        else:
            print(f"📌 {title}: Nenhum detectado")

    print_hw("Wi-Fi", wifi_hw)
    print_hw("Bluetooth", bt_hw)
    print_hw("Ethernet", eth_hw)
    print_hw("Audio", audio_hw)
    print_hw("Video", video_hw)
    print_hw("USB", usb_hw)

    return wifi_hw, bt_hw, eth_hw, audio_hw, video_hw, usb_hw

# Rodar detecção
detect_hardware()

