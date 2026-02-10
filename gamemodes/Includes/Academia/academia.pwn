// =============================================================================
//  SHINOBI ROLEPLAY (SHRP) - ACADEMIA (TREINOS / TRILHAS)  [REV 2026]
//  Salve como: Includes/Academia/academia_treinos.pwn   (ANSI)
//
//  O que isso faz:
//    - Sensei/Diretor/Staff libera aluno por 30 minutos para escolher treinos.
//    - Aluno usa /treino para escolher (quando liberado).
//    - /verTreinos (/vertreinos) mais explicativo.
//
//  REQUISITOS no seu enum Info[]:
//    - pTreinoInter1, pTreinoInter2, pTreinoAvancado (do limiteatributos.pwn)
//    - pAcademiaTreinamento   (NOVO)  -> timestamp unix (gettime()) ate quando pode escolher
//    - pAcademiaRank, pMember, pRank, pAdminZC
//
//  Regras:
//    - Pode ter ate 2 intermediarios.
//    - Treino avancado so pode ser escolhido quando:
//        (1) for JOUNIN (pRank >= LA_RANK_JOUNIN)
//        (2) tiver 2 intermediarios definidos (REGRA DURA)
//        (3) avancado obrigatoriamente vira 1 dos intermediarios (fica sobrando 1 inter).
//
//  Auditoria/Logs:
//    - Arquivo: Logs/academia_treinos.log
//    - Discord (opcional): se dcconnector estiver incluido, envia msg num canal.
//
//  IMPORTANTE (mudancas no gamemode):
//    1) No topo do GM:  #include "Includes/Academia/academia_treinos.pwn"
//    2) No OnPlayerConnect:    AcademiaTreinos_InitPlayer(playerid);
//    3) No OnPlayerDisconnect: AcademiaTreinos_InitPlayer(playerid);
//    4) No OnDialogResponse (bem no inicio):
//         if(AcademiaTreinos_OnDialog(playerid, dialogid, response, listitem, inputtext)) return 1;
//
//  Discord (opcional):
//    - Antes de incluir este arquivo, voce pode setar:
//        #define ACA_AUDIT_CHANNEL_NAME  "auditoria-academia"
//      (crie um canal no Discord com esse nome)
// =============================================================================
//#include "Includes\Perfil\limiteatributos.pwn"

#if defined _SHRP_ACADEMIA_TREINOS_
    #endinput
#endif
#define _SHRP_ACADEMIA_TREINOS_

// --- Dependencia: limites/treinos do perfil
#if !defined _SHRP_LIMITE_ATRIBUTOS_
    #tryinclude "Includes/Perfil/limiteatributos.pwn"
#endif
#if !defined _SHRP_LIMITE_ATRIBUTOS_
    #error "Inclua primeiro: Includes/Perfil/limiteatributos.pwn (limites/treinos)."
#endif

// -----------------------------------------------------------------------------
// CONFIG
// -----------------------------------------------------------------------------
#if !defined ACA_TREINO_LIBERADO_SECONDS
    #define ACA_TREINO_LIBERADO_SECONDS  (30 * 60) // 30 minutos
#endif

#if !defined ACA_STAFF_MIN_LEVEL
    #define ACA_STAFF_MIN_LEVEL          (1) // pAdminZC >= 1
#endif

#if !defined ACA_LOG_FILE
    #define ACA_LOG_FILE                 ("Logs/academia_treinos.log")
#endif

// -----------------------------------------------------------------------------
// DIALOGS (nao colide com 2600-2608 do seu sistema atual)
// -----------------------------------------------------------------------------
#define DIALOG_SENSEI_TREINOS_MENU     (2610)
#define DIALOG_SENSEI_TREINOS_SET      (2611)
#define DIALOG_ALUNO_ESCOLHER_INTER    (2612)
#define DIALOG_ALUNO_ESCOLHER_AVANC    (2613)
#define DIALOG_SENSEI_TREINOS_ID       (2614)

