#if defined _NNRP_MENTOR_SKILLBAR_V7_
    #endinput
#endif
#define _NNRP_MENTOR_SKILLBAR_V7_

/*
    NNRP - Mentor/Bind SkillBar (v7)
    =================================
    - Grid dinAmico (padrAo 5 colunas x 2 linhas).
    - NAO mostra a barra se o player nAo tiver nenhum jutsu bindado.
    - Evita a5 em cima e 4 em baixoa desalinhado:
        * por padrAo, mostra APENAS Acones bindados
        * cada linha A centralizada separadamente
      (se preferir manter espaAos vazios pra ficar sempre 5x2, use /msbempty 0)

    - CustomizaAAo IN-GAME por comandos:
        /mentorbar                 -> liga/desliga (sA3 aparece se tiver bind)
        /msbpos <centerX> <baseY>  -> posiAAo (baseY = linha de baixo)
        /msbsize <px>              -> tamanho do Acone
        /msbgap <px>               -> espaAamento X
        /msbgapy <px>              -> espaAamento Y
        /msbcols <1..10>           -> colunas
        /msbrows <1..6>            -> linhas
        /msbmax <1..24>            -> mAximo de Acones mostrados
        /msbempty <0/1>            -> 1=oculta vazios (padrAo), 0=mostra placeholders
        /msbreset                  -> reset padrAo
        /msbinfo                   -> ver config

    Requisitos:
    - Inclua este mA3dulo DEPOIS do hotbarpreparacao.pwn (gBindJutsu / JUTSU_MAX_BINDS).
    - Para o cooldown visual (tint) funcionar, mantenha no GM um PUBLIC:
          public MSB_GetJutsuCooldownEnd(playerid, jid)
      (retorna gettime()+segundos). Se nAo existir, sA3 fica anormala.
*/

#include <a_samp>
#include <zcmd>
#include <sscanf2>

// --------------------
// Visual (cooldown)
// --------------------
#define MSB_DEFAULT_SPRITE      ("InventSkill:Nada")
#define MSB_COLOR_READY         (-1)
#define MSB_COLOR_COOLDOWN      (0xFF777777)
#define MSB_TICK_MS             (450)

// --------------------
// Defaults (por player)
// --------------------
#define MSB_DEF_CENTER_X        (320.0)
#define MSB_DEF_BASE_Y          (420.0)
#define MSB_DEF_ICON_SIZE       (20.0)
#define MSB_DEF_GAP_X           (0.0)
#define MSB_DEF_GAP_Y           (0.0)
#define MSB_DEF_COLS            (5)
#define MSB_DEF_ROWS            (2)
#define MSB_DEF_MAX             (10)
#define MSB_DEF_HIDE_EMPTY      (1) // 0 = mantem grid sempre "cheio" (5x2), 1 = esconde slots vazios

#define MSB_MSG_ON              (0x00FF66AA)
#define MSB_MSG_OFF             (0xFF5A4EAA)

#define DLG_MSB_SELOS         (29990)

// limite local (hotbar usa 24)
#if defined JUTSU_MAX_BINDS
    #define MSB_BIND_MAX         (JUTSU_MAX_BINDS)
#else
    #define MSB_BIND_MAX         (24)
#endif

#define MSB_MAX_SLOTS            (24) // mAximo de Acones desenhados pelo mA3dulo

// --------------------
// Estado por player
// --------------------
new bool:gMSB_Enabled[MAX_PLAYERS];
new bool:gMSB_Visible[MAX_PLAYERS];
new bool:gMSB_WantVisible[MAX_PLAYERS]; // user preference
new bool:gMSB_Created[MAX_PLAYERS];
new gMSB_Timer[MAX_PLAYERS];

new Float:gMSB_CenterX[MAX_PLAYERS];
new Float:gMSB_BaseY[MAX_PLAYERS];
new Float:gMSB_IconSize[MAX_PLAYERS];
new Float:gMSB_GapX[MAX_PLAYERS];
new Float:gMSB_GapY[MAX_PLAYERS];
new gMSB_Cols[MAX_PLAYERS];
new gMSB_Rows[MAX_PLAYERS];
new gMSB_MaxIcons[MAX_PLAYERS];
new bool:gMSB_HideEmpty[MAX_PLAYERS];

