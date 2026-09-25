# Notificações via Telegram

Telegram é opcional.

O bot avisa quando:

- o hunter inicia;
- o Terraform conclui com sucesso;
- ocorre erro diferente de falta de capacidade.

## 1. Crie o bot

No Telegram, abra:

```text
@BotFather
```

Envie:

```text
/newbot
```

Escolha nome e username terminado em `bot`.

Nunca publique o token.

## 2. Inicie conversa com o bot

Clique em **Start** e envie uma mensagem.

## 3. Descubra o Chat ID

```bash
curl -s "https://api.telegram.org/botCOLOQUE_SEU_TOKEN_AQUI/getUpdates"
```

Procure:

```json
"chat": {
  "id": 123456789
}
```

## 4. Teste

```bash
curl -s \
  -X POST \
  "https://api.telegram.org/botCOLOQUE_SEU_TOKEN_AQUI/sendMessage" \
  -d "chat_id=COLOQUE_SEU_CHAT_ID_AQUI" \
  --data-urlencode "text=Teste do XUH Hunter"
```

## 5. Configure

```bash
sudo nano /etc/xuh-hunter.env
```

```env
TELEGRAM_BOT_TOKEN=COLOQUE_SEU_TOKEN_AQUI
TELEGRAM_CHAT_ID=COLOQUE_SEU_CHAT_ID_AQUI
```

```bash
sudo chmod 600 /etc/xuh-hunter.env
```

Em execução manual, se preferir:

```bash
export TELEGRAM_BOT_TOKEN="SEU_TOKEN"
export TELEGRAM_CHAT_ID="SEU_CHAT_ID"

./xuh-hunter.sh
```
