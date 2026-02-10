#if defined _SHRP_GUERRA_INCLUDED
    #endinput
#endif
#define _SHRP_GUERRA_INCLUDED

// =============================================================================
//  SHRP - Sistema de Guerra entre Vilas (Kages)
//  Extraido do gamemode original e corrigido (guards / comandos).
//  Arquivo: Includes/Faccoes/shrp_guerra.pwn (ANSI)
// =============================================================================

// ============================================================================
//  SHRP - SISTEMA DE GUERRA ENTRE VILAS (KAGES)
//  - Declarar/Encerrar guerra via /guerra (somente Kage)
//  - Consultar via IsVillagesAtWar(v1, v2)
//  - Persistencia: scriptfiles/shrp_wars.cfg
// ============================================================================

#define GUERRA_FILE             "shrp_wars.cfg"
#define GUERRA_MAX_VILAS        (6)   // 0..5 (0 = none)
#define GUERRA_DIALOG_LIST      (35010)
#define GUERRA_DIALOG_ACTION    (35011)

static const gGuerraVilaName[GUERRA_MAX_VILAS][16] =
{
    "SEM",
    "KONOHA",
    "SUNA",
    "KIRIGAKURE",
    "IWAGAKURE",
    "KUMOGAKURE"
};

new gGuerraWar[GUERRA_MAX_VILAS][GUERRA_MAX_VILAS]; // 0/1 simetrico
new gGuerraDlgMap[MAX_PLAYERS][GUERRA_MAX_VILAS];    // listitem -> vilaId
new gGuerraSelVila[MAX_PLAYERS];

// -------------------------
// Helpers
// -------------------------
stock Guerra_IsValidVila(v)
{
    return (v > 0 && v < GUERRA_MAX_VILAS);
}

stock Guerra_ClearAll()
{
    for(new a=0; a<GUERRA_MAX_VILAS; a++)
    {
        for(new b=0; b<GUERRA_MAX_VILAS; b++)
            gGuerraWar[a][b] = 0;
    }
    return 1;
}

stock Guerra_SetWar(v1, v2, bool:on)
{
    if(!Guerra_IsValidVila(v1) || !Guerra_IsValidVila(v2) || v1 == v2) return 0;
    gGuerraWar[v1][v2] = on ? 1 : 0;
    gGuerraWar[v2][v1] = on ? 1 : 0;
    return 1;
}

forward IsVillagesAtWar(v1, v2);
public IsVillagesAtWar(v1, v2)
{
    if(!Guerra_IsValidVila(v1) || !Guerra_IsValidVila(v2) || v1 == v2) return 0;
    return gGuerraWar[v1][v2] != 0;
}

// -------------------------
// Persistencia
// -------------------------
stock Guerra_Save()
{
    new File:f = fopen(GUERRA_FILE, io_write);
    if(!f) return 0;

    fwrite(f, "; SHRP wars - formato: v1 v2\n");

    for(new v1=1; v1<GUERRA_MAX_VILAS; v1++)
    {
        for(new v2=v1+1; v2<GUERRA_MAX_VILAS; v2++)
        {
            if(gGuerraWar[v1][v2])
            {
                new line[32];
                format(line, sizeof(line), "%d %d\n", v1, v2);
                fwrite(f, line);
            }
        }
    }
    fclose(f);
    return 1;
}

stock bool:Guerra_ParseTwoInts(const line[], &a, &b)
{
    a = 0; b = 0;
    new len = strlen(line);
    if(len < 3) return false;

    // pula comentarios
    if(line[0] == ';' || line[0] == '#') return false;

    // pega primeiro numero
    new i = 0;
    while(i < len && (line[i] == ' ' || line[i] == '\t' || line[i] == '\r' || line[i] == '\n')) i++;
    if(i >= len) return false;

    new start = i;
    while(i < len && line[i] >= '0' && line[i] <= '9') i++;
    if(i == start) return false;

    new tmp[16];
    new n = 0;
    for(new k=start; k<i && n < sizeof(tmp)-1; k++) tmp[n++] = line[k];
    tmp[n] = '\0';
    a = strval(tmp);

    while(i < len && (line[i] == ' ' || line[i] == '\t')) i++;
    if(i >= len) return false;

    start = i;
    while(i < len && line[i] >= '0' && line[i] <= '9') i++;
    if(i == start) return false;

    n = 0;
    for(new k=start; k<i && n < sizeof(tmp)-1; k++) tmp[n++] = line[k];
    tmp[n] = '\0';
    b = strval(tmp);

    return true;
}

stock Guerra_Load()
{
    Guerra_ClearAll();

    new File:f = fopen(GUERRA_FILE, io_read);
    if(!f) return 0; // sem arquivo ainda, ok

    new line[64];
    while(fread(f, line))
    {
        new a, b;
        if(!Guerra_ParseTwoInts(line, a, b)) continue;
        Guerra_SetWar(a, b, true);
    }
    fclose(f);
    return 1;
}

// -------------------------
// Permissao: Kage -> Vila
// OBS: baseado no que voce mandou:
// case 1: Tsuchikage  (Iwa = 4)
// case 2: Mizukage    (Kiri = 3)
// case 3: Raikage     (Kumo = 5)
// -------------------------
stock Guerra_GetVilaFromKage(playerid)
{
    // Se seu enum usa outro nome, ajuste apenas esse switch.
    switch(Info[playerid][pKage])
    {
        case 1: return 4; // Tsuchikage -> Iwa
        case 2: return 3; // Mizukage   -> Kiri
        case 3: return 5; // Raikage    -> Kumo
    }
    return 0;
}

