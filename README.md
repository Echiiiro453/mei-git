# MEI Git

**CLI para instalação automática de drivers Wi-Fi e Bluetooth no Linux.**

O MEI Git detecta seu hardware, identifica o fabricante e instala o driver correto, tudo de forma automatizada. Ideal para notebooks e desktops Linux, sem dor de cabeça.

---

## 🔧 Funcionalidades

- Detecta dispositivos Wi-Fi e Bluetooth automaticamente.
- Identifica fabricante (Intel, Realtek, Broadcom, Generic).
- Baixa o driver correto do GitHub.
- Compila e instala automaticamente.
- Limpa arquivos temporários após a instalação.

---

## ⚙️ Instalação

Clone o repositório:

```bash
git clone https://github.com/Echiiiro453/mei-git.git
cd mei-git

Torne o script executável:

chmod +x mei_git.py setup.sh


Instale dependências do sistema:

sudo ./setup.sh


Crie o link global para rodar o comando de qualquer lugar:

sudo ln -sf $(pwd)/mei_git.py /usr/local/bin/mei-git

🚀 Uso

Instale Wi-Fi e Bluetooth:

mei-git install wifi bluetooth
