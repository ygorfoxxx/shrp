// Backend NPCGPT (GROQ) - compatível com HTTP() do SA-MP (CP1252/ANSI)
// - Aceita body em x-www-form-urlencoded vindo do Pawn (bytes CP1252)
// - Responde em text/plain com bytes CP1252 (mantém acentos PT-BR)
// - Remove emojis e caracteres fora do CP1252 para não "bugar" no SA-MP
//
// Provider (Plano A): GROQ (OpenAI-compatible)
//   Endpoint: https://api.groq.com/openai/v1/chat/completions
//   Modelo padrão: llama-3.1-8b-instant
//
// Dicas de limite (pra não tomar 429):
// - O limit real é por *API key* (e por modelo). Se você usar vários NPCs, todos somam no mesmo limite.
// - Aqui tem rate limit interno simples (por minuto) para proteger.
//
// .env mínimo:
//   NPCGPT_SECRET=suasenha
//   GROQ_API_KEY=xxxx          (ou GROQ_API_KEYS=key1,key2,key3)
//   NPCGPT_PROVIDER=groq       (default)
//   GROQ_MODEL=llama-3.1-8b-instant
//   NPCGPT_DEBUG=0
//
// Rodar:
//   npm i express dotenv
//   node server.js

import "dotenv/config";
import express from "express";
import fs from "node:fs";

const app = express();
app.use(express.raw({ type: "*/*", limit: "128kb" }));

const PORT = Number(process.env.PORT || 3333);
const SECRET = String(process.env.NPCGPT_SECRET || "").trim();
const DEBUG = String(process.env.NPCGPT_DEBUG || "0") === "1";
const MAX_CHARS = Number(process.env.NPCGPT_MAX_CHARS || 220);

const PROVIDER = String(process.env.NPCGPT_PROVIDER || "groq").trim().toLowerCase();

