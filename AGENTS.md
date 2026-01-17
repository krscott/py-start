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
| Run all tests | `pytest` |
| Run single test | `pytest tests/test_file.py::test_name` |
| Run tests verbose | `pytest -v` |

## 1. Environment & Dependencies

### Template

This repository contains example code (the `greet` function and related tests) that
demonstrates the coding standards. The `init-template.sh` script automates the
template initialization process.

**When starting a new project from this template:**

1. Run `./init-template.sh your_project_name` to rename the project
2. Remove the example `greet` function from `your_project/lib.py`
3. Remove the example test from `tests/test_lib.py`
4. Update `your_project/__init__.py` to export your own functions
5. Update `your_project/__main__.py` with your own CLI implementation
6. Replace this "Template" section to describe your project's specific structure and conventions

The examples are provided to show proper style and can be referenced as models for
your own implementation.

### Dependencies
*   **Python Dependencies**: Defined in `pyproject.toml`
    *   `dependencies`: Production dependencies (e.g., mypy)
    *   `optional-dependencies.dev`: Development tools (pytest, isort, black)
*   **System/Dev Tools**: Defined in `flake.nix` under `devPkgs`
*   **Python Version**: `>=3.10.12` (specified in `pyproject.toml`)

### Adding Python Dependencies

This project uses a three-layer dependency management system:
1. **`pyproject.toml`** - Declares what Python packages you want (source of truth)
2. **`default.nix`** - Maps Python packages to Nix packages (for reproducibility)
3. **`pip install -e '.[dev]'`** - Installs packages from pyproject.toml into your venv

**The workflow for adding dependencies:**

1. **Update `pyproject.toml`** (declare what you want):
   * For runtime dependencies, add to the `dependencies` list:
     ```toml
     dependencies = [
         # ...
         "new-package~=1.0",  # Add your dependency here with version constraint
     ]
     ```
   * For development-only dependencies, add to the `project.optional-dependencies.dev` list:
     ```toml
     [project.optional-dependencies]
     dev = [
         # ...
         "dev-package~=2.0",  # Add your dev dependency here
     ]
     ```

2. **Update `default.nix`** (map to Nix packages):
   * For runtime dependencies, add to the `propagatedBuildInputs` list:
     ```nix
     propagatedBuildInputs = [
       # ...
       new-package  # Add the Nix package name here
     ];
     ```
   * Note: The Nix package name may differ from the PyPI name

3. **Update `flake.nix`** (only for system-level dev tools):
   * For development tools that aren't Python packages (like git, curl, etc.), add to the `devPkgs` list:
     ```nix
     devPkgs =
       with pkgs;
       [
         # ...
         new-dev-tool  # Add new development tool here
       ]
       ++ py-start.buildInputs;
     ```

4. **Install the dependencies**:
   * Run `pip install -e '.[dev]'` to install from pyproject.toml into your venv

**Important Notes**:
* ✅ **DO**: Run `pip install -e '.[dev]'` after updating pyproject.toml
* ❌ **DON'T**: Run `pip install <package-name>` directly (bypasses pyproject.toml)
* The key distinction: `pip install -e '.[dev]'` installs FROM pyproject.toml (correct), while `pip install <package>` installs a package directly (incorrect)
* Prefer specific version constraints in `pyproject.toml` (e.g., `~=1.0` or `>=1.0,<2.0`)
* Always update pyproject.toml first, then sync the Nix configuration

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
*   **Command**: `mypy .`
*   **Description**: Runs static type analysis on all Python files.
*   **Rule**: Zero errors allowed. All new code must include type hints.
*   **Tips**:
    *   For type stubs issues, try adding `types-<package>` package.
    *   Ignore third-party: If no stubs available, as a last resort, add `# type: ignore` comment

#### Type Checking Configuration

The project uses a strict mypy configuration defined in `pyproject.toml` under `[tool.mypy]`:

* Disallows untyped definitions with `disallow_untyped_defs = True`
* Enables warnings for various typing issues
* Excludes tests from type checking (to allow more flexible testing patterns)

All tool configurations (mypy, isort, black) are consolidated in `pyproject.toml` for easier management.

