#!/usr/bin/env bash
#
# Instalador do serviço systemd do XUH Hunter
# Desenvolvido por Schubert Araujo
#

set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo "Execute com sudo:"
    echo "  sudo ./install.sh"
    exit 1
fi

if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
    echo "ERRO: não foi possível identificar o usuário Linux que executará o hunter."
    echo "Execute este instalador a partir do seu usuário normal usando sudo."
    exit 1
fi

REAL_USER="$SUDO_USER"
USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_PATH="/etc/systemd/system/xuh-hunter.service"
ENV_PATH="/etc/xuh-hunter.env"

has_tf_files() {
    local dir="$1"
    [[ -d "$dir" ]] &&
        find "$dir" -maxdepth 1 -type f -name '*.tf' -print -quit 2>/dev/null | grep -q .
}

if has_tf_files "$SCRIPT_DIR/terraform"; then
    TERRAFORM_DIR="$SCRIPT_DIR/terraform"
elif has_tf_files "$SCRIPT_DIR"; then
    TERRAFORM_DIR="$SCRIPT_DIR"
else
    echo "ERRO: nenhum arquivo .tf foi encontrado."
    echo
    echo "Extraia primeiro a Stack Terraform da OCI em:"
    echo "  $SCRIPT_DIR/terraform/"
    echo
    echo "Exemplo:"
    echo "  unzip SUA_STACK.zip -d \"$SCRIPT_DIR/terraform/\""
    exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
    echo "ERRO: Terraform não encontrado no PATH."
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "ERRO: systemctl não está disponível neste Linux."
    echo "Você ainda pode executar manualmente:"
    echo "  ./xuh-hunter.sh"
    exit 1
fi

if [[ "$(ps -p 1 -o comm= 2>/dev/null || true)" != "systemd" ]]; then
    echo "ERRO: systemd não está ativo como PID 1."
    echo
    echo "Isso é comum em algumas instalações WSL."
    echo "O XUH Hunter pode ser executado manualmente com:"
    echo "  ./xuh-hunter.sh"
    echo
    echo "Para instalar o serviço, habilite systemd no seu ambiente primeiro."
    exit 1
fi

cat <<INFO

XUH Hunter - instalação do serviço

Usuário Linux detectado : $REAL_USER
Home detectado          : $USER_HOME
Diretório do projeto    : $SCRIPT_DIR
Diretório Terraform     : $TERRAFORM_DIR
Serviço                 : $SERVICE_PATH
Config Telegram         : $ENV_PATH (opcional)

INFO

read -r -p "Deseja continuar? [y/N] " ANSWER
case "$ANSWER" in
    y|Y|yes|YES|s|S|sim|SIM) ;;
    *) echo "Instalação cancelada."; exit 0 ;;
esac

chmod +x "$SCRIPT_DIR/xuh-hunter.sh"

cat > "$SERVICE_PATH" <<SERVICE
[Unit]
Description=XUH Hunter - OCI A1 Capacity Hunter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$SCRIPT_DIR
Environment=XUH_TERRAFORM_DIR=$TERRAFORM_DIR
EnvironmentFile=-$ENV_PATH
ExecStart=$SCRIPT_DIR/xuh-hunter.sh
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable xuh-hunter.service

echo
read -r -p "Deseja iniciar o XUH Hunter agora? [y/N] " START_NOW
case "$START_NOW" in
    y|Y|yes|YES|s|S|sim|SIM)
        systemctl restart xuh-hunter.service
        echo
        systemctl --no-pager --full status xuh-hunter.service || true
        ;;
    *)
        echo "Serviço instalado e habilitado."
        echo "Para iniciar depois:"
        echo "  sudo systemctl start xuh-hunter"
        ;;
esac

echo
echo "Comandos úteis:"
echo "  systemctl status xuh-hunter"
echo "  journalctl -u xuh-hunter -f"
echo "  sudo systemctl stop xuh-hunter"
