#!/bin/bash

# setup.sh - v5.2 - Instalador com quebra de linha manual para maior compatibilidade

# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "?? Erro: Este script precisa ser executado com privilégios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

# Força o locale para UTF-8 para máxima compatibilidade com caracteres
export LANG=C.UTF-8

# --- Verificação e Instalação do 'dialog' ---
install_dialog_if_missing() {
    if ! command -v dialog &> /dev/null; then
        echo "???? Pacote 'dialog' nao encontrado. Instalando..."
        if command -v apt-get &> /dev/null; then
            apt-get update -qq && apt-get install -y -qq dialog
        elif command -v dnf &> /dev/null; then
            dnf install -y dialog
        elif command -v pacman &> /dev/null; then
            pacman -S --noconfirm dialog
        elif command -v zypper &> /dev/null; then
            zypper --non-interactive install dialog
        fi

        if ! command -v dialog &> /dev/null; then
             echo "???? Falha ao instalar o 'dialog'. O script continuara em modo texto simples."
        fi
    fi
}

# --- Funções de Interface ---
show_message() {
    if command -v dialog &> /dev/null; then
        # Aumentamos o tamanho da caixa para 12 de altura e 78 de largura
        dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 12 78
    else
        echo -e "\n$1\n"
    fi
}

ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirmacao" --cr-wrap --yesno "$1" 12 78
        return $?
    else
        read -p "$1 [S/n] " choice
        case "$choice" in
            [sS][iI][mM]|[sS]|"") return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# --- Lógica Principal ---
main() {
    install_dialog_if_missing

    # Mensagem de boas-vindas formatada manualmente
    WELCOME_TEXT="Bem-vindo ao instalador de dependencias do MEI Git!"
    WELCOME_TEXT+="\n\n"
    WELCOME_TEXT+="Este script ira preparar seu sistema para compilar e instalar drivers."
    show_message "$WELCOME_TEXT"

    # Mensagem de confirmação formatada manualmente
    CONFIRM_TEXT="O script ira detectar sua distribuicao e instalar os pacotes"
    CONFIRM_TEXT+="\nnecessarios (como git, dkms, build-essential, etc)."
    CONFIRM_TEXT+="\n\nDeseja continuar?"
    if ! ask_yes_no "$CONFIRM_TEXT"; then
        show_message "Instalacao cancelada pelo usuario."
        exit 0
    fi

    # Detecção de Distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        show_message "?? Nao foi possivel detectar a distribuicao."
        exit 1
    fi

    # Lógica de Instalação Multi-distro
    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            PACKAGES="git dkms build-essential linux-headers-$(uname -r)"
            COMMAND="apt-get update && apt-get install -y $PACKAGES"
            ;;
        "fedora" | "rhel" | "centos")
            PACKAGES="git dkms kernel-devel"
            COMMAND="dnf install -y $PACKAGES && dnf groupinstall -y 'Development Tools'"
            ;;
        "arch" | "endeavouros" | "manjaro")
            PACKAGES="git dkms base-devel linux-headers"
            COMMAND="pacman -Syu --noconfirm $PACKAGES"
            ;;
        "opensuse-tumbleweed" | "opensuse-leap")
            PACKAGES="git dkms patterns-devel-base-devel_basis kernel-default-devel"
            COMMAND="zypper install -y $PACKAGES"
            ;;
        *)
            ERROR_TEXT="?? Distribuicao '$OS' nao suportada.\\n\\n"
            ERROR_TEXT+="Por favor, instale manualmente os pacotes equivalentes a:\\n"
            ERROR_TEXT+="git, dkms, build-essential, linux-headers."
            show_message "$ERROR_TEXT"
            exit 1
            ;;
    esac

    # Usa --programbox para mostrar a saída do comando em tempo real
    if command -v dialog &> /dev/null; then
        dialog --title "Instalando Dependencias para '$OS'..." --programbox "$COMMAND" 25 90
    else
        echo "???? Executando comando de instalacao..."
        eval $COMMAND
    fi
    
    INSTALL_STATUS=$?

    if [ $INSTALL_STATUS -ne 0 ]; then
        show_message "?? Falha na instalacao das dependencias. Verifique os erros na janela anterior."
        exit 1
    fi

    # Mensagem final de sucesso formatada manualmente
    SUCCESS_TEXT="?? Dependencias instaladas com sucesso!\\n\\n"
    SUCCESS_TEXT+="O MEI Git está pronto para o proximo passo."
    show_message "$SUCCESS_TEXT"
    
    clear
    FINAL_CMD="ln -sf \"\$(pwd)/mei_git.py\" /usr/local/bin/mei-git"
    echo "=================================================================="
    echo "?? Setup concluido com sucesso!"
    echo ""
    echo "Para criar o comando global, copie e cole o comando abaixo:"
    echo ""
    echo -e "\033[1;32msudo $FINAL_CMD\033[0m" # Imprime o comando em verde
    echo ""
    echo "=================================================================="
}

# Executa a função principal
main