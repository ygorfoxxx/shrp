// ==========================================================
//  hotbarpreparacao.pwn (CORE)
//  - Lista de jutsus (somente os liberados p/ player)
//  - Bind por selos -> jutsu (hotbar futura)
//  - Compat?vel com pawncc antigo
// ==========================================================

#if defined _HBPREP_INC
    // j? inclu?do
#else
#define _HBPREP_INC

#include <a_samp>

// ---------- FALLBACKS ----------
#if !defined SendClientMessageEx
    #define SendClientMessageEx(%0,%1,%2) SendClientMessage(%0,%1,%2)
#endif

// Elemento1/Elemento2 existem no seu GM. Se n?o existir, retorna 0.
#if defined Elemento1
stock HB_GetElemento1(playerid) { return Elemento1[playerid]; }
#else
stock HB_GetElemento1(playerid) { return 0; }
#endif

#if defined Elemento2
stock HB_GetElemento2(playerid) { return Elemento2[playerid]; }
#else
stock HB_GetElemento2(playerid) { return 0; }
#endif

// Buffers globais (evita crash por stack)
new gHB_ListBuf[4096];
new gHB_CatBuf[2048];

// ---------- ELEMENTOS ----------
#define ELEM_NONE   (0)
#define ELEM_KATON  (1)
#define ELEM_SUITON (2)
#define ELEM_FUTON  (3)
#define ELEM_DOTON  (4)
#define ELEM_RAITON (5)

// ---------- BINDS ----------
#define JUTSU_MAX_BINDS   (24)
#define JUTSU_MAX_SELOS   (128)

// ----------------------------------------------------------
// Normaliza a sequ?ncia de selos para um formato can?nico.
// Aceita varia??es com/sem v?rgula/espa?o e tamb?m "Drag?o"
// em diferentes encodings (ex: UTF-8 ou CP1252).
// Formato gerado: "Tigre, Dragao, " (sempre com ", " no fim)
// ----------------------------------------------------------
stock HBCH_SanitizeSealToken(const inTok[], outTok[], outLen)
{
    new j = 0;
    for (new i = 0; inTok[i] != '\0' && j < outLen - 1; i++)
    {
        new c = inTok[i];

        // UTF-8: '?' = 0xC3 0xA3, 'ã' aparece quando j? veio "quebrado"
        if (c == 195) // 0xC3
        {
            new c2 = inTok[i + 1];
            if (c2 == 163) // 0xA3
            {
                outTok[j++] = 'a';
                i++;
                continue;
            }
        }

        // CP1252/Latin-1: '?' = 0xE3
        if (c == 227)
        {
            outTok[j++] = 'a';
            continue;
        }

        // lower-case (ASCII)
        if (c >= 'A' && c <= 'Z') c += 32;

        // mant?m s? letras/n?meros
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9'))
            outTok[j++] = c;
    }
    outTok[j] = '\0';
    return 1;
}

stock bool:HBCH_SelosCanonicalize(const input[], output[], outLen)
{
    output[0] = '\0';
    if (!strlen(input)) return false;

    new token[24];
    new clean[24];
    new tlen = 0;

    for (new i = 0; ; i++)
    {
        new c = input[i];

        if (c == ' ' || c == '\t' || c == ',' || c == ';' || c == '|' || c == '\n' || c == '\r' || c == '\0')
        {
            if (tlen > 0)
            {
                token[tlen] = '\0';
                HBCH_SanitizeSealToken(token, clean, sizeof clean);

                // ignora "e"
                if (!strcmp(clean, "e", true))
                {
                    // nada
                }
                else if (!strcmp(clean, "tigre", true) || !strcmp(clean, "t", true) || !strcmp(clean, "1", false))
                    format(output, outLen, "%sTigre, ", output);

                else if (!strcmp(clean, "dragao", true) || !strcmp(clean, "d", true) || !strcmp(clean, "2", false))
                    format(output, outLen, "%sDragao, ", output);

                else if (!strcmp(clean, "coelho", true) || !strcmp(clean, "c", true) || !strcmp(clean, "3", false))
                    format(output, outLen, "%sCoelho, ", output);

                else if (!strcmp(clean, "rato", true) || !strcmp(clean, "r", true) || !strcmp(clean, "4", false))
                    format(output, outLen, "%sRato, ", output);

                else if (!strcmp(clean, "cobra", true) || !strcmp(clean, "s", true) || !strcmp(clean, "5", false))
                    format(output, outLen, "%sCobra, ", output);

                else
                    return false;

                tlen = 0;
            }

            if (c == '\0') break;
            continue;
        }

        if (tlen < (sizeof(token) - 1))
            token[tlen++] = c;
    }

    return (strlen(output) > 0);
}


// IDs internos
enum eJutsuId
{
    JID_INVALID = -1,

    // Katon
    JID_GOUKAKYUU,
    JID_HOUSENKA,
    JID_KARYUUENDAN,

    // Raiton
    JID_ARASHI_I,
    JID_RAIKYUU,
    JID_NAGASHI,

    // Suiton
    JID_MIZURAPPA,
    JID_SUIKODAN,
    JID_SUIROU,

    // Futon
    JID_RASENGAN,
    JID_HANACHI,
    JID_SHINKUHA,
    JID_ATSUGAI,

    // Doton
    JID_IWAKAI,
    JID_DORYUUHEKI,
    JID_DOROJIGOKU,

    // Transforma??es / especiais
    JID_EREMITA_SUSANO,
    JID_BARREIRA_TOGGLE,
    JID_SABERU,
    JID_SELAMENTO,
    JID_KINOBI,
    JID_KAWARIMI,
    JID_IRYOU,
    JID_KATSUYU,
    JID_MESU,
    JID_URUSHI,

