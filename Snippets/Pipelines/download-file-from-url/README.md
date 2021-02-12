# Overview
The [built-in tasks](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/?view=azure-devops) do not include a simple task to load a file from any URL to the working directory. There is a [custom extension in the marketplace](https://marketplace.visualstudio.com/items?itemName=Fizcko.azure-devops-download-a-file) that you can use for this purpose. If this is not suitable for you, then you can do this with a simple PowerShell task as follows:

```yaml
- task: PowerShell@2
  displayName: "Download File"
  inputs:
    targetType: "inline"
    script: |
      Invoke-WebRequest -Uri "https://any-host-$(withParameter).net/FileName.zip" -OutFile "$(Pipeline.Workspace)/Pipeline/drop/$(targetFolderName)/assets/FileName.zip"
```
