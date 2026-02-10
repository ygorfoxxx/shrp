#if defined _SWRP_FAMA_INC
    #endinput
#endif
#define _SWRP_FAMA_INC

// =====================================================
//  SWRP - Sistema de Fama (LEVE / DOF2)
//  - Ninja Fama (0..200) -> Rank E..SS (NinjaFamaRank[playerid])
//  - Fama de Cla (0..50)
//  - Opiniao Popular (0..100) default 50
//  - Alcunha (string)
//  Salva em: scriptfiles/SWRP/Fama/<Nome>.ini
// =====================================================

#define FAMA_MAX_NINJA      (200)
#define FAMA_MAX_CLAN       (50)
#define OPINIAO_DEFAULT     (50)
#define OPINIAO_MAX         (100)

new FamaNinjaPts[MAX_PLAYERS];
new FamaClanPts[MAX_PLAYERS];
new FamaOpiniao[MAX_PLAYERS];
new FamaAlcunha[MAX_PLAYERS][32];
new bool:FamaLoaded[MAX_PLAYERS];

stock Fama_Reset(playerid)
{
    FamaNinjaPts[playerid] = 0;
    FamaClanPts[playerid] = 0;
    FamaOpiniao[playerid] = OPINIAO_DEFAULT;
    FamaAlcunha[playerid][0] = '\0';
    FamaLoaded[playerid] = false;
    return 1;
}

stock Fama_GetFile(playerid, out[], out_size)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof name);
    format(out, out_size, "SWRP/Fama/%s.ini", name);
    return 1;
}

stock Fama_ClampAll(playerid)
{
    if(FamaNinjaPts[playerid] < 0) FamaNinjaPts[playerid] = 0;
    if(FamaNinjaPts[playerid] > FAMA_MAX_NINJA) FamaNinjaPts[playerid] = FAMA_MAX_NINJA;

    if(FamaClanPts[playerid] < 0) FamaClanPts[playerid] = 0;
    if(FamaClanPts[playerid] > FAMA_MAX_CLAN) FamaClanPts[playerid] = FAMA_MAX_CLAN;

    if(FamaOpiniao[playerid] < 0) FamaOpiniao[playerid] = 0;
    if(FamaOpiniao[playerid] > OPINIAO_MAX) FamaOpiniao[playerid] = OPINIAO_MAX;

    return 1;
}

// 0=E,1=D,2=C,3=B,4=A,5=S,6=SS
stock Fama_RankFromPts(pts)
{
    if(pts >= 160) return 6; // SS (160..200)
    if(pts >= 140) return 5; // S  (140..159)
    if(pts >= 110) return 4; // A  (110..139)
    if(pts >= 80)  return 3; // B  (80..109)
    if(pts >= 50)  return 2; // C  (50..79)
    if(pts >= 30)  return 1; // D  (30..49)
    return 0;               // E  (0..29)
}

stock Fama_RecalcRank(playerid)
{
    // NinjaFamaRank[] existe no teu gamemode e é usado no nametag
    NinjaFamaRank[playerid] = Fama_RankFromPts(FamaNinjaPts[playerid]);
    return 1;
}

stock Fama_GetNotoriedadeStr(pts, out[], out_size)
{
    // Texto “universal” (não “quebra” RP do SA-MP)
    if(pts >= 200) return format(out, out_size, "Lenda do mundo ninja");
    if(pts >= 160) return format(out, out_size, "Presenca marcante onde passa");
    if(pts >= 140) return format(out, out_size, "Reconhecido mundialmente (alcunha)");
    if(pts >= 110) return format(out, out_size, "Famoso em todo o Pais");
    if(pts >= 80)  return format(out, out_size, "Reconhecido pela Vila inteira");
    if(pts >= 50)  return format(out, out_size, "Reconhecido pelos civis como ninja");
    if(pts >= 30)  return format(out, out_size, "Conhecido pelo Cla e divisao");
    return format(out, out_size, "Conhecido no proprio distrito");
}

stock Fama_GetClanTierStr(pts, out[], out_size)
{
    if(pts >= 40) return format(out, out_size, "Candidato a Lideranca");
    if(pts >= 30) return format(out, out_size, "Elite do Cla");
    if(pts >= 20) return format(out, out_size, "Promessa do Cla");
    if(pts >= 10) return format(out, out_size, "Conhecido do Cla");
    return format(out, out_size, "Iniciante no Cla");
}

