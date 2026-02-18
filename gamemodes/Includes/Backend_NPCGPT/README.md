# NPCGPT Backend (SHRP)

Esse backend recebe mensagens do SA-MP via `HTTP()` (Pawn) e usa a API da OpenAI para gerar falas do NPC.

## 1) Requisitos
- Node.js 18+ instalado

## 2) Instalar e rodar
1. Abra a pasta `Backend_NPCGPT`
2. Execute `run_windows.bat` (ou rode manualmente: `npm i` e depois `npm start`)
3. Edite o arquivo `.env` e configure:
   - `NPCGPT_SECRET` (um segredo seu)
   - `OPENAI_API_KEY` (sua chave da OpenAI)
   - (opcional) `OPENAI_MODEL`

## 3) Configurar no Pawn
No arquivo `Includes/Npcs/bandidos.pwn`, procure e ajuste:
- `#define NPCGPT_URL "http://127.0.0.1:3333/npc"`
- `#define NPCGPT_SECRET "CHANGE_ME"`

Use o MESMO segredo no `.env`.

## 4) Teste rapido
- Inicie o backend (deve aparecer: `[NPCGPT] rodando em http://127.0.0.1:3333`)
- Inicie o servidor SA-MP
- Crie um NPC:
  `/criarbandido slot=0 tipo=1 skin=305 nome=Bandido gpt=1 dist=4.0 persona="curto e desconfiado"`
- Chegue perto (3~4m) e fale no chat normal. Ele deve responder.

## 5) Modo admin (/npcgpt)
- `/npcgpt` envia a mensagem pro NPC GPT mais proximo.
- O backend pode retornar linha `SET:` para ajustar o NPC (skin, hp, elem, behav, etc).

Dica: use `bandidoinfo` para ver o estado do NPC.

## Seguranca
- Se voce expor isso pra internet, use firewall e escolha um `NPCGPT_SECRET` forte.
- Ideal: rodar backend na mesma maquina do servidor e usar `127.0.0.1`.
