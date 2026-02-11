//----------------------------------------------------------
// SHRP - Bandidos (MINIMO)
// Arquivo: bandidos_novo.txt  (ANSI / sem acentos)
// O que fica aqui:
//   1) Menu /criarbandido (wizard) para criar NPC
//   2) NPC tem "vila" (Info[][pMember] + SistemaBandanaIDStatus)
//   3) Jogador pode falar com o NPC pelo chat (bem perto) usando Persona/Historia
//
// IMPORTANTE (integracao):
// - No seu OnDialogResponse do GM, adicione:
//     if(BandidoMenu_OnDialog(playerid, dialogid, response, listitem, inputtext)) return 1;
// - (Opcional) Em OnGameModeExit:
//     Bandido_OnGameModeExit();
//
// Requisitos:
// - a_samp
// - FCNPC
//----------------------------------------------------------

#if defined _SHRP_BANDIDOS_MIN_INCLUDED
    #endinput
#endif
#define _SHRP_BANDIDOS_MIN_INCLUDED

#include <a_samp>

// ----------------------------------------------------------
// HTTP native (compat)
// Alguns packs antigos de a_samp.inc nao declaram HTTP(), mas o SA-MP 0.3.DL tem.
// Isso evita: undefined symbol "HTTP" (inclusive dentro do FCNPC.inc).
// ----------------------------------------------------------
#if !defined HTTP_GET
    #define HTTP_GET (1)
#endif
#if !defined HTTP_POST
    #define HTTP_POST (2)
#endif
#if !defined HTTP_DELETE
    #define HTTP_DELETE (3)
#endif
#if !defined HTTP_PUT
    #define HTTP_PUT (4)
#endif

// declara apenas uma vez (usa macro guarda)
#if !defined _SHRP_HTTP_NATIVE_DECL
    #define _SHRP_HTTP_NATIVE_DECL
    native HTTP(index, type, const url[], const data[], const callback[]);
#endif

#include <FCNPC>


#if !defined HTTP_POST
    #define HTTP_POST (2)
#endif


// ----------------------------------------------------------
// CONFIG
// ----------------------------------------------------------
#if !defined MAXIMO_BANDIDOS
    #define MAXIMO_BANDIDOS (20)
#endif

#define BANDIDO_TALK_DIST_DEFAULT   (6.0)
#define BANDIDO_SAY_RADIUS_DEFAULT  (18.0)


// ----------------------------------------------------------
// NPCGPT (server.js / Groq) - HTTP endpoint
// Server.js esperado (upload do usuario): POST /npc (x-www-form-urlencoded) 
// Campos usados: secret, mode, npcname, persona, msg, playerid, slot 
// Retorno: text/plain (CP1252) com linhas "ACT:" / "SAY:" 
// ----------------------------------------------------------
#if !defined NPCGPT_URL
    #define NPCGPT_URL "127.0.0.1:3333/npc"
#endif

#if !defined NPCGPT_SECRET
    // MESMO valor do .env (NPCGPT_SECRET)
    #define NPCGPT_SECRET "p1rul1t0"
#endif

#define BANDIDO_CHAT_DIST_MIN       (3.0)   // 2~3m como voce pediu
#define BANDIDO_CHAT_COOLDOWN_MS    (1500)  // anti-spam (1.5s)

new gBandidoTalkTick[MAX_PLAYERS];
new bool:gBandidoTalkPending[MAX_PLAYERS];
new gBandidoTalkPendingSlot[MAX_PLAYERS];
new gBandidoTalkHttpId[MAX_PLAYERS];

forward Bandido_TalkHttp(playerid, response_code, data[]);

// Dialogs (mantem base parecida com o seu arquivo original)
#define BANDIDO_DLG_BASE            (24000)
#define DLG_BANDIDO_SLOT            (BANDIDO_DLG_BASE+1)
#define DLG_BANDIDO_OVERWRITE       (BANDIDO_DLG_BASE+2)
#define DLG_BANDIDO_NAME            (BANDIDO_DLG_BASE+3)
#define DLG_BANDIDO_VILA            (BANDIDO_DLG_BASE+4)
#define DLG_BANDIDO_SKIN            (BANDIDO_DLG_BASE+5)
#define DLG_BANDIDO_PERSONA         (BANDIDO_DLG_BASE+6)
#define DLG_BANDIDO_HISTORIA        (BANDIDO_DLG_BASE+7)
#define DLG_BANDIDO_CONFIRM         (BANDIDO_DLG_BASE+8)

