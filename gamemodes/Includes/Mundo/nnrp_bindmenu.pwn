// =============================================================================
//  Includes/Mundo/nnrp_bindmenu.pwn (v6)
//  BIND UI (menu com mouse) - v6 (fix dup BindUI_OnDisconnect)
//
//  Problema que este arquivo resolve:
//   - A versão anterior criava dezenas de PlayerTextDraws (por player).
//   - Se o seu gamemode já estiver perto do limite, as criações começam a
//     retornar INVALID e a grid some (exatamente como no seu print).
//
//  Solução:
//   - Tudo que é "estático" vira TextDraw GLOBAL (não conta no limite por player)
//   - Só o que precisa variar por player fica como PlayerTextDraw:
//       * Título + dica (2)
//       * 12 ícones de jutsu (12)
//       * Ícone do jutsu selecionado + 6 slots de selo (7)
//
//  Integração (sem y_hooks):
//   1) Coloque este include DEPOIS do a_samp/zcmd/sscanf2 no seu GM.
//   2) No OnPlayerClickTextDraw:
//        if (BindUI_OnClickTD(playerid, clickedid)) return 1;
//   3) No OnPlayerClickPlayerTextDraw:
//        if (BindUI_OnClickPTD(playerid, playertextid)) return 1;
//   4) No OnPlayerDisconnect:
//        BindUI_OnDisconnect(playerid);
//
//  Texturas:
//   - BindUI.txd (precisa existir no client):
//       BindUI_bg, BindUI_btn_left, BindUI_btn_right, BindUI_btn_close,
//       BindUI_slot_frame
//   - Ícones dos jutsus: InventSkill.txd (ex.: InventSkill:Goukakyuu)
// =============================================================================

#if defined _NNRP_BINDMENU_
    #endinput
#endif
#define _NNRP_BINDMENU_

#include <a_samp>
#include <zcmd>
#include "Includes/Jutsus/hotbarpreparacao.pwn"

// -----------------------------------------------------------------------------
// Ajuste de cor caso seu GM não tenha
// -----------------------------------------------------------------------------
#if !defined COLOR_WHITE
    #define COLOR_WHITE 0xFFFFFFFF
#endif

// -----------------------------------------------------------------------------
// Sprites
// -----------------------------------------------------------------------------
#define BUI_TEX_BG        "BindUI:BindUI_bg"
#define BUI_TEX_LEFT      "BindUI:BindUI_btn_left"
#define BUI_TEX_RIGHT     "BindUI:BindUI_btn_right"
#define BUI_TEX_CLOSE     "BindUI:BindUI_btn_close"
#define BUI_TEX_FRAME     "BindUI:BindUI_slot_frame"

// Selos (desenhados como TEXTO para não depender de sprites)
// Se você quiser usar sprites depois, é só trocar para "BindUI:BindUI_selo_tigre" etc

// -----------------------------------------------------------------------------
// Layout (base SA-MP 640x480)
// -----------------------------------------------------------------------------
#define BUI_PANEL_X   (120.0)
#define BUI_PANEL_Y   (125.0)
#define BUI_PANEL_W   (400.0)
#define BUI_PANEL_H   (250.0)

#define BUI_CLOSE_X   (505.0)
#define BUI_CLOSE_Y   (132.0)

#define BUI_GRID_X    (150.0)
#define BUI_GRID_Y    (165.0)
#define BUI_SLOT_W    (38.0)
#define BUI_SLOT_H    (38.0)
#define BUI_GAP_X     (10.0)
#define BUI_GAP_Y     (14.0)

#define BUI_COLS      (4)
#define BUI_ROWS      (3)
#define BUI_PER_PAGE  (BUI_COLS * BUI_ROWS)
#define BUI_MAX_LIST  (128)

// Área dos selos (abaixo da grid)
#define BUI_SEAL_TITLE_Y  (268.0)
#define BUI_SEAL_SLOTS_X  (190.0)
#define BUI_SEAL_SLOTS_Y  (298.0)
#define BUI_SEAL_SLOT_W   (34.0)
#define BUI_SEAL_SLOT_H   (34.0)
#define BUI_SEAL_GAP      (8.0)

#define BUI_SEAL_BTNS_X   (185.0)
#define BUI_SEAL_BTNS_Y   (346.0)
#define BUI_SEAL_BTN_W    (58.0)
#define BUI_SEAL_BTN_H    (24.0)
#define BUI_SEAL_BTN_GAP  (6.0)

#define BUI_BTN_OK_X      (388.0)
#define BUI_BTN_OK_Y      (346.0)
#define BUI_BTN_W         (52.0)
#define BUI_BTN_H         (24.0)

#define BUI_BTN_CLR_X     (444.0)
#define BUI_BTN_CLR_Y     (346.0)

#define BUI_BTN_BACK_X    (500.0)
#define BUI_BTN_BACK_Y    (346.0)

