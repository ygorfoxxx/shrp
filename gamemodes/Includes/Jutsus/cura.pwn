#if defined _IRYOU_MOD_PWN
    #endinput
#endif
#define _IRYOU_MOD_PWN

#include <a_samp>
#include <zcmd>

// ==========================================================
// FALLBACKS
// ==========================================================
#if !defined COLOR_WHITE
    #define COLOR_WHITE 0xFFFFFFFF
#endif

#if !defined SendClientMessageEx
    #define SendClientMessageEx(%0,%1,%2) SendClientMessage(%0,%1,%2)
#endif

#if !defined NONE
    #define NONE 0
#endif
#if !defined PLAYER
    #define PLAYER 1
#endif

// ==========================================================
// CONFIG
// ==========================================================
#define IRYOU_RANGE             (3.5)

#define IRYOU_INPUT_MS          (50)       // mais rápido pra pegar "tap" no N
#define IRYOU_TICK_MS           (2000)     // cura a cada 2s
#define IRYOU_COOLDOWN_SEC      (6)

#define IRYOU_HEAL_PCT          (0.05)     // 5% por tick

#define IRYOU_LEVE_REQ          (500)
#define IRYOU_MEDIA_REQ         (2000)
#define IRYOU_PESADA_REQ        (4000)

#define IRYOU_LEVE_CUSTO        (300.0)
#define IRYOU_MEDIA_CUSTO       (600.0)
#define IRYOU_PESADA_CUSTO      (1000.0)

#define IRYOU_EFFECT_SLOT       (9)

// Se quiser que AO PERDER O ALVO (range/VW/int) pare tudo, deixe 1.
// Se quiser que só pare por N/dano/vida cheia, coloque 0.
#define IRYOU_STOP_ON_LOSE_TARGET   (1)

// ==========================================================
// MENU
// ==========================================================
#define DIALOG_IRYOU_TARGET     (9150)
#define IRYOU_MENU_MAX          (15)

// ==========================================================
// STATE
// ==========================================================
new bool:Iryou_Ativo[MAX_PLAYERS];
new bool:Iryou_Selecting[MAX_PLAYERS];

new Iryou_Target[MAX_PLAYERS];
new Iryou_Level[MAX_PLAYERS];
new Float:Iryou_Custo[MAX_PLAYERS];

new Iryou_TimerInput[MAX_PLAYERS];
new Iryou_TimerHeal[MAX_PLAYERS];
new Iryou_NextUse[MAX_PLAYERS];

new Float:Iryou_LastHP[MAX_PLAYERS];
new Iryou_LastKeys[MAX_PLAYERS];

new Iryou_MenuTargets[MAX_PLAYERS][IRYOU_MENU_MAX];
new Iryou_MenuCount[MAX_PLAYERS];

// Alias pra não quebrar chamadas antigas:
stock Jutsu_Iryou_Exec(playerid)
{
    return Iryou_Use(playerid);
}


// ==========================================================
// HELPERS BÁSICOS
// ==========================================================
stock bool:Iryou_IsValidPlayer(playerid)
{
    return (playerid >= 0 && playerid < MAX_PLAYERS && IsPlayerConnected(playerid));
}

stock bool:Iryou_SameWorldInt(playerid, targetid)
{
    if(GetPlayerVirtualWorld(playerid) != GetPlayerVirtualWorld(targetid)) return false;
    if(GetPlayerInterior(playerid) != GetPlayerInterior(targetid)) return false;
    return true;
}

stock Float:Iryou_Dist(playerid, targetid)
{
    new Float:px, Float:py, Float:pz;
    new Float:tx, Float:ty, Float:tz;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerPos(targetid, tx, ty, tz);
    return floatsqroot((px-tx)*(px-tx) + (py-ty)*(py-ty) + (pz-tz)*(pz-tz));
}

// ==========================================================
// STRING UTILS (INI)
// ==========================================================
stock Iryou_StripLineEnd(str[])
{
    new len = strlen(str);
    while(len > 0 && (str[len-1] == '\n' || str[len-1] == '\r'))
    {
        str[--len] = '\0';
    }
    return 1;
}

stock Iryou_Trim(str[])
{
    // trim esquerda
    new i = 0;
    while(str[i] != '\0' && str[i] <= ' ') i++;
    if(i > 0) strdel(str, 0, i);

    // trim direita
    new len = strlen(str);
    while(len > 0 && str[len-1] <= ' ')
    {
        str[--len] = '\0';
    }
    return 1;
}