    // Bases / modo
    JID_BASE_ORO,
    JID_BASE_AKA,
    JID_MODO_RATO,
    JID_MODO_DRAGAO,
    JID_RAIJIN_VOADOR,
	
	//
	JID_SAPO_PRISAO, //jutsu invocacao sapo

    // Cl?
    JID_CLAN_TIGRE,
	
	//HYUGA KAITEN
	JID_HAKKESHOU,

	// Hyuuga
	JID_BYAKUGAN

};

#if !defined JID_CLA_TIGRE
    #define JID_CLA_TIGRE JID_CLAN_TIGRE
#endif

new gBindSelos[MAX_PLAYERS][JUTSU_MAX_BINDS][JUTSU_MAX_SELOS];
new eJutsuId:gBindJutsu[MAX_PLAYERS][JUTSU_MAX_BINDS];

// ==========================================================
// PERSIST?NCIA DOS BINDS (sem y_hooks)
// - Salva/Carrega DENTRO do .ini da conta (pasta CONTAS/)
// - Tag usada: [data]
// - Chaves criadas:
//    HB_BindJutsu0..23 (int)
//    HB_BindSelos0..23 (string)
// ==========================================================

#include <YSI\y_ini>

// Conta/chave atual (setada no login). Se vazio, usa o nick.
new gHB_AccKey[MAX_PLAYERS][32];

// Flag: j? carregou binds desta sess?o?
new bool:gHB_BindsLoaded[MAX_PLAYERS];

stock HBCH_SanitizeKey(key[])
{
    for (new i = 0; key[i] != '\0'; i++)
    {
        switch (key[i])
        {
            case ' ', '/', '\\', ':', '*', '?', '"', '<', '>', '|': key[i] = '_';
        }
    }
    return 1;
}

stock HBCH_SetAccountKey(playerid, const key[])
{
    format(gHB_AccKey[playerid], sizeof(gHB_AccKey[]), "%s", key);
    HBCH_SanitizeKey(gHB_AccKey[playerid]);
    return 1;
}

stock HBCH_GetAccountKey(playerid, out[], outSize)
{
    if (gHB_AccKey[playerid][0] != '\0')
    {
        format(out, outSize, "%s", gHB_AccKey[playerid]);
        return 1;
    }

    new nick[MAX_PLAYER_NAME];
    GetPlayerName(playerid, nick, sizeof nick);
    format(out, outSize, "%s", nick);
    HBCH_SanitizeKey(out);
    return 1;
}

stock HBCH_GetAccountIniPath(playerid, out[], outSize)
{
    new key[32];
    HBCH_GetAccountKey(playerid, key, sizeof key);

    #if defined USERFILE
        format(out, outSize, USERFILE, key);
    #else
        format(out, outSize, "CONTAS/%s.ini", key);
    #endif
    return 1;
}

// ------------ LOAD (INI -> arrays) ------------
forward HBCH_Binds_Parse(playerid, name[], value[]);
public HBCH_Binds_Parse(playerid, name[], value[])
{
    // HB_BindJutsuX
    if (strfind(name, "HB_BindJutsu", true) == 0)
    {
        new idx = 0;
        for (new i = 12; name[i] != '\0'; i++)
        {
            if (name[i] < '0' || name[i] > '9') return 1;
            idx = (idx * 10) + (name[i] - '0');
        }
        if (idx < 0 || idx >= JUTSU_MAX_BINDS) return 1;

        gBindJutsu[playerid][idx] = eJutsuId:strval(value);
        return 1;
    }

    // HB_BindSelosX
    if (strfind(name, "HB_BindSelos", true) == 0)
    {
        new idx = 0;
        for (new i = 12; name[i] != '\0'; i++)
        {
            if (name[i] < '0' || name[i] > '9') return 1;
            idx = (idx * 10) + (name[i] - '0');
        }
        if (idx < 0 || idx >= JUTSU_MAX_BINDS) return 1;

        // Alguns INIs acabam gravando um caractere invis?vel (ex: 0x01) quando estava "vazio".
// Trata isso como string vazia.
if (value[0] <= 1 && value[1] == ' ')
{
    gBindSelos[playerid][idx][0] = ' ';
    return 1;
}

new canon[128];
if (HBCH_SelosCanonicalize(value, canon, sizeof canon))
    format(gBindSelos[playerid][idx], JUTSU_MAX_SELOS, "%s", canon);
else
    format(gBindSelos[playerid][idx], JUTSU_MAX_SELOS, "%s", value);
return 1;
    }

    return 1;
}

stock HBCH_Binds_LoadFromAccount(playerid)
{
    new file[64];
    HBCH_GetAccountIniPath(playerid, file, sizeof file);

    // Sempre reseta antes de carregar (evita lixo/char invis?vel em slots vazios).
    Jutsu_BindReset(playerid);

    // Se ainda n?o existe, s? marca como carregado (pra n?o ficar parseando ? toa).
    if (!fexist(file))
    {
        gHB_BindsLoaded[playerid] = true;
    HBCH_SyncSkillBar(playerid);
        return 0;
    }

    INI_ParseFile(file, "HBCH_Binds_Parse", .bExtra = true, .extra = playerid);
    gHB_BindsLoaded[playerid] = true;
    HBCH_SyncSkillBar(playerid);
    return 1;
}

// ------------ SAVE (arrays -> INI) ------------
stock HBCH_Binds_SaveToAccount(playerid)
{
    new file[64];
    HBCH_GetAccountIniPath(playerid, file, sizeof file);

    new INI:fh = INI_Open(file);
    if (fh == INI_NO_FILE) return 0;

    INI_SetTag(fh, "data");

    new key[24];
    for (new i = 0; i < JUTSU_MAX_BINDS; i++)
    {
        format(key, sizeof key, "HB_BindJutsu%d", i);
        INI_WriteInt(fh, key, _:gBindJutsu[playerid][i]);

        format(key, sizeof key, "HB_BindSelos%d", i);
        INI_WriteString(fh, key, gBindSelos[playerid][i]);
    }

    INI_Close(fh);
    return 1;
}

