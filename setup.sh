#!/bin/bash

# setup.sh - v4.1 com interface interativa e suporte multi-distro completo

# --- Verificação e Instalação do 'dialog' ---
# Primeiro, checa se o 'dialog' está disponível para uma experiência melhor
if ! command -v dialog &> /dev/null; then
    echo "???? O pacote 'dialog' não foi encontrado. Tentando instalar para uma melhor experiência..."
    # A maioria das distros usa o mesmo nome de pacote 'dialog'
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y dialog
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y dialog
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm dialog
    fi
    
    if [ $? -ne 0 ]; then
        echo "???? Falha ao instalar o 'dialog'. O script continuará em modo texto simples."
    fi
fi

# --- Funções de Interface ---
# Funções para mostrar mensagens e fazer perguntas, usando 'dialog' se disponível

show_message() {
    if command -v dialog &> /dev/null; then
        dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 10 70
    else
        echo -e "\n$1\n" # Fallback para modo texto
    fi
}

ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirmação" --yesno "$1" 10 70
        return $? # Retorna 0 para Sim, 1 para Não
    else
        read -p "$1 [S/n] " choice
        case "$choice" in
            [sS][iI][mM]|[sS]|"") return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# --- Lógica Principal do Script ---

show_message "Bem-vindo ao instalador de dependências do MEI Git!\\n\\nEste script irá preparar seu sistema para compilar e instalar drivers."

if ask_yes_no "O script irá detectar sua distribuição e instalar os pacotes necessários (como git, dkms, build-essential, etc.).\\n\\nDeseja continuar?"; then
    
    # Detecção de Distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        show_message "?? Não foi possível detectar a distribuição. Instale as dependências manualmente."
        exit 1
    fi

    # Lógica de Instalação Multi-distro Completa
    echo "???? Detectada distro: $OS. Preparando para instalar pacotes..."
    
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            PACKAGES="git dkms build-essential linux-headers-$(uname -r)"
            COMMAND="sudo apt-get update && sudo apt-get install -y $PACKAGES"
            ;;
        "fedora" | "rhel" | "centos")
            PACKAGES="git dkms kernel-devel"
            COMMAND="sudo dnf install -y $PACKAGES && sudo dnf groupinstall -y \"Development Tools\""
            ;;
        "arch" | "endeavouros" | "manjaro")
            PACKAGES="git dkms base-devel linux-headers"
            COMMAND="sudo pacman -Syu --noconfirm $PACKAGES"
            ;;
        "opensuse-tumbleweed" | "opensuse-leap")
            PACKAGES="git dkms patterns-devel-base-devel_basis kernel-default-devel"
            COMMAND="sudo zypper install -y $PACKAGES"
            ;;
        "void")
            PACKAGES="git dkms base-devel linux-headers"
            COMMAND="sudo xbps-install -Syu $PACKAGES"
            ;;
        "solus")
            PACKAGES="git dkms linux-current-headers system.devel"
            COMMAND="sudo eopkg it -y $PACKAGES"
            ;;
        *)
            show_message "?? Distribuição '$OS' não suportada por este script.\\n\\nPor favor, instale os pacotes equivalentes a: git, dkms, build-essential, linux-headers."
            exit 1
            ;;
    esac

    echo "   Executando o comando de instalação..."
    
    # Executa o comando de instalação definido
    eval $COMMAND

    if [ $? -ne 0 ]; then
        show_message "?? Falha na instalação das dependências. Verifique os erros no terminal."
        exit 1
    fi

    show_message "?? Dependências instaladas com sucesso!\\n\\nO MEI Git está pronto para ser usado. Lembre-se de criar o comando global com 'sudo ln ...' se ainda não o fez."

else
    show_message "Instalação cancelada pelo usuário."
    exit 0
fi