# Agent Guide for py-start

This repository is a Python project managed with **Nix**. All development 
actions (building, testing, formatting) should ideally be performed within the 
Nix environment to ensure reproducibility.

This doc assumes the dev environment is already active.

## Quick Reference

| Action | Command |
|--------|---------|
| Format code | `./format.sh` |
| Type check | `mypy .` |
| Run all tests | `python -m pytest` |
| Run single test | `python -m pytest tests/test_file.py::test_name` |
| Run tests verbose | `python -m pytest -v` |

## 1. Environment & Dependencies

### Template

This repository contains example code (the `greet` function and related tests) that
demonstrates the coding standards. When starting a new project:

1. Remove the example `greet` function from `py_start/lib.py`
2. Remove the example test from `tests/test_lib.py`
3. Update `py_start/__init__.py` to export your own functions
4. Update `py_start/__main__.py` with your own CLI implementation
5. Remove this section ("Template") of `AGENTS.md`

The examples are provided to show proper style and can be referenced as models for
your own implementation.

### Dependencies
*   **Python Dependencies**: Defined in `pyproject.toml`
    *   `dependencies`: Production dependencies (e.g., mypy)
    *   `optional-dependencies.dev`: Development tools (pytest, isort, black)
*   **System/Dev Tools**: Defined in `flake.nix` under `devPkgs`
*   **Python Version**: `>=3.10.12` (specified in `pyproject.toml`)

### Adding Python Dependencies
When adding new Python dependencies to the project, you need to update both the `pyproject.toml` file and the `default.nix` file to ensure consistency across all environments:

1. **Update `pyproject.toml`**:
   * For runtime dependencies, add to the `dependencies` list:
     ```toml
     dependencies = [
         "mypy~=1.9",
         "new-package~=1.0",  # Add your dependency here with version constraint
     ]
     ```
   * For development-only dependencies, add to the `project.optional-dependencies.dev` list:
     ```toml
     [project.optional-dependencies]
     dev = [
         "pytest",
         "isort",
         "black",
         "dev-package~=2.0",  # Add your dev dependency here
     ]
     ```

2. **Update `default.nix`**:
   * For runtime dependencies, add to the `propagatedBuildInputs` list:
     ```nix
     propagatedBuildInputs = [
       mypy
       new-package  # Add the Nix package name here
     ];
     ```

3. **Update `flake.nix` (if needed)**:
   * For development tools and system dependencies, add to the `devPkgs` list:
     ```nix
     devPkgs =
       with pkgs;
       [
         black
         isort
         mypy
         python3.pkgs.pytest
         python3.pkgs.venvShellHook
         new-dev-tool  # Add new development tool here
       ]
       ++ py-start.buildInputs;
     ```

4. **Using the updated dependencies**:
   * Run `pip install -e '.[dev]'` to install added dependencies

**Important Notes**:
* NEVER install dependencies directly with `pip`. ALWAYS update using `pip install -e '.[dev]'`.
* Always prefer to use a specific version constraint in `pyproject.toml` (e.g., `~=1.0` or `>=1.0,<2.0`)
* Ensure the package name in `default.nix` matches the Nix package name (may differ from PyPI name)

## 2. Build, Test, and Lint Commands

All commands should be executed from the project root directory.

### Formatting
*   **Command**: `./format.sh`
*   **What it does**: 
    1. Runs `isort .` to organize imports
    2. Runs `black .` to format code style
    3. Runs `nix fmt` on all `.nix` files (if nix is available)
*   **Rule**: ALWAYS run this before committing code.
*   **Config**: Black and isort use their defaults (no custom configuration files).

### Type Checking
*   **Command**: `mypy .` (inside dev shell) or `nix run .#mypy`
*   **Description**: Runs static type analysis on all Python files.
*   **Rule**: Zero errors allowed. All new code must include type hints.
*   **Tips**:
    *   For type stubs issues, try adding `types-<package>` package.
    *   Ignore third-party: If no stubs available, as a last resort, add `# type: ignore` comment

#### Type Checking Configuration

The project uses a strict mypy configuration defined in `mypy.ini`:

* Disallows untyped definitions with `disallow_untyped_defs = True`
* Enables warnings for various typing issues
* Excludes tests from type checking

Run mypy with `mypy .` from the project root to check all files.

### Testing

Tests are run with `pytest`

#### Run Single Test
```bash
# Specific test function
python -m pytest tests/test_lib.py::test_greet

# Specific test file
python -m pytest tests/test_lib.py

# With verbose output
python -m pytest tests/test_lib.py::test_greet -v

# With print statements shown
python -m pytest tests/test_lib.py -s
```

#### Test Organization
*   **Location**: All tests must be in the `tests/` directory.
*   **Naming**: 
    *   Test files: `test_*.py` or `*_test.py`
    *   Test functions: `test_*`
    *   Test classes: `Test*`
*   **Fixtures**: Use pytest fixtures for setup/teardown (see `capsys` usage in `tests/test_lib.py:3`).
*   **Coverage**: Aim for high coverage on new logic, especially core functionality.

## 3. Code Style & Conventions

### General Principles
*   **Python Version**: 3.10+ (supports modern type hints like `list[str]`, `dict[str, int]`)
*   **Formatting**: Strictly **Black** (code) and **Isort** (imports). Never manually format.
*   **Type Hints**: **Mandatory** for all public functions, methods, and class attributes.

### Type Hints
Use modern python type hints.

