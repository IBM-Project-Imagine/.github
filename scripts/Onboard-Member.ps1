#Requires -Version 5.1

<#
.SYNOPSIS
    Adds one or more members to the IBM-Project-Imagine organization base teams.

.DESCRIPTION
    For each user, adds them to:
      - members               (base team; all org members)
      - affiliation-<party>   (the affiliation team matching -Affiliation)
      - any additional teams passed via -Teams

    Accepts usernames inline (-Username) or from a CSV file (-FromFile).
    -Username and -FromFile are mutually exclusive.

    CSV format (-FromFile):
      Username,Affiliation,ExtraTeams
      alice,microsoft,
      bob,github,maintainers
      carol,ibm,"maintainers,security"

    The ExtraTeams column is optional and may contain a comma-separated list of
    additional team slugs. Quote the field if it contains multiple slugs.

    Prerequisites:
      - gh CLI installed and authenticated (gh auth login)
      - Authenticated account must have admin:org scope
      - Verify:  gh auth status
      - Refresh: gh auth refresh -s admin:org

.PARAMETER Username
    One or more GitHub usernames to onboard. Mutually exclusive with -FromFile.

.PARAMETER Affiliation
    The Founding Party the user(s) are affiliated with.
    Valid values: microsoft, github, ibm.
    Required when using -Username. Ignored when using -FromFile (affiliation is read from the CSV).

.PARAMETER Teams
    Additional team slugs to add the user(s) to, beyond members and their affiliation team.
    Optional. Only applies when using -Username.

.PARAMETER FromFile
    Path to a CSV file with columns: Username, Affiliation, ExtraTeams.
    Mutually exclusive with -Username.

.PARAMETER Help
    Display this help text and exit.

.EXAMPLE
    .\Onboard-Member.ps1 -Username alice -Affiliation microsoft

    Adds alice to: members, affiliation-microsoft.

.EXAMPLE
    .\Onboard-Member.ps1 -Username alice, bob -Affiliation github -Teams maintainers

    Adds alice and bob to: members, affiliation-github, maintainers.

.EXAMPLE
    .\Onboard-Member.ps1 -FromFile .\new-members.csv

    Reads usernames, affiliations, and extra teams from the CSV and onboards each user.

.EXAMPLE
    .\Onboard-Member.ps1 -Username alice -Affiliation ibm -WhatIf

    Shows what would be done without making any API calls.
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Inline')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Inline')]
    [string[]]$Username,

    [Parameter(Mandatory, ParameterSetName = 'Inline')]
    [ValidateSet('microsoft', 'github', 'ibm')]
    [string]$Affiliation,

    [Parameter(ParameterSetName = 'Inline')]
    [string[]]$Teams = @(),

    [Parameter(Mandatory, ParameterSetName = 'File')]
    [string]$FromFile,

    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Help) {
    Get-Help $PSCommandPath -Detailed
    exit 0
}

# ---------------------------------------------------------------------------
# Verify prerequisites
# ---------------------------------------------------------------------------

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error 'gh CLI not found. Install from https://cli.github.com and authenticate with: gh auth login'
}

$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "gh is not authenticated. Run: gh auth login`n$authStatus"
}

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$Org = 'IBM-Project-Imagine'

# ---------------------------------------------------------------------------
# Build work list
# ---------------------------------------------------------------------------

$workItems = @()

if ($PSCmdlet.ParameterSetName -eq 'File') {
    if (-not (Test-Path $FromFile)) {
        Write-Error "File not found: $FromFile"
    }
    $rows = Import-Csv -Path $FromFile
    foreach ($row in $rows) {
        if ([string]::IsNullOrWhiteSpace($row.Username)) { continue }
        $validAffiliations = @('microsoft', 'github', 'ibm')
        if ($row.Affiliation -notin $validAffiliations) {
            Write-Error "Row '$($row.Username)': invalid Affiliation '$($row.Affiliation)'. Must be one of: $($validAffiliations -join ', ')"
        }
        $extraTeams = if ([string]::IsNullOrWhiteSpace($row.ExtraTeams)) {
            @()
        } else {
            $row.ExtraTeams -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        }
        $workItems += [pscustomobject]@{ Username = $row.Username.Trim(); Affiliation = $row.Affiliation.Trim(); ExtraTeams = $extraTeams }
    }
} else {
    foreach ($user in $Username) {
        $workItems += [pscustomobject]@{ Username = $user; Affiliation = $Affiliation; ExtraTeams = $Teams }
    }
}

if ($workItems.Count -eq 0) {
    Write-Host 'No users to process.'
    exit 0
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Add-Membership ([string]$User, [string]$TeamSlug) {
    $body = [ordered]@{ role = 'member' }
    $body | ConvertTo-Json -Compress | gh api "orgs/$Org/teams/$TeamSlug/memberships/$User" --method PUT --input - 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "  Failed to add '$User' to '@$Org/$TeamSlug'."
        return $false
    }
    return $true
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Write-Host "Onboarding $($workItems.Count) user(s) to @$Org..."
Write-Host ''

foreach ($item in $workItems) {
    $affiliationTeam = "affiliation-$($item.Affiliation)"
    $targetTeams     = @('members', $affiliationTeam) + $item.ExtraTeams

    Write-Host "  $($item.Username) -> $($targetTeams -join ', ')"

    foreach ($teamSlug in $targetTeams) {
        if ($PSCmdlet.ShouldProcess("@$Org/$teamSlug", "Add '$($item.Username)'")) {
            $ok = Add-Membership $item.Username $teamSlug
            if ($ok) {
                Write-Host "    [add]  @$Org/$teamSlug"
            }
        } else {
            Write-Host "    [whatif] @$Org/$teamSlug"
        }
    }

    Write-Host ''
}

Write-Host 'Done.'
