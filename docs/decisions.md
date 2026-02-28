# Architecture Decision Records (ADRs)

This document captures key design decisions made in the OCI Landing Zone Modular project, including the context, options considered, and rationale behind each choice.

---

## ADR-001: Modular over monolithic design

**Date:** 2024-01  
**Status:** Accepted

### Context
The official OCI Landing Zone (oracle-quickstart/oci-landing-zones) is a comprehensive solution but requires deploying the entire stack at once. Teams in early OCI adoption often only need a subset of capabilities.

### Decision
Split the Landing Zone into four independently deployable modules: `compartments`, `iam`, `budgets`, `security-baseline`.

### Rationale
- Teams can adopt incrementally without accepting all defaults upfront
- Each module can be versioned, tested, and documented independently
- Failures in one module do not affect others during deployment
- Easier to understand and contribute to

### Trade-offs
- More coordination needed when modules depend on each other's outputs (mitigated by clear output contracts)
- Users must wire modules together themselves in the `full` example

---

## ADR-002: One IAM policy per group/environment combination

**Date:** 2024-01  
**Status:** Accepted

### Context
OCI IAM policies have a hard limit of 50 statements per policy resource. A naive approach (one policy per group) would hit this limit quickly for groups with many environments or complex permission sets.

### Decision
Create one `oci_identity_policy` resource per `{group, environment}` pair.

### Rationale
- Stays well within OCI's statement limit per policy
- Each policy is independently auditable: "what can lz-developers do in prod?"
- Granular Terraform state: `terraform taint` or destroy can target a single group/env
- Easier to review in OCI Console

### Trade-offs
- More policy resources in state (O(groups × environments))
- Policy names are generated — not user-defined (acceptable for managed resources)

---

## ADR-003: for_each over count for all named resources

**Date:** 2024-01  
**Status:** Accepted

### Context
Terraform's `count` creates resources indexed by integer. Removing an item from the middle of a list causes all subsequent resources to be destroyed and recreated.

### Decision
Use `for_each` exclusively for all resources with meaningful names (compartments, groups, policies, budgets).

### Rationale
- `for_each` uses stable string keys — adding or removing an environment does not affect others
- State is more readable: `module.compartments.oci_identity_compartment.environment["prod"]`
- Safer `terraform plan` output when modifying configurations

### Trade-offs
- Requires flattening nested structures with `flatten()` and `for` expressions (slightly more complex HCL)

---

## ADR-004: DEFAULT vault for non-production, VIRTUAL_PRIVATE for production

**Date:** 2024-01  
**Status:** Accepted

### Context
OCI Vault offers two tiers: DEFAULT (shared HSM partition, no extra cost) and VIRTUAL_PRIVATE (dedicated HSM, ~$1,000/month). Both provide equivalent key protection for most use cases.

### Decision
Default `vault_type` to `DEFAULT`. The `full` example uses `VIRTUAL_PRIVATE` for prod and `DEFAULT` for dev/staging.

### Rationale
- DEFAULT vaults provide FIPS 140-2 Level 3 protection, which is sufficient for most workloads
- Cost optimization: only pay for dedicated HSM where there's a regulatory or compliance requirement
- `vault_type` is a variable, so teams can override for their specific requirements

### Trade-offs
- Teams with strict regulatory requirements (PCI-DSS, FedRAMP) must explicitly set `VIRTUAL_PRIVATE` for all environments

---

## ADR-005: Dual budget alerts (FORECAST + ACTUAL)

**Date:** 2024-01  
**Status:** Accepted

### Context
OCI Budget alerts support two types: FORECAST (projected spend) and ACTUAL (real spend). Most examples only configure one.

### Decision
Create both a FORECAST and an ACTUAL alert for every budget, with configurable thresholds.

### Rationale
- FORECAST allows teams to act before hitting the limit (proactive)
- ACTUAL ensures teams are notified if the forecast was inaccurate (reactive fallback)
- Different thresholds (e.g., FORECAST at 80%, ACTUAL at 90%) create a two-stage warning system
- Minimal cost impact — alert rules are free

### Trade-offs
- More email notifications; teams should configure separate alert channels or filter by subject line

---

## ADR-006: Apache 2.0 License

**Date:** 2024-01  
**Status:** Accepted

### Context
The project is intended for use and contribution by the Oracle ACE community and broader OCI ecosystem.

### Decision
Use Apache License 2.0.

### Rationale
- Consistent with Oracle's open source projects and the official OCI Terraform modules
- Permissive enough for enterprise use without copyleft restrictions
- Includes explicit patent grant, which is important for infrastructure code
- Recognized and trusted by legal teams in enterprise environments
