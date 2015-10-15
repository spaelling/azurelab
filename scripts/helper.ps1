#
# Deploy_BaseTemplates.ps1
#

# as $$PSScriptRoot is not set when executing single lines (F8), get it here (copied to clipboard)
$PSScriptRoot | clip; break;
$MyScriptRoot = 'E:\OneDrive\Dokumenter\VS Projects\AzureLabDeployment\AzureLabDeployment\Scripts'

Import-Module Azure 

Switch-AzureMode AzureResourceManager

Remove-AzureAccount -Name (Get-AzureAccount | % Id)
Add-AzureAccount

$SubscriptionID = Get-AzureSubscription -SubscriptionName 'BizSpark' | % SubscriptionId; Select-AzureSubscription -SubscriptionId $SubscriptionID

$ResourceGroupName = "scsmlab01"
$Location = "West Europe"
$StorageAccountName = "scsmlab01storage" # we need this to store the DSC file. can be same as the one in template
$ContainerName = "templates"

New-AzureResourceGroup -Name $ResourceGroupName -Location $Location -Force
New-AzureStorageAccount -ResourceGroupName $ResourceGroupName -Location $Location -Name $StorageAccountName -Type Standard_LRS

# need storage context to create a container
$StorageAccountPrimaryKey = (Get-AzureStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Key1
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountPrimaryKey
# created with blob permissions. does not seem like it needs a SAS Token to get access to it when deploying ARM template
New-AzureStorageContainer -Name $ContainerName -Context $StorageContext -Permission Container

$Destination = "https://$StorageAccountName.blob.core.windows.net/$ContainerName"

$AzCopyPath = "..\Tools\AzCopy.exe"
$AzCopyPath = [System.IO.Path]::Combine($MyScriptRoot, $AzCopyPath)
$SourceDirectory = "..\Templates\"
$SourceDirectory = [System.IO.Path]::Combine($MyScriptRoot, $SourceDirectory)

& $AzCopyPath """$SourceDirectory""", $Destination, "/DestKey:$StorageAccountPrimaryKey", "/S", "/Y", "/Z:$env:LocalAppData\Microsoft\Azure\AzCopy\$ResourceGroupName"

# copy all blob uris to clipboard
#Get-AzureStorageBlob -Container $ContainerName -Context $StorageContext | % {"$Destination/$($_.Name)"} | clip

# TODO: get from template json - see Deploy-AzureRessourceGroup.ps1
#$ResourceGroupName = "LinkedTemplate01"
#$Location = "West Europe"

$TemplateFile = $SourceDirectory + "DeploymentTemplate.json"
$TemplateParameterFile = $SourceDirectory + "DeploymentTemplate.param.dev.json"
# test the template
Test-AzureResourceGroupTemplate -ResourceGroupName $ResourceGroupName `
    -TemplateFile $TemplateFile `
    -TemplateParameterFile $TemplateParameterFile `
    -Verbose

$TemplateFile = $SourceDirectory + "NIC.json"
$TemplateParameterFile = $SourceDirectory + "NIC.param.json"
Test-AzureResourceGroupTemplate -ResourceGroupName $ResourceGroupName `
    -TemplateFile $TemplateFile `
	-TemplateParameterFile $TemplateParameterFile `
    -Verbose



#Get-AzureResourceGroupDeployment -ResourceGroupName $ResourceGroupName | fl -Property Timestamp

Get-AzureVMSize -Location $Location | ogv

#Find all the available publishers
Get-AzureVMImagePublisher -Location $Location | ogv

$publisher = "MicrosoftSQLServer"
Get-AzureVMImageOffer -Location $location -Publisher $publisher | Select Offer

$offer = "SQL2012SP2-WS2012R2"
Get-AzureVMImageSku -Location $location -Publisher $publisher -Offer $offer | Select Skus