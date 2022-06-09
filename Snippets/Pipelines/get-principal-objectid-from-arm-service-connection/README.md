# Overview
Mainly to access KeyVault secrets from pipelines, an according Access Policy for the Service Principal must be deployed first. This snippet shows how to gather the necessary AAD Object ID.

Note: The variable `$servicePrincipalId` is automatically propagated to the environment of the task when setting `addSpnToEnvironment` to true. [See Microsoft documentation for further information](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-cli?view=azure-devops).

```yaml
- task: AzureCLI@2
  displayName: 'Evaluate variables for KeyVault deployment'
  inputs:
    azureSubscription: '${{ parameters.armServiceConnection }}'
    scriptType: bash
    scriptLocation: inlineScript
    addSpnToEnvironment: true
    inlineScript: |
      svcConObjectId=$(az ad sp show --id $servicePrincipalId --query id -o tsv)
      echo "##vso[task.setvariable variable=armServicePrincipalId;]$svcConObjectId"
```
