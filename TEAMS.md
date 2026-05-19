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
| `admins` | GitHub organization owners. Kept intentionally small. Visibility: `closed` (visible to all org members). | Admin on org settings and all repos | Steering Committee designation; two per Founding Party | `steering-committee` |
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

# Cross-party review required on shared repos (at least two Founding Parties represented)
# Adopted approach: CODEOWNERS listing all three affiliation teams; any reviewer from any two parties satisfies the rule.
/core/                  @IBM-Project-Imagine/affiliation-microsoft @IBM-Project-Imagine/affiliation-github @IBM-Project-Imagine/affiliation-ibm
```

The last pattern is the adopted approach for GOVERNANCE §4's "at least two Founding Parties represented" rule: CODEOWNERS lines listing all three affiliation teams. A reviewer from any two parties satisfies the cross-party review requirement. See [Planned Evolution](#planned-evolution) for the future upgrade path using repo rulesets.

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

## Planned Evolution

Items intentionally deferred or identified for future revision. Each entry notes the condition that should trigger the revisit.

| Item | Current state | Planned change | Trigger |
| --- | --- | --- | --- |
| `release-managers` team | Permission level adopted (Maintain); team not yet created. | Create team and assign membership when the first release is ready to cut. | First release to cut. |
| Cross-party review enforcement | CODEOWNERS listing all three affiliation teams. | Migrate to repo rulesets with "required reviewers from distinct teams" for cleaner enforcement. | GitHub "required reviewers from distinct teams" feature reaches sufficient maturity. |
| Membership review cadence | Annual for all teams. | Move `admins` and `maintainers` to semi-annual review. | Org reaches substantial, sustained activity. |

---

## Adopted Decisions

1. **Admin team size** — Two per Founding Party. Redundancy is prudent for a small cross-party org.
2. **Maintain vs Write for `release-managers`** — Maintain. This allows release and tag management without granting full repo admin. Team creation is deferred; see [Planned Evolution](#planned-evolution).
3. **Affiliation enforcement mechanism** — CODEOWNERS lines listing all three affiliation teams. See [Planned Evolution](#planned-evolution) for the repo ruleset upgrade path.
4. **Bots policy** — A PR to this repository is sufficient to add a bot. SC approval is not required at this stage.
5. **Membership review cadence** — Annual for all teams. See [Planned Evolution](#planned-evolution) for a potential cadence increase for `admins` and `maintainers`.