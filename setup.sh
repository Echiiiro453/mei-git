#!/bin/bash

# setup.sh - v5.3 - Instalador com progresso real e modo não-interativo

# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "?? Erro: Este script precisa ser executado com privilegios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

# Força o locale para UTF-8 para máxima compatibilidade com caracteres
export LANG=C.UTF-8

# --- Variáveis Globais ---
LOG_FILE="/tmp/mei-git-setup.log"
>"$LOG_FILE" # Limpa o log antigo antes de começar

# --- Funções ---

# Instala o 'dialog' silenciosamente se necessário
install_dialog_if_missing() {
    if ! command -v dialog &> /dev/null; then
        echo "???? Pacote 'dialog' nao encontrado. Instalando..."
        export DEBIAN_FRONTEND=noninteractive
        if command -v apt-get &> /dev/null; then
            apt-get update -qq && apt-get install -y -qq dialog
        elif command -v dnf &> /dev/null; then
            dnf install -y dialog
        elif command -v pacman &> /dev/null; then
            pacman -S --noconfirm dialog
        elif command -v zypper &> /dev/null; then
            zypper --non-interactive install dialog
        fi
    fi
}

# Funções para mostrar caixas de diálogo
show_message() {
    if command -v dialog &> /dev/null; then
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

    WELCOME_TEXT="Bem-vindo ao instalador de dependencias do MEI Git!\n\nEste script ira preparar seu sistema para compilar e instalar drivers."
    show_message "$WELCOME_TEXT"

    CONFIRM_TEXT="O script ira detectar sua distribuicao e instalar os pacotes necessarios (como git, dkms, etc).\n\nDeseja continuar?"
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
            # Força o modo não-interativo para o apt
            COMMAND="export DEBIAN_FRONTEND=noninteractive; apt-get update && apt-get install -y $PACKAGES"
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
            show_message "?? Distribuicao '$OS' nao suportada."
            exit 1
            ;;
    esac

    # --- NOVO BLOCO DE INSTALAÇÃO COM PROGRESSO REAL ---
    if command -v dialog &> /dev/null; then
        # Roda o comando de instalação em segundo plano, enviando a saída para o log
        (eval $COMMAND) > "$LOG_FILE" 2>&1 &
        INSTALL_PID=$!

        # Mostra o conteúdo do log em tempo real com --tailboxbg
        dialog --title "Instalando Dependencias para '$OS'..." --tailboxbg "$LOG_FILE" 25 90
        
        # Espera o processo de instalação terminar
        wait $INSTALL_PID
        INSTALL_STATUS=$?
    else
        echo "???? Executando comando de instalacao..."
        eval $COMMAND
        INSTALL_STATUS=$?
    fi
    
    if [ $INSTALL_STATUS -ne 0 ]; then
        show_message "?? Falha na instalacao das dependencias. Verifique os erros no terminal."
        exit 1
    fi

    # Mensagem final de sucesso
    FINAL_CMD="ln -sf \"\$(pwd)/mei_git.py\" /usr/local/bin/mei-git"
    show_message "?? Dependencias instaladas com sucesso!\\n\\nO MEI Git está pronto para o proximo passo."
    
    clear
    echo "=================================================================="
    echo "?? Setup concluido com sucesso!"
    echo ""
    echo "Para criar o comando global, copie e cole o comando abaixo:"
    echo ""
    echo -e "\033[1;32msudo $FINAL_CMD\033[0m"
    echo ""
    echo "=================================================================="
}

# Executa a função principal
main