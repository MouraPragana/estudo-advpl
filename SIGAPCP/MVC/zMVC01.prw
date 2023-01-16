#Include "TOTVS.CH"
#Include "FWMVCDef.ch"

Static cTitulo :="Ordens de Produ��o"
Static cAliasMVC := "Z01"

//https://mvcadvpl.wordpress.com/category/mvc/
User Function zMVC01()
    Local aArea := GetArea()
    Local oBrowse
    Private aRotina := {}

    //Defini��es do menu
    aRotina := MenuDef()

    //Fornece um objeto do tipo grid que permite a exibi��o de dados do tipo array, texto, tabela e query.
    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias(cAliasMVC)
    oBrowse:setDescription(cTitulo)
    oBrowse:DisableDetails()

    //Ativa a Browse
    oBrowse:Activate()

    RestArea(aArea)
Return Nil

// Fun��es do Menu
Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.zMVC01" OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Incluir" ACTION "VIEWDEF.zMVC01" OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Alterar" ACTION "VIEWDEF.zMVC01" OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Excluir" ACTION "VIEWDEF.zMVC01" OPERATION 5 ACCESS 0
    
Return aRotina

Static Function ModelDef()
    //Esta fun��o fornece o objeto com as estruturas de metadado do dicion�rio de dados, utilizadas pelas classes Model e View.
    // Par�metros := 1 - Model | 2 - View, Alias da Tabela
    Local oStruct := FWFormStruct(1, cAliasMVC)
    Local oModel
    Local bPre := NIL
    Local bPos := {|| "U_TESTE()"}
    Local bCommit := NIL
    Local bCancel := Nil

    //Criando o modelo de dados para Cadastro
    //A MPFormModel realiza o tratamento da fun��o Help, 
    // cria vari�veis de mem�ria e disponibiliza fun��es para persist�ncia 
    // em campos existentes no dicion�rio de dados, ela � utilizada em todas 
    // as aplica��es do Protheus.
    oModel := MPFormModel():New("zMVC01M", bPre, bPos, bCommit, bCancel)
    oModel:AddFields("Z01MASTER",/*cOwner*/,oStruct)
    oModel:SetDescription("Modelo de dados - " + cTitulo)
    oModel:GetModel("Z01MASTER"):SetDescription("Dados de " + cTitulo)
    oModel:SetPrimaryKey({"Z01_FILIAL","Z01_NUMOP"})
Return oModel

User Function Teste()
    MsgAlert("Texto", "Titulo!")
Return .F.

Static Function ViewDef()
    Local oModel := FWLoadModel("zMVC01")
    Local oStruct := FWFormStruct(2,cAliasMVC)
    Local oView

    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_Z01", oStruct, "Z01MASTER")
    oView:CreateHorizontalBox("Tela",100)
    oView:SetOwnerView("VIEW_Z01", "Tela")
Return oView
