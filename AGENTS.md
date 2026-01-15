# Agent Guide for py-start

This repository is a Python project managed with **Nix**. All development actions (building, testing, formatting) should ideally be performed within the Nix environment to ensure reproducibility.

## Quick Reference

| Action | Command | Alternative |
|--------|---------|-------------|
| Format code | `./format.sh` | `nix run .#format` |
| Type check | `mypy .` | `nix run .#mypy` |
| Run all tests | `./pytest.sh` or `pytest` | `nix run .#test` |
| Run single test | `pytest tests/test_file.py::test_name` | - |
| Run tests verbose | `pytest -v` | - |
| Enter dev shell | `nix develop` | - |

## 1. Environment & Dependencies

### Nix Setup
*   **Nix Flake**: The project uses `flake.nix` to pin dependencies (Python 3.10+, pytest, black, isort, mypy).
*   **Dev Shell**: Run `nix develop` to enter a shell with all dependencies available in your `PATH`.
    *   A `.venv` virtual environment is automatically created with `pip install -e '.[dev]'`.
    *   *Agent Note*: If you cannot run `nix develop`, assume tools are available or use `nix run` wrappers.

### Dependencies
*   **Python Dependencies**: Defined in `pyproject.toml`
    *   `dependencies`: Production dependencies (e.g., mypy)
    *   `optional-dependencies.dev`: Development tools (pytest, isort, black)
*   **System/Dev Tools**: Defined in `flake.nix` under `devPkgs`
*   **Python Version**: `>=3.10.12` (specified in `pyproject.toml`)

## 2. Build, Test, and Lint Commands

All commands should be executed from the project root directory.

### Formatting
*   **Command**: `./format.sh` or `nix run .#format`
*   **What it does**: 
    1. Runs `isort .` to organize imports
    2. Runs `black .` to format code style
    3. Runs `nix fmt` on all `.nix` files (if nix is available)
*   **Rule**: ALWAYS run this before committing code. Never manually format Python files.
*   **Config**: Black and isort use their defaults (no custom configuration files).

### Type Checking
*   **Command**: `mypy .` (inside dev shell) or `nix run .#mypy`
*   **Description**: Runs static type analysis on all Python files.
*   **Rule**: Zero errors allowed. All new code must include type hints.
*   **Tips**:
    *   For type stubs issues: `pip install types-<package>`
    *   Ignore third-party: Add `# type: ignore` comment (sparingly)

### Testing

#### Run All Tests
*   **Command**: `./pytest.sh` or `pytest` or `nix run .#test`
*   **Note**: The `pytest.sh` script sets `PYTHONPATH=.:$PYTHONPATH` automatically.

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
```python
# Good - All types specified
def calculate_total(items: list[dict[str, float]], tax_rate: float = 0.1) -> float:
    return sum(item["price"] for item in items) * (1 + tax_rate)

# Bad - Missing types
def calculate_total(items, tax_rate=0.1):
    return sum(item["price"] for item in items) * (1 + tax_rate)

# Good - Return type even for None
def log_message(message: str) -> None:
    print(message)
```

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

log = logging.getLogger(__name__)

# Good - Specific exceptions, proper logging
def process_data(data: dict[str, str]) -> None:
    try:
        value = data["key"]
        result = int(value)
    except KeyError as e:
        log.error("Missing required key: %s", e)
        raise ValueError(f"Invalid data structure: {e}") from e
    except ValueError as e:
        log.error("Invalid integer value: %s", e)
        raise

# Bad - Bare except, print statements
def process_data(data):
    try:
        value = data["key"]
        result = int(value)
    except:
        print("Error occurred")
        return None
```

### Logging
*   Use `logging` module, not `print()` statements (except for CLI output).
*   Logger naming: `log = logging.getLogger(__name__)` (see `py_start/lib.py:3`).
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

```
py-start/
├── py_start/           # Main package
│   ├── __init__.py     # Package initialization
│   ├── __main__.py     # CLI entry point (pystart command)
│   └── lib.py          # Core functionality
├── tests/              # Test files
│   └── test_lib.py     # Tests for lib.py
├── flake.nix           # Nix dependencies and build config
├── pyproject.toml      # Python project metadata and dependencies
├── format.sh           # Formatting script
└── pytest.sh           # Test runner script
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
- [ ] Type hints added to all new functions
- [ ] Logging used instead of print (except CLI output)

### Common Issues
*   **Import errors in tests**: Run `./pytest.sh` instead of `pytest` directly (sets PYTHONPATH).
*   **Nix commands not working**: Enter dev shell first with `nix develop`.
*   **Type errors from untyped libraries**: Install type stubs (`pip install types-<package>`) or use `# type: ignore`.

## 6. Entry Points

The project defines a CLI entry point in `pyproject.toml`:
*   **Command**: `pystart`
*   **Implementation**: `py_start.__main__:main`
*   **Usage**: After `pip install -e .`, run `pystart` from anywhere in the venv.