new PlayerText:gMSB_TD[MAX_PLAYERS][MSB_MAX_SLOTS];
new gMSB_Count[MAX_PLAYERS];
new gMSB_Jid[MAX_PLAYERS][MSB_MAX_SLOTS];

new bool:gMSB_Cool[MAX_PLAYERS][MSB_MAX_SLOTS];

// ----------------------------------------------------------
// Util
// ----------------------------------------------------------
static stock MSB_ClampInt(value, minv, maxv)
{
    if (value < minv) return minv;
    if (value > maxv) return maxv;
    return value;
}

static stock Float:MSB_ClampFloat(Float:value, Float:minv, Float:maxv)
{
    if (value < minv) return minv;
    if (value > maxv) return maxv;
    return value;
}

static stock MSB_GetCooldownEnd(playerid, jid)
{
    if (funcidx("MSB_GetJutsuCooldownEnd") != -1)
    {
        return CallLocalFunction("MSB_GetJutsuCooldownEnd", "dd", playerid, jid);
    }
    return 0;
}

static stock MSB_IsValidJid(jid)
{
    #if defined JID_INVALID
        return (jid != _:JID_INVALID);
    #else
        return (jid != -1);
    #endif
}

// ----------------------------------------------------------
// Sprite mapping
// ----------------------------------------------------------
stock MSB_GetSpriteByJid(jid, out[], outSize)
{
    format(out, outSize, "%s", MSB_DEFAULT_SPRITE);
    if (!MSB_IsValidJid(jid)) return 1;

    #if defined JID_GOUKAKYUU
    switch (jid)
    {
        case JID_GOUKAKYUU:         return format(out, outSize, "InventSkill:Goukakyuu");
        case JID_HOUSENKA:          return format(out, outSize, "InventSkill:Housenka");
        case JID_KARYUUENDAN:       return format(out, outSize, "InventSkill:KaryuuEndan");

        case JID_ARASHI_I:          return format(out, outSize, "InventSkill:Arashi");
        case JID_RAIKYUU:           return format(out, outSize, "InventSkill:Raikyuu");
        case JID_NAGASHI:           return format(out, outSize, "InventSkill:Nagashi");

        case JID_MIZURAPPA:         return format(out, outSize, "InventSkill:Mizurappa");
        case JID_SUIKODAN:          return format(out, outSize, "InventSkill:Suikodan");
        case JID_SUIROU:            return format(out, outSize, "InventSkill:Suirou");

        case JID_RASENGAN:          return format(out, outSize, "InventSkill:Rasengan");
        case JID_KINOBI:            return format(out, outSize, "InventSkill:Kinobori");
        case JID_KAWARIMI:          return format(out, outSize, "InventSkill:Kawarimi");

        case JID_IRYOU:             return format(out, outSize, "InventSkill:Iryou");
        case JID_KATSUYU:           return format(out, outSize, "InventSkill:Katsuyu");
        case JID_MESU:              return format(out, outSize, "InventSkill:Mesu");
        case JID_URUSHI:            return format(out, outSize, "InventSkill:Urushi");
    }
    #else
    // fallback mAnimo
    switch (jid)
    {
        case 0: return format(out, outSize, "InventSkill:Goukakyuu");
    }
    #endif

    return 1;
}

// ----------------------------------------------------------
// Create/Destroy
// ----------------------------------------------------------
static stock MSB_Destroy(playerid)
{
    if (!gMSB_Created[playerid]) return 1;

    for (new i = 0; i < gMSB_Count[playerid]; i++)
    {
        PlayerTextDrawHide(playerid, gMSB_TD[playerid][i]);
        PlayerTextDrawDestroy(playerid, gMSB_TD[playerid][i]);
    }

    gMSB_Created[playerid] = false;
    gMSB_Count[playerid] = 0;
    return 1;
}

static stock MSB_Show(playerid)
{
    if (!gMSB_Created[playerid]) return 1;
    for (new i = 0; i < gMSB_Count[playerid]; i++) PlayerTextDrawShow(playerid, gMSB_TD[playerid][i]);
    return 1;
}

static stock MSB_Hide(playerid)
{
    if (!gMSB_Created[playerid]) return 1;
    for (new i = 0; i < gMSB_Count[playerid]; i++) PlayerTextDrawHide(playerid, gMSB_TD[playerid][i]);
    return 1;
}

