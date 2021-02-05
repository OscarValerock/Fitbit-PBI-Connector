// This file contains your Data Connector logic

section Fitbit_PBI_Connector;

client_id = "XXXX";//from the app
redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
authorize_uri = "https://www.fitbit.com/oauth2/authorize";
windowWidth = 720;
windowHeight = 1024;
UserID = "XXXX"; //gotofitbit.com and then in the panel view your profile, in the URL will appear your user

[DataSource.Kind="Fitbit_PBI_Connector", Publish="Fitbit_PBI_Connector.Publish"]

shared Fitbit_PBI_Connector.Contents = () =>

let
    source = FitBitNavTable()
in
    source;

shared Fitbit_PBI_Connector.GetProfile = () =>

let

    source = Json.Document(Web.Contents("https://api.fitbit.com/1/user/" & UserID & "/profile.json", 
        [Headers = 
            [
                #"Content-type" = "application/json"
            ]
         ]
     )),
     user = source[user]
in
    user;

shared Fitbit_PBI_Connector.GetTotalActivities = () =>

let
    source = Json.Document(Web.Contents("https://api.fitbit.com/1/user/-/activities.json",[Headers = [#"Content-type" = "application/json"]]))
in
    source;

// Data Source Kind description and OAUTH Process

Fitbit_PBI_Connector = [
TestConnection = (dataSourcePath) =>  { "Fitbit_PBI_Connector.GetContents"},
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin
            //Implicit = []
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

StartLogin = (resourceUrl, state, display) =>
    let
        authorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
            response_type = "token",
            client_id = client_id,
            redirect_uri = redirect_uri,
            scope = "profile activity sleep weight",
            expires_in= "604800",
            state = state,
            prompt = "login"
        ])
    in
        [
            LoginUri = authorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = 720,
            WindowWidth = 1024,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) =>
    let

        ReplaceText = Text.ReplaceRange(callbackUri,50,1,"?"),
        Parts = Uri.Parts(ReplaceText)[Query]

    in
        TokenMethod(Parts);      

TokenMethod = (access_token) =>

    let

        ToJSON = Text.FromBinary(Json.FromValue({access_token})),
        body = Json.Document(ToJSON),
        body1 = body{0}

    in
        body1;

// Data Source UI publishing description

Fitbit_PBI_Connector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = Fitbit_PBI_Connector.Icons,
    SourceTypeImage = Fitbit_PBI_Connector.Icons
];

Fitbit_PBI_Connector.Icons = [
    Icon16 = { Extension.Contents("Fitbit_PBI_Connector16.png"), Extension.Contents("Fitbit_PBI_Connector20.png"), Extension.Contents("Fitbit_PBI_Connector24.png"), Extension.Contents("Fitbit_PBI_Connector32.png") },
    Icon32 = { Extension.Contents("Fitbit_PBI_Connector32.png"), Extension.Contents("Fitbit_PBI_Connector40.png"), Extension.Contents("Fitbit_PBI_Connector48.png"), Extension.Contents("Fitbit_PBI_Connector64.png") }
];

//Navigation Tables

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

FitBitNavTable = () as table => 
let
        objects = #table(
            {"Name","Key","Data","ItemKind","ItemName","IsLeaf"},{
            {Extension.LoadString("GetProfile"),"Profile",Fitbit_PBI_Connector.GetProfile(),"Table","Table",false},
            {Extension.LoadString("GetTotalActivities"),"Total Activities",Fitbit_PBI_Connector.GetTotalActivities(),"Table","Table",false}
        }),
        NavTable = Table.ToNavigationTable(objects,{"Key"},"Name","Data","ItemKind","ItemName","IsLeaf")
in
        NavTable;