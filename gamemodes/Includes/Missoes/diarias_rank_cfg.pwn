#if defined _SHRP_DAILY_CFG_INCLUDED
    #endinput
#endif
#define _SHRP_DAILY_CFG_INCLUDED

// ================================================================
// SHRP - Quadro de Missoes Diarias (Rank + TXD)
// Arquivo: diarias_rank_cfg.pwn
//
// Edite SOMENTE aqui para personalizar:
//  - Limites diarios por rank
//  - Recompensas base
//  - Requisitos (Genin/Chunin/Jounin/ANBU/Kage ou Fama)
//  - Penalidades (morte/quit)
//  - Posicoes dos provedores (Quadro/Sensei/Kage) por vila
//  - Pool de missoes (templates) por rank
//
// Observacao importante:
//  - Este sistema usa offsets relativos ao "provedor" (quadro/sensei/kage).
//    Isso deixa tudo configuravel por vila: basta posicionar o provedor.
//  - Para vilas em borda do mapa (ex.: Kiri), use dpScale menor.
// ================================================================

// ------------------------------
// Ranks
// ------------------------------
#define DR_MAX (6)
#define DR_E (0)
#define DR_D (1)
#define DR_C (2)
#define DR_B (3)
#define DR_A (4)
#define DR_S (5)

// ------------------------------
// Provedor / origem das missoes
// ------------------------------
#define DP_BOARD  (1) // quadro/academia
#define DP_SENSEI (2) // sensei/diretor
#define DP_KAGE   (3) // kage

// Quais ranks cada provedor pode oferecer:
#define DAILY_PROVIDER_MASK_BOARD  ( (1<<DR_E) | (1<<DR_D) )
#define DAILY_PROVIDER_MASK_SENSEI ( (1<<DR_C) | (1<<DR_B) )
#define DAILY_PROVIDER_MASK_KAGE   ( (1<<DR_E) | (1<<DR_D) | (1<<DR_C) | (1<<DR_B) | (1<<DR_A) | (1<<DR_S) )

// ------------------------------
// Limites diarios por rank
// ------------------------------
new const gDailyLimit[DR_MAX] = { 
    5,  // Rank E
    12, // Rank D
    9,  // Rank C
    5,  // Rank B
    2,  // Rank A
    1   // Rank S
};

// ------------------------------
// Recompensas base por rank
// (Cada missao pode sobrescrever; se 0, usa base)
// ------------------------------
new const gDailyBaseRyos[DR_MAX] = { 200, 400, 800, 1500, 3000, 6000 };
new const gDailyBaseXP[DR_MAX]   = { 150, 300, 650, 1150, 2100, 4200 };
new const gDailyBaseFama[DR_MAX] = { 1, 2, 4, 6, 10, 18 };
new const gDailyBaseOp[DR_MAX]   = { 1, 1, 2, 3, 4, 6 };

// ------------------------------
// Requisitos (graduacao / fama)
// Por padrao usamos Info[playerid][pRank] como graduacao.
// Ajuste os thresholds pra bater com seu servidor.
// Exemplo comum:
// 0=Academia, 1=Genin, 2=Chunin, 3=Tokubetsu, 4=Jounin, 5=ANBU, 6=Kage
// ------------------------------
#define DAILY_REQ_D_PRANK (0) // Genin
#define DAILY_REQ_C_PRANK (2) // Chunin
#define DAILY_REQ_B_PRANK (2) // Chunin
#define DAILY_REQ_A_PRANK (4) // Jounin
#define DAILY_REQ_S_PRANK (5) // ANBU (ou Kage >= 6)

#define DAILY_ALLOW_S_BY_FAMA (1)
// Se DAILY_ALLOW_S_BY_FAMA=1, Rank S libera se NinjaFamaRank >= valor abaixo:
#define DAILY_REQ_S_FAMA_RANK (7) // Lendario (ajuste)

// Permissao especial (edite para ANBU/Kage/etc)
#define DAILY_HAS_SPECIAL_S(%0) (Info[%0][pRank] >= 5)
#define DAILY_HAS_SPECIAL_A(%0) (Info[%0][pRank] >= 4)

