#if defined _SHRP_REGISTRO_PERSONAGEM_
    #endinput
#endif
#define _SHRP_REGISTRO_PERSONAGEM_

// ========================================================================
// Registro de Personagem (SHRP)
// Fluxo: Sexo -> Nome -> Vila -> Elemento -> Clã/Kekkei Genkai -> LIBERA PLAYER
//
// Este módulo só cuida do "personagem novo" (criação inicial).
// Ele usa variáveis/rotinas já existentes no gamemode (Info[][], AbrirEscolhaVila, etc).
// ========================================================================

// Dialogs exclusivos do módulo (evita conflito com outros sistemas)
#if !defined DIALOG_REGCHAR_ELEMENTO
    #define DIALOG_REGCHAR_ELEMENTO     (26001)
#endif

#if !defined DIALOG_REGCHAR_CLAN
    #define DIALOG_REGCHAR_CLAN         (26002)
#endif

// ------------------------------------------------------------
// Pré-checagens: whitelist / manutenção
// Retorna 1 se pode continuar, 0 se bloqueou (e já abriu o dialog).
// ------------------------------------------------------------
stock RegChar_PreCheck(playerid)
{
    if(WhiteListt == 1 && Info[playerid][pWhiteList] == 0)
    {
        ShowPlayerDialog(playerid, DIALOG_WHITELIST, DIALOG_STYLE_MSGBOX,
            "{E9FE23}WhiteList",
            "{FFFFFF}Você precisa passar por uma verificação para conseguir jogar no servidor.\n\n{E9FE23}Fale com um Staff.{FFFFFF}",
            "Fechar");
        return 0;
    }

    if(ServidorEmManutencao == 1)
    {
        ShowPlayerDialog(playerid, DIALOG_MANUTENCAO, DIALOG_STYLE_MSGBOX,
            "{E9FE23}Manutenção",
            "{FFFFFF}Servidor está em manutenção.\n\n{E9FE23}Tente mais tarde.{FFFFFF}",
            "Fechar");
        return 0;
    }
    return 1;
}

// ------------------------------------------------------------
// Tela: Nome
// ------------------------------------------------------------
stock RegChar_ShowNome(playerid)
{
    new string[256];
    format(string, sizeof(string),
        "{FFFFFF}*O nome do personagem poderá ser trocado apenas no (CK) Character Kill.\n\
*Minimo de 4 caracteres e maximo de 9 caracteres.\n\
*Use apenas letras.\n\
*Use apenas nome japonês ou inglês.");

    ShowPlayerDialog(playerid, DIALOG_ESCOLHERNOME, DIALOG_STYLE_INPUT,
        "{E9FE23}Escolha o nome do seu personagem",
        string,
        "Aceitar",
        "Fechar");
    Audio_Play(playerid, 58);
    return 1;
}

// Chamado após escolher o SEXO (REG_SEX)
stock RegChar_AfterSex(playerid)
{
    CancelSelectTextDraw(playerid);
    if(!RegChar_PreCheck(playerid)) return 1;
    return RegChar_ShowNome(playerid);
}

// Chamado após escolher o NOME (DIALOG_ESCOLHERNOME OK)
stock RegChar_AfterNome(playerid)
{
    // A vila é escolhida por TextDraw (sistema já existente no GM)
    SelectTextDraw(playerid, COLOR_WHITE);
    AbrirEscolhaVila(playerid);
    return 1;
}

// ------------------------------------------------------------
// Tela: Elemento
// ------------------------------------------------------------
stock RegChar_ShowElemento(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_REGCHAR_ELEMENTO, DIALOG_STYLE_LIST,
        "{E9FE23}Escolha do Elemento",
        "Katon (Fogo)\nFuuton (Vento)\nDoton (Terra)\nSuiton (Água)\nRaiton (Raio)",
        "Escolher",
        "Voltar");
    Audio_Play(playerid, 58);
    return 1;
}

// ------------------------------------------------------------
// Tela: Clã / Kekkei Genkai
// (usa os clãs já existentes no GM: Senju/Uchiha/Nara/Hyuuga)
// ------------------------------------------------------------
stock RegChar_ShowClan(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_REGCHAR_CLAN, DIALOG_STYLE_LIST,
        "{E9FE23}Escolha da Kekkei Genkai / Clã",
        "Senju\nUchiha\nNara\nHyuuga",
        "Escolher",
        "Voltar");
    Audio_Play(playerid, 58);
    return 1;
}

stock RegChar_ResetElementos(playerid)
{
    Info[playerid][pKaton]  = 0;
    Info[playerid][pFuton]  = 0;
    Info[playerid][pDoton]  = 0;
    Info[playerid][pSuiton] = 0;
    Info[playerid][pRaiton] = 0;
    return 1;
}

stock RegChar_ApplyElemento(playerid, listitem)
{
    RegChar_ResetElementos(playerid);

    switch(listitem)
    {
        case 0: Info[playerid][pKaton]  = 1; // Katon
        case 1: Info[playerid][pFuton]  = 1; // Fuuton
        case 2: Info[playerid][pDoton]  = 1; // Doton
        case 3: Info[playerid][pSuiton] = 1; // Suiton
        case 4: Info[playerid][pRaiton] = 1; // Raiton
    }
    return 1;
}

stock RegChar_ApplyClan(playerid, listitem)
{
    // 1=Senju, 2=Uchiha, 3=Nara, 4=Hyuuga (mesmo padrão do GM)
    Info[playerid][pClan] = (listitem + 1);
    return 1;
}

// Chamado quando a VILA foi escolhida (Konoha/Kiri). Abre elemento.
stock RegChar_AfterVilaEscolhida(playerid)
{
    if(!RegChar_PreCheck(playerid)) return 1;
    return RegChar_ShowElemento(playerid);
}

// Finaliza criação: salva, marca registro completo e libera o player.
stock RegChar_Finish(playerid)
{
    Info[playerid][pReg] = 1;

    // Salva tudo agora (nome/vila/elemento/clã/etc)
    OnPlayerSavedStats(playerid);

    // Libera o jogador para jogar
    TogglePlayerControllable(playerid, 1);
    SetCameraBehindPlayer(playerid);

    SendClientMessage(playerid, -1, "[SHRP] Registro concluído! Bem-vindo.");
    return 1;
}

// ========================================================================
// Hook do OnDialogResponse
// Retorna 1 se o módulo tratou o dialog.
// ========================================================================
stock RegChar_OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_REGCHAR_ELEMENTO:
        {
            if(!response)
            {
                // obriga a escolher
                return RegChar_ShowElemento(playerid);
            }

            RegChar_ApplyElemento(playerid, listitem);
            return RegChar_ShowClan(playerid);
        }

        case DIALOG_REGCHAR_CLAN:
        {
            if(!response)
            {
                // obriga a escolher
                return RegChar_ShowClan(playerid);
            }

            RegChar_ApplyClan(playerid, listitem);
            return RegChar_Finish(playerid);
        }
    }
    return 0;
}