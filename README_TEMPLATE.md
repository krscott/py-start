# py-start

Project description goes here.

## Documentation Structure

This repository contains several documentation files for different audiences:

- **README.md** - User-facing project documentation for developers using or deploying this project
- [**AGENTS.md**](AGENTS.md) - Comprehensive development guidelines for AI agents,
  including code style, conventions, and workflows

## Development

Update dependencies
```
nix flake update
```

Start nix dev shell
```
nix develop
```

Nix supplies runtime and development dependencies. On first use, the shell
creates a separate `.venv` for the checkout and installs only the local project
in editable mode, without resolving or downloading Python packages.

Declare Python dependencies in `pyproject.toml` and the corresponding Nix
packages in `default.nix` (runtime) or `flake.nix` (development tools). Exit and
re-enter `nix develop` after changing Nix dependencies. To refresh package
metadata or script entry points in an existing virtual environment, run:

```sh
python -m pip install --no-deps --no-build-isolation -e .
```

Nix is optional. For manual setup, install Python 3.12 or newer and Just, then:

```sh
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -e '.[dev]'
just check
```

The dev extra includes the Python pyright wrapper, which provides the `pyright`
command and may download Node and pyright on first use. `just format` skips Nix
formatting when Nix is absent and shell formatting when shfmt is absent.

## Python compatibility

Black's target controls the syntax it writes; it does not check compatibility.
Mypy and pyright target the minimum version to check standard-library use.
Pyright also checks syntax compatibility, including syntax mypy can miss.

`nix build` runs unit tests on nixpkgs' default Python, and `checks.python-minimum`
runs them on the minimum version. That catches runtime differences, such as eager
annotation evaluation, that type checking alone does not detect.

Runtime dependency floors match the minor versions tested by the locked nixpkgs.
Keep mypy unpinned in the dev extras to match Nix's version.

## Nix command isolation

The command built by `nix build` runs Python in [isolated mode (`-I`)](https://docs.python.org/3/using/cmdline.html#cmdoption-I).
It uses the packaged dependencies and ignores inherited `PYTHONPATH`,
`PYTHONHOME`, user site-packages, and the script directory for imports.
`PYSTART_VERBOSE` and the working directory's `.env` file still work. Python
leaves the environment variables available to application code and subprocesses.

Development shells, editable installs, and library imports use the active Python
environment. For plugins deliberately loaded through `PYTHONPATH`, remove the
`postInstall` block that adds `-I` in `default.nix` and adapt
`tests/test_nix_cli.py` to the intended plugin behavior.

`nix flake check` tests the installed command with conflicting Python settings
through `checks.nix-cli`. To run those tests directly after `nix build`:

```sh
nix develop -c env PYSTART_NIX_EXECUTABLE="$PWD/result/bin/pystart" python -m pytest tests/test_nix_cli.py
```
