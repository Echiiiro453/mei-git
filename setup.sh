#!/bin/bash

# setup.sh - v5.0 - Instalador profissional com feedback visual e log de erros

# --- Verificação de Root ---
# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "?? Erro: Este script precisa ser executado com privilégios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

# --- Variáveis Globais ---
LOG_FILE="/tmp/mei-git-setup.log"

# --- Funções de Interface ---
# Limpa o log antigo antes de começar
>"$LOG_FILE"

# Função para instalar o 'dialog' se necessário (com suporte a mais distros)
install_dialog_if_missing() {
    if ! command -v dialog &> /dev/null; then
        echo "???? Pacote 'dialog' não encontrado. Instalando para uma melhor experiência..."
        if command -v apt-get &> /dev/null; then
            apt-get update >"$LOG_FILE" 2>&1 && apt-get install -y dialog >>"$LOG_FILE" 2>&1
        elif command -v dnf &> /dev/null; then
            dnf install -y dialog >"$LOG_FILE" 2>&1
        elif command -v pacman &> /dev/null; then
            pacman -S --noconfirm dialog >"$LOG_FILE" 2>&1
        elif command -v zypper &> /dev/null; then
            zypper install -y dialog >"$LOG_FILE" 2>&1
        fi
    fi
}

# Funções para mostrar caixas de diálogo
show_message() {
    if command -v dialog &> /dev/null; then
        dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 12 75
    else
        echo -e "\n$1\n"
    fi
}

show_error_log() {
    if command -v dialog &> /dev/null; then
        dialog --title "?? Erro na Instalação" --cr-wrap --textbox "$LOG_FILE" 20 75
    else
        echo -e "\n?? Erro na Instalação. Log de erro:\n"
        cat "$LOG_FILE"
    fi
}

ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirmação" --cr-wrap --yesno "$1" 12 75
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

    show_message "Bem-vindo ao instalador de dependências do MEI Git!\\n\\nEste script irá preparar seu sistema para compilar e instalar drivers."

    if ! ask_yes_no "O script irá detectar sua distribuição e instalar os pacotes necessários (como git, dkms, etc.).\\n\\nDeseja continuar?"; then
        show_message "Instalação cancelada pelo usuário."
        exit 0
    fi

    # Detecção de Distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        show_message "?? Não foi possível detectar a distribuição. Instale as dependências manualmente."
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
            show_message "?? Distribuição '$OS' não suportada por este script.\\n\\nPor favor, instale os pacotes equivalentes a: git, dkms, build-essential, linux-headers."
            exit 1
            ;;
    esac

    # Mostra uma caixa de "aguarde" enquanto a instalação acontece em background
    if command -v dialog &> /dev/null; then
      dialog --title "Instalando..." --infobox "\\nPor favor, aguarde enquanto as dependências são instaladas.\\n\\nIsso pode levar alguns minutos..." 10 70 &
    else
      echo "???? Instalando dependências... Por favor, aguarde."
    fi

    # Executa a instalação e salva a saída no arquivo de log
    eval $COMMAND > "$LOG_FILE" 2>&1
    INSTALL_STATUS=$?

    # Para o processo do infobox
    kill $! &>/dev/null
    wait $! &>/dev/null

    if [ $INSTALL_STATUS -ne 0 ]; then
        show_error_log
        exit 1
    fi

    # Mensagem final de sucesso
    FINAL_CMD="sudo ln -sf \"\$(pwd)/mei_git.py\" /usr/local/bin/mei-git"
    show_message "?? Dependências instaladas com sucesso!\\n\\nO MEI Git está pronto para o próximo passo.\\n\\nPara criar o comando global, rode o seguinte comando no seu terminal:"
    
    # Limpa a tela e mostra o comando final de forma bem clara
    clear
    echo "=================================================================="
    echo "?? Setup concluído com sucesso!"
    echo ""
    echo "Copie e cole o comando abaixo para finalizar a instalação:"
    echo ""
    echo -e "\033[1;32m$FINAL_CMD\033[0m" # Imprime o comando em verde
    echo ""
    echo "=================================================================="

}

# Executa a função principal
main