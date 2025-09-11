#!/bin/bash

# setup.sh - v4.1 com interface interativa e suporte multi-distro completo

# --- Verifica��o e Instala��o do 'dialog' ---
# Primeiro, checa se o 'dialog' est� dispon�vel para uma experi�ncia melhor
if ! command -v dialog &> /dev/null; then
    echo "???? O pacote 'dialog' n�o foi encontrado. Tentando instalar para uma melhor experi�ncia..."
    # A maioria das distros usa o mesmo nome de pacote 'dialog'
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y dialog
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y dialog
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm dialog
    fi
    
    if [ $? -ne 0 ]; then
        echo "???? Falha ao instalar o 'dialog'. O script continuar� em modo texto simples."
    fi
fi

# --- Fun��es de Interface ---
# Fun��es para mostrar mensagens e fazer perguntas, usando 'dialog' se dispon�vel

show_message() {
    if command -v dialog &> /dev/null; then
        dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 10 70
    else
        echo -e "\n$1\n" # Fallback para modo texto
    fi
}

ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirma��o" --yesno "$1" 10 70
        return $? # Retorna 0 para Sim, 1 para N�o
    else
        read -p "$1 [S/n] " choice
        case "$choice" in
            [sS][iI][mM]|[sS]|"") return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# --- L�gica Principal do Script ---

show_message "Bem-vindo ao instalador de depend�ncias do MEI Git!\\n\\nEste script ir� preparar seu sistema para compilar e instalar drivers."

if ask_yes_no "O script ir� detectar sua distribui��o e instalar os pacotes necess�rios (como git, dkms, build-essential, etc.).\\n\\nDeseja continuar?"; then
    
    # Detec��o de Distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        show_message "?? N�o foi poss�vel detectar a distribui��o. Instale as depend�ncias manualmente."
        exit 1
    fi

    # L�gica de Instala��o Multi-distro Completa
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
            show_message "?? Distribui��o '$OS' n�o suportada por este script.\\n\\nPor favor, instale os pacotes equivalentes a: git, dkms, build-essential, linux-headers."
            exit 1
            ;;
    esac

    echo "   Executando o comando de instala��o..."
    
    # Executa o comando de instala��o definido
    eval $COMMAND

    if [ $? -ne 0 ]; then
        show_message "?? Falha na instala��o das depend�ncias. Verifique os erros no terminal."
        exit 1
    fi

    show_message "?? Depend�ncias instaladas com sucesso!\\n\\nO MEI Git est� pronto para ser usado. Lembre-se de criar o comando global com 'sudo ln ...' se ainda n�o o fez."

else
    show_message "Instala��o cancelada pelo usu�rio."
    exit 0
fi