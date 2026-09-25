# XUH Hunter — OCI A1 Capacity Hunter

> Automatiza novas tentativas de criação de instâncias **OCI `VM.Standard.A1.Flex`** quando a região retorna **`Out of host capacity`**.

**Execute em qualquer Linux. Crie na tenancy e região OCI que você quiser.**

Desenvolvido por **Schubert Araujo**  
GitHub: [@sharaujo](https://github.com/sharaujo) · LinkedIn: [linkedin.com/in/sharaujo](https://www.linkedin.com/in/sharaujo/)

---

## O problema

Em algumas regiões da Oracle Cloud Infrastructure, uma configuração válida de instância A1 pode falhar temporariamente com:

```text
500-InternalError, Out of host capacity.
```

Nessa situação, repetir manualmente a criação pela Console pode ser trabalhoso. O **XUH Hunter** automatiza somente essas novas tentativas legítimas usando **Terraform**, pode permanecer ativo via **systemd** e pode avisar via **Telegram** quando a instância for criada.

> [!IMPORTANT]
> O XUH Hunter **não contorna quotas, limites, políticas ou controles de capacidade da OCI**. Ele apenas automatiza novas tentativas através das APIs/providers oficiais. Erros que não sejam relacionados à falta de capacidade interrompem o hunter.

---

## Onde posso executar?

O host que executa o XUH Hunter **não precisa** estar na mesma tenancy, na mesma região ou sequer dentro da Oracle Cloud.

Ele precisa apenas de:

- Linux;
- acesso à Internet;
- Terraform;
- credenciais válidas para a tenancy OCI de destino.

| Host que executa o hunter | Funciona? |
|---|:---:|
| VM em outra conta OCI | ✅ |
| VM em outra região OCI | ✅ |
| Homelab Linux | ✅ |
| VM no Proxmox | ✅ |
| Raspberry Pi / mini PC | ✅ |
| VPS de outro provedor | ✅ |
| AWS / Azure / GCP | ✅ |
| Notebook Linux ligado continuamente | ✅ |
| WSL para testes manuais | ✅ |

### Cenário A — uma OCI criando em outra OCI

```text
Conta OCI A / outra região
        │
        ▼
  Host Linux 24x7
        │
        │ Terraform + OCI API
        ▼
Conta OCI B / região alvo
        │
        ▼
 VM.Standard.A1.Flex
```

### Cenário B — homelab criando na OCI

```text
Homelab / Proxmox / Raspberry / Linux
                 │
                 │ Internet
                 ▼
             XUH Hunter
                 │
                 ▼
              OCI API
                 │
                 ▼
          VM.Standard.A1.Flex
```

---

## Como funciona

```text
┌──────────────────────────────┐
│ Host Linux                   │
│                              │
│ systemd (opcional)           │
│       ↓                      │
│ xuh-hunter.sh                │
│       ↓                      │
│ terraform apply              │
└──────────────┬───────────────┘
               │
               ▼
             OCI API
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
Out of capacity       Sucesso
       │                │
       ▼                ▼
   aguarda          VM criada
       │                │
       └── retry        ▼
                     Telegram
                        │
                        ▼
                       fim
```

O hunter continua **somente** quando identifica um erro de capacidade. Se aparecer autenticação inválida, quota, subnet incorreta, imagem inválida ou outro erro inesperado, ele para.

---

## Diferenciais

- roda em praticamente qualquer Linux;
- não depende de GitHub Actions;
- não depende de estar dentro da OCI;
- pode executar em uma tenancy/região e criar em outra;
- usa a configuração Terraform gerada pela própria Console da OCI;
- não obriga o usuário a montar `tfvars` manualmente;
- executa `terraform init` automaticamente quando o hunter inicia;
- retry somente para erros reconhecidos de capacidade;
- encerra automaticamente após sucesso;
- encerra em erros inesperados;
- pode sobreviver a reboot via systemd;
- logs persistentes;
- Telegram opcional;
- intervalo de retry configurável;
- detecta Terraform tanto em `terraform/` quanto, por compatibilidade, na raiz do projeto.

---

# Fluxo recomendado

```text
1. Configurar acesso à API OCI
        ↓
2. Criar a VM visualmente na Console
        ↓
3. Save as Stack
        ↓
4. Baixar o Terraform gerado pela OCI
        ↓
5. Extrair para a pasta terraform/
        ↓
6. terraform plan
        ↓
7. terraform apply (uma tentativa manual)
        ↓
8. Confirmar "Out of host capacity"
        ↓
9. Executar XUH Hunter
        ↓
10. Opcional: instalar como serviço systemd
```

---

# Instalação

## 1. Clone o repositório

```bash
git clone https://github.com/sharaujo/oci-a1-capacity-hunter.git
cd oci-a1-capacity-hunter
```

## 2. Pré-requisitos

Você precisa de:

- `git`;
- Terraform;
- OCI CLI configurado com API Signing Key;
- acesso à Internet;
- `curl` apenas se desejar Telegram.

O projeto **não assume uma distribuição específica**. Instale Terraform e OCI CLI pelo método adequado à sua distribuição.

Valide:

```bash
terraform version
oci --version
```

## 3. Configure a API da OCI

Se ainda não configurou o acesso da máquina Linux à tenancy OCI de destino:

**[docs/CONFIGURACAO-OCI.md](docs/CONFIGURACAO-OCI.md)**

Ao final, este comando deve funcionar sem pedir senha da chave:

```bash
oci iam availability-domain list --output table
```

## 4. Monte a instância pela Console da OCI

Na tenancy/região de destino:

```text
Compute
→ Instances
→ Create instance
```

Configure normalmente:

- nome da VM;
- `VM.Standard.A1.Flex`;
- OCPUs;
- memória;
- imagem;
- VCN/subnet;
- IP público, se necessário;
- boot volume;
- chave SSH pública.

Você pode clicar em **Create** uma vez para validar. Se a única falha for `Out of host capacity`, esse é exatamente o cenário do XUH Hunter.

## 5. Save as Stack

Na tela de criação, use:

```text
Save as stack
```

Depois abra a Stack no Resource Manager e faça o download da **Terraform configuration**.

Guia detalhado:

**[docs/STACK-TERRAFORM.md](docs/STACK-TERRAFORM.md)**

## 6. Extraia a Stack para `terraform/`

A forma recomendada é:

```bash
unzip /CAMINHO/DA/SUA_STACK.zip -d terraform/
```

Confirme:

```bash
find terraform -maxdepth 1 -type f -name '*.tf' -print
```

Você deve ver algo como:

```text
terraform/main.tf
```

> Se você extrair o `main.tf` na raiz do projeto por engano, o XUH Hunter também consegue detectá-lo. Porém, para manter o repositório organizado, prefira `terraform/`.

## 7. Valide o Terraform manualmente

Entre na pasta que contém o `.tf`:

```bash
cd terraform
```

Inicialize:

```bash
terraform init
```

Planeje:

```bash
terraform plan
```

Para uma Stack criada exclusivamente para uma nova VM, o normal é algo semelhante a:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

Revise o plano. Não continue se houver exclusões ou alterações inesperadas.

Agora faça **uma tentativa manual**:

```bash
terraform apply -auto-approve
```

O cenário esperado é:

```text
Error: 500-InternalError, Out of host capacity.
```

Se aparecer outro erro, corrija-o primeiro.

Volte para a raiz:

```bash
cd ..
```

## 8. Execute o XUH Hunter

```bash
chmod +x xuh-hunter.sh
./xuh-hunter.sh
```

Na primeira execução, ele verifica o ambiente e executa `terraform init` automaticamente.

Exemplo:

```text
[XUH Hunter] Verificando ambiente...
✓ Terraform encontrado
✓ Arquivos Terraform encontrados
✓ Terraform inicializado

========================================
XUH Hunter iniciado...
========================================

Tentativa #1
Consultando OCI...
Sem capacidade disponível. Nova tentativa em 60s.
```

O intervalo padrão é 60 segundos.

Para usar outro intervalo:

```bash
XUH_INTERVAL=120 ./xuh-hunter.sh
```

O valor mínimo aceito pelo script é 10 segundos. Para uso contínuo, recomendamos intervalos mais conservadores, como 60–120 segundos.

---

# Telegram — opcional

O hunter funciona sem Telegram.

Para receber avisos de:

- início;
- sucesso;
- erro inesperado;

siga:

**[docs/TELEGRAM.md](docs/TELEGRAM.md)**

O token **não fica dentro do script**. A configuração recomendada é:

```text
/etc/xuh-hunter.env
```

---

# Rodando como serviço

Depois de validar manualmente o hunter, instale o serviço:

```bash
sudo ./install.sh
```

O instalador detecta automaticamente:

- seu usuário Linux;
- o diretório real do clone;
- o diretório que contém os arquivos Terraform.

Ele mostra tudo antes de criar o serviço.

Não é necessário substituir manualmente usuário ou caminhos.

### Status

```bash
systemctl status xuh-hunter
```

### Logs

```bash
journalctl -u xuh-hunter -f
```

### Parar

```bash
sudo systemctl stop xuh-hunter
```

### Iniciar

```bash
sudo systemctl start xuh-hunter
```

### WSL

O teste manual com:

```bash
./xuh-hunter.sh
```

funciona normalmente no WSL.

O `install.sh` exige um Linux com **systemd ativo**. Em instalações WSL sem systemd habilitado, use o hunter manualmente ou habilite systemd no WSL antes de instalar o serviço.

---

# Estrutura do projeto

```text
oci-a1-capacity-hunter/
├── README.md
├── LICENSE
├── .gitignore
├── xuh-hunter.sh
├── install.sh
├── systemd/
│   └── xuh-hunter.service.template
├── terraform/
│   └── README.md
└── docs/
    ├── ARQUITETURA.md
    ├── CONFIGURACAO-OCI.md
    ├── STACK-TERRAFORM.md
    ├── TELEGRAM.md
    └── TROUBLESHOOTING.md
```

---

# Segurança

Nunca publique:

```text
~/.oci/config
*.pem
*.key
*.ppk
terraform.tfstate
terraform.tfstate.*
terraform.tfvars
.env
tokens
chat IDs
SSH private keys
```

O `.gitignore` deste projeto já bloqueia os padrões mais comuns, mas **sempre revise `git status` antes do commit**:

```bash
git status
```

---

# Comportamento em erros

| Situação | Ação |
|---|---|
| `Out of host capacity` | aguarda e tenta novamente |
| capacidade insuficiente reconhecida | aguarda e tenta novamente |
| sucesso do Terraform | avisa e encerra |
| autenticação inválida | encerra |
| quota/limite | encerra |
| subnet/imagem inválida | encerra |
| erro Terraform inesperado | encerra |
| `terraform init` falhou | encerra antes do loop |

Isso evita transformar o projeto em um loop cego.

---

# Documentação

- **[Configuração da API OCI](docs/CONFIGURACAO-OCI.md)**
- **[Gerando a Stack Terraform](docs/STACK-TERRAFORM.md)**
- **[Telegram](docs/TELEGRAM.md)**
- **[Arquitetura](docs/ARQUITETURA.md)**
- **[Troubleshooting](docs/TROUBLESHOOTING.md)**

---

# Roadmap

- [ ] backoff exponencial opcional;
- [ ] notificações via Discord;
- [ ] notificações via Slack;
- [ ] ntfy;
- [ ] métricas Prometheus;
- [ ] container/Docker;
- [ ] múltiplas configurações Terraform;
- [ ] múltiplos Availability Domains;
- [ ] integração opcional com OCI Capacity Report;
- [ ] testes automatizados do shell.

---

# Autor

**Schubert Araujo**

Cloud Infrastructure · DevOps · Automation

- GitHub: [github.com/sharaujo](https://github.com/sharaujo)
- LinkedIn: [linkedin.com/in/sharaujo](https://www.linkedin.com/in/sharaujo/)

Contribuições, issues e pull requests são bem-vindos.

---

## Licença

MIT. Consulte [LICENSE](LICENSE).