stock Fama_GetOpiniaoStr(op, out[], out_size)
{
    if(op >= 90) return format(out, out_size, "Heroi do Povo (muito alto)");
    if(op >= 80) return format(out, out_size, "Heroi do Povo (alto)");
    if(op >= 70) return format(out, out_size, "Boa reputacao");
    if(op >= 60) return format(out, out_size, "Tende ao justo");

    if(op <= 10) return format(out, out_size, "Inimigo Publico (extremo)");
    if(op <= 20) return format(out, out_size, "Inimigo Publico (muito alto)");
    if(op <= 30) return format(out, out_size, "Ma reputacao");
    if(op <= 40) return format(out, out_size, "Tende ao egoista");

    return format(out, out_size, "Neutro");
}

stock Fama_RefreshNameTag(playerid)
{
    // teu nametag atualiza tudo aqui
    SistemaBandanaIDStatus(playerid);
    return 1;
}

stock Fama_Load(playerid)
{
    new file[128];
    Fama_GetFile(playerid, file, sizeof file);

    if(!DOF2_FileExists(file))
    {
        DOF2_CreateFile(file);
        DOF2_SetInt(file, "NinjaPts", 0);
        DOF2_SetInt(file, "ClanPts", 0);
        DOF2_SetInt(file, "Opiniao", OPINIAO_DEFAULT);
        DOF2_SetString(file, "Alcunha", "");
        DOF2_SaveFile();
    }

    FamaNinjaPts[playerid] = DOF2_GetInt(file, "NinjaPts");
    FamaClanPts[playerid]  = DOF2_GetInt(file, "ClanPts");
    FamaOpiniao[playerid]  = DOF2_GetInt(file, "Opiniao");

    format(FamaAlcunha[playerid], sizeof(FamaAlcunha[]), DOF2_GetString(file, "Alcunha"));

    Fama_ClampAll(playerid);
    Fama_RecalcRank(playerid);

    FamaLoaded[playerid] = true;
    return 1;
}

stock Fama_Save(playerid)
{
    if(!FamaLoaded[playerid]) return 1;

    new file[128];
    Fama_GetFile(playerid, file, sizeof file);

    if(!DOF2_FileExists(file)) DOF2_CreateFile(file);

    Fama_ClampAll(playerid);
    DOF2_SetInt(file, "NinjaPts", FamaNinjaPts[playerid]);
    DOF2_SetInt(file, "ClanPts",  FamaClanPts[playerid]);
    DOF2_SetInt(file, "Opiniao",  FamaOpiniao[playerid]);
    DOF2_SetString(file, "Alcunha", FamaAlcunha[playerid]);
    DOF2_SaveFile();
    return 1;
}

stock bool:Fama_HasPerm(playerid)
{
    // Usa o teu admin do GM (simples e direto)
    if(Info[playerid][pAdminZC] > 0) return true;
    return IsPlayerAdmin(playerid);
}

stock Fama_AddNinja(playerid, pts, const motivo[] = "")
{
    FamaNinjaPts[playerid] += pts;
    Fama_ClampAll(playerid);
    Fama_RecalcRank(playerid);
    Fama_RefreshNameTag(playerid);

    if(motivo[0])
    {
        new rk[4], msg[144];
        GetFamaRankStr(NinjaFamaRank[playerid], rk, sizeof rk); // teu stock do GM
        format(msg, sizeof msg, "{AB7C4E}(FAMA){FFFFFF} +%d fama ninja (%d/%d) Rank %s. Motivo: %s",
            pts, FamaNinjaPts[playerid], FAMA_MAX_NINJA, rk, motivo);
        SendClientMessage(playerid, -1, msg);
    }
    return 1;
}

stock Fama_AddClan(playerid, pts)
{
    FamaClanPts[playerid] += pts;
    Fama_ClampAll(playerid);
    return 1;
}

stock Fama_AddOpiniao(playerid, delta)
{
    FamaOpiniao[playerid] += delta;
    Fama_ClampAll(playerid);
    return 1;
}