// Precisa ter passado a missao da academia para usar o quadro (DP_BOARD):
#define DAILY_CAN_USE_BOARD(%0) (Daily_AcaIsDone(%0) == 1)

// ------------------------------
// Reset diario (America/Sao_Paulo)
// ------------------------------
#define DAILY_TZ_OFFSET_SEC (-3*3600) // Brasil (sem DST)

// ------------------------------
// Falha/penalidade (morte/quit)
//  - DAILY_PEN_MODE 1: consome 1 tentativa do rank do dia (incrementa done)
//  - DAILY_PEN_MODE 2: aplica cooldown no rank (DAILY_PEN_COOLDOWN_MIN)
// ------------------------------
#define DAILY_FAIL_ON_DEATH (1)
#define DAILY_FAIL_ON_QUIT  (1)

#define DAILY_PEN_MODE (2)
#define DAILY_PEN_COOLDOWN_MIN (50)

// ------------------------------
// Anti-burla
// ------------------------------
#define DAILY_HOLD_MIN (2) // segundos minimo dentro do CP
#define DAILY_HOLD_MAX (4) // maximo (se a missao pedir 0, sorteia 2-4)

#define DAILY_MAX_STEP_DIST (120.0) // metros por tick (1s). Acima disso = suspeito.
#define DAILY_BLOCK_ON_SUSPECT (0)  // 1 = bloqueia recompensa se suspeito

// Minimos por rank (tempo/distancia)
new const gDailyMinTime[DR_MAX] = { 60, 120, 180, 240, 300, 360 };
new const Float:gDailyMinDist[DR_MAX] = { 120.0, 220.0, 300.0, 380.0, 480.0, 600.0 };

// ------------------------------
// Objetos / pickups / 3DText
// ------------------------------
#define DAILY_BOARD_OBJ_MODEL (19482)
#define DAILY_BOARD_PICKUP    (1239)

// Controle visual dos provedores (quadro/sensei/kage).
// Como voce ja tem NPC no local, por padrao deixamos DESLIGADO para nao aparecer:
//  - objeto (placa)
//  - pickup (icone girando)
//  - 3DText ("aperte ...")
//
// Se algum dia voce quiser ver a placa/icone, coloque 1.
#define DAILY_PROVIDER_SPAWN_OBJECT (0)
#define DAILY_PROVIDER_SPAWN_PICKUP (0)
#define DAILY_PROVIDER_SPAWN_3DTEXT (0)



// ------------------------------
// Fallback de coordenadas da academia (caso o include AcaM1 nao esteja acima)
// ------------------------------
#if !defined ACA_M1_INS_IWA_X
    #define ACA_M1_INS_IWA_X (-1824.5000)
    #define ACA_M1_INS_IWA_Y (1882.3000)
    #define ACA_M1_INS_IWA_Z (2.0700)
    #define ACA_M1_INS_KIRI_X (2830.6000)
    #define ACA_M1_INS_KIRI_Y (-2433.5000)
    #define ACA_M1_INS_KIRI_Z (29.7000)
    #define ACA_M1_ENT_IWA_X (-1819.1000)
    #define ACA_M1_ENT_IWA_Y (1863.1000)
    #define ACA_M1_ENT_IWA_Z (2.0700)
    #define ACA_M1_ENT_KIRI_X (2811.5000)
    #define ACA_M1_ENT_KIRI_Y (-2432.3000)
    #define ACA_M1_ENT_KIRI_Z (29.6000)
#endif

// ------------------------------
// Posicoes dos provedores (por vila)
// dpScale: multiplicador de offsets das missoes.
//  - Para vilas perto da borda do mapa, use dpScale menor.
// ------------------------------
enum eDailyProvPos { dpType, dpVila, Float:dpX, Float:dpY, Float:dpZ, Float:dpA, Float:dpScale };

