#!/bin/bash

# setup.sh - v4.2 - Mais robusto, com melhorias de compatibilidade e interface

# Força o locale para UTF-8 para garantir que acentos e caracteres especiais funcionem
export LANG=C.UTF-8

# --- Verificação e Instalação do 'dialog' ---
if ! command -v dialog &> /dev/null; then
    echo "???? O pacote 'dialog' nao foi encontrado. Tentando instalar para uma melhor experiencia..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y dialog
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y dialog
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm dialog
    fi
    
    if [ $? -ne 0 ]; then
        echo "???? Falha ao instalar o 'dialog'. O script continuara em modo texto simples."
    fi
fi

# --- Funções de Interface ---
show_message() {
    if command -v dialog &> /dev/null; then
        # --cr-wrap quebra as linhas automaticamente
        dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 12 75
    else
        echo -e "\n$1\n"
    fi
}

ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirmacao" --cr-wrap --yesno "$1" 12 75
        return $?
    else
        read -p "$1 [S/n] " choice
        case "$choice" in
            [sS][iI][mM]|[sS]|"") return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# --- Lógica Principal do Script ---

show_message "Bem-vindo ao instalador de dependencias do MEI Git!\\n\\nEste script ira preparar seu sistema para compilar e instalar drivers."

if ask_yes_no "O script ira detectar sua distribuicao e instalar os pacotes necessarios (como git, dkms, build-essential, etc.).\\n\\nDeseja continuar?"; then
    
    # Detecção de Distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        show_message "?? Nao foi possivel detectar a distribuicao. Instale as dependencias manualmente."
        exit 1
    fi

    # Lógica de Instalação Multi-distro
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
        # Adicione outros casos aqui se necessário
        *)
            show_message "?? Distribuicao '$OS' nao suportada por este script.\\n\\nPor favor, instale os pacotes equivalentes a: git, dkms, build-essential, linux-headers."
            exit 1
            ;;
    esac

    echo "   Executando o comando de instalacao..."
    eval $COMMAND

    if [ $? -ne 0 ]; then
        show_message "?? Falha na instalacao das dependencias. Verifique os erros no terminal."
        exit 1
    fi

    show_message "?? Dependencias instaladas com sucesso!\\n\\nO MEI Git esta pronto para ser usado. Lembre-se de criar o comando global com 'sudo ln ...' se ainda nao o fez."

else
    show_message "Instalacao cancelada pelo usuario."
    exit 0
fi