// GROQ (Plano A)
const GROQ_URL = String(process.env.GROQ_URL || "https://api.groq.com/openai/v1/chat/completions").trim();
const GROQ_MODEL = String(process.env.GROQ_MODEL || "llama-3.1-8b-instant").trim();
const GROQ_KEYS = (
  String(process.env.GROQ_API_KEYS || process.env.GROQ_API_KEY || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
);

// (Opcional) Gemini fallback se você quiser no futuro (não obrigatório)
// const GEMINI_KEY = String(process.env.GEMINI_API_KEY || "").trim();

if (!SECRET) console.log("[NPCGPT] AVISO: NPCGPT_SECRET não definida no .env");
if (PROVIDER === "groq" && GROQ_KEYS.length === 0) console.log("[NPCGPT] AVISO: GROQ_API_KEY/GROQ_API_KEYS não definida no .env");

// ---------------- LORE DO SERVIDOR (arquivo grande) ----------------
// Use com RAG simples pra nao estourar contexto.
// .env:
//   NPCGPT_LORE_MODE=rag|brief|full|off   (default rag)
//   NPCGPT_LORE_PATH=./lore.txt
//   NPCGPT_LORE_BRIEF_PATH=./lore_brief.txt
//   NPCGPT_LORE_SNIPPET_CHARS=1200
//   NPCGPT_LORE_WATCH=1
const LORE_MODE = String(process.env.NPCGPT_LORE_MODE || "rag").trim().toLowerCase();
const LORE_PATH = String(process.env.NPCGPT_LORE_PATH || "./lore.txt").trim();
const LORE_BRIEF_PATH = String(process.env.NPCGPT_LORE_BRIEF_PATH || "./lore_brief.txt").trim();
const LORE_SNIPPET_CHARS = Number(process.env.NPCGPT_LORE_SNIPPET_CHARS || 1200);
const LORE_WATCH = String(process.env.NPCGPT_LORE_WATCH || "1").trim() === "1";

let loreRaw = "";
let loreChunks = [];
let loreBrief = "";
let loreMtimeMs = 0;

function safeReadFile(path) {
  try { return fs.readFileSync(path, "utf8"); } catch { return ""; }
}
function chunkLore(raw) {
  const parts = String(raw || "").split(/\n{2,}/).map(s => s.trim()).filter(Boolean);
  const chunks = [];
  let cur = "";
  for (const p of parts) {
    if (!cur) { cur = p; continue; }
    if ((cur.length + 2 + p.length) <= 900) cur = cur + "\n\n" + p;
    else { chunks.push(cur); cur = p; }
  }
  if (cur) chunks.push(cur);
  return chunks;
}
function reloadLoreIfNeeded() {
  if (LORE_MODE === "off") return;
  try {
    const st = fs.statSync(LORE_PATH);
    if (st.mtimeMs !== loreMtimeMs) {
      loreMtimeMs = st.mtimeMs;
      loreRaw = safeReadFile(LORE_PATH);
      loreChunks = chunkLore(loreRaw);
      loreBrief = safeReadFile(LORE_BRIEF_PATH).trim();
      if (!loreBrief) loreBrief = loreRaw.trim().slice(0, 650);
      if (DEBUG) console.log(`[NPCGPT] Lore recarregado: ${LORE_PATH} (chunks=${loreChunks.length})`);
    }
  } catch {
    loreRaw = "";
    loreChunks = [];
    loreBrief = "";
  }
}
function normTokens(s) {
  return String(s || "")
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s-]+/gu, " ")
    .split(/\s+/)
    .filter(t => t.length >= 3)
    .slice(0, 40);
}
function loreRag(query) {
  if (!loreChunks.length) return "";
  const toks = normTokens(query);
  if (!toks.length) return "";

  const scored = loreChunks.map((c) => {
    const lower = c.toLowerCase();
    let score = 0;
    for (const t of toks) if (lower.includes(t)) score += 1;
    return { c, score };
  }).filter(x => x.score > 0);

  scored.sort((a, b) => b.score - a.score);

  const picked = [];
  let used = 0;
  for (const it of scored.slice(0, 6)) {
    const add = it.c.trim();
    if (!add) continue;
    if (used + add.length + 2 > LORE_SNIPPET_CHARS) break;
    picked.push(add);
    used += add.length + 2;
    if (picked.length >= 3) break;
  }
  return picked.join("\n\n").trim();
}
function getLoreContext({ msg, npcname, persona }) {
  if (LORE_MODE === "off") return "";
  reloadLoreIfNeeded();
  if (!loreRaw) return "";

  if (LORE_MODE === "full") return loreRaw.trim().slice(0, LORE_SNIPPET_CHARS);
  if (LORE_MODE === "brief") return String(loreBrief || "").trim().slice(0, LORE_SNIPPET_CHARS);

  // rag
  const q = `${npcname || ""} ${persona || ""} ${msg || ""}`.trim();
  const rag = loreRag(q);
  const brief = String(loreBrief || "").trim().slice(0, 500);
  if (rag) return (brief ? (brief + "\n\n" + rag) : rag).slice(0, LORE_SNIPPET_CHARS);
  return brief.slice(0, LORE_SNIPPET_CHARS);
}

if (LORE_WATCH && LORE_MODE !== "off") {
  try { fs.watch(LORE_PATH, { persistent: false }, () => reloadLoreIfNeeded()); } catch {}
  try { fs.watch(LORE_BRIEF_PATH, { persistent: false }, () => reloadLoreIfNeeded()); } catch {}
}
reloadLoreIfNeeded();
// ------------------------------------------------------------


// ---------------- CP1252 helpers ----------------

function percentDecodeLatin1(s) {
  const bytes = [];
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (ch === "+") {
      bytes.push(0x20);
      continue;
    }
    if (ch === "%" && i + 2 < s.length) {
      const hex = s.slice(i + 1, i + 3);
      if (/^[0-9a-fA-F]{2}$/.test(hex)) {
        bytes.push(parseInt(hex, 16));
        i += 2;
        continue;
      }
    }
    bytes.push(s.charCodeAt(i) & 0xff);
  }
  return Buffer.from(bytes).toString("latin1");
}

