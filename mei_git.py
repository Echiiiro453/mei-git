#!/usr/bin/env python3
import sys
import os
import json
import subprocess
import re

# --- Funções Auxiliares ---

def run_cmd(cmd):
    """
    Executa um comando no shell, mostrando a saída em tempo real.
    Retorna True se o comando for bem-sucedido, False caso contrário.
    """
    print(f"🔩 Executando: {cmd}")
    try:
        # Usamos Popen para streaming de saída, essencial para longas compilações
        process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        for line in iter(process.stdout.readline, ''):
            print(line, end='')
        process.wait()
        return process.returncode == 0
    except Exception as e:
        print(f"❌ Erro ao executar comando: {e}")
        return False

def load_driver_db():
    """Carrega o banco de dados de drivers do arquivo JSON."""
    try:
        with open("drivers.json") as f:
            return json.load(f)
    except FileNotFoundError:
        print("❌ Erro: Arquivo 'drivers.json' não encontrado. Certifique-se de que ele está na mesma pasta.")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Erro de formato no 'drivers.json': {e}")
        sys.exit(1)

def check_pkg_manager():
    """Verifica qual gerenciador de pacotes está disponível."""
    if run_cmd("command -v apt-get"):
        return "apt"
    # Adicionar outras verificações aqui no futuro (ex: pacman, dnf)
    return None

# --- Função de Detecção (Scan) ---

def detect_hardware():
    """
    Escaneia o hardware PCI e USB, imprime um resumo e retorna um CONJUNTO
    de todos os Device IDs [VendorID:DeviceID] encontrados.
    """
    print("🔍 Escaneando hardware PCI e USB...")
    detected_ids = set()
    try:
        pci_output = subprocess.getoutput("lspci -nn")
        pci_ids = re.findall(r'\[(\w{4}:\w{4})\]', pci_output)
        detected_ids.update(pci_ids)
        
        usb_output = subprocess.getoutput("lsusb")
        usb_ids = re.findall(r'ID (\w{4}:\w{4})', usb_output)
        detected_ids.update(usb_ids)
    except Exception as e:
        print(f"⚠️ Não foi possível escanear o hardware: {e}")

    if not detected_ids:
        print("Nenhum ID de dispositivo encontrado.")
    else:
        print(f"✔️ {len(detected_ids)} IDs de dispositivos únicos encontrados.")
    return detected_ids

# --- Função de Instalação (Install) ---

def install_driver(category, detected_ids, db):
    """
    O "motor" de instalação que lê e executa as "receitas" do drivers.json.
    Agora suporta múltiplos tipos de instalação.
    """
    print(f"\n🚀 Procurando por um driver instalável na categoria '{category}'...")
    drivers_in_category = db.get(category)
    if not drivers_in_category:
        print(f"❌ Nenhuma entrada para a categoria '{category}' encontrada em drivers.json.")
        return

    # 1. Encontrar um driver compatível
    target_driver = None
    driver_name = ""
    for name, details in drivers_in_category.items():
        if any(did in detected_ids for did in details.get("device_ids", [])):
            target_driver = details
            driver_name = name
            print(f"✅ Driver compatível encontrado: '{driver_name}'")
            break
            
    if not target_driver:
        print(f"❌ Nenhum driver compatível para sua máquina foi encontrado na categoria '{category}' em drivers.json.")
        return

    # 2. Instalar dependências
    pkg_manager = check_pkg_manager()
    dependencies = target_driver.get("dependencies")
    if dependencies:
        print("\n[Passo 1 de 3] Verificando e instalando dependências...")
        if pkg_manager == "apt":
            dep_string = " ".join(dependencies)
            if not run_cmd(f"sudo apt-get install -y {dep_string}"):
                print("❌ Falha ao instalar dependências. Abortando.")
                return
        else:
            print(f"⚠️ Gerenciador de pacotes não suportado. Por favor, instale manualmente: {dependencies}")

    # 3. Executar a instalação baseada no TIPO
    print(f"\n[Passo 2 de 3] Executando instalação (tipo: {target_driver.get('type')})...")
    install_type = target_driver.get("type")
    success = False

    if install_type == "git":
        repo_url = target_driver["repo"]
        repo_name = repo_url.split("/")[-1].replace(".git", "")
        if not os.path.exists(repo_name):
            if not run_cmd(f"git clone {repo_url}"):
                print("❌ Falha ao clonar o repositório. Abortando.")
                return
        else:
            print(f"   - O diretório '{repo_name}' já existe. Pulando clone.")
        
        try:
            original_dir = os.getcwd()
            os.chdir(repo_name)
            
            build_steps = target_driver.get("build_steps", [])
            for step in build_steps:
                if not run_cmd(step):
                    print(f"❌ Falha no passo de compilação: '{step}'. Abortando.")
                    os.chdir(original_dir)
                    return
            success = True
            os.chdir(original_dir)

        except Exception as e:
            print(f"❌ Erro durante o processo de build: {e}")
            os.chdir(original_dir) # Garante que voltamos ao dir original
            return

    elif install_type == "apt":
        package = target_driver.get("package")
        if package:
            success = run_cmd(f"sudo apt-get install -y {package}")
        else:
            print("❌ Erro no JSON: tipo 'apt' sem a chave 'package'.")

    elif install_type == "shell":
        build_steps = target_driver.get("build_steps", [])
        if not build_steps:
            print("❌ Erro no JSON: tipo 'shell' sem a chave 'build_steps'.")
        else:
            for step in build_steps:
                if not run_cmd(step):
                    print(f"❌ Falha no passo de shell: '{step}'. Abortando.")
                    return
            success = True

    else:
        print(f"❌ Tipo de instalação desconhecido: '{install_type}'")

    if not success:
        print("\n A instalação principal falhou. Verifique os logs de erro.")
        return

    # 4. Executar passos de pós-instalação
    post_install_steps = target_driver.get("post_install")
    if post_install_steps:
        print("\n[Passo 3 de 3] Executando passos de pós-instalação...")
        for step in post_install_steps:
            if not run_cmd(step):
                print(f"⚠️ O passo de pós-instalação '{step}' falhou, mas a instalação principal pode ter funcionado.")

    print(f"\n🎉 Processo de instalação para '{driver_name}' concluído!")

# --- Função Principal (CLI) ---

def main():
    """Ponto de entrada do script."""
    args = sys.argv[1:]
    if not args:
        print("Uso: mei-git <comando> [argumento]")
        print("Comandos disponíveis:")
        print("  scan          - Detecta o hardware e seus IDs.")
        print("  install <cat> - Instala o driver para uma categoria (ex: wifi, video).")
        sys.exit(1)

    command = args[0]
    if command == "scan":
        detect_hardware()
    elif command == "install":
        if len(args) < 2:
            print("❌ Erro: Especifique a categoria. Uso: mei-git install <categoria>")
            sys.exit(1)
        
        category_to_install = args[1]
        driver_db = load_driver_db()
        detected_device_ids = detect_hardware()
        
        if not detected_device_ids:
            print("Não foi possível continuar a instalação sem detectar os IDs de hardware.")
            sys.exit(1)

        install_driver(category_to_install, detected_device_ids, driver_db)
    else:
        print(f"Comando desconhecido: '{command}'")
        sys.exit(1)

if __name__ == "__main__":
    main()

