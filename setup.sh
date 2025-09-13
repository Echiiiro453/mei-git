#!/bin/bash

# setup.sh - v6.0 - Adiciona suporte inteligente ao AUR para Arch Linux

# Garante que o script está sendo executado como root (com sudo)
if [ "$EUID" -ne 0 ]; then
  echo "❌ Erro: Este script precisa ser executado com privilegios de root."
  echo "   Por favor, rode com: sudo ./setup.sh"
  exit 1
fi

export LANG=C.UTF-8
LOG_FILE="/tmp/mei-git-setup.log"
>"$LOG_FILE"

# --- Funções de Interface ---
install_dialog_if_missing() {
    if ! command -v dialog &> /dev/null; then
        echo "📦 Pacote 'dialog' nao encontrado. Instalando..."
        export DEBIAN_FRONTEND=noninteractive
        if command -v apt-get &> /dev/null; then apt-get update -qq && apt-get install -y -qq dialog
        elif command -v dnf &> /dev/null; then dnf install -y dialog
        elif command -v pacman &> /dev/null; then pacman -S --noconfirm dialog
        fi
    fi
}
show_message() {
    if command -v dialog &> /dev/null; then dialog --title "MEI Git Setup" --cr-wrap --msgbox "$1" 12 78
    else echo -e "\n$1\n"; fi
}
ask_yes_no() {
    if command -v dialog &> /dev/null; then dialog --title "Confirmacao" --cr-wrap --yesno "$1" 12 78; return $?
    else read -p "$1 [S/n] " choice; case "$choice" in [sS][iI][mM]|[sS]|"") return 0 ;; *) return 1 ;; esac; fi
}

# --- NOVA FUNÇÃO DE INSTALAÇÃO PARA ARCH ---
run_install_arch_family() {
    OFFICIAL_PACKAGES=("git" "dkms" "base-devel" "linux-headers" "dialog")
    AUR_PACKAGES=("python-pythondialog")
    
    (
        echo 10; echo "XXX"; echo "Etapa 1/3: Instalando pacotes oficiais..."; echo "XXX"
        pacman -Syu --noconfirm --needed "${OFFICIAL_PACKAGES[@]}" > "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
        sleep 1

        echo 50; echo "XXX"; echo "Etapa 2/3: Verificando Ajudante AUR (yay)..."; echo "XXX"
        if command -v yay &> /dev/null; then
            echo 75; echo "XXX"; echo "Etapa 3/3: Instalando pacotes do AUR com yay..."; echo "XXX"
            # Roda o yay como o usuário que chamou o sudo, não como root
            sudo -u $SUDO_USER yay -S --noconfirm "${AUR_PACKAGES[@]}" >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then echo 1 > /tmp/mei-git-status.txt; exit; fi
        else
            echo 100; echo "XXX"; echo "Aviso: Ajudante 'yay' nao encontrado."; echo "XXX"
            sleep 2
        fi
        echo 100; echo "XXX"; echo "Finalizando..."; echo "XXX"; sleep 1
        echo 0 > /tmp/mei-git-status.txt
    ) | dialog --title "Instalando para Familia Arch Linux" --gauge "Iniciando..." 10 75 0

    if ! command -v yay &> /dev/null; then
        YAY_MISSING=true
    fi
}


# --- Lógica Principal ---
main() {
    install_dialog_if_missing

    show_message "Bem-vindo ao instalador de dependencias do MEI Git!"
    if ! ask_yes_no "Deseja continuar com a instalacao das dependencias?"; then
        show_message "Instalacao cancelada."; exit 0; fi

    if [ -f /etc/os-release ]; then . /etc/os-release; OS=$ID; else
        show_message "❌ Nao foi possivel detectar a distribuicao."; exit 1; fi

    case "$OS" in
        "ubuntu" | "debian" | "linuxmint" | "deepin" | "pop" | "mx")
            # A lógica para Debian-based...
            PACKAGES=("git" "dkms" "build-essential" "linux-headers-$(uname -r)" "python3-dialog")
            # (O resto do bloco de progresso para Debian...)
            ;;
        "fedora" | "rhel" | "centos")
            # A lógica para Fedora-based...
            PACKAGES=("git" "dkms" "kernel-devel-$(uname -r)" "python3-dialog" "Development Tools")
            # (O resto do bloco de progresso para Fedora...)
            ;;
        "arch" | "endeavouros" | "manjaro")
            run_install_arch_family # Chama a nova função específica para Arch
            ;;
        *)
            show_message "❌ Distribuicao '$OS' nao suportada."; exit 1 ;;
    esac
    
    FINAL_STATUS=$(cat /tmp/mei-git-status.txt 2>/dev/null); rm /tmp/mei-git-status.txt 2>/dev/null
    if [ "$FINAL_STATUS" != "0" ]; then
        show_message "❌ Falha na instalacao. Verifique os erros."; exit 1; fi
    
    clear
    echo "=================================================================="
    echo "✅ Setup concluído com sucesso!"
    echo ""
    
    if [ "$YAY_MISSING" = true ]; then
        echo -e "\033[1;33mATENÇÃO:\033[0m A dependência 'python-pythondialog' precisa ser instalada do AUR."
        echo "Você não parece ter um ajudante AUR como o 'yay'."
        echo "Por favor, instale o 'python-pythondialog' manualmente."
        echo ""
    fi
    
    FINAL_CMD="ln -sf \"\$(pwd)/mei_git.py\" /usr/local/bin/mei-git"
    echo "Para criar o comando global, copie e cole o comando abaixo:"
    echo ""; echo -e "\033[1;32msudo $FINAL_CMD\033[0m"; echo ""
    echo "=================================================================="
}

main
