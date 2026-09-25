# Configuração da API OCI

Este guia prepara **qualquer host Linux** para autenticar na Oracle Cloud Infrastructure usando uma **API Signing Key**.

O host pode estar dentro da OCI, em outra tenancy/região, em homelab, Proxmox, Raspberry Pi, mini PC, outro cloud ou VPS.

A localização do host não determina a tenancy ou região de destino. Isso é definido pelas **credenciais OCI** e pelo Terraform.

## 1. Instale o OCI CLI

Depois valide:

```bash
oci --version
```

## 2. Localize o usuário no portal OCI

Entre na **tenancy que receberá a nova VM**.

O caminho visual pode mudar, mas normalmente passa por:

```text
Identity & Security
→ Domains
→ Default domain (ou seu domínio)
→ Users
→ selecione o usuário
```

O objetivo é chegar à página do usuário e localizar:

```text
API Keys
```

Você pode usar um usuário existente ou criar um usuário dedicado à automação.

## 3. Permissões IAM

O usuário precisa fazer parte de um grupo com permissões suficientes para os recursos presentes na Stack Terraform.

Em um cenário típico de Compute, ele precisa conseguir:

- criar/gerenciar instâncias no compartment alvo;
- usar a VCN/subnet escolhida;
- criar/usar volumes;
- ler/usar a imagem selecionada;
- consultar Availability Domains e informações necessárias.

> Evite conceder `Administrator` global somente para fazer o hunter funcionar.

## 4. Gere uma chave API dedicada

```bash
mkdir -p ~/.oci
chmod 700 ~/.oci
```

Chave privada sem passphrase:

```bash
openssl genrsa -out ~/.oci/xuh_hunter.pem 2048
chmod 600 ~/.oci/xuh_hunter.pem
```

Pública:

```bash
openssl rsa \
  -pubout \
  -in ~/.oci/xuh_hunter.pem \
  -out ~/.oci/xuh_hunter_public.pem
```

## 5. Cadastre a pública no portal

```bash
cat ~/.oci/xuh_hunter_public.pem
```

Na página do usuário:

```text
API Keys
→ Add API Key
→ Paste Public Key
```

Cole tudo:

```text
-----BEGIN PUBLIC KEY-----
...
-----END PUBLIC KEY-----
```

A OCI exibirá o fingerprint.

## 6. Pegue os dados

Você precisará de:

- User OCID;
- Tenancy OCID;
- Fingerprint;
- Região.

Exemplo de região:

```text
sa-saopaulo-1
```

## 7. Configure `~/.oci/config`

```bash
nano ~/.oci/config
```

Exemplo:

```ini
[DEFAULT]
user=ocid1.user.oc1..COLOQUE_SEU_USER_OCID_AQUI
fingerprint=COLOQUE_O_FINGERPRINT_AQUI
key_file=/home/COLOQUE_SEU_USUARIO_LINUX_AQUI/.oci/xuh_hunter.pem
tenancy=ocid1.tenancy.oc1..COLOQUE_SEU_TENANCY_OCID_AQUI
region=COLOQUE_SUA_REGIAO_AQUI
```

Proteja:

```bash
chmod 600 ~/.oci/config
```

## 8. Teste

```bash
oci iam availability-domain list --output table
```

Se funcionar sem pedir passphrase, está pronto.

## Alternativa: `oci setup config`

Também é possível:

```bash
oci setup config
```

Para automação, certifique-se de que a chave final configurada em `key_file=` não exija digitação de passphrase.

## API Key x SSH Key

**API Signing Key** autentica OCI CLI/Terraform/API.

**SSH Public Key** é inserida na futura VM para acesso ao sistema operacional.

Nunca publique chaves privadas.