// VilaId sugerido: 1=Iwa, 2=Kiri (edite se quiser mais vilas)
// VilaId sugerido: 1=Iwa, 2=Kiri (edite se quiser mais vilas)
//
// IMPORTANTE (compilacao Pawno 0.3.DL):
//  - Nao use operacoes (+/-) dentro de inicializadores const.
//  - Por isso, os provedores sao montados em runtime no init.
#define DAILY_PROV_MAX (6)

new gDailyProvPos[DAILY_PROV_MAX][eDailyProvPos];
new gDailyProvCount = 0;

stock DailyCfg_AddProv(type, vila, Float:x, Float:y, Float:z, Float:a, Float:scale)
{
    new i = gDailyProvCount;
    if(i >= DAILY_PROV_MAX) return 0;

    gDailyProvPos[i][dpType]  = type;
    gDailyProvPos[i][dpVila]  = vila;
    gDailyProvPos[i][dpX]     = x;
    gDailyProvPos[i][dpY]     = y;
    gDailyProvPos[i][dpZ]     = z;
    gDailyProvPos[i][dpA]     = a;
    gDailyProvPos[i][dpScale] = scale;

    gDailyProvCount++;
    return 1;
}

// Chame isso 1x no Daily_Init()
stock DailyCfg_InitProviders()
{
    gDailyProvCount = 0;

    // IWA - quadro (academia)
    DailyCfg_AddProv(DP_BOARD,  1, ACA_M1_INS_IWA_X,  ACA_M1_INS_IWA_Y,  ACA_M1_INS_IWA_Z,  90.0, 1.00);

    // KIRI - quadro (academia) -> escala menor por estar perto do limite do mapa
    DailyCfg_AddProv(DP_BOARD,  2, ACA_M1_INS_KIRI_X, ACA_M1_INS_KIRI_Y, ACA_M1_INS_KIRI_Z, 180.0, 0.35);

    // Sensei / diretor (AJUSTE PARA SUA POSICAO REAL)
    // Dica: deixe perto do quadro, ou na sala do diretor.
    DailyCfg_AddProv(DP_SENSEI, 1, (ACA_M1_INS_IWA_X  + 3.0), (ACA_M1_INS_IWA_Y  + 2.0), ACA_M1_INS_IWA_Z,  45.0, 1.00);
    DailyCfg_AddProv(DP_SENSEI, 2, (ACA_M1_INS_KIRI_X + 3.0), (ACA_M1_INS_KIRI_Y + 2.0), ACA_M1_INS_KIRI_Z,  45.0, 0.35);

    // Kage (AJUSTE!)
    DailyCfg_AddProv(DP_KAGE,   1, (ACA_M1_ENT_IWA_X  + 25.0), (ACA_M1_ENT_IWA_Y  + 20.0), (ACA_M1_ENT_IWA_Z  + 1.0), 0.0, 1.00);
    DailyCfg_AddProv(DP_KAGE,   2, (ACA_M1_ENT_KIRI_X + 25.0), (ACA_M1_ENT_KIRI_Y + 20.0), (ACA_M1_ENT_KIRI_Z + 1.0), 0.0, 0.35);

    return 1;
}

// ------------------------------
// Tipos de missao
// ------------------------------
#define DMT_DELIVERY (1)
#define DMT_INVEST   (2)
#define DMT_PATROL   (3)
#define DMT_PVE      (4)
#define DMT_ESCORT   (5)
#define DMT_RESCUE   (6)
#define DMT_BOSS     (7)