stock Guerra_IsKage(playerid)
{
    return (Guerra_GetVilaFromKage(playerid) != 0);
}

// -------------------------
// UI: /guerra e /guerras
// -------------------------
stock Guerra_OpenMenu(playerid)
{
    new myVila = Guerra_GetVilaFromKage(playerid);
    if(!Guerra_IsValidVila(myVila))
        return SendClientMessage(playerid, -1, "{FF4040}Apenas Kages podem declarar/encerrar guerra."), 1;

    new list[512];
    list[0] = '\0';

    strcat(list, "Vila\tStatus\n");

    for(new i=0; i<GUERRA_MAX_VILAS; i++) gGuerraDlgMap[playerid][i] = 0;

    new li = 0;
    for(new v=1; v<GUERRA_MAX_VILAS; v++)
    {
        if(v == myVila) continue;

        gGuerraDlgMap[playerid][li] = v;

        new line[96];
		new status[32];

		if(IsVillagesAtWar(myVila, v))
		    format(status, sizeof status, "{FF4040}EM GUERRA{FFFFFF}");
		else
		    format(status, sizeof status, "{40FF40}PAZ{FFFFFF}");

		format(line, sizeof line, "%s\t%s\n", gGuerraVilaName[v], status);


        strcat(list, line);
        li++;
    }

    ShowPlayerDialog(playerid, GUERRA_DIALOG_LIST, DIALOG_STYLE_TABLIST_HEADERS,
        "Guerra entre Vilas", list, "Selecionar", "Fechar");
    return 1;
}


stock Guerra_OpenAction(playerid, vilaTarget)
{
    new myVila = Guerra_GetVilaFromKage(playerid);
    if(!Guerra_IsValidVila(myVila) || !Guerra_IsValidVila(vilaTarget)) return 0;

    gGuerraSelVila[playerid] = vilaTarget;

    new list[128];
    if(IsVillagesAtWar(myVila, vilaTarget))
        format(list, sizeof(list), "Encerrar guerra com %s", gGuerraVilaName[vilaTarget]);
    else
        format(list, sizeof(list), "Declarar guerra a %s", gGuerraVilaName[vilaTarget]);

    ShowPlayerDialog(playerid, GUERRA_DIALOG_ACTION, DIALOG_STYLE_LIST, "Confirmar", list, "Confirmar", "Cancelar");
    return 1;
}

stock Guerra_AnnounceChange(myVila, targetVila, bool:nowWar)
{
    new msg[144];
    if(nowWar)
        format(msg, sizeof(msg), "{FF4040}[GUERRA]{FFFFFF} %s declarou guerra a %s!", gGuerraVilaName[myVila], gGuerraVilaName[targetVila]);
    else
        format(msg, sizeof(msg), "{40FF40}[PAZ]{FFFFFF} %s encerrou a guerra com %s.", gGuerraVilaName[myVila], gGuerraVilaName[targetVila]);

    SendClientMessageToAll(-1, msg);
    return 1;
}

stock Guerra_OnDialog(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == GUERRA_DIALOG_LIST)
    {
        if(!response) return 1;

        new vilaTarget = gGuerraDlgMap[playerid][listitem];
        if(!Guerra_IsValidVila(vilaTarget)) return 1;

        return Guerra_OpenAction(playerid, vilaTarget);
    }

    if(dialogid == GUERRA_DIALOG_ACTION)
    {
        if(!response) return 1;

        new myVila = Guerra_GetVilaFromKage(playerid);
        new targetVila = gGuerraSelVila[playerid];

        if(!Guerra_IsValidVila(myVila) || !Guerra_IsValidVila(targetVila)) return 1;

        new bool:wasWar = (IsVillagesAtWar(myVila, targetVila) != 0);
        new bool:nowWar = !wasWar;

        Guerra_SetWar(myVila, targetVila, nowWar);
        Guerra_Save();
        Guerra_AnnounceChange(myVila, targetVila, nowWar);

        return 1;
    }
    return 0;
}

#if defined CMD
CMD:guerra(playerid, params[]) { return Guerra_OpenMenu(playerid); }
CMD:guerras(playerid, params[]) { return Guerra_ListActive(playerid); }
#elseif defined YCMD
YCMD:guerra(playerid, params[], help) { return Guerra_OpenMenu(playerid); }
YCMD:guerras(playerid, params[], help) { return Guerra_ListActive(playerid); }
#endif

stock Guerra_ListActive(playerid)
{
    new msg[256];
    new any = 0;
    SendClientMessage(playerid, -1, "{FFFF00}Guerras ativas:{FFFFFF}");
    for(new v1=1; v1<GUERRA_MAX_VILAS; v1++)
    {
        for(new v2=v1+1; v2<GUERRA_MAX_VILAS; v2++)
        {
            if(gGuerraWar[v1][v2])
            {
                format(msg, sizeof(msg), " - %s x %s", gGuerraVilaName[v1], gGuerraVilaName[v2]);
                SendClientMessage(playerid, -1, msg);
                any = 1;
            }
        }
    }
    if(!any) SendClientMessage(playerid, -1, "Nenhuma guerra ativa no momento.");
    return 1;
}