Run mypy with `mypy .` from the project root to check all files.

### Testing

Tests are run with `pytest`

#### Run Single Test
```bash
# Specific test function
pytest tests/test_lib.py::test_greet

# Specific test file
pytest tests/test_lib.py

# With verbose output
pytest tests/test_lib.py::test_greet -v

# With print statements shown
pytest tests/test_lib.py -s
```

#### Useful pytest Flags

These flags are particularly helpful for AI agents debugging tests:

*   `-v` / `--verbose` - Show detailed test names and results
*   `-s` / `--capture=no` - Show print statements and stdout
*   `-x` / `--exitfirst` - Stop on first failure (useful for debugging)
*   `--lf` / `--last-failed` - Run only tests that failed in the last run
*   `--ff` / `--failed-first` - Run failed tests first, then remaining tests
*   `--pdb` - Drop into debugger on failures
*   `-k EXPRESSION` - Run tests matching expression (e.g., `-k "test_greet or test_parse"`)
*   `--collect-only` - Show what tests would be run without running them

**Example workflow for debugging**:
```bash
pytest -x           # Run until first failure
pytest --lf --pdb   # Re-run failed test with debugger
pytest -v           # Verify all tests pass
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

Use the `logging` module for operational messages, and `print()` for direct user output.

**When to use each**:
*   `print()` → Direct user-facing output, results, CLI responses (e.g., the actual greeting in the greet function)
*   `log.info()` → Informational progress messages (e.g., "Starting server on port 8000")
*   `log.debug()` → Detailed debugging information (e.g., "Processing record 42 of 100")
*   `log.warning()` → Warning messages that don't stop execution
*   `log.error()` → Error messages for exceptions or failures

**Logger naming**:
*   Prefer `log = logging.getLogger(__name__)` over hard-coded strings
*   This provides better traceability and works correctly after template initialization
*   Example: `log = logging.getLogger(__name__)` not `log = logging.getLogger("py_start")`

**Example**:
```python
import logging

log = logging.getLogger(__name__)

def greet(name: str) -> None:
    log.debug("Greeting user...")  # Operational message
    print(f"Hello, {name}!")       # Direct user output
```

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
    *   Run `pytest` to verify tests pass (create tests for new functionality).
4.  **Commit**: Only commit once all checks pass.

### Pre-Commit Checklist
- [ ] Code is formatted with `./format.sh`
- [ ] Type checking passes: `mypy .` (zero errors)
- [ ] All tests pass: `pytest`
- [ ] New functionality has tests
- [ ] New code has modern type hints
- [ ] Logging used instead of print (except CLI output)

## 6. Entry Points

The project defines a CLI entry point in `pyproject.toml`:
*   **Command**: `pystart`
*   **Implementation**: `py_start.__main__:main`
*   **Usage**: After `pip install -e '.[dev]'`, run `pystart` from anywhere in the venv.

## 7. Reusable Template Components

This template includes reusable utilities that can be leveraged in your projects:

### EnvAction - CLI Arguments with Environment Variable Fallbacks

The `EnvAction` class in `py_start/__main__.py` provides a custom `argparse.Action` that allows CLI arguments to fall back to environment variables. This is useful for configuration that can be specified either on the command line or through environment variables.

**Features**:
- Automatically checks environment variables when CLI argument is not provided
- Handles boolean flags (with `nargs=0`)
- Automatically updates help text to show default values and environment variable names
- Respects `required` parameter logic based on presence of defaults or env vars

**Usage Example**:
```python
parser.add_argument(
    "-v",
    "--verbose",
    action=EnvAction,
    env_var="MYAPP_VERBOSE",
    nargs=0,
    help="show more detailed log messages",
)
```

This will:
1. Check if `-v` or `--verbose` is passed on the command line
2. If not, check if `MYAPP_VERBOSE` environment variable is set
3. Update the help text to show: "show more detailed log messages (env: MYAPP_VERBOSE)"

**When to use**:
- Configuration options that should work both from CLI and environment variables
- Containerized applications where env vars are preferred
- CI/CD pipelines where env vars are easier to manage than CLI flags