// -----------------------------------------------------------------------------
// Estado interno (nao salva)
// -----------------------------------------------------------------------------
new AcaSenseiTarget[MAX_PLAYERS]; // guarda o aluno do menu do sensei

// -----------------------------------------------------------------------------
// Discord audit (opcional)
// -----------------------------------------------------------------------------
#if defined dcconnector_included
    #if !defined ACA_AUDIT_CHANNEL_NAME
        #define ACA_AUDIT_CHANNEL_NAME "auditoria-academia"
    #endif
    new DCC_Channel:gAcaAuditChannel = DCC_INVALID_CHANNEL;
#endif

// -----------------------------------------------------------------------------
// Init (chamar no connect/disconnect)
//  - NAO zera pAcademiaTreinamento aqui (porque voce quer salvar por 30 min)
// -----------------------------------------------------------------------------
stock AcademiaTreinos_InitPlayer(playerid)
{
    AcaSenseiTarget[playerid] = INVALID_PLAYER_ID;
    return 1;
}

// -----------------------------------------------------------------------------
// Helpers (permissoes)
// -----------------------------------------------------------------------------
stock bool:Academia_IsSensei(playerid)
{
    return (Info[playerid][pAcademiaRank] == 2);
}
stock bool:Academia_IsDiretor(playerid)
{
    return (Info[playerid][pAcademiaRank] == 1);
}
stock bool:Academia_IsStaff(playerid)
{
    return (Info[playerid][pAdminZC] >= ACA_STAFF_MIN_LEVEL);
}
stock bool:Academia_IsAlunoRegistrado(playerid)
{
    // No seu GM: 3/4 parecem ser "aluno registrado" (Kiri/Iwa)
    return (Info[playerid][pAcademiaRank] == 3 || Info[playerid][pAcademiaRank] == 4);
}
stock bool:Academia_MesmaVila(playerid, targetid)
{
    return (Info[playerid][pMember] == Info[targetid][pMember]);
}
stock bool:Academia_PodeGerenciarTreinos(playerid, targetid)
{
    if(!IsPlayerConnected(targetid)) return false;

    // Staff: permissao flexivel (qualquer vila/alvo conectado)
    if(Academia_IsStaff(playerid)) return true;

    // Sensei/Diretor: regras normais
    if(!(Academia_IsSensei(playerid) || Academia_IsDiretor(playerid))) return false;
    if(!Academia_MesmaVila(playerid, targetid)) return false;
    if(!Academia_IsAlunoRegistrado(targetid)) return false;

    return true;
}

// -----------------------------------------------------------------------------
// Helpers (tempo / liberacao)
// -----------------------------------------------------------------------------
stock Academia_FormatTime(seconds, dest[], destSize)
{
    new m = seconds / 60;
    new s = seconds % 60;
    format(dest, destSize, "%dm %ds", m, s);
    return 1;
}

// Retorna true se o player ainda esta liberado (Info[pAcademiaTreinamento] > gettime())
// Se estiver expirado, zera para nao ficar "lixo" salvo.
stock bool:Academia_TreinoLiberado(playerid, bool:notify)
{
    if(Info[playerid][pAcademiaTreinamento] > gettime()) return true;

    if(Info[playerid][pAcademiaTreinamento] != 0)
        Info[playerid][pAcademiaTreinamento] = 0;

    if(notify)
        SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Sua liberacao expirou. Peca para um Sensei/Diretor liberar novamente (30 min).");

    return false;
}

stock Academia_SetLiberacao(playerid, seconds)
{
    if(seconds <= 0) Info[playerid][pAcademiaTreinamento] = 0;
    else Info[playerid][pAcademiaTreinamento] = gettime() + seconds;
    return 1;
}

// -----------------------------------------------------------------------------
// Helpers (format / ids)
// -----------------------------------------------------------------------------
stock Academia_AttrName(attrId, dest[], destSize)
{
    switch(attrId)
    {
        case LA_ATTR_TAI: format(dest, destSize, "Taijutsu");
        case LA_ATTR_NIN: format(dest, destSize, "Ninjutsu");
        case LA_ATTR_KEN: format(dest, destSize, "Kenjutsu");
        case LA_ATTR_GEN: format(dest, destSize, "Genjutsu");
        default: format(dest, destSize, "Nenhum");
    }
    return 1;
}

