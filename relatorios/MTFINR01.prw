#INCLUDE 'protheus.ch'
#INCLUDE 'parmtype.ch'
#INCLUDE 'rwmake.ch'
#INCLUDE 'report.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'TbiConn.ch'

/*/{Protheus.doc} Mateus Pragana Function MTFINR01
    Relatório de Contas a Receber Vencido por cliente.
    @author Mateus Pragana
    @since 07/01/2023
    /*/
User Function MTFINR01(_emp,_filial)
    Local emp       := _emp
    Local fil       := _filial
    Local aCli      := {}
    Local codCli
    Local lojaCli
    Local mailCli
    Local nX 

    // Se for executado pelo schedule.
    If IsBlind()
        RpcSetType(3)
        If RpcSetEnv(emp,fil,,,"FIN",,,,,,)
            aCli := zGetCli()
            For nX := 1 to Len(aCli)
                codCli  := aCli[nX][1]
                lojaCli := aCli[nX][2]
                mailCli := aCli[nX][3]

                oReport := reportDef(codCli, lojaCli)
                oReport:nRemoteType := NO_REMOTE
                oReport:cEmail := mailCli
                oReport:nDevice := 3
                oReport:SetPreview(.F.)
                oReport:Print(.F.)
            Next
        EndIf
        RpcClearEnv()
    // Se for executado pelo meno de módulo. 
    Else
        oReport := reportDef()
        oReport:printDialog()
    EndIf
Return 

// Função para criar uma thread para executar a rotina. 
// Necessário informar Empresa e Filial.
User Function SJFINR01(aParametros)
    Local emp := aParametros[1]
    Local fil := aParametros[2]

    StartJob("U_MTFINR01", GetEnvServer(), .T., emp, fil)
Return

// Função para retornar informações do cliente caso ele tenha e-mail e títulos em seu nome.
// Retorno:
// aCli[nx][1] => Código
// aCli[nx][2] => Loja
// aCli[nx][3] => Email
Static Function zGetCli()
    Local aAreaAnt  := GetArea()
    Local aCli      := {}
    Local nPos      := 0
    Local cMail     := ""

    DbSelectArea("SE1")
    SE1->(DbSetOrder(1))
    SE1->(DbGoTop())

    While SE1->(!EOF())
        If (!EMPTY(ALLTRIM(SE1->E1_CLIENTE)) .AND. !EMPTY(ALLTRIM(SE1->E1_LOJA)) .AND. Date() > SE1->E1_VENCREA .AND. SE1->E1_SALDO <> 0)
            nPos := aScan(aCli, {|x| x[1] == SE1->E1_CLIENTE .AND. x[2] == SE1->E1_LOJA})
            If nPos <= 0
                cMail := Posicione("SA1",1,xFilial("SA1") + ALLTRIM(SE1->E1_CLIENTE) + ALLTRIM(SE1->E1_LOJA),"A1_EMAIL")
                If !EMPTY(ALLTRIM(cMail))
                    aaDD(aCli, {ALLTRIM(SE1->E1_CLIENTE), ALLTRIM(SE1->E1_LOJA), ALLTRIM(cMail)})  
                EndIf
            EndIf
        EndIF

        SE1->(DbSkip())
    EndDo

    RestArea(aAreaAnt)
Return aCli

// Definições do relatório.
// Retorno: Definição do relatório.
Static Function reportDef(_cliente, _loja)
    //Variaveis
    Local cPerg     := "MTFINR01"
    Local cTitulo   := "Relatório de Contas a Receber Vencido por Cliente"
    local oReport   := TReport():New("MTFINR01", cTitulo, cPerg,{|oReport| PrintReport(oReport, _cliente, _loja)},"Relatório de contas a Receber Vencidos por Cliente")
    Local oSection1 := TRSection():New(oReport, "Item",{"SA1","SE5"})

    //oReport
    oReport:SetLandscape()
    oReport:SetTotalInLine(.F.)
    oReport:ShowHeader()
    oReport:ShowParamPage()
    oReport:lParamPage := .F.

    //oSection
    oSection1:SetTotalInLine(.F.)

    //Cells
    TRCell():New(oSection1,"FILIAL"     , "TMP", "Filial"           ,                   ,08,,,"CENTER"  ,,"CENTER")
    TRCell():New(oSection1,"NUMTITULO"  , "TMP", "Titulo"           ,                   ,15,,,"RIGHT"   ,,"RIGHT")
    TRCell():New(oSection1,"CODCLI"     , "TMP", "Cod Cliente"      ,                   ,15,,,"CENTER"  ,,"CENTER")
    TRCell():New(oSection1,"LOJACLI"    , "TMP", "Loja"             ,                   ,08,,,"LEFT"    ,,"LEFT")
    TRCell():New(oSection1,"NOMECLI"    , "TMP", "Cliente"          ,                   ,25,,,"LEFT"    ,,"LEFT")
    TRCell():New(oSection1,"VENC"       , "TMP", "Vencimento"       ,                   ,20,,,"RIGHT"   ,,"RIGHT")
    TRCell():New(oSection1,"VENCREAL"   , "TMP", "Vencimento Real"  ,                   ,20,,,"RIGHT"   ,,"RIGHT")
    TRCell():New(oSection1,"TOTAL"      , "TMP", "Valor Total"      ,"@E 999,999.99"    ,15,,,"RIGHT"   ,,"RIGHT")
    TRCell():New(oSection1,"FALTANTE"   , "TMP", "Valor Faltante"   ,"@E 999,999.99"    ,15,,,"RIGHT"   ,,"RIGHT")

    //https://tdn.totvs.com/display/public/framework/TRFunction
    TRFunction():New(oSection1:Cell("NUMTITULO")    ,,"COUNT"   ,,,,,.F.,.T.,.F.,oSection1)
    TRFunction():New(oSection1:Cell("TOTAL")        ,,"SUM"     ,,,,,.F.,.T.,.F.,oSection1)
    TRFunction():New(oSection1:Cell("FALTANTE")     ,,"SUM"     ,,,,,.F.,.T.,.F.,oSection1)
