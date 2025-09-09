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
* Checa se o driver já está carregado antes de tentar instalar.
* Pergunta ao usuário antes de instalar qualquer driver.

---

## ⚙️ Instalação e Setup Completo (Copy/Paste Ready)

```bash
# Clone o repositório e entre na pasta
git clone https://github.com/Echiiiro453/mei-git.git && cd mei-git

# Torne os scripts executáveis
chmod +x mei_git.py setup.sh

# Instale dependências do sistema
sudo ./setup.sh

# Crie link global para rodar de qualquer lugar
sudo ln -sf $(pwd)/mei_git.py /usr/local/bin/mei-git

# Teste a instalação: instale Wi-Fi e Bluetooth
mei-git install wifi bluetooth
```

---

## 🚀 Uso

Instale apenas Wi-Fi ou apenas Bluetooth:

```bash
mei-git install wifi
mei-git install bluetooth
```

O script detecta o hardware, checa se o driver já está carregado e pergunta antes de instalar.

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

* Use **sudo** ao instalar drivers.
* Suporta Linux (Debian/Ubuntu testado; adaptações podem ser necessárias para outras distros).
* Conexão com internet estável necessária.
* Se o driver já estiver instalado ou carregado, o script informa e pede confirmação antes de reinstalar.

---

## 🛠️ Suporte a Dispositivos

| Tipo de Dispositivo | Fabricantes Suportados            | Exemplo de Driver/Repo      |
| ------------------- | --------------------------------- | --------------------------- |
| Wi-Fi USB/Pci       | Intel, Realtek, Broadcom, Generic | rtl8811au, rtl8188, iwlwifi |
| Bluetooth USB/Pci   | Intel, Realtek, Broadcom, Generic | btusb, broadcom bt          |
| Ethernet (extra)    | Realtek, Intel                    | r8168, e1000e               |

*(Lista de drivers no `drivers.json`, expansível)*

---

## 💡 Roadmap / Próximos Recursos

* Suporte multi-distro completo (Arch, Fedora, OpenSUSE).
* Verificação de repositório ativo antes de clonar.
* Logging detalhado de instalação.
* Adição de drivers adicionais (mais Realtek, Intel, Broadcom).
* Integração com GUI para usuários menos familiarizados com terminal.

---

## 📌 Contribuindo

1. Fork o projeto.
2. Crie uma branch: `git checkout -b minha-feature`.
3. Commit suas alterações: `git commit -m "Minha contribuição"`.
4. Push: `git push origin minha-feature`.
5. Abra Pull Request.

---

## ⚠️ Licença

MIT License — consulte o arquivo `LICENSE` no repositório.
