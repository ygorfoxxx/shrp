// ==========================================================
//  Includes\Jutsus\cmd_hotbar.pwn
//  - /listajutsus   (aliases: /lj, /jutsus)
//  - /bindjutsu <id> <selos...>
//  - /unbindjutsu <id>
//  Requer: hotbarpreparacao.pwn (enum + binds + Jutsu_BindSet)
// ==========================================================

#if defined _CMD_HOTBAR_INC
    #endinput
#endif
#define _CMD_HOTBAR_INC

#include <a_samp>
#include <zcmd>
#include <sscanf2>

#include "Includes\Jutsus\hotbarpreparacao.pwn"

// p/ no dar erro se seu GM no tiver:
#if !defined COLOR_WHITE
    #define COLOR_WHITE 0xFFFFFFFF
#endif
#if !defined SendClientMessageEx
    #define SendClientMessageEx(%0,%1,%2) SendClientMessage(%0,%1,%2)
#endif

// Dialog ID (mude se j usa esse nmero em outro lugar)
#define DLG_LISTA_JUTSUS (9410)

// ----------------------------------------------------------
// Buffers globais (evita stack)
// ----------------------------------------------------------
static HBCH_ListBuf[4096];
static HBCH_LineBuf[196];

// ----------------------------------------------------------
// Nome dos Jutsus (index = ID do enum eJutsuId)
// IMPORTANTE: segue a ordem do enum no hotbarpreparacao.
// ----------------------------------------------------------
static const gJutsuNome[][] =
{
    "Katon: Goukakyuu",
    "Katon: Housenka",
    "Katon: Karyuuendan",

    "Raiton: Arashi (I)",
    "Raiton: Raikyuu",
    "Raiton: Nagashi",

    "Suiton: Mizurappa",
    "Suiton: Suikodan",
    "Suiton: Suirou",

    "Futon: Rasengan",
    "Futon: Hanachi",
    "Futon: Shinkuha",
    "Futon: Atsugai",

    "Doton: Iwakai",
    "Doton: Doryuuheki",
    "Doton: Dorojigoku",

    "Transform: Eremita + Susano",
    "Anbu: Barreira (toggle)",
    "Especial: Saberu",
    "Especial: Selamento",
    "Especial: Kinobori",
    "Especial: Kawarimi",
    "Medico: Iryou",
    "Medico: Katsuyu",
    "Medico: Mesu Chakra",
    "Especial: Urushi",

    "Base: Orochimaru (abrir)",
    "Base: Akatsuka (abrir)",
    "Modo: Rato (Senin/Minato)",
    "Modo: Dragao (Minato)",
    "Raijin: Voador",

	"Invocação: Prisão do Sapo", //jutsu invocacao sapo
	
    "Cla: Tigre (varia por cla)",
	
	"Hyuuga: Byakugan",
	"Hyuuga: Hakkeshou Kaiten"


};

stock bool:Jutsu_IsValidId(jutsuId)
{
    if (jutsuId < 0) return false;
    if (jutsuId >= sizeof(gJutsuNome)) return false;
    return true;
}

stock Jutsu_GetNomeLocal(jutsuId, dest[], size)
{
    if (!Jutsu_IsValidId(jutsuId))
    {
        format(dest, size, "INVALID");
        return 0;
    }
    format(dest, size, "%s", gJutsuNome[jutsuId]);
    return 1;
}

// ----------------------------------------------------------
// Normaliza entrada do player em sequncia padro:
// gera sempre: "Tigre, Dragao, " (com ", " no fim)
// ----------------------------------------------------------
// ----------------------------------------------------------
// LISTA (mostra s jutsus liberados)
// ----------------------------------------------------------
stock HB_ShowListaJutsus_Local(playerid)
{
    // Garante que binds estejam carregados (pra quem reloga e j usa sem spawn/login).
    HB_LoadBindsOnce(playerid);

    HBCH_ListBuf[0] = '\0';

    strcat(HBCH_ListBuf, "{FFD400}Selos: {FFFFFF}Tigre=SHIFT | Dragao=C | Rato=H | Cobra=N | Coelho=Y\n", sizeof HBCH_ListBuf);
    strcat(HBCH_ListBuf, "{AAAAAA}Use: {FFFFFF}/bindjutsu <id> <selos...>\n", sizeof HBCH_ListBuf);
    strcat(HBCH_ListBuf, "{AAAAAA}Ex: {FFFFFF}/bindjutsu 21 Cobra Tigre\n\n", sizeof HBCH_ListBuf);

    new count = 0;

    for (new i = 0; i < sizeof(gJutsuNome); i++)
    {
        if (!Jutsu_PlayerTemAcessoByJutsuId(playerid, eJutsuId:i)) continue;

        format(HBCH_LineBuf, sizeof HBCH_LineBuf, "{FFFFFF}%02d {AAAAAA}- {FFFFFF}%s\n", i, gJutsuNome[i]);
        strcat(HBCH_ListBuf, HBCH_LineBuf, sizeof HBCH_ListBuf);
        count++;
    }

    if (!count)
        strcat(HBCH_ListBuf, "{FFFFFF}Voce nao tem jutsus liberados no momento.\n", sizeof HBCH_ListBuf);

    ShowPlayerDialog(playerid, DLG_LISTA_JUTSUS, DIALOG_STYLE_MSGBOX,
        "Seus Jutsus (IDs liberados)", HBCH_ListBuf, "Fechar", "");
    return 1;
}