// =======================
//  COMANDOS (STAFF)
// =======================
CMD:fama(playerid, params[])
{
    new id = playerid;
    if (params[0] != '\0')
    {
        if (sscanf(params, "d", id)) return SendClientMessage(playerid, -1, "{FFFFFF}Use: /fama ou /fama [id]");
        if (!IsPlayerConnected(id))  return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} ID inválido.");
    }

    new rk[4], msg[164];
    GetFamaRankStr(NinjaFamaRank[id], rk, sizeof rk);

    format(msg, sizeof msg, "{FFFFFF}Fama Ninja: {5ABAFF}%d/200{FFFFFF} | Rank: {5ABAFF}%s", FamaNinjaPts[id], rk);
    SendClientMessage(playerid, -1, msg);

    format(msg, sizeof msg, "{FFFFFF}Fama do Clã: {5ABAFF}%d/50{FFFFFF}", FamaClanPts[id]);
    SendClientMessage(playerid, -1, msg);

    format(msg, sizeof msg, "{FFFFFF}Opinião Popular: {5ABAFF}%d%%{FFFFFF} (50 = neutro)", FamaOpiniao[id]);
    SendClientMessage(playerid, -1, msg);

    format(msg, sizeof msg, "{FFFFFF}Alcunha: {5ABAFF}%s", (FamaAlcunha[id][0] ? FamaAlcunha[id] : "Nenhuma"));
    SendClientMessage(playerid, -1, msg);

    return 1;
}


CMD:setfama(playerid, params[])
{
    if(!Fama_HasPerm(playerid)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} Sem permissao.");

    new id, pts;
    if(sscanf(params, "dd", id, pts)) return SendClientMessage(playerid, -1, "{FFFFFF}Use: /setfama [id] [0-200]");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} ID invalido.");

    FamaNinjaPts[id] = pts;
    Fama_ClampAll(id);
    Fama_RecalcRank(id);
    Fama_RefreshNameTag(id);

    SendClientMessage(playerid, -1, "{AB7C4E}(OK){FFFFFF} Fama ninja setada.");
    return 1;
}

CMD:addfama(playerid, params[])
{
    if(!Fama_HasPerm(playerid)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} Sem permissao.");

    new id, pts;
    if(sscanf(params, "dd", id, pts)) return SendClientMessage(playerid, -1, "{FFFFFF}Use: /addfama [id] [+/-pts]");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} ID invalido.");

    Fama_AddNinja(id, pts, "Avaliacao do narrador");
    SendClientMessage(playerid, -1, "{AB7C4E}(OK){FFFFFF} Fama ninja ajustada.");
    return 1;
}

CMD:addfamacla(playerid, params[])
{
    if(!Fama_HasPerm(playerid)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} Sem permissao.");

    new id, pts;
    if(sscanf(params, "dd", id, pts)) return SendClientMessage(playerid, -1, "{FFFFFF}Use: /addfamacla [id] [+/-pts]");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} ID invalido.");

    Fama_AddClan(id, pts);
    SendClientMessage(playerid, -1, "{AB7C4E}(OK){FFFFFF} Fama do cla ajustada.");
    return 1;
}

CMD:addopiniao(playerid, params[])
{
    if(!Fama_HasPerm(playerid)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} Sem permissao.");

    new id, delta;
    if(sscanf(params, "dd", id, delta)) return SendClientMessage(playerid, -1, "{FFFFFF}Use: /addopiniao [id] [+/-valor]");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} ID invalido.");

    Fama_AddOpiniao(id, delta);
    SendClientMessage(playerid, -1, "{AB7C4E}(OK){FFFFFF} Opiniao popular ajustada.");
    return 1;
}

CMD:setalcunha(playerid, params[])
{
    if(!Fama_HasPerm(playerid)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} Sem permissao.");

    new id;
    new alc[32];
    if(sscanf(params, "ds[32]", id, alc)) return SendClientMessage(playerid, -1, "{FFFFFF}Use: /setalcunha [id] [texto]");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{FF030F}(ERRO){FFFFFF} ID invalido.");

    format(FamaAlcunha[id], sizeof(FamaAlcunha[]), "%s", alc);
    SendClientMessage(playerid, -1, "{AB7C4E}(OK){FFFFFF} Alcunha setada.");
    return 1;
}
