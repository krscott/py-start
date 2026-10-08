# Design Document

Software requirements for `py-start`

## Overview

TODO - High-level, functional description

## Normative Language

The key words `MUST`, `MUST NOT`, `SHOULD`, `SHOULD NOT`, and `MAY` in this
document are to be interpreted as described in RFC 2119.

## Design Methodology

In descending order, this project optimizes for:

1. Correctness - ops MUST result in a good state
2. Reliability - ops SHOULD be reproducible
3. User-friendly - ops SHOULD have a minimal interface and useful error messages
4. Speed - ops SHOULD be efficient

User-visible requirements listed in this document MUST have corresponding
integration tests. Wherever possible, tests SHOULD be implemented first
(Red-Green-Refactor).

## Architecture

The application follows a clean separation of concerns:

- Entry Point (`__main__.py`): Handles CLI interaction and argument parsing
- TODO

## Python compatibility

The minimum Python version is 3.12. Choose the oldest interpreter in the locked
nixpkgs with a working package set for both runtime and development dependencies.
An interpreter alone is not enough: Python 3.11 is still present, but its package
set cannot evaluate the required dependencies.

The default Nix build runs unit tests on nixpkgs' default Python. The
`checks.python-minimum` flake check builds the same package on Python 3.12 and
runs its unit tests through `pytestCheckHook`. CI runs both builds and runs the
CLI integration tests in the default development shell. Tests on the minimum
interpreter catch runtime differences, such as eager annotation evaluation,
that type checking alone does not detect.

When raising the minimum, update these together:

- `requires-python` in `pyproject.toml`.
- Black's `target-version`, mypy's `python_version`, and pyright's `pythonVersion`.
- The `pythonOlder` guard in `default.nix`, which rejects unsupported interpreters.
- The interpreter used by `checks.python-minimum` in `flake.nix`.
- The version documented here and in AGENTS.md.

Black's target controls the syntax it writes; it does not check compatibility.
Mypy and pyright target the minimum version to check standard-library use.
Pyright also checks syntax compatibility, including syntax mypy may miss.

Runtime dependency floors match the minor versions tested by the locked nixpkgs.
Development tools come from Nix. Keep mypy unpinned in the dev extras so pip can
reuse Nix's version. Run Nix's Node-based `pyright` directly rather than installing
the PyPI wrapper, which downloads an npm package outside the Nix lock.
