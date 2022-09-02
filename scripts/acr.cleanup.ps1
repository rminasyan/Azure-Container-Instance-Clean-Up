# This script check and removes the old docker images from the azure container registry
# WARNING: this script will delete all image tags within a repository that share the same manifest

[CmdletBinding()]
Param(
    # Define ACR Name
    [Parameter (Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $AzureRegistryName,

    # Define Azure Subscription Name
    [Parameter (Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $SubscriptionName,
  
    # Number of images to retain per respository
    [Parameter (Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Int] $ImagestoKeep,

    # Enable deletion or just run in scan mode
    [Parameter (Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $EnableDelete = "yes",

    # Specify repository to cleanup (if not specified will default to all repositories within the registry)
    [Parameter (Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $Repository
)

$imagesDeleted = 0

if ($SubscriptionName) {
    Write-Host "Setting subscription to: $SubscriptionName"
    az account set --subscription $SubscriptionName
}

if ($Repository) {
    $RepoList = @("", "", $Repository)
}
else {
    Write-Host "Getting list of all repositories in container registry: $AzureRegistryName"
    $RepoList = az acr repository list --name $AzureRegistryName --output table
}

for ($index = 2; $index -lt $RepoList.length; $index++) {
    $RepositoryName = $RepoList[$index]

    write-host ""
    Write-Host "Checking repository: $RepositoryName"
    $RepositoryTags = az acr repository show-tags --name $AzureRegistryName --repository $RepositoryName --output tsv --orderby time_desc
    write-host "# Total images:"$RepositoryTags.Count" # Images to keep:"$ImagestoKeep
    if($RepositoryTags -is [Object[]])