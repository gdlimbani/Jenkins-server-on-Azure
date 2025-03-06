# TF_AZ_ROLE_AKS
## Document to record the information required / necessary to run the Jenkins pipeline. Will be used for practicing the terraform IAC for deploying the Azure resources

Pre-requisites required to run this Jenkin pipelines.

* Create an "App Registrations" in the Microsoft Entra ID in Azure.
* Provide app name and then create it.
* Create the client secret for above client ID (Application ID) generated.
* The object ID for above created client also referred as service principal. This is used to access the Azure resources based on the permission granted.
* name of service principal "terraform-sp". Add below permissions by going to resource group "Access Control (IAM).
* Permissions:
    - User Access Administrator
    - Azure Container Storage Contributor
    - Azure Kubernetes Service Contributor Role
    - Storage Account Contributor
    - Network Contributor
    - Virtual Machine Contributor
* For storing the terraform state, we use storage container from Azure storage account. This storage account needs access for creating the tfstate file and writing , modifying it when terraform apply, terraform destroy commands are executed from jenkins pipeline.