stock Academia_AttrFromListItem(listitem)
{
    // ordem fixa nos dialogs
    switch(listitem)
    {
        case 0: return LA_ATTR_TAI;
        case 1: return LA_ATTR_NIN;
        case 2: return LA_ATTR_KEN;
        case 3: return LA_ATTR_GEN;
    }
    return LA_TREINO_NONE;
}

// -----------------------------------------------------------------------------
// AUDITORIA (arquivo + discord opcional)
// -----------------------------------------------------------------------------
stock AcademiaTreinos_DiscordInit()
{
#if defined dcconnector_included
    if(gAcaAuditChannel == DCC_INVALID_CHANNEL)
    {
        gAcaAuditChannel = DCC_FindChannelByName(ACA_AUDIT_CHANNEL_NAME);
    }
#endif
    return 1;
}

stock Academia_Audit(const action[], actorid, targetid, const extra[] = "")
{

	static lastDiscordTime;
	if(gettime() == lastDiscordTime) {
		// evita mais de 1 msg por segundo
		return 1;
	}
	lastDiscordTime = gettime();

    new msg[256];
    new aname[32], tname[32];

    format(aname, sizeof aname, "%s(%d)", PlayerNameDados(actorid), actorid);

    if(targetid != INVALID_PLAYER_ID && IsPlayerConnected(targetid))
        format(tname, sizeof tname, "%s(%d)", PlayerNameDados(targetid), targetid);
    else
        format(tname, sizeof tname, "-");

    format(msg, sizeof msg,
        "[ACADEMIA] %s | por %s | alvo %s | vila=%d | %s",
        action, aname, tname,
        (targetid != INVALID_PLAYER_ID && IsPlayerConnected(targetid)) ? Info[targetid][pMember] : -1,
        extra
    );

    // Console
    printf("%s", msg);

    // Arquivo
    new File:f = fopen(ACA_LOG_FILE, io_append);
    if(f)
    {
        fwrite(f, msg);
        fwrite(f, "\r\n");
        fclose(f);
    }

    // Discord (opcional)
#if defined dcconnector_included
    AcademiaTreinos_DiscordInit();
    if(gAcaAuditChannel != DCC_INVALID_CHANNEL)
    {
        DCC_SendChannelMessage(gAcaAuditChannel, msg);
    }
#endif
    return 1;
}

