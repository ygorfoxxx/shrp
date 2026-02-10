// =============================================================================
//  Shinobi Roleplay (SHRP) - Limites de Atributos + Trilhas de Treino (Basico/Inter/Avancado)
//  Arquivo: Includes/Perfil/limiteatributos.pwn
//
//  O que este include faz:
//    - Limita o UP de Vida/Chakra/Tai/Nin/Ken/Gen pelo seu pRank (Aluno/Genin/Chunin/Jounin)
//    - Adiciona o sistema de "Treinos":
//        * Basico   = cap 70
//        * Inter    = cap 120
//        * Avancado = cap 170
//
//      Regras (do seu pedido):
//        - Sem treino avancado: pode ter ATE 2 treinos intermediarios.
//        - Com treino avancado: pode ter SOMENTE 1 treino intermediario (o outro vira basico).
//        - O atributo "avancado" sempre pode ir ate 170 (apenas quando Jounin).
//        - O atributo "intermediario" pode ir ate 120 (a partir de Chunin).
//        - O resto fica em basico (70) ou aluno (40), conforme rank.
//
//  Dependencias esperadas no seu gamemode:
//    - Info[playerid][pRank], Info[playerid][pPuntosNinja]
//    - Info[playerid][pHealthMaximo] (Float), Info[playerid][pChakra] (Float)
//    - Info[playerid][pTaijutsu], Info[playerid][pNinjutsu], Info[playerid][pKenjutsu], Info[playerid][pGenjutsu]
//    - BtnUparStats[playerid][0..5]
//    - MostrarStatus(playerid) e CarregarStatus(playerid)
//
//  NOVO: precisa adicionar 3 campos no seu enum PlayerData (Info):
//    - pTreinoInter1   (int)  // id do atributo escolhido como INTER 1  (ou -1)
//    - pTreinoInter2   (int)  // id do atributo escolhido como INTER 2  (ou -1)
//    - pTreinoAvancado (int)  // id do atributo escolhido como AVANCADO (ou -1)
//
//  IDs de atributo (treino) usados pelo include:
//    LA_ATTR_TAI = 1 | LA_ATTR_NIN = 2 | LA_ATTR_KEN = 3 | LA_ATTR_GEN = 4
//    (Vida/Chakra NAO usam treino: eles so seguem cap por rank; voce pode mudar os caps abaixo.)
//
//  Como integrar:
//    1) Coloque este arquivo em: Includes/Perfil/limiteatributos.pwn  (ANSI)
//    2) No gamemode, adicione:
//         #include "Includes/Perfil/limiteatributos.pwn"
//       depois do enum Info[] e das variaveis BtnUparStats.
//    3) Substitua sua funcao AoClicarNoStatsUp por:
//         AoClicarNoStatsUp(playerid, PlayerText:playertextid)
//             return LimiteAtributos_OnClick(playerid, playertextid);
//    4) Garanta que seus saves/loads carreguem/salvem pTreinoInter1/2 e pTreinoAvancado.
//
// =============================================================================

#if defined _SHRP_LIMITE_ATRIBUTOS_
    #endinput
#endif
#define _SHRP_LIMITE_ATRIBUTOS_

// -----------------------------------------------------------------------------
// CONFIG RAPIDA
// -----------------------------------------------------------------------------


// 0 = recomendado: nao permite passar do cap (cap "duro")
// 1 = legado: permite passar +1 antes de bloquear (nao recomendado)
#if !defined LA_MODO_LEGADO_PLUS1
    #define LA_MODO_LEGADO_PLUS1 (0)
#endif

// Mensagens
#if !defined LA_MSG_SEM_PONTOS
    #define LA_MSG_SEM_PONTOS "(AVISO) Voce nao tem mais pontos suficientes."
#endif
#if !defined LA_MSG_MAX_TEXTO
    #define LA_MSG_MAX_TEXTO "(AVISO) Voce nao consegue mais colocar pontos em (%s)."
#endif

// -----------------------------------------------------------------------------
// RANK (pRank)
// 0 = Aluno | 1 = Genin | 2 = Chunin | 3 = Jounin
// -----------------------------------------------------------------------------
#define LA_RANK_ALUNO  (0)
#define LA_RANK_GENIN  (1)
#define LA_RANK_CHUNIN (2)
#define LA_RANK_JOUNIN (3)

