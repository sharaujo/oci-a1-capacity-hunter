#!/usr/bin/env bash
#
# XUH Hunter — OCI A1 Capacity Hunter
# Desenvolvido por Schubert Araujo
# GitHub: https://github.com/sharaujo
# Projeto: https://github.com/sharaujo/oci-a1-capacity-hunter
#

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL="${XUH_INTERVAL:-60}"
LOG="${XUH_LOG:-${SCRIPT_DIR}/xuh-hunter.log}"
ENV_FILE="${XUH_ENV_FILE:-/etc/xuh-hunter.env}"

if [[ -r "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    set -a
    source "$ENV_FILE"
    set +a
fi

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

log() {
    printf '%s\n' "$1" | tee -a "$LOG"
}

ok() {
    log "✓ $1"
}

notify_telegram() {
    local message="$1"

    [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]] && return 0
    command -v curl >/dev/null 2>&1 || return 0

    curl -fsS \
        -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${message}" \
        >/dev/null 2>&1 || true
}

fatal() {
    log "ERRO: $1"
    notify_telegram "❌ XUH Hunter não pôde iniciar.

$1"
    exit 1
}

has_tf_files() {
    local dir="$1"
    [[ -d "$dir" ]] &&
        find "$dir" -maxdepth 1 -type f -name '*.tf' -print -quit 2>/dev/null | grep -q .
}

detect_terraform_dir() {
    if [[ -n "${XUH_TERRAFORM_DIR:-}" ]]; then
        printf '%s\n' "$XUH_TERRAFORM_DIR"
        return
    fi

    if has_tf_files "${SCRIPT_DIR}/terraform"; then
        printf '%s\n' "${SCRIPT_DIR}/terraform"
        return
    fi

    if has_tf_files "$SCRIPT_DIR"; then
        printf '%s\n' "$SCRIPT_DIR"
        return
    fi

    printf '%s\n' "${SCRIPT_DIR}/terraform"
}

TERRAFORM_DIR="$(detect_terraform_dir)"

log "[XUH Hunter] Verificando ambiente..."

command -v terraform >/dev/null 2>&1 || fatal "Terraform não encontrado no PATH."
ok "Terraform encontrado"

if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || (( INTERVAL < 10 )); then
    fatal "XUH_INTERVAL deve ser um número inteiro de pelo menos 10 segundos."
fi
ok "Intervalo configurado: ${INTERVAL}s"

if ! has_tf_files "$TERRAFORM_DIR"; then
    fatal "Nenhum arquivo .tf encontrado.

Extraia a Stack Terraform da OCI em:
${SCRIPT_DIR}/terraform/

Exemplo:
unzip SUA_STACK.zip -d ${SCRIPT_DIR}/terraform/"
fi

ok "Arquivos Terraform encontrados em: $TERRAFORM_DIR"

cd "$TERRAFORM_DIR" || fatal "Não foi possível acessar: $TERRAFORM_DIR"

log "[XUH Hunter] Inicializando Terraform..."

INIT_OUTPUT=$(terraform init -input=false -no-color 2>&1)
INIT_CODE=$?
printf '%s\n' "$INIT_OUTPUT" >> "$LOG"

if [[ "$INIT_CODE" -ne 0 ]]; then
    log ""
    log "Falha durante terraform init."
    printf '%s\n' "$INIT_OUTPUT" | tail -40 | tee -a "$LOG"
    fatal "terraform init falhou. Corrija o erro acima antes de iniciar o hunter."
fi

ok "Terraform inicializado"

VALIDATE_OUTPUT=$(terraform validate -no-color 2>&1)
VALIDATE_CODE=$?
printf '%s\n' "$VALIDATE_OUTPUT" >> "$LOG"

if [[ "$VALIDATE_CODE" -ne 0 ]]; then
    log ""
    log "Falha durante terraform validate."
    printf '%s\n' "$VALIDATE_OUTPUT" | tail -40 | tee -a "$LOG"
    fatal "terraform validate falhou. Corrija a configuração antes de iniciar o hunter."
fi

ok "Configuração Terraform validada"

log ""
log "========================================"
log "XUH Hunter iniciado em $(date)"
log "Terraform: $TERRAFORM_DIR"
log "Intervalo: ${INTERVAL}s"
log "========================================"

notify_telegram "🟢 XUH Hunter iniciado.

Host: $(hostname)
Terraform: ${TERRAFORM_DIR}
Intervalo: ${INTERVAL}s
Data: $(date)"

ATTEMPT=0

while true; do
    ATTEMPT=$((ATTEMPT + 1))

    log ""
    log "[$(date)] Tentativa #${ATTEMPT}"
    log "Consultando OCI via Terraform..."

    OUTPUT=$(terraform apply \
        -auto-approve \
        -input=false \
        -no-color 2>&1)

    EXIT_CODE=$?

    printf '%s\n' "$OUTPUT" >> "$LOG"

    if [[ "$EXIT_CODE" -eq 0 ]]; then
        log "========================================"
        log "VM/recursos criados com sucesso!"
        log "$(date)"
        log "========================================"

        notify_telegram "✅ XUH HUNTER - SUCESSO!

O Terraform concluiu a criação com sucesso.
Host do hunter: $(hostname)
Tentativa: #${ATTEMPT}
Data: $(date)

O hunter foi encerrado automaticamente."

        exit 0
    fi

    if grep -qiE \
        'out of([[:space:]]+host)?[[:space:]]+capacity|capacity.*unavailable|insufficient.*capacity' \
        <<<"$OUTPUT"; then

        log "Sem capacidade disponível. Nova tentativa em ${INTERVAL}s."
        sleep "$INTERVAL"
        continue
    fi

    log ""
    log "ERRO DIFERENTE DE CAPACIDADE."
    log "Hunter interrompido para evitar tentativas incorretas."

    ERROR_SUMMARY=$(printf '%s\n' "$OUTPUT" | tail -30)
    printf '%s\n' "$ERROR_SUMMARY" | tee -a "$LOG"

    notify_telegram "❌ XUH Hunter interrompido.

O Terraform retornou um erro diferente de falta de capacidade.

Host: $(hostname)
Tentativa: #${ATTEMPT}
Data: $(date)

Verifique:
tail -50 ${LOG}"

    exit 1
done
