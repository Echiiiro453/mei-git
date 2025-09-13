#!/bin/bash

# setup.sh - v6.7 - Instalador universal para MEI Git
# Com suporte a Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro/EndeavourOS, openSUSE
# Inclui fix para python-pythondialog no Arch (AUR)

# --- Segurança: precisa de root ---
if [ "$EUID" -ne 0 ]; then
  echo "?? Erro: Este script precisa ser executado com privilégios de root."
  echo "   Use: sudo ./setup.sh"
  exit 1
fi

export LANG=C.UTF-8
LOG_FILE="/tmp/mei-git-setup.log"
> "$LOG_FILE"

# --- Funções auxiliares ---
install_dialog_if_missing() {
    if ! command -v dialog &>/dev/null; then
        echo "???? Instalando pacote 'dialog'..."
        if command -v apt-get &>/dev/null; then
            apt-get update -qq && apt-get install -y -qq dialog
        elif command -v dnf &>/dev/null; then
            dnf install -y dialog
        elif command -v pacman &>/dev/null; then
            pacman -S --noconfirm dialog
        elif command -v zypper &>/dev/null; then
            zypper install -y dialog
        fi
    fi
}

show_message() {
    if command -v dialog &>/dev/null; then
        dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 12 78
    else
        echo -e "\n$1\n"
    fi
}

ask_yes_no() {
    if command -v dialog &>/dev/null; then
        dialog --title "Confirmação" --cr-wrap --yesno "$1" 12 78
        return $?
    else
        read -p "$1 [S/n] " choice
        case "$choice" in
            [sS][iI][mM]|[sS]|"") return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# --- Instalação por família ---
run_install_debian_family() {
    PACKAGES=("git" "dkms" "build-essential" "linux-headers-$(uname -r)" "python3-dialog")
    apt-get update
    apt-get install -y "${PACKAGES[@]}"
}

run_install_fedora_family() {
    dnf install -y git dkms "kernel-devel-$(uname -r)" python3-dialog
    dnf groupinstall -y "Development Tools"
}

run_install_arch_family() {
    OFFICIAL_PACKAGES="git dkms base-devel linux-headers dialog"
    AUR_PACKAGE="python-pythondialog"

    echo "???? Instalando pacotes oficiais do Arch..."
    pacman -Syu --noconfirm --needed $OFFICIAL_PACKAGES

    # Verifica se python-pythondialog está instalado
    if ! pacman -Q "$AUR_PACKAGE" &>/dev/null; then
        echo "???? Pacote '$AUR_PACKAGE' não encontrado nos repositórios oficiais."
        if command -v yay &>/dev/null; then
            if ask_yes_no "Deseja instalar '$AUR_PACKAGE' do AUR com yay?"; then
                sudo -u "$SUDO_USER" yay -S --noconfirm "$AUR_PACKAGE"
            fi
        else
            echo "???? 'yay' não encontrado. Instale manualmente o pacote AUR:"
            echo "   git clone https://aur.archlinux.org/$AUR_PACKAGE.git"
            echo "   cd $AUR_PACKAGE && makepkg -si"
        fi
    fi
}

run_install_opensuse_family() {
    zypper install -y git dkms make gcc kernel-devel python3-dialog
}

# --- Main ---
main() {
    install_dialog_if_missing
    show_message "Bem-vindo ao instalador de dependências do MEI Git!"
    if ! ask_yes_no "Deseja continuar a instalação?"; then
        show_message "Instalação cancelada."
        exit 0
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        show_message "?? Não foi possível detectar a distribuição."
        exit 1
    fi

    echo "???? Detectado: $PRETTY_NAME"

    case "$OS" in
        # Debian/Ubuntu family
        "ubuntu"|"debian"|"linuxmint"|"pop"|"zorin"|"deepin"|"mx"|"kali"|"neon")
            run_install_debian_family
            ;;
        # Fedora/RHEL family
        "fedora"|"rhel"|"centos"|"rocky"|"almalinux"|"clearos")
            run_install_fedora_family
            ;;
        # Arch family
        "arch"|"manjaro"|"endeavouros"|"garuda"|"arco")
            run_install_arch_family
            ;;
        # openSUSE family
        "opensuse-tumbleweed"|"opensuse-leap")
            run_install_opensuse_family
            ;;
        *)
            show_message "???? Distribuição '$OS' não suportada automaticamente.\n\
Instale manualmente: git dkms build-essential (ou base-devel) linux-headers python3-dialog"
            ;;
    esac

    echo "=================================================================="
    echo "?? Setup concluído!"
    echo ""
    echo "Crie o comando global com:"
    echo "   sudo ln -sf \"\$(pwd)/mei-git\" /usr/local/bin/mei-git"
    echo "=================================================================="
}

main
