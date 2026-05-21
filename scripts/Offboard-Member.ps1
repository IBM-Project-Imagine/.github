#Requires -Version 5.1

<#
.SYNOPSIS
    Removes one or more members from all IBM-Project-Imagine org teams.

.DESCRIPTION
    For each user, discovers every org team they belong to, displays the list,
    prompts for confirmation, then removes them from all of those teams.

    The user's GitHub account and org membership are not affected — only team
    memberships are removed. To fully remove someone from the org, use the
    GitHub UI or 'gh api orgs/<org>/members/<username> --method DELETE'.

    Prerequisites:
      - gh CLI installed and authenticated (gh auth login)
      - Authenticated account must have admin:org scope
      - Verify:  gh auth status
      - Refresh: gh auth refresh -s admin:org

.PARAMETER Username
    One or more GitHub usernames to offboard.

.PARAMETER Help
    Display this help text and exit.

.EXAMPLE
    .\Offboard-Member.ps1 -Username alice

    Lists alice's team memberships and prompts for confirmation before removing.

.EXAMPLE
    .\Offboard-Member.ps1 -Username alice, bob

    Processes both users sequentially, prompting for each.

.EXAMPLE
    .\Offboard-Member.ps1 -Username alice -WhatIf

    Shows which teams alice would be removed from without making any API calls.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string[]]$Username,

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
# Helpers
# ---------------------------------------------------------------------------

function Get-UserTeams ([string]$User) {
    $allTeams = gh api "orgs/$Org/teams" --paginate 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to retrieve org teams."
    }

    $userTeams = @()
    foreach ($team in $allTeams) {
        gh api "orgs/$Org/teams/$($team.slug)/memberships/$User" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $userTeams += $team.slug
        }
    }
    return $userTeams
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

foreach ($user in $Username) {

    Write-Host "Offboarding '$user' from @$Org..."
    Write-Host ''

    $memberTeams = Get-UserTeams $user

    if ($memberTeams.Count -eq 0) {
        Write-Host "  '$user' is not a member of any teams in @$Org."
        Write-Host ''
        continue
    }

    Write-Host "  Teams '$user' belongs to:"
    foreach ($slug in $memberTeams) {
        Write-Host "    - @$Org/$slug"
    }
    Write-Host ''

    foreach ($slug in $memberTeams) {
        if ($PSCmdlet.ShouldProcess("@$Org/$slug", "Remove '$user'")) {
            gh api "orgs/$Org/teams/$slug/memberships/$user" --method DELETE 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "  Failed to remove '$user' from '@$Org/$slug'."
            } else {
                Write-Host "  [remove] '$user' from @$Org/$slug"
            }
        } else {
            Write-Host "  [whatif] Remove '$user' from @$Org/$slug"
        }
    }

    Write-Host ''
}

Write-Host 'Done.'
