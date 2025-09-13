#!/bin/bash

# setup.sh - Instala dependências essenciais para o MEI Git

echo "🚀 Iniciando setup do MEI Git..."

# Função para detectar a distribuição
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "❌ Não foi possível detectar a distribuição. Instale as dependências manualmente."
        exit 1
    fi
}

# Função para perguntar sim/não
ask_yes_no() {
    local prompt="$1"
    read -p "$prompt (s/n): " yn
    case $yn in
        [Ss]*) return 0 ;;
        *) return 1 ;;
    esac
}

# Instalação para Debian/Ubuntu
run_install_debian_family() {
    PACKAGES="git dkms build-essential linux-headers-$(uname -r) python3-dialog"
    sudo apt-get update
    sudo apt-get install -y $PACKAGES
}

# Instalação para Fedora/RHEL/CentOS
run_install_fedora_family() {
    PACKAGES="git dkms kernel-devel kernel-headers python3-dialog"
    sudo dnf install -y $PACKAGES
}

# Instalação para openSUSE
run_install_opensuse_family() {
    PACKAGES="git dkms kernel-devel kernel-headers python3-dialog"
    sudo zypper install -y $PACKAGES
}

# Instalação para Arch/Manjaro
run_install_arch_family() {
    OFFICIAL_PACKAGES="git dkms base-devel linux-headers dialog"
    AUR_PACKAGE="python-pythondialog"
    COMMAND="pacman -Syu --noconfirm --needed $OFFICIAL_PACKAGES"

    echo "📦 Instalando pacotes oficiais: $OFFICIAL_PACKAGES"
    eval $COMMAND
    INSTALL_STATUS=$?
    echo $INSTALL_STATUS > /tmp/mei-git-status.txt

    # Agora cuida do pacote do AUR
    if ! pacman -Q "$AUR_PACKAGE" &> /dev/null; then
        if command -v yay &> /dev/null; then
            if ask_yes_no "A dependência '$AUR_PACKAGE' do AUR é necessária. Deseja instalar com 'yay'?"; then
                sudo -u $SUDO_USER yay -S --noconfirm "$AUR_PACKAGE"
            fi
        else
            if ask_yes_no "O pacote '$AUR_PACKAGE' precisa do AUR. Deseja instalar o helper 'yay' automaticamente?"; then
                sudo -u $SUDO_USER bash -c "
                    git clone https://aur.archlinux.org/yay.git /tmp/yay &&
                    cd /tmp/yay &&
                    makepkg -si --noconfirm
                "
                if command -v yay &> /dev/null; then
                    sudo -u $SUDO_USER yay -S --noconfirm "$AUR_PACKAGE"
                fi
            else
                declare -g YAY_MISSING_GLOBAL=true
            fi
        fi
    fi
}

# --- Lógica Principal ---
detect_distro

case "$OS" in
    "ubuntu" | "debian" | "linuxmint")
        run_install_debian_family
        ;;
    "fedora" | "rhel" | "centos")
        run_install_fedora_family
        ;;
    "arch" | "manjaro")
        run_install_arch_family
        ;;
    "opensuse-tumbleweed" | "opensuse-leap")
        run_install_opensuse_family
        ;;
    *)
        echo "⚠️ Distribuição '$OS' não suportada por este script."
        echo "Por favor, instale manualmente: git dkms build-essential linux-headers python3-dialog"
        ;;
esac

if [ "$YAY_MISSING_GLOBAL" = true ]; then
    echo "⚠️ O pacote 'python-pythondialog' não foi instalado porque você recusou instalar o 'yay'."
    echo "   Instale manualmente com: yay -S python-pythondialog"
fi

echo "✅ Setup concluído! O MEI Git está pronto para ser usado."
echo "   Use 'sudo ln -sf \$(pwd)/mei_git.py /usr/local/bin/mei-git' para criar o comando global."
