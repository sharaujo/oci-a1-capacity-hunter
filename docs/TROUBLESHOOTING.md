# Troubleshooting

## `Nenhum arquivo .tf encontrado`

Extraia a Stack:

```bash
unzip SUA_STACK.zip -d terraform/
```

Confirme:

```bash
find terraform -maxdepth 1 -type f -name '*.tf' -print
```

## `Terraform initialized in an empty directory`

Você executou `terraform init` em um diretório sem `.tf`.

Use:

```bash
cd terraform
terraform init
```

ou execute da raiz:

```bash
./xuh-hunter.sh
```

O hunter detecta o diretório correto.

## `Inconsistent dependency lock file`

Execute:

```bash
cd terraform
terraform init
```

O XUH Hunter atualizado também executa `terraform init` automaticamente antes do loop.

## `Out of host capacity`

É o erro tratado com retry.

## `NotAuthorizedOrNotFound`

Verifique API key, OCIDs, fingerprint, tenancy e policies.

Teste:

```bash
oci iam availability-domain list --output table
```

## `Password was not given but private key is encrypted`

A API private key exige passphrase.

Para automação unattended, use uma chave dedicada sem passphrase e proteja com:

```bash
chmod 600 ~/.oci/xuh_hunter.pem
```

## `LimitExceeded`

Não é falta temporária de host. Verifique quotas/limites. O hunter para.

## `TooManyRequests`

Aumente o intervalo e investigue:

```bash
XUH_INTERVAL=120 ./xuh-hunter.sh
```

## `InvalidParameter`

Corrija a Stack/configuração. Não use retry infinito.

## Telegram não envia

Teste a API do Telegram diretamente e confira `/etc/xuh-hunter.env`.

## `systemd` não está ativo

Confira:

```bash
ps -p 1 -o comm=
```

Se não retornar `systemd`, use:

```bash
./xuh-hunter.sh
```

ou habilite systemd no ambiente.

## Logs

```bash
journalctl -u xuh-hunter -f
```

```bash
tail -f xuh-hunter.log
```