function parseBody(raw) {
  const out = {};
  if (!raw) return out;

  // JSON (caso algum cliente mande assim)
  const asTextUtf8 = Buffer.isBuffer(raw) ? raw.toString("utf8") : String(raw);
  const t = (asTextUtf8 || "").trim();
  if (t.startsWith("{") && t.endsWith("}")) {
    try {
      const obj = JSON.parse(t);
      if (obj && typeof obj === "object") return obj;
    } catch {
      // cai para form
    }
  }

  // x-www-form-urlencoded CP1252
  const s = Buffer.isBuffer(raw) ? raw.toString("latin1") : String(raw);
  for (const part of s.split("&")) {
    if (!part) continue;
    const eq = part.indexOf("=");
    const k = eq === -1 ? part : part.slice(0, eq);
    const v = eq === -1 ? "" : part.slice(eq + 1);
    const key = percentDecodeLatin1(k);
    const val = percentDecodeLatin1(v);
    if (key) out[key] = val;
  }
  return out;
}

function normalizePunctuation(text) {
  return String(text || "")
    // aspas curvas / apóstrofo
    .replace(/[\u2018\u2019\u02BC]/g, "'")
    .replace(/[\u201C\u201D]/g, '"')
    // travessões
    .replace(/[\u2013\u2014]/g, "-")
    // reticências
    .replace(/\u2026/g, "...")
    // NBSP -> espaço
    .replace(/\u00A0/g, " ");
}

/**
 * Sanitiza para SA-MP (CP1252):
 * - remove emojis/símbolos fora do CP1252
 * - limita a 3 linhas
 * - limita total de caracteres (máx. 350)
 */
function cleanTextForSAMP(text) {
  if (!text) return "";
  let t = normalizePunctuation(text);

  // tira \r e aspas perdidas no começo/fim
  t = t.replace(/\r/g, "").trim().replace(/^"+|"+$/g, "");

  // mantém no máx. 3 linhas
  const lines = t
    .split("\n")
    .map((l) => l.trim())
    .filter(Boolean)
    .slice(0, 3);

  t = lines.join("\n");

  // remove fora do range seguro (ASCII + Latin-1 Supplement)
  t = t.replace(/[^\x20-\x7E\u00A0-\u00FF\n]/g, "");

  // colapsa espaços
  t = t.replace(/[ \t]{2,}/g, " ").trim();

  // limita tamanho total
  if (t.length > MAX_CHARS) t = t.slice(0, MAX_CHARS).trim();

  return antiPlayerWords(t);
}

function safeStr(v, max = 900) {
  return String(v ?? "").replace(/\r/g, "").slice(0, max);
}

// ---------------- Rate limit interno (proteção) ----------------
// O seu Pawn já tem cooldown por player. Aqui é uma proteção global simples.
// Default: 28 req/min (pra ficar abaixo de 30 rpm com folga)
const RL_MAX_PER_MIN = Math.max(1, Number(process.env.NPCGPT_RPM || 28));
let rlCount = 0;
let rlWindowStart = Date.now();

function rlAllow() {
  const now = Date.now();
  if (now - rlWindowStart >= 60_000) {
    rlWindowStart = now;
    rlCount = 0;
  }
  if (rlCount >= RL_MAX_PER_MIN) return false;
  rlCount++;
  return true;
}

// ---------------- Memória curta por jogador (pra não ficar "tosco") ----------------
const MEM_MAX_TURNS = Math.max(0, Math.min(10, Number(process.env.NPCGPT_MEM_TURNS || 6))); // 0 desliga
const memory = new Map(); // key = `${slot}:${playerid}` -> [{role, content}...]

function memKey(slot, playerid) {
  return `${slot}:${playerid}`;
}
function memGet(slot, playerid) {
  if (!MEM_MAX_TURNS) return [];
  return memory.get(memKey(slot, playerid)) || [];
}
function memPush(slot, playerid, role, content) {
  if (!MEM_MAX_TURNS) return;
  const k = memKey(slot, playerid);
  const arr = memory.get(k) || [];
  arr.push({ role, content });
  // corta do começo
  while (arr.length > MEM_MAX_TURNS * 2) arr.shift();
  memory.set(k, arr);
}

// ---------------- Groq helpers ----------------
let rrKeyIdx = 0;
function pickGroqKey() {
  if (GROQ_KEYS.length === 0) return "";
  rrKeyIdx = (rrKeyIdx + 1) % GROQ_KEYS.length;
  return GROQ_KEYS[rrKeyIdx];
}