// -----------------------------------------------------------------------------
// Estado
// -----------------------------------------------------------------------------
enum { BUI_STATE_LIST = 0, BUI_STATE_SEALS = 1 };
enum eSeal { SEAL_NONE = 0, SEAL_TIGRE, SEAL_DRAGAO, SEAL_COELHO, SEAL_RATO, SEAL_COBRA };

static bool:gBUI_GlobCreated;

static Text:gBUI_BG;
static Text:gBUI_Close;
static Text:gBUI_Left;
static Text:gBUI_Right;

static Text:gBUI_Frame[BUI_PER_PAGE];

// Selos UI (globais)
static Text:gBUI_SealSlotFrame[6];
static Text:gBUI_SealBtn[5];
static Text:gBUI_OK;
static Text:gBUI_CLR;
static Text:gBUI_BACK;
static Text:gBUI_SealHint;

// PlayerTextDraws (dinâmicos)
static PlayerText:gBUI_Title[MAX_PLAYERS];
static PlayerText:gBUI_Hint[MAX_PLAYERS];
static PlayerText:gBUI_Icon[MAX_PLAYERS][BUI_PER_PAGE];
static PlayerText:gBUI_SelJutsuIcon[MAX_PLAYERS];
static PlayerText:gBUI_SealSlotIcon[MAX_PLAYERS][6];

static bool:gBUI_Open[MAX_PLAYERS];
static gBUI_State[MAX_PLAYERS];
static gBUI_Page[MAX_PLAYERS];
static gBUI_List[MAX_PLAYERS][BUI_MAX_LIST]; // até 128 jutsus (sobra)
static gBUI_Count[MAX_PLAYERS];
static gBUI_Selected[MAX_PLAYERS];

static eSeal:gBUI_SealSeq[MAX_PLAYERS][6];
static gBUI_SealCount[MAX_PLAYERS];

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------
stock BUI_AddSealName(eSeal:seal, out[], outSize)
{
    switch (seal)
    {
        case SEAL_TIGRE:  format(out, outSize, "%sTigre, ", out);
        case SEAL_DRAGAO: format(out, outSize, "%sDragao, ", out);
        case SEAL_COELHO: format(out, outSize, "%sCoelho, ", out);
        case SEAL_RATO:   format(out, outSize, "%sRato, ", out);
        case SEAL_COBRA:  format(out, outSize, "%sCobra, ", out);
    }
    return 1;
}

stock BUI_SealToShort(eSeal:seal, out[], outSize)
{
    // abreviações pra mostrar no slot
    switch (seal)
    {
        case SEAL_TIGRE:  format(out, outSize, "T");
        case SEAL_DRAGAO: format(out, outSize, "D");
        case SEAL_COELHO: format(out, outSize, "C");
        case SEAL_RATO:   format(out, outSize, "R");
        case SEAL_COBRA:  format(out, outSize, "S");
        default:          format(out, outSize, "");
    }
    return 1;
}

stock BUI_GetSpriteByJid(jid, out[], outSize)
{
    // IMPORTANTE: nomes precisam bater com seu InventSkill.txd
    switch (jid)
    {
        case JID_GOUKAKYUU:  format(out, outSize, "InventSkill:Goukakyuu");
        case JID_HOUSENKA:   format(out, outSize, "InventSkill:Housenka");
        case JID_KARYUUENDAN:format(out, outSize, "InventSkill:Karyuuendan");

        case JID_ARASHI_I:   format(out, outSize, "InventSkill:Arashi");
        case JID_RAIKYUU:    format(out, outSize, "InventSkill:Raikyuu");
        case JID_NAGASHI:    format(out, outSize, "InventSkill:Nagashi");

        case JID_MIZURAPPA:  format(out, outSize, "InventSkill:Mizurappa");
        case JID_SUIKODAN:   format(out, outSize, "InventSkill:Suikodan");
        case JID_SUIROU:     format(out, outSize, "InventSkill:Suirou");

        case JID_RASENGAN:   format(out, outSize, "InventSkill:Rasengan");
        case JID_HANACHI:    format(out, outSize, "InventSkill:Hanachi");
        case JID_SHINKUHA:   format(out, outSize, "InventSkill:Shinkuha");
        case JID_ATSUGAI:    format(out, outSize, "InventSkill:Atsugai");

        case JID_IWAKAI:     format(out, outSize, "InventSkill:Iwakai");
        case JID_DORYUUHEKI: format(out, outSize, "InventSkill:Doryuuheki");
        case JID_DOROJIGOKU: format(out, outSize, "InventSkill:Dorojigoku");

        case JID_SABERU:     format(out, outSize, "InventSkill:Saberu");
        case JID_SELAMENTO:  format(out, outSize, "InventSkill:Selamento");
        case JID_KINOBI:     format(out, outSize, "InventSkill:Kinobori");
        case JID_KAWARIMI:   format(out, outSize, "InventSkill:Kawarimi");
        case JID_IRYOU:      format(out, outSize, "InventSkill:Iryou");
        case JID_KATSUYU:    format(out, outSize, "InventSkill:Katsuyu");
        case JID_MESU:       format(out, outSize, "InventSkill:Mesu");
        case JID_URUSHI:     format(out, outSize, "InventSkill:Urushi");
        case JID_RAIJIN_VOADOR: format(out, outSize, "InventSkill:Raijin");

        default:             format(out, outSize, "InventSkill:Nada");
    }
    return 1;
}

