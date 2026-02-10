#if defined _NNRP_MSB_COOLDOWNS_
    #endinput
#endif
#define _NNRP_MSB_COOLDOWNS_

/*
    NNRP - Mapeamento de Cooldown para MentorSkillBar (Opção A)
    ---------------------------------------------------------
    Este include fornece a função PUBLIC esperada pelo módulo:

        public MSB_GetJutsuCooldownEnd(playerid, jid)

    Ela retorna o "end time" do cooldown no padrão do seu GM:
        gettime() + segundos

    COLOQUE ESSE INCLUDE NO FINAL DO SEU GAMEMODE (NNRP_modular.pwn),
    depois de todas as declarações de variáveis/enums dos jutsus.
*/

forward MSB_GetJutsuCooldownEnd(playerid, jid);
public MSB_GetJutsuCooldownEnd(playerid, jid)
{
    // jid chega sem tag (vem do sistema de binds/skillbar).
    // IMPORTANTE: não use "case _:JID_..." (isso vira um label '_' e quebra o switch).
    // Basta comparar o inteiro normalmente.

    #if defined JID_GOUKAKYUU
    switch (jid)
    {
        // === Katon
        case JID_GOUKAKYUU:       return TimerFireBall[playerid];
        case JID_HOUSENKA:        return Housenka[playerid][houTimer];
        case JID_KARYUUENDAN:     return Karyuuendan[playerid][karTimer];

        // === Raiton
        case JID_ARASHI_I:        return TimerArashi[playerid];
        case JID_RAIKYUU:         return Raikyuu[playerid][raiTimer];
        case JID_NAGASHI:         return TimerNaga[playerid];

        // === Suiton
        case JID_MIZURAPPA:       return TimerMizurappa[playerid];
        case JID_SUIKODAN:        return Suikodan[playerid][suiTimer];
        case JID_SUIROU:          return Suirou[playerid][rouTimer];

        // === Fuuton
        case JID_RASENGAN:        return Rasengan[playerid][RasenganTimer];
        case JID_HANACHI:         return TimerHanachi[playerid];
        case JID_SHINKUHA:        return Shinkuha[playerid][shinTimer];
        case JID_ATSUGAI:         return Atsugai[playerid][atsuTimer];

        // === Doton
        case JID_IWAKAI:          return Iwakai[playerid][iwaTimer];
        case JID_DORYUUHEKI:      return Doryuuheki[playerid][doryTimer];
        case JID_DOROJIGOKU:      return Dorojigoku[playerid][doroTimer];

        // === Extras / Mentor / Médicos
        case JID_BARREIRA_TOGGLE: return Barreira[playerid][BarreiraTime];
        case JID_SABERU:          return ChakraSaberu[playerid][saberuTimer];
        case JID_KATSUYU:         return Katsuyu[playerid][katsuTimer];
        case JID_MESU:            return timerMesuChakra[playerid];
        case JID_URUSHI:          return Urushi[playerid][urushiTimer];
        case JID_RAIJIN_VOADOR:   return PlayerRaijinVoador[playerid][raijinTimer];
		case JID_KAWARIMI:		return KawarimiTimer[playerid];
    }
    #endif

    return 0;
}