async function groqChat({ messages, temperature, maxTokens }) {
  const apiKey = pickGroqKey();
  if (!apiKey) throw new Error("GROQ_API_KEY não definida.");

  const body = {
    model: GROQ_MODEL,
    messages,
    temperature,
    max_tokens: maxTokens,
  };

  const r = await fetch(GROQ_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const txt = await r.text();
  if (!r.ok) {
    // mantém texto pra debug
    const err = new Error(`Groq HTTP ${r.status}: ${txt.slice(0, 300)}`);
    err.status = r.status;
    throw err;
  }

  const j = JSON.parse(txt);
  const out = j?.choices?.[0]?.message?.content ?? "";
  return String(out);
}

function buildSystemPrompt({ npcname, persona, age, elem, behav, passive, charname, maxChars, loreContext }) {
  const personaLine = persona ? `História/Persona do NPC (use isso como verdade): ${persona}` : "";
  const loreLine = loreContext ? `Lore do servidor (use como CANON):\n${loreContext}` : "";

  // Regras que você pediu:
  // - Até 3 linhas
  // - Pode ser curto (nao forcar encher linguiça)
  // - Pode usar ação no estilo /eu
  // - Fala séria, shinobi do universo do Kishimoto
  return [
    `Você é ${npcname}, um shinobi do universo de Naruto (Masashi Kishimoto). Você é um personagem real desse mundo.`,
    personaLine,
    loreLine,
    `Dados rápidos: idade=${age || "?"} elemento=${elem || "?"} comportamento=${behav || "?"} passivo=${passive || "?"}.`,
    "Responda sempre em PT-BR, sem emojis, sem aspas no começo/fim, e sem meta (não diga que é IA).",
    charname ? `O interlocutor e um PERSONAGEM chamado ${charname}. Trate como personagem (use "voce" ou o nome dele).` : "O interlocutor e um PERSONAGEM. Trate como personagem (use \"voce\").",
    "NUNCA use as palavras jogador, player, usuario. Nunca fale de Groq/IA/tecnologia real; responda como shinobi do mundo.",
    "Evite repetir bordoes e frases inteiras usadas recentemente. Se ja disse algo parecido, reformule.",
    `A resposta deve ter no maximo 3 linhas e no maximo ${maxChars} caracteres no total. Pode ser curta.`,
    "Formato OBRIGATÓRIO por linha:",
    "Se você usar ACT:, você DEVE enviar também uma linha SAY: logo abaixo (ACT na 1ª linha, SAY na 2ª).",
    "Se o player escrever uma ação usando /eu, responda com ACT: (reação/ação do NPC) e em seguida SAY: (fala do NPC).",
    "Quando fizer sentido (ameaça, movimento, intimidação, gestos), use ACT: em vez de descrever a ação dentro do SAY:.",
    "SAY: <fala do NPC>",
    "ou ACT: <ação no estilo /eu, em terceira pessoa, sem nome>  (ex: ACT: observa o céu e ajusta a bandana)",
    "Nunca envie comandos administrativos. Nada de SET: no modo normal.",
  ]
    .filter(Boolean)
    .join("\n");
}

function antiPlayerWords(protocolText) {
  const lines = String(protocolText || "").split("\n");
  const out = lines.map((ln) => {
    const st = ln.trim();
    if (/^ACT:/i.test(st)) {
      return st
        .replace(/\b(o|a)\s+jogador(a)?\b/gi, "a figura a frente")
        .replace(/\bjogador(a)?\b/gi, "a figura")
        .replace(/\bplayer\b/gi, "a figura a frente")
        .replace(/\busu[aá]rio\b/gi, "a figura");
    }
    return st
      .replace(/\b(o|a)\s+jogador(a)?\b/gi, "voce")
      .replace(/\bjogador(a)?\b/gi, "voce")
      .replace(/\bplayer\b/gi, "voce")
      .replace(/\busu[aá]rio\b/gi, "voce");
  });
  return out.join("\n");
}

function parseModelOutputToProtocol(text) {
  // Aceita que o modelo possa mandar multi-linhas.
  let t = cleanTextForSAMP(text);

  // Se não respeitou tags, força SAY:
  if (!/^(SAY:|ACT:)/i.test(t)) t = "SAY: " + t;

  // Limita a 3 linhas explicitamente
  const lines = t.split("\n").slice(0, 3);
  t = lines.join("\n").trim();

  // Se veio ACT sem SAY, o SA-MP acaba mostrando só a ação.
  // Força uma fala curta (2ª linha) para sempre ter ação + fala.
  if (/^ACT:/i.test(t) && !/\n\s*SAY:/i.test(t)) {
    const fall = [
      "SAY: Fala baixo. O que voce quer?",
      "SAY: Sem rodeio. Diz logo.",
      "SAY: Aqui nao e lugar pra conversa alta.",
      "SAY: Se tem segredo, fala perto.",
    ];
    t = `${t}\n${fall[Math.floor(Math.random() * fall.length)]}`;
    t = cleanTextForSAMP(t);
    t = t.split("\n").slice(0, 3).join("\n").trim();
  }

  // Nunca mais que o limite do .env (NPCGPT_MAX_CHARS)
  if (t.length > MAX_CHARS) t = t.slice(0, MAX_CHARS).trim();

  return t;
}

app.get("/", (_req, res) => res.status(200).send("OK"));

app.post("/npc", async (req, res) => {
  const p = parseBody(req.body);

  const gotSecret = String(p.secret || "").trim();
  res.set("Content-Type", "text/plain; charset=windows-1252");
  if (!SECRET || gotSecret !== SECRET) {
    return res.status(403).send(Buffer.from("DENIED", "latin1"));
  }

  // Proteção de rate limit global
  if (!rlAllow()) {
    const buf = Buffer.from("SAY: Aguenta um instante... tem muita gente falando comigo agora.", "latin1");
    return res.status(200).send(buf);
  }

  const mode = safeStr(p.mode || "chat", 16).toLowerCase(); // "chat" ou "admin" (admin não usado aqui)
  const npcname = safeStr(p.npcname || "NPC", 32);
  const charname = safeStr(p.charname || p.playername || "", 32);
  const persona = safeStr(p.persona || "", 520);
  const msg = safeStr(p.msg || "", 900);

  const playerid = Number(p.playerid || 0);
  const slot = Number(p.slot || 0);

  const age = safeStr(p.age || "", 8);
  const elem = safeStr(p.elem || "", 8);
  const behav = safeStr(p.behav || "", 8);
  const passive = safeStr(p.passive || "", 8);

  if (DEBUG) console.log(`[NPCGPT] REQ slot=${slot} player=${playerid}${charname ? " char="+charname : ""} npc=${npcname}: ${msg}`);

  const loreContext = getLoreContext({ msg, npcname, persona });
  const system = buildSystemPrompt({ npcname, persona, age, elem, behav, passive, charname, maxChars: MAX_CHARS, loreContext });

  // memória curta (por player + NPC slot)
  const mem = memGet(slot, playerid);

  // messages OpenAI format
  const messages = [
    { role: "system", content: system },
    ...mem,
    { role: "user", content: msg },
  ];

  try {
    let rawOut = "";

    if (PROVIDER === "groq") {
      rawOut = await groqChat({
        messages,
        temperature: 0.85,
        maxTokens: 160, // suficiente pra ate 3 linhas curtas
      });
    } else {
      rawOut = "SAY: Provedor inválido no servidor.";
    }

    const out = parseModelOutputToProtocol(rawOut) || "SAY: ...";

    // salva memória (somente chat normal)
    if (mode !== "admin") {
      memPush(slot, playerid, "user", msg);
      memPush(slot, playerid, "assistant", out);
    }

    if (DEBUG) console.log(`[NPCGPT] RESP: ${out}`);

    const buf = Buffer.from(out, "latin1");
    return res.status(200).send(buf);
  } catch (e) {
    const errMsg = String(e?.message || e);
    if (DEBUG) console.log("[NPCGPT] ERRO:", errMsg);

    // Se tiver várias keys, o round-robin já tenta reduzir 429.
    const fallback = Buffer.from("SAY: Tô sem chakra pra pensar agora... tenta de novo já já.", "latin1");
    return res.status(200).send(fallback);
  }
});

app.listen(PORT, "127.0.0.1", () => {
  console.log(`---`);
  console.log(`[NPCGPT] Rodando em http://127.0.0.1:${PORT}`);
  console.log(`[NPCGPT] Provider: ${PROVIDER} | Model: ${GROQ_MODEL}`);
  console.log(`[NPCGPT] RPM interno: ${RL_MAX_PER_MIN} req/min (proteção)`);
  console.log(`---`);
});