stock BUI_BuildList(playerid)
{
    gBUI_Count[playerid] = 0;

    // Integer loop (older pawncc friendly). Same access check used in /bindjutsu.
    for (new id = 0; id <= _:JID_CLAN_TIGRE; id++)
    {
        if (!Jutsu_IsValidId(id)) continue;
        if (!Jutsu_PlayerTemAcessoByJutsuId(playerid, id)) continue;

        gBUI_List[playerid][gBUI_Count[playerid]] = id;
        gBUI_Count[playerid]++;
        if (gBUI_Count[playerid] >= BUI_MAX_LIST) break;
    }

    return 1;
}

stock BUI_TotalPages(playerid)
{
    // Evita conflito com macros/defines genéricos (ex.: #define total ...)
    new buiPages = (gBUI_Count[playerid] + (BUI_PER_PAGE - 1)) / BUI_PER_PAGE;
    if (buiPages < 1) buiPages = 1;
    return buiPages;
}

stock BUI_RefreshList(playerid)
{
    new start = gBUI_Page[playerid] * BUI_PER_PAGE;

    for (new i = 0; i < BUI_PER_PAGE; i++)
    {
        new idx = start + i;
        if (idx >= gBUI_Count[playerid])
        {
            PlayerTextDrawSetString(playerid, gBUI_Icon[playerid][i], " ");
            PlayerTextDrawHide(playerid, gBUI_Icon[playerid][i]);
            continue;
        }

        new jid = gBUI_List[playerid][idx];
        new spr[64];
        BUI_GetSpriteByJid(jid, spr, sizeof spr);
        PlayerTextDrawSetString(playerid, gBUI_Icon[playerid][i], spr);
        PlayerTextDrawShow(playerid, gBUI_Icon[playerid][i]);
    }

    new pages = BUI_TotalPages(playerid);
    new hint[128];
    format(hint, sizeof hint, "Clique no jutsu para bindar. (Pagina %d/%d)", (gBUI_Page[playerid] + 1), pages);
    PlayerTextDrawSetString(playerid, gBUI_Hint[playerid], hint);
    PlayerTextDrawShow(playerid, gBUI_Hint[playerid]);
    return 1;
}

stock BUI_RefreshSeals(playerid)
{
    // slots
    for (new i = 0; i < 6; i++)
    {
        new s[8];
        BUI_SealToShort(gBUI_SealSeq[playerid][i], s, sizeof s);
        if (!strlen(s)) format(s, sizeof s, " ");
        PlayerTextDrawSetString(playerid, gBUI_SealSlotIcon[playerid][i], s);
        PlayerTextDrawShow(playerid, gBUI_SealSlotIcon[playerid][i]);
    }
    return 1;
}

