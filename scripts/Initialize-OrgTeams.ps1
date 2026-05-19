#Requires -Version 5.1

<#
.SYNOPSIS
    Creates the initial team structure for the IBM-Project-Imagine GitHub organization.

.DESCRIPTION
    Bootstraps the 6 initial teams defined in TEAMS.md. The script is idempotent:
    it checks whether each team exists before creating it and skips teams that are
    already present.

    Teams created (in order):
      admins                secret  - GitHub organization owners. Kept intentionally small.
      members               closed  - Base team. All org members belong to it.
      maintainers           closed  - Write access to shared and incubating repos. (child of: members)
      affiliation-microsoft closed  - Members affiliated with Microsoft.            (child of: members)
      affiliation-github    closed  - Members affiliated with GitHub.               (child of: members)
      affiliation-ibm       closed  - Members affiliated with IBM.                  (child of: members)

    Prerequisites:
      - gh CLI installed and authenticated (gh auth login)
      - Authenticated account must have admin:org scope
      - Verify:  gh auth status
      - Refresh: gh auth refresh -s admin:org

.PARAMETER Help
    Display this help text and exit.

.EXAMPLE
    .\Initialize-Teams.ps1

    Creates all missing teams. Skips teams that already exist.

.EXAMPLE
    .\Initialize-Teams.ps1 -WhatIf

    Shows what would be created without making any API calls.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
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

# Teams are listed in creation order. Child teams must appear after their parent.
$TeamDefinitions = @(
    [ordered]@{
        slug        = 'admins'
        name        = 'Admins'
        description = 'GitHub organization owners. Kept intentionally small.'
        privacy     = 'closed'
        parent      = $null
    },
    [ordered]@{
        slug        = 'members'
        name        = 'Members'
        description = 'Base team. All org members belong to it.'
        privacy     = 'closed'
        parent      = $null
    },
    [ordered]@{
        slug        = 'maintainers'
        name        = 'Maintainers'
        description = 'Write access to shared and incubating repos.'
        privacy     = 'closed'
        parent      = 'members'
    },
    [ordered]@{
        slug        = 'affiliation-microsoft'
        name        = 'Affiliation: Microsoft'
        description = 'Members affiliated with Microsoft.'
        privacy     = 'closed'
        parent      = 'members'
    },
    [ordered]@{
        slug        = 'affiliation-github'
        name        = 'Affiliation: GitHub'
        description = 'Members affiliated with GitHub.'
        privacy     = 'closed'
        parent      = 'members'
    },
    [ordered]@{
        slug        = 'affiliation-ibm'
        name        = 'Affiliation: IBM'
        description = 'Members affiliated with IBM.'
        privacy     = 'closed'
        parent      = 'members'
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

Write-Host "Initializing teams for @$Org..."
Write-Host ''

# Tracks slug -> id for parent resolution. Populated as teams are created or found.
$resolvedIds = @{}

foreach ($team in $TeamDefinitions) {

    $existingId = Get-ExistingTeamId $team.slug

    if ($null -ne $existingId) {
        Write-Host "  [skip]   @$Org/$($team.slug) already exists (id: $existingId)"
        $resolvedIds[$team.slug] = $existingId
        continue
    }

    # Build request body
    $body = [ordered]@{
        name        = $team.name
        description = $team.description
        privacy     = $team.privacy
    }

    if ($null -ne $team.parent) {
        $parentId = $resolvedIds[$team.parent]
        if (-not $parentId) {
            Write-Error "Cannot resolve parent '$($team.parent)' for '$($team.slug)'. Ensure the parent team is defined earlier in the list."
        }
        $body['parent_team_id'] = $parentId
    }

    if ($PSCmdlet.ShouldProcess("@$Org/$($team.slug)", 'Create team')) {
        $result = $body | ConvertTo-Json -Compress | gh api "orgs/$Org/teams" --method POST --input -
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create team '$($team.slug)'. Check that your token has admin:org scope."
        }
        $created = $result | ConvertFrom-Json
        $resolvedIds[$team.slug] = $created.id
        Write-Host "  [create] @$Org/$($team.slug) (id: $($created.id))"
    } else {
        # WhatIf: record a placeholder so parent resolution works for subsequent teams.
        $resolvedIds[$team.slug] = -1
        Write-Host "  [whatif] @$Org/$($team.slug)"
    }
}

Write-Host ''
Write-Host 'Done. Run Get-TeamMembers.ps1 to verify the result.'
