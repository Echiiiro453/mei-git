#!/bin/bash

# setup.sh - v4 com interface interativa usando 'dialog'

# --- Verifica��o e Instala��o do 'dialog' ---
if ! command -v dialog &> /dev/null; then
    echo "???? O pacote 'dialog' n�o foi encontrado. Tentando instalar..."
    sudo apt-get update && sudo apt-get install -y dialog
    if [ $? -ne 0 ]; then
        echo "?? Falha ao instalar o 'dialog'. O script continuar� em modo texto."
    fi
fi

# --- Fun��es com 'dialog' (se dispon�vel) ---
show_message() {
    if command -v dialog &> /dev/null; then
        dialog --title "MEI Git Setup" --msgbox "$1" 10 60
    else
        echo "$1" # Fallback para modo texto
    fi
}

ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirma��o" --yesno "$1" 10 60
        return $? # Retorna 0 para Sim, 1 para N�o
    else
        read -p "$1 [S/n] " choice
        case "$choice" in
            [sS][iI][mM]|[sS]|"") return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# --- L�gica Principal ---

show_message "Bem-vindo ao instalador de depend�ncias do MEI Git! Este script ir� preparar seu sistema para usar a ferramenta."

if ask_yes_no "As seguintes depend�ncias ser�o instaladas: git, dkms, build-essential e linux-headers. Deseja continuar?"; then
    
    # Detec��o de Distro e Instala��o (c�digo que j� t�nhamos)
    . /etc/os-release
    OS=$ID
    
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            PACKAGES="git dkms build-essential linux-headers-$(uname -r)"
            COMMAND="sudo apt-get update && sudo apt-get install -y $PACKAGES"
            ;;
        # ... (outros casos para Fedora, Arch, etc.)
        *)
            show_message "?? Distribui��o '$OS' n�o suportada. Instale os pacotes manualmente."
            exit 1
            ;;
    esac

    echo "???? Instalando pacotes para '$OS'..."
    eval $COMMAND

    if [ $? -ne 0 ]; then
        show_message "?? Falha na instala��o das depend�ncias. Verifique os erros no terminal."
        exit 1
    fi

    show_message "?? Depend�ncias instaladas com sucesso! O MEI Git est� pronto para ser usado. Lembre-se de criar o comando global."

else
    show_message "Instala��o cancelada pelo usu�rio."
    exit 1
fi