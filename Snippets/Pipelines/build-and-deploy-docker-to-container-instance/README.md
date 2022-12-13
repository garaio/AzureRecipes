# Introduction
Build and publish Docker container to Container Registry (CI pipeline) and deploy image to a Container Instance in a subsequent CD pipeline. The concept of independent pipelines for CI & CD is adapted from the snippet [`cascading-ci-cd-pipelines`](../cascading-ci-cd-pipelines).

The application used for this sample is taken from [the official Docker tutorial](https://docs.docker.com/get-started/02_our_app).

# CI/CD principle
The image is built and pushed on every build using the ID of the pipeline run as tag. When deploying a build (i.e. release) to stages, this ID is taken to reference the Docker image in the runtime environment (in this case Container Instance, but could also be Kubernetes Service or an App Service).

# Prerequisites
1. Create an Azure Container Registry
1. Activate Admin user access (menu `Access keys`) and copy password for usage in piplines
1. Create a Service Connection in the Azure DevOps project (type `Docker Registry` -> `Azure Container Registry`)
1. Adjust the variables in the CI & CD pipeline accordingly (you may us a variable group)

# Resources
* [Bicep Template for Container Registry](./Deployment/azuredeploy.registry.bicep)
* [Bicep Template for Container Instance](./Deployment/azuredeploy.instance.bicep)
* [CI Pipeline](./azure-pipelines.ci.yml)
* [CD Pipeline](./azure-pipelines.cd.yml)