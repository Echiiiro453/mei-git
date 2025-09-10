# MEI Git

**CLI Linux para instalação inteligente de drivers comuns e de difícil configuração.**

O **MEI Git** é uma ferramenta de linha de comando que automatiza a detecção e instalação de drivers que frequentemente faltam ou causam problemas em distribuições Linux. Ele usa um banco de dados curado (`drivers.json`) com "receitas" para instalar drivers de Wi-Fi, vídeo, ethernet e periféricos diretamente de suas fontes.

Ideal para pós-instalação de sistemas em notebooks e desktops com hardware específico.

---

## 🔧 Funcionalidades

- **Detecção Precisa:** Escaneia seu hardware PCI e USB para encontrar os IDs exatos dos dispositivos.
- **Instalação Baseada em Receitas:** Segue instruções detalhadas de um arquivo `drivers.json` para cada driver.
- **Múltiplos Métodos de Instalação:** Suporta instalação via `git` (compilando o código-fonte), `apt` (usando pacotes da distro) e `shell` (executando comandos específicos).
- **Gerenciamento de Dependências:** Instala automaticamente os pacotes necessários (`dkms`, `build-essential`, etc.) antes de compilar um driver.
- **Foco em Drivers Problemáticos:** Concentra-se em drivers que normalmente não vêm por padrão no kernel, como certos chips **Realtek**, **Broadcom** e placas **NVIDIA** legacy.
- **Log Simplificado:** Gera um log detalhado da detecção em `/tmp/mei-hw.log`.

---

## ⚙️ Instalação

Copie e cole os comandos abaixo no seu terminal para uma instalação global:

```bash
# 1. Clone o repositório
git clone [https://github.com/Echiiiro453/mei-git.git](https://github.com/Echiiiro453/mei-git.git)
cd mei-git

# 2. Torne os scripts executáveis
chmod +x mei_git.py setup.sh

# 3. Rode o setup para instalar dependências (suporta múltiplas distros)
sudo ./setup.sh

# 4. Crie o link simbólico para rodar o comando de qualquer lugar
sudo ln -sf $(pwd)/mei_git.py /usr/local/bin/mei-git