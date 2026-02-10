#if defined _SHRP_ORGS_INCLUDED
    #endinput
#endif
#define _SHRP_ORGS_INCLUDED

// =============================================================================
//  SHRP - Modulo de Organizacoes (Orgs) e Cargos
//  Extraido do gamemode original para facilitar manutencao e updates.
//  Arquivo: Includes/Faccoes/shrp_orgs.pwn (ANSI)
// =============================================================================

#define             PASTA_ORGS                    "CONTAS/ORGS/%s.ini"
#define MAX_CARGOS          100
#define MAX_ORGS            10
#define ACADEMIA            0
#define AKATSUKI            1
#define ANBUKONOHA          2
#define ANBUKIRI            3
#define DELEGACIAKONOHA     4
#define DELEGACIAKIRI       5
#define HOSPITALKONOHA      6
#define HOSPITALKIRI        7
#define OTOGAKURE           8
#define TAKA                9
#define DIALOG_AKATSUKIO    32117
#define DIALOG_AKATSUKIC    32118
#define DIALOG_AKATSUKIM    32119
#define DIALOG_AKATSUKIE    32120
#define DIALOG_AKATSKIAC    32121
#define DIALOG_ANBUKONOHAO  32122
#define DIALOG_ANBUKONOHAC  32123
#define DIALOG_ANBUKONOHAM  32124
#define DIALOG_ANBUKONOHAE  32125
#define DIALOG_ANBUKIRIO    32126
#define DIALOG_ANBUKIRIC    32127
#define DIALOG_ANBUKIRIM    32128
#define DIALOG_ANBUKIRIE    32129
#define DIALOG_DPKONOHAO    32130
#define DIALOG_DPKONOHAC    32131
#define DIALOG_DPKONOHAM    32132
#define DIALOG_DPKONOHAE    32133
#define DIALOG_DPKIRIO      32134
#define DIALOG_DPKIRIC      32135
#define DIALOG_DPKIRIM      32136
#define DIALOG_DPKIRIE      32137
#define DIALOG_HPKONOHAO    32138
#define DIALOG_HPKONOHAC    32139
#define DIALOG_HPKONOHAM    32140
#define DIALOG_HPKONOHAE    32141
#define DIALOG_HPKIRIO      32142
#define DIALOG_HPKIRIC      32143
#define DIALOG_HPKIRIM      32144
#define DIALOG_HPKIRIE      32145
#define DIALOG_OTOGAKUREO   32146
#define DIALOG_OTOGAKUREC   32147
#define DIALOG_OTOGAKUREM   32148
#define DIALOG_OTOGAKUREE   32149
#define DIALOG_TAKAO        32150
#define DIALOG_TAKAC        32151
#define DIALOG_TAKAM        32152
#define DIALOG_TAKAE        32153
//== Dialog Para aceitar Convites ==//
#define DIALOG_ANBUKONOHAAC    32154
#define DIALOG_ANBUKIRIAC      32155
#define DIALOG_DPKONOHAAC      32156
#define DIALOG_DPKIRIAC        32157
#define DIALOG_HPKONOHAAC      32158
#define DIALOG_HPKIRIAC        32159
#define DIALOG_OTOGAKUREAC     32160
#define DIALOG_TAKAAC          32161
//== Dialog de Horas ==//
#define DIALOG_DPKONOHAH    32162
#define DIALOG_DPKIRIH      32163
//=== Sistema de Org Variaveis ===//
new PontoBatidoDP[MAX_PLAYERS];
new PontoBatidoHP[MAX_PLAYERS];
new EditandoPontoHP[MAX_PLAYERS];
new SkinPontoDP[MAX_PLAYERS];
new PortaDPKonoha[MAX_PLAYERS];
new PortaHPKonohaMCH[MAX_PLAYERS];
new PortaHPKonohaNECRO[MAX_PLAYERS];
new PortaHPIwagakureBaixo[MAX_PLAYERS];
new PortaDPKiri[MAX_PLAYERS];
new PortaHPKiriBaixo[MAX_PLAYERS];
new PortaHPKiriMCH[MAX_PLAYERS];
new PortaHPKiriNECRO[MAX_PLAYERS];

