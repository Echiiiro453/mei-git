# MEI Git

**CLI Linux para instalação automática de drivers Wi-Fi, Bluetooth, vídeo, áudio e periféricos.**

O **MEI Git** detecta seu hardware, identifica fabricante e modelo, e instala o driver correto — tudo de forma automatizada.  
Compatível com múltiplas distribuições Linux. Ideal para notebooks e desktops.

---

## 🔧 Funcionalidades

- Detecta dispositivos **Wi-Fi, Bluetooth, Vídeo, Áudio e USB** automaticamente.  
- Identifica fabricantes: **Intel, Realtek, Broadcom, NVIDIA, AMD** etc.  
- Baixa o driver correto diretamente do GitHub.  
- Compila e instala automaticamente com **DKMS**.  
- Checagem inteligente: detecta se o driver já está carregado no sistema.  
- Logs em `/var/log/mei-git.log`.  

---

## ⚙️ Instalação

Copie e cole os comandos abaixo no terminal:

```bash
# Clone o repositório
git clone https://github.com/Echiiiro453/mei-git.git
cd mei-git

# Torne os scripts executáveis
chmod +x mei_git.py setup.sh

# Rode o setup para instalar dependências (multi-distro)
sudo ./setup.sh

# Crie o link global para rodar de qualquer lugar
sudo ln -sf $(pwd)/mei_git.py /usr/local/bin/mei-git
```

---

## 🚀 Uso

Instalar Wi-Fi e Bluetooth:

```bash
mei-git install wifi bluetooth
```

Instalar apenas Wi-Fi:

```bash
mei-git install wifi
```

Instalar apenas Bluetooth:

```bash
mei-git install bluetooth
```

Checar drivers detectados sem instalar:

```bash
mei-git --check
```

Instalar tudo automaticamente (sem perguntas):

```bash
mei-git --auto
```

---

## 📂 Estrutura do projeto

```
mei-git/
├── mei_git.py       # Script principal
├── drivers.json     # Lista de drivers e repositórios
├── setup.sh         # Instala dependências multi-distro
└── README.md        # Documentação
```

---

## 📝 Observações

- Requer **sudo** para instalar drivers.  
- Compatível com:  
  - **Debian/Ubuntu** (apt)  
  - **Fedora/RHEL** (dnf)  
  - **Arch Linux** (pacman)  
  - **openSUSE** (zypper)  
- Recomendado usar internet estável (os drivers são baixados do GitHub).  
- Testado em kernel Linux 5.x e 6.x.  

---

## 📌 Roadmap

- [x] Suporte multi-distro  
- [x] Checagem inteligente de drivers já instalados  
- [x] Confirmação antes de instalar  
- [ ] Expansão para vídeo, áudio e impressoras  
- [ ] Releases com pacotes `.deb` e `.rpm`  

---

👨‍💻 Autor: **Marcondes (Andrey)**  
📦 Repo oficial: [MEI Git](https://github.com/Echiiiro453/mei-git)  
