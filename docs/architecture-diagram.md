# OCI Landing Zone — Architecture Diagram

This diagram can be rendered with any Mermaid-compatible viewer (GitHub, GitLab, Notion, VS Code with Mermaid extension).

```mermaid
graph TD
    subgraph Tenancy["🏢 Root Tenancy"]

        subgraph IAM["IAM Layer (tenancy-level)"]
            G1["👥 lz-platform-admins"]
            G2["👥 lz-developers"]
            G3["👥 lz-dba-team"]
            G4["👥 lz-network-admins"]
            G5["👥 lz-security-team"]
            G6["👥 lz-auditors"]
        end

        subgraph BudgetLayer["💰 Budget Alerts"]
            B1["📊 Budget: dev\n$100/month"]
            B2["📊 Budget: staging\n$250/month"]
            B3["📊 Budget: prod\n$1,000/month"]
        end

        subgraph DEV["📦 Compartment: dev"]
            DEV_NET["🌐 network"]
            DEV_COMP["⚡ compute"]
            DEV_DB["🗄️ database"]
            subgraph DEV_SEC["🔒 security"]
                DEV_VAULT["🔑 Vault (DEFAULT)"]
                DEV_LOGS["📋 Audit Logs\n(90 days)"]
                DEV_CG["🛡️ Cloud Guard"]
                DEV_ONS["🔔 Alerts Topic"]
            end
        end

        subgraph STAGING["📦 Compartment: staging"]
            STG_NET["🌐 network"]
            STG_COMP["⚡ compute"]
            STG_DB["🗄️ database"]
            subgraph STG_SEC["🔒 security"]
                STG_VAULT["🔑 Vault (DEFAULT)"]
                STG_LOGS["📋 Audit Logs\n(180 days)"]
                STG_ONS["🔔 Alerts Topic"]
            end
        end

        subgraph PROD["📦 Compartment: prod"]
            PRD_NET["🌐 network"]
            PRD_COMP["⚡ compute"]
            PRD_DB["🗄️ database"]
            subgraph PRD_SEC["🔒 security"]
                PRD_VAULT["🔑 Vault\n(VIRTUAL_PRIVATE)"]
                PRD_LOGS["📋 Audit Logs\n(365 days)"]
                PRD_ONS["🔔 Alerts Topic"]
            end
        end

    end

    B1 --> DEV
    B2 --> STAGING
    B3 --> PROD

    G1 -->|admin| DEV
    G1 -->|admin| STAGING
    G1 -->|admin| PROD
    G2 -->|developer| DEV
    G2 -->|developer| STAGING
    G3 -->|dba| DEV
    G3 -->|dba| STAGING
    G3 -->|dba| PROD

    style Tenancy fill:#f5f5f5,stroke:#333
    style DEV fill:#e8f4fd,stroke:#2196F3
    style STAGING fill:#fff8e1,stroke:#FFC107
    style PROD fill:#fce4ec,stroke:#E91E63
    style IAM fill:#e8f5e9,stroke:#4CAF50
    style BudgetLayer fill:#f3e5f5,stroke:#9C27B0
```

## Module Dependency Graph

```mermaid
graph LR
    COMP[compartments]
    IAM[iam]
    BUD[budgets]
    SEC[security-baseline]

    COMP -->|environment_compartment_ids| IAM
    COMP -->|environment_compartment_ids\nworkload_compartment_ids| BUD
    COMP -->|environment_compartment_ocid\nsecurity_compartment_ocid| SEC

    style COMP fill:#bbdefb
    style IAM fill:#c8e6c9
    style BUD fill:#fff9c4
    style SEC fill:#ffcdd2
```

## Deployment Order

```mermaid
sequenceDiagram
    participant TF as Terraform
    participant OCI as OCI API

    TF->>OCI: 1. Create environment compartments
    OCI-->>TF: compartment OCIDs

    TF->>OCI: 2. Create workload compartments (under envs)
    OCI-->>TF: workload OCIDs

    TF->>OCI: 3. Create IAM groups
    OCI-->>TF: group OCIDs

    TF->>OCI: 4. Create IAM policies
    OCI-->>TF: policy OCIDs

    TF->>OCI: 5. Create budgets + alert rules
    OCI-->>TF: budget OCIDs

    TF->>OCI: 6. Create Vault + KMS key
    OCI-->>TF: vault/key OCIDs

    TF->>OCI: 7. Create Object Storage bucket (audit logs)
    OCI-->>TF: bucket name

    TF->>OCI: 8. Create Service Connector (logs → bucket)
    TF->>OCI: 9. Enable Cloud Guard
    TF->>OCI: 10. Create Event Rules + ONS topics
    OCI-->>TF: all resource OCIDs

    Note over TF,OCI: Total: ~3-5 minutes on first apply
```