// -----------------------------------------------------------------------------
// Globals (cria 1x)
// -----------------------------------------------------------------------------
stock BUI_CreateGlobals()
{
    if (gBUI_GlobCreated) return 1;

    // BG
    gBUI_BG = TextDrawCreate(BUI_PANEL_X, BUI_PANEL_Y, BUI_TEX_BG);
    TextDrawFont(gBUI_BG, 4);
    TextDrawTextSize(gBUI_BG, BUI_PANEL_W, BUI_PANEL_H);
    TextDrawSetOutline(gBUI_BG, 0);
    TextDrawSetShadow(gBUI_BG, 0);
    TextDrawUseBox(gBUI_BG, 1);
    TextDrawBoxColor(gBUI_BG, 0);

    // Close
    gBUI_Close = TextDrawCreate(BUI_CLOSE_X, BUI_CLOSE_Y, BUI_TEX_CLOSE);
    TextDrawFont(gBUI_Close, 4);
    TextDrawTextSize(gBUI_Close, 22.0, 22.0);
    TextDrawSetSelectable(gBUI_Close, 1);

    // Prev/Next
    gBUI_Left = TextDrawCreate(120.0, 348.0, BUI_TEX_LEFT);
    TextDrawFont(gBUI_Left, 4);
    TextDrawTextSize(gBUI_Left, 22.0, 22.0);
    TextDrawSetSelectable(gBUI_Left, 1);

    gBUI_Right = TextDrawCreate(160.0, 348.0, BUI_TEX_RIGHT);
    TextDrawFont(gBUI_Right, 4);
    TextDrawTextSize(gBUI_Right, 22.0, 22.0);
    TextDrawSetSelectable(gBUI_Right, 1);

    // Frames da grid (4x3)
    for (new i = 0; i < BUI_PER_PAGE; i++)
    {
        new col = (i % BUI_COLS);
        new row = (i / BUI_COLS);
        new Float:x = BUI_GRID_X + (col * (BUI_SLOT_W + BUI_GAP_X));
        new Float:y = BUI_GRID_Y + (row * (BUI_SLOT_H + BUI_GAP_Y));

        gBUI_Frame[i] = TextDrawCreate(x, y, BUI_TEX_FRAME);
        TextDrawFont(gBUI_Frame[i], 4);
        TextDrawTextSize(gBUI_Frame[i], BUI_SLOT_W, BUI_SLOT_H);
    }

    // SELS: hint
    gBUI_SealHint = TextDrawCreate(150.0, BUI_SEAL_TITLE_Y, "Selecione os selos (ordem):");
    TextDrawFont(gBUI_SealHint, 1);
    TextDrawLetterSize(gBUI_SealHint, 0.22, 1.0);
    TextDrawSetOutline(gBUI_SealHint, 1);

    // Seal slot frames (6)
    for (new s = 0; s < 6; s++)
    {
        new Float:x2 = BUI_SEAL_SLOTS_X + (s * (BUI_SEAL_SLOT_W + BUI_SEAL_GAP));
        new Float:y2 = BUI_SEAL_SLOTS_Y;
        gBUI_SealSlotFrame[s] = TextDrawCreate(x2, y2, BUI_TEX_FRAME);
        TextDrawFont(gBUI_SealSlotFrame[s], 4);
        TextDrawTextSize(gBUI_SealSlotFrame[s], BUI_SEAL_SLOT_W, BUI_SEAL_SLOT_H);
    }

    // Seal buttons (texto com box) - 5
    // Tigre, Dragao, Coelho, Rato, Cobra
    static const sealNames[5][] = { "Tigre", "Dragao", "Coelho", "Rato", "Cobra" };
    for (new b = 0; b < 5; b++)
    {
        new Float:bx = BUI_SEAL_BTNS_X + (b * (BUI_SEAL_BTN_W + BUI_SEAL_BTN_GAP));
        gBUI_SealBtn[b] = TextDrawCreate(bx, BUI_SEAL_BTNS_Y, sealNames[b]);
        TextDrawFont(gBUI_SealBtn[b], 1);
        TextDrawLetterSize(gBUI_SealBtn[b], 0.22, 1.0);
        TextDrawTextSize(gBUI_SealBtn[b], BUI_SEAL_BTN_W, BUI_SEAL_BTN_H);
        TextDrawAlignment(gBUI_SealBtn[b], 2);
        TextDrawUseBox(gBUI_SealBtn[b], 1);
        TextDrawBoxColor(gBUI_SealBtn[b], 0x00000066);
        TextDrawColor(gBUI_SealBtn[b], 0xFFFFFFFF);
        TextDrawSetOutline(gBUI_SealBtn[b], 1);
        TextDrawSetSelectable(gBUI_SealBtn[b], 1);
    }

    // OK/Clear/Back (texto com box)
    gBUI_OK = TextDrawCreate(BUI_BTN_OK_X, BUI_BTN_OK_Y, "OK");
    TextDrawFont(gBUI_OK, 1);
    TextDrawLetterSize(gBUI_OK, 0.25, 1.0);
    TextDrawTextSize(gBUI_OK, BUI_BTN_W, BUI_BTN_H);
    TextDrawAlignment(gBUI_OK, 2);
    TextDrawUseBox(gBUI_OK, 1);
    TextDrawBoxColor(gBUI_OK, 0x006600AA);
    TextDrawColor(gBUI_OK, 0xFFFFFFFF);
    TextDrawSetOutline(gBUI_OK, 1);
    TextDrawSetSelectable(gBUI_OK, 1);

    gBUI_CLR = TextDrawCreate(BUI_BTN_CLR_X, BUI_BTN_CLR_Y, "LIMPAR");
    TextDrawFont(gBUI_CLR, 1);
    TextDrawLetterSize(gBUI_CLR, 0.20, 1.0);
    TextDrawTextSize(gBUI_CLR, BUI_BTN_W + 18.0, BUI_BTN_H);
    TextDrawAlignment(gBUI_CLR, 2);
    TextDrawUseBox(gBUI_CLR, 1);
    TextDrawBoxColor(gBUI_CLR, 0x660000AA);
    TextDrawColor(gBUI_CLR, 0xFFFFFFFF);
    TextDrawSetOutline(gBUI_CLR, 1);
    TextDrawSetSelectable(gBUI_CLR, 1);

    gBUI_BACK = TextDrawCreate(BUI_BTN_BACK_X, BUI_BTN_BACK_Y, "VOLTAR");
    TextDrawFont(gBUI_BACK, 1);
    TextDrawLetterSize(gBUI_BACK, 0.20, 1.0);
    TextDrawTextSize(gBUI_BACK, BUI_BTN_W + 18.0, BUI_BTN_H);
    TextDrawAlignment(gBUI_BACK, 2);
    TextDrawUseBox(gBUI_BACK, 1);
    TextDrawBoxColor(gBUI_BACK, 0x000000AA);
    TextDrawColor(gBUI_BACK, 0xFFFFFFFF);
    TextDrawSetOutline(gBUI_BACK, 1);
    TextDrawSetSelectable(gBUI_BACK, 1);

    gBUI_GlobCreated = true;
    return 1;
}