stock Iryou_ReadIniValue(const filename[], const key[], dest[], destSize)
{
    new File:f = fopen(filename, io_read);
    if(!f) return 0;

    new line[256];
    new left[128];
    new right[128];

    while(fread(f, line))
    {
        Iryou_StripLineEnd(line);
        Iryou_Trim(line);

        if(!line[0]) continue;
        if(line[0] == ';' || line[0] == '#') continue;

        new eq = strfind(line, "=", false);
        if(eq == -1) continue;

        strmid(left, line, 0, eq, sizeof left);
        strmid(right, line, eq+1, strlen(line), sizeof right);

        Iryou_Trim(left);
        Iryou_Trim(right);

        if(!strcmp(left, key, true))
        {
            format(dest, destSize, "%s", right);
            fclose(f);
            return 1;
        }
    }

    fclose(f);
    return 0;
}

stock Iryou_GetCharName(playerid, dest[], destSize)
{
    // tenta ler pelo INI: CONTAS/nomedaconta.ini  (Nome = ...)
    new acc[MAX_PLAYER_NAME];
    GetPlayerName(playerid, acc, sizeof acc);

    new path[96];
    format(path, sizeof path, "CONTAS/%s.ini", acc);

    if(Iryou_ReadIniValue(path, "Nome", dest, destSize))
        return 1;

    // fallback: mostra conta se não achar
    format(dest, destSize, "%s", acc);
    return 1;
}

// ==========================================================
// MIRA (igual Arashi)
// ==========================================================
stock Iryou_GetAimTarget(playerid)
{
    new vw = GetPlayerVirtualWorld(playerid);

    #if defined GetLookingTarget
        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(i == playerid) continue;
            if(!IsPlayerConnected(i)) continue;

            #if defined Invunerable
                new bool:ign = (Invunerable[i] == 1);
            #else
                new bool:ign = false;
            #endif

            new ret = GetLookingTarget(80.0, 3.0, ign, false, vw, playerid, i);
            if(ret == PLAYER) return i;
        }
        return INVALID_PLAYER_ID;
    #else
        return GetPlayerTargetPlayer(playerid);
    #endif
}

// ==========================================================
// EFEITO / ANIMAÇÃO
// ==========================================================
stock Iryou_EfeitoStart(playerid)
{
    ApplyAnimation(playerid, "Shinobi_Anim", "Cura_1", 4.0, 1, 0, 0, 0, 0, 1);

    SetPlayerAttachedObject(playerid, IRYOU_EFFECT_SLOT, 18677, 5,
        0.0000, 0.0429, -1.6980,
        0.0000, 0.0000, 0.0000,
        1.0000, 1.0000, 1.0000
    );

    #if defined AudioInPlayer
        AudioInPlayer(playerid, 50.0, 72);
    #endif
    return 1;
}

stock Iryou_EfeitoEnsure(playerid)
{
    if(!Iryou_Ativo[playerid]) return 1;

    #if defined IsPlayerAttachedObjectSlotUsed
        if(!IsPlayerAttachedObjectSlotUsed(playerid, IRYOU_EFFECT_SLOT))
        {
            SetPlayerAttachedObject(playerid, IRYOU_EFFECT_SLOT, 18677, 5,
                0.0000, 0.0429, -1.6980,
                0.0000, 0.0000, 0.0000,
                1.0000, 1.0000, 1.0000
            );
        }
    #else
        SetPlayerAttachedObject(playerid, IRYOU_EFFECT_SLOT, 18677, 5,
            0.0000, 0.0429, -1.6980,
            0.0000, 0.0000, 0.0000,
            1.0000, 1.0000, 1.0000
        );
    #endif
    return 1;
}

stock Iryou_EfeitoStop(playerid)
{
    RemovePlayerAttachedObject(playerid, IRYOU_EFFECT_SLOT);
    ClearAnimations(playerid);
    return 1;
}

stock Iryou_Say(playerid)
{
    #if defined MensagemJutsu
        new str[64];
        format(str, sizeof str, "Iryou no Jutsu!");
        MensagemJutsu(playerid, 20.0, str);
    #else
        SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(JUTSU){FFFFFF} Iryou no Jutsu!");
    #endif
    return 1;
}

