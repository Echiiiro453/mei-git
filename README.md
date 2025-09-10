
````markdown
# MEI Git

**CLI Linux para instalação inteligente de drivers comuns e de difícil configuração.**

O **MEI Git** é uma ferramenta de linha de comando que automatiza a detecção e instalação de drivers que frequentemente faltam ou causam problemas em distribuições Linux. Ele usa um banco de dados curado com "receitas" para instalar drivers de Wi-Fi, vídeo, ethernet e periféricos diretamente de suas fontes.

Tudo em um único arquivo, portátil e fácil de usar. Ideal para pós-instalação de sistemas em notebooks e desktops.

---

## 🔧 Funcionalidades

- **Detecção Precisa:** Escaneia seu hardware PCI e USB para encontrar os IDs exatos dos dispositivos.
- **Instalação Baseada em Receitas:** Segue instruções detalhadas de um banco de dados interno para cada driver.
- **Múltiplos Métodos de Instalação:** Suporta instalação via `git` (compilando o código-fonte), `apt` (usando pacotes da distro) e `shell` (executando comandos específicos).
- **Gerenciamento de Dependências:** Instala automaticamente os pacotes necessários (`dkms`, `build-essential`, etc.) através do comando `setup`.
- **Foco em Drivers Problemáticos:** Concentra-se em drivers que normalmente não vêm por padrão no kernel, como certos chips **Realtek**, **Broadcom** e placas **NVIDIA** legacy.
- **Log Simplificado:** Gera um log detalhado da detecção em `/tmp/mei-hw.log`.

---

## ⚙️ Instalação Rápida

Você só precisa de um único arquivo. Abra o terminal e execute os comandos abaixo:

```bash
# 1. Baixe o script do repositório
curl -LO [https://github.com/Echiiiro453/mei-git/raw/main/mei-git](https://github.com/Echiiiro453/mei-git/raw/main/mei-git)

# (Se não tiver o curl, use o wget)
# wget [https://github.com/Echiiiro453/mei-git/raw/main/mei-git](https://github.com/Echiiiro453/mei-git/raw/main/mei-git)

# 2. Dê permissão de execução
chmod +x mei-git

# 3. Rode o setup para instalar dependências e o comando global
sudo ./mei-git setup
````

Após o setup, o comando `mei-git` estará disponível em todo o sistema.

-----

## 🚀 Como Usar (Passo a Passo)

A filosofia da ferramenta é simples: primeiro você escaneia para diagnosticar, depois instala o que for necessário.

### Passo 1: Escaneie seu Hardware

Use o comando `scan` para fazer um diagnóstico seguro. Ele não modifica nada no seu sistema e mostra o que o MEI Git conseguiu detectar.

```bash
mei-git scan
```

A saída será algo como:

```
🔍 Escaneando hardware PCI e USB...
✔️ 42 IDs de dispositivos únicos encontrados.
```

### Passo 2: Instale o Driver por Categoria

Escolha a categoria do driver que está faltando e use o comando `install`.

**Exemplo: Instalando um driver de Wi-Fi**

Se o seu Wi-Fi não funciona, rode:

```bash
sudo mei-git install wifi
```

O script irá identificar seu hardware, encontrar um driver compatível no banco de dados interno e iniciar a instalação, mostrando cada passo na tela.

### Outros Exemplos

```bash
# Para instalar um driver de vídeo (ex: NVIDIA legacy)
sudo mei-git install video

# Para instalar um driver de rede cabeada (ex: Realtek r8168)
sudo mei-git install ethernet

# Para instalar o plugin da sua impressora HP
sudo mei-git install printer
```

### Ajuda e Documentação

Para ver a lista de comandos ou a documentação completa a qualquer momento, use:

```bash
# Ver a lista de comandos
mei-git

# Ver a documentação completa (este README)
mei-git readme
```

-----

## 📌 Roadmap (Roteiro)

  - [x] Motor de detecção de hardware por IDs.
  - [x] Motor de instalação baseado em "receitas" JSON internas.
  - [x] Suporte para `git`, `apt` e `shell` como métodos de instalação.
  - [x] Comando de `setup` multi-distro para dependências.
  - [x] Documentação embutida no script (`mei-git readme`).
  - [ ] Suporte para instalar múltiplas categorias de uma só vez (`mei-git install wifi video`).
  - [ ] Comando interativo para adicionar novos drivers ao banco de dados (`mei-git add-driver`).
  - [ ] Confirmação interativa ("Você deseja instalar [driver]? [S/n]") antes de cada instalação.

-----

👨‍💻 **Autor:** Marcondes (Andrey)
\<br\>
📦 **Repositório Oficial:** [github.com/Echiiiro453/mei-git](https://github.com/Echiiiro453/mei-git)

```
```