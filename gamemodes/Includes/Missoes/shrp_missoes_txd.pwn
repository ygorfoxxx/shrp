#if defined _SHRP_MISSOES_TXD_INCLUDED
    #endinput
#endif
#define _SHRP_MISSOES_TXD_INCLUDED

// ==========================================================
// SHRP - Missoes - TextDraws
// Extraido do SHRP.pwn (refactor automatico)
// ==========================================================

// TextDraw global (MissoesBKG[])
stock Missoes_CreateGlobalTextDraws()
{
MissoesBKG[0] = TextDrawCreate(80.000000, -20.000000, "MSS:Int1");
    TextDrawFont(MissoesBKG[0], 4);
    TextDrawLetterSize(MissoesBKG[0], 0.600000, 2.000000);
    TextDrawTextSize(MissoesBKG[0], 500.000000, 500.000000);
    TextDrawSetOutline(MissoesBKG[0], 1);
    TextDrawSetShadow(MissoesBKG[0], 0);
    TextDrawAlignment(MissoesBKG[0], 1);
    TextDrawColor(MissoesBKG[0], -1);
    TextDrawBackgroundColor(MissoesBKG[0], 255);
    TextDrawBoxColor(MissoesBKG[0], 50);
    TextDrawUseBox(MissoesBKG[0], 1);
    TextDrawSetProportional(MissoesBKG[0], 1);
    TextDrawSetSelectable(MissoesBKG[0], 0);
    return 1;
}

