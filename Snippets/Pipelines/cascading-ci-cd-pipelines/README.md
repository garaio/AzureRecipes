# Introduction
The typical pattern for Continous Delivery is as follows
* On every relevant branch: Build pipeline with integration of all sources, run of unit and integration tests as well as any other validation and finally **creation/publishing of a deployable artifact**
* On successful build of particular branches: **Deploy given artifact** to multiple environments (e.g. DEV, TEST, INT, PROD) with approval steps between but without initially build the sources again

The reasons for choosing this pattern are as follows:
* Economize load on build agents (especially the build of Javascript- or Docker-based applications may be very time-consuming)
* Maintain a clear history of what is deployed thanks of having the artifact as input parameter for the CD pipeline (Release Management)
* More simple control of what builds are deployed to which stages

Note: _Some applications may use a different deployment for development environments (e.g. generation of "debug builds") and therefore rely on an additional build/release pipeline._

# Reference Architecture
The CI-pipeline (Continous Integration -> [`azure-pipelines.ci.yml`](./azure-pipelines.ci.yml)) as well as the CD-pipeline (Continous Deployment -> [`azure-pipelines.cd.yml`](./azure-pipelines.cd.yml)) realize a complete delivery process for a Single Page Application (SPA) hosted in a Storage Account as static website and connected to an Azure Function.

# Key Concepts
* Set main trigger in CD pipeline to 'none' to not react on any commits. Instead configure reference to CI pipeline as trigger in the resources section. You don't need to configure anything in Azure DevOps
* Use Variable Groups per environment, including a "Build" environment for validations during build process
* Recommendation: Use [Templates for Tasks](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops) if the deployment actions are equal for stages

# References
* [Trigger one pipeline after another](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/pipeline-triggers?view=azure-devops&tabs=yaml)
* [Use referenced pipeline artifacts](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/resources?view=azure-devops&tabs=schema#download-for-pipelines)