// ----------------------------------------------------------
// Layout + Build
// ----------------------------------------------------------
static stock MSB_BuildList(playerid)
{
    // monta lista de jids que serAo exibidos
    new count = 0;

    #if defined gBindJutsu
        for (new i = 0; i < MSB_BIND_MAX; i++)
        {
            new jid = _:gBindJutsu[playerid][i];
            if (!MSB_IsValidJid(jid)) continue;
            gMSB_Jid[playerid][count] = jid;
            count++;
            if (count >= gMSB_MaxIcons[playerid]) break;
            if (count >= MSB_MAX_SLOTS) break;
        }
    #endif

    // se nao tem nenhum bind, nao mostra a barra
    if (count <= 0)
    {
        gMSB_Count[playerid] = 0;
        return 0;
    }

    if (!gMSB_HideEmpty[playerid])
    {
        // preenche placeholders pra manter grid "cheio"
        new target = gMSB_MaxIcons[playerid];
        target = MSB_ClampInt(target, 1, MSB_MAX_SLOTS);
        while (count < target)
        {
            gMSB_Jid[playerid][count] = -1;
            count++;
        }
    }

    gMSB_Count[playerid] = count;
    return count;
}

static stock MSB_Rebuild(playerid)
{
    MSB_Destroy(playerid);

    new count = MSB_BuildList(playerid);
    if (count <= 0)
    {
        gMSB_Visible[playerid] = false;
        return 1;
    }

    // limita colunas/linhas
    new cols = MSB_ClampInt(gMSB_Cols[playerid], 1, 10);
    new rows = MSB_ClampInt(gMSB_Rows[playerid], 1, 6);

    // limita mAximo de Acones ao tamanho do grid
    new gridCap = cols * rows;
    if (count > gridCap) count = gridCap;
    if (count > MSB_MAX_SLOTS) count = MSB_MAX_SLOTS;

    gMSB_Count[playerid] = count;

    new Float:centerX = gMSB_CenterX[playerid];
    new Float:baseY   = gMSB_BaseY[playerid];
    new Float:size    = gMSB_IconSize[playerid];
    new Float:gapX    = gMSB_GapX[playerid];
    new Float:gapY    = gMSB_GapY[playerid];

    // quantas linhas efetivas vamos usar
    new usedRows = (count + cols - 1) / cols;
    if (usedRows < 1) usedRows = 1;
    if (usedRows > rows) usedRows = rows;

    new idx = 0;
    for (new r = 0; r < usedRows; r++)
    {
        new remaining = count - (r * cols);
        new inRow = (remaining >= cols) ? cols : remaining;
        if (inRow <= 0) break;

        // centraliza a linha pelo nAomero de itens dela
        new Float:rowW = (size * float(inRow)) + (gapX * float(inRow - 1));
        new Float:leftX = centerX - (rowW * 0.5);

        // baseY A linha de baixo
        new Float:y = baseY - float((usedRows - 1) - r) * (size + gapY);

        for (new c = 0; c < inRow; c++)
        {
            new Float:x = leftX + float(c) * (size + gapX);

            new sprite[64];
            MSB_GetSpriteByJid(gMSB_Jid[playerid][idx], sprite, sizeof sprite);

            gMSB_TD[playerid][idx] = CreatePlayerTextDraw(playerid, x, y, sprite);
            PlayerTextDrawFont(playerid, gMSB_TD[playerid][idx], 4);
            PlayerTextDrawLetterSize(playerid, gMSB_TD[playerid][idx], 0.600000, 2.000000);
            PlayerTextDrawTextSize(playerid, gMSB_TD[playerid][idx], size, size);
            PlayerTextDrawSetOutline(playerid, gMSB_TD[playerid][idx], 1);
            PlayerTextDrawSetShadow(playerid, gMSB_TD[playerid][idx], 0);
            PlayerTextDrawAlignment(playerid, gMSB_TD[playerid][idx], 1);
            PlayerTextDrawColor(playerid, gMSB_TD[playerid][idx], MSB_COLOR_READY);
            PlayerTextDrawBackgroundColor(playerid, gMSB_TD[playerid][idx], 255);
            PlayerTextDrawUseBox(playerid, gMSB_TD[playerid][idx], 0);
            PlayerTextDrawSetProportional(playerid, gMSB_TD[playerid][idx], 1);
            PlayerTextDrawSetSelectable(playerid, gMSB_TD[playerid][idx], 0);

            gMSB_Cool[playerid][idx] = false;
            idx++;
            if (idx >= count) break;
        }
        if (idx >= count) break;
    }

    gMSB_Created[playerid] = true;

    // aplica cooldown visual jA na criaAAo
    for (new i = 0; i < gMSB_Count[playerid]; i++)
    {
        new jid = gMSB_Jid[playerid][i];
        new end = MSB_GetCooldownEnd(playerid, jid);
        new bool:isCd = (end > 0 && end > gettime());
        gMSB_Cool[playerid][i] = isCd;
        PlayerTextDrawColor(playerid, gMSB_TD[playerid][i], isCd ? MSB_COLOR_COOLDOWN : MSB_COLOR_READY);
    }

    return 1;
}

