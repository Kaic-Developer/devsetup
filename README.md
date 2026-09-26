# 🚀 Kaic DevSetup

Automação para configuração de um ambiente de desenvolvimento no **Windows**, criada para facilitar a preparação de máquinas novas ou recém-formatadas.

O objetivo do projeto é reduzir o trabalho manual necessário para configurar um ambiente moderno de desenvolvimento utilizando **WSL 2, Ubuntu, Docker, Git e Visual Studio Code**.

---

## 📌 Sobre o projeto

Configurar um computador novo para desenvolvimento normalmente envolve diversas etapas:

- Ativar recursos de virtualização do Windows
- Configurar WSL 2
- Instalar uma distribuição Linux
- Configurar Hyper-V quando necessário
- Instalar Docker Desktop
- Instalar Git
- Instalar Visual Studio Code
- Reiniciar o computador durante determinadas etapas
- Verificar se cada componente está funcionando

O **Kaic DevSetup** automatiza boa parte desse processo.

O script verifica o estado atual da máquina antes de realizar alterações, evitando reinstalações desnecessárias.

---

## ⚙️ O que o DevSetup configura

Atualmente o projeto verifica e/ou configura:

- Windows Subsystem for Linux (WSL)
- WSL 2 como versão padrão
- Virtual Machine Platform
- Hyper-V quando disponível
- Ubuntu
- Docker Desktop
- Git
- Visual Studio Code
- WinGet
- Serviço `vmcompute`
- Arquitetura do sistema
- Estado do hipervisor

---

## 🧠 Como funciona

O projeto possui dois arquivos principais:

```text
DevSetup/
│
├── devsetup.bat
├── setup-dev.ps1
├── README.md
└── .gitignore
```

### `devsetup.bat`

É o ponto de entrada do instalador.

Ele inicia o PowerShell com as configurações necessárias para executar o DevSetup.

### `setup-dev.ps1`

Contém a lógica principal da automação.

O script:

```text
Inicia como Administrador
        ↓
Verifica o Windows
        ↓
Verifica virtualização
        ↓
Verifica recursos necessários
        ↓
Configura WSL 2
        ↓
Verifica/instala Ubuntu
        ↓
Verifica/instala Git
        ↓
Verifica/instala VS Code
        ↓
Verifica/instala Docker Desktop
        ↓
Executa validações
        ↓
Informa se é necessário reiniciar
```

---

## 📦 Instalação

Clone o repositório:

```bash
git clone https://github.com/Kaic-Developer/devsetup.git
```

Entre na pasta:

```bash
cd devsetup
```

Execute:

```text
devsetup.bat
```

Também é possível simplesmente executar o arquivo `devsetup.bat` pelo Windows Explorer.

O script solicitará privilégios de administrador quando necessário.

---

## 🔄 Reinicialização

Alguns recursos do Windows só ficam disponíveis após uma reinicialização.

Quando isso acontecer, o DevSetup informará que o computador precisa ser reiniciado.

Depois do reinício, execute novamente:

```text
devsetup.bat
```

O script verificará o que já foi configurado e continuará o processo sem reinstalar desnecessariamente os componentes encontrados.

---

## 🐧 Ubuntu e WSL

Quando o Ubuntu for instalado pela primeira vez, pode ser necessário iniciá-lo para concluir a configuração inicial.

O Ubuntu solicitará:

```text
username
password
```

Essas credenciais pertencem ao ambiente Linux e são independentes da conta do Windows.

---

## 🐳 Docker

O projeto prepara o Windows para utilizar o **Docker Desktop com WSL 2**.

Depois da configuração, o ambiente pode ser utilizado para desenvolvimento com tecnologias como:

- PHP
- Laravel
- MySQL
- Redis
- Node.js
- Nginx
- PostgreSQL

Esses serviços poderão ser executados posteriormente através de containers Docker específicos para cada projeto.

---

## 🎯 Objetivo

O projeto nasceu durante a preparação do meu próprio ambiente de desenvolvimento.

Além de automatizar a configuração da máquina, o projeto também serve como estudo prático de:

- PowerShell
- Automação
- Git
- Windows
- WSL 2
- Linux
- Docker
- Ambientes de desenvolvimento

---

## 🛣️ Roadmap

Algumas melhorias planejadas:

- [ ] Melhorar tratamento de erros
- [ ] Criar sistema de logs
- [ ] Detectar reinicializações pendentes
- [ ] Permitir selecionar quais ferramentas instalar
- [ ] Adicionar modo somente diagnóstico
- [ ] Adicionar mais ferramentas opcionais
- [ ] Criar releases versionadas
- [ ] Adicionar testes para funções do PowerShell

---

## ⚠️ Aviso

Este projeto modifica recursos opcionais do Windows e pode instalar softwares utilizando o WinGet.

Leia o código antes de executá-lo em ambientes importantes ou corporativos.

O projeto está em desenvolvimento e deve ser utilizado com atenção.

---

## 👨‍💻 Autor

**Kaic Leonardo**

Desenvolvedor focado em desenvolvimento web, backend e automação.

GitHub:  
https://github.com/Kaic-Developer

LinkedIn:  
https://www.linkedin.com/in/kaic-leonardo-087347345/

---

## 📄 Licença

Este projeto é disponibilizado para fins de estudo e desenvolvimento.

Uma licença open source poderá ser adicionada futuramente.