// -----------------------------------------------------------------------------
// TREINOS (caps)
// -----------------------------------------------------------------------------
#define LA_CAP_ALUNO   (40)
#define LA_CAP_BASICO  (70)
#define LA_CAP_INTER   (120)
#define LA_CAP_AVANC   (170)

// -----------------------------------------------------------------------------
// IDS DE ATRIBUTOS (TREINO)
// -----------------------------------------------------------------------------
#define LA_TREINO_NONE (-1)

#define LA_ATTR_TAI (1)
#define LA_ATTR_NIN (2)
#define LA_ATTR_KEN (3)
#define LA_ATTR_GEN (4)

// -----------------------------------------------------------------------------
// LIMITES VIDA/CHAKRA (por rank)
//  - Por padrao estou seguindo a mesma tabela 40/70/120/170.
//  - Se voce quiser que seja ilimitado, coloque um numero MUITO alto (ex: 9999.0).
// -----------------------------------------------------------------------------
#if !defined LA_VIDA_MAX_ALUNO
    #define LA_VIDA_MAX_ALUNO   (9999.0)
#endif
#if !defined LA_VIDA_MAX_GENIN
    #define LA_VIDA_MAX_GENIN   (9999.0)
#endif
#if !defined LA_VIDA_MAX_CHUNIN
    #define LA_VIDA_MAX_CHUNIN  (9999.0)
#endif
#if !defined LA_VIDA_MAX_JOUNIN
    #define LA_VIDA_MAX_JOUNIN  (9999.0)
#endif

#if !defined LA_CHAKRA_MAX_ALUNO
    #define LA_CHAKRA_MAX_ALUNO  (25.0)
#endif
#if !defined LA_CHAKRA_MAX_GENIN
    #define LA_CHAKRA_MAX_GENIN  (60.0)
#endif
#if !defined LA_CHAKRA_MAX_CHUNIN
    #define LA_CHAKRA_MAX_CHUNIN (120.0)
#endif
#if !defined LA_CHAKRA_MAX_JOUNIN
    #define LA_CHAKRA_MAX_JOUNIN (170.0)
#endif

// -----------------------------------------------------------------------------
// HELPERS
// -----------------------------------------------------------------------------
stock LA_SendSemPontos(playerid)
{
    SendClientMessage(playerid, -1, LA_MSG_SEM_PONTOS);
    if(Info[playerid][pPuntosNinja] < 0) Info[playerid][pPuntosNinja] = 0;
}

stock bool:LA_TentarGastarPonto(playerid)
{
    if(Info[playerid][pPuntosNinja] < 1)
    {
        LA_SendSemPontos(playerid);
        Info[playerid][pPuntosNinja] = 0;
        return false;
    }
    Info[playerid][pPuntosNinja] -= 1;
    if(Info[playerid][pPuntosNinja] < 0) Info[playerid][pPuntosNinja] = 0;
    return true;
}

stock LA_SendMaxMsg(playerid, const nomeAttr[])
{
    new s[128];
    format(s, sizeof(s), LA_MSG_MAX_TEXTO, nomeAttr);
    SendClientMessage(playerid, -1, s);
}

stock bool:LA_AtCapFloat(Float:atual, Float:cap)
{
    if(LA_MODO_LEGADO_PLUS1) return (atual > cap);
    return (atual >= cap);
}

stock bool:LA_AtCapInt(atual, cap)
{
    if(LA_MODO_LEGADO_PLUS1) return (atual > cap);
    return (atual >= cap);
}

// -----------------------------------------------------------------------------
// CAP POR RANK (vida/chakra)
// -----------------------------------------------------------------------------
stock Float:LA_GetVidaMaxPorRank(playerid)
{
    switch(Info[playerid][pRank])
    {
        case LA_RANK_ALUNO:  return LA_VIDA_MAX_ALUNO;
        case LA_RANK_GENIN:  return LA_VIDA_MAX_GENIN;
        case LA_RANK_CHUNIN: return LA_VIDA_MAX_CHUNIN;
        case LA_RANK_JOUNIN: return LA_VIDA_MAX_JOUNIN;
    }
    return LA_VIDA_MAX_GENIN;
}

stock Float:LA_GetChakraMaxPorRank(playerid)
{
    switch(Info[playerid][pRank])
    {
        case LA_RANK_ALUNO:  return LA_CHAKRA_MAX_ALUNO;
        case LA_RANK_GENIN:  return LA_CHAKRA_MAX_GENIN;
        case LA_RANK_CHUNIN: return LA_CHAKRA_MAX_CHUNIN;
        case LA_RANK_JOUNIN: return LA_CHAKRA_MAX_JOUNIN;
    }
    return LA_CHAKRA_MAX_GENIN;
}