// ----------------------------------------------------------
// STORAGE (somente o necessario)
// ----------------------------------------------------------
new gBandidoNpc[MAXIMO_BANDIDOS]; // playerid do FCNPC
new BandidoMember[MAXIMO_BANDIDOS];                        // vila (Info[][pMember])
new BandidoSkin[MAXIMO_BANDIDOS];
new BandidoVW[MAXIMO_BANDIDOS];
new BandidoInterior[MAXIMO_BANDIDOS];
new Float:BandidoSpawn[MAXIMO_BANDIDOS][3];

new BandidoName[MAXIMO_BANDIDOS][32];
new BandidoPersona[MAXIMO_BANDIDOS][128];
new BandidoHistoria[MAXIMO_BANDIDOS][128];
new Float:BandidoTalkDist[MAXIMO_BANDIDOS];

new Text3D:BandidoLabel[MAXIMO_BANDIDOS];

// ----------------------------------------------------------
// MENU (wizard)
// ----------------------------------------------------------
new bool:gBMenuActive[MAX_PLAYERS];
new gBMenuSlot[MAX_PLAYERS];
new gBMenuMember[MAX_PLAYERS];
new gBMenuSkin[MAX_PLAYERS];
new gBMenuName[MAX_PLAYERS][32];
new gBMenuPersona[MAX_PLAYERS][128];
new gBMenuHistoria[MAX_PLAYERS][128];


// ----------------------------------------------------------
// HELPERS
// ----------------------------------------------------------
stock Bandido_IsValidSlot(slot)
{
    return (slot >= 0 && slot < MAXIMO_BANDIDOS);
}

stock Bandido_IsNpcValid(slot)
{
    if(!Bandido_IsValidSlot(slot)) return 0;
    new npcid = gBandidoNpc[slot];
    if(npcid == INVALID_PLAYER_ID) return 0;
    if(!IsPlayerConnected(npcid)) return 0;
    if(!IsPlayerNPC(npcid)) return 0;
    return 1;
}

stock Bandido_GetSlotByPlayerId(playerid)
{
    for(new s=0; s<MAXIMO_BANDIDOS; s++)
    {
        if(gBandidoNpc[s] == playerid) return s;
    }
    return -1;
}

// Para outros sistemas consultarem via CallLocalFunction.
forward Bandido_IsBandidoPlayer(playerid);
public Bandido_IsBandidoPlayer(playerid)
{
    return (Bandido_GetSlotByPlayerId(playerid) != -1);
}

stock Float:NNRP_Dist3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    new Float:dx = (x1 - x2);
    new Float:dy = (y1 - y2);
    new Float:dz = (z1 - z2);
    return floatsqroot(dx*dx + dy*dy + dz*dz);
}