// ----------------------------------------------------------
// Tick
// ----------------------------------------------------------
forward MSB_Tick(playerid);
public MSB_Tick(playerid)
{
    if (!IsPlayerConnected(playerid) || !gMSB_Visible[playerid] || !gMSB_Created[playerid])
    {
        if (gMSB_Timer[playerid])
        {
            KillTimer(gMSB_Timer[playerid]);
            gMSB_Timer[playerid] = 0;
        }
        return 0;
    }

    for (new i = 0; i < gMSB_Count[playerid]; i++)
    {
        new jid = gMSB_Jid[playerid][i];
        new end = MSB_GetCooldownEnd(playerid, jid);
        new bool:isCd = (end > 0 && end > gettime());
        if (gMSB_Cool[playerid][i] == isCd) continue;
        gMSB_Cool[playerid][i] = isCd;
        PlayerTextDrawColor(playerid, gMSB_TD[playerid][i], isCd ? MSB_COLOR_COOLDOWN : MSB_COLOR_READY);
        PlayerTextDrawShow(playerid, gMSB_TD[playerid][i]);
    }
    return 1;
}

static stock MSB_StartTick(playerid)
{
    if (gMSB_Timer[playerid]) return 1;
    gMSB_Timer[playerid] = SetTimerEx("MSB_Tick", MSB_TICK_MS, true, "d", playerid);
    return 1;
}

static stock MSB_StopTick(playerid)
{
    if (!gMSB_Timer[playerid]) return 1;
    KillTimer(gMSB_Timer[playerid]);
    gMSB_Timer[playerid] = 0;
    return 1;
}

// ----------------------------------------------------------
// Public API (hotbarpreparacao chama MSB_SyncBinds)
// ----------------------------------------------------------
forward MSB_OnConnect(playerid);
public MSB_OnConnect(playerid)
{
    gMSB_Enabled[playerid] = true;
    gMSB_Visible[playerid] = false;
    gMSB_WantVisible[playerid] = true;
    gMSB_Created[playerid] = false;
    gMSB_Timer[playerid] = 0;

    gMSB_CenterX[playerid]  = MSB_DEF_CENTER_X;
    gMSB_BaseY[playerid]    = MSB_DEF_BASE_Y;
    gMSB_IconSize[playerid] = MSB_DEF_ICON_SIZE;
    gMSB_GapX[playerid]     = MSB_DEF_GAP_X;
    gMSB_GapY[playerid]     = MSB_DEF_GAP_Y;
    gMSB_Cols[playerid]     = MSB_DEF_COLS;
    gMSB_Rows[playerid]     = MSB_DEF_ROWS;
    gMSB_MaxIcons[playerid] = MSB_DEF_MAX;
    gMSB_HideEmpty[playerid]= (MSB_DEF_HIDE_EMPTY ? true : false);

    gMSB_Count[playerid] = 0;
    return 1;
}

forward MSB_OnDisconnect(playerid);
public MSB_OnDisconnect(playerid)
{
    MSB_StopTick(playerid);
    MSB_Destroy(playerid);
    gMSB_Visible[playerid] = false;
    gMSB_Enabled[playerid] = false;
    return 1;
}

