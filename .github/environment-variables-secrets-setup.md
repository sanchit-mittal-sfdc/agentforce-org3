# GitHub Environment Setup: Secrets and Variables

Every secret and variable below must be created **separately in each GitHub Environment**:
`dev`, `int`, `qa`, `uat`, `production`.

Path in GitHub: **Settings → Environments → (environment name) → Environment secrets / Environment variables**

## How environment names are chosen

| Workflow | Environment used |
|---|---|
| Validation (on PR) | Target branch of the PR. `main` becomes `production`. Any other branch uses its own name (`dev`, `int`, `qa`, `uat`). |
| Deployment (manual) | The branch the workflow is run from. `main` becomes `production`. Any other branch uses its own name. |

## Secrets (Environment secrets)

| Name | Required? | Description | Example |
|---|---|---|---|
| `CLIENT_ID` | **Required** | Consumer Key of the Salesforce Connected App used for JWT login. | `3MVG9...xyz` |
| `JWT_KEY_FILE_CONTENT` | **Required** | Full text of the private key (`server.key`), including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines. The matching certificate (`.crt`) must be uploaded to the Connected App. | `-----BEGIN PRIVATE KEY-----`<br>`MIIE...`<br>`-----END PRIVATE KEY-----` |

## Variables: required

| Name | Description | Example |
|---|---|---|
| `USERNAME` | Login username in the target org. This user must be pre-authorized on the Connected App. | `sanchit.mittal@nestle.com.dev` |
| `INSTANCE_URL` | My Domain URL of the target org. | `https://nppc-ca-vet--dev.sandbox.my.salesforce.com` |
| `TEST_LEVEL` | Which Apex tests run during validate or deploy. Allowed values: `NoTestRun`, `RunLocalTests`, `RunSpecifiedTests`, `RunAllTestsInOrg`. Any other value (a typo) makes the `check-config` step fail the pipeline immediately. | `NoTestRun` (dev), `RunLocalTests` (production) |

## Variables: conditionally required

| Name | Required when | Description | Example |
|---|---|---|---|
| `TEST_CLASSES` | `TEST_LEVEL` is `RunSpecifiedTests`. The pipeline fails if it is empty in that case. | Test class names, separated by commas or spaces. | `AccountTriggerTest,VisitRelatedContactsControllerTest` |
| `DEPLOY_ALLOWED_USERS` | Required for the **deployment** workflow. If it is not set, nobody can deploy (safe default). Not needed for validation. | Comma-separated GitHub usernames allowed to deploy to this environment. Matching is case-insensitive and exact (`ali` does not match `alice`). | `sanchit-mittal,alice,bob` |

## Variables: optional

| Name | Default | Description | Example |
|---|---|---|---|
| `IS_RUN_VALIDATION` | ON | Switch for the validation dry-run. Only the exact string `false` turns it off. A warning is logged when it is skipped. | `false` |
| `IS_RUN_CODE_ANALYSIS` | ON | Switch for Code Analyzer (PMD for Apex, ESLint for LWC/Aura JS, etc.). Only the exact string `false` turns it off. The analysis is informational and never fails the pipeline. | `false` |
| `ALLOW_DESTRUCTIVE_CHANGES` | `false` | If `true`, components deleted in the delta (`destructiveChanges.xml`) are also deleted from the org. Keep it `false` in production unless intended. | `true` |
| `DELTA_USE_MANUAL_FROM_SHA` | off | Deployment only. If `true`, the delta base is `DELTA_MANUAL_FROM_SHA` instead of the `deployed/<env>` tag. Useful for the first deployment or for recovery. | `true` |
| `DELTA_MANUAL_FROM_SHA` | none | Starting commit SHA used when `DELTA_USE_MANUAL_FROM_SHA` is `true`. | `a1b2c3d4e5f6...` (full SHA) |
| `SF_CLI_VERSION` | `latest` | Pins the Salesforce CLI version. | `2.60.0` |
| `SGD_VERSION` | `latest` | Pins the `sfdx-git-delta` plugin version. | `6.10.0` |

## Quick setup checklist (per environment)

- [ ] Secret `CLIENT_ID`
- [ ] Secret `JWT_KEY_FILE_CONTENT`
- [ ] Variable `USERNAME`
- [ ] Variable `INSTANCE_URL`
- [ ] Variable `TEST_LEVEL`
- [ ] Variable `TEST_CLASSES` (only if `TEST_LEVEL` is `RunSpecifiedTests`)
- [ ] Variable `DEPLOY_ALLOWED_USERS` (only if deployments will run from this environment)
- [ ] Optional variables as needed

## Notes

- **Switch rule:** switches default to ON. Only the exact lowercase string `false` turns a feature off. `False`, `FALSE`, `no` or `0` do **not** turn it off.
- **Missing required values:** the `check-config` action fails the pipeline early with a clear error naming the missing item and the environment.
- **Dev org:** set `TEST_LEVEL=NoTestRun` in `dev`. With `RunLocalTests`, the dev org fails because of an existing test data conflict (`VisitRelatedContactsControllerTest`, `DUPLICATE_VALUE`) and org-wide coverage below 75%.