// ----------------------------------------------------------
// URL encode (CP1252 safe) para x-www-form-urlencoded
// - Mantem letras/numeros e -_.~
// - Espaco vira +
// - Outros viram %HH
// ----------------------------------------------------------
stock Bandido_URLEncodeCP1252(const in[], out[], outLen)
{
    new o = 0;
    for(new i=0; in[i] != '\0' && o < outLen-1; i++)
    {
        new c = in[i];
        // espaco
        if(c == ' ')
        {
            if(o < outLen-1) out[o++] = '+';
            continue;
        }

        // unreserved
        if((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') ||
           c == '-' || c == '_' || c == '.' || c == '~')
        {
            out[o++] = c;
            continue;
        }

        // %HH
        if(o < outLen-4)
        {
            static const hex[] = "0123456789ABCDEF";
            out[o++] = '%';
            out[o++] = hex[(c >> 4) & 0xF];
            out[o++] = hex[c & 0xF];
        }
        else break;
    }
    out[o] = '\0';
    return o;
}


// ----------------------------------------------------------
// SA-MP HTTP() em muitos packs NAO aceita "http://" / "https://".
// Por compatibilidade, removemos automaticamente se vier.
// ----------------------------------------------------------
stock Bandido_BuildHttpUrl(out[], outLen)
{
    format(out, outLen, "%s", NPCGPT_URL);

    // remove "http://"
    if( (out[0] == 'h' || out[0] == 'H') &&
        (out[1] == 't' || out[1] == 'T') &&
        (out[2] == 't' || out[2] == 'T') &&
        (out[3] == 'p' || out[3] == 'P') &&
        (out[4] == ':') && (out[5] == '/') && (out[6] == '/') )
    {
        strdel(out, 0, 7);
    }
    // remove "https://"
    else if( (out[0] == 'h' || out[0] == 'H') &&
        (out[1] == 't' || out[1] == 'T') &&
        (out[2] == 't' || out[2] == 'T') &&
        (out[3] == 'p' || out[3] == 'P') &&
        (out[4] == 's' || out[4] == 'S') &&
        (out[5] == ':') && (out[6] == '/') && (out[7] == '/') )
    {
        strdel(out, 0, 8);
    }
    return 1;
}



stock bool:Bandido_PrefixI(const s[], const prefix[])
{
    for(new i=0; prefix[i] != '\0'; i++)
    {
        if(s[i] == '\0') return false;
        if(tolower(s[i]) != tolower(prefix[i])) return false;
    }
    return true;
}


stock Bandido_BuildPersona(slot, out[], outLen)
{
    out[0] = '\0';

    if(BandidoPersona[slot][0])
    {
        format(out, outLen, "Persona: %s", BandidoPersona[slot]);
    }

    if(BandidoHistoria[slot][0])
    {
        if(out[0]) strcat(out, "\n", outLen);
        strcat(out, "Historia: ", outLen);
        strcat(out, BandidoHistoria[slot], outLen);
    }

    // Se vazio, deixa vazio mesmo.
    return 1;
}

stock Bandido_PlayerSayNear(playerid, const msg[], Float:radius = BANDIDO_SAY_RADIUS_DEFAULT)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new vw = GetPlayerVirtualWorld(playerid);

    new pname[32];
    pname[0] = '\0';
    // Preferir nome de personagem do RP (Info[][pNome])
    if(Info[playerid][pNome][0] != '\0')
        format(pname, sizeof pname, "%s", Info[playerid][pNome]);
    else
        GetPlayerName(playerid, pname, sizeof pname);

    new out[220];
    format(out, sizeof out, "%s diz: %s", pname, msg);

    for(new p=0; p<MAX_PLAYERS; p++)
    {
        if(!IsPlayerConnected(p) || IsPlayerNPC(p)) continue;
        if(GetPlayerVirtualWorld(p) != vw) continue;

        new Float:x, Float:y, Float:z;
        GetPlayerPos(p, x, y, z);

        if(NNRP_Dist3D(px, py, pz, x, y, z) <= radius)
        {
            SendClientMessage(p, 0xE6E6E6FF, out);
        }
    }
    return 1;
}

stock Bandido_NpcActNear(slot, const act[], Float:radius = BANDIDO_SAY_RADIUS_DEFAULT)
{
    if(!Bandido_IsNpcValid(slot)) return 0;

    new npcid = gBandidoNpc[slot];
    new Float:nx, Float:ny, Float:nz;
    FCNPC_GetPosition(npcid, nx, ny, nz);

    new vw = BandidoVW[slot];

    new out[220];
    format(out, sizeof out, "* %s %s", BandidoName[slot], act);

    for(new p=0; p<MAX_PLAYERS; p++)
    {
        if(!IsPlayerConnected(p) || IsPlayerNPC(p)) continue;
        if(GetPlayerVirtualWorld(p) != vw) continue;

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(p, px, py, pz);

        if(NNRP_Dist3D(px, py, pz, nx, ny, nz) <= radius)
        {
            SendClientMessage(p, 0xC8C8FFFF, out);
        }
    }
    return 1;
}


stock Bandido_FindNearestSlotToPlayer(playerid, Float:maxDist)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new vw = GetPlayerVirtualWorld(playerid);
    new interior = GetPlayerInterior(playerid);

    new best = -1;
    new Float:bestD = maxDist;

    for(new s=0; s<MAXIMO_BANDIDOS; s++)
    {
        if(!Bandido_IsNpcValid(s)) continue;
        if(BandidoVW[s] != vw) continue;
        if(BandidoInterior[s] != interior) continue;

        new Float:nx, Float:ny, Float:nz;
        FCNPC_GetPosition(gBandidoNpc[s], nx, ny, nz);

        new Float:d = NNRP_Dist3D(px, py, pz, nx, ny, nz);
        if(d <= bestD)
        {
            bestD = d;
            best = s;
        }
    }
    return best;
}

stock Bandido_VilaNome(member, out[], outLen)
{
    switch(member)
    {
        case 1: format(out, outLen, "Konoha");
        case 2: format(out, outLen, "Suna");
        case 3: format(out, outLen, "Kiri");
        case 4: format(out, outLen, "Iwa");
        case 5: format(out, outLen, "Kumo");
        default: format(out, outLen, "Sem bandana");
    }
    return 1;
}