// -----------------------------------------------------------------------------
// Print mais autoexplicativo (/verTreinos ou /vertreinos)
// -----------------------------------------------------------------------------
stock Academia_PrintTreinos(playerid, targetid)
{
    new a1[24], a2[24], aa[24];
    new line[180];

    Academia_AttrName(Info[targetid][pTreinoInter1], a1, sizeof(a1));
    Academia_AttrName(Info[targetid][pTreinoInter2], a2, sizeof(a2));
    Academia_AttrName(Info[targetid][pTreinoAvancado], aa, sizeof(aa));

    format(line, sizeof(line), "{AB7C4E}(ACADEMIA) {FFFFFF}%s {AB7C4E}[%d]", PlayerNameDados(targetid), targetid);
    SendClientMessage(playerid, -1, line);

    format(line, sizeof(line), "{AB7C4E} - Inter 1: {FFFFFF}%s {AB7C4E}| Inter 2: {FFFFFF}%s {AB7C4E}| Avancado: {FFFFFF}%s", a1, a2, aa);
    SendClientMessage(playerid, -1, line);

    // Proximo passo
    if(Info[targetid][pTreinoInter1] == LA_TREINO_NONE)
        SendClientMessage(playerid, -1, "{AB7C4E} - Proximo passo: {FFFFFF}definir Intermediario 1.");
    else if(Info[targetid][pTreinoAvancado] == LA_TREINO_NONE && Info[targetid][pTreinoInter2] == LA_TREINO_NONE)
        SendClientMessage(playerid, -1, "{AB7C4E} - Proximo passo: {FFFFFF}definir Intermediario 2.");
    else if(Info[targetid][pTreinoAvancado] == LA_TREINO_NONE && Info[targetid][pRank] >= LA_RANK_JOUNIN)
        SendClientMessage(playerid, -1, "{AB7C4E} - Proximo passo: {FFFFFF}escolher Avancado (somente se tiver 2 Intermediarios).");
    else if(Info[targetid][pTreinoAvancado] == LA_TREINO_NONE)
        SendClientMessage(playerid, -1, "{AB7C4E} - Status: {FFFFFF}ao virar Jounin e com 2 Intermediarios, voce libera o Avancado.");
    else
        SendClientMessage(playerid, -1, "{AB7C4E} - Status: {FFFFFF}treinos completos.");

    // Tempo de liberacao (se tiver)
    if(Info[targetid][pAcademiaTreinamento] > gettime())
    {
        new left = Info[targetid][pAcademiaTreinamento] - gettime();
        new t[24];
        Academia_FormatTime(left, t, sizeof t);
        format(line, sizeof(line), "{AB7C4E} - Liberacao ativa: {FFFFFF}%s {AB7C4E}restante (use /treino).", t);
        SendClientMessage(playerid, -1, line);
    }
    else
    {
        SendClientMessage(playerid, -1, "{AB7C4E} - Liberacao: {FFFFFF}INATIVA {AB7C4E}(Sensei/Diretor libera por 30 min).");
    }

    // Regras (curtas)
    SendClientMessage(playerid, -1, "{AB7C4E} - Regra dura: {FFFFFF}Avancado so com 2 intermediarios + Jounin.");

    return 1;
}

// -----------------------------------------------------------------------------
// Regra ao setar AVANCADO (REGRA DURA):
//  - so Jounin
//  - PRECISA TER 2 intermediarios
//  - avancado deve ser 1 dos intermediarios
//  - quando vira avancado, sobra apenas 1 inter (o outro)
// -----------------------------------------------------------------------------
stock bool:Academia_SetAvancadoDeInter(playerid, targetid, attrId)
{
    if(Info[targetid][pRank] < LA_RANK_JOUNIN)
    {
        SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) O treino avancado so pode ser definido quando o ninja for (Jounin).");
        return false;
    }

    new inter1 = Info[targetid][pTreinoInter1];
    new inter2 = Info[targetid][pTreinoInter2];

    // REGRA DURA: precisa ter 2 inter
    if(inter1 == LA_TREINO_NONE || inter2 == LA_TREINO_NONE)
    {
        SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) REGRA DURA: para ter avancado, o ninja precisa primeiro ter 2 treinos intermediarios.");
        return false;
    }

    if(attrId == LA_TREINO_NONE || (attrId != inter1 && attrId != inter2))
    {
        SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) O avancado deve ser escolhido a partir de um dos seus treinos intermediarios.");
        return false;
    }

    Info[targetid][pTreinoAvancado] = attrId;

    // Reorganiza intermediarios: sobra apenas 1 inter (o que NAO virou avancado)
    if(attrId == inter1)
    {
        Info[targetid][pTreinoInter1] = inter2;
        Info[targetid][pTreinoInter2] = LA_TREINO_NONE;
    }
    else
    {
        Info[targetid][pTreinoInter1] = inter1;
        Info[targetid][pTreinoInter2] = LA_TREINO_NONE;
    }

    return true;
}

