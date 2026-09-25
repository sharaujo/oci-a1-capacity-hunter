# Gerando o Terraform pela própria OCI

O fluxo recomendado do XUH Hunter é **não montar manualmente um `terraform.tfvars` gigante**.

A própria OCI gera o Terraform correspondente à VM configurada visualmente.

## 1. Configure a VM

```text
Compute
→ Instances
→ Create instance
```

Configure nome, A1 Flex, OCPUs, memória, imagem, rede, IP público, boot volume e SSH public key.

## 2. Faça um Create manual para validar

Clique em **Create** uma vez.

Se houver capacidade, a instância poderá ser criada e você não precisa do hunter.

Se aparecer:

```text
Out of capacity for shape VM.Standard.A1.Flex...
```

ou:

```text
Out of host capacity
```

esse é o cenário do XUH Hunter.

## 3. Salve como Stack

Use:

```text
Save as stack
```

## 4. Abra o Resource Manager

```text
Resource Manager
→ Stacks
```

Abra a Stack e baixe a:

```text
Terraform configuration
```

## 5. Extraia no projeto

```bash
git clone https://github.com/sharaujo/oci-a1-capacity-hunter.git
cd oci-a1-capacity-hunter

unzip /CAMINHO/DA/SUA_STACK.zip -d terraform/
```

Confira:

```bash
find terraform -maxdepth 1 -type f -name '*.tf' -print
```

Exemplo:

```text
terraform/main.tf
```

### Extraí na raiz por engano

O XUH Hunter detecta `.tf` na raiz por compatibilidade.

Mesmo assim, recomendamos:

```bash
mv ./*.tf terraform/
```

Se você já gerou state na raiz:

```bash
mv terraform.tfstate* terraform/ 2>/dev/null || true
```

## 6. Valide manualmente

```bash
cd terraform
terraform init
terraform plan
```

Revise todo o plano.

Depois faça **uma tentativa**:

```bash
terraform apply -auto-approve
```

O cenário esperado é:

```text
Error: 500-InternalError, Out of host capacity.
```

Se houver outro erro, corrija antes.

## 7. Inicie o hunter

```bash
cd ..
./xuh-hunter.sh
```

O script executa automaticamente:

```text
terraform init
terraform validate
terraform apply
```

e só repete o `apply` quando reconhecer falta de capacidade.
