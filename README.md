# MEI Git

**CLI Linux para instalação automática de drivers Wi-Fi e Bluetooth.**

O **MEI Git** detecta seu hardware, identifica o fabricante e instala o driver correto, tudo de forma automatizada. Ideal para notebooks e desktops Linux — esqueça a dor de cabeça de compilar drivers manualmente.

---

## 🔧 Funcionalidades

* Detecta automaticamente dispositivos Wi-Fi e Bluetooth.
* Identifica fabricantes: **Intel**, **Realtek**, **Broadcom** ou **Generic**.
* Baixa o driver correto diretamente do GitHub.
* Compila e instala automaticamente.
* Limpa arquivos temporários pós-instalação.

---

## ⚙️ Instalação

1. **Clone o repositório:**

```bash
git clone https://github.com/Echiiiro453/mei-git.git
cd mei-git
```

2. **Torne os scripts executáveis:**

```bash
chmod +x mei_git.py setup.sh
```

3. **Instale dependências do sistema:**

```bash
sudo ./setup.sh
```

4. **Crie o link global para rodar o comando de qualquer lugar:**

```bash
sudo ln -sf $(pwd)/mei_git.py /usr/local/bin/mei-git
```

---

## 🚀 Uso

Instale Wi-Fi e Bluetooth com um comando:

```bash
mei-git install wifi bluetooth
```

Verifique apenas Wi-Fi ou Bluetooth:

```bash
mei-git install wifi
mei-git install bluetooth
```

---

## 📂 Estrutura do projeto

```
mei-git/
├── mei_git.py       # Script principal
├── drivers.json     # Lista de drivers e repositórios
├── setup.sh         # Instala dependências do sistema
└── README.md        # Este arquivo
```

---

## 📝 Observações

* Certifique-se de rodar com **permissões sudo** quando instalar drivers.
* Suporta apenas Linux (testado em distribuições baseadas em Debian/Ubuntu).
* Recomendado usar uma conexão com internet estável, pois os drivers são baixados do GitHub.