stock Jutsu_BindReset(playerid);

// ------------ WRAPPERS (compat com vers?es anteriores) ------------
stock HB_SaveBinds(playerid)       { return HBCH_Binds_SaveToAccount(playerid); }
stock HB_LoadBinds(playerid)       { return HBCH_Binds_LoadFromAccount(playerid); }
stock HB_LoadBindsOnce(playerid)
{
    if (gHB_BindsLoaded[playerid]) return 1;

    new r = HBCH_Binds_LoadFromAccount(playerid);

    // limpeza de segurança: impede que o mesmo jutsu fique duplicado em múltiplas binds antigas
    HB_BindsCleanupDupes(playerid);

    return r;
}


// ------------ SKILLBAR SYNC (MentorSkillBar) ---------------
// Chama MSB_SyncBinds() se o mÃ³dulo da barra estiver incluÃ­do.
stock HBCH_SyncSkillBar(playerid)
{
    if (funcidx("MSB_SyncBinds") != -1)
        CallLocalFunction("MSB_SyncBinds", "d", playerid);
    return 1;
}


// ------------ FUN??ES QUE O GAMEMODE J? CHAMA ------------
stock HBCH_Binds_OnConnect(playerid)
{
    gHB_AccKey[playerid][0] = '\0';
    gHB_BindsLoaded[playerid] = false;

    // Evita lixo em gBindSelos/gBindJutsu quando a conta ainda n?o tem binds.
    Jutsu_BindReset(playerid);
    return 1;
}

stock HBCH_Binds_OnLogin(playerid, const accountKey[])
{
    HBCH_SetAccountKey(playerid, accountKey);
    gHB_BindsLoaded[playerid] = false;
    return HBCH_Binds_LoadFromAccount(playerid);
}

stock HBCH_Binds_OnSpawn(playerid)
{
    if (!gHB_BindsLoaded[playerid]) HBCH_Binds_LoadFromAccount(playerid);
    return 1;
}

stock HBCH_Binds_OnDisconnect(playerid)
{
    return HBCH_Binds_SaveToAccount(playerid);
}
// ----------------------------------------------------------
// RESET de binds (OnPlayerConnect / quando logar)
// ----------------------------------------------------------
stock Jutsu_BindReset(playerid)
{
    for(new i = 0; i < JUTSU_MAX_BINDS; i++)
    {
        gBindJutsu[playerid][i] = JID_INVALID;
        gBindSelos[playerid][i][0] = '\0';
    }
    return 1;
}

// ----------------------------------------------------------
// Remove binds duplicados (mesmo jutsu em mais de um slot)
// - Útil para corrigir binds antigas e garantir "1 jutsu = 1 bind"
// ----------------------------------------------------------
stock HB_BindsCleanupDupes(playerid)
{
    if (!gHB_BindsLoaded[playerid]) return 0;

    new changed = 0;
    for (new i = 0; i < JUTSU_MAX_BINDS; i++)
    {
        new eJutsuId:jid = gBindJutsu[playerid][i];
        if (jid == JID_INVALID) continue;

        for (new j = i + 1; j < JUTSU_MAX_BINDS; j++)
        {
            if (gBindJutsu[playerid][j] == jid)
            {
                gBindJutsu[playerid][j] = JID_INVALID;
                gBindSelos[playerid][j][0] = '\0';
                changed = 1;
            }
        }
    }

    if (changed) HB_SaveBinds(playerid);
    HBCH_SyncSkillBar(playerid);
    return changed;
}

// Remove todas as ocorrências do jutsu, exceto o índice "keepIndex"
stock HB_BindDedupeJutsu(playerid, eJutsuId:jutsuId, keepIndex)
{
    new changed = 0;
    for (new i = 0; i < JUTSU_MAX_BINDS; i++)
    {
        if (i == keepIndex) continue;
        if (gBindJutsu[playerid][i] == jutsuId)
        {
            gBindJutsu[playerid][i] = JID_INVALID;
            gBindSelos[playerid][i][0] = '\0';
            changed = 1;
        }
    }
    return changed;
}