// ----------------------------------------------------------
// VILA / BANDANA
// (mesma ideia do seu arquivo original: Info[][pMember], Info[][pNome], PlayerIsLogado e SistemaBandanaIDStatus)
// ----------------------------------------------------------
stock Bandido_ApplyBandana(slot)
{
    if(!Bandido_IsNpcValid(slot)) return 0;
    new npcid = gBandidoNpc[slot];

    Info[npcid][pMember] = BandidoMember[slot];

    if(BandidoName[slot][0] != '\0')
    {
        format(Info[npcid][pNome], 24, "%s", BandidoName[slot]);
        SetPlayerName(npcid, BandidoName[slot]);
    }

    PlayerIsLogado[npcid] = 1;

    if(funcidx("SistemaBandanaIDStatus") != -1)
    {
        CallLocalFunction("SistemaBandanaIDStatus", "i", npcid);
    }
    return 1;
}

// ----------------------------------------------------------
// LABEL
// ----------------------------------------------------------
stock Bandido_UpdateLabel(slot)
{
    if(!Bandido_IsNpcValid(slot)) return 0;

    if(BandidoLabel[slot] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(BandidoLabel[slot]);
        BandidoLabel[slot] = Text3D:INVALID_3DTEXT_ID;
    }

    new vila[24];
    Bandido_VilaNome(BandidoMember[slot], vila, sizeof vila);
    return 1;
}

// ----------------------------------------------------------
// CREATE / DESTROY
// ----------------------------------------------------------

// ----------------------------------------------------------
// INIT (para compiladores que nao suportam "{..., ...}")
// Chame no seu OnGameModeInit:
//     Bandido_Init();
// ----------------------------------------------------------
stock Bandido_Init()
{
    for(new s=0; s<MAXIMO_BANDIDOS; s++)
    {
        gBandidoNpc[s] = INVALID_PLAYER_ID;
        BandidoLabel[s] = Text3D:INVALID_3DTEXT_ID;
        BandidoMember[s] = 0;
        BandidoSkin[s] = 0;
        BandidoVW[s] = 0;
        BandidoInterior[s] = 0;
        BandidoSpawn[s][0] = 0.0;
        BandidoSpawn[s][1] = 0.0;
        BandidoSpawn[s][2] = 0.0;
        BandidoName[s][0] = '\0';
        BandidoPersona[s][0] = '\0';
        BandidoHistoria[s][0] = '\0';
        BandidoTalkDist[s] = BANDIDO_CHAT_DIST_MIN;
    }
    return 1;
}

stock Bandido_ResetSlot(slot)
{
    gBandidoNpc[slot] = INVALID_PLAYER_ID;
    BandidoMember[slot] = 0;
    BandidoSkin[slot] = 0;
    BandidoVW[slot] = 0;
    BandidoInterior[slot] = 0;
    BandidoSpawn[slot][0] = 0.0;
    BandidoSpawn[slot][1] = 0.0;
    BandidoSpawn[slot][2] = 0.0;
    BandidoName[slot][0] = '\0';
    BandidoPersona[slot][0] = '\0';
    BandidoHistoria[slot][0] = '\0';
    BandidoTalkDist[slot] = BANDIDO_TALK_DIST_DEFAULT;

    if(BandidoLabel[slot] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(BandidoLabel[slot]);
        BandidoLabel[slot] = Text3D:INVALID_3DTEXT_ID;
    }
    return 1;
}

stock Bandido_Destroy(slot)
{
    if(!Bandido_IsValidSlot(slot)) return 0;

    if(BandidoLabel[slot] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(BandidoLabel[slot]);
        BandidoLabel[slot] = Text3D:INVALID_3DTEXT_ID;
    }

    if(Bandido_IsNpcValid(slot))
    {
        FCNPC_Destroy(gBandidoNpc[slot]);
    }

    Bandido_ResetSlot(slot);
    return 1;
}

