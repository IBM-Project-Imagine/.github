#Requires -Version 5.1

<#
.SYNOPSIS
    Adds one or more users to a specific IBM-Project-Imagine team.

.DESCRIPTION
    Adds each specified user to the given team. Accepts usernames inline
    (-Username) or from a plain-text file (-FromFile), one username per line.
    -Username and -FromFile are mutually exclusive.

    Lines beginning with '#' and blank lines in the file are ignored.

    Prerequisites:
      - gh CLI installed and authenticated (gh auth login)
      - Authenticated account must have admin:org scope
      - Verify:  gh auth status
      - Refresh: gh auth refresh -s admin:org

.PARAMETER Username
    One or more GitHub usernames to add. Mutually exclusive with -FromFile.

.PARAMETER Team
    The slug of the team to add the user(s) to (e.g. maintainers, affiliation-ibm).

.PARAMETER FromFile
    Path to a plain-text file containing usernames, one per line.
    Mutually exclusive with -Username.

.PARAMETER Help
    Display this help text and exit.

.EXAMPLE
    .\Add-TeamMember.ps1 -Username alice -Team maintainers

    Adds alice to the maintainers team.

.EXAMPLE
    .\Add-TeamMember.ps1 -Username alice, bob, carol -Team affiliation-microsoft

    Adds all three users to the affiliation-microsoft team.

.EXAMPLE
    .\Add-TeamMember.ps1 -FromFile .\new-maintainers.txt -Team maintainers

    Reads usernames from the file and adds each to the maintainers team.

.EXAMPLE
    .\Add-TeamMember.ps1 -Username alice -Team maintainers -WhatIf

    Shows what would be done without making any API calls.
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Inline')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Inline')]
    [string[]]$Username,

    [Parameter(Mandatory)]
    [string]$Team,

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
# Build user list
# ---------------------------------------------------------------------------

$users = @()

if ($PSCmdlet.ParameterSetName -eq 'File') {
    if (-not (Test-Path $FromFile)) {
        Write-Error "File not found: $FromFile"
    }
    $users = Get-Content $FromFile |
        Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' } |
        ForEach-Object { $_.Trim() }
} else {
    $users = $Username
}

if ($users.Count -eq 0) {
    Write-Host 'No users to process.'
    exit 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Write-Host "Adding $($users.Count) user(s) to @$Org/$Team..."
Write-Host ''

foreach ($user in $users) {
    if ($PSCmdlet.ShouldProcess("@$Org/$Team", "Add '$user'")) {
        $body = [ordered]@{ role = 'member' }
        $body | ConvertTo-Json -Compress | gh api "orgs/$Org/teams/$Team/memberships/$user" --method PUT --input - 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "  Failed to add '$user' to '@$Org/$Team'."
        } else {
            Write-Host "  [add]  $user -> @$Org/$Team"
        }
    } else {
        Write-Host "  [whatif] $user -> @$Org/$Team"
    }
}

Write-Host ''
Write-Host 'Done.'