// ----------------------------------------------------------
// Set bind: 1 jutsu <-> 1 sequ?ncia de selos
// ----------------------------------------------------------
stock Jutsu_BindSet(playerid, eJutsuId:jutsuId, const selos[])
{
    HB_LoadBindsOnce(playerid);
    if (jutsuId == JID_INVALID) return 0;
    if (!strlen(selos)) return 0;

    // Segurança: se o player já tinha duplicatas antigas, remove antes de setar
    // (mantém o comportamento esperado: 1 jutsu só pode existir em 1 bind)
    HB_BindsCleanupDupes(playerid);

    new canon[128];
    if (!HBCH_SelosCanonicalize(selos, canon, sizeof canon))
        format(canon, sizeof canon, "%s", selos);

    // 1) se já existir bind com esses selos, usa esse slot e remove duplicatas do mesmo jutsu
    for (new i = 0; i < JUTSU_MAX_BINDS; i++)
    {
        if (gBindJutsu[playerid][i] != JID_INVALID && !strcmp(gBindSelos[playerid][i], canon, true))
        {
            HB_BindDedupeJutsu(playerid, jutsuId, i);

            gBindJutsu[playerid][i] = jutsuId;
            format(gBindSelos[playerid][i], JUTSU_MAX_SELOS, "%s", canon);
            HB_SaveBinds(playerid);
    HBCH_SyncSkillBar(playerid);
            return 1;
        }
    }

    // 2) se já existir bind desse jutsu, atualiza os selos no slot existente e remove outras duplicatas
    for (new j = 0; j < JUTSU_MAX_BINDS; j++)
    {
        if (gBindJutsu[playerid][j] == jutsuId)
        {
            HB_BindDedupeJutsu(playerid, jutsuId, j);

            format(gBindSelos[playerid][j], JUTSU_MAX_SELOS, "%s", canon);
            HB_SaveBinds(playerid);
    HBCH_SyncSkillBar(playerid);
            return 1;
        }
    }

    // 3) slot livre
    for (new k = 0; k < JUTSU_MAX_BINDS; k++)
    {
        if (gBindJutsu[playerid][k] == JID_INVALID)
        {
            HB_BindDedupeJutsu(playerid, jutsuId, k);

            gBindJutsu[playerid][k] = jutsuId;
            format(gBindSelos[playerid][k], JUTSU_MAX_SELOS, "%s", canon);
            HB_SaveBinds(playerid);
    HBCH_SyncSkillBar(playerid);
            return 1;
        }
    }

    // 4) sem espaço: substitui o 1º e remove duplicatas
    HB_BindDedupeJutsu(playerid, jutsuId, 0);

    gBindJutsu[playerid][0] = jutsuId;
    format(gBindSelos[playerid][0], JUTSU_MAX_SELOS, "%s", canon);
    HB_SaveBinds(playerid);
    HBCH_SyncSkillBar(playerid);
    return 1;
}


stock Jutsu_BindClearBySelos(playerid, const selos[])
{
    HB_LoadBindsOnce(playerid);
    if (!strlen(selos)) return 0;

    new canon[128];
    if (!HBCH_SelosCanonicalize(selos, canon, sizeof canon))
        format(canon, sizeof canon, "%s", selos);

    for(new i = 0; i < JUTSU_MAX_BINDS; i++)
    {
        if (gBindJutsu[playerid][i] != JID_INVALID && !strcmp(gBindSelos[playerid][i], canon, true))
        {
            gBindJutsu[playerid][i] = JID_INVALID;
            gBindSelos[playerid][i][0] = '\0';
            HB_SaveBinds(playerid);
    HBCH_SyncSkillBar(playerid);
            return 1;
        }
    }
    return 0;
}


stock Jutsu_BindClearByJutsu(playerid, eJutsuId:jutsuId)
{
    HB_LoadBindsOnce(playerid);
    if (jutsuId == JID_INVALID) return 0;

    for(new i = 0; i < JUTSU_MAX_BINDS; i++)
    {
        if (gBindJutsu[playerid][i] == jutsuId)
        {
            gBindJutsu[playerid][i] = JID_INVALID;
            gBindSelos[playerid][i][0] = '\0';
            HB_SaveBinds(playerid);
    HBCH_SyncSkillBar(playerid);
            return 1;
        }
    }
    return 0;
}


// ----------------------------------------------------------
// Elemento + n?vel m?nimo (Info[playerid][pKaton] etc)
// ----------------------------------------------------------
// ----------------------------------------------------------
// ELEMENTO: precisa TER o elemento (Info[][]) e n?vel m?nimo
// (Elemento1/2 vira apenas um "extra" quando estiver setado)
// ----------------------------------------------------------
stock Jutsu_PlayerHasElementoNivel(playerid, elemento, nivelMin)
{
    if (elemento == ELEM_NONE) return 1;

    // Se Elemento1/2 n?o estiverem setados (0), n?o bloqueia a lista.
    new e1 = HB_GetElemento1(playerid);
    new e2 = HB_GetElemento2(playerid);
    if ((e1 != 0 || e2 != 0) && (e1 != elemento && e2 != elemento)) return 0;

    switch (elemento)
    {
        case ELEM_KATON:  return (Info[playerid][pKaton]  >= nivelMin);
        case ELEM_SUITON: return (Info[playerid][pSuiton] >= nivelMin);
        case ELEM_FUTON:  return (Info[playerid][pFuton]  >= nivelMin);
        case ELEM_DOTON:  return (Info[playerid][pDoton]  >= nivelMin);
        case ELEM_RAITON: return (Info[playerid][pRaiton] >= nivelMin);
    }
    return 0;
}


stock Jutsu_PlayerTemElemento(playerid, elemento, nivelMin)
{
    return Jutsu_PlayerHasElementoNivel(playerid, elemento, nivelMin);
}