stock Bandido_Create(slot, skinid, const name[], member, const persona[], const historia[])
{
    if(!Bandido_IsValidSlot(slot)) return 0;

    if(gBandidoNpc[slot] != INVALID_PLAYER_ID) Bandido_Destroy(slot);

    BandidoMember[slot] = member;
    BandidoSkin[slot] = skinid;
    format(BandidoName[slot], sizeof BandidoName[], "%s", name);
    format(BandidoPersona[slot], sizeof BandidoPersona[], "%s", persona);
    format(BandidoHistoria[slot], sizeof BandidoHistoria[], "%s", historia);

    if(BandidoTalkDist[slot] < 1.5) BandidoTalkDist[slot] = BANDIDO_TALK_DIST_DEFAULT;

    new npcid = FCNPC_Create(BandidoName[slot]);
    if(npcid == INVALID_PLAYER_ID) return 0;

    gBandidoNpc[slot] = npcid;

    FCNPC_Spawn(npcid, BandidoSkin[slot], BandidoSpawn[slot][0], BandidoSpawn[slot][1], BandidoSpawn[slot][2]);

    SetPlayerVirtualWorld(npcid, BandidoVW[slot]);
    SetPlayerInterior(npcid, BandidoInterior[slot]);

    Bandido_ApplyBandana(slot);
    Bandido_UpdateLabel(slot);

    return 1;
}

stock Bandido_OnGameModeExit()
{
    for(new s=0; s<MAXIMO_BANDIDOS; s++)
    {
        if(gBandidoNpc[s] != INVALID_PLAYER_ID)
            Bandido_Destroy(s);
    }
    return 1;
}

// ----------------------------------------------------------
// MENU (WIZARD)
// ----------------------------------------------------------
stock BandidoMenu_Reset(playerid)
{
    gBMenuActive[playerid] = true;
    gBMenuSlot[playerid] = -1;
    gBMenuMember[playerid] = 0;
    gBMenuSkin[playerid] = GetPlayerSkin(playerid);

    gBMenuName[playerid][0] = '\0';
    gBMenuPersona[playerid][0] = '\0';
    gBMenuHistoria[playerid][0] = '\0';
    return 1;
}

stock BandidoMenu_ShowSlot(playerid)
{
    new list[2048];
    list[0] = '\0';
    strcat(list, "Slot\tStatus\n");

    for(new s=0; s<MAXIMO_BANDIDOS; s++)
    {
        new line[128];
        if(gBandidoNpc[s] == INVALID_PLAYER_ID)
            format(line, sizeof line, "%d\tLivre\n", s);
        else
            format(line, sizeof line, "%d\tOcupado: %s\n", s, BandidoName[s]);
        strcat(list, line);
    }

    ShowPlayerDialog(playerid, DLG_BANDIDO_SLOT, DIALOG_STYLE_TABLIST_HEADERS,
        "Criar NPC - Slot", list, "Selecionar", "Cancelar");
    return 1;
}

stock BandidoMenu_Start(playerid)
{
    BandidoMenu_Reset(playerid);
    return BandidoMenu_ShowSlot(playerid);
}


