#Requires -Version 5.1

<#
.SYNOPSIS
    Removes one or more users from a specific IBM-Project-Imagine team.

.DESCRIPTION
    Removes each specified user from the given team. If a user is not a member
    of the team a warning is issued and processing continues.

    This removes the user from the specified team only. To remove a user from
    all teams at once, use Offboard-Member.ps1.

    Prerequisites:
      - gh CLI installed and authenticated (gh auth login)
      - Authenticated account must have admin:org scope
      - Verify:  gh auth status
      - Refresh: gh auth refresh -s admin:org

.PARAMETER Username
    One or more GitHub usernames to remove.

.PARAMETER Team
    The slug of the team to remove the user(s) from (e.g. maintainers).

.PARAMETER Help
    Display this help text and exit.

.EXAMPLE
    .\Remove-TeamMember.ps1 -Username alice -Team maintainers

    Removes alice from the maintainers team.

.EXAMPLE
    .\Remove-TeamMember.ps1 -Username alice, bob -Team affiliation-microsoft

    Removes both users from the affiliation-microsoft team.

.EXAMPLE
    .\Remove-TeamMember.ps1 -Username alice -Team maintainers -WhatIf

    Shows what would be done without making any API calls.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string[]]$Username,

    [Parameter(Mandatory)]
    [string]$Team,

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
# Main
# ---------------------------------------------------------------------------

Write-Host "Removing $($Username.Count) user(s) from @$Org/$Team..."
Write-Host ''

foreach ($user in $Username) {
    if ($PSCmdlet.ShouldProcess("@$Org/$Team", "Remove '$user'")) {
        gh api "orgs/$Org/teams/$Team/memberships/$user" --method DELETE 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "  '$user' was not a member of '@$Org/$Team' or the request failed."
        } else {
            Write-Host "  [remove] $user <- @$Org/$Team"
        }
    } else {
        Write-Host "  [whatif] $user <- @$Org/$Team"
    }
}

Write-Host ''
Write-Host 'Done.'
