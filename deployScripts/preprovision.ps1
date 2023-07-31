########################################################################
# Check for available capacity in region
########################################################################
#region Functions
Function Get-AzAvailableCores ($location, $skuFriendlyNames, $minCores = 0) {
    # using az command because there is currently a bug in various versions of PowerShell that affects Get-AzVMUsage
    $usage = (az vm list-usage --location $location --output json --only-show-errors) | ConvertFrom-Json

    $usage = $usage | 
        Where-Object {$_.localname -match $skuFriendlyNames} 

    $enhanced = $usage |
        ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name available -Value 0 -Force -PassThru
            $_.available = $_.limit - $_.currentValue
        }

    $enhanced = $enhanced |
        ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name usableLocation -Value $false -Force -PassThru
            If ($_.available -ge $minCores) {
                $_.usableLocation = $true
            } 
            else {
                $_.usableLocation = $false
            }
        }

    $enhanced

}

Function Get-AzAvailableLocations ($location, $skuFriendlyNames, $minCores = 0) {
    $allLocations = get-AzLocation
    $geographyGroup = ($allLocations | Where-Object {$_.location -eq $location}).GeographyGroup
    $locations = $allLocations | Where-Object { `
            $_.GeographyGroup -eq $geographyGroup `
            -and $_.Location -ne $location `
            -and $_.RegionCategory -eq "Recommended" `
            -and $_.PhysicalLocation -ne ""
        }

    $usableLocations = $locations | 
        ForEach-Object {
            $available = Get-AzAvailableCores -location $_.location -skuFriendlyNames $skuFriendlyNames -minCores $minCores |
                Where-Object {$_.localName -ne "Total Regional vCPUs"}
            If ($available.usableLocation) {
                $_ | Add-Member -MemberType NoteProperty -Name TotalCores     -Value $available.limit -Force 
                $_ | Add-Member -MemberType NoteProperty -Name AvailableCores -Value $available.available -Force 
                $_ | Add-Member -MemberType NoteProperty -Name usableLocation -Value $available.usableLocation -Force -PassThru
            }
        }

    $usableLocations
}
#endregion Functions

$location = $env:AZURE_LOCATION

########################################################################
# Create SSH RSA Public Key
########################################################################
Write-Host "Creating SSH RSA Public Key..."
$file = "videoai_rsa"

# Generate the SSH key pair
ssh-keygen -q -t rsa -b 4096 -f $file -N '""' 

# Get the public key
$AZURE_PUBLIC_SSH_KEY = get-content "$file.pub"

# Escape the backslashes 
$AZURE_PUBLIC_SSH_KEY = $AZURE_PUBLIC_SSH_KEY.Replace("\", "\\")

# set the env variable
azd env set AZURE_PUBLIC_SSH_KEY $AZURE_PUBLIC_SSH_KEY

########################################################################
# Get the logged in user's object ID
########################################################################
$USER_OBJECT_ID = az ad signed-in-user show --query id -o tsvc
azd env set USER_OBJECT_ID $USER_OBJECT_ID