Return oReport

// Impressao do relatório.
Static Function PrintReport(oReport, _cliente, _loja)
    Local oSection  := oReport:Section(1)
    Local cQuery    := ""
    Local cliente   := _cliente
    Local loja      := _loja

    oSection:Init()
    oSection:SetHEaderSection(.T.)

    // Filtrar código do cliente caso seja informado - relatório menu.
    cQuery +="%"
    If(!EMPTY(ALLTRIM(MV_PAR01)))
        cQuery += "AND A1_COD ='" + MV_PAR01 + "'" + CRLF
    EndIf

    // Filtrar Loja do cliente caso seja informado - relatório menu.
    If (!EMPTY(ALLTRIM(MV_PAR02)))
        cQuery += "AND A1_LOJA ='" + MV_PAR02 + "'" + CRLF
    EndIf

    // Filtrar por código do cliente e a loja - relatório por JOB.
    If(!EMPTY(ALLTRIM(cliente)) .AND. !EMPTY(ALLTRIM(loja)))
        cQuery += "AND A1_COD ='" + cliente + "'" + CRLF
        cQuery += "AND A1_LOJA ='" + loja + "'" + CRLF
    EndIf
    cQuery +="%"

    BeginSql Alias "TMP"
        SELECT 
            E1_FILIAL AS FILIAL, 
            E1_NUM AS NUMTITULO, 
            A1_COD AS CODCLI,
            A1_LOJA AS LOJACLI,
            A1_NREDUZ AS NOMECLI,
            E1_VENCTO AS VENC,
            E1_VENCREA AS VENCREAL,
            E1_VALOR AS TOTAL,
            E1_SALDO AS FALTANTE
        FROM %TABLE:SE1% (NOLOCK) AS SE1
        INNER JOIN %TABLE:SA1% (NOLOCK) AS SA1
        ON
            (
                SE1.D_E_L_E_T_ = SA1.D_E_L_E_T_
                AND E1_CLIENTE = A1_COD
                AND E1_LOJA = A1_LOJA
            )
        WHERE SE1.%NotDel%
        AND E1_FILIAL = %XFILIAL:SE1%
        AND E1_SALDO <> 0
        AND DATEDIFF(DAY, E1_VENCREA, GETDATE()) > 0
        %EXP:cQuery%
        ORDER BY E1_VENCREA, A1_COD, E1_VALOR
    EndSql

    While TMP->(!EOF())
        If oReport:Cancel()
            Exit
        EndIf

        oSection:Cell("FILIAL"):SetValue(TMP->FILIAL)
        oSection:Cell("NUMTITULO"):SetValue(TMP->NUMTITULO)
        oSection:Cell("CODCLI"):SetValue(TMP->CODCLI) 
        oSection:Cell("LOJACLI"):SetValue(TMP->LOJACLI) 
        oSection:Cell("NOMECLI"):SetValue(TMP->NOMECLI)
        oSection:Cell("VENC"):SetValue(sToD(TMP->VENC))
        oSection:Cell("VENCREAL"):SetValue(sToD(TMP->VENCREAL)) 
        oSection:Cell("TOTAL"):SetValue(TMP->TOTAL) 
        oSection:Cell("FALTANTE"):SetValue(TMP->FALTANTE) 

        oSection:PrintLine()
        TMP->(DbSkip())
    EndDo

    oSection:Finish()
    TMP->(DbCloseArea())
Return 