// -----------------------------------------------------------------------------
// CAP EFETIVO POR TREINO (Tai/Nin/Ken/Gen)
// -----------------------------------------------------------------------------

// Base por rank: Aluno=40, demais=70 (o resto sobe via treino)
stock LA_GetCapBasePorRank(playerid)
{
    if(Info[playerid][pRank] <= LA_RANK_ALUNO) return LA_CAP_ALUNO;
    return LA_CAP_BASICO;
}

// Quando existe treino avancado, so 1 intermediario continua valendo.
// Escolha do intermediario efetivo:
//   - usa pTreinoInter1 se valido; senao usa pTreinoInter2; senao none.
stock LA_GetInterEfetivo(playerid)
{
    if(Info[playerid][pTreinoInter1] != LA_TREINO_NONE) return Info[playerid][pTreinoInter1];
    if(Info[playerid][pTreinoInter2] != LA_TREINO_NONE) return Info[playerid][pTreinoInter2];
    return LA_TREINO_NONE;
}

stock bool:LA_IsInter(playerid, attrId)
{
    if(attrId == LA_TREINO_NONE) return false;

    // Inter so vale a partir de Chunin
    if(Info[playerid][pRank] < LA_RANK_CHUNIN) return false;

    // Com avancado setado: so 1 inter continua valendo
    if(Info[playerid][pTreinoAvancado] != LA_TREINO_NONE)
    {
        return (LA_GetInterEfetivo(playerid) == attrId);
    }

    // Sem avancado: pode ter ate 2 inter
    return (Info[playerid][pTreinoInter1] == attrId || Info[playerid][pTreinoInter2] == attrId);
}

stock bool:LA_IsAvancado(playerid, attrId)
{
    if(attrId == LA_TREINO_NONE) return false;

    // Avancado so vale quando Jounin
    if(Info[playerid][pRank] < LA_RANK_JOUNIN) return false;

    return (Info[playerid][pTreinoAvancado] == attrId);
}

// Cap final do atributo por treino + rank
stock LA_GetCapPorTreino(playerid, attrId)
{
    new cap = LA_GetCapBasePorRank(playerid);

    if(LA_IsAvancado(playerid, attrId)) return LA_CAP_AVANC;
    if(LA_IsInter(playerid, attrId))    return LA_CAP_INTER;

    return cap;
}

// -----------------------------------------------------------------------------
// MAPEAMENTO: pegar attrId a partir do "botao" clicado
// -----------------------------------------------------------------------------
stock LA_AttrIdFromButton(playerid, PlayerText:playertextid)
{
    // BtnUparStats indices:
    // 0 Vida | 1 Chakra | 2 Taijutsu | 3 Ninjutsu | 4 Kenjutsu | 5 Genjutsu
    if(playertextid == BtnUparStats[playerid][2]) return LA_ATTR_TAI;
    if(playertextid == BtnUparStats[playerid][3]) return LA_ATTR_NIN;
    if(playertextid == BtnUparStats[playerid][4]) return LA_ATTR_KEN;
    if(playertextid == BtnUparStats[playerid][5]) return LA_ATTR_GEN;
    return LA_TREINO_NONE;
}

stock LA_NameByAttr(attrId, dest[], destSize)
{
    switch(attrId)
    {
        case LA_ATTR_TAI: format(dest, destSize, "Taijutsu");
        case LA_ATTR_NIN: format(dest, destSize, "Ninjutsu");
        case LA_ATTR_KEN: format(dest, destSize, "Kenjutsu");
        case LA_ATTR_GEN: format(dest, destSize, "Genjutsu");
        default: format(dest, destSize, "Atributo");
    }
    return 1;
}

// -----------------------------------------------------------------------------
// UPS
// -----------------------------------------------------------------------------
stock bool:LA_UpVida(playerid)
{
    if(!LA_TentarGastarPonto(playerid)) return false;

    new Float:cap = LA_GetVidaMaxPorRank(playerid);
    if(LA_AtCapFloat(Info[playerid][pHealthMaximo], cap))
    {
        Info[playerid][pPuntosNinja] += 1;
        LA_SendMaxMsg(playerid, "Vida");
        return false;
    }

    Info[playerid][pHealthMaximo] += 10.0;
    if(!LA_MODO_LEGADO_PLUS1 && Info[playerid][pHealthMaximo] > cap) Info[playerid][pHealthMaximo] = cap;

    MostrarStatus(playerid);
    CarregarStatus(playerid);
    return true;
}