// ------------------------------
// Definicao (template) de missao
// ATENCAO:
// - As posicoes sao OFFSETS relativos ao provedor.
// - O sistema calcula: pos = origem + offset * dpScale
//
// Campos mais usados por tipo:
//  DELIVERY: P1=pegar, P2=entregar
//  INVEST:   P1,P2,P3=investigar
//  PATROL:   P1..P4 (dmNeed=qtde pontos)
//  PVE:      Area + Radius, dmNeed=kills, dmNpcSkin
//  ESCORT:   P1=start, P2..P4=rota (dmNeed=qtde pontos da rota), dmObjModel
//  RESCUE:   P1..P4=possiveis spots (dmNeed=qtde spots), Area=safe point, dmNpcSkin=refem
//  BOSS:     P1..P3=selos, P4=boss spawn, dmNpcSkin=boss
//
// Recompensas (dmRyos/dmXP/dmFama/dmOp):
// - Se 0, usa base do rank.
// ------------------------------
enum eDailyMDef
{
    dmRank,
    dmType,
    dmName[64],
    dmDesc[260],
    dmHold,          // segundos (0 = random 2-4)
    dmMinTime,       // segundos (0 = rank default)
    Float:dmMinDist, // metros (0.0 = rank default)
    dmNeed,          // kills OU spots OU pontos rota (depende do tipo)
    dmNpcSkin,       // PVE/boss/hostage
    dmObjModel,      // escort object
    Float:dmP1x, Float:dmP1y, Float:dmP1z,
    Float:dmP2x, Float:dmP2y, Float:dmP2z,
    Float:dmP3x, Float:dmP3y, Float:dmP3z,
    Float:dmP4x, Float:dmP4y, Float:dmP4z,
    Float:dmAreaX, Float:dmAreaY, Float:dmAreaZ,
    Float:dmRadius,
    dmRyos, dmXP, dmFama, dmOp
};

