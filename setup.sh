#!/bin/bash

# setup.sh - v5.0 - Instalador profissional com feedback visual e log de erros

# --- Verifica��o de Root ---
# Garante que o script est� sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "?? Erro: Este script precisa ser executado com privil�gios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

# --- Vari�veis Globais ---
LOG_FILE="/tmp/mei-git-setup.log"

# --- Fun��es de Interface ---
# Limpa o log antigo antes de come�ar
>"$LOG_FILE"

# Fun��o para instalar o 'dialog' se necess�rio (com suporte a mais distros)
install_dialog_if_missing() {
    if ! command -v dialog &> /dev/null; then
        echo "???? Pacote 'dialog' n�o encontrado. Instalando para uma melhor experi�ncia..."
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

# Fun��es para mostrar caixas de di�logo
show_message() {
    if command -v dialog &> /dev/null; then
        dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 12 75
    else
        echo -e "\n$1\n"
    fi
}

show_error_log() {
    if command -v dialog &> /dev/null; then
        dialog --title "?? Erro na Instala��o" --cr-wrap --textbox "$LOG_FILE" 20 75
    else
        echo -e "\n?? Erro na Instala��o. Log de erro:\n"
        cat "$LOG_FILE"
    fi
}

ask_yes_no() {
    if command -v dialog &> /dev/null; then
        dialog --title "Confirma��o" --cr-wrap --yesno "$1" 12 75
        return $?
    else
        read -p "$1 [S/n] " choice
        case "$choice" in
            [sS][iI][mM]|[sS]|"") return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# --- L�gica Principal ---
main() {
    install_dialog_if_missing

    show_message "Bem-vindo ao instalador de depend�ncias do MEI Git!\\n\\nEste script ir� preparar seu sistema para compilar e instalar drivers."

    if ! ask_yes_no "O script ir� detectar sua distribui��o e instalar os pacotes necess�rios (como git, dkms, etc.).\\n\\nDeseja continuar?"; then
        show_message "Instala��o cancelada pelo usu�rio."
        exit 0
    fi

    # Detec��o de Distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        show_message "?? N�o foi poss�vel detectar a distribui��o. Instale as depend�ncias manualmente."
        exit 1
    fi

    # L�gica de Instala��o Multi-distro
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
            show_message "?? Distribui��o '$OS' n�o suportada por este script.\\n\\nPor favor, instale os pacotes equivalentes a: git, dkms, build-essential, linux-headers."
            exit 1
            ;;
    esac

    # Mostra uma caixa de "aguarde" enquanto a instala��o acontece em background
    if command -v dialog &> /dev/null; then
      dialog --title "Instalando..." --infobox "\\nPor favor, aguarde enquanto as depend�ncias s�o instaladas.\\n\\nIsso pode levar alguns minutos..." 10 70 &
    else
      echo "???? Instalando depend�ncias... Por favor, aguarde."
    fi

    # Executa a instala��o e salva a sa�da no arquivo de log
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
    show_message "?? Depend�ncias instaladas com sucesso!\\n\\nO MEI Git est� pronto para o pr�ximo passo.\\n\\nPara criar o comando global, rode o seguinte comando no seu terminal:"
    
    # Limpa a tela e mostra o comando final de forma bem clara
    clear
    echo "=================================================================="
    echo "?? Setup conclu�do com sucesso!"
    echo ""
    echo "Copie e cole o comando abaixo para finalizar a instala��o:"
    echo ""
    echo -e "\033[1;32m$FINAL_CMD\033[0m" # Imprime o comando em verde
    echo ""
    echo "=================================================================="

}

# Executa a fun��o principal
main