stock bool:LA_UpChakra(playerid)
{
    if(!LA_TentarGastarPonto(playerid)) return false;

    new Float:cap = LA_GetChakraMaxPorRank(playerid);
    if(LA_AtCapFloat(Info[playerid][pChakra], cap))
    {
        Info[playerid][pPuntosNinja] += 1;
        LA_SendMaxMsg(playerid, "Chakra");
        return false;
    }

    Info[playerid][pChakra] += 10.0;
    if(!LA_MODO_LEGADO_PLUS1 && Info[playerid][pChakra] > cap) Info[playerid][pChakra] = cap;

    MostrarStatus(playerid);
    CarregarStatus(playerid);
    return true;
}

stock bool:LA_UpSkillInt(playerid, attrId)
{
    new cap = LA_GetCapPorTreino(playerid, attrId);
    if(!LA_TentarGastarPonto(playerid)) return false;

    new atual;
    switch(attrId)
    {
        case LA_ATTR_TAI: atual = Info[playerid][pTaijutsu];
        case LA_ATTR_NIN: atual = Info[playerid][pNinjutsu];
        case LA_ATTR_KEN: atual = Info[playerid][pKenjutsu];
        case LA_ATTR_GEN: atual = Info[playerid][pGenjutsu];
        default:
        {
            Info[playerid][pPuntosNinja] += 1;
            return false;
        }
    }

    if(LA_AtCapInt(atual, cap))
    {
        new nm[24];
        LA_NameByAttr(attrId, nm, sizeof(nm));
        Info[playerid][pPuntosNinja] += 1;
        LA_SendMaxMsg(playerid, nm);
        return false;
    }

    switch(attrId)
    {
        case LA_ATTR_TAI: Info[playerid][pTaijutsu] += 1;
        case LA_ATTR_NIN: Info[playerid][pNinjutsu] += 1;
        case LA_ATTR_KEN: Info[playerid][pKenjutsu] += 1;
        case LA_ATTR_GEN: Info[playerid][pGenjutsu] += 1;
    }

    if(!LA_MODO_LEGADO_PLUS1)
    {
        switch(attrId)
        {
            case LA_ATTR_TAI: if(Info[playerid][pTaijutsu] > cap) Info[playerid][pTaijutsu] = cap;
            case LA_ATTR_NIN: if(Info[playerid][pNinjutsu] > cap) Info[playerid][pNinjutsu] = cap;
            case LA_ATTR_KEN: if(Info[playerid][pKenjutsu] > cap) Info[playerid][pKenjutsu] = cap;
            case LA_ATTR_GEN: if(Info[playerid][pGenjutsu] > cap) Info[playerid][pGenjutsu] = cap;
        }
    }

    MostrarStatus(playerid);
    CarregarStatus(playerid);
    return true;
}

// -----------------------------------------------------------------------------
// ENTRADA UNICA: CHAMAR NO SEU AoClicarNoStatsUp
// -----------------------------------------------------------------------------
stock LimiteAtributos_OnClick(playerid, PlayerText:playertextid)
{
    if(playertextid == BtnUparStats[playerid][0]) return LA_UpVida(playerid);
    if(playertextid == BtnUparStats[playerid][1]) return LA_UpChakra(playerid);

    new attrId = LA_AttrIdFromButton(playerid, playertextid);
    if(attrId != LA_TREINO_NONE) return LA_UpSkillInt(playerid, attrId);

    return 0;
}

// -----------------------------------------------------------------------------
// API OPCIONAL (para sua Academia / Sensei usar depois)
// -----------------------------------------------------------------------------
stock LA_ClearTreinos(playerid)
{
    Info[playerid][pTreinoInter1]   = LA_TREINO_NONE;
    Info[playerid][pTreinoInter2]   = LA_TREINO_NONE;
    Info[playerid][pTreinoAvancado] = LA_TREINO_NONE;
    return 1;
}

stock LA_SetTreinoInter1(playerid, attrId)   { Info[playerid][pTreinoInter1] = attrId; return 1; }
stock LA_SetTreinoInter2(playerid, attrId)   { Info[playerid][pTreinoInter2] = attrId; return 1; }
stock LA_SetTreinoAvancado(playerid, attrId) { Info[playerid][pTreinoAvancado] = attrId; return 1; }