// ----------------------------------------------------------
// CAST por ID (chama fun??es do seu GM)
// ----------------------------------------------------------
stock Jutsu_CastByID(playerid, eJutsuId:jutsuId)
{
    switch (jutsuId)
    {
        case JID_GOUKAKYUU:      return JutsuGoukakyuu(playerid);
        case JID_HOUSENKA:       return HousenkaJutsu(playerid);
        case JID_KARYUUENDAN:    return JutsuKaryuuendan(playerid);

        case JID_ARASHI_I:       return ArashiJutsuI(playerid);
        case JID_RAIKYUU:        return JutsuRaikyuu(playerid);
        case JID_NAGASHI:        return JutsuNagashi(playerid);

        case JID_MIZURAPPA:      return SJutsuMizurappa(playerid);
        case JID_SUIKODAN:       return SuikodanJutsu(playerid);
        case JID_SUIROU:
        {
            SuirouNoJutsu(playerid);
            DeletePVar(playerid, "SuirouJutsuS");
            return 1;
        }

        case JID_RASENGAN:       return JutsuRasengan(playerid);
        case JID_HANACHI:        return JutsuHanachi(playerid);
        case JID_SHINKUHA:       return JutsuShinkuha(playerid);
        case JID_ATSUGAI:        return JutsuAtsugai(playerid);

        case JID_IWAKAI:         return JutsuIwakai(playerid);
        case JID_DORYUUHEKI:     return JutsuDoryuuheki(playerid);
        case JID_DOROJIGOKU:     return SJutsuDorojigoku(playerid);

        case JID_EREMITA_SUSANO:
        {
            JutsuEremita(playerid);
            JutsuSusano(playerid);
            return 1;
        }

        case JID_BARREIRA_TOGGLE:
        {
            if (Barreira[playerid][BarreiraAtiva] == 0) JutsuBarreira(playerid);
            else
            {
                BarreiraOff(playerid);
                ApplyAnimation(playerid, "Shinobi_Anim", "Nara_02", 5.5, 0, 0, 0, 0, 0);
            }
            return 1;
        }

        case JID_SABERU:
        {
            SaberuNoJutsu(playerid);
            DeletePVar(playerid, "ChakraNoSaberu");
            return 1;
        }

        case JID_SELAMENTO:      return JutsuSelamento(playerid);

        case JID_KINOBI:
        {
            SetTimerEx("KinobiStart", 100, false, "i", playerid);
            AudioInPlayer(playerid, 25.0, 36);
            return 1;
        }

        case JID_KAWARIMI:       return KawarimiJutsu(playerid);

        case JID_IRYOU:          return Iryou_Use(playerid);
        case JID_KATSUYU:        return JutsuKatsuyuA(playerid);
        case JID_MESU:           return MesuChakra(playerid);
        case JID_URUSHI:         return UrushiJutsu(playerid);

        case JID_BASE_ORO:       return BaseAbrir(playerid, 0);
        case JID_BASE_AKA:       return BaseAbrir(playerid, 1);

        case JID_MODO_RATO:
        {
            if (Info[playerid][pSenin] == 2) return JutsuMarcaMaldicao(playerid);
            if (Info[playerid][pSenin] == 4) return RineSharingan(playerid);
            if (Info[playerid][pClan]  == 5) return TeleporteKunai(playerid);
            return 1;
        }

        case JID_MODO_DRAGAO:
        {
            if (Info[playerid][pClan] == 5) return RaijinVoadorRasengan(playerid);
            return 1;
        }

        case JID_RAIJIN_VOADOR:  return RaijinVoador(playerid);


		 case JID_SAPO_PRISAO:    return SapoInvocacaoJutsu(playerid); //jutsu invocacao sapo
		
			//KAITEN HYUGA
		case JID_HAKKESHOU:
{
    if(Info[playerid][pClan] != CLAN_HYUUGA || Info[playerid][pClanNivel] < 2) return 1;
    return JutsuHakkeshou(playerid);
}

		
		case JID_BYAKUGAN:
{
    if(Info[playerid][pClan] != CLAN_HYUUGA || Info[playerid][pClanNivel] < 1) return 1;
    return ByakuganJutsu(playerid);
}

        case JID_CLAN_TIGRE:
        {
            if (Info[playerid][pClan] == 1) return JutsuTsutenkyakuu(playerid);
            if (Info[playerid][pClan] == 2) return IzanagiJutsu(playerid);
            if (Info[playerid][pClan] == 3) return JutsuKageshibari(playerid);

            if (Info[playerid][pClan] == 4)
            {
                if (Byakugan[playerid][byakuganUse] == 0) return ByakuganJutsu(playerid);
                if (Byakugan[playerid][byakuganUse] == 1) return ByakuganAtivar(playerid);
                return 1;
            }

            if (Info[playerid][pClan] == 5) return ColocarKunaiChao(playerid);
            if (Info[playerid][pClan] == 6) return JutsuRasengan(playerid);
			
			
            return 1;
        }
    }
    return 0;
}

// ----------------------------------------------------------
// Tabela padr?o (selos -> jutsu) + elemento + n?vel min
// ----------------------------------------------------------
static const gDefaultSelos[][] =
{
    // Katon
    "Tigre, Drag?o, Tigre, Drag?o, ",
    "Drag?o, Tigre, Rato, ",
    "Tigre, Drag?o, Tigre, Cobra, ",

    // Transforma??es
    "Drag?o, Tigre, Drag?o, ",

    // Raiton
    "Tigre, Coelho, Tigre, ",
    "Rato, Tigre, Coelho, ",
    "Tigre, Coelho, Tigre, Rato, ",

    // Suiton
    "Tigre, Rato, Tigre, ",
    "Drag?o, Coelho, Tigre, ",
    "Tigre, Rato, Tigre, Rato, ",

    // Futon
    "Tigre, Drag?o, Tigre, ",
    "Tigre, Drag?o, Tigre, Rato, ",
    "Rato, Tigre, Drag?o, ",
    "Tigre, Drag?o, Rato, Tigre, ",

    // Doton
    "Tigre, Cobra, Tigre, ",
    "Cobra, Tigre, Drag?o, ",
    "Tigre, Cobra, Tigre, Drag?o, ",

    // Anbu Barreira
    "Cobra, Coelho, Tigre, ",

    // Especiais
    "Rato, Tigre, Rato, ", // Saberu
    "Tigre, Cobra, ",      // Selamento
    "Coelho, ",            // Kinobi
    "Cobra, ",             // Kawarimi
    "Cobra, Tigre, ",      // Iryou
    "Cobra, Tigre, Cobra, ", // Katsuyu
    "Cobra, Tigre, Cobra, Tigre, Cobra, ", // Mesu
    "Rato, Tigre, ",       // Urushi

    // Cl?
    "Tigre, ",

    // Bases
    "Tigre, Drag?o, Rato, Drag?o, Rato, Cobra, ",
    "Coelho, Tigre, Tigre, Drag?o, Tigre, Cobra, ",

    // Modo / Raijin
    "Rato, ",
    "Drag?o, ",
    "Coelho, Tigre, "
	
	
};