forward MSB_SyncBinds(playerid);
public MSB_SyncBinds(playerid)
{
    if (!IsPlayerConnected(playerid)) return 0;

    // se desabilitado, mantAm escondido
    if (!gMSB_Enabled[playerid] || !gMSB_WantVisible[playerid])
    {
        gMSB_Visible[playerid] = false;
        MSB_Hide(playerid);
        MSB_StopTick(playerid);
        return 1;
    }

    // rebuild (se nAo tiver nada bindado, ele mesmo esconde)
    MSB_Rebuild(playerid);

    if (gMSB_Count[playerid] <= 0)
    {
        // sem binds -> nAo mostra
        gMSB_Visible[playerid] = false;
        MSB_StopTick(playerid);
        return 1;
    }

    gMSB_Visible[playerid] = true;
    MSB_Show(playerid);
    MSB_StartTick(playerid);
    return 1;
}

// ----------------------------------------------------------
// CMD: /mentorbar (toggle)
// ----------------------------------------------------------
CMD:mentorbar(playerid, params[])
{
    #pragma unused params

    gMSB_Enabled[playerid] = !gMSB_Enabled[playerid];

    if (!gMSB_Enabled[playerid] || !gMSB_WantVisible[playerid])
    {
        gMSB_Visible[playerid] = false;
        MSB_Hide(playerid);
        MSB_StopTick(playerid);
        return SendClientMessage(playerid, MSB_MSG_OFF, "(SKILLBAR) Desligada.");
    }

    // liga (sA3 aparece se tiver binds)
    MSB_SyncBinds(playerid);
    if (!gMSB_Visible[playerid])
        return SendClientMessage(playerid, MSB_MSG_ON, "(SKILLBAR) Ligada (sem binds: nAo aparece). Use /bindjutsu.");

    return SendClientMessage(playerid, MSB_MSG_ON, "(SKILLBAR) Ligada.");
}

// ----------------------------------------------------------
// CustomizaAAo IN-GAME
// ----------------------------------------------------------
CMD:msbpos(playerid, params[])
{
    new Float:cx, Float:by;
    if (sscanf(params, "ff", cx, by))
        return SendClientMessage(playerid, -1, "Use: /msbpos <centerX> <baseY>");

    gMSB_CenterX[playerid] = MSB_ClampFloat(cx, 40.0, 600.0);
    gMSB_BaseY[playerid]   = MSB_ClampFloat(by, 80.0, 430.0);

    MSB_SyncBinds(playerid);
    return 1;
}

CMD:msbsize(playerid, params[])
{
    new Float:s;
    if (sscanf(params, "f", s))
        return SendClientMessage(playerid, -1, "Use: /msbsize <px>");

    gMSB_IconSize[playerid] = MSB_ClampFloat(s, 12.0, 60.0);
    MSB_SyncBinds(playerid);
    return 1;
}

CMD:msbgap(playerid, params[])
{
    new Float:g;
    if (sscanf(params, "f", g))
        return SendClientMessage(playerid, -1, "Use: /msbgap <px>");

    gMSB_GapX[playerid] = MSB_ClampFloat(g, 0.0, 40.0);
    MSB_SyncBinds(playerid);
    return 1;
}

CMD:msbgapy(playerid, params[])
{
    new Float:g;
    if (sscanf(params, "f", g))
        return SendClientMessage(playerid, -1, "Use: /msbgapy <px>");

    gMSB_GapY[playerid] = MSB_ClampFloat(g, 0.0, 40.0);
    MSB_SyncBinds(playerid);
    return 1;
}

CMD:msbcols(playerid, params[])
{
    new c;
    if (sscanf(params, "d", c))
        return SendClientMessage(playerid, -1, "Use: /msbcols <1..10>");

    gMSB_Cols[playerid] = MSB_ClampInt(c, 1, 10);

    // garante max compatAvel com grid
    new cap = gMSB_Cols[playerid] * gMSB_Rows[playerid];
    if (gMSB_MaxIcons[playerid] > cap) gMSB_MaxIcons[playerid] = cap;

    MSB_SyncBinds(playerid);
    return 1;
}

CMD:msbrows(playerid, params[])
{
    new r;
    if (sscanf(params, "d", r))
        return SendClientMessage(playerid, -1, "Use: /msbrows <1..6>");

    gMSB_Rows[playerid] = MSB_ClampInt(r, 1, 6);

    new cap = gMSB_Cols[playerid] * gMSB_Rows[playerid];
    if (gMSB_MaxIcons[playerid] > cap) gMSB_MaxIcons[playerid] = cap;

    MSB_SyncBinds(playerid);
    return 1;
}

