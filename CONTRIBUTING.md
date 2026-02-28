# Contributing to OCI Landing Zone Modular

Thank you for considering contributing! This guide will help you get started.

---

## Ways to Contribute

- **Bug reports** — open an issue with reproduction steps and your OCI provider version
- **Feature requests** — describe the use case and expected behavior
- **Code contributions** — new modules, fixes, or improvements
- **Documentation** — corrections, examples, or translations

---

## Development Setup

### Prerequisites

- Terraform >= 1.5
- tflint
- checkov (for security scanning)
- An OCI tenancy for testing (free tier works for most modules)

### Install tools

```bash
# tflint
brew install tflint   # macOS
# or
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# checkov
pip install checkov
```

---

## Code Standards

### Terraform style

- Run `terraform fmt -recursive` before committing
- All variables must have a `description`
- All outputs must have a `description`
- Use `for_each` instead of `count` for named resources
- Avoid hardcoded values — use variables with sensible defaults

### File structure per module

Every module must have:
```
modules/<name>/
├── main.tf        # Resource definitions
├── variables.tf   # Input variables
├── outputs.tf     # Output values
└── README.md      # Usage, inputs, outputs table
```

### Naming conventions

| Resource type | Convention | Example |
|--------------|------------|---------|
| Compartment | `lz-<env>` | `lz-prod` |
| Group | `lz-<role>` | `lz-developers` |
| Policy | `lz-policy-<group>-<env>` | `lz-policy-developers-dev` |
| Budget | `lz-budget-<env>` | `lz-budget-prod` |

---

## Pull Request Process

1. Fork the repository and create a branch: `feat/your-feature` or `fix/your-bug`
2. Make your changes following the code standards above
3. Run validation locally:
   ```bash
   terraform fmt -check -recursive
   tflint --recursive
   checkov -d . --framework terraform
   ```
4. Update the relevant `README.md` if you changed inputs/outputs
5. Open a PR with a clear description of what changed and why
6. Ensure the GitHub Actions CI passes

---

## Reporting Security Issues

Do **not** open a public issue for security vulnerabilities. Instead, contact the maintainers directly via the email listed in the repository profile.

---

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 license.
