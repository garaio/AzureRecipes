# Introduction
The Artifacts section in Azure DevOps provides a simple and convenient possibility to share code packages (e.g. Nuget or npm) among components (typically multiple repositories in the same project).
This snippet shows a pipeline to independently build and publish a Nuget package from one or multiple projects. It:
* Provides a simple approach for versioning: Major & minor version is manually specified in the pipeline. Because the pipeline is placed in the same repository with the code, this can be easily managed along with the changes done in the code and updated in the same commit.
* Fully relies on the *.csproj settings (no redundant management of a *.nuspec file). This should be reconsidered if multiple projects shall be included in a package.
* Has build and publish in separate stages in the pipeline

# References
* [MSDN Publish and download artifacts in Azure Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/artifacts/pipeline-artifacts)