// -----------------------------------------------------------------------------
// PlayerTextDraws (cria por player 1x)
// -----------------------------------------------------------------------------
stock BUI_EnsurePlayer(playerid)
{
    if (gBUI_Title[playerid] != PlayerText:INVALID_TEXT_DRAW) return 1;

    // Title
    gBUI_Title[playerid] = CreatePlayerTextDraw(playerid, 136.0, 132.0, "BIND - Escolha um jutsu");
    PlayerTextDrawFont(playerid, gBUI_Title[playerid], 1);
    PlayerTextDrawLetterSize(playerid, gBUI_Title[playerid], 0.35, 1.2);
    PlayerTextDrawSetOutline(playerid, gBUI_Title[playerid], 1);
    PlayerTextDrawColor(playerid, gBUI_Title[playerid], 0xFFFFFFFF);

    // Hint
    gBUI_Hint[playerid] = CreatePlayerTextDraw(playerid, 136.0, 150.0, "");
    PlayerTextDrawFont(playerid, gBUI_Hint[playerid], 1);
    PlayerTextDrawLetterSize(playerid, gBUI_Hint[playerid], 0.22, 1.0);
    PlayerTextDrawSetOutline(playerid, gBUI_Hint[playerid], 1);
    PlayerTextDrawColor(playerid, gBUI_Hint[playerid], 0xFFFFFFFF);

    // Icons (12)
    for (new i = 0; i < BUI_PER_PAGE; i++)
    {
        new col = (i % BUI_COLS);
        new row = (i / BUI_COLS);
        new Float:x = BUI_GRID_X + (col * (BUI_SLOT_W + BUI_GAP_X)) + 2.0;
        new Float:y = BUI_GRID_Y + (row * (BUI_SLOT_H + BUI_GAP_Y)) + 2.0;

        gBUI_Icon[playerid][i] = CreatePlayerTextDraw(playerid, x, y, "InventSkill:Nada");
        PlayerTextDrawFont(playerid, gBUI_Icon[playerid][i], 4);
        PlayerTextDrawTextSize(playerid, gBUI_Icon[playerid][i], BUI_SLOT_W - 4.0, BUI_SLOT_H - 4.0);
        PlayerTextDrawSetSelectable(playerid, gBUI_Icon[playerid][i], 1);
    }

    // Selected jutsu icon (seal mode)
    gBUI_SelJutsuIcon[playerid] = CreatePlayerTextDraw(playerid, 136.0, 270.0, "InventSkill:Nada");
    PlayerTextDrawFont(playerid, gBUI_SelJutsuIcon[playerid], 4);
    PlayerTextDrawTextSize(playerid, gBUI_SelJutsuIcon[playerid], 34.0, 34.0);
    PlayerTextDrawSetSelectable(playerid, gBUI_SelJutsuIcon[playerid], 0);

    // Seal slot icons (6) (texto centralizado dentro do frame)
    for (new s = 0; s < 6; s++)
    {
        new Float:x2 = BUI_SEAL_SLOTS_X + (s * (BUI_SEAL_SLOT_W + BUI_SEAL_GAP));
        new Float:y2 = BUI_SEAL_SLOTS_Y + 8.0;
        gBUI_SealSlotIcon[playerid][s] = CreatePlayerTextDraw(playerid, x2 + (BUI_SEAL_SLOT_W / 2.0), y2, " ");
        PlayerTextDrawFont(playerid, gBUI_SealSlotIcon[playerid][s], 1);
        PlayerTextDrawLetterSize(playerid, gBUI_SealSlotIcon[playerid][s], 0.40, 1.4);
        PlayerTextDrawAlignment(playerid, gBUI_SealSlotIcon[playerid][s], 2);
        PlayerTextDrawSetOutline(playerid, gBUI_SealSlotIcon[playerid][s], 1);
        PlayerTextDrawColor(playerid, gBUI_SealSlotIcon[playerid][s], 0xFFFFFFFF);
        PlayerTextDrawSetSelectable(playerid, gBUI_SealSlotIcon[playerid][s], 0);
    }

    return 1;
}