// Chame isso no seu OnDialogResponse do GM:
// if(BandidoMenu_OnDialog(playerid, dialogid, response, listitem, inputtext)) return 1;
stock BandidoMenu_OnDialog(playerid, dialogid, response, listitem, inputtext[])
{
    if(!gBMenuActive[playerid]) return 0;

    switch(dialogid)
    {
        case DLG_BANDIDO_SLOT:
        {
            if(!response){ gBMenuActive[playerid] = false; return 1; }

            new slot = listitem;
            if(!Bandido_IsValidSlot(slot)) return BandidoMenu_ShowSlot(playerid);

            gBMenuSlot[playerid] = slot;

            if(gBandidoNpc[slot] != INVALID_PLAYER_ID)
            {
                ShowPlayerDialog(playerid, DLG_BANDIDO_OVERWRITE, DIALOG_STYLE_MSGBOX,
                    "Slot Ocupado",
                    "Esse slot ja tem um NPC.\nDeseja substituir?",
                    "Sim", "Nao");
                return 1;
            }

            ShowPlayerDialog(playerid, DLG_BANDIDO_NAME, DIALOG_STYLE_INPUT,
                "Nome do NPC",
                "Digite o nome do NPC (ex: Guarda Iwa):",
                "OK", "Voltar");
            return 1;
        }
        case DLG_BANDIDO_OVERWRITE:
        {
            if(!response) return BandidoMenu_ShowSlot(playerid);

            new slot = gBMenuSlot[playerid];
            if(Bandido_IsValidSlot(slot) && gBandidoNpc[slot] != INVALID_PLAYER_ID)
                Bandido_Destroy(slot);

            ShowPlayerDialog(playerid, DLG_BANDIDO_NAME, DIALOG_STYLE_INPUT,
                "Nome do NPC",
                "Digite o nome do NPC (ex: Guarda Iwa):",
                "OK", "Voltar");
            return 1;
        }
        case DLG_BANDIDO_NAME:
        {
            if(!response) return BandidoMenu_ShowSlot(playerid);

            if(strlen(inputtext) < 2)
                return ShowPlayerDialog(playerid, DLG_BANDIDO_NAME, DIALOG_STYLE_INPUT,
                    "Nome do NPC",
                    "Nome muito curto.\nDigite novamente:",
                    "OK", "Voltar"), 1;

            format(gBMenuName[playerid], sizeof gBMenuName[], "%s", inputtext);

            ShowPlayerDialog(playerid, DLG_BANDIDO_VILA, DIALOG_STYLE_LIST,
                "Vila / Bandana",
                "Sem bandana (0)\nKonoha (1)\nSuna (2)\nKiri (3)\nIwa (4)\nKumo (5)",
                "OK", "Voltar");
            return 1;
        }
        case DLG_BANDIDO_VILA:
        {
            if(!response)
                return ShowPlayerDialog(playerid, DLG_BANDIDO_NAME, DIALOG_STYLE_INPUT,
                    "Nome do NPC", "Digite o nome do NPC:", "OK", "Voltar"), 1;

            gBMenuMember[playerid] = listitem;

            new msg[140];
            format(msg, sizeof msg, "Digite o SkinID do NPC.\n\nSugestao: sua skin atual = %d", GetPlayerSkin(playerid));
            ShowPlayerDialog(playerid, DLG_BANDIDO_SKIN, DIALOG_STYLE_INPUT,
                "SkinID", msg, "OK", "Voltar");
            return 1;
        }
        case DLG_BANDIDO_SKIN:
        {
            if(!response)
                return ShowPlayerDialog(playerid, DLG_BANDIDO_VILA, DIALOG_STYLE_LIST,
                    "Vila / Bandana",
                    "Sem bandana (0)\nKonoha (1)\nSuna (2)\nKiri (3)\nIwa (4)\nKumo (5)",
                    "OK", "Voltar"), 1;

            if(strlen(inputtext) < 1)
                return ShowPlayerDialog(playerid, DLG_BANDIDO_SKIN, DIALOG_STYLE_INPUT,
                    "SkinID", "Digite um numero (SkinID).", "OK", "Voltar"), 1;

            new skin = strval(inputtext);
            if(skin < 0 || skin > 311)
                return ShowPlayerDialog(playerid, DLG_BANDIDO_SKIN, DIALOG_STYLE_INPUT,
                    "SkinID", "SkinID invalido.\nDigite novamente:", "OK", "Voltar"), 1;

            gBMenuSkin[playerid] = skin;

            ShowPlayerDialog(playerid, DLG_BANDIDO_PERSONA, DIALOG_STYLE_INPUT,
                "Persona (jeito de falar)",
                "Opcional.\nEx: rabugento, desconfiado, fala baixo.\nDeixe vazio se nao quiser.",
                "OK", "Pular");
            return 1;
        }
        case DLG_BANDIDO_PERSONA:
        {
            if(response && strlen(inputtext) >= 2)
                format(gBMenuPersona[playerid], sizeof gBMenuPersona[], "%s", inputtext);
            else
                gBMenuPersona[playerid][0] = '?';

            ShowPlayerDialog(playerid, DLG_BANDIDO_HISTORIA, DIALOG_STYLE_INPUT,
                "Historia (curta)",
                "Opcional.\nEx: Ex-ninja que foi expulso, vive de bicos e conhece segredos.\nDeixe vazio se nao quiser.",
                "OK", "Pular");
            return 1;
        }
        case DLG_BANDIDO_HISTORIA:
        {
            if(response && strlen(inputtext) >= 2)
                format(gBMenuHistoria[playerid], sizeof gBMenuHistoria[], "%s", inputtext);
            else
                gBMenuHistoria[playerid][0] = '?';

            new vila[24];
            Bandido_VilaNome(gBMenuMember[playerid], vila, sizeof vila);

            new conf[420];
            format(conf, sizeof conf,
                "Confirme a criacao:\n\nSlot: %d\nNome: %s\nVila: %s\nSkin: %d\nPersona: %s\nHistoria: %s\n\nCriar agora no seu local?",
                gBMenuSlot[playerid],
                gBMenuName[playerid],
                vila,
                gBMenuSkin[playerid],
                (gBMenuPersona[playerid][0] ? gBMenuPersona[playerid] : "(vazio)"),
                (gBMenuHistoria[playerid][0] ? gBMenuHistoria[playerid] : "(vazio)")
            );

            ShowPlayerDialog(playerid, DLG_BANDIDO_CONFIRM, DIALOG_STYLE_MSGBOX,
                "Confirmar", conf, "Criar", "Voltar");
            return 1;
        }
        case DLG_BANDIDO_CONFIRM:
        {
            if(!response) return BandidoMenu_ShowSlot(playerid);

            new slot = gBMenuSlot[playerid];
            if(!Bandido_IsValidSlot(slot))
                return BandidoMenu_ShowSlot(playerid), 1;

            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);

            BandidoSpawn[slot][0] = x;
            BandidoSpawn[slot][1] = y;
            BandidoSpawn[slot][2] = z;

            BandidoVW[slot] = GetPlayerVirtualWorld(playerid);
            BandidoInterior[slot] = GetPlayerInterior(playerid);
            BandidoTalkDist[slot] = BANDIDO_CHAT_DIST_MIN;

            Bandido_Create(slot,
                gBMenuSkin[playerid],
                gBMenuName[playerid],
                gBMenuMember[playerid],
                gBMenuPersona[playerid],
                gBMenuHistoria[playerid]
            );

            SendClientMessage(playerid, 0x40FF40FF, "[NPC] Criado. Pra conversar, fique bem perto e fale no chat.");
            gBMenuActive[playerid] = false;
            return 1;
        }
    }

    return 0;
}