static const eJutsuId:gDefaultJutsuId[] =
{
    JID_GOUKAKYUU, JID_HOUSENKA, JID_KARYUUENDAN,
    JID_EREMITA_SUSANO,
    JID_ARASHI_I, JID_RAIKYUU, JID_NAGASHI,
    JID_MIZURAPPA, JID_SUIKODAN, JID_SUIROU,
    JID_RASENGAN, JID_HANACHI, JID_SHINKUHA, JID_ATSUGAI,
    JID_IWAKAI, JID_DORYUUHEKI, JID_DOROJIGOKU,
    JID_BARREIRA_TOGGLE,
    JID_SABERU, JID_SELAMENTO, JID_KINOBI, JID_KAWARIMI, JID_IRYOU, JID_KATSUYU, JID_MESU, JID_URUSHI,
    JID_CLAN_TIGRE,
    JID_BASE_ORO, JID_BASE_AKA,
    JID_MODO_RATO, JID_MODO_DRAGAO, JID_RAIJIN_VOADOR
};

static const gDefaultElemento[] =
{
    ELEM_KATON, ELEM_KATON, ELEM_KATON,
    ELEM_NONE,
    ELEM_RAITON, ELEM_RAITON, ELEM_RAITON,
    ELEM_SUITON, ELEM_SUITON, ELEM_SUITON,
    ELEM_FUTON, ELEM_FUTON, ELEM_FUTON, ELEM_FUTON,
    ELEM_DOTON, ELEM_DOTON, ELEM_DOTON,
    ELEM_NONE,
    ELEM_NONE, ELEM_NONE, ELEM_NONE, ELEM_NONE, ELEM_NONE, ELEM_NONE, ELEM_NONE, ELEM_NONE,
    ELEM_NONE,
    ELEM_NONE, ELEM_NONE,
    ELEM_NONE, ELEM_NONE, ELEM_NONE
};

static const gDefaultNivelMin[] =
{
    1, 2, 3,
    1,
    1, 2, 3,
    1, 2, 3,
    1, 1, 2, 3,
    1, 2, 3,
    1,
    1, 1, 1, 1, 1, 1, 1, 1,
    1,
    1, 1,
    1, 1, 1
};

#define DEFAULT_COUNT (sizeof(gDefaultSelos))

stock Jutsu_FindDefaultById(eJutsuId:jutsuId)
{
    for(new i = 0; i < DEFAULT_COUNT; i++)
        if (gDefaultJutsuId[i] == jutsuId) return i;
    return -1;
}

// ----------------------------------------------------------
// Acesso especial (SEM switch => n?o d? erro 014)
// ----------------------------------------------------------
stock Jutsu_PlayerTemAcessoEspecial(playerid, eJutsuId:jutsuId)
{
    if (jutsuId == JID_KINOBI || jutsuId == JID_KAWARIMI) return 1;

    if (jutsuId == JID_EREMITA_SUSANO) return (Info[playerid][pSenin] > 0);
    if (jutsuId == JID_SELAMENTO)      return (Info[playerid][pProgressoDP] > 0);

    if (jutsuId == JID_IRYOU)
    {
        if(Info[playerid][pProgressoHP] >= 1
            || Info[playerid][pHPPatente] == 2 || Info[playerid][pHPPatente] == 3
            || Info[playerid][pHPPatente] == 4 || Info[playerid][pHPPatente] == 5
            || Info[playerid][pHPPatente] == 7 || Info[playerid][pHPPatente] == 8
            || Info[playerid][pHPPatente] == 9 || Info[playerid][pHPPatente] == 10) return 1;
        return 0;
    }
    if (jutsuId == JID_KATSUYU) return (Info[playerid][pProgressoHP] >= 3000 && Info[playerid][pRank] >= 2);
    if (jutsuId == JID_MESU)    return (Info[playerid][pProgressoHP] >= 7000);
    if (jutsuId == JID_URUSHI)  return (Info[playerid][pProgressoHP] >= 7000);

    if (jutsuId == JID_BARREIRA_TOGGLE) return (Info[playerid][pAnbuPatente] == 2);
    if (jutsuId == JID_SABERU)          return (Info[playerid][pProgressoDP] >= 3000);

    if (jutsuId == JID_BASE_ORO) return (Info[playerid][pBaseAcesso] != 0 && Info[playerid][pBaseAcesso] != 2);
    if (jutsuId == JID_BASE_AKA) return (Info[playerid][pBaseAcesso] != 0 && Info[playerid][pBaseAcesso] != 1);

    if (jutsuId == JID_MODO_RATO)        return (Info[playerid][pSenin] == 2 || Info[playerid][pSenin] == 4 || Info[playerid][pClan] == 5);
    if (jutsuId == JID_MODO_DRAGAO)      return (Info[playerid][pClan] == 5);
    if (jutsuId == JID_RAIJIN_VOADOR)    return (Info[playerid][pClan] == 5);

    if (jutsuId == JID_CLAN_TIGRE)       return (Info[playerid][pClan] != 0);

	//jutsu invocação do sapo
	if (jutsuId == JID_SAPO_PRISAO)	   return (Info[playerid][pRank] >= 3 && Info[playerid][pSenin] > 0);

	//KAITEN HYUGA
	if (jutsuId == JID_HAKKESHOU) return (Info[playerid][pClan] == 4);


    return 0;
}

