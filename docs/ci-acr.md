# CI: building and publishing to Azure Container Registry

GitHub Actions builds the image(s) in this repository and pushes them to
`flowmatters.azurecr.io`. This replaces the Docker Hub (`joelrahman/...`) builds.

| Image | Dockerfile | Workflow |
| --- | --- | --- |
| `flowmatters.azurecr.io/conda-python-science` | `Dockerfile` | `.github/workflows/acr-image.yml` |

## What runs when

- **Push to `master`** that touches the image's files: build and push
  `sha-<short>` and `latest`. Changes to `.github/` and this file don't trigger
  a build.
- **Pull request** (images with a public base only): build without pushing. Images built
  `FROM flowmatters.azurecr.io/...` skip this, because a pull request has no registry
  credentials.
- **Manual run** (Actions → workflow → Run workflow, on `master`):
  - `mode=check` builds the image and diffs it against an existing ACR tag
    (`compare_tag`, default `latest`). The diff covers installed packages (conda, pip,
    dpkg, apk, gem), file hashes under the image's `WORKDIR`, and `Cmd`, `Entrypoint`,
    `Env` and the other config fields. It pushes nothing, and the result is in the job
    summary.
  - `mode=publish` builds and pushes, like a push to `master` does.
  `gh workflow run <workflow> -f mode=check` does the same from the command line.

Base images like `python-airflow-task` are not rebuilt automatically. When a base
changes, publish it first, then publish the images built on it. The chain is
`conda-python-science` → `python-airflow-task` → `openwater-airflow-task`.

## Azure side

Login uses GitHub OIDC with the user-assigned managed identity `conda-python-science-ci-acr-push`
(resource group `fm-k8s`). It has AcrPush on the `flowmatters` registry, and one
federated credential, `github-main`, with subject
`repo:flowmatters/conda-python-science:ref:refs/heads/master`. No password or key is stored.
The workflow reads the repository variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` and
`AZURE_SUBSCRIPTION_ID`.

Runs from any other ref (including tags) cannot log in. To publish from tags, add a
federated credential for that subject.

The login step exchanges an Entra token for an ACR refresh token rather than calling
`az acr login`, which needs a control-plane role. This is the same method as
`flowmatters/peper` (see its `docs/deployment/ci.md`).