// ==========================================================
// STOP
// ==========================================================
stock Iryou_Stop(playerid)
{
    Iryou_Ativo[playerid] = false;

    if(Iryou_TimerInput[playerid])
    {
        KillTimer(Iryou_TimerInput[playerid]);
        Iryou_TimerInput[playerid] = 0;
    }
    if(Iryou_TimerHeal[playerid])
    {
        KillTimer(Iryou_TimerHeal[playerid]);
        Iryou_TimerHeal[playerid] = 0;
    }

    Iryou_EfeitoStop(playerid);

    // compat GM (assumindo que existem no seu GM)
    CuraUsada[playerid] = 0;
    IryouUse[playerid]  = 0;

    Iryou_Target[playerid]   = INVALID_PLAYER_ID;
    Iryou_Level[playerid]    = 0;
    Iryou_Custo[playerid]    = 0.0;
    Iryou_LastHP[playerid]   = 0.0;
    Iryou_LastKeys[playerid] = 0;

    return 1;
}

// ==========================================================
// MENU: monta lista (coloca "prefer" no topo se válido)
// ==========================================================
stock bool:Iryou_IsCandidate(playerid, targetid)
{
    if(!Iryou_IsValidPlayer(targetid)) return false;
    if(targetid == playerid) return false;

    if(!Iryou_SameWorldInt(playerid, targetid)) return false;
    if(Iryou_Dist(playerid, targetid) > IRYOU_RANGE) return false;

    if(GetPVarInt(targetid, "Inconsciente") >= 1) return false;
    return true;
}

stock Iryou_BuildMenu(playerid, prefer)
{
    Iryou_MenuCount[playerid] = 0;

    if(prefer != INVALID_PLAYER_ID && Iryou_IsCandidate(playerid, prefer))
    {
        Iryou_MenuTargets[playerid][Iryou_MenuCount[playerid]++] = prefer;
    }

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(Iryou_MenuCount[playerid] >= IRYOU_MENU_MAX) break;
        if(i == playerid) continue;
        if(i == prefer) continue;
        if(!Iryou_IsCandidate(playerid, i)) continue;

        Iryou_MenuTargets[playerid][Iryou_MenuCount[playerid]++] = i;
    }

    return Iryou_MenuCount[playerid];
}

stock Iryou_OpenTargetMenu(playerid, prefer)
{
    new count = Iryou_BuildMenu(playerid, prefer);
    if(count <= 0)
        return SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Não tem ninguém perto para curar.");

    new list[1024];
    list[0] = '\0';

    for(new idx = 0; idx < count; idx++)
    {
        new id = Iryou_MenuTargets[playerid][idx];

        new nome[64];
        Iryou_GetCharName(id, nome, sizeof nome);

        new line[96];
        format(line, sizeof line, "[%d] %s\n", id, nome);
        strcat(list, line);
    }

    Iryou_Selecting[playerid] = true;

    ShowPlayerDialog(playerid, DIALOG_IRYOU_TARGET, DIALOG_STYLE_LIST,
        "Escolha quem você quer curar", list, "Curar", "Cancelar");

    return 1;
}

// Handler: você precisa chamar isso no OnDialogResponse do GM
stock Iryou_OnDialogResponse(playerid, dialogid, response, listitem)
{
    if(dialogid != DIALOG_IRYOU_TARGET) return 0;

    Iryou_Selecting[playerid] = false;

    if(!response) return 1;
    if(listitem < 0 || listitem >= Iryou_MenuCount[playerid]) return 1;

    new targetid = Iryou_MenuTargets[playerid][listitem];
    if(!Iryou_IsValidPlayer(targetid)) return 1;

    return Iryou_Start(playerid, targetid);
}

// ==========================================================
// START (centraliza o início da cura; usado pelo cmd e menu)
// ==========================================================
stock Iryou_Start(playerid, targetid)
{
    if(Iryou_Ativo[playerid])
        return SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Você já está curando. Aperte {E9FE23}N{FFFFFF} para parar.");

    // valida alvo
    if(!Iryou_IsCandidate(playerid, targetid))
        return SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Alvo inválido para iniciar cura.");

    // nível/custo por progresso
    new level = 0;
    new Float:custo = 0.0;

    if(Info[playerid][pProgressoHP] >= IRYOU_PESADA_REQ) { level = 3; custo = IRYOU_PESADA_CUSTO; }
    else if(Info[playerid][pProgressoHP] >= IRYOU_MEDIA_REQ) { level = 2; custo = IRYOU_MEDIA_CUSTO; }
    else if(Info[playerid][pProgressoHP] >= IRYOU_LEVE_REQ) { level = 1; custo = IRYOU_LEVE_CUSTO; }
    else return SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Você não tem progresso médico suficiente.");

    if(Info[playerid][pChakraEnUso] < custo)
    {
        #if defined SemChakra
            return SemChakra(playerid);
        #else
            return SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Sem chakra suficiente.");
        #endif
    }

    // consome e ativa
    Info[playerid][pChakraEnUso] -= custo;

    Iryou_Target[playerid] = targetid;
    Iryou_Level[playerid]  = level;
    Iryou_Custo[playerid]  = custo;

    CuraUsada[playerid] = 1;
    IryouUse[playerid]  = 1;

    Iryou_Ativo[playerid] = true;

    Iryou_LastHP[playerid]   = Info[playerid][pHealthEnUso];
    Iryou_LastKeys[playerid] = 0;

    Iryou_Say(playerid);
    Iryou_EfeitoStart(playerid);

    SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(DICA){FFFFFF} Cura ativa. Aperte {E9FE23}N{FFFFFF} uma vez para parar.");

    Iryou_TimerInput[playerid] = SetTimerEx("Iryou_Input", IRYOU_INPUT_MS, true, "i", playerid);
    Iryou_TimerHeal[playerid]  = SetTimerEx("Iryou_HealTick", IRYOU_TICK_MS, true, "i", playerid);

    return 1;
}