// === Kumogakure
//DP
new PortaDPKumo[MAX_PLAYERS];
//=== Sistema das Orgs ===//
enum Orgs
{
    iCargo[MAX_CARGOS]
}
new OrgInfo[MAX_ORGS][Orgs];
enum _cargo
{
    oorgid,
    cargonome[30],
    quantidade
};
new InfoCargo[][_cargo] =
{
    //Academia
    {ACADEMIA, "Diretor", 1}, // ID CARGO 1
    {ACADEMIA, "Assistente", 2}, // ID CARGO 2
    {ACADEMIA, "SenseiAulas", 3}, // ID CARGO 3
    {ACADEMIA, "SenseiTimes", 9}, // ID CARGO 4
    {ACADEMIA, "Membros", 27}, // ID CARGO 5
    //Akatsuki
    {AKATSUKI, "Lider", 1},
    {AKATSUKI, "Membros", 9},
    //AnbuKonoha
    {ANBUKONOHA, "Lider", 1},
    {ANBUKONOHA, "Membros", 9},
    //AnbuKiri
    {ANBUKIRI, "Lider", 1},
    {ANBUKIRI, "Membros", 9},
    //DP Konoha
    {DELEGACIAKONOHA, "General", 1},
    {DELEGACIAKONOHA, "Membros", 9},
    //DP Kiri
    {DELEGACIAKIRI, "General", 1},
    {DELEGACIAKIRI, "Membros", 9},
    //HP Konoha
    {HOSPITALKONOHA, "ChefeMedico", 1},
    {HOSPITALKONOHA, "Membros", 9},
    //HP Kiri
    {HOSPITALKIRI, "ChefeMedico", 1},
    {HOSPITALKIRI, "Membros", 9},
    //Otogakure
    {OTOGAKURE, "Lider", 1},
    {OTOGAKURE, "Membros", 9},
    //Taka
    {TAKA, "Lider", 1},
    {TAKA, "Membros", 9}
};

