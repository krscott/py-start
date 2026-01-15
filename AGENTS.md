# Agent Guide for py-start

This repository is a Python project template managed with **Nix**. All development actions (building, testing, formatting) should ideally be performed within the Nix environment to ensure reproducibility.

## 1. Environment & Dependencies

*   **Nix Flake**: The project uses `flake.nix` to pin dependencies (Python version, libraries, tools).
*   **Dev Shell**: Run `nix develop` to enter a shell with all dependencies (`python`, `pytest`, `black`, `isort`, `mypy`) available in your `PATH`.
    *   *Agent Note*: If you cannot run `nix develop`, assume tools are available in the current environment or use `nix run` wrappers as specified below.
*   **Dependencies**: Defined in `pyproject.toml` and `flake.nix`.
    *   Python dependencies: `pyproject.toml` (under `dependencies` or `optional-dependencies`).
    *   System/Dev dependencies: `flake.nix` (under `devPkgs`).

## 2. Build, Test, and Lint Commands

Execute these commands from the project root.

### Formatting
*   **Command**: `./format.sh`
*   **Description**: Runs `isort` (imports), `black` (code style), and `nix fmt` (if available).
*   **Rule**: Always run this before committing or verifying code.

### Type Checking
*   **Command**: `mypy .` (inside dev shell) or `nix run .#mypy`
*   **Description**: Runs static type analysis.
*   **Rule**: Zero errors allowed. All new code must be typed.

### Testing
*   **Command**: `pytest`
*   **Description**: Discovers and runs tests.
*   **Run Single Test**: `pytest tests/path/to/test_file.py::test_function_name`
*   **Rule**:
    *   Tests should be placed in a `tests/` directory (create if missing).
    *   Use `pytest` fixtures for setup.
    *   Aim for high coverage on new logic.

## 3. Code Style & Conventions

### General
*   **Python Version**: 3.10+ (Check `pyproject.toml` `requires-python`).
*   **Formatting**: Strictly **Black** and **Isort**. Do not manually format; use the script.
*   **Type Hints**: **Mandatory** for all function arguments and return values.
    ```python
    # Good
    def calculate_total(items: list[Item]) -> float: ...

    # Bad
    def calculate_total(items): ...
    ```

### Naming
*   **Variables/Functions**: `snake_case`
*   **Classes**: `PascalCase`
*   **Constants**: `UPPER_CASE`
*   **Modules**: `snake_case` (e.g., `py_start/lib.py`)

### Imports
*   Use absolute imports where possible (e.g., `from py_start.lib import greet`).
*   Grouped and sorted automatically by `isort`.

### Error Handling
*   Use specific exceptions (avoid bare `except:`).
*   Log errors using the `logging` module, not `print`.
    ```python
    import logging
    log = logging.getLogger(__name__)

    try:
        process_data()
    except ValueError as e:
        log.error("Failed to process data: %s", e)
        raise
    ```

### File System
*   Use `pathlib.Path` instead of `os.path` for file manipulations.
*   Assume the project root is the current working directory.

## 4. Workflow for Agents

1.  **Explore**: Read `pyproject.toml` and `flake.nix` to understand scope.
2.  **Edit**: Apply changes.
3.  **Verify**:
    *   Run `./format.sh` to fix style.
    *   Run `mypy .` to check types.
    *   Run `pytest` (if tests exist) or create a test to verify the change.
4.  **Commit**: Ensure no lint/type errors remain before finalizing.