// ==========================================================
// TIMER RÁPIDO: detecta N (tap), dano, efeito, perder alvo
// ==========================================================
forward Iryou_Input(playerid);
public Iryou_Input(playerid)
{
    if(!Iryou_IsValidPlayer(playerid)) return 0;
    if(!Iryou_Ativo[playerid]) return 0;

    new keys, ud, lr;
    GetPlayerKeys(playerid, keys, ud, lr);

    // tap no N (borda)
    if((keys & KEY_NO) && !(Iryou_LastKeys[playerid] & KEY_NO))
    {
        SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Você interrompeu a cura.");
        Iryou_Stop(playerid);
        return 0;
    }
    Iryou_LastKeys[playerid] = keys;

    // se ficou inconsciente
    if(GetPVarInt(playerid, "Inconsciente") >= 1)
    {
        SendClientMessageEx(playerid, COLOR_WHITE, "{FF6A6A}(IRYOU){FFFFFF} Cura interrompida: você ficou inconsciente.");
        Iryou_Stop(playerid);
        return 0;
    }

    // dano no curador (HP caiu)
    new Float:myhp = Info[playerid][pHealthEnUso];
    if(Iryou_LastHP[playerid] > 0.0 && myhp + 0.001 < Iryou_LastHP[playerid])
    {
        SendClientMessageEx(playerid, COLOR_WHITE, "{FF6A6A}(IRYOU){FFFFFF} Cura interrompida: você foi atacado.");
        Iryou_Stop(playerid);
        return 0;
    }
    Iryou_LastHP[playerid] = myhp;

    // alvo ok?
    new targetid = Iryou_Target[playerid];
    if(targetid == INVALID_PLAYER_ID || !Iryou_IsValidPlayer(targetid))
    {
        Iryou_Stop(playerid);
        return 0;
    }

    // mantém efeito sempre ligado enquanto ativo
    Iryou_EfeitoEnsure(playerid);

    #if IRYOU_STOP_ON_LOSE_TARGET
        if(!Iryou_SameWorldInt(playerid, targetid))
        {
            SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Cura interrompida: alvo mudou de mundo/interior.");
            Iryou_Stop(playerid);
            return 0;
        }
        if(Iryou_Dist(playerid, targetid) > IRYOU_RANGE)
        {
            SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Cura interrompida: alvo se afastou.");
            Iryou_Stop(playerid);
            return 0;
        }
    #endif

    return 1;
}

// ==========================================================
// TIMER LENTO: cura 5% por tick até encher
// ==========================================================
forward Iryou_HealTick(playerid);
public Iryou_HealTick(playerid)
{
    if(!Iryou_IsValidPlayer(playerid)) return 0;
    if(!Iryou_Ativo[playerid]) return 0;

    new targetid = Iryou_Target[playerid];
    if(targetid == INVALID_PLAYER_ID || !Iryou_IsValidPlayer(targetid))
    {
        Iryou_Stop(playerid);
        return 0;
    }

    if(!Iryou_SameWorldInt(playerid, targetid)) return 1;
    if(Iryou_Dist(playerid, targetid) > IRYOU_RANGE) return 1;

    if(GetPVarInt(targetid, "Inconsciente") >= 1) return 1;

    new Float:hp  = Info[targetid][pHealthEnUso];
    new Float:max = Info[targetid][pHealthMaximo];
    if(max <= 0.0) return 1;

    hp += (max * IRYOU_HEAL_PCT);

    if(hp >= max)
    {
        NewSetHP(targetid, max);

        if(Iryou_Level[playerid] == 3)
        {
            Info[targetid][pNinjaFraturado] = 0;
            Info[targetid][pNinjaQuebrado]  = 0;
            ClearAnimations(targetid);
        }

        SendClientMessageEx(playerid, COLOR_WHITE, "{00FF00}(IRYOU){FFFFFF} Cura finalizada (vida cheia).");
        Iryou_Stop(playerid);
        return 0;
    }

    NewSetHP(targetid, hp);
    return 1;
}

