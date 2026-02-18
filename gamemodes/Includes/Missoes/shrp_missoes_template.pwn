#if defined _SHRP_MISSOES_TEMPLATE_INCLUDED
    #endinput
#endif
#define _SHRP_MISSOES_TEMPLATE_INCLUDED

// ==========================================================
// SHRP - TEMPLATE: Como criar uma missao nova (baseado no seu sistema atual)
// ==========================================================
//
// IMPORTANTE:
//  O teu sistema de missao "Normal" (Sensei) hoje funciona em 3 partes:
//   (A) LISTA / SELECAO   -> MostrarMissoes() e AoClicarNaMissoes()
//   (B) PROGRESSO (CP)    -> Missoes_OnPlayerEnterCheckpoint()
//   (C) ENTREGA / REWARD  -> MissoesPosicao() (quando volta no Sensei)
//
// Entao, pra criar UMA missao nova, voce geralmente mexe nesses 3 lugares.
// Este include e um roteiro + esqueleto. Copia e cola as partes para a tua missao.
//
// ----------------------------------------------------------
// 1) Crie um ID novo (na faixa que voce quiser)
// ----------------------------------------------------------
//
// Ex.: Missao nova de Iwagakure: "Entrega de Pergaminho"
// Escolha um numero que nao conflite com os cases ja existentes.
//
#define MISSAO_IWA_ENTREGA_PERG  99

// ----------------------------------------------------------
// 2) Variavel de progresso (CP) dessa missao
// ----------------------------------------------------------
// Se a sua missao tiver etapas, use uma variavel por player:
//
//   new IwaPergCP[MAX_PLAYERS];
//
// Voce pode colocar isso perto das outras variaveis de missao (topo do SHRP.pwn),
// OU criar um include de vars (se voce quiser deixar 100% fora do gamemode).

// ----------------------------------------------------------
// 3) Iniciar a missao (coloque um "case" em AoClicarNaMissoes)
// ----------------------------------------------------------
//
// Procure no include: Includes/Missoes/shrp_missoes_normal.inc
// a funcao AoClicarNaMissoes(...).
//
// Dentro do switch de missoes, adicione algo assim:
//
// case MISSAO_IWA_ENTREGA_PERG:
// {
//     // Liga o estado de missao
//     EmMissaoNormal[playerid] = 1;
//     IdentMissaoNormal[playerid] = MISSAO_IWA_ENTREGA_PERG;
//     MissoesNormalOpen[playerid] = 0;
//     MissaoNormalFinalizada[playerid] = 0;
//
//     // Etapa 1 (checkpoint inicial)
//     // IwaPergCP[playerid] = 1; // se voce criar a variavel
//     SetPlayerCheckpoint(playerid, -1750.0, 1900.0, 2.0, 2.5); // TROQUE coordenadas
//
//     SendClientMessage(playerid, -1, "{FFFFFF}Missao iniciada: Entrega de Pergaminho. Va ate o checkpoint.");
// }
//
// ----------------------------------------------------------
// 4) Progresso / etapas (coloque as checagens em Missoes_OnPlayerEnterCheckpoint)
// ----------------------------------------------------------
//
// Procure no include: Includes/Missoes/shrp_missoes_hooks.inc
// a funcao Missoes_OnPlayerEnterCheckpoint(playerid).
//
// Ali voce vai ver varios blocos:
//   if(EmMissaoNormal[playerid] == 1 && IdentMissaoNormal[playerid] == X && ...)
//   { ... SetPlayerCheckpoint(...) ... }
//
// Copie um bloco parecido e adapte:
//
// if(EmMissaoNormal[playerid] == 1 && IdentMissaoNormal[playerid] == MISSAO_IWA_ENTREGA_PERG)
// {
//     // Se for 1 etapa so:
//     DisablePlayerCheckpoint(playerid);
//     MissaoNormalFinalizada[playerid] = 1;
//     SendClientMessage(playerid, -1, "{FFFFFF}Etapa concluida. Volte ao Sensei para receber a recompensa.");
// }
//
// Se tiver 2+ etapas, voce controla por IwaPergCP[playerid].
// Exemplo:
// if(EmMissaoNormal[playerid] == 1 && IdentMissaoNormal[playerid] == MISSAO_IWA_ENTREGA_PERG)
// {
//     if(IwaPergCP[playerid] == 1) { IwaPergCP[playerid] = 2; SetPlayerCheckpoint(playerid, x2,y2,z2, 2.5); }
//     else if(IwaPergCP[playerid] == 2) { DisablePlayerCheckpoint(playerid); MissaoNormalFinalizada[playerid] = 1; }
// }
//
// ----------------------------------------------------------
// 5) Entrega / recompensa (coloque um case em MissoesPosicao)
// ----------------------------------------------------------
//
// Procure no include: Includes/Missoes/shrp_missoes_normal.inc
// a funcao MissoesPosicao(playerid).
//
// Ela tem switch(Missoes) com os cases que pagam recompensa quando:
//   MissaoNormalFinalizada[playerid] == 1
// e o player volta no ponto do Sensei.
//
// Adicione:
//
// case MISSAO_IWA_ENTREGA_PERG:
// {
//     EmMissaoNormal[playerid] = 0;
//     IdentMissaoNormal[playerid] = 0;
//     MissoesNormalOpen[playerid] = 0;
//     MissaoNormalFinalizada[playerid] = 0;
//     // IwaPergCP[playerid] = 0; // se existir
//
//     GivePlayerCash(playerid, 120);
//     GivePlayerExperiencia(playerid, 1000);
//     RyoseXPTxd(playerid, 1000, 120);
//
//     Audio_Play(playerid, 59);
//     SubirDLevel(playerid);
//     SalvarConta(playerid);
// }
//
// ----------------------------------------------------------
// 6) (Opcional) Mostrar na lista do painel (MostrarMissoes)
// ----------------------------------------------------------
// Se a tua lista de missoes for fixa por vila (1/2/3),
// voce precisa adicionar o nome/descricao no painel para o player ver.
//
// Isso fica em MostrarMissoes(playerid, vila).
//
// ==========================================================
// DICA RAPIDA:
//  Sempre que criar uma missao nova, pense nesses 3 pontos:
//
//  - INICIO:      AoClicarNaMissoes -> seta IdentMissaoNormal e checkpoint inicial
//  - PROGRESSO:   Missoes_OnPlayerEnterCheckpoint -> atualiza etapas e seta MissaoNormalFinalizada
//  - ENTREGA:     MissoesPosicao -> paga e reseta variaveis
// ==========================================================