stock Jutsu_PlayerTemAcessoByJutsuId(playerid, eJutsuId:jutsuId)
{
    if (jutsuId == JID_KINOBI || jutsuId == JID_KAWARIMI) return 1;

    new idx = Jutsu_FindDefaultById(jutsuId);
    if (idx == -1) return Jutsu_PlayerTemAcessoEspecial(playerid, jutsuId);

    new elem = gDefaultElemento[idx];
    new lvl  = gDefaultNivelMin[idx];

    if (elem == ELEM_NONE) return Jutsu_PlayerTemAcessoEspecial(playerid, jutsuId);
    return Jutsu_PlayerTemElemento(playerid, elem, lvl);
}

// ----------------------------------------------------------
// BIND cast (hotbar)
// ----------------------------------------------------------
stock Jutsu_TryCastBind(playerid, const selos[])
{
    // Seguran?a: garante que carregou do INI antes de tentar comparar
    HB_LoadBindsOnce(playerid);

    new canon[128];
    if (!HBCH_SelosCanonicalize(selos, canon, sizeof canon))
        format(canon, sizeof canon, "%s", selos);

    for(new i = 0; i < JUTSU_MAX_BINDS; i++)
    {
        if (gBindJutsu[playerid][i] == JID_INVALID) continue;

        if (!strcmp(gBindSelos[playerid][i], canon, true))
        {
            new eJutsuId:jid = gBindJutsu[playerid][i];
            if (!Jutsu_PlayerTemAcessoByJutsuId(playerid, jid))
            {
                SendClientMessage(playerid, 0xFFFFFFFF, "{EF0D02}(HOTBAR){FFFFFF} Voc? n?o tem acesso a esse jutsu ainda.");
                return 1;
            }
            return Jutsu_CastByID(playerid, jid);
        }
    }
    return 0;
}

// ----------------------------------------------------------
// PRINCIPAL: Selos.pwn chama isso (S? bind)
// ----------------------------------------------------------
stock Jutsu_CastBySelos(playerid, const selos[])
{
    if (!strlen(selos)) return 0;

    if (Jutsu_TryCastBind(playerid, selos)) return 1;

    SendClientMessage(playerid, 0xFFFFFFFF, "{EF0D02}(HOTBAR){FFFFFF} Nenhum jutsu est? alocado nessa sequ?ncia de selos.");
    return 1;
}

// ----------------------------------------------------------
// LISTA (somente os liberados)
// ----------------------------------------------------------
#if !defined DIALOG_LISTA_JUTSUS_HOTBAR
    #define DIALOG_LISTA_JUTSUS_HOTBAR (22990)
#endif

