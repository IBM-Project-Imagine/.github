#Requires -Version 5.1

<#
.SYNOPSIS
    Lists teams in the IBM-Project-Imagine organization.

.DESCRIPTION
    Three modes of operation:

      No parameters   — lists all org-level teams with slug, name, privacy, and member count.
      -Team <slug>    — lists members of a specific team with their team role.
      -Repo <name>    — lists teams that have been granted access to a specific repository,
                        along with the permission level granted.

    -Team and -Repo are mutually exclusive.

    Prerequisites:
      - gh CLI installed and authenticated (gh auth login)
      - Verify: gh auth status

.PARAMETER Team
    Slug of the team to list members for. Mutually exclusive with -Repo.

.PARAMETER Repo
    Repository name (without the org prefix). Lists teams with access to that repository.
    Mutually exclusive with -Team.

.PARAMETER Help
    Display this help text and exit.

.EXAMPLE
    .\Get-Teams.ps1

    Lists all org teams with slug, name, privacy, and member count.

.EXAMPLE
    .\Get-Teams.ps1 -Team maintainers

    Lists all members of the maintainers team and their team role (member or maintainer).

.EXAMPLE
    .\Get-Teams.ps1 -Repo my-library

    Lists all teams that have been granted access to the my-library repository,
    along with the permission level each team holds.
#>

[CmdletBinding(DefaultParameterSetName = 'OrgLevel')]
param(
    [Parameter(ParameterSetName = 'ByTeam')]
    [string]$Team,

    [Parameter(ParameterSetName = 'ByRepo')]
    [string]$Repo,

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

switch ($PSCmdlet.ParameterSetName) {

    'OrgLevel' {
        Write-Host "Teams in @$Org"
        Write-Host ''
        $teamsJson = gh api "orgs/$Org/teams" --paginate 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to retrieve teams for @$Org."
        }
        $teams = $teamsJson | ConvertFrom-Json
        if ($teams.Count -eq 0) {
            Write-Host '  (no teams found)'
        } else {
            $teams |
                Select-Object slug, name, privacy, members_count |
                Sort-Object slug |
                Format-Table -AutoSize
        }
    }

    'ByTeam' {
        Write-Host "Members of @$Org/$Team"
        Write-Host ''

        $maintainersJson = gh api "orgs/$Org/teams/$Team/members?role=maintainer" --paginate 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Team '$Team' not found or access denied. Verify the team slug with: .\Get-Teams.ps1"
        }

        $membersJson = gh api "orgs/$Org/teams/$Team/members?role=member" --paginate 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to retrieve members for team '$Team'."
        }

        $rows = @()
        foreach ($m in ($maintainersJson | ConvertFrom-Json)) {
            $rows += [pscustomobject]@{ login = $m.login; role = 'maintainer' }
        }
        foreach ($m in ($membersJson | ConvertFrom-Json)) {
            $rows += [pscustomobject]@{ login = $m.login; role = 'member' }
        }

        if ($rows.Count -eq 0) {
            Write-Host '  (no members)'
        } else {
            $rows | Sort-Object role, login | Format-Table -AutoSize
        }
    }

    'ByRepo' {
        Write-Host "Teams with access to $Org/$Repo"
        Write-Host ''
        $teamsJson = gh api "repos/$Org/$Repo/teams" --paginate 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to retrieve teams for '$Repo'. Verify the repository name is correct."
        }
        $teams = $teamsJson | ConvertFrom-Json
        if ($teams.Count -eq 0) {
            Write-Host '  (no teams have been granted access to this repository)'
        } else {
            $teams |
                Select-Object slug, name, permission |
                Sort-Object slug |
                Format-Table -AutoSize
        }
    }
}
