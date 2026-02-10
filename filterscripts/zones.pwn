// Criado Por Jonathan Feitosa
// Dia: 12/02/2015
 
#include <a_samp>
#include <zcmd>
 
#define MAX_GZ 10
 
new
    _@jGZ[MAX_GZ],
    _@jGZTwo,
    Float:_@getC[9],
    bool:Variavel[2],
    jStr[120],
    StringJFS[120],
    jStrTwo[120],
    __jC
;
 
public OnFilterScriptInit()
    return print("\n\nCriador de GZ - Carregado\nMesmo se estivesse bugado ia carregar. '-'\n\n");
 
public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
    if(Variavel[0])
    {
        ++__jC;
        _@getC[2] = fX;
        _@getC[3] = fY;
        
        if(_@getC[0] > _@getC[2] && _@getC[1] > _@getC[3])
            _@jGZ[__jC] = GangZoneCreate(_@getC[2], _@getC[3], _@getC[0], _@getC[1]),
                format(jStr, sizeof jStr, "GangZoneCreate(%f, %f, %f, %f);", _@getC[2], _@getC[3], _@getC[0], _@getC[1]);
        else if(_@getC[0] < _@getC[2] && _@getC[1] > _@getC[3])
            _@jGZ[__jC] = GangZoneCreate(_@getC[0], _@getC[3], _@getC[2], _@getC[1]),
                format(jStr, sizeof jStr, "GangZoneCreate(%f, %f, %f, %f);", _@getC[0], _@getC[3], _@getC[2], _@getC[1]);
        else if(_@getC[0] > _@getC[2] && _@getC[1] < _@getC[3])
            _@jGZ[__jC] = GangZoneCreate(_@getC[2], _@getC[1], _@getC[0], _@getC[3]),
                format(jStr, sizeof jStr, "GangZoneCreate(%f, %f, %f, %f);", _@getC[2], _@getC[1], _@getC[0], _@getC[3]);
        else if(_@getC[0] < _@getC[2] && _@getC[1] < _@getC[3])
            _@jGZ[__jC] = GangZoneCreate(_@getC[0], _@getC[1], _@getC[2], _@getC[3]),
                format(jStr, sizeof jStr, "GangZoneCreate(%f, %f, %f, %f);", _@getC[0], _@getC[1], _@getC[2], _@getC[3]);
        
        new File:Arquivo = fopen("jGangZone.txt", io_append);
        format(StringJFS, sizeof (StringJFS), "\n\njCriador GZ - Por Click Map:\n%s\n", jStr);
        fwrite(Arquivo, StringJFS);
        fclose(Arquivo);
        GangZoneShowForPlayer(playerid, _@jGZ[__jC], 0xFFFF0096);
        Variavel[0] = false;
    }
    else
         _@getC[0] = fX, _@getC[1] = fY, Variavel[0] = true;
    return true;
}
 
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == 6579)
    {
        if(!response) return true;
        switch(listitem)
        {
                case 0:
                {
                    if(Variavel[1]) return SendClientMessage(playerid, -1, "ERRO: Você já usou essa coordenada. Casso errou, use a opção Limpar.");
                    GetPlayerPos(playerid, _@getC[4], _@getC[6], _@getC[8]);
                    Variavel[1] = true;
                }
                case 1: {
                
                    if(!Variavel[1]) return SendClientMessage(playerid, -1, "ERRO: Você precisa da primeira coordenada!");
 
                    GetPlayerPos(playerid, _@getC[5], _@getC[7], _@getC[8]);
                    
                    SendClientMessage(playerid, -1, "PARABÉNS: Você conseguiu pegar a segunda coordenada. Visualize no Mapa.");
 
                    if(_@getC[4] > _@getC[5] && _@getC[6] > _@getC[7])
                        _@jGZTwo = GangZoneCreate(_@getC[5], _@getC[7], _@getC[4], _@getC[6]),
                            format(jStrTwo, sizeof jStrTwo, "GangZoneCreate(%f, %f, %f, %f);", _@getC[5], _@getC[7], _@getC[4], _@getC[6]);
                    else if(_@getC[4] < _@getC[5] && _@getC[6] > _@getC[7])
                        _@jGZTwo = GangZoneCreate(_@getC[4], _@getC[7], _@getC[5], _@getC[6]),
                            format(jStrTwo, sizeof jStrTwo, "GangZoneCreate(%f, %f, %f, %f);", _@getC[4], _@getC[7], _@getC[5], _@getC[6]);
                    else if(_@getC[4] > _@getC[5] && _@getC[6] < _@getC[7])
                        _@jGZTwo = GangZoneCreate(_@getC[5], _@getC[6], _@getC[4], _@getC[7]),
                            format(jStrTwo, sizeof jStrTwo, "GangZoneCreate(%f, %f, %f, %f);", _@getC[5], _@getC[6], _@getC[4], _@getC[7]);
                    else if(_@getC[4] < _@getC[5] && _@getC[6] < _@getC[7])
                        _@jGZTwo = GangZoneCreate(_@getC[4], _@getC[6], _@getC[5], _@getC[7]),
                            format(jStrTwo, sizeof jStrTwo, "GangZoneCreate(%f, %f, %f, %f);", _@getC[4], _@getC[6], _@getC[5], _@getC[7]);
 
                    GangZoneShowForPlayer(playerid, _@jGZTwo, 0xFFFF0096);
                }
                case 2:
                {
                    new File:Arquivo = fopen("jGangZone.txt", io_append);
                    format(StringJFS, sizeof (StringJFS), "\n\njCriador GZ - Por Dialog CMD:\n%s\n", jStrTwo);
                    fwrite(Arquivo, StringJFS);
                    fclose(Arquivo);
                    SendClientMessage(playerid, -1, "PARABÉNS: GangZone Salva com Sucesso!");
                }
                case 3:
                {
                    SendClientMessage(playerid, -1, "PARABÉNS: Sistema Limpo com Sucesso!");
                    Variavel[1] = false;
                    GangZoneDestroy(_@jGZTwo);
                }
        }
        return true;
    }
    return false;
}
 
command(criargz, playerid, params[])
    return
        ShowPlayerDialog(playerid, 6579, DIALOG_STYLE_LIST, "Criador de GZ", "Coordenada I\nCoordenada II\nSalvar\nLimpar", "Selecionar", "Sair");
 
command(limparclickmap, playerid, params[]) {
    for(new i; i < MAX_GZ; i++) GangZoneDestroy(_@jGZ[i]);
    Variavel[0] = false, __jC = 0, SendClientMessage(playerid, -1, "PARABÉNS: Sistema Limpo com Sucesso!");
    return true;
}
 
command(lultimoclickmap, playerid, params[])
    return
        GangZoneDestroy(_@jGZ[__jC]), Variavel[0] = false, --__jC, SendClientMessage(playerid, -1, "PARABÉNS: Sistema Limpo com Sucesso!");