new const gDailyMissions[][eDailyMDef] =
{
    // ============================================================
    // RANK E (6 missoes)
    // ============================================================
    { DR_E, DMT_DELIVERY,
      "Entrega: Pergaminho de Aula",
      "Pegue o pergaminho na sala de arquivos e entregue no patio para registrar sua presenca.",
      3, 0, 0.0, 0, 0, 0,
      30.0, 18.0, 0.0,   -34.0, 22.0, 0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_E, DMT_INVEST,
      "Inspecao: Equipamentos de Treino",
      "Verifique tres pontos do patio e confirme se os equipamentos estao seguros antes do treino comecar.",
      2, 0, 0.0, 0, 0, 0,
      24.0, 42.0, 0.0,   -16.0, 36.0, 0.0,   -44.0, 10.0, 0.0,   0.0,0.0,0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_E, DMT_PATROL,
      "Patrulha: Muro da Academia",
      "Faca uma ronda curta no perimetro da academia. Quatro pontos, sem correr de um para o outro.",
      2, 0, 0.0, 4, 0, 0,
      60.0,  0.0, 0.0,   60.0, 40.0, 0.0,   -60.0, 40.0, 0.0,   -60.0, 0.0, 0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_E, DMT_RESCUE,
      "Busca: Aluno Perdido",
      "Um aluno sumiu durante o treino. Procure em possiveis pontos e leve-o para a area segura da academia.",
      3, 0, 0.0, 4, 120, 0,
      42.0, 54.0, 0.0,   -30.0, 55.0, 0.0,   -55.0, 15.0, 0.0,   20.0, -40.0, 0.0,
      0.0, 0.0, 0.0, 6.0,
      0,0,0,0 },

    { DR_E, DMT_ESCORT,
      "Escolta: Novato Ate o Portao",
      "Um novato esta nervoso. Escolte o percurso ate o portao. Se afastar demais, a missao falha.",
      0, 0, 0.0, 3, 0, 1271,
      0.0, 5.0, 0.0,   50.0, 0.0, 0.0,   80.0, 20.0, 0.0,   110.0, 0.0, 0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_E, DMT_PVE,
      "Treino: Derrubar Bonecos",
      "Treino supervisionado. Derrube os alvos (bonecos) marcados na area indicada.",
      0, 0, 0.0, 3, 162, 0,
      0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      72.0, 58.0, 0.0, 22.0,
      0,0,0,0 },

    // ============================================================
    // RANK D (6 missoes)
    // ============================================================
    { DR_D, DMT_DELIVERY,
      "Entrega: Suprimentos do Ichiraku",
      "Pegue a caixa de suprimentos e entregue no ponto de distribuicao. Mantenha postura e sem atalhos suspeitos.",
      3, 0, 0.0, 0, 0, 0,
      40.0, -28.0, 0.0,   145.0,  10.0, 0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_D, DMT_INVEST,
      "Inspecao: Pegadas Suspeitas",
      "Siga a trilha e registre tres pontos de evidencia. Fique alguns segundos em cada local.",
      3, 0, 0.0, 0, 0, 0,
      92.0, 48.0, 0.0,   140.0, 62.0, 0.0,   160.0, 20.0, 0.0,   0.0,0.0,0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_D, DMT_PATROL,
      "Patrulha: Arredores da Vila",
      "Ronda externa. Quatro pontos em sequencia. A ideia e verificar, nao sprintar e voltar.",
      2, 0, 0.0, 4, 0, 0,
      150.0, 0.0, 0.0,   150.0, 90.0, 0.0,   10.0, 90.0, 0.0,   10.0, 0.0, 0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_D, DMT_PVE,
      "Combate: Bandidos no Campo",
      "Ha bandidos perto da rota. Elimine os alvos marcados. Apenas contam eliminacoes do sistema.",
      0, 0, 0.0, 5, 100, 0,
      0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      190.0, 70.0, 0.0, 32.0,
      0,0,0,0 },

    { DR_D, DMT_ESCORT,
      "Escolta: Caixa do Comerciante",
      "Uma carga precisa chegar inteira. Escolte a caixa ate o destino. Distancia maxima conta.",
      0, 0, 0.0, 3, 0, 1271,
      40.0, -10.0, 0.0,   120.0, -20.0, 0.0,   180.0, 30.0, 0.0,   230.0, -10.0, 0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_D, DMT_RESCUE,
      "Resgate: Ferido na Trilha",
      "Um civil se feriu. Encontre-o e leve para o ponto seguro para atendimento rapido.",
      3, 0, 0.0, 4, 119, 0,
      120.0, 110.0, 0.0,   180.0, 120.0, 0.0,   200.0, 70.0, 0.0,   160.0, 40.0, 0.0,
      30.0, 30.0, 0.0, 7.0,
      0,0,0,0 },

    // ============================================================
    // RANK C (6 missoes)
    // ============================================================
    { DR_C, DMT_DELIVERY,
      "Entrega: Ervas Medicinais",
      "Pegue as ervas e entregue no ponto medico. Atrasos e atalhos chamam atencao.",
      3, 0, 0.0, 0, 0, 0,
      70.0, -90.0, 0.0,   220.0, -60.0, 0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_C, DMT_INVEST,
      "Investigacao: Reuniao Ilegal",
      "Posicione-se em tres pontos e observe. So conclui se permanecer o tempo minimo em cada local.",
      3, 0, 0.0, 0, 0, 0,
      240.0, 35.0, 0.0,   280.0, 65.0, 0.0,   300.0, 5.0, 0.0,   0.0,0.0,0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_C, DMT_PATROL,
      "Patrulha: Linha de Fronteira",
      "Patrulhe quatro pontos na fronteira. Se for muito rapido, nao valida.",
      2, 0, 0.0, 4, 0, 0,
      260.0, -120.0, 0.0,   310.0, -80.0, 0.0,   360.0, -120.0, 0.0,   410.0, -80.0, 0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_C, DMT_PVE,
      "Combate: Ninjas Renegados",
      "Elimine os renegados na area marcada. Contagem so vale para NPCs criados pelo sistema.",
      0, 0, 0.0, 8, 101, 0,
      0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      300.0, -170.0, 0.0, 40.0,
      0,0,0,0 },

    { DR_C, DMT_ESCORT,
      "Escolta: Caravana Curta",
      "Uma caravana precisa cruzar um trecho. Fique proximo o tempo todo e conclua a rota.",
      0, 0, 0.0, 3, 0, 1271,
      210.0, -10.0, 0.0,   260.0, -40.0, 0.0,   320.0, 20.0, 0.0,   380.0, -10.0, 0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_C, DMT_RESCUE,
      "Resgate: Refem do Contrabando",
      "Localize o refem e leve-o ao ponto seguro. O local e aleatorio entre possiveis spots.",
      3, 0, 0.0, 4, 141, 0,
      260.0, 130.0, 0.0,   320.0, 130.0, 0.0,   290.0, 180.0, 0.0,   350.0, 160.0, 0.0,
      150.0, 50.0, 0.0, 8.0,
      0,0,0,0 },

    // ============================================================
    // RANK B (3 missoes)
    // ============================================================
    { DR_B, DMT_INVEST,
      "Operacao: Infiltracao Silenciosa",
      "Trio de pontos para observacao. Permanece mais tempo em cada um. Sem completar instantaneo.",
      4, 0, 0.0, 0, 0, 0,
      340.0, 0.0, 0.0,   380.0, 40.0, 0.0,   420.0, -10.0, 0.0,   0.0,0.0,0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_B, DMT_PVE,
      "Combate: Grupo de Elite",
      "Elimine o grupo de elite na area marcada. Se afastar e voltar rapido demais pode gerar suspeita.",
      0, 0, 0.0, 12, 98, 0,
      0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      400.0, -120.0, 0.0, 55.0,
      0,0,0,0 },

    { DR_B, DMT_ESCORT,
      "Escolta: Suprimento Critico",
      "A carga e critica. Distancia maxima reduzida. Conclua a rota sem abandonar o alvo.",
      0, 0, 0.0, 3, 0, 1271,
      320.0, 100.0, 0.0,   360.0, 120.0, 0.0,   410.0, 90.0, 0.0,   460.0, 120.0, 0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    // ============================================================
    // RANK A (3 missoes)
    // ============================================================
    { DR_A, DMT_RESCUE,
      "Resgate: Captura de Alto Risco",
      "Um shinobi foi capturado. Ache o local do cativeiro e leve ao ponto seguro. Atrasos custam caro.",
      4, 0, 0.0, 4, 286, 0,
      420.0, -160.0, 0.0,   460.0, -120.0, 0.0,   500.0, -200.0, 0.0,   540.0, -140.0, 0.0,
      260.0, -40.0, 0.0, 10.0,
      0,0,0,0 },

    { DR_A, DMT_DELIVERY,
      "Entrega: Pergaminho Secreto",
      "Pegue o pergaminho secreto e entregue no ponto de troca. O sistema valida tempo e distancia minima.",
      4, 0, 0.0, 0, 0, 0,
      250.0, 220.0, 0.0,   560.0, 230.0, 0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_A, DMT_PVE,
      "Combate: Desmantelar Esquadrao",
      "Um esquadrao inimigo foi visto. Elimine todos na area. Recompensa alta, contagem valida pelo sistema.",
      0, 0, 0.0, 15, 290, 0,
      0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      520.0, 40.0, 0.0, 65.0,
      0,0,0,0 },

    // ============================================================
    // RANK S (3 missoes)
    // ============================================================
    { DR_S, DMT_BOSS,
      "S: Selos e Executar o Alvo",
      "Ative tres selos de contencao e derrote o alvo principal. Somente eliminacao marcada pelo sistema conta.",
      4, 0, 0.0, 1, 287, 0,
      520.0, -60.0, 0.0,   560.0, -30.0, 0.0,   590.0, -90.0, 0.0,   620.0, -60.0, 0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 },

    { DR_S, DMT_PVE,
      "S: Caça aos Missing-nin",
      "Elimine o grupo de missing-nin na area marcada. Missao pesada: valida tempo/distancia e contagem de NPCs.",
      0, 0, 0.0, 20, 295, 0,
      0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,   0.0,0.0,0.0,
      600.0, 120.0, 0.0, 80.0,
      0,0,0,0 },

    { DR_S, DMT_ESCORT,
      "S: Escolta de VIP",
      "Escolta extrema. Distancia maxima bem curta. Conclua a rota sem se afastar ou a missao falha.",
      0, 0, 0.0, 3, 0, 1271,
      480.0, 300.0, 0.0,   520.0, 330.0, 0.0,   570.0, 300.0, 0.0,   620.0, 340.0, 0.0,
      0.0,0.0,0.0, 0.0,
      0,0,0,0 }
};