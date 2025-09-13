# MEI Git

<div align="center">
  <p>
    <a href="https://github.com/Echiiiro453/mei-git"><img src="./assets/logo.png" width="400" alt="mei-git-logo" /></a>
  </p>
  <p><b>O canivete suíço para instalação de drivers no Linux.</b></p>
  <p>Ferramenta com interface no terminal (TUI) que detecta seu hardware e instala drivers de Wi-Fi, vídeo, rede e periféricos de forma automatizada.</p>
  <p>
    <a href="https://github.com/Echiiiro453/mei-git/blob/main/LICENSE">
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

> ⚡ Cansado de passar horas em fóruns obscuros procurando drivers compatíveis com Linux?  
> O **MEI Git** automatiza a detecção, download e instalação usando um banco de dados curado para os hardwares mais comuns e problemáticos.

---

## 🎥 Demonstração

![Demonstração do MEI Git em ação](./assets/demonstracao.gif)


---

## 🚀 Funcionalidades

- 🖥️ **Interface TUI:** Menu interativo no terminal, fácil de usar.
- 🔍 **Detecção Precisa:** Usa `lspci` e `lsusb` para identificar o hardware.
- 📦 **Instalação Automatizada:** Baseada em receitas no `drivers_install.json`.
- 🛠️ **Múltiplos Métodos:** Suporte a `git clone` + compilação, pacotes (`apt`, `dnf` etc.) e scripts shell.
- 🌍 **Ampla Cobertura:** Drivers para Wi-Fi (Realtek, Broadcom, MediaTek), vídeo (NVIDIA), impressoras (HP) e mais.

---

## 📥 Instalação

```bash
# 1. Clone o repositório
git clone https://github.com/Echiiiro453/mei-git.git
cd mei-git

# 2. Permissão de execução e instalação
chmod +x setup.sh
sudo ./setup.sh

# 3. Criar comando global (o setup instrui no final)
sudo ln -sf "$(pwd)/mei-git" /usr/local/bin/mei-git
```

Agora você pode rodar `mei-git` de qualquer lugar. ✅

---

## 💻 Como Usar

### 🔹 Modo Interativo (TUI) — Recomendado
Interface gráfica no terminal que guia o usuário passo a passo:

```bash
mei-git
```

Opções incluem **Diagnosticar Hardware (Scan)** e **Instalar Driver por Categoria**.

---

### 🔹 Modo Linha de Comando (CLI) — Para Automação
Ideal para usuários avançados ou scripts:

```bash
# Diagnóstico rápido
mei-git scan

# Instalar driver de Wi-Fi
sudo mei-git install wifi
```

---

## 🛤️ Roadmap

- [x] Interface TUI
- [ ] Função "Adicionar Nova Receita" direto pela TUI
- [ ] Instalação múltipla em um só comando (`mei-git install wifi video`)
- [ ] Suporte a drivers de vídeo AMD
- [ ] Releases oficiais em `.deb` e `.rpm`

---

## 🤝 Contribuindo

Pull Requests são bem-vindos!  
Antes de contribuir, confira as [issues abertas](https://github.com/Echiiiro453/mei-git/issues).

---

## 📜 Licença

Distribuído sob licença **MIT**. Veja [LICENSE](./LICENSE) para mais informações.