// -----------------------------------------------------------------------------
// Setar intermediario (pode ter 2 ate virar avancado)
// -----------------------------------------------------------------------------
stock bool:Academia_AddInter(playerid, targetid, attrId)
{
    if(attrId == LA_TREINO_NONE) return false;

    if(attrId == Info[targetid][pTreinoInter1] || attrId == Info[targetid][pTreinoInter2] || attrId == Info[targetid][pTreinoAvancado])
    {
        SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Esse atributo ja esta em algum treino.");
        return false;
    }

    // Se ja tem avancado, so 1 intermediario pode existir (slot 1).
    if(Info[targetid][pTreinoAvancado] != LA_TREINO_NONE)
    {
        Info[targetid][pTreinoInter1] = attrId;
        Info[targetid][pTreinoInter2] = LA_TREINO_NONE;
        return true;
    }

    // Sem avancado: pode ter ate 2 inter
    if(Info[targetid][pTreinoInter1] == LA_TREINO_NONE)
    {
        Info[targetid][pTreinoInter1] = attrId;
        return true;
    }
    if(Info[targetid][pTreinoInter2] == LA_TREINO_NONE)
    {
        Info[targetid][pTreinoInter2] = attrId;
        return true;
    }

    SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Este ninja ja possui 2 treinos intermediarios. (No Jounin, escolha 1 deles para virar avancado.)");
    return false;
}

// -----------------------------------------------------------------------------
// Menus
// -----------------------------------------------------------------------------
stock AcademiaTreinos_OpenFromMenuAcademia(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_SENSEI_TREINOS_ID, DIALOG_STYLE_INPUT,
        "{AB7C4E}Sensei - Gerenciar Treinos",
        "{FFFFFF}Digite o ID do aluno para gerenciar os treinos.",
        "Abrir", "Cancelar"
    );
    Audio_Play(playerid, 58);
    return 1;
}

stock AcademiaTreinos_ShowSenseiMenu(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_SENSEI_TREINOS_MENU, DIALOG_STYLE_LIST,
        "{AB7C4E}Sensei - Treinos (Academia)",
        "Liberar aluno (30 min)\nRevogar liberacao do aluno\nSetar treino intermediario\nSetar treino avancado (Jounin)\nLimpar treinos do aluno\nVer treinos do aluno",
        "Selecionar", "Fechar"
    );
    Audio_Play(playerid, 58);
    return 1;
}

stock AcademiaTreinos_ShowEscolhaInter(playerid, bool:segundoInter)
{
    new title[80];
    if(segundoInter) format(title, sizeof(title), "{AB7C4E}Escolher Treino Intermediario (Inter 2)");
    else format(title, sizeof(title), "{AB7C4E}Escolher Treino Intermediario (Inter 1)");

    ShowPlayerDialog(playerid, DIALOG_ALUNO_ESCOLHER_INTER, DIALOG_STYLE_LIST,
        title,
        "Taijutsu\nNinjutsu\nKenjutsu\nGenjutsu",
        "Escolher", "Cancelar"
    );
    Audio_Play(playerid, 58);
    return 1;
}

stock AcademiaTreinos_ShowEscolhaAvancado(playerid)
{
    // REGRA DURA: precisa ter 2 inter
    if(Info[playerid][pTreinoInter1] == LA_TREINO_NONE || Info[playerid][pTreinoInter2] == LA_TREINO_NONE)
    {
        SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) REGRA DURA: voce precisa ter 2 intermediarios antes de escolher o avancado.");
        return 1;
    }

    new s[128], a1[24], a2[24];
    Academia_AttrName(Info[playerid][pTreinoInter1], a1, sizeof(a1));
    Academia_AttrName(Info[playerid][pTreinoInter2], a2, sizeof(a2));
    format(s, sizeof(s), "%s\n%s", a1, a2);

    ShowPlayerDialog(playerid, DIALOG_ALUNO_ESCOLHER_AVANC, DIALOG_STYLE_LIST,
        "{AB7C4E}Escolher Treino Avancado (a partir dos 2 Intermediarios)",
        s,
        "Escolher", "Cancelar"
    );
    Audio_Play(playerid, 58);
    return 1;
}

