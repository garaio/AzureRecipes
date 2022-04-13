# Overview
Get Auth Token from a AAD App Registration (Service Principal) to call AAD-authenticated REST API's. This is for example used to load data from Log Analytics Workspace, but the concept can be easily adapted for other services as well.

# Implementation Notes (Getting Started)
Create following parameters:
* LogAnalyticsWorkspaceId | Text | Any value | `Log Analytics Workspace ID (Guid)`
* TenantId | Text | Any value | `Active Directory Directory ID (Guid)`
* LogAnalyticsPrincipalId | Text | Any value | `Active Directory App Registration ClienID (Guid) - ensure that this App has reading permissions to the Log Analytics Workspace`
* LogAnalyticsPrincipalSecret | Text | Any value | `Active Directory App Registration Secret`

## Create a Function for Authentication
[`Function-GetLogAnalyticsApiToken`](./Function-GetLogAnalyticsApiToken.txt):
```ts
let
    Source = () => let
        Source = Json.Document(Web.Contents("https://login.microsoftonline.com/"&#"TenantId"&"/oauth2/token", 
        [
            Headers=[Accept="application/json", ContentType="application/x-www-form-urlencoded"],
            Content=Text.ToBinary(
                "grant_type=client_credentials
                &resource=https://api.loganalytics.io
                &client_id="&#"LogAnalyticsPrincipalId"&"
                &client_secret="&#"LogAnalyticsPrincipalSecret"
            )
        ]))[access_token]
    in
        Source
in
    Source
```

## Create a Query that dynamically injects the Token
[`Query-GetDataFromLogAnalytics`](./Query-GetDataFromLogAnalytics.txt):
```ts
let AnalyticsQuery =
    let Source = Json.Document(Web.Contents("https://api.loganalytics.io/v1/workspaces/"&#"LogAnalyticsWorkspaceId"&"/query", 
    [Headers=[#"Authorization"="Bearer " & GetLogAnalyticsApiToken()],
    Query=[#"query"="AzureDiagnostics
    | where ResourceProvider =~ ""Microsoft.ApiManagement""
    | where isRequestSuccess_b == false
    | project TimeGenerated, ResourceName=tolower(Resource), ApiName=apiId_s, OperationName=operationId_s, ResponseCode=responseCode_d, ErrorType=lastError_source_s, ErrorReason=lastError_reason_s, ErrorMessage=lastError_message_s",#"x-ms-app"="OmsAnalyticsPBI",#"timespan"=AzureDataTimespan,#"prefer"="ai.response-thinning=true"],Timeout=#duration(0,0,4,0)])),
    TypeMap = #table(
    { "AnalyticsTypes", "Type" }, 
    { 
    { "string",   Text.Type },
    { "int",      Int32.Type },
    { "long",     Int64.Type },
    { "real",     Double.Type },
    { "timespan", Duration.Type },
    { "datetime", DateTimeZone.Type },
    { "bool",     Logical.Type },
    { "guid",     Text.Type },
    { "dynamic",  Text.Type }
    }),
    DataTable = Source[tables]{0},
    Columns = Table.FromRecords(DataTable[columns]),
    ColumnsWithType = Table.Join(Columns, {"type"}, TypeMap , {"AnalyticsTypes"}),
    Rows = Table.FromRows(DataTable[rows], Columns[name]), 
    Table = Table.TransformColumnTypes(Rows, Table.ToList(ColumnsWithType, (c) => { c{0}, c{3}}))
in
    Table,
    #"Added Date" = Table.AddColumn(AnalyticsQuery, "Date", each Date.From([TimeGenerated])),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Date",{{"Date", type date}})
in #"Changed Type"
```

# Considerations
* In powerbi.com service connection definitions, set authentication mode to "Anonymous" and skip test connection
* This solution requires that the service credentials are stored within parameters as clear text. This is not a great solution, however, ensure that the App Registration used for this access has only minimal permissions granted (ideally just Reader role on the according Log Analytics Workspace itself).