// ==========================================================
// CMD /iryou
// - se tiver 2+ alvos válidos perto => abre menu e NÃO cura até selecionar
// - se tiver 1 alvo só => cura direto
// ==========================================================
// ==========================================================
//  IRYOU como "JUTSU" (função real) + CMD atalho
//  - O core (hotbarpreparacao) pode chamar Jutsu_Iryou via CallLocalFunction
//  - Por isso eu deixo um public Jutsu_Iryou() que chama o stock Jutsu_Iryou_Exec()
// ==========================================================

// Se o core chamar por CallLocalFunction("Jutsu_Iryou", ...), precisa ser public:
forward Jutsu_Iryou(playerid);
public Jutsu_Iryou(playerid)
{
    return Jutsu_Iryou_Exec(playerid);
}

// ==========================================================
//  IRYOU - CMD virando stock (pra poder ser chamado por selos/hotbar)
// ==========================================================

stock Iryou_Use(playerid)
{
    // gate estilo GM
    if(!(Info[playerid][pProgressoHP] >= 1
        || Info[playerid][pHPPatente] == 2 || Info[playerid][pHPPatente] == 3 || Info[playerid][pHPPatente] == 4
        || Info[playerid][pHPPatente] == 5 || Info[playerid][pHPPatente] == 7 || Info[playerid][pHPPatente] == 8
        || Info[playerid][pHPPatente] == 9 || Info[playerid][pHPPatente] == 10))
    {
        return 1;
    }

    if(Iryou_Selecting[playerid])
        return SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Selecione um alvo no menu (ou cancele).");

    if(Iryou_Ativo[playerid])
        return SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Você já está curando. Aperte {E9FE23}N{FFFFFF} para parar.");

    if(CuraUsada[playerid] == 1) return 1;

    // cooldown
    if(Iryou_NextUse[playerid] > gettime())
    {
        new left = Iryou_NextUse[playerid] - gettime();
        new msg[96];
        format(msg, sizeof msg, "{E9FE23}(IRYOU){FFFFFF} Aguarde %d segundos para usar novamente.", left);
        return SendClientMessageEx(playerid, COLOR_WHITE, msg);
    }

    // pega mira e monta lista
    new aim = Iryou_GetAimTarget(playerid);
    new count = Iryou_BuildMenu(playerid, aim);

    if(count <= 0)
        return SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Não tem ninguém perto para curar.");

    // se tiver 2+ -> menu (não cura ainda!)
    if(count >= 2)
        return Iryou_OpenTargetMenu(playerid, aim);

    // se tiver 1 -> cura direto
    new targetid = Iryou_MenuTargets[playerid][0];
    Iryou_NextUse[playerid] = gettime() + IRYOU_COOLDOWN_SEC;
    return Iryou_Start(playerid, targetid);
}

// Seu comando chama o stock:
CMD:iryou(playerid, params[])
{
    #pragma unused params
    return Iryou_Use(playerid);
}


// ==========================================================
// HOOK OPCIONAL (RECOMENDADO): pega o tap no N 100%
// Chame no OnPlayerKeyStateChange do GM
// ==========================================================
stock Iryou_OnKeyStateChange(playerid, newkeys, oldkeys)
{
    if(!Iryou_Ativo[playerid]) return 1;

    if((newkeys & KEY_NO) && !(oldkeys & KEY_NO))
    {
        SendClientMessageEx(playerid, COLOR_WHITE, "{E9FE23}(IRYOU){FFFFFF} Você interrompeu a cura.");
        Iryou_Stop(playerid);
        return 1;
    }
    return 1;
}

// ==========================================================
// Limpeza
// ==========================================================
stock Iryou_OnDisconnect(playerid)
{
    Iryou_Selecting[playerid] = false;
    if(Iryou_Ativo[playerid]) Iryou_Stop(playerid);
    Iryou_NextUse[playerid] = 0;
    return 1;
}