// -----------------------------------------------------------------------------
// Comandos
// -----------------------------------------------------------------------------
CMD:verTreinos(playerid, params[])
{
    // /vertreinos (sem id) => voce mesmo
    new targetid;
    if(sscanf(params, "d", targetid))
    {
        return Academia_PrintTreinos(playerid, playerid);
    }

    if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) ID invalido.");

    // Staff pode ver qualquer um. Sensei/Diretor ve conforme permissao.
    if(!(Academia_IsStaff(playerid) || Academia_IsSensei(playerid) || Academia_IsDiretor(playerid)))
        return SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Voce nao tem permissao para ver os treinos de outro ninja.");

    return Academia_PrintTreinos(playerid, targetid);
}

CMD:senseitreino(playerid, params[])
{
    new targetid;
    if(sscanf(params, "d", targetid)) return SendClientMessage(playerid, -1, "{AB7C4E}(USO) /senseitreino (ID do aluno)");
    if(!Academia_PodeGerenciarTreinos(playerid, targetid)) return SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Voce nao pode gerenciar treinos desse ninja.");

    AcaSenseiTarget[playerid] = targetid;
    return AcademiaTreinos_ShowSenseiMenu(playerid);
}

CMD:treino(playerid)
{
    if(!Academia_IsAlunoRegistrado(playerid)) return SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Voce nao esta registrado na Academia.");

    if(!Academia_TreinoLiberado(playerid, false))
        return SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Voce nao esta liberado. Peca para um Sensei/Diretor liberar (30 min).");

    // Inter 1
    if(Info[playerid][pTreinoInter1] == LA_TREINO_NONE)
        return AcademiaTreinos_ShowEscolhaInter(playerid, false);

    // Inter 2
    if(Info[playerid][pTreinoAvancado] == LA_TREINO_NONE && Info[playerid][pTreinoInter2] == LA_TREINO_NONE)
        return AcademiaTreinos_ShowEscolhaInter(playerid, true);

    // Avancado (REGRA DURA: precisa 2 inter + Jounin)
    if(Info[playerid][pTreinoAvancado] == LA_TREINO_NONE
        && Info[playerid][pRank] >= LA_RANK_JOUNIN
        && Info[playerid][pTreinoInter1] != LA_TREINO_NONE
        && Info[playerid][pTreinoInter2] != LA_TREINO_NONE)
    {
        return AcademiaTreinos_ShowEscolhaAvancado(playerid);
    }

    SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Voce ja definiu seus treinos (ou ainda nao cumpre a regra do avancado). Use /vertreinos.");
    return 1;
}