// ----------------------------------------------------------
// TALK
// ----------------------------------------------------------
stock Bandido_SayNear(slot, const msg[], Float:radius = BANDIDO_SAY_RADIUS_DEFAULT)
{
    if(!Bandido_IsNpcValid(slot)) return 0;

    new npcid = gBandidoNpc[slot];
    new Float:nx, Float:ny, Float:nz;
    FCNPC_GetPosition(npcid, nx, ny, nz);

    new vw = BandidoVW[slot];

    new out[220];
    format(out, sizeof out, "%s diz: %s", BandidoName[slot], msg);

    for(new p=0; p<MAX_PLAYERS; p++)
    {
        if(!IsPlayerConnected(p) || IsPlayerNPC(p)) continue;
        if(GetPlayerVirtualWorld(p) != vw) continue;

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(p, px, py, pz);

        if(NNRP_Dist3D(px, py, pz, nx, ny, nz) <= radius)
        {
            SendClientMessage(p, 0xE6E6E6FF, out);
        }
    }
    return 1;
}

stock bool:Bandido_StrHas(const text[], const needle[])
{
    return (strfind(text, needle, true) != -1);
}


stock Bandido_HandleTalk(slot, playerid, const msg[])
{
    // distancia curta (2~3m) e cooldown
    new Float:px, Float:py, Float:pz, Float:nx, Float:ny, Float:nz;
    GetPlayerPos(playerid, px, py, pz);
    FCNPC_GetPosition(gBandidoNpc[slot], nx, ny, nz);

    if(NNRP_Dist3D(px, py, pz, nx, ny, nz) > BANDIDO_CHAT_DIST_MIN)
    {
        SendClientMessage(playerid, 0xFF4040FF, "[NPC] Chega mais perto (2~3m) pra conversar.");
        return 1;
    }

    new now = GetTickCount();
    if(now - gBandidoTalkTick[playerid] < BANDIDO_CHAT_COOLDOWN_MS)
    {
        SendClientMessage(playerid, 0xFFB84DFF, "[NPC] Calma. Espera um pouco antes de falar de novo.");
        return 1;
    }
    gBandidoTalkTick[playerid] = now;

    if(gBandidoTalkPending[playerid])
    {
        SendClientMessage(playerid, 0xFFB84DFF, "[NPC] Aguarda a resposta...");
        return 1;
    }

    // Mostra a fala do player localmente (na area)
    Bandido_PlayerSayNear(playerid, msg, 18.0);

    // Monta form-urlencoded pro server.js (/npc) 
    new personaRaw[600];
    Bandido_BuildPersona(slot, personaRaw, sizeof personaRaw);

    new charRaw[32];
    charRaw[0] = '\0';
    if(Info[playerid][pNome][0] != '\0')
        format(charRaw, sizeof charRaw, "%s", Info[playerid][pNome]);
    else
        GetPlayerName(playerid, charRaw, sizeof charRaw);

    new encNpc[96], encChar[96], encPersona[1200], encMsg[1200];
    Bandido_URLEncodeCP1252(BandidoName[slot], encNpc, sizeof encNpc);
    Bandido_URLEncodeCP1252(charRaw, encChar, sizeof encChar);
    Bandido_URLEncodeCP1252(personaRaw, encPersona, sizeof encPersona);
    Bandido_URLEncodeCP1252(msg, encMsg, sizeof encMsg);

    new data[2048];
    format(data, sizeof data,
        "secret=%s&mode=chat&npcname=%s&charname=%s&persona=%s&msg=%s&playerid=%d&slot=%d",
        NPCGPT_SECRET, encNpc, encChar, encPersona, encMsg, playerid, slot
    );

    // Dispara HTTP
    gBandidoTalkPending[playerid] = true;
    gBandidoTalkPendingSlot[playerid] = slot;

    new url[128];
    Bandido_BuildHttpUrl(url, sizeof url);
    gBandidoTalkHttpId[playerid] = HTTP(playerid, HTTP_POST, url, data, "Bandido_TalkHttp");
    return 1;
}



