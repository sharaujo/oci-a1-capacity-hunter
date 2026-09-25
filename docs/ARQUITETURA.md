# Arquitetura do XUH Hunter

O host de automação é independente da OCI de destino.

```text
┌───────────────────────────────┐
│ Host Linux                    │
│ OCI VM / Homelab / VPS / WSL │
│                               │
│ xuh-hunter.sh                 │
│        ↓                      │
│ Terraform                     │
└───────────────┬───────────────┘
                │ HTTPS
                ▼
          OCI Public API
                │
                ▼
      Tenancy / região alvo
                │
                ▼
       VM.Standard.A1.Flex
```

## Responsabilidades

### Terraform

Define a infraestrutura usando o código gerado pela própria Stack da OCI.

### XUH Hunter

1. localiza os `.tf`;
2. executa `terraform init`;
3. executa `terraform validate`;
4. executa `terraform apply`;
5. repete apenas para capacity;
6. para em erro inesperado;
7. para após sucesso.

### systemd

Opcional. Mantém o hunter ativo após logout, fechamento do SSH ou reboot.

### Telegram

Opcional. Notifica início, sucesso e erro inesperado.

## Multi-tenancy / multi-região

Exemplos válidos:

```text
VM OCI Phoenix / Tenancy A
      │
      ▼
OCI São Paulo / Tenancy B
```

```text
Homelab em casa
      │
      ▼
OCI São Paulo
```

O destino é definido pelas credenciais OCI e pelo Terraform.