//Sistema de Orgs Inicio
stock LoadOrgs(orgid)
{
    new string[54], file[128];
    format(file, sizeof(file), PASTA_ORGS, GetNameOrgs(orgid));
    if(!DOF2_FileExists(file)) {
        DOF2_CreateFile(file);
        for(new i = 0; i < sizeof(InfoCargo); i++) {
            if(InfoCargo[i][oorgid] == orgid) {
                if(InfoCargo[i][quantidade] == 1) {
                    DOF2_SetString(file, InfoCargo[i][cargonome], "Ninguem");
                    DOF2_SaveFile();
                } else {
                    for(new a = 0; a < InfoCargo[i][quantidade]; a++) {
                        format(string, sizeof(string), "%s%d", InfoCargo[i][cargonome], a);
                        DOF2_SetString(file, string, "Ninguem");
                        DOF2_SaveFile();
                    }
                }
            }
        }
    }
    return 1;
}
stock GetNameOrgs(orgid)
{
    new string[64];
    switch(orgid)
    {
        case 0: string = "Academia";
        case 1: string = "Akatsuki";
        case 2: string = "AnbuKonoha";
        case 3: string = "AnbuKiri";
        case 4: string = "DelegaciaKonoha";
        case 5: string = "DelegaciaKiri";
        case 6: string = "HospitalKonoha";
        case 7: string = "HospitalKiri";
        case 8: string = "Otogakure";
        case 9: string = "Taka";
        case 10: string = "HospitalKumo";
    }
    return string;
}
stock GetCargoName(cargoid)
{
    new string[64];
    switch(cargoid)
    {
        case 0: string = "Diretor";
        case 1: string = "AssistenteAcademia";
        case 2: string = "SenseiAulas";
        case 3: string = "SenseiTimes";
        case 4: string = "MembrosAcademia";
        case 5: string = "AkatsukiLider";
        case 6: string = "AkatsukiMembros";
        case 7: string = "LiderAnbuKonoha";
        case 8: string = "MembrosAnbuKonoha";
        case 9: string = "LiderAnbuKiri";
        case 10: string = "MembrosAnbuKiri";
        case 11: string = "GeneralKonoha";
        case 12: string = "MembrosPMKonoha";
        case 13: string = "GeneralKiri";
        case 14: string = "MembrosPMKiri";
        case 15: string = "ChefeMedicoKonoha";
        case 16: string = "MembrosHPKonoha";
        case 17: string = "ChefeMedicoKiri";
        case 18: string = "MembrosHPKiri";
        case 19: string = "LiderOtogakure";
        case 20: string = "MembrosOtogakure";
        case 21: string = "LiderTaka";
        case 22: string = "MembrosTaka";
        case 23: string = "ChefeMedicoKumo";
        case 24: string = "MembrosHPKumo";
        case 25: string = "GeneralKumo";
        case 26: string = "MembrosPMKumo";
    }
    return string;
}
stock GiveOrgCargo(playerid, orgid, cargoid)
{
    new idcargo;
    for(new i = 0; i < sizeof(InfoCargo); i++)
    {
        if(InfoCargo[i][oorgid] == orgid)
        {
            Info[playerid][pOrgs] = orgid;
            if(Info[playerid][pCargos] == cargoid && GetCargoName(i))
            {
                Info[playerid][pCargos] = cargoid;
            }
        }
    }
    return 1;
}
CMD:darlider(playerid, params[])
{
    new giveplayerid, idorg, idcargo;
    new str[200];
    new pName[32], aName[32];
    if(Info[playerid][pAdminZC] <= 0)return SendClientMessage(playerid, 0xFF0000AA, "[ERRO]: Este comando n?o existe!");
    if(sscanf(params, "ddd", giveplayerid, idorg, idcargo)) return SendClientMessage(playerid, 0xFF230AFF, "[ERRO] Use /darlider [ID] [IDORG] [IDCARGO].");
    if(!IsPlayerConnected(giveplayerid)) return SendClientMessage(playerid, 0xFF230AFF, "[ERRO] O ID digitado n?o est? no servidor.");
    if(Info[playerid][pAdminZC] == 1 || Info[playerid][pAdminZC] == 2)
    {
        Info[giveplayerid][pOrgs] = idorg;
        Info[giveplayerid][pCargos] = idcargo;
        GetPlayerName(giveplayerid, aName, sizeof(aName));
        format(str, sizeof(str), "{E9FE23}[AVISO]{FFFFFF}: Voc? deu a org {E9FE23}%s{FFFFFF} e o cargo {E9FE23}%s{FFFFFF} para o jogador {E9FE23}%s{FFFFFF}.", GetNameOrgs(idorg), GetCargoName(idcargo), aName);
        SendClientMessage(playerid, -1, str);
    }
    return 1;
}
CMD:darcargoo(playerid, params[])
{
    new giveplayerid, idcargo;
    new str[200];
    new aName[32];
    if(Info[playerid][pAdminZC] <= 0)return SendClientMessage(playerid, 0xFF0000AA, "[ERRO]: Este comando n?o existe!");
    if(sscanf(params, "dd", giveplayerid, idcargo)) return SendClientMessage(playerid, 0xFF230AFF, "[ERRO] Use /darcargoo [ID] [IDCARGO].");
    if(!IsPlayerConnected(giveplayerid)) return SendClientMessage(playerid, 0xFF230AFF, "[ERRO] O ID digitado n?o est? no servidor.");
    if(Info[playerid][pAdminZC] == 1 || Info[playerid][pAdminZC] == 2)
    {
        GetPlayerName(giveplayerid, aName, sizeof(aName));
        Info[giveplayerid][pCargos] = idcargo;
        format(str, sizeof(str), "{E9FE23}[AVISO]{FFFFFF}: Voc? deu o cargo {E9FE23}%s{FFFFFF} ao jogador {E9FE23}%s{FFFFFF}.", GetCargoName(idcargo), aName);
        SendClientMessage(playerid, -1, str);
    }
    return 1;
}
CMD:removerorg(playerid, params[])
{
    new giveplayerid;
    new str[200];
    new aName[32];
    if(Info[playerid][pAdminZC] <= 0)return SendClientMessage(playerid, 0xFF0000AA, "[ERRO]: Este comando n?o existe!");
    if(sscanf(params, "d", giveplayerid)) return SendClientMessage(playerid, 0xFF230AFF, "[ERRO] Use /removerorg [ID].");
    if(!IsPlayerConnected(giveplayerid)) return SendClientMessage(playerid, 0xFF230AFF, "[ERRO] O ID digitado n?o est? no servidor.");
    if(Info[playerid][pAdminZC] == 1 || Info[playerid][pAdminZC] == 2)
    {
        GetPlayerName(giveplayerid, aName, sizeof(aName));
        Info[giveplayerid][pOrgs] = 999;
        Info[giveplayerid][pCargos] = 999;
        format(str, sizeof(str), "{E9FE23}[AVISO]{FFFFFF}: Voc? retirou o jogador {E9FE23}%s{FFFFFF} de todos os cargos/org's que ele estava.", aName);
        SendClientMessage(playerid, -1, str);
    }
    return 1;
}
//Menu Sistema de Org Lider
CMD:menuakat(playerid, params[]) // Menu Akatsuki
{
    if(Info[playerid][pOrgs] == 1 && Info[playerid][pCargos] == 5)
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_AKATSUKIO, DIALOG_STYLE_LIST, "{E9FE23}Menu Akatsuki", "Convidar\n\
                                                                                                  Membros\n\
                                                                                                  Expulsar", "OK", "Fechar");
    } else return 0;
    return 1;
}
CMD:menuanbu(playerid, params[])
{
    if(Info[playerid][pOrgs] == 999 && Info[playerid][pCargos] == 999) return 0;
    if(Info[playerid][pOrgs] == 3 && Info[playerid][pCargos] == 9)
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_ANBUKIRIO, DIALOG_STYLE_LIST, "{E9FE23}Menu Anbu Kiri", "Contratar\n\
                                                                                                   Membros\n\
                                                                                                   Expulsar", "OK", "Fechar");
    }
    else if(Info[playerid][pOrgs] == 2 && Info[playerid][pCargos] == 7)
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_ANBUKONOHAO, DIALOG_STYLE_LIST, "{E9FE23}Menu Anbu Konoha", "Convidar\n\
                                                                                                       Membros\n\
                                                                                                       Expulsar", "OK", "Fechar");
    }
    return 1;
}
CMD:menudelegacia(playerid, params[])
{
    if(Info[playerid][pOrgs] == 999 && Info[playerid][pCargos] == 999) return 0;
    if(Info[playerid][pOrgs] == 5 && Info[playerid][pCargos] == 13) // Kirigakure DP
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_DELEGACIAKIRIGAKURE, DIALOG_STYLE_LIST, "{E9FE23}Menu Delegacia Kiri", "Contratar\n\
                                                                                                      Membros\n\
                                                                                                      Horas\n\
                                                                                                      Expulsar\n\
                                                                                                      Promover", "OK", "Fechar");
    }
    else if(Info[playerid][pOrgs] == 4 && Info[playerid][pCargos] == 11) // Konoha DP
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_DELEGACIAIWAGAKURE, DIALOG_STYLE_LIST, "{E9FE23}Menu Delegacia Iwagakure", "Contratar\n\
                                                                                                          Membros\n\
                                                                                                          Horas\n\
                                                                                                          Expulsar\n\
                                                                                                          Promover", "OK", "Fechar");
    }
    else if(Info[playerid][pOrgs] == 25 && Info[playerid][pCargos] == 20) // Kumogakure DP
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_DELEGACIAKUMOGAKURE, DIALOG_STYLE_LIST, "{E9FE23}Menu Delegacia Kumogakure", "Contratar\n\
                                                                                                          Membros\n\
                                                                                                          Horas\n\
                                                                                                          Expulsar\n\
                                                                                                          Promover", "OK", "Fechar");
    }
    return 1;
}
CMD:menuhospital(playerid, params[])
{
    if(Info[playerid][pOrgs] == 999 && Info[playerid][pCargos] == 999) return 0;
    if(Info[playerid][pOrgs] == 6 && Info[playerid][pCargos] == 15) // Konoha HP
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_HOSPITALIWAGAKURE, DIALOG_STYLE_LIST, "{E9FE23}Menu Hospital Iwagakure", "Contratar\n\
                                                                                                            Membros\n\
                                                                                                            Horas\n\
                                                                                                            Expulsar\n\
                                                                                                            Promover", "OK", "Fechar");
    }
    else if(Info[playerid][pOrgs] == 7 && Info[playerid][pCargos] == 17) // Kiri HP
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_HOSPITAKIRIGAKURE, DIALOG_STYLE_LIST, "{E9FE23}Menu Hospital Kiri", "Contratar\n\
                                                                                                               Membros\n\
                                                                                                               Horas\n\
                                                                                                               Expulsar\n\
                                                                                                               Promover", "OK", "Fechar");
    }
    else if(Info[playerid][pOrgs] == 23 && Info[playerid][pCargos] == 18) // Kumo Hp
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_HOSPITAKUMOGAKURE, DIALOG_STYLE_LIST, "{E9FE23}Menu Hospital Kumo", "Contratar\n\
                                                                                                               Membros\n\
                                                                                                               Horas\n\
                                                                                                               Expulsar\n\
                                                                                                               Promover", "OK", "Fechar");
    }
    return 1;
}
CMD:menuotoga(playerid, params[])
{
    if(Info[playerid][pOrgs] == 8 && Info[playerid][pCargos] == 19)
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_OTOGAKUREO, DIALOG_STYLE_LIST, "{E9FE23}Menu Otogakure", "Convidar\n\
                                                                                                    Membros\n\
                                                                                                    Expulsar", "OK", "Fechar");
    } else return 0;
    return 1;
}
CMD:menutaka(playerid, params[])
{
if(Info[playerid][pOrgs] == 8 && Info[playerid][pCargos] == 19)
    {
        Audio_Play(playerid, 58);
        ShowPlayerDialog(playerid, DIALOG_TAKAO, DIALOG_STYLE_LIST, "{E9FE23}Menu Taka", "Convidar\n\
                                                                                          Membros\n\
                                                                                          Expulsar", "OK", "Fechar");
    } else return 0;
    return 1;
}
//Final Sistema de Org Lider
//Bater Pontos ORG
CMD:darpatentedp(playerid, params[])
{
    new string[64];
    new patente;
    new giveplayerid;
    new aName[32];
    if(sscanf(params, "dd", giveplayerid, patente)) return SendClientMessage(playerid, 0xFF230AFF, "[ERRO] Use /dardppatente [ID] [ID PATENTE].");
    if(Info[playerid][pAdminZC] == 1 || Info[playerid][pAdminZC] == 2 || Info[playerid][pAdminZC] == 3)
    {
        GetPlayerName(giveplayerid, aName, sizeof(aName));
        Info[giveplayerid][pDPPatente] = patente;
        format(string, sizeof(string), "[AVISO] Voc? deu a patente %d ao jogador %s", patente, PlayerNameDados(giveplayerid));
        SendClientMessage(playerid, COLOR_WHITE, string);
    }
    return 1;
}
TeclaEntrarDP(playerid, newkeys, oldkeys)
{
    if(BtnDireito[playerid] == 1) return 0;
    if(IsPlayerInRangeOfPoint(playerid, 0.5, -1399.6886, 1556.9932, 7.8914) || IsPlayerInRangeOfPoint(playerid, 0.5, -1400.2764, 1557.4340, 7.8914) || IsPlayerInRangeOfPoint(playerid, 0.5, -1400.7546, 1564.5370, 7.8914) || IsPlayerInRangeOfPoint(playerid, 0.5, -1401.2924, 1564.9861, 7.8914) ||
       IsPlayerInRangeOfPoint(playerid, 0.5, -1411.6118, 1559.1954, 7.8914) || IsPlayerInRangeOfPoint(playerid, 0.5, -1404.7063, 1558.8009, 24.9930) || IsPlayerInRangeOfPoint(playerid, 0.5, 2313.4319, -2264.1235, 30.6717) || IsPlayerInRangeOfPoint(playerid, 0.5, 2312.6467,-2264.1184,30.6717) ||
       IsPlayerInRangeOfPoint(playerid, 0.5, 2308.1458, -2258.7026, 30.6717) || IsPlayerInRangeOfPoint(playerid, 0.5, 2307.3972, -2258.6558, 30.6717) || IsPlayerInRangeOfPoint(playerid, 0.5, 2302.5212, -2269.5071, 30.6717) || IsPlayerInRangeOfPoint(playerid, 0.5, 2308.3337, -2265.6038, 47.7732) ||
       IsPlayerInRangeOfPoint(playerid, 0.5, 1884.5414, 1337.0575, 38.9390) || IsPlayerInRangeOfPoint(playerid, 0.5, 1884.5391, 1337.8057, 38.9390) || IsPlayerInRangeOfPoint(playerid, 0.5, 1889.8604, 1342.5381, 38.9390) || IsPlayerInRangeOfPoint(playerid, 0.5, 1889.9094, 1343.2694, 38.9390) ||
       IsPlayerInRangeOfPoint(playerid, 0.5, 1878.9401, 1347.8588, 38.9390) || IsPlayerInRangeOfPoint(playerid, 0.5, 1877.4010, 1342.3336, 62.4008))
    {
        if(PRESSED(KEY_CTRL_BACK)) {EntradaDP(playerid);}
    }
    return 1;
}

