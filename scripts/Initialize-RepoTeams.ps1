#Requires -Version 5.1

<#
.SYNOPSIS
    Creates the maintainers and contributors teams for a specific repository.

.DESCRIPTION
    Creates two project-scoped teams in the IBM-Project-Imagine GitHub organization
    and grants each team access to the specified repository:

      <project>-maintainers  — granted MaintainerPermission on <repo> (default: maintain)
      <project>-contributors — granted ContributorPermission on <repo> (default: triage)

    The script is idempotent: if a team already exists it is skipped. Repo permission
    grants are applied (or updated) regardless of whether the team was just created or
    already existed.

    Per TEAMS.md conventions, project teams are not parented to any org-level team.

    Prerequisites:
      - gh CLI installed and authenticated (gh auth login)
      - Authenticated account must have admin:org scope
      - Verify:  gh auth status
      - Refresh: gh auth refresh -s admin:org

.PARAMETER Project
    The project name. Teams will be named <project>-maintainers and <project>-contributors.

.PARAMETER Repo
    The repository name (without the org prefix) to grant the teams access to.

.PARAMETER MaintainerPermission
    Repository permission level to grant the maintainers team. Default: maintain.
    Valid values: write, maintain.

.PARAMETER ContributorPermission
    Repository permission level to grant the contributors team. Default: triage.
    Valid values: triage, write.

.PARAMETER Help
    Display this help text and exit.

.EXAMPLE
    .\Initialize-RepoTeams.ps1 -Project my-library -Repo my-library

    Creates my-library-maintainers (maintain) and my-library-contributors (triage)
    and grants each team the appropriate access to the my-library repository.

.EXAMPLE
    .\Initialize-RepoTeams.ps1 -Project my-library -Repo my-library -MaintainerPermission write -WhatIf

    Shows what would be created without making any API calls.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$Project,

    [Parameter(Mandatory)]
    [string]$Repo,

    [ValidateSet('write', 'maintain')]
    [string]$MaintainerPermission = 'maintain',

    [ValidateSet('triage', 'write')]
    [string]$ContributorPermission = 'triage',

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

$TeamDefinitions = @(
    [ordered]@{
        slug        = "$Project-maintainers"
        name        = "$Project : Maintainers"
        description = "Maintainers for the $Project project."
        privacy     = 'closed'
        permission  = $MaintainerPermission
    },
    [ordered]@{
        slug        = "$Project-contributors"
        name        = "$Project : Contributors"
        description = "Contributors for the $Project project."
        privacy     = 'closed'
        permission  = $ContributorPermission
    }
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Get-ExistingTeamId ([string]$Slug) {
    $response = gh api "orgs/$Org/teams/$Slug" 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    ($response | ConvertFrom-Json).id
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Write-Host "Initializing repo teams for project '$Project' on $Org/$Repo..."
Write-Host ''

foreach ($team in $TeamDefinitions) {

    # --- Create team if it does not exist ---
    $existingId = Get-ExistingTeamId $team.slug

    if ($null -ne $existingId) {
        Write-Host "  [skip]   @$Org/$($team.slug) already exists"
    } else {
        $body = [ordered]@{
            name        = $team.name
            description = $team.description
            privacy     = $team.privacy
        }

        if ($PSCmdlet.ShouldProcess("@$Org/$($team.slug)", 'Create team')) {
            $result = $body | ConvertTo-Json -Compress | gh api "orgs/$Org/teams" --method POST --input -
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to create team '$($team.slug)'. Check that your token has admin:org scope."
            }
            $created = $result | ConvertFrom-Json
            Write-Host "  [create] @$Org/$($team.slug) (id: $($created.id))"
        } else {
            Write-Host "  [whatif] Create @$Org/$($team.slug)"
        }
    }

    # --- Grant repo access (PUT is idempotent; safe whether team was created or skipped) ---
    if ($PSCmdlet.ShouldProcess("$Org/$Repo", "Grant '$($team.permission)' to @$Org/$($team.slug)")) {
        $permBody = [ordered]@{ permission = $team.permission }
        $permBody | ConvertTo-Json -Compress | gh api "orgs/$Org/teams/$($team.slug)/repos/$Org/$Repo" --method PUT --input - 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to grant '$($team.permission)' on '$Repo' for team '$($team.slug)'. The team exists but repo permission was not set."
        } else {
            Write-Host "  [grant]  $($team.permission) on $Org/$Repo -> @$Org/$($team.slug)"
        }
    } else {
        Write-Host "  [whatif] Grant '$($team.permission)' on $Org/$Repo -> @$Org/$($team.slug)"
    }

    Write-Host ''
}

Write-Host "Done. Run 'Get-Teams.ps1 -Repo $Repo' to verify the result."