// PlayerTextDraws do painel de missoes (MissoesNew[playerid][])
stock Missoes_CreatePlayerTextDraws_New(playerid)
{
//COORDENADA_X, COORDENADA_Y, "1000");
//Para mover o texto para a direita, você deve aumentar o valor da COORDENADA_X

// === Missoes Novos === //
    MissoesNew[playerid][0] = CreatePlayerTextDraw(playerid, 323.000000, 148.000000, "Gato (Rank D)");
    PlayerTextDrawFont(playerid, MissoesNew[playerid][0], 1);
    PlayerTextDrawLetterSize(playerid, MissoesNew[playerid][0], 0.366666, 1.400000);
    PlayerTextDrawTextSize(playerid, MissoesNew[playerid][0], 629.500000, 298.000000);
    PlayerTextDrawSetOutline(playerid, MissoesNew[playerid][0], 1);
    PlayerTextDrawSetShadow(playerid, MissoesNew[playerid][0], 0);
    PlayerTextDrawAlignment(playerid, MissoesNew[playerid][0], 2);
    PlayerTextDrawColor(playerid, MissoesNew[playerid][0], 255);
    PlayerTextDrawBackgroundColor(playerid, MissoesNew[playerid][0], 0);
    PlayerTextDrawBoxColor(playerid, MissoesNew[playerid][0], 0);
    PlayerTextDrawUseBox(playerid, MissoesNew[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, MissoesNew[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][0], 0);

    MissoesNew[playerid][1] = CreatePlayerTextDraw(playerid, 323.000000, 169.000000, "Houve uma recente crise interna na area de coleta de lixo da vila.");
    PlayerTextDrawFont(playerid, MissoesNew[playerid][1], 1);
    PlayerTextDrawLetterSize(playerid, MissoesNew[playerid][1], 0.245833, 1.400000);
    PlayerTextDrawTextSize(playerid, MissoesNew[playerid][1], 629.500000, 298.000000);
    PlayerTextDrawSetOutline(playerid, MissoesNew[playerid][1], 1);
    PlayerTextDrawSetShadow(playerid, MissoesNew[playerid][1], 0);
    PlayerTextDrawAlignment(playerid, MissoesNew[playerid][1], 2);
    PlayerTextDrawColor(playerid, MissoesNew[playerid][1], -1);
    PlayerTextDrawBackgroundColor(playerid, MissoesNew[playerid][1], 0);
    PlayerTextDrawBoxColor(playerid, MissoesNew[playerid][1], 0);
    PlayerTextDrawUseBox(playerid, MissoesNew[playerid][1], 1);
    PlayerTextDrawSetProportional(playerid, MissoesNew[playerid][1], 1);
    PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][1], 0);

    MissoesNew[playerid][2] = CreatePlayerTextDraw(playerid, 283.000000, 294.000000, "1.000 Ryos");
    PlayerTextDrawFont(playerid, MissoesNew[playerid][2], 1);
    PlayerTextDrawLetterSize(playerid, MissoesNew[playerid][2], 0.200000, 1.600000);
    PlayerTextDrawTextSize(playerid, MissoesNew[playerid][2], 629.500000, 298.000000);
    PlayerTextDrawSetOutline(playerid, MissoesNew[playerid][2], 1);
    PlayerTextDrawSetShadow(playerid, MissoesNew[playerid][2], 0);
    PlayerTextDrawAlignment(playerid, MissoesNew[playerid][2], 2);
    PlayerTextDrawColor(playerid, MissoesNew[playerid][2], -1);
    PlayerTextDrawBackgroundColor(playerid, MissoesNew[playerid][2], 0);
    PlayerTextDrawBoxColor(playerid, MissoesNew[playerid][2], 0);
    PlayerTextDrawUseBox(playerid, MissoesNew[playerid][2], 1);
    PlayerTextDrawSetProportional(playerid, MissoesNew[playerid][2], 1);
    PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][2], 0);

    MissoesNew[playerid][3] = CreatePlayerTextDraw(playerid, 330.000000, 294.000000, "1.000 XP");
    PlayerTextDrawFont(playerid, MissoesNew[playerid][3], 1);
    PlayerTextDrawLetterSize(playerid, MissoesNew[playerid][3], 0.200000, 1.600000);
    PlayerTextDrawTextSize(playerid, MissoesNew[playerid][3], 629.500000, 298.000000);
    PlayerTextDrawSetOutline(playerid, MissoesNew[playerid][3], 1);
    PlayerTextDrawSetShadow(playerid, MissoesNew[playerid][3], 0);
    PlayerTextDrawAlignment(playerid, MissoesNew[playerid][3], 2);
    PlayerTextDrawColor(playerid, MissoesNew[playerid][3], -1);
    PlayerTextDrawBackgroundColor(playerid, MissoesNew[playerid][3], 0);
    PlayerTextDrawBoxColor(playerid, MissoesNew[playerid][3], 0);
    PlayerTextDrawUseBox(playerid, MissoesNew[playerid][3], 1);
    PlayerTextDrawSetProportional(playerid, MissoesNew[playerid][3], 1);
    PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][3], 0);

    MissoesNew[playerid][4] = CreatePlayerTextDraw(playerid, 384.000000, 295.000000, "1.000 XP");
    PlayerTextDrawFont(playerid, MissoesNew[playerid][4], 1);
    PlayerTextDrawLetterSize(playerid, MissoesNew[playerid][4], 0.154166, 1.600000);
    PlayerTextDrawTextSize(playerid, MissoesNew[playerid][4], 629.500000, 298.000000);
    PlayerTextDrawSetOutline(playerid, MissoesNew[playerid][4], 1);
    PlayerTextDrawSetShadow(playerid, MissoesNew[playerid][4], 0);
    PlayerTextDrawAlignment(playerid, MissoesNew[playerid][4], 2);
    PlayerTextDrawColor(playerid, MissoesNew[playerid][4], -1);
    PlayerTextDrawBackgroundColor(playerid, MissoesNew[playerid][4], 0);
    PlayerTextDrawBoxColor(playerid, MissoesNew[playerid][4], 0);
    PlayerTextDrawUseBox(playerid, MissoesNew[playerid][4], 1);
    PlayerTextDrawSetProportional(playerid, MissoesNew[playerid][4], 1);
    PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][4], 0);

    MissoesNew[playerid][5] = CreatePlayerTextDraw(playerid, 416.000000, 295.000000, "1.000 XP");
    PlayerTextDrawFont(playerid, MissoesNew[playerid][5], 1);
    PlayerTextDrawLetterSize(playerid, MissoesNew[playerid][5], 0.154166, 1.600000);
    PlayerTextDrawTextSize(playerid, MissoesNew[playerid][5], 629.500000, 298.000000);
    PlayerTextDrawSetOutline(playerid, MissoesNew[playerid][5], 1);
    PlayerTextDrawSetShadow(playerid, MissoesNew[playerid][5], 0);
    PlayerTextDrawAlignment(playerid, MissoesNew[playerid][5], 2);
    PlayerTextDrawColor(playerid, MissoesNew[playerid][5], -1);
    PlayerTextDrawBackgroundColor(playerid, MissoesNew[playerid][5], 0);
    PlayerTextDrawBoxColor(playerid, MissoesNew[playerid][5], 0);
    PlayerTextDrawUseBox(playerid, MissoesNew[playerid][5], 1);
    PlayerTextDrawSetProportional(playerid, MissoesNew[playerid][5], 1);
    PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][5], 0);

    MissoesNew[playerid][6] = CreatePlayerTextDraw(playerid, 260.000000, 329.000000, "_");
    PlayerTextDrawFont(playerid, MissoesNew[playerid][6], 2);
    PlayerTextDrawLetterSize(playerid, MissoesNew[playerid][6], 0.258332, 1.750000);
    PlayerTextDrawTextSize(playerid, MissoesNew[playerid][6], 11.000000, 64.000000);
    PlayerTextDrawSetOutline(playerid, MissoesNew[playerid][6], 1);
    PlayerTextDrawSetShadow(playerid, MissoesNew[playerid][6], 0);
    PlayerTextDrawAlignment(playerid, MissoesNew[playerid][6], 2);
    PlayerTextDrawColor(playerid, MissoesNew[playerid][6], -1);
    PlayerTextDrawBackgroundColor(playerid, MissoesNew[playerid][6], 255);
    PlayerTextDrawBoxColor(playerid, MissoesNew[playerid][6], 0);
    PlayerTextDrawUseBox(playerid, MissoesNew[playerid][6], 1);
    PlayerTextDrawSetProportional(playerid, MissoesNew[playerid][6], 1);
    PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][6], 1);

    MissoesNew[playerid][7] = CreatePlayerTextDraw(playerid, 394.000000, 329.000000, "_");
    PlayerTextDrawFont(playerid, MissoesNew[playerid][7], 2);
    PlayerTextDrawLetterSize(playerid, MissoesNew[playerid][7], 0.258332, 1.750000);
    PlayerTextDrawTextSize(playerid, MissoesNew[playerid][7], 11.000000, 64.000000);
    PlayerTextDrawSetOutline(playerid, MissoesNew[playerid][7], 1);
    PlayerTextDrawSetShadow(playerid, MissoesNew[playerid][7], 0);
    PlayerTextDrawAlignment(playerid, MissoesNew[playerid][7], 2);
    PlayerTextDrawColor(playerid, MissoesNew[playerid][7], -1);
    PlayerTextDrawBackgroundColor(playerid, MissoesNew[playerid][7], 255);
    PlayerTextDrawBoxColor(playerid, MissoesNew[playerid][7], 0);
    PlayerTextDrawUseBox(playerid, MissoesNew[playerid][7], 1);
    PlayerTextDrawSetProportional(playerid, MissoesNew[playerid][7], 1);
    PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][7], 1);
    return 1;
}


