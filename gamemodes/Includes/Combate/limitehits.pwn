#if defined _SHRP_MAXHITS_
    #endinput
#endif
#define _SHRP_MAXHITS_


// ==========================================================
// LIMITES DE HITS POR ATRIBUTO + BONUS POR ARMA
// - Chão: HitPlayerCount (combo no chão)
// - Ar:   TaijutsuAirHit (combo no ar)
// ==========================================================

// -------- CONFIG CHÃO (combo no chão) --------
#if !defined GROUND_TAI_MIN_HITS
    #define GROUND_TAI_MIN_HITS   (3)
#endif
#if !defined GROUND_TAI_MAX_HITS
    #define GROUND_TAI_MAX_HITS   (5)
#endif
#if !defined GROUND_TAI_STEP
    #define GROUND_TAI_STEP       (60)   // a cada 60 Taijutsu +1 hit
#endif

#if !defined GROUND_KEN_MIN_HITS
    #define GROUND_KEN_MIN_HITS   (3)
#endif
#if !defined GROUND_KEN_MAX_HITS
    #define GROUND_KEN_MAX_HITS   (6)
#endif
#if !defined GROUND_KEN_STEP
    #define GROUND_KEN_STEP       (60)   // a cada 60 Kenjutsu +1 hit
#endif

// -------- CONFIG AR (combo no ar) --------
#if !defined AIR_TAI_MIN_HITS
    #define AIR_TAI_MIN_HITS      (3)
#endif
#if !defined AIR_TAI_MAX_HITS
    #define AIR_TAI_MAX_HITS      (6)
#endif
#if !defined AIR_TAI_STEP
    #define AIR_TAI_STEP          (50)   // a cada 50 Taijutsu +1 hit
#endif

#if !defined AIR_KEN_MIN_HITS
    #define AIR_KEN_MIN_HITS      (3)
#endif
#if !defined AIR_KEN_MAX_HITS
    #define AIR_KEN_MAX_HITS      (5)
#endif
#if !defined AIR_KEN_STEP
    #define AIR_KEN_STEP          (70)   // a cada 70 Kenjutsu +1 hit
#endif

// Trava curtinha só pro chão (pra impedir continuar batendo depois do limite)
#if !defined GROUND_COMBO_LOCK_MS
    #define GROUND_COMBO_LOCK_MS  (250)
#endif

stock ClampInt(val, minv, maxv)
{
    if(val < minv) return minv;
    if(val > maxv) return maxv;
    return val;
}

// Decide se o hit atual conta como "Kenjutsu" (arma) ou "Taijutsu" (mão).
stock bool:IsKenjutsuHit(playerid)
{
    if(UsandoArma[playerid]) return true;
    if(SaberuEspadass[playerid]) return true;
    if(CharakNoSaberuUse[playerid] == 1) return true;
    if(MesuChakaraUsando[playerid] == 1) return true;
    if(ArmaData[playerid][armaDamage] >= 1) return true;
    return false;
}

// ==========================================================
// BONUS POR ARMA (personalize aqui)
// - Retorna +hits extras dependendo da arma atual
// - Você pode diferenciar CHÃO e AR usando o parâmetro isAir
// ==========================================================
stock GetWeaponHitBonus(playerid, bool:isAir)
{
    new id = ArmaData[playerid][armaDamage];

    // Se quiser dar bonus também pra "chakra no sabre" mesmo sem armaDamage:
    if(CharakNoSaberuUse[playerid] == 1) return 1;
    if(MesuChakaraUsando[playerid] == 1) return 1;

    switch(id)
    {
        // ===== EXEMPLOS (edite do seu jeito) =====
        // case 7:  return isAir ? 1 : 1;  // Nunoboko (lendária) +1 hit no ar e no chão
        // case 10: return isAir ? 1 : 2;  // Kiba (lendária) +1 no ar, +2 no chão
        // case 11: return 1;              // Kabutowari +1
        // case 50: return 1;              // Hiramekarei 2 mãos +1
        // case 28: return 1;              // Kunai Gigante +1

        default: return 0;
    }
}

// Se quiser que arma lendária também aumente o "TETO MÁXIMO" (cap):
stock GetWeaponHitMaxBonus(playerid, bool:isAir)
{
    new id = ArmaData[playerid][armaDamage];

    switch(id)
    {
        // EXEMPLOS:
        // case 7:  return 1; // Nunoboko: permite passar do AIR_KEN_MAX_HITS / GROUND_KEN_MAX_HITS em +1
        // case 10: return 2; // Kiba: +2 no cap

        default: return 0;
    }
}

// ==========================================================
// LIMITES CALCULADOS
// ==========================================================
stock GetGroundComboHitLimit(playerid)
{
    new limit, maxBonus;

    if(IsKenjutsuHit(playerid))
    {
        limit    = GROUND_KEN_MIN_HITS + (Info[playerid][pKenjutsu] / GROUND_KEN_STEP) + GetWeaponHitBonus(playerid, false);
        maxBonus = GetWeaponHitMaxBonus(playerid, false);
        return ClampInt(limit, GROUND_KEN_MIN_HITS, (GROUND_KEN_MAX_HITS + maxBonus));
    }
    else
    {
        limit = GROUND_TAI_MIN_HITS + (Info[playerid][pTaijutsu] / GROUND_TAI_STEP);
        return ClampInt(limit, GROUND_TAI_MIN_HITS, GROUND_TAI_MAX_HITS);
    }
}

stock GetAirComboHitLimit(playerid)
{
    new limit, maxBonus;

    if(IsKenjutsuHit(playerid))
    {
        limit    = AIR_KEN_MIN_HITS + (Info[playerid][pKenjutsu] / AIR_KEN_STEP) + GetWeaponHitBonus(playerid, true);
        maxBonus = GetWeaponHitMaxBonus(playerid, true);
        return ClampInt(limit, AIR_KEN_MIN_HITS, (AIR_KEN_MAX_HITS + maxBonus));
    }
    else
    {
        limit = AIR_TAI_MIN_HITS + (Info[playerid][pTaijutsu] / AIR_TAI_STEP);
        return ClampInt(limit, AIR_TAI_MIN_HITS, AIR_TAI_MAX_HITS);
    }
}

// ==========================================================
// TRAVA DO CHÃO (não conflita com HittedImpossible do ar)
// ==========================================================
new ComboLockGround[MAX_PLAYERS];

function ClearGroundComboLock(playerid)
{
    ComboLockGround[playerid] = 0;
    return 1;
}