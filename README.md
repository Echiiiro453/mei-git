<div align="center">
  <br />
  <p>
    <a href="https://github.com/Echiiiro453/mei-git"><img src="https://i.imgur.com/uV33s2l.png" width="400" alt="mei-git-logo" /></a>
  </p>
  <br />
  <p>
    <b>O canivete suíço para instalação de drivers no Linux.</b>
  </p>
  <p>
    Detecta seu hardware e instala drivers de Wi-Fi, vídeo, rede e periféricos de forma automatizada.
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

> Cansado de passar horas em fóruns obscuros procurando um driver compatível com Linux? O **MEI Git** foi criado para resolver esse problema. Ele automatiza todo o processo de detecção, download e instalação, usando um banco de dados curado com as soluções para os hardwares mais comuns e problemáticos.

## ?? Funcionalidades

- ?? **Detecção Automática:** Identifica seu hardware (`lspci`, `lsusb`) e seus IDs de fabricante/dispositivo.
- ?? **Banco de Dados Inteligente:** Utiliza um arquivo `drivers.json` com "receitas" de instalação para cada hardware.
- ?? **Múltiplos Métodos:** Suporta instalação via `git clone` + compilação, gerenciadores de pacotes (`apt`, `dnf`, etc.) ou scripts `shell`.
- ?? **Ampla Cobertura:** Inclui drivers para:
  - ???? Wi-Fi & Ethernet (Realtek, Broadcom)
  - ?????? Placas de Vídeo (NVIDIA legacy)
  - ?????? Impressoras (HP e outras)
  - ???? E muito mais...

---

## ???? Instalação

A instalação é feita em dois passos simples: rodar o script de setup e criar o comando global.

```bash
# 1. Clone o repositório e entre na pasta
git clone [https://github.com/Echiiiro453/mei-git.git](https://github.com/Echiiiro453/mei-git.git)
cd mei-git

# 2. Dê permissão de execução e rode o setup
# (Ele instalará dependências como git, dkms e build-essential)
chmod +x setup.sh
sudo ./setup.sh

# 3. Crie o comando global para usar 'mei-git' de qualquer lugar
sudo ln -sf "$(pwd)/mei_git.py" /usr/local/bin/mei-git
'''

Pronto! Agora o comando mei-git está disponível em todo o seu sistema.

?????? Como Usar
O fluxo de trabalho é simples: primeiro escaneie para um diagnóstico, depois instale o que for necessário.

1. Escanear Hardware
Use scan para ver o que o MEI Git detecta no seu sistema. É um comando seguro que não instala ou modifica nada.

Bash

mei-git scan
O comando scan também pode mostrar quais drivers do banco de dados são compatíveis com seu hardware e se os módulos já estão carregados no kernel.

2. Instalar um Driver
Use install seguido da categoria do dispositivo. O MEI Git irá escanear, encontrar um driver compatível e iniciar a instalação.

Bash

# Para instalar um driver de Wi-Fi
sudo mei-git install wifi

# Para instalar um driver de Vídeo
sudo mei-git install video

# Para instalar um driver de Rede Ethernet
sudo mei-git install ethernet
Se um driver compatível for encontrado, a instalação começará, mostrando cada passo no terminal.

???? Estrutura do Projeto
mei-git/
?%%? mei_git.py      # O script principal da aplicação (CLI)
?%%? drivers.json    # O banco de dados com as "receitas" de instalação
?%%? setup.sh        # Script para instalar as dependências do sistema
?%%? README.md       # Esta documentação
???? Roadmap (Planos Futuros)
[ ] Suporte a mais distribuições no script de setup (Void, Alpine, etc.).

[ ] Detecção e instalação de drivers de vídeo AMD.

[ ] Adicionar drivers proprietários de impressoras Canon/Epson.

[ ] Criar uma interface gráfica (GUI) simples para facilitar o uso.

???? Contribuindo
Contribuições são o que tornam a comunidade open source incrível. Qualquer ajuda é muito bem-vinda.

Faça um Fork do projeto

Crie sua Feature Branch (git checkout -b feature/DriverNovo)

Faça o Commit de suas alterações (git commit -m 'feat: Adiciona suporte para o driver X')

Faça o Push para a Branch (git push origin feature/DriverNovo)

Abra um Pull Request

???? Licença
Distribuído sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

<div align="center">
<h3>?? Se este projeto te ajudou, considere dar uma estrela no repositório! ??</h3>
</div>