// -----------------------------------------------------------------------------
// Handler: OnDialogResponse (chamar do seu GM)
// Retorna true se o dialog era deste sistema.
// -----------------------------------------------------------------------------
stock bool:AcademiaTreinos_OnDialog(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_SENSEI_TREINOS_ID)
    {
        if(!response) return true;

        new targetid = strval(inputtext);
        if(!Academia_PodeGerenciarTreinos(playerid, targetid))
        {
            SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) ID invalido ou sem permissao para gerenciar esse ninja.");
            return true;
        }
        AcaSenseiTarget[playerid] = targetid;
        AcademiaTreinos_ShowSenseiMenu(playerid);
        return true;
    }

    if(dialogid == DIALOG_SENSEI_TREINOS_MENU)
    {
        if(!response) return true;

        new targetid = AcaSenseiTarget[playerid];
        if(!Academia_PodeGerenciarTreinos(playerid, targetid))
        {
            SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Aluno invalido/fora ou sem permissao.");
            return true;
        }

        switch(listitem)
        {
            case 0: // Liberar aluno (30 min)
            {
                Academia_SetLiberacao(targetid, ACA_TREINO_LIBERADO_SECONDS);

                SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Voce liberou o aluno por 30 minutos. (Aluno: /treino)");
                SendClientMessage(targetid, -1, "{AB7C4E}(TREINOS) Seu Sensei liberou voce por 30 minutos para escolher treinos. Use /treino.");

                Academia_Audit("LIBERAR_30MIN", playerid, targetid, "liberacao=30min");
            }
            case 1: // Revogar liberacao
            {
                Academia_SetLiberacao(targetid, 0);

                SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Voce revogou a liberacao do aluno.");
                SendClientMessage(targetid, -1, "{AB7C4E}(TREINOS) Sua liberacao foi revogada. Peca novamente ao Sensei.");

                Academia_Audit("REVOGAR_LIBERACAO", playerid, targetid, "liberacao=0");
            }
            case 2: // Setar intermediario
            {
                SetPVarInt(playerid, "ACA_SET_MODE", 1); // 1 = inter
                ShowPlayerDialog(playerid, DIALOG_SENSEI_TREINOS_SET, DIALOG_STYLE_LIST,
                    "{AB7C4E}Sensei - Setar Intermediario",
                    "Taijutsu\nNinjutsu\nKenjutsu\nGenjutsu",
                    "Setar", "Voltar"
                );
                Audio_Play(playerid, 58);
            }
            case 3: // Setar avancado (Jounin)
            {
                SetPVarInt(playerid, "ACA_SET_MODE", 2); // 2 = avancado
                ShowPlayerDialog(playerid, DIALOG_SENSEI_TREINOS_SET, DIALOG_STYLE_LIST,
                    "{AB7C4E}Sensei - Setar Avancado (REGRA: precisa 2 Inter + Jounin)",
                    "Taijutsu\nNinjutsu\nKenjutsu\nGenjutsu",
                    "Setar", "Voltar"
                );
                Audio_Play(playerid, 58);
            }
            case 4: // Limpar
            {
                LA_ClearTreinos(targetid);
                Academia_SetLiberacao(targetid, 0);

                SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Treinos do aluno foram limpos.");
                SendClientMessage(targetid, -1, "{AB7C4E}(TREINOS) Seus treinos foram resetados pelo Sensei.");

                Academia_Audit("LIMPAR_TREINOS", playerid, targetid, "reset=1");
            }
            case 5: // Ver treinos
            {
                Academia_PrintTreinos(playerid, targetid);
            }
        }
        return true;
    }

    if(dialogid == DIALOG_SENSEI_TREINOS_SET)
    {
        if(!response)
        {
            DeletePVar(playerid, "ACA_SET_MODE");
            AcademiaTreinos_ShowSenseiMenu(playerid);
            return true;
        }

        new targetid = AcaSenseiTarget[playerid];
        if(!Academia_PodeGerenciarTreinos(playerid, targetid))
        {
            SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Aluno invalido/fora ou sem permissao.");
            DeletePVar(playerid, "ACA_SET_MODE");
            return true;
        }

        new mode = GetPVarInt(playerid, "ACA_SET_MODE");
        DeletePVar(playerid, "ACA_SET_MODE");

        new attrId = Academia_AttrFromListItem(listitem);
        if(attrId == LA_TREINO_NONE)
        {
            AcademiaTreinos_ShowSenseiMenu(playerid);
            return true;
        }

        if(mode == 1)
        {
            if(Academia_AddInter(playerid, targetid, attrId))
            {
                new nm[24], extra[64];
                Academia_AttrName(attrId, nm, sizeof(nm));
                format(extra, sizeof extra, "inter=%s", nm);

                SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Intermediario setado/adicionado com sucesso.");
                SendClientMessage(targetid, -1, "{AB7C4E}(TREINOS) Seu Sensei definiu um treino intermediario para voce.");

                Academia_Audit("SET_INTER", playerid, targetid, extra);
            }
        }
        else if(mode == 2)
        {
            if(Academia_SetAvancadoDeInter(playerid, targetid, attrId))
            {
                new nm2[24], extra2[64];
                Academia_AttrName(attrId, nm2, sizeof(nm2));
                format(extra2, sizeof extra2, "avancado=%s", nm2);

                SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Avancado definido com sucesso.");
                SendClientMessage(targetid, -1, "{AB7C4E}(TREINOS) Seu Sensei definiu seu treino avancado.");

                // Quando conclui avancado, trava a liberacao (fim do fluxo)
                Academia_SetLiberacao(targetid, 0);

                Academia_Audit("SET_AVANCADO", playerid, targetid, extra2);
            }
        }

        AcademiaTreinos_ShowSenseiMenu(playerid);
        return true;
    }

    if(dialogid == DIALOG_ALUNO_ESCOLHER_INTER)
    {
        if(!response) return true;

        if(!Academia_IsAlunoRegistrado(playerid)) return true;
        if(!Academia_TreinoLiberado(playerid, true)) return true;

        new attrId = Academia_AttrFromListItem(listitem);
        if(attrId == LA_TREINO_NONE) return true;

        new bool:segundo = (Info[playerid][pTreinoInter1] != LA_TREINO_NONE);

        if(Academia_AddInter(playerid, playerid, attrId))
        {
            new nm[24], msg[96], extra[64];
            Academia_AttrName(attrId, nm, sizeof(nm));
            format(extra, sizeof extra, "inter=%s", nm);

            if(!segundo)
            {
                format(msg, sizeof(msg), "{AB7C4E}(TREINOS) Intermediario 1 definido: {FFFFFF}%s", nm);
                SendClientMessage(playerid, -1, msg);
                Academia_Audit("ALUNO_ESCOLHEU_INTER1", playerid, playerid, extra);
            }
            else
            {
                format(msg, sizeof(msg), "{AB7C4E}(TREINOS) Intermediario 2 definido: {FFFFFF}%s", nm);
                SendClientMessage(playerid, -1, msg);
                Academia_Audit("ALUNO_ESCOLHEU_INTER2", playerid, playerid, extra);
            }

            // Se completou 2 inter, trava a liberacao (fim do fluxo intermediario)
            if(Info[playerid][pTreinoInter1] != LA_TREINO_NONE && Info[playerid][pTreinoInter2] != LA_TREINO_NONE)
            {
                Academia_SetLiberacao(playerid, 0);
                SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Seus 2 intermediarios foram definidos. Ao virar Jounin, peca liberacao para escolher o avancado.");
            }
        }
        return true;
    }

    if(dialogid == DIALOG_ALUNO_ESCOLHER_AVANC)
    {
        if(!response) return true;

        if(!Academia_IsAlunoRegistrado(playerid)) return true;
        if(!Academia_TreinoLiberado(playerid, true)) return true;

        if(Info[playerid][pRank] < LA_RANK_JOUNIN)
        {
            SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Voce so pode escolher o avancado quando for (Jounin).");
            return true;
        }

        // REGRA DURA: precisa ter 2 inter
        if(Info[playerid][pTreinoInter1] == LA_TREINO_NONE || Info[playerid][pTreinoInter2] == LA_TREINO_NONE)
        {
            SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) REGRA DURA: voce precisa ter 2 intermediarios antes de escolher o avancado.");
            return true;
        }

        // Lista sempre com 2 itens (Inter1 e Inter2)
        new inter1 = Info[playerid][pTreinoInter1];
        new inter2 = Info[playerid][pTreinoInter2];

        new attrEscolhido = (listitem == 0) ? inter1 : inter2;
        if(attrEscolhido == LA_TREINO_NONE) return true;

        if(Academia_SetAvancadoDeInter(playerid, playerid, attrEscolhido))
        {
            new nm[24], msg2[96], extra[64];
            Academia_AttrName(attrEscolhido, nm, sizeof(nm));
            format(extra, sizeof extra, "avancado=%s", nm);

            format(msg2, sizeof(msg2), "{AB7C4E}(TREINOS) Treino avancado definido: {FFFFFF}%s", nm);
            SendClientMessage(playerid, -1, msg2);

            // Concluiu: trava liberacao
            Academia_SetLiberacao(playerid, 0);
            SendClientMessage(playerid, -1, "{AB7C4E}(TREINOS) Concluido. Use /vertreinos para conferir.");

            Academia_Audit("ALUNO_ESCOLHEU_AVANCADO", playerid, playerid, extra);
        }
        return true;
    }

    return false;
}