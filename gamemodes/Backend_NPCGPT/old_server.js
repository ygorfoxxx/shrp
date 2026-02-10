// Backend NPCGPT (Gemini) - compatível com HTTP() do SA-MP (CP1252/ANSI)
// - Aceita body em x-www-form-urlencoded vindo do Pawn (bytes CP1252)
// - Responde em text/plain com bytes CP1252 (mantém acentos PT-BR)
// - Remove emojis e caracteres fora do CP1252 para não "bugar" no SA-MP

import "dotenv/config";
import express from "express";
import { GoogleGenerativeAI } from "@google/generative-ai";

const app = express();
// raw = não perde bytes (importante para CP1252 vindo do Pawn)
app.use(express.raw({ type: "*/*", limit: "128kb" }));

const PORT = Number(process.env.PORT || 3333);
const SECRET = String(process.env.NPCGPT_SECRET || "").trim();
const DEBUG = String(process.env.NPCGPT_DEBUG || "0") === "1";

const GEMINI_KEY = String(process.env.GEMINI_API_KEY || "").trim();
const DEFAULT_MODEL = "gemini-1.5-flash-latest";
const GEMINI_MODEL = String(process.env.GEMINI_MODEL || DEFAULT_MODEL).trim();

if (!GEMINI_KEY) console.log("[NPCGPT] AVISO: GEMINI_API_KEY não definida no .env");
if (!SECRET) console.log("[NPCGPT] AVISO: NPCGPT_SECRET não definida no .env");

const genAI = new GoogleGenerativeAI(GEMINI_KEY);

// ---------- CP1252 helpers ----------

function percentDecodeLatin1(s) {
  // decodifica %XX como bytes (0-255), mantendo CP1252/latin1
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
 * Limpa texto para o SA-MP:
 * - mantém acentos (ç, ã, é...) porque SA-MP renderiza em CP1252
 * - remove emojis e símbolos fora do CP1252
 * - remove quebras de linha excessivas (mantém no máx. 2 linhas)
 */
function cleanTextForSAMP(text) {
  if (!text) return "";
  let t = normalizePunctuation(text);

  // remove controles
  t = t.replace(/\r/g, "").trim();

  // limita a 2 linhas
  const lines = t.split("\n").map(l => l.trim()).filter(Boolean).slice(0, 2);
  t = lines.join("\n");

  // remove tudo fora do "range seguro" (ASCII + Latin-1 Supplement)
  // (evita emojis e símbolos que bugam no SA-MP)
  t = t.replace(/[^\x20-\x7E\u00A0-\u00FF\n]/g, "");

  // colapsa espaços
  t = t.replace(/[ \t]{2,}/g, " ").trim();

  return t;
}

function safeStr(v, max = 700) {
  return String(v ?? "").replace(/\r/g, "").slice(0, max);
}

async function listModels() {
  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${encodeURIComponent(
      GEMINI_KEY
    )}`;
    const r = await fetch(url);
    const j = await r.json();
    const models = Array.isArray(j.models) ? j.models : [];
    const usable = models.filter(
      (m) =>
        Array.isArray(m.supportedGenerationMethods) &&
        m.supportedGenerationMethods.includes("generateContent")
    );
    return usable
      .map((m) => m.baseModelId || String(m.name || "").replace(/^models\//, ""))
      .filter(Boolean);
  } catch {
    return [];
  }
}

let cachedModels = null;
async function ensureModelsCache() {
  if (cachedModels) return cachedModels;
  cachedModels = await listModels();
  return cachedModels;
}

async function getWorkingModelName(preferred) {
  if (preferred && preferred !== "gemini-2.0-flash") return preferred;
  const list = await ensureModelsCache();
  return list.includes(DEFAULT_MODEL) ? DEFAULT_MODEL : list[0] || DEFAULT_MODEL;
}

function isModelNotFoundError(e) {
  const msg = String(e?.message || e || "");
  return msg.includes("404") || msg.toLowerCase().includes("not found");
}

app.get("/", (_req, res) => res.status(200).send("OK"));

app.get("/models", async (_req, res) => {
  try {
    const list = await ensureModelsCache();
    res.status(200).json({ models: list });
  } catch (e) {
    res.status(500).json({ error: String(e?.message || e) });
  }
});

app.post("/npc", async (req, res) => {
  const p = parseBody(req.body);

  const gotSecret = String(p.secret || "").trim();
  if (gotSecret !== SECRET) {
    res.set("Content-Type", "text/plain; charset=windows-1252");
    return res.status(403).send(Buffer.from("DENIED", "latin1"));
  }

  const mode = safeStr(p.mode || "chat", 16).toLowerCase();
  const npcname = safeStr(p.npcname || "NPC", 32);
  const msg = safeStr(p.msg || "", 700);

  if (DEBUG) console.log(`[NPCGPT] REQ de ${npcname}: ${msg}`);

  const system = [
    `Você é um NPC chamado ${npcname} em um universo inspirado em shinobis.`,
    "Naruto e personagens do anime NÃO existem nesse universo.",
    "Responda sempre em Português (PT-BR).",
    "Sem emojis. Sem símbolos estranhos.",
    "Responda em no máximo 2 linhas.",
    "Formato: SAY: <fala>  (ou ACT: / SET: quando fizer sentido)",
  ].join("\n");

  const context = `NPC=${npcname}\nMSG=${msg}\nMODE=${mode}`;
  const prompt = `${system}\n\n${context}\n\nResponda agora:`;

  let modelName = await getWorkingModelName(GEMINI_MODEL);

  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const model = genAI.getGenerativeModel({ model: modelName });
      const r = await model.generateContent(prompt);
      const text = (r?.response?.text?.() || "").trim();

      let out = cleanTextForSAMP(text) || "SAY: ...";
      if (!/^((SAY|ACT|SET):)/i.test(out)) out = "SAY: " + out;

      if (DEBUG) console.log(`[NPCGPT] RESP: ${out}`);

      // envia em CP1252/latin1 para o SA-MP renderizar acentos
      const buf = Buffer.from(out, "latin1");
      res.set("Content-Type", "text/plain; charset=windows-1252");
      return res.status(200).send(buf);
    } catch (e) {
      const errorMsg = String(e?.message || e);
      if (DEBUG) console.log(`[NPCGPT] Erro (tentativa ${attempt + 1}):`, errorMsg);

      if (errorMsg.includes("429") || errorMsg.toLowerCase().includes("quota")) {
        await new Promise((r) => setTimeout(r, 2000));
        continue;
      }

      if (isModelNotFoundError(e)) {
        cachedModels = null;
        const list = await ensureModelsCache();
        modelName = list[0] || DEFAULT_MODEL;
        continue;
      }

      const fallback = Buffer.from("SAY: Minha cabeça está doendo agora...", "latin1");
      res.set("Content-Type", "text/plain; charset=windows-1252");
      return res.status(200).send(fallback);
    }
  }
});

app.listen(PORT, "127.0.0.1", () => {
  console.log(`---`);
  console.log(`[NPCGPT] Rodando em http://127.0.0.1:${PORT}`);
  console.log(`[NPCGPT] Limite grátis: ~15 mensagens por minuto.`);
  console.log(`---`);
});