// -----------------------------------------------------------------------------
// Mostrar/Esconder
// -----------------------------------------------------------------------------
stock BindUI_Show(playerid)
{
    BUI_CreateGlobals();
    BUI_EnsurePlayer(playerid);

    BUI_BuildList(playerid);
    gBUI_Page[playerid] = 0;
    gBUI_State[playerid] = BUI_STATE_LIST;
    gBUI_Selected[playerid] = JID_INVALID;

    // reset selos
    gBUI_SealCount[playerid] = 0;
    for (new i = 0; i < 6; i++) gBUI_SealSeq[playerid][i] = SEAL_NONE;

    // mostrar globais base
    TextDrawShowForPlayer(playerid, gBUI_BG);
    TextDrawShowForPlayer(playerid, gBUI_Close);
    TextDrawShowForPlayer(playerid, gBUI_Left);
    TextDrawShowForPlayer(playerid, gBUI_Right);

    for (new f = 0; f < BUI_PER_PAGE; f++)
        TextDrawShowForPlayer(playerid, gBUI_Frame[f]);

    // esconder área de selos
    TextDrawHideForPlayer(playerid, gBUI_SealHint);
    for (new s = 0; s < 6; s++) TextDrawHideForPlayer(playerid, gBUI_SealSlotFrame[s]);
    for (new b = 0; b < 5; b++) TextDrawHideForPlayer(playerid, gBUI_SealBtn[b]);
    TextDrawHideForPlayer(playerid, gBUI_OK);
    TextDrawHideForPlayer(playerid, gBUI_CLR);
    TextDrawHideForPlayer(playerid, gBUI_BACK);

    // textos do player
    PlayerTextDrawSetString(playerid, gBUI_Title[playerid], "BIND - Escolha um jutsu");
    PlayerTextDrawShow(playerid, gBUI_Title[playerid]);

    BUI_RefreshList(playerid);
    PlayerTextDrawShow(playerid, gBUI_Hint[playerid]);

    for (new i2 = 0; i2 < BUI_PER_PAGE; i2++)
        PlayerTextDrawShow(playerid, gBUI_Icon[playerid][i2]);

    // hide selos ptd
    PlayerTextDrawHide(playerid, gBUI_SelJutsuIcon[playerid]);
    for (new k = 0; k < 6; k++) PlayerTextDrawHide(playerid, gBUI_SealSlotIcon[playerid][k]);

    SelectTextDraw(playerid, 0x00FF00FF);
    gBUI_Open[playerid] = true;
    return 1;
}

stock BindUI_Hide(playerid)
{
    if (!gBUI_Open[playerid]) return 1;

    CancelSelectTextDraw(playerid);

    // globais
    TextDrawHideForPlayer(playerid, gBUI_BG);
    TextDrawHideForPlayer(playerid, gBUI_Close);
    TextDrawHideForPlayer(playerid, gBUI_Left);
    TextDrawHideForPlayer(playerid, gBUI_Right);
    for (new f = 0; f < BUI_PER_PAGE; f++) TextDrawHideForPlayer(playerid, gBUI_Frame[f]);

    TextDrawHideForPlayer(playerid, gBUI_SealHint);
    for (new s = 0; s < 6; s++) TextDrawHideForPlayer(playerid, gBUI_SealSlotFrame[s]);
    for (new b = 0; b < 5; b++) TextDrawHideForPlayer(playerid, gBUI_SealBtn[b]);
    TextDrawHideForPlayer(playerid, gBUI_OK);
    TextDrawHideForPlayer(playerid, gBUI_CLR);
    TextDrawHideForPlayer(playerid, gBUI_BACK);

    // ptd
    PlayerTextDrawHide(playerid, gBUI_Title[playerid]);
    PlayerTextDrawHide(playerid, gBUI_Hint[playerid]);
    for (new i2 = 0; i2 < BUI_PER_PAGE; i2++) PlayerTextDrawHide(playerid, gBUI_Icon[playerid][i2]);
    PlayerTextDrawHide(playerid, gBUI_SelJutsuIcon[playerid]);
    for (new k = 0; k < 6; k++) PlayerTextDrawHide(playerid, gBUI_SealSlotIcon[playerid][k]);

    gBUI_Open[playerid] = false;
    gBUI_State[playerid] = BUI_STATE_LIST;
    gBUI_Selected[playerid] = JID_INVALID;
    return 1;
}


// -----------------------------------------------------------------------------
// Entrar no modo selos
// -----------------------------------------------------------------------------
stock BUI_EnterSealMode(playerid, eJutsuId:jid)
{
    gBUI_State[playerid] = BUI_STATE_SEALS;
    gBUI_Selected[playerid] = jid;

    // atualiza title
    new nome[64];
    Jutsu_GetNomeById(jid, nome, sizeof nome);
    new pos = strfind(nome, ": ", true);
    if (pos != -1) format(nome, sizeof nome, "%s", nome[pos + 2]);

    new t[96];
    format(t, sizeof t, "BIND - Selos (%s)", nome);
    PlayerTextDrawSetString(playerid, gBUI_Title[playerid], t);
    PlayerTextDrawShow(playerid, gBUI_Title[playerid]);

    PlayerTextDrawSetString(playerid, gBUI_Hint[playerid], "Clique nos selos. OK salva. LIMPAR apaga. VOLTAR retorna.");
    PlayerTextDrawShow(playerid, gBUI_Hint[playerid]);

    // selecionado
    new spr[64];
    BUI_GetSpriteByJid(jid, spr, sizeof spr);
    PlayerTextDrawSetString(playerid, gBUI_SelJutsuIcon[playerid], spr);
    PlayerTextDrawShow(playerid, gBUI_SelJutsuIcon[playerid]);

    // reset selos
    gBUI_SealCount[playerid] = 0;
    for (new i = 0; i < 6; i++) gBUI_SealSeq[playerid][i] = SEAL_NONE;
    BUI_RefreshSeals(playerid);

    // esconder ícones da lista
    for (new i2 = 0; i2 < BUI_PER_PAGE; i2++) PlayerTextDrawHide(playerid, gBUI_Icon[playerid][i2]);
    for (new f = 0; f < BUI_PER_PAGE; f++) TextDrawHideForPlayer(playerid, gBUI_Frame[f]);
    TextDrawHideForPlayer(playerid, gBUI_Left);
    TextDrawHideForPlayer(playerid, gBUI_Right);

    // mostrar área de selos
    TextDrawShowForPlayer(playerid, gBUI_SealHint);
    for (new s = 0; s < 6; s++) TextDrawShowForPlayer(playerid, gBUI_SealSlotFrame[s]);
    for (new b = 0; b < 5; b++) TextDrawShowForPlayer(playerid, gBUI_SealBtn[b]);
    TextDrawShowForPlayer(playerid, gBUI_OK);
    TextDrawShowForPlayer(playerid, gBUI_CLR);
    TextDrawShowForPlayer(playerid, gBUI_BACK);
    return 1;
}

