# Agent guide for py-start

Code from the original py-start template may be removed as the project evolves.

## Development environment

Use `nix develop` to enter the development shell. Nix supplies runtime and
development dependencies, including setuptools. Its hooks create `.venv` if
missing, activate it, and install only the local project in editable mode,
without resolving or downloading Python packages. Each worktree has its own
editable installation. Agents can run this themselves; no user restart is needed.
CI sets `PIP_NO_INDEX=1` when creating the environment to enforce this.

For noninteractive commands, use `nix develop -c <command>`, for example:

```sh
nix develop -c python -m pytest
```

Run Python tools such as pytest and mypy with `python -m <tool>` so they use the
active environment and can find its installed packages.

Run `pyright` directly. In the Nix shell, Nix supplies the Node program and the
creation hook skips pip dependencies. For manual setup, run
`python -m pip install -e '.[dev]'` to install the Python wrapper, which provides
the same command.
It may download Node and pyright on first use. Nix is optional; install Just
separately when working without it.

## Dependencies

Declare dependencies before installing them:

1. Add runtime dependencies to `pyproject.toml` under `dependencies`, or
   development dependencies under `project.optional-dependencies.dev`.
2. Add corresponding Nix runtime packages to `default.nix`. Add development
   tools needed by the Nix environment to `flake.nix`.
3. Exit and re-enter `nix develop` to load the updated Nix dependencies. To
   refresh package metadata or script entry points in an existing `.venv`, run
   `python -m pip install --no-deps --no-build-isolation -e .` in that shell.

For libraries without type hints, add available stub packages to development
dependencies. If stubs are unavailable, use a mypy override scoped to the
affected module in `pyproject.toml`.

## Validation

| Check | Command |
|-------|---------|
| Pyright | `pyright` |
| Mypy | `python -m mypy .` |
| Tests | `python -m pytest` |

Both type checkers must pass. Keep any necessary type-checking exceptions narrow
and explain why they are needed.

Use pytest fixtures for setup and teardown. Minimize mocks.

## Code style

- Use Python 3.12+ type hints, such as `list[str | None]`. See
  [Python compatibility](#python-compatibility) for the minimum-version policy.
- Keep imports at the top of the file unless a local import is necessary.
- Prefer returning values over raising exceptions. Make failures actionable.
- Use `pathlib.Path` instead of `os.path`.
- Prefer composition over inheritance and keep data easy to inspect, test,
  and serialize.

## Python compatibility

The minimum Python version is 3.12. Choose the oldest interpreter in the locked
nixpkgs whose package set works for both runtime and development dependencies.
An interpreter being present in nixpkgs is not enough.

When raising the minimum, update these together:

- `requires-python` in `pyproject.toml`.
- Black's `target-version`, mypy's `python_version`, and pyright's
  `pythonVersion` in `pyproject.toml`.
- The `pythonOlder` guard in `default.nix`, which rejects unsupported interpreters.
- The interpreter used by `checks.python-minimum` in `flake.nix`.
- The version in this file, in this section and under Code style.
- The manual setup instructions in the project README (`README_TEMPLATE.md`
  until the template is initialized).

The README's "Python compatibility" section explains how these settings are used.

## Nix-packaged command

The `-I` added to the `pystart` entry point in `default.nix` is deliberate. See
"Nix command isolation" in the project README before changing it.