// ==========================================================
// Missoes (painel novo) - PlayerTextDraws sob demanda
// Motivo: economizar PTD para nao quebrar HUD/Skillbar.
// ==========================================================
stock MissoesNew_UIReset(playerid)
{
    for(new i = 0; i < 8; i++) MissoesNew[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    return 1;
}


// ------------------------------------------------------------
// IMPORTANTE (BUG FIX):
//  PlayerTextDraw ID 0 (zero) E VALIDO no SA-MP.
//  O codigo antigo tratava PlayerText:0 como invalido, o que fazia:
//   - Recriar o painel toda hora
//   - NAO destruir o PTD 0, vazando PlayerTextDraws
//  Resultado: depois de algumas aberturas, faltava descricao/botoes e nao clicava.
// ------------------------------------------------------------

// Chame isso em OnPlayerConnect (OU garanta que MissoesNew_UIReset seja chamado uma vez por player)
stock MissoesNew_OnConnect(playerid)
{
    MissoesNew_UIReset(playerid);
    return 1;
}

// Chame isso em OnPlayerDisconnect para nao vazar PlayerTextDraws
stock MissoesNew_OnDisconnect(playerid)
{
    MissoesNew_UIDestroy(playerid);
    return 1;
}

stock MissoesNew_UIDestroy(playerid)
{
    // Destroi TODAS as PTDs do painel (se existirem) e marca como INVALID.
    // Isso evita o bug de "so aparece o titulo" quando parte do array fica 0/INVALID.
    for(new i = 0; i < 8; i++)
    {
        if(MissoesNew[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawDestroy(playerid, MissoesNew[playerid][i]);
        }
        MissoesNew[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    }
    return 1;
}


// Verifica se o painel MissoesNew esta "quebrado":
// - algum indice INVALID_TEXT_DRAW
// - algum indice duplicado (ex: varios indices com 0 por falta de inicializacao ou falha de create)
// Duplicado NUNCA deveria acontecer quando o painel esta corretamente criado.
stock MissoesNew_UIHasInvalidOrDup(playerid)
{
    for(new i = 0; i < 8; i++)
    {
        if(MissoesNew[playerid][i] == PlayerText:INVALID_TEXT_DRAW) return 1;

        for(new j = i + 1; j < 8; j++)
        {
            if(MissoesNew[playerid][i] == MissoesNew[playerid][j]) return 1;
        }
    }
    return 0;
}


stock MissoesNew_UIEnsure(playerid)
{
    // IMPORTANTE:
    // Arrays "new PlayerText:MissoesNew[MAX_PLAYERS][8];" comecam em 0 no Pawn.
    // PlayerText:0 pode ser um ID valido (primeiro PTD criado), entao NAO tratamos 0 como invalido.
    //
    // O que realmente quebra o painel e:
    // - algum indice ficar INVALID_TEXT_DRAW
    // - indices duplicados (ex: varios indices ficam 0 porque nunca foram preenchidos / falha no create)
    //   -> duplicado nunca deveria acontecer quando o painel foi criado corretamente.
    if(MissoesNew_UIHasInvalidOrDup(playerid))
    {
        MissoesNew_UIDestroy(playerid);
        Missoes_CreatePlayerTextDraws_New(playerid);
    }
    return 1;
}