stock BUI_ExitSealMode(playerid)
{
    gBUI_State[playerid] = BUI_STATE_LIST;
    gBUI_Selected[playerid] = JID_INVALID;

    PlayerTextDrawSetString(playerid, gBUI_Title[playerid], "BIND - Escolha um jutsu");
    PlayerTextDrawShow(playerid, gBUI_Title[playerid]);

    // esconder selos
    TextDrawHideForPlayer(playerid, gBUI_SealHint);
    for (new s = 0; s < 6; s++) TextDrawHideForPlayer(playerid, gBUI_SealSlotFrame[s]);
    for (new b = 0; b < 5; b++) TextDrawHideForPlayer(playerid, gBUI_SealBtn[b]);
    TextDrawHideForPlayer(playerid, gBUI_OK);
    TextDrawHideForPlayer(playerid, gBUI_CLR);
    TextDrawHideForPlayer(playerid, gBUI_BACK);

    PlayerTextDrawHide(playerid, gBUI_SelJutsuIcon[playerid]);
    for (new i = 0; i < 6; i++) PlayerTextDrawHide(playerid, gBUI_SealSlotIcon[playerid][i]);

    // mostrar list
    TextDrawShowForPlayer(playerid, gBUI_Left);
    TextDrawShowForPlayer(playerid, gBUI_Right);
    for (new f = 0; f < BUI_PER_PAGE; f++) TextDrawShowForPlayer(playerid, gBUI_Frame[f]);

    BUI_RefreshList(playerid);
    for (new i2 = 0; i2 < BUI_PER_PAGE; i2++) PlayerTextDrawShow(playerid, gBUI_Icon[playerid][i2]);
    return 1;
}

// -----------------------------------------------------------------------------
// Salvar bind
// -----------------------------------------------------------------------------
stock BUI_SaveBind(playerid)
{
    if (gBUI_Selected[playerid] == JID_INVALID)
        return 0;

    if (gBUI_SealCount[playerid] <= 0)
    {
        SendClientMessage(playerid, COLOR_WHITE, "{EF0D02}(BIND){FFFFFF} Escolha pelo menos 1 selo.");
        return 0;
    }

    new seq[128];
    seq[0] = '\0';
    for (new i = 0; i < gBUI_SealCount[playerid]; i++)
        BUI_AddSealName(gBUI_SealSeq[playerid][i], seq, sizeof seq);

    // Canonicaliza pra ficar igual ao sistema /bindjutsu
    new canon[128];
    if (!HBCH_SelosCanonicalize(seq, canon, sizeof canon))
        format(canon, sizeof canon, "%s", seq);

    Jutsu_BindSet(playerid, gBUI_Selected[playerid], canon);

    // se tiver mentorbar instalada, tenta sincronizar
    if (funcidx("MSB_SyncFromBinds") != -1)
        CallLocalFunction("MSB_SyncFromBinds", "i", playerid);

    new n[64];
    Jutsu_GetNomeById(gBUI_Selected[playerid], n, sizeof n);
    new pos = strfind(n, ": ", true);
    if (pos != -1) format(n, sizeof n, "%s", n[pos + 2]);

    new msg[196];
    format(msg, sizeof msg, "{00FF00}[BIND]{FFFFFF} %s agora ativa com: {FFFF00}%s", n, canon);
    SendClientMessage(playerid, COLOR_WHITE, msg);
    return 1;
}