stock Jutsu_SelosToKeys(const selos[], out[], outSize)
{
    out[0] = '\0';

    new tok[16], ti = 0;
    new len = strlen(selos);

    for(new i = 0; i <= len; i++)
    {
        new ch = selos[i];

        if(ch == ',' || ch == '\0')
        {
            tok[ti] = '\0';

            if(tok[0] != '\0')
            {
                new part[8];
                part[0] = '\0';

                if(!strcmp(tok, "Tigre", false))            format(part, sizeof part, "SHIFT");
                else if(!strcmp(tok, "Drag?o", false) || !strcmp(tok, "Dragao", false)) format(part, sizeof part, "C");
                else if(!strcmp(tok, "Rato", false))        format(part, sizeof part, "H");
                else if(!strcmp(tok, "Cobra", false))       format(part, sizeof part, "N");
                else if(!strcmp(tok, "Coelho", false))      format(part, sizeof part, "Y");

                if(part[0] != '\0')
                {
                    if(out[0] != '\0') strcat(out, " ", outSize);
                    strcat(out, part, outSize);
                }
            }
            ti = 0;
        }
        else if(ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n')
        {
            if(ti < (sizeof tok - 1)) tok[ti++] = ch;
        }
    }
    return 1;
}

stock Jutsu_GetNomeById(eJutsuId:jutsuId, out[], outSize)
{
    switch(jutsuId)
    {
        case JID_GOUKAKYUU:        format(out, outSize, "Katon: Goukakyuu no Jutsu");
        case JID_HOUSENKA:         format(out, outSize, "Katon: Housenka no Jutsu");
        case JID_KARYUUENDAN:      format(out, outSize, "Katon: Karyuuendan no Jutsu");

        case JID_ARASHI_I:         format(out, outSize, "Raiton: Arashi I");
        case JID_RAIKYUU:          format(out, outSize, "Raiton: Raikyuu no Jutsu");
        case JID_NAGASHI:          format(out, outSize, "Raiton: Nagashi no Jutsu");

        case JID_MIZURAPPA:        format(out, outSize, "Suiton: Mizurappa");
        case JID_SUIKODAN:         format(out, outSize, "Suiton: Suikodan");
        case JID_SUIROU:           format(out, outSize, "Suiton: Suirou");

        case JID_RASENGAN:         format(out, outSize, "Futon: Espiral de Vento");
        case JID_HANACHI:          format(out, outSize, "Futon: Hanachi");
        case JID_SHINKUHA:         format(out, outSize, "Futon: Shinkuha");
        case JID_ATSUGAI:          format(out, outSize, "Futon: Atsugai");

        case JID_IWAKAI:           format(out, outSize, "Doton: Impacto Rochoso");
        case JID_DORYUUHEKI:       format(out, outSize, "Doton: Montanha Rochosa");
        case JID_DOROJIGOKU:       format(out, outSize, "Doton: Pris?o de Lama");

        case JID_EREMITA_SUSANO:   format(out, outSize, "Eremita: Susano");
        case JID_SELAMENTO:        format(out, outSize, "Jikuu: Selamento");

        case JID_IRYOU:            format(out, outSize, "Iryou: Cura");
        case JID_KATSUYU:          format(out, outSize, "Iryou: Kuchiyose Katsuyu");
        case JID_MESU:             format(out, outSize, "Iryou: Chakra no Mesu");
        case JID_URUSHI:           format(out, outSize, "Iryou: Urushi");

        case JID_BARREIRA_TOGGLE:  format(out, outSize, "Anbu: Barreira");
        case JID_SABERU:           format(out, outSize, "Chakra: Saberu");
        case JID_KINOBI:           format(out, outSize, "Chakra: Kinobori (andar na ?gua)");
        case JID_KAWARIMI:         format(out, outSize, "Substitui??o: Kawarimi");

        case JID_BASE_ORO:         format(out, outSize, "Base: Orochimaru");
        case JID_BASE_AKA:         format(out, outSize, "Base: Akatsuki");

        case JID_MODO_RATO:        format(out, outSize, "Modo: Rato");
        case JID_MODO_DRAGAO:      format(out, outSize, "Modo: Drag?o");
        case JID_RAIJIN_VOADOR:    format(out, outSize, "Hiraishin: Raijin Voador");

		//KAITEN HYUUGA
		case JID_HAKKESHOU:		format(out, outSize, "Hyuuga: Hakkeshou Kaiten no Jutsu");

        case JID_CLAN_TIGRE:       format(out, outSize, "Cl?: Jutsu do cl?");
        default:                   format(out, outSize, "Jutsu %d", _:jutsuId);
    }
    return 1;
}

stock Jutsu_DefaultTemAcesso(playerid, idx)
{
    if(idx < 0 || idx >= DEFAULT_COUNT) return 0;

    new elem = gDefaultElemento[idx];
    new lvl  = gDefaultNivelMin[idx];
    new eJutsuId:jid = gDefaultJutsuId[idx];

    if(elem == ELEM_NONE) return Jutsu_PlayerTemAcessoEspecial(playerid, jid);
    return Jutsu_PlayerTemElemento(playerid, elem, lvl);
}

stock Jutsu_AppendCategoria(playerid, list[], listSize, const titulo[], especial, categoria)
{
    gHB_CatBuf[0] = '\0';

    for(new i = 0; i < DEFAULT_COUNT; i++)
    {
        if(!Jutsu_DefaultTemAcesso(playerid, i)) continue;

        if(!especial)
        {
            if(gDefaultElemento[i] != categoria) continue;
        }
        else
        {
            new eJutsuId:jid = gDefaultJutsuId[i];
            new grp = 0;

            if(jid == JID_EREMITA_SUSANO || jid == JID_SELAMENTO || jid == JID_SABERU || jid == JID_KINOBI || jid == JID_KAWARIMI) grp = 1;
            else if(jid == JID_IRYOU || jid == JID_KATSUYU || jid == JID_MESU || jid == JID_URUSHI) grp = 2;
            else if(jid == JID_BARREIRA_TOGGLE) grp = 3;
            else if(jid == JID_BASE_ORO || jid == JID_BASE_AKA) grp = 4;
            else if(jid == JID_MODO_RATO || jid == JID_MODO_DRAGAO || jid == JID_RAIJIN_VOADOR) grp = 5;
            else if(jid == JID_CLAN_TIGRE || jid == JID_HAKKESHOU) grp = 6;


            if(grp != categoria) continue;
        }

        new nome[80], keys[64], line[200];
        Jutsu_GetNomeById(gDefaultJutsuId[i], nome, sizeof nome);
        Jutsu_SelosToKeys(gDefaultSelos[i], keys, sizeof keys);

        if(keys[0] != '\0') format(line, sizeof line, "{FFFFFF}- %s {AAAAAA}(%s)\n", nome, keys);
        else               format(line, sizeof line, "{FFFFFF}- %s\n", nome);

        strcat(gHB_CatBuf, line, sizeof gHB_CatBuf);
    }

    if(gHB_CatBuf[0] != '\0')
    {
        strcat(list, titulo, listSize);
        strcat(list, "\n", listSize);
        strcat(list, gHB_CatBuf, listSize);
        strcat(list, "\n", listSize);
    }
    return 1;
}

stock Jutsu_ShowListaJutsus(playerid)
{
    gHB_ListBuf[0] = '\0';

    strcat(gHB_ListBuf, "{FFD400}Selos: {FFFFFF}Tigre=SHIFT | Drag?o=C | Rato=H | Cobra=N | Coelho=Y\n\n", sizeof gHB_ListBuf);

    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{FF5A4E}Katon", 0, ELEM_KATON);
    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{9B7CFF}Raiton", 0, ELEM_RAITON);
    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{4EC5FF}Suiton", 0, ELEM_SUITON);
    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{9BE35A}Futon", 0, ELEM_FUTON);
    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{C9A06A}Doton", 0, ELEM_DOTON);

    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{FFFFFF}Especiais", 1, 1);
    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{E9FE23}Iryou", 1, 2);
    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{C2A2DA}Anbu", 1, 3);
    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{BDBDBD}Bases", 1, 4);
    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{BDBDBD}Modos", 1, 5);
    Jutsu_AppendCategoria(playerid, gHB_ListBuf, sizeof gHB_ListBuf, "{BDBDBD}Cl?", 1, 6);

    // nunca retorna 0 (pra ZCMD n?o dizer "comando n?o existe")
    if(gHB_ListBuf[0] == '\0')
    {
        SendClientMessage(playerid, -1, "Voc? n?o tem jutsus dispon?veis para listar.");
        return 1;
    }

    ShowPlayerDialog(playerid, DIALOG_LISTA_JUTSUS_HOTBAR, DIALOG_STYLE_MSGBOX,
        "Seus Jutsus (somente os liberados)", gHB_ListBuf, "Fechar", "");
    return 1;
}



#endif // _HBPREP_INC