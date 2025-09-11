#!/bin/bash

# setup.sh - v4 com interface interativa usando 'dialog'

# --- Verificação e Instalação do 'dialog' ---
if ! command -v dialog &> /dev/null; then
    echo "???? O pacote 'dialog' não foi encontrado. Tentando instalar..."
    sudo apt-get update && sudo apt-get install -y dialog
    if [ $? -ne 0 ]; then
        echo "?? Falha ao instalar o 'dialog'. O script continuará em modo texto."
    fi
fi

# --- Funções com 'dialog' (se disponível) ---
show_message() {
    if command -v dialog &> /dev/null; then
        dialog --title "MEI Git Setup" --msgbox "$1" 10 60
    else
        echo "$1" # Fallback para modo texto
    fi
}

ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirmação" --yesno "$1" 10 60
        return $? # Retorna 0 para Sim, 1 para Não
    else
        read -p "$1 [S/n] " choice
        case "$choice" in
            [sS][iI][mM]|[sS]|"") return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# --- Lógica Principal ---

show_message "Bem-vindo ao instalador de dependências do MEI Git! Este script irá preparar seu sistema para usar a ferramenta."

if ask_yes_no "As seguintes dependências serão instaladas: git, dkms, build-essential e linux-headers. Deseja continuar?"; then
    
    # Detecção de Distro e Instalação (código que já tínhamos)
    . /etc/os-release
    OS=$ID
    
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            PACKAGES="git dkms build-essential linux-headers-$(uname -r)"
            COMMAND="sudo apt-get update && sudo apt-get install -y $PACKAGES"
            ;;
        # ... (outros casos para Fedora, Arch, etc.)
        *)
            show_message "?? Distribuição '$OS' não suportada. Instale os pacotes manualmente."
            exit 1
            ;;
    esac

    echo "???? Instalando pacotes para '$OS'..."
    eval $COMMAND

    if [ $? -ne 0 ]; then
        show_message "?? Falha na instalação das dependências. Verifique os erros no terminal."
        exit 1
    fi

    show_message "?? Dependências instaladas com sucesso! O MEI Git está pronto para ser usado. Lembre-se de criar o comando global."

else
    show_message "Instalação cancelada pelo usuário."
    exit 1
fi