```python
# BAD - untyped
def log_messages(messages):
    for msg in messages:
        if msg:
            print(msg)

# BAD - legacy typing, inferred return
def log_messages(messages: List[Optional[str]]):
    ...

# GOOD - modern typing, explicit return
def log_messages(messages: list[str | None]) -> None:
    ...
```

Avoid `Any` and `# type: ignore` unless necessary.

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Variables/Functions | `snake_case` | `user_name`, `calculate_total()` |
| Classes | `PascalCase` | `UserAccount`, `DataProcessor` |
| Constants | `UPPER_CASE` | `MAX_SIZE`, `API_KEY` |
| Modules | `snake_case` | `py_start/lib.py`, `data_utils.py` |
| Private attributes | `_leading_underscore` | `_internal_cache` |

### Imports
*   **Absolute imports preferred**: Use `from py_start.lib import greet` not `from .lib import greet`.
*   **Automatic sorting**: `isort` handles organization (stdlib → third-party → local).
*   **No wildcard imports**: Avoid `from module import *`.

### Error Handling
Strongly prefer using values for errors instead of throwing exceptions.

In cases where exceptions are required, use specific, idiomatic code.

```python
import logging

log = logging.getLogger("py_start")

# BAD - Bare except, print statements
def process_data(data):
    try:
        value = data["key"]
        return int(value)
    except:
        print("Error occurred")
        return None

# GOOD - Pass-through exceptions, proper logging
def process_data(data: dict[str, str]) -> int:
    try:
        value = data["key"]
        return int(value)
    except KeyError as e:
        log.error("Missing required key: %s", e)
        raise
    except ValueError as e:
        log.error("Invalid integer value: %s", e)
        raise

# GOOD - Values instead of errors
def process_data(data: dict[str, str]) -> int | None:
    try:
        value = data["key"]
        return int(value)
    except KeyError as e:
        pass
    except ValueError as e:
        pass
    return None
```

#### Exceptions vs Values

Use *exceptions* where:
- Want to crash the program with a stack trace (e.g. `assert`)
- Required for library/interface

Use *values* where:
- The error both occurs and is handled within our code

### Logging
*   Use `logging` module, not `print()` statements (except for CLI output).
*   Logger naming: `log = logging.getLogger("py_start")`
*   Levels: `debug()` for detailed info, `info()` for general events, `warning()`/`error()` for issues.

### File System Operations
*   **Use `pathlib.Path`** instead of `os.path`:
```python
# Good
from pathlib import Path

config_file = Path("config") / "settings.json"
if config_file.exists():
    content = config_file.read_text()

# Bad
import os

config_file = os.path.join("config", "settings.json")
if os.path.exists(config_file):
    with open(config_file) as f:
        content = f.read()
```

### Docstrings
*   Use docstrings for public modules, classes, and functions.
*   Format: Google style or NumPy style (be consistent).
```python
def greet(name: str) -> None:
    """Print a greeting message.
    
    Args:
        name: The name of the person to greet.
    """
    print(f"Hello, {name}!")
```

## 4. Project Structure

Update this section as needed.

```
py-start/
├── py_start/              # Main package
│   ├── __init__.py        # Package initialization
│   ├── __main__.py        # CLI entry point (pystart command)
│   └── lib.py             # Core functionality
├── tests/                 # Test files
│   └── test_lib.py        # Tests for lib.py
├── flake.nix              # Nix dependencies and build config
├── default.nix            # Nix package definition
├── mypy.ini               # Mypy type checking configuration
├── pyproject.toml         # Python project metadata and dependencies
├── format.sh              # Formatting script
├── AGENTS.md              # This file - agent guidelines
├── CLAUDE.md              # Claude Code integration config
└── README.md              # Project documentation
```

## 5. Workflow for Agents

### Standard Development Cycle
1.  **Explore**: Read `pyproject.toml` and relevant source files to understand context.
2.  **Edit**: Make code changes following the style guidelines above.
3.  **Verify**:
    *   Run `./format.sh` to automatically fix formatting.
    *   Run `mypy .` to ensure type correctness (zero errors required).
    *   Run `python -m pytest` to verify tests pass (create tests for new functionality).
4.  **Commit**: Only commit once all checks pass.

### Pre-Commit Checklist
- [ ] Code is formatted with `./format.sh`
- [ ] Type checking passes: `mypy .` (zero errors)
- [ ] All tests pass: `python -m pytest`
- [ ] New functionality has tests
- [ ] New code has modern type hints
- [ ] Logging used instead of print (except CLI output)

## 6. Entry Points

The project defines a CLI entry point in `pyproject.toml`:
*   **Command**: `pystart`
*   **Implementation**: `py_start.__main__:main`
*   **Usage**: After `pip install -e '.[dev]'`, run `pystart` from anywhere in the venv.

## 7. Special Instructions for AI Coding Agents

When working with this codebase, AI assistants should:

1. **Follow Type Annotation Standards**: Always add return type annotations, even for
   functions that return None.

2. **Prefer Error Values Over Exceptions**: Follow the "Values instead of errors" pattern
   shown in the Error Handling section when appropriate.

3. **Ensure Consistent Documentation**: Add docstrings for all public functions, classes,
   and modules using the Google style format shown in examples.

4. **Apply Pre-Commit Checks**: Before suggesting committing changes, ensure the code would
   pass the pre-commit checklist (formatting, type checking, tests).

5. **Respect Project Structure**: Place new functionality in appropriate locations following
   the established project structure.

