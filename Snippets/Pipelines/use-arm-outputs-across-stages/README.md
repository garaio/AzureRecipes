# Introduction
Often the deployment of resources is implemented with multiple Bicep/ARM definitions. The [official documentation to process outputs from those deployments in later steps](https://learn.microsoft.com/en-us/azuredevops/pipelines/process/variables#set-a-multi-job-output-variable) is not very clear and complete, so here is a complete sample.

Deploy Bicep/ARM and read outputs (from [`azure-pipelines.cd.yml`](./azure-pipelines.cd.yml)):

```yaml
- task: AzureResourceManagerTemplateDeployment@3
  displayName: 'Deploy ARM Template (ResourceGroup)'
  inputs:
    azureResourceManagerConnection: 'ARM Service Connection'
    subscriptionId: '$(subscriptionId)'
    resourceGroupName: '$(resourceGroupName)'
    location: '$(resourceLocation)'
    csmFile: '$(Pipeline.Workspace)/CI-Pipeline/$(ciArtifactName)/$(deploymentFolderName)/azuredeploy.bicep'
    overrideParameters: '-resourceNamePrefix "$(opsResourceNamePrefix)" -resourceNameSuffix "$(resourceNameSuffix)"'
    deploymentMode: 'Incremental'
    deploymentName: 'Monitoring-$(Build.BuildId)-$(Environment.Name)'
    deploymentOutputs: armOutputs
# Map ARM outputs from JSON object to output-variables which can be read in later jobs/stages. More: https://learn.microsoft.com/en-us/azuredevops/pipelines/process/variables#set-a-multi-job-output-variable
- task: PowerShell@2
  name: resids
  displayName: 'Gather ARM Template Outputs'
  inputs:
    targetType: inline
    script: |
      $outputsObject = ConvertFrom-Json '$(armOutputs)'
      
      Write-Output "Parsed Object: $(ConvertTo-Json $outputsObject -Compress)"
      foreach ($output in $outputsObject.PSObject.Properties) {
          Write-Host "$($output.Name) = $($output.Value.value)"
          Write-Host "##vso[task.setvariable variable=$($output.Name);isOutput=true]$($output.Value.value)"
      }
```

Use values mapped to outputs (from [`azure-pipelines.cd.yml`](./azure-pipelines.cd.yml)):

```yaml
- stage: deploy_prod
  displayName: 'Deploy PROD Environment'
  dependsOn: 
    - deploy_cmn_monitor # Important: This stage must be referenced explicitely to allow reading of outputs via dependencies
    - deploy_test
  variables:
    # Note: Output referencing is special for deployment jobs: https://learn.microsoft.com/en-us/azure/devops/pipelines/process/deployment-jobs?view=azure-devops#support-for-output-variables
    actionGrpDevOpsTeamResId: $[ stageDependencies.deploy_cmn_monitor.monitoring.outputs['monitoring.resids.actionGrpDevOpsTeamResId'] ]
    actionGrpGaraioRemResId: $[ stageDependencies.deploy_cmn_monitor.monitoring.outputs['monitoring.resids.actionGrpGaraioRemResId'] ]
  jobs:
    - template: templates.deploy-to-stage.yml
      parameters:
        envName: 'PROD'
        suffix: 'p'
        releaseDate: '$(currentDate)'
        armServiceConnection: 'ARM Service Connection'
        actionGrpDevOpsTeamResId: '$(actionGrpDevOpsTeamResId)'
        actionGrpGaraioRemResId: '$(actionGrpGaraioRemResId)'
```
