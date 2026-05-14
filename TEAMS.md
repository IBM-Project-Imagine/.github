# Teams

This document describes the team structure for the Project Imagine GitHub organization. Teams are the unit of permission management — repository access is granted to teams, never to individual users.

## Conventions

- **Slugs** are lowercase, kebab-case (e.g., `release-managers`, not `Release_Managers`).
- **Permissions are granted to teams, not individuals.** Any exception requires Steering Committee approval and is documented in the relevant repository's `CODEOWNERS` or settings.
- **Parent teams hold the broadest permissions.** Child teams inherit from their parent; do not re-grant the parent's permissions on a child unless narrowing scope.
- **Membership in multiple teams is expected.** A person is typically in one affiliation team, one or more role teams, and zero or more project teams.
- **Every team has a documented owner.** The owner is responsible for membership reviews (see [Reviews](#reviews)).

## Team Hierarchy

```
@IBM-Project-Imagine/members                        # base team; all org members
├── @IBM-Project-Imagine/maintainers                # write access to shared/incubating repos
│   └── @IBM-Project-Imagine/release-managers       # release/tag rights on shared repos
├── @IBM-Project-Imagine/admins                     # org owners; small
├── @IBM-Project-Imagine/security                   # security triage, sensitive paths
├── @IBM-Project-Imagine/steering-committee         # governance per GOVERNANCE.md §3.3
├── @IBM-Project-Imagine/tsc                        # technical steering per §3.4 (optional)
├── @IBM-Project-Imagine/affiliation-microsoft      # affiliation tracking
├── @IBM-Project-Imagine/affiliation-github
├── @IBM-Project-Imagine/affiliation-ibm
└── @IBM-Project-Imagine/bots                       # service accounts and automation
```

Project-specific teams are created per repository or project group and are **not** children of the role teams above:

```
@IBM-Project-Imagine/<project>-maintainers
@IBM-Project-Imagine/<project>-contributors
```

## Team Definitions

### Role teams

| Team | Purpose | Default repo permission | Membership criteria | Owner |
| --- | --- | --- | --- | --- |
| `members` | Base team. All org members belong to it. | Read on public/shared repos | Any org member | `admins` |
| `maintainers` | People with write access to shared and incubating repos. | Write on shared and incubating repos | Per GOVERNANCE §3.2 — nominated by an existing Maintainer, confirmed by lazy consensus | `steering-committee` |
| `release-managers` | Subset of Maintainers authorized to cut releases. | Maintain on shared repos (push tags, manage releases) | Designated by repo Maintainers; tracked in repo `MAINTAINERS.md` | `steering-committee` |
| `admins` | GitHub organization owners. Kept intentionally small. | Admin on org settings and all repos | Steering Committee designation; one or two per Founding Party | `steering-committee` |
| `security` | Handles security triage, CODEOWNERS for sensitive paths, and coordinated disclosure. | Read by default; CODEOWNERS write on `/security/` and similar paths | Designated per repo; cross-party representation required for shared repos | `steering-committee` |
| `bots` | Service accounts, GitHub Apps, automation identities. | Varies per repo; granted minimum required permission | Created via PR to `IBM-Project-Imagine/.github`; documented in [Bots](#bots) | `admins` |

### Governance teams

| Team | Purpose | Default repo permission | Membership criteria | Owner |
| --- | --- | --- | --- | --- |
| `steering-committee` | Highest decision-making body per GOVERNANCE §3.3. | Read | Appointed by each Founding Party; `<2>` seats per party | Each Founding Party manages its own seats |
| `tsc` | Technical Steering Committee per GOVERNANCE §3.4. | Read | One Maintainer per active shared repository | `steering-committee` |

### Affiliation teams

Affiliation teams track which Founding Party a member is associated with. They are used in `CODEOWNERS` to enforce cross-party review on shared repositories (per GOVERNANCE §4) and for audit reporting.

| Team | Purpose | Default repo permission | Membership criteria | Owner |
| --- | --- | --- | --- | --- |
| `affiliation-microsoft` | Members affiliated with Microsoft | None (informational) | Self-declared at onboarding; verified by `admins` | Microsoft `admins` seat |
| `affiliation-github` | Members affiliated with GitHub | None (informational) | Self-declared at onboarding; verified by `admins` | GitHub `admins` seat |
| `affiliation-ibm` | Members affiliated with IBM | None (informational) | Self-declared at onboarding; verified by `admins` | IBM `admins` seat |

Affiliation teams are informational only — they do **not** grant repo permissions. A member must also be in a role or project team to have access.

### Project teams

Created per project as needed. Naming convention: `<project>-<role>`.

| Pattern | Purpose | Default repo permission |
| --- | --- | --- |
| `<project>-maintainers` | Maintainers scoped to a specific project | Write or Maintain on that project's repos |
| `<project>-contributors` | Regular contributors with elevated access | Triage or Write on that project's repos |

Project teams are documented in the project's own `README.md` and `CODEOWNERS`.

## Permission Matrix

| Team | Org permission | Shared repos | Incubating repos | Sandbox repos |
| --- | --- | --- | --- | --- |
| `admins` | Owner | Admin | Admin | Admin |
| `maintainers` | Member | Write | Write | — |
| `release-managers` | Member | Maintain | Maintain | — |
| `security` | Member | Read (+ CODEOWNERS on sensitive paths) | Read | Read |
| `steering-committee` | Member | Read | Read | Read |
| `tsc` | Member | Read | Read | Read |
| `members` | Member | Read | Read | Read |
| Affiliation teams | — | — | — | — |

"—" means no permission granted at the team level. Members may still have access via other team memberships.

## CODEOWNERS Conventions

Per-repo `CODEOWNERS` files use team handles. Common patterns:

```
# Default reviewer for any change
*                       @IBM-Project-Imagine/<repo>-maintainers

# Security-sensitive paths
/security/              @IBM-Project-Imagine/security
/.github/workflows/     @IBM-Project-Imagine/security @IBM-Project-Imagine/<repo>-maintainers

# Cross-party review required on shared repos (one reviewer from any two parties)
# Enforced via repo ruleset requiring CODEOWNERS review, with reviewers spanning teams:
/core/                  @IBM-Project-Imagine/affiliation-microsoft @IBM-Project-Imagine/affiliation-github @IBM-Project-Imagine/affiliation-ibm
```

The last pattern is one approach to GOVERNANCE §4's "at least two Founding Parties represented" rule. The cleanest enforcement is via repo rulesets requiring a minimum number of approving reviewers from CODEOWNERS, combined with CODEOWNERS lines that list all three affiliation teams.

## Onboarding

When a new person joins the organization:

1. An `admins` member adds them to `members`.
2. They are added to the appropriate `affiliation-*` team.
3. They are added to project or role teams as required by their work.
4. The change is recorded in the org audit log (automatic) and, for `steering-committee`, `admins`, or `maintainers` additions, in the next SC meeting minutes.

## Offboarding

When a person leaves:

1. Their Founding Party notifies `admins` (or the SC, for governance-level roles).
2. `admins` removes them from all teams. The person remains in the org's audit history.
3. Any `CODEOWNERS` entries naming the individual directly (which should be rare; teams are preferred) are updated.
4. For `release-managers` or `admins` departures, secrets and signing keys they had access to are rotated.

## Reviews

Each team owner reviews membership at least **annually**. Affiliation teams are reviewed whenever a Founding Party reports a personnel change. Reviews are tracked in `IBM-Project-Imagine/governance` as issues labeled `team-review`.

## Bots

Service accounts and automation identities used by this organization. Each bot has a documented purpose, owner, and credential rotation policy.

| Bot | Purpose | Owner | Credential rotation |
| --- | --- | --- | --- |
| *(none yet)* | | | |

Adding a bot requires a PR to this document and `admins` approval.

## Changes to This Document

Changes follow the governance change process (GOVERNANCE.md §12) when they affect role definitions, permissions, or affiliation team structure. Editorial changes and additions of project teams may be merged by `admins` without SC vote.

---

## Decisions still needed

0. **Is this too much?** — we want to balance speed and control. Also, this serves as an example of what's possible when adopting cross-organization collaboration and Inner Source practices.
1. **Admin team size** — one or two per Founding Party. Two gives redundancy; one keeps the privileged group small.
2. **Maintain vs Write for `release-managers`** — Maintain lets them manage releases without full repo admin, which is usually what you want.
3. **Affiliation enforcement mechanism** — CODEOWNERS lines listing all three affiliation teams (as above), or repo ruleset requiring N reviewers from a labeled set? The ruleset approach is cleaner once GitHub's "required reviewers from distinct teams" feature is more mature.
4. **Bots policy** — confirm the "PR to add a bot" approach, or require SC approval.
5. **Membership review cadence** — annual is suggested; some orgs do semi-annually for `admins` and `maintainers`.