# Pasta Terraform

Coloque aqui os arquivos `.tf` baixados da Stack da OCI.

```bash
unzip /CAMINHO/DA/SUA_STACK.zip -d terraform/
```

Depois:

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

O `xuh-hunter.sh` também executa `terraform init` e `terraform validate` automaticamente antes do loop.

Não faça commit de:

```text
terraform.tfstate
terraform.tfstate.*
.terraform/
chaves
credenciais
```