CMD:msbmax(playerid, params[])
{
    new m;
    if (sscanf(params, "d", m))
        return SendClientMessage(playerid, -1, "Use: /msbmax <1..24>");

    m = MSB_ClampInt(m, 1, MSB_MAX_SLOTS);

    // limita no grid atual
    new cap = gMSB_Cols[playerid] * gMSB_Rows[playerid];
    if (m > cap) m = cap;

    gMSB_MaxIcons[playerid] = m;
    MSB_SyncBinds(playerid);
    return 1;
}

CMD:msbempty(playerid, params[])
{
    new v;
    if (sscanf(params, "d", v))
        return SendClientMessage(playerid, -1, "Use: /msbempty <0/1> (1=oculta vazios)");

    gMSB_HideEmpty[playerid] = (v != 0);
    MSB_SyncBinds(playerid);
    return 1;
}

CMD:msbreset(playerid, params[])
{
    #pragma unused params

    gMSB_CenterX[playerid]  = MSB_DEF_CENTER_X;
    gMSB_BaseY[playerid]    = MSB_DEF_BASE_Y;
    gMSB_IconSize[playerid] = MSB_DEF_ICON_SIZE;
    gMSB_GapX[playerid]     = MSB_DEF_GAP_X;
    gMSB_GapY[playerid]     = MSB_DEF_GAP_Y;
    gMSB_Cols[playerid]     = MSB_DEF_COLS;
    gMSB_Rows[playerid]     = MSB_DEF_ROWS;
    gMSB_MaxIcons[playerid] = MSB_DEF_MAX;
    gMSB_HideEmpty[playerid]= (MSB_DEF_HIDE_EMPTY ? true : false);

    MSB_SyncBinds(playerid);
    return SendClientMessage(playerid, -1, "(SKILLBAR) Config resetada.");
}


CMD:msbselos(playerid, params[])
{
    #pragma unused params

    new line[256];
    new dialog[4096];
    strcat(dialog, "SLOT\tJUTSU\tSELOS\n");

    new count = 0;

    for (new i = 0; i < JUTSU_MAX_BINDS; i++)
    {
        if (gBindJutsu[playerid][i] == JID_INVALID) continue;

        new nome[64];
        nome[0] = '\0';
        // tenta usar o helper do hotbarpreparacao (se existir)
        #if defined Jutsu_GetNomeById
            Jutsu_GetNomeById(gBindJutsu[playerid][i], nome, sizeof(nome));
        #else
            format(nome, sizeof(nome), "ID %d", _:gBindJutsu[playerid][i]);
        #endif

        format(line, sizeof(line), "%d\t%s\t%s\n", i + 1, nome, gBindSelos[playerid][i]);
        strcat(dialog, line);
        count++;

        if (count >= 30) { strcat(dialog, "...\t...\t...\n"); break; } // evita dialog enorme
    }

    if (count <= 0)
        return ShowPlayerDialog(playerid, DLG_MSB_SELOS, DIALOG_STYLE_MSGBOX, "SELOS / BINDS", "Voce nao tem nenhum jutsu bindado.\nUse /bindjutsu para criar binds.", "OK", "");

    return ShowPlayerDialog(playerid, DLG_MSB_SELOS, DIALOG_STYLE_TABLIST_HEADERS, "SELOS / BINDS", dialog, "OK", "");
}

// Alias /selos (se ainda nao existir no seu GM)
#if !defined cmd_selos
CMD:selos(playerid, params[])
{
    return cmd_msbselos(playerid, params);
}
#endif

CMD:msbinfo(playerid, params[])
{
    #pragma unused params

    new msg[160];
    format(msg, sizeof msg,
        "(SKILLBAR) enabled=%d wantVisible=%d shown=%d | cols=%d rows=%d max=%d | size=%.1f gapX=%.1f gapY=%.1f | centerX=%.1f baseY=%.1f | hideEmpty=%d",
        gMSB_Enabled[playerid], gMSB_WantVisible[playerid], gMSB_Visible[playerid],
        gMSB_Cols[playerid], gMSB_Rows[playerid], gMSB_MaxIcons[playerid],
        gMSB_IconSize[playerid], gMSB_GapX[playerid], gMSB_GapY[playerid],
        gMSB_CenterX[playerid], gMSB_BaseY[playerid], gMSB_HideEmpty[playerid]
    );
    SendClientMessage(playerid, -1, msg);
    return 1;
}