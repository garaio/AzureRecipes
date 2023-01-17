# Introduction
Function App with generated OpenAPI specification from attributes in source, automatically gathered and published to an API Management instance (dedicated to application or centrally provided), including a smart versioning concept.

> [Blueprint Central API Management](../../../Blueprints/central-api-management)


# API Definitions
With continous deployment process, the HTTP Functions intended for external integration are automatically published to an API Management instance. This bases on a OpenAPI V3 specification, which is created/generated with the official [`Microsoft.Azure.WebJobs.Extensions.OpenApi`](https://github.com/Azure/azure-functions-openapi-extension) package.

## Manual
1. Define attributes on all Functions that shall be published. Include all objects transmitted in request and response and list all potentiall results. Samples: https://github.com/Azure/azure-functions-openapi-extension/tree/main/samples/Microsoft.Azure.WebJobs.Extensions.OpenApi.FunctionApp.InProc
1. Check and carefully adjust version setting in [`OpenApiConfigurationOptions`](./DemoFuncApp/OpenApiConfigurationOptions.cs)
1. Run Function App locally (for testing you may download OpenAPI specification from http://localhost:7012/api/openapi/v3.json)
1. Commit changes and let the pipelines do the rest. Validate result in the API Management service (and potentially the Developer Portal)

## References
* [Documentation of available OpenAPI attributes](https://github.com/Azure/azure-functions-openapi-extension/blob/main/docs/openapi-core.md#decorators)
* [Provide sample request objects](https://github.com/Azure/azure-functions-openapi-extension/blob/main/docs/openapi-core.md#openapirequestbodyattribute)
* [Advanced schema specification of request/response objects](https://github.com/Azure/azure-functions-openapi-extension/blob/main/docs/openapi-core.md#openapipropertyattribute)

## Further
Maintain [REST API patterns](https://docs.microsoft.com/en-us/azure/architecture/best-practices/api-design) as much as reasonable


# Deployment

As the OpenAPI specification is directly extracted from the just deployed App Service, this has to be up and running with the most actual content. Therefore we separate the deployment in two jobs, first the regular resource deployment (including all the App Service stuff) and then the API definition on top of it.

Read OpenAPI specification from URL and inject it to Bicep deployment (from [`templates.deploy-to-stage.yml`](./templates.deploy-to-stage.yml)):

```yaml
- task: PowerShell@2
  displayName: 'Gather API Definition info object(s)'
  inputs:
    targetType: inline
    script: |
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
      $json = Invoke-WebRequest 'https://$(demoFuncName).azurewebsites.net/api/openapi/v3.json' | ConvertFrom-Json
      $result = (ConvertTo-Json $json.info -Compress).Replace("`"","'")
      Write-Output "Demo: $($result)"
      Write-Host "##vso[task.setvariable variable=demoApiSpecInfoJson]$result"

- task: AzureResourceManagerTemplateDeployment@3
  displayName: 'Deploy ARM Template (ResourceGroup)'
  inputs:
    azureResourceManagerConnection: '${{ parameters.armServiceConnection }}'
    subscriptionId: '$(subscriptionId)'
    resourceGroupName: '$(resourceGroupName)'
    location: '$(resourceLocation)'
    csmFile: '$(Pipeline.Workspace)/CI-Pipeline/$(ciArtifactName)/$(deploymentFolderName)/azuredeploy.api-definitions.bicep'
    overrideParameters: '-resourceNamePrefix "$(resourceNamePrefix)" -resourceNameSuffix "${{ parameters.suffix }}" -demoApiSpecInfoJson "$(demoApiSpecInfoJson)"'
    deploymentMode: 'Incremental'
    deploymentName: 'API-Definitions-$(Build.BuildId)-$(Environment.Name)'
```

The injected JSON string just contains the first definition section (including name and version of API to be deployed), but not the whole API specification. Transmitting this full object would be errorprone.

In the Bicep definition, this is handled as follows (from [`azuredeploy.api-definitions.bicep`](./Deployment/azuredeploy.api-definitions.bicep)):

```typescript
param demoApiSpecInfoJson string = ''

...
var demoApiSpecInfoObject = json(demoApiSpecInfoJson)
...

module apiDefinitionProducerRes './modules.apiDefinition.bicep' = if(!empty(demoApiSpecInfoJson)) {
  name: 'apim-api-definition-${demoApiRoute}'
  scope: resourceGroup()
  params: {
    apiMgmtName: apiMgmtName
    apiMgmtFuncKeySecret: listkeys('${demoFuncRes.id}/host/default', '2021-03-01').functionKeys.default
    apiMgmtApiRoute: demoApiRoute
    apiMgmtApiSubscriptionRequired: true
    apiDefVersion: demoApiSpecInfoObject.version
    apiDefTitle: demoApiSpecInfoObject.title
    apiDefDescription: demoApiSpecInfoObject.description
    apiFuncId: demoFuncRes.id
    apiFuncName: demoFuncName
    apiSpecificationUrl: 'https://${demoFuncName}.azurewebsites.net/api/openapi/v3.json'
  }
}
```

The versioning is the realized as follows (from [`modules.apiDefinition.bicep`](./Deployment/modules.apiDefinition.bicep)):

```typescript
param apiDefVersion string = '1.0.0'
...
var apiDefVersionParts = split(apiDefVersion, '.')
...
var apiMgmtApiName = '${apiFuncName}-v${apiDefVersionParts[0]}' // e.g. 'customer-project-demo-f-t-v1'
...
resource apiMgmtApiRes 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: apiMgmtApiName
  parent: apiMgmtRes
  properties: {
    displayName: !empty(apiDefTitle) ? apiDefTitle : apiFuncName
    description: apiDefDescription
    subscriptionRequired: apiMgmtApiSubscriptionRequired
    path: apiMgmtApiRoute
    protocols: [
      'https'
    ]
    isCurrent: true
    apiType: 'http'
    apiVersion: 'v${apiDefVersionParts[0]}'
    apiVersionSetId: apiMgmtVersionSetRes.id
    apiRevision: '${int(apiDefVersionParts[1]) + 1}'
    apiRevisionDescription: 'API Definition: ${apiDefVersion}'
    format: 'openapi+json-link'
    value: apiSpecificationUrl
  }
}
```

The major version matches with the version in the API Management (with versioning-scheme `Segment` this is a URL parameter). Minor versions are less relevant for integrators as it only sets the revision number, build version is just added to the description, so changes on these levels are informational only.

The advantage of this, is the fact that only the most current version is set/updated during deployment. Older versions stay as they have been, until they are manually removed from the API Management instance, usually after a period of beeing declared as deprecated.

As the App Service endpoints may now beeing called by different versions (by using different URLs which are introduced by changed major numbers), we must be able to detect the used API version in the code. Therewith conditional processing or responses are possible.
To enable this, the deployment creates an API Management policy that injects the version in a HTTP header:

```typescript
var apiVersionHeaderName = 'Api-Version'

resource apiMgmtApiPolicyRes 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  name: 'policy'
  parent: apiMgmtApiRes
  properties: {
    value: '<policies><inbound><base /><set-backend-service backend-id="${apiMgmtBackendRes.name}" /><set-header name="${apiVersionHeaderName}" exists-action="override"><value>${apiDefVersion}</value></set-header></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
    format: 'xml'
  }
}
```

In the code, this can be easily retrieved as follows (from [`FunctionHelper`](./DemoFuncApp/FunctionHelper.cs)):

```csharp
public static class FunctionHelper
{
    /// <summary>
    /// Reads API Version from HTTP header (automatically enriched by API Management) or uses <see cref="OpenApiConfigurationOptions">currently published version</see> otherwise
    /// </summary>
    /// <remarks>This information can be used for separated handling of different versions active</remarks>
    public static Version GetApiVersion(this HttpRequest req)
    {
        var apiVersion = req.Headers.TryGetValue(Constants.Headers.ApiVersion, out var apiVersionValue) ? (string)apiVersionValue : OpenApiConfigurationOptions.CurrentVersion;
        return Version.Parse(apiVersion);
    }
}

// Sample usage
public static async Task<IActionResult> Create(
    [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = Constants.Routes.DemoEntities + "/{" + Constants.RouteParams.EntityId + "}")] HttpRequest req,
    string id,
    ILogger log)
{
    var apiVersion = FunctionHelper.GetApiVersion(req);
    ...
}
```


# Authentication Enforced on App Service?

If you need to publish an OpenAPI spec from an App Service resource that has the built-in authentication activated and enforced, the specification cannot be automatically gathered during deployment via HTTP request.

In such a situation you may proceed as follows:

1. After API changes start the App Service instance locally, export the Open API specification (http://localhost:7012/api/openapi/v3.json) and store in a folder that is under version control.
2. Ensure that these specification files are included in the build artifact (CI pipeline) and copied to the Storage Account (deployment container).
3. Update the Bicep definition that would reference the specification from the URL ([`azuredeploy.api-definitions.bicep`](./Deployment/azuredeploy.api-definitions.bicep)) as follows:

 ```typescript
 var serviceFuncOpenApiSpecName = 'DemoFuncApp.json' // OpenAPI specification manually exported for DemoFuncApp
 var serviceFuncOpenApiSpecPath = '/${serviceFuncOpenApiSpecName}'
 var serviceFuncOpenApiSpecInfoObject = !empty(openApiSpecInfoObjectsJson) ? json(openApiSpecInfoObjectsJson)[serviceFuncOpenApiSpecName] : {}
...
 serviceApiDefinitionUrl: '${storageAccountBlobUri}${blobContainerDeployment}${serviceFuncOpenApiSpecPath}?${listAccountSas(storageAccountRes.id, '2019-06-01', storageAccountFunctionSasParams).accountSasToken}'
 ```

4. With the change above, the specification is read from a generated Storage Account URL instead of directly from the App Service. What is yet missing, is the header information to handle correct version deployment. Therefore you may update the YAML pipeline as follows:

```yaml
- task: PowerShell@2
  displayName: 'Gather API Definition info objects'
  inputs:
    targetType: inline
    script: |
      $hash = @{}
      Get-ChildItem -Path "$(Pipeline.Workspace)/CI-Pipeline/$(ciArtifactName)" -Filter *.json
      |
      Foreach-Object {
        $json = Get-Content $_.FullName | ConvertFrom-Json
        $hash[$_.Name] = $json.info
        Write-Host "Processed: " $_.Name
      }
      $result = (ConvertTo-Json $hash -Compress).Replace("`"","'")
      Write-Host "##vso[task.setvariable variable=openApiSpecInfoObjectsJson]$result"
```

5. In opposition to the extraction from an URL, this script reads the specifications of all (potentially) available files from a directory and creates a dictionary object using the API name as the key. This fits to the processing proposed in step 3.