// ----------------------------------------------------------
// HTTP callback (server.js -> Groq)
// - Espera linhas SAY:/ACT: e envia pra area
// ----------------------------------------------------------
public Bandido_TalkHttp(playerid, response_code, data[])
{
    gBandidoTalkPending[playerid] = false;

    new slot = gBandidoTalkPendingSlot[playerid];
    if(!Bandido_IsNpcValid(slot)) return 1;

    if(response_code != 200 || !data[0])
    {
        Bandido_SayNear(slot, "Tô sem chakra pra pensar agora... tenta de novo.", 18.0);
        return 1;
    }

    // data ja vem em CP1252/text plain, pode ter \n
    new buf[1024];
    format(buf, sizeof buf, "%s", data);

    // processa ate 6 linhas (server.js pode quebrar linha grande)
    new line[220];
    new pos = 0;
    for(new i=0; i<6; i++)
    {
        line[0] = '\0';

        // pega ate \n
        new j = 0;
        while(buf[pos] != '\0' && buf[pos] != '\n' && j < sizeof(line)-1)
        {
            line[j++] = buf[pos++];
        }
        line[j] = '\0';
        if(buf[pos] == '\n') pos++;

        if(!line[0]) continue;

        // trim simples
        while(line[0] == ' ') strdel(line, 0, 1);
        // trim final (remove \r e espacos no fim)
        new ll = strlen(line);
        while(ll > 0 && (line[ll-1] == '\r' || line[ll-1] == ' ')) { line[ll-1] = '\0'; ll--; }

        if(Bandido_PrefixI(line, "ACT:"))
        {
            // remove prefixo "ACT:"
            new act[180];
            if(strlen(line) > 4) strmid(act, line, 4, strlen(line), sizeof act);
            else act[0] = '\0';
            while(act[0] == ' ') strdel(act, 0, 1);
            if(act[0]) Bandido_NpcActNear(slot, act, 18.0);
        }
        else if(Bandido_PrefixI(line, "SAY:"))
        {
            new say[180];
            if(strlen(line) > 4) strmid(say, line, 4, strlen(line), sizeof say);
            else say[0] = '\0';
            while(say[0] == ' ') strdel(say, 0, 1);
            if(say[0]) Bandido_SayNear(slot, say, 18.0);
        }
        else
        {
            Bandido_SayNear(slot, line, 18.0);
        }
    }

    return 1;
}


// ----------------------------------------------------------
// CMDs
// ----------------------------------------------------------
#if defined CMD

CMD:criarbandido(playerid, params[])
{
    #pragma unused params
    // Sem params = abre wizard (igual a ideia do seu arquivo original) ?filecite?turn10file2?L24-L29?
    // Params sao ignorados (fica somente menu, como voce pediu).
    return BandidoMenu_Start(playerid);
}

#endif


// ----------------------------------------------------------
// CHAT HOOK
// Coloque no seu GM (OnPlayerText):
//     if(Bandido_OnPlayerText(playerid, text)) return 0; // bloqueia chat global quando conversar
// ----------------------------------------------------------
stock Bandido_OnPlayerText(playerid, text[])
{
    if(!IsPlayerConnected(playerid) || IsPlayerNPC(playerid)) return 0;

    // ignora comandos e mensagens vazias
    if(!text[0] || text[0] == '/' || text[0] == '!') return 0;

    new slot = Bandido_FindNearestSlotToPlayer(playerid, BANDIDO_CHAT_DIST_MIN);
    if(slot == -1) return 0;

    // manda pro NPC
    Bandido_HandleTalk(slot, playerid, text);
    return 1;
}