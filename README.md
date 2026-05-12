# Arches

Arches is a web-based, geospatial information system for cultural heritage inventory and management. Arches is purpose-built for the international cultural heritage field, and designed to record all types of immovable heritage, including archaeological sites, buildings and other historic structures, landscapes, and heritage ensembles or districts. For more information and background on the Arches project, please visit [archesproject.org](http://archesproject.org/).

For general inquiries and to get technical support from the wider Arches community, visit our [Community Forum](https://community.archesproject.org/).

For general user installation and app documentation, visit [arches.readthedocs.io](https://arches.readthedocs.io).

For the documentation pertaining to the version under development, visit [arches.readthedocs.io/en/latest](https://arches.readthedocs.io/en/latest).  We welcome new contributors; please see [Contributing to Arches](CONTRIBUTING.md) for details.

Issue reports are encouraged! [Please read this article](http://polite.technology/reportabug.html) before reporting issues.
*   [Report a Bug](https://github.com/archesproject/arches/issues/new?template=bug.md)
*   [File a Feature Ticket](https://github.com/archesproject/arches/issues/new?template=feature.md)


#### Quick Install

Installation is fully documented in the official documentation, [arches.readthedocs.io/en/stable](https://arches.readthedocs.io/en/stable), but assuming you have all of the dependencies installed you should make a virtual environment, activate it, and then run
```
    pip install arches
```
then
```
    arches-admin startproject myproject
```
enter the new `myproject` directory
```
    cd myproject
```
and run
```
    python manage.py setup_db
    python manage.py runserver
```
in a separate terminal, activate your virtual environment and navigate to the root directory of the project ( you should be on the same level as `package.json`) 
```
    cd myproject/myproject
```
and run
```   
    npm run build_development
```
to create a frontend asset bundle. This process should complete in less than 2 minutes.

Finally, visit `localhost:8000` in a browser (only Chrome is fully supported at this time).

If you run into problems, please review our full [installation documentation](http://arches.readthedocs.io/en/stable/installation/)

#### Release Cycle

Our general release cycle will typically be a functional release (either major if there are backward incompatible changes or minor, if there are not) every 9 months. Each functional release will typically be followed by one or more patch releases. See [semver.org](https://semver.org/) for version numbering.

-   Functional releases will usually introduce new functionality to the application, but could also include styling updates, enhancements to the UX, bug fixes, and performance improvements.
-   Patch releases are really only concerned with fixing any bugs related to the previous release or any other issues not yet addressed

#### Support for previous releases

- LTS (Long Term Support) releases will be maintained with patch releases for at least 27 months. Typically an LTS release will be the second minor release following a major release. 
- Feature releases (with the exception of stable releases) will be supported only until the next feature release. After that users are expected to upgrade to the latest release on [pypi.python.org](https://pypi.python.org/pypi/arches)

#### For details regarding future releases, see the [feature roadmap](https://github.com/archesproject/arches-roadmap).

---

## Flax & Teal Patched Build

This branch (`fat_dev/8.1.x`) tracks `upstream/dev/8.1.x` with additional patches applied by Flax & Teal. It is the basis for the `ghcr.io/flaxandteal/arches-base` Docker image.

### Applied patches

| Area | Description | Upstream commit/PR |
|---|---|---|
| Docker | Ubuntu 18.04→24.04, Python 3.8→3.12, Node 10→20 | `docker/8.1` branch |
| Docker | Modern NodeSource GPG keyring setup | `docker/8.1` branch |
| Docker | `pip install --prefer-binary` to avoid source builds | `docker/8.1` branch |
| Docker | Install `git` during npm build stage | `docker/8.1` branch |
| CI | Tag-triggered workflow to build and push `arches-base` image | `docker/8.1` branch |
| PostgreSQL | Remove `CREATE DATABASE template_postgis` from `init-unix.sql` (already provided by `postgis/postgis` image) | `docker/8.1` branch |
| App startup | Catch `PermissionError` from `generate_frontend_configuration()` so the app starts under a read-only filesystem | `docker/8.1` branch (`95873a9`) |
| Dependencies | `psycopg2` → `psycopg2-binary` (bundles libpq, no runtime `libpq-dev` needed) | `docker/8.1` branch |

### Docker image tagging

Images are built automatically when a tag matching `v*` is pushed. Tags follow the convention:

```
v<arches-version>-v<n>
```

- `<arches-version>` — the upstream Arches version this build is based on (matches `version` in `pyproject.toml`, e.g. `8.1.3`)
- `v<n>` — an internal increment starting at `v1`, increased whenever patches are added or changed without an upstream version bump

Examples:

| Tag | Meaning |
|---|---|
| `v8.1.3-v1` | First patched build based on Arches 8.1.3 |
| `v8.1.3-v2` | Second patched build on the same upstream version (e.g. an additional fix applied) |
| `v8.1.4-v1` | First patched build after upstream bumped to 8.1.4 |

To trigger a build from a specific commit:

```bash
git tag v8.1.3-fat1 <commit-sha>   # omit <commit-sha> to tag HEAD
git push origin v8.1.3-v1
```

The Arches version is embedded in the image as a label (`org.opencontainers.image.version`) and can be inspected without pulling:

```bash
docker inspect ghcr.io/flaxandteal/arches-base:v8.1.3-v1 | jq '.[0].Config.Labels'
```

### Staying in sync with upstream

`fat_dev/8.1.x` is kept up to date with `upstream/dev/8.1.x`. Before tagging a new build, pull the latest upstream changes:

```bash
git fetch upstream
git merge upstream/dev/8.1.x
```

If upstream introduces changes that conflict with the patches above, resolve them and update this table accordingly.
