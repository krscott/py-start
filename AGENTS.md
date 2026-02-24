# Agent Guide for py-start

This document is to provide agents information to avoid common mistakes.

## Quick Reference

| Action | Command |
|--------|---------|
| Type check | `python -m pyright` |
| Type check | `python -m mypy .` |
| Run all tests | `python -m pytest` |
| Run single test | `python -m pytest tests/test_file.py::test_name` |
| Format code | `./format.sh` |

## Environment & Dependencies

### Template

Run `./init-template.sh your_project_name` to initialize a new project from this template.
Then remove the example `greet` function and tests, and this "Template" section.

### Adding Dependencies

1. Add to `pyproject.toml` (`dependencies` or `optional-dependencies.dev`)
2. Add corresponding Nix package to `default.nix`
3. Run `pip install -e '.[dev]'`

**Important**: Always use `pip install -e '.[dev]'`, never `pip install <package>` directly.

### Nix Environment

**Common issues when working with Nix + venv setup:**

**missing .venv**
  - If .venv is not present, but nix exists on the system, do not create the
    virtual environment yourself. Ask the user to restart the agent from
    within a new `nix develop` environment.

**Tools can't find packages installed in venv:**
  - Running tools directly (e.g., `pytest`, `mypy`, `pyright`) uses Nix environment versions, which can't see venv packages
  - **Solution: Always use `python -m <tool>`** - this uses the venv's python and sees all venv packages
  - This is especially important after adding new dependencies
  - Examples: `python -m pytest`, `python -m mypy .`, `python -m pyright`

**mypy and type stubs:**
  - For packages without built-in type hints, add stub packages to dev dependencies
  - Example: `tqdm` requires `types-tqdm` in `[project.optional-dependencies.dev]`
  - If stub packages aren't available, add mypy override in `pyproject.toml`:
    ```toml
    [[tool.mypy.overrides]]
    module = "package_name"
    ignore_missing_imports = true
    ```

## Build, Test, and Lint

### Type Checking

Both mypy and pyright must pass. However, for non-trival pyright issues, it may
be better to set the error to be ignored in the config.

### Testing
* Tests in `tests/` directory
* Use pytest fixtures for setup/teardown
* Minimize use of mocks

## Code Style

### Type Hints
Use modern Python 3.10+ syntax:

```python
# BAD
def log_messages(messages: List[Optional[str]]):
    ...

# GOOD
def log_messages(messages: list[str | None]) -> None:
    ...
```

Avoid `Any` and `# type: ignore` unless necessary.

### Imports
* Imports go at the top of the file. Don't include within functions unless absolutely necessary.

### Error Handling
Prefer returning values over throwing exceptions.

```python
# Prefer values when error is handled locally
def process_data_safe(data: dict[str, str]) -> int | None:
    try:
        return int(data["key"])
    except (KeyError, ValueError):
        return None

# Use exceptions when caller needs to handle or for crash-with-trace
def process_data_strict(data: dict[str, str]) -> int:
    try:
        return int(data["key"])
    except KeyError as e:
        log.error("Missing required key: %s", e)
        raise
```

### Logging
* `print()` for direct user output (CLI responses)
* `logging` module for operational messages
* Use `log = logging.getLogger(__name__)`

### File System
Use `pathlib.Path` instead of `os.path`.

### Data-Oriented Design
Follow data-oriented design principles to keep code simple and maintainable:

```python
# BAD - Object-oriented approach
class UserProcessor:
    def __init__(self, user: User):
        self.user = user

    def process(self) -> ProcessedUser:
        # mix data and behavior
        ...

# GOOD - Data-oriented approach
@dataclass
class User:
    id: int
    name: str
    email: str

def process_user(user: User) -> ProcessedUser:
    # pure function transforms data
    ...
```

**Keep data structures simple:**
* Prefer composition over inheritance
* Make data easy to inspect, test, and serialize

## Documentation

### DESIGN.md
**Keep DESIGN.md up to date.**

This file serves as a blueprint for the application's architecture and design. If you make significant changes to:
*   The architecture (e.g., adding modules, changing entry points)
*   The interface (e.g., CLI arguments, environment variables)
*   The core functionality
*   The data flow

You **must** update `DESIGN.md` to reflect these changes. An AI agent should be able to read `DESIGN.md` and reproduce the current state of the application.