// -----------------------------------------------------------------------------
// Click handlers
// -----------------------------------------------------------------------------
stock BindUI_OnClickTD(playerid, Text:clickedid)
{
    if (!gBUI_Open[playerid]) return 0;

    if (clickedid == Text:INVALID_TEXT_DRAW)
        return 1;

    if (clickedid == gBUI_Close)
    {
        BindUI_Hide(playerid);
        return 1;
    }

    if (gBUI_State[playerid] == BUI_STATE_LIST)
    {
        if (clickedid == gBUI_Left)
        {
            if (gBUI_Page[playerid] > 0) gBUI_Page[playerid]--;
            BUI_RefreshList(playerid);
            return 1;
        }
        if (clickedid == gBUI_Right)
        {
            new pages = BUI_TotalPages(playerid);
            if (gBUI_Page[playerid] < (total - 1)) gBUI_Page[playerid]++;
            BUI_RefreshList(playerid);
            return 1;
        }
        return 1;
    }

    // SEALS
    if (gBUI_State[playerid] == BUI_STATE_SEALS)
    {
        if (clickedid == gBUI_BACK)
        {
            BUI_ExitSealMode(playerid);
            return 1;
        }
        if (clickedid == gBUI_CLR)
        {
            gBUI_SealCount[playerid] = 0;
            for (new i = 0; i < 6; i++) gBUI_SealSeq[playerid][i] = SEAL_NONE;
            BUI_RefreshSeals(playerid);
            return 1;
        }
        if (clickedid == gBUI_OK)
        {
            if (BUI_SaveBind(playerid))
                BindUI_Hide(playerid);
            return 1;
        }

        // botões de selo
        for (new b = 0; b < 5; b++)
        {
            if (clickedid != gBUI_SealBtn[b]) continue;
            if (gBUI_SealCount[playerid] >= 6)
            {
                SendClientMessage(playerid, COLOR_WHITE, "{EF0D02}(BIND){FFFFFF} Limite de selos atingido. Use LIMPAR.");
                return 1;
            }
            new eSeal:seal = SEAL_NONE;
            switch (b)
            {
                case 0: seal = SEAL_TIGRE;
                case 1: seal = SEAL_DRAGAO;
                case 2: seal = SEAL_COELHO;
                case 3: seal = SEAL_RATO;
                case 4: seal = SEAL_COBRA;
            }
            gBUI_SealSeq[playerid][gBUI_SealCount[playerid]] = seal;
            gBUI_SealCount[playerid]++;
            BUI_RefreshSeals(playerid);
            return 1;
        }
        return 1;
    }

    return 1;
}

stock BindUI_OnClickPTD(playerid, PlayerText:playertextid)
{
    if (!gBUI_Open[playerid]) return 0;

    if (playertextid == PlayerText:INVALID_TEXT_DRAW)
        return 1;

    if (gBUI_State[playerid] != BUI_STATE_LIST)
        return 1;

    for (new i = 0; i < BUI_PER_PAGE; i++)
    {
        if (playertextid != gBUI_Icon[playerid][i]) continue;
        new listIndex = (gBUI_Page[playerid] * BUI_PER_PAGE) + i;
        if (listIndex >= gBUI_Count[playerid]) return 1;
        new jid = gBUI_List[playerid][listIndex];
        BUI_EnterSealMode(playerid, jid);
        return 1;
    }
    return 1;
}


// -----------------------------------------------------------------------------
// IMPORTANT: PlayerTextDraw handles start as 0 (not INVALID) on older pawncc.
// Without resetting them on connect/disconnect, BUI_EnsurePlayer() may think
// they already exist and skip creation -> you see only the frames/background.
// -----------------------------------------------------------------------------
stock BindUI_ResetPlayer(playerid)
{
    gBUI_Open[playerid] = false;
    gBUI_State[playerid] = BUI_STATE_LIST;
    gBUI_Page[playerid] = 0;
    gBUI_Selected[playerid] = JID_INVALID;
    gBUI_SealCount[playerid] = 0;

    gBUI_Title[playerid] = PlayerText:INVALID_TEXT_DRAW;
    gBUI_Hint[playerid]  = PlayerText:INVALID_TEXT_DRAW;
    gBUI_SelJutsuIcon[playerid] = PlayerText:INVALID_TEXT_DRAW;

    for (new i = 0; i < BUI_PER_PAGE; i++)
        gBUI_Icon[playerid][i] = PlayerText:INVALID_TEXT_DRAW;

    for (new s = 0; s < 6; s++)
        gBUI_SealSlotIcon[playerid][s] = PlayerText:INVALID_TEXT_DRAW;

    return 1;
}

// -----------------------------------------------------------------------------
// Integração (SEM hooks / SEM y_hooks)
// 1) No OnPlayerConnect:     BindUI_OnConnect(playerid);
// 2) No OnPlayerDisconnect:  BindUI_OnDisconnect(playerid);
// 3) No OnPlayerClickTextDraw:
//      if (BindUI_OnClickTD(playerid, clickedid)) return 1;
// 4) No OnPlayerClickPlayerTextDraw:
//      if (BindUI_OnClickPTD(playerid, playertextid)) return 1;
// -----------------------------------------------------------------------------
stock BindUI_OnConnect(playerid)
{
    return BindUI_ResetPlayer(playerid);
}

stock BindUI_OnDisconnect(playerid)
{
    if (gBUI_Open[playerid]) BindUI_Hide(playerid);
    return BindUI_ResetPlayer(playerid);
}

// -----------------------------------------------------------------------------
// Comando
// -----------------------------------------------------------------------------
CMD:bindui(playerid, params[])
{
    #pragma unused params
    return BindUI_Show(playerid);
}