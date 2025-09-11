<div align="center">
  <br />
  <p>
    <a href="https://github.com/Echiiiro453/mei-git"><img src="https://i.imgur.com/uV33s2l.png" width="400" alt="mei-git-logo" /></a>
  </p>
  <br />
  <p>
    <b>O canivete su��o para instala��o de drivers no Linux.</b>
  </p>
  <p>
    Detecta seu hardware e instala drivers de Wi-Fi, v�deo, rede e perif�ricos de forma automatizada.
  </p>
  <p>
    <a href="#">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license" />
    </a>
    <a href="#">
      <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="prs-welcome" />
    </a>
    <a href="#">
      <img src="https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black" alt="linux-badge" />
    </a>
  </p>
</div>

---

> Cansado de passar horas em f�runs obscuros procurando um driver compat�vel com Linux? O **MEI Git** foi criado para resolver esse problema. Ele automatiza todo o processo de detec��o, download e instala��o, usando um banco de dados curado com as solu��es para os hardwares mais comuns e problem�ticos.

## ?? Funcionalidades

- ?? **Detec��o Autom�tica:** Identifica seu hardware (`lspci`, `lsusb`) e seus IDs de fabricante/dispositivo.
- ?? **Banco de Dados Inteligente:** Utiliza um arquivo `drivers.json` com "receitas" de instala��o para cada hardware.
- ?? **M�ltiplos M�todos:** Suporta instala��o via `git clone` + compila��o, gerenciadores de pacotes (`apt`, `dnf`, etc.) ou scripts `shell`.
- ?? **Ampla Cobertura:** Inclui drivers para:
  - ???? Wi-Fi & Ethernet (Realtek, Broadcom)
  - ?????? Placas de V�deo (NVIDIA legacy)
  - ?????? Impressoras (HP e outras)
  - ???? E muito mais...

---

## ???? Instala��o

A instala��o � feita em dois passos simples: rodar o script de setup e criar o comando global.

```bash
# 1. Clone o reposit�rio e entre na pasta
git clone [https://github.com/Echiiiro453/mei-git.git](https://github.com/Echiiiro453/mei-git.git)
cd mei-git

# 2. D� permiss�o de execu��o e rode o setup
# (Ele instalar� depend�ncias como git, dkms e build-essential)
chmod +x setup.sh
sudo ./setup.sh

# 3. Crie o comando global para usar 'mei-git' de qualquer lugar
sudo ln -sf "$(pwd)/mei_git.py" /usr/local/bin/mei-git
'''

Pronto! Agora o comando mei-git est� dispon�vel em todo o seu sistema.

?????? Como Usar
O fluxo de trabalho � simples: primeiro escaneie para um diagn�stico, depois instale o que for necess�rio.

1. Escanear Hardware
Use scan para ver o que o MEI Git detecta no seu sistema. � um comando seguro que n�o instala ou modifica nada.

Bash

mei-git scan
O comando scan tamb�m pode mostrar quais drivers do banco de dados s�o compat�veis com seu hardware e se os m�dulos j� est�o carregados no kernel.

2. Instalar um Driver
Use install seguido da categoria do dispositivo. O MEI Git ir� escanear, encontrar um driver compat�vel e iniciar a instala��o.

Bash

# Para instalar um driver de Wi-Fi
sudo mei-git install wifi

# Para instalar um driver de V�deo
sudo mei-git install video

# Para instalar um driver de Rede Ethernet
sudo mei-git install ethernet
Se um driver compat�vel for encontrado, a instala��o come�ar�, mostrando cada passo no terminal.

???? Estrutura do Projeto
mei-git/
?%%? mei_git.py      # O script principal da aplica��o (CLI)
?%%? drivers.json    # O banco de dados com as "receitas" de instala��o
?%%? setup.sh        # Script para instalar as depend�ncias do sistema
?%%? README.md       # Esta documenta��o
???? Roadmap (Planos Futuros)
[ ] Suporte a mais distribui��es no script de setup (Void, Alpine, etc.).

[ ] Detec��o e instala��o de drivers de v�deo AMD.

[ ] Adicionar drivers propriet�rios de impressoras Canon/Epson.

[ ] Criar uma interface gr�fica (GUI) simples para facilitar o uso.

???? Contribuindo
Contribui��es s�o o que tornam a comunidade open source incr�vel. Qualquer ajuda � muito bem-vinda.

Fa�a um Fork do projeto

Crie sua Feature Branch (git checkout -b feature/DriverNovo)

Fa�a o Commit de suas altera��es (git commit -m 'feat: Adiciona suporte para o driver X')

Fa�a o Push para a Branch (git push origin feature/DriverNovo)

Abra um Pull Request

???? Licen�a
Distribu�do sob a licen�a MIT. Veja o arquivo LICENSE para mais detalhes.

<div align="center">
<h3>?? Se este projeto te ajudou, considere dar uma estrela no reposit�rio! ??</h3>
</div>

