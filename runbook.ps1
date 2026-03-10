param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop")]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$TagKey,

    [Parameter(Mandatory = $true)]
    [string]$TagValue,

    [Parameter(Mandatory = $false)]
    [string]$AlertsWebhook
)

$ErrorActionPreference = "Continue"

function ConvertTo-MarkdownTable {
    param([object[]]$Data)

    if ($null -eq $Data -or $Data.Count -eq 0) { return "" }

    $csv = $Data | ConvertTo-Csv -NoTypeInformation
    $header = $csv[0] -replace '"', '' -replace ',', ' | '
    $separator = ($csv[0] -split ',' | ForEach-Object { '---' }) -join ' | '

    $rows = $csv[1..($csv.Count - 1)] | ForEach-Object {
        $_ -replace '"', '' -replace ',', ' | '
    }

    return ($header, $separator, ($rows -join "`n")) -join "`n"
}

function Send-Alert {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $AlertsWebhook) { return }

    try {
        $payload = @{ text = $Message } | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri $AlertsWebhook -Method Post -ContentType "application/json" -Body $payload
    }
    catch {
        Write-Output "Failed to post alert webhook"
        Write-Output " - Message: $($_.Exception.Message)"
    }
}

# Login
az login --identity --only-show-errors
Connect-AzAccount -Identity

$context = Get-AzContext
$subscriptionId = $context.Subscription.Id

Write-Output $subscriptionId

az account set --subscription $subscriptionId --only-show-errors

$query = "[].{name:name,type:type,kind:kind,rg:resourceGroup}"

$resources = az resource list --tag "$TagKey=$TagValue" --query $query -o json --only-show-errors | ConvertFrom-Json

if (-not $resources) {

    Write-Output "No resources found with tag $TagKey=$TagValue"

Send-Alert @"
### Azure Resource $Action
No resources found with tag **$TagKey=$TagValue**
"@

    exit 0
}

$resources = @($resources)

# Dispatch table
$dispatch = @{
    "microsoft.containerservice/managedclusters" = {
        param($r,$a)
        az aks $a --resource-group $r.rg --name $r.name --only-show-errors
    }

    "microsoft.web/sites" = {
        param($r,$a)

        if ($r.kind -match "functionapp") {
            az functionapp $a --resource-group $r.rg --name $r.name --only-show-errors
        }
        else {
            az webapp $a --resource-group $r.rg --name $r.name --only-show-errors
        }
    }

    "microsoft.containerinstance/containergroups" = {
        param($r,$a)
        az container $a --resource-group $r.rg --name $r.name --only-show-errors
    }

    "microsoft.dbforpostgresql/flexibleservers" = {
        param($r,$a)
        az postgres flexible-server $a --resource-group $r.rg --name $r.name --only-show-errors
    }

    "microsoft.dbformysql/flexibleservers" = {
        param($r,$a)
        az mysql flexible-server $a --resource-group $r.rg --name $r.name --only-show-errors
    }

    "microsoft.sql/managedinstances" = {
        param($r,$a)
        az sql mi $a --resource-group $r.rg --managed-instance $r.name --only-show-errors
    }

    "microsoft.network/applicationgateways" = {
        param($r,$a)
        az network application-gateway $a --resource-group $r.rg --name $r.name --only-show-errors
    }

    "microsoft.streamanalytics/streamingjobs" = { # WARN: untested
        param($r,$a)
        az stream-analytics job $a --resource-group $r.rg --name $r.name --only-show-errors
    }

    "microsoft.synapse/workspaces" = { # WARN: untested
        param($r,$a)

        $pools = az synapse sql pool list `
            --workspace-name $r.name `
            --resource-group $r.rg `
            --query "[].name" `
            -o tsv `
            --only-show-errors

        if ($pools) {

            foreach ($pool in $pools -split "`n") {

                if ($a -eq "start") { $sub = "resume" }
                else { $sub = "pause" }

                az synapse sql pool $sub `
                    --name $pool `
                    --workspace-name $r.name `
                    --resource-group $r.rg `
                    --only-show-errors
            }
        }
    }
}

$results = $resources | ForEach-Object -Parallel {

    $ErrorActionPreference = "Stop"

    $Action = $using:Action
    $dispatch = $using:dispatch
    $Resource = $_

    $type = $Resource.type.ToLowerInvariant()
    $rg = $Resource.rg
    $name = $Resource.name

    Write-Output "Processing $type $name in $rg"

    try {

        if ($dispatch.ContainsKey($type)) {
            # Only call the dispatch once
            & $dispatch[$type] $Resource $Action
        } else {
            $actionToInvoke = if ($Action -eq "stop") { "powerOff" } else { $Action }
            $cleanType = $Resource.type.Trim('/')
            az resource invoke-action `
                --action $actionToInvoke `
                --resource-group $rg `
                --name $name `
                --resource-type $cleanType `
                --only-show-errors
        }

        [pscustomobject]@{
            Name   = $name
            Type   = $type
            RG     = $rg
            Action = $Action
            Status = "Succeeded"
            Message = $null
        }

    } catch {
        $err = $_
        Write-Output "Action failed for $name"

        [pscustomobject]@{
            Name   = $name
            Type   = $type
            RG     = $rg
            Action = $Action
            Status = "Failed"
            Message = $err.Exception.Message
        }
    }

} -ThrottleLimit 10

$results = @($results)

$failed = $results | Where-Object { $_.Status -eq "Failed" }
$succeeded = $results | Where-Object { $_.Status -eq "Succeeded" }

if ($succeeded.Count -gt 0) {

    Write-Output "`nSucceeded:"

    $succeeded | ForEach-Object {
        Write-Output " - $($_.Name) ($($_.Type)) in $($_.RG)"
    }
}

if ($failed.Count -gt 0) {

    Write-Output "`nFailed:"

    $failed | ForEach-Object {

        Write-Output " - $($_.Name) ($($_.Type)) in $($_.RG)"

        if ($_.Message) {
            Write-Output "   Message: $($_.Message)"
        }
    }
}

$succeededTable = ConvertTo-MarkdownTable ($succeeded | Select-Object Name,Type,RG)
$failedTable = ConvertTo-MarkdownTable ($failed | Select-Object Name,Type,RG,Message)

$md = @"
`n
### Azure Resource $Action summary`n
**Subscription:** $subscriptionId `n
**Tag:** $TagKey=$TagValue `n

**Succeeded:** $(@($succeeded).Count) `n
**Failed:** $(@($failed).Count) `n

"@

if ($succeededTable) {
    $md += "`n#### Succeeded`n$succeededTable`n"
}

if ($failedTable) {
    $md += "`n#### Failed`n$failedTable`n"
}

Send-Alert $md

if ($failed.Count -gt 0) {
    exit 1
}