// ==========================================================
// /bindjutsu <id> <selos...>
// ==========================================================
CMD:bindjutsu(playerid, params[])
{
    new id;
    new raw[256];

    if (sscanf(params, "dS()[256]", id, raw))
    {
        SendClientMessageEx(playerid, COLOR_WHITE,
            "{EF0D02}Use:{FFFFFF} /bindjutsu <id> <selos...>  |  Ex: /bindjutsu 21 Cobra Tigre");
        SendClientMessageEx(playerid, COLOR_WHITE,
            "{AAAAAA}Dica:{FFFFFF} use /listajutsus para ver os IDs.");
        return 1;
    }

    if (!Jutsu_IsValidId(id))
    {
        SendClientMessageEx(playerid, COLOR_WHITE,
            "{EF0D02}(BIND){FFFFFF} ID invalido.");
        return 1;
    }

    if (!Jutsu_PlayerTemAcessoByJutsuId(playerid, eJutsuId:id))
    {
        SendClientMessageEx(playerid, COLOR_WHITE,
            "{EF0D02}(BIND){FFFFFF} Voce ainda nao tem acesso a esse jutsu.");
        return 1;
    }

    new canon[128];
    if (!HBCH_SelosCanonicalize(raw, canon, sizeof canon))
    {
        SendClientMessageEx(playerid, COLOR_WHITE,
            "{EF0D02}Erro:{FFFFFF} Selos invalidos. Use: Tigre/Dragao/Coelho/Rato/Cobra (pode separar por espaco ou virgula).");
        SendClientMessageEx(playerid, COLOR_WHITE,
            "{AAAAAA}Ex:{FFFFFF} /bindjutsu 21 Cobra Tigre  |  /bindjutsu 0 Tigre Dragao Tigre Dragao");
        return 1;
    }

    // Garante load antes de mexer + salva no .ini
    Jutsu_BindSet(playerid, eJutsuId:id, canon);

    new jname[64];
    Jutsu_GetNomeLocal(id, jname, sizeof jname);

    new msg[196];
    format(msg, sizeof msg, "{00FF00}[BIND]{FFFFFF} %s (ID %d) agora ativa com: {FFFF00}%s", jname, id, canon);
    SendClientMessageEx(playerid, COLOR_WHITE, msg);
    return 1;
}

// ==========================================================
// /unbindjutsu <id>
// ==========================================================
CMD:unbindjutsu(playerid, params[])
{
    new id;
    if (sscanf(params, "d", id))
        return SendClientMessageEx(playerid, COLOR_WHITE, "{EF0D02}Use:{FFFFFF} /unbindjutsu <id>");

    if (!Jutsu_IsValidId(id))
        return SendClientMessageEx(playerid, COLOR_WHITE, "{EF0D02}(UNBIND){FFFFFF} ID invalido.");

    // Remove qualquer bind que esteja apontando pra esse jutsu
    Jutsu_BindClearByJutsu(playerid, eJutsuId:id);

    new jname[64];
    Jutsu_GetNomeLocal(id, jname, sizeof jname);

    new msg[160];
    format(msg, sizeof msg, "{00FF00}[BIND]{FFFFFF} Removido bind do jutsu: %s (ID %d).", jname, id);
    SendClientMessageEx(playerid, COLOR_WHITE, msg);
    return 1;
}

// ==========================================================
// /listajutsus + aliases
// ==========================================================
CMD:listajutsus(playerid, params[])
{
    #pragma unused params
    return HB_ShowListaJutsus_Local(playerid);
}

CMD:lj(playerid, params[])
{
    #pragma unused params
    return HB_ShowListaJutsus_Local(playerid);
}

CMD:jutsus(playerid, params[])
{
    #pragma unused params
    return HB_ShowListaJutsus_Local(playerid);
}
