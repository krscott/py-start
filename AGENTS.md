# Agent Guide for py-start

Python project managed with **Nix**. Dev environment assumed active.

## Quick Reference

| Action | Command |
|--------|---------|
| Type check (required) | `mypy .` |
| Type check (optional) | `pyright` |
| Run all tests | `pytest` |
| Run single test | `pytest tests/test_file.py::test_name` |
| Format code | `./format.sh` |

## 1. Environment & Dependencies

### Template

Run `./init-template.sh your_project_name` to initialize a new project from this template.
Then remove the example `greet` function and tests, and replace this "Template" section.

### Adding Dependencies

Three-layer system:
1. **`pyproject.toml`** - Source of truth for Python packages
2. **`default.nix`** - Maps to Nix packages (add to `propagatedBuildInputs`)
3. **`flake.nix`** - System-level dev tools only (add to `devPkgs`)

**Workflow:**
1. Add to `pyproject.toml` (`dependencies` or `optional-dependencies.dev`)
2. Add corresponding Nix package to `default.nix`
3. Run `pip install -e '.[dev]'`

**Important**: Always use `pip install -e '.[dev]'`, never `pip install <package>` directly.

## 2. Build, Test, and Lint

### Type Checking
* **Command**: `mypy .`
* **Rule**: Zero errors allowed. All code must have type hints.
* Config in `pyproject.toml` under `[tool.mypy]`

**Pyright (optional):**
* Available in dev shell for additional type checking: `pyright`
* **Agent policy**:
  - Agents should run pyright and fix trivial issues (e.g., adding missing type annotations, fixing obvious type errors)
  - Only mypy is required to pass; pyright warnings are informational
  - Non-trivial pyright issues that require refactoring beyond simple type definitions should be left to the user
  - Examples of trivial fixes: adding return type annotations, annotating untyped variables
  - Examples of non-trivial issues: restructuring code to satisfy strict type checks, major API changes

### Testing
* Tests in `tests/` directory
* Use pytest fixtures for setup/teardown

**Write testable, functional units:**

Code should be organized into small, focused functions that are easy to test without mocks:

```python
# BAD - Hard to test, requires mocking
class DataProcessor:
    def __init__(self):
        self.db = connect_to_database()
        self.api = ExternalAPI()

    def process(self, user_id: int) -> Result:
        user = self.db.get_user(user_id)
        data = self.api.fetch_data(user.token)
        return self._transform(data)

# GOOD - Easy to test, no mocks needed
def transform_data(data: dict[str, Any]) -> Result:
    """Pure function - test with real data structures."""
    return Result(
        value=data["value"] * 2,
        status="processed"
    )

def process_user_data(user: User, data: dict[str, Any]) -> Result:
    """Business logic separated from I/O - test with real objects."""
    if not user.is_active:
        return Result(value=0, status="inactive")
    return transform_data(data)

def process(user_id: int, db: Database, api: ExternalAPI) -> Result:
    """I/O orchestration - only this function needs integration tests."""
    user = db.get_user(user_id)
    data = api.fetch_data(user.token)
    return process_user_data(user, data)
```

**Minimize mocks by separating concerns:**

* **Pure functions**: Test with real data structures, no mocks needed
* **Business logic**: Accept data as parameters, return values - test with real objects
* **I/O operations**: Isolate in thin wrapper functions - only these need mocks

```python
# Business logic - no mocks needed
def calculate_discount(price: float, user_tier: str) -> float:
    multipliers = {"basic": 0.95, "premium": 0.85, "vip": 0.75}
    return price * multipliers.get(user_tier, 1.0)

def test_calculate_discount():
    assert calculate_discount(100.0, "premium") == 85.0
    assert calculate_discount(100.0, "unknown") == 100.0

# I/O wrapper - mock only the external service
def get_user_tier(user_id: int, api: UserAPI) -> str:
    return api.fetch_user(user_id).tier

def test_get_user_tier(mocker):
    mock_api = mocker.Mock()
    mock_api.fetch_user.return_value = User(tier="premium")
    assert get_user_tier(123, mock_api) == "premium"
```

**When mocks are appropriate:**
* External services (HTTP APIs, databases)
* File system operations
* Time-dependent behavior (`datetime.now()`)
* System resources (network, processes)

**When to avoid mocks:**
* Pure business logic (use real data structures)
* Data transformations (use real input/output)
* Internal function calls (test the whole unit)
* Simple data classes and dataclasses

## 3. Code Style

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
* Absolute imports preferred: `from py_start.lib import greet`
* isort handles organization automatically

### Error Handling
Prefer returning values over throwing exceptions.

```python
# Prefer values when error is handled locally
def process_data(data: dict[str, str]) -> int | None:
    try:
        return int(data["key"])
    except (KeyError, ValueError):
        return None

# Use exceptions when caller needs to handle or for crash-with-trace
def process_data(data: dict[str, str]) -> int:
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

**Separate data from behavior:**
* Use plain data structures: `dict`, `list`, `dataclasses`
* Transform data through pure functions instead of methods
* Avoid complex class hierarchies and deep inheritance

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
* Prefer flat structures over nested ones when possible
* Use composition over inheritance
* Make data easy to inspect, test, and serialize

```python
# BAD - Complex inheritance
class BaseEntity:
    ...
class UserEntity(BaseEntity):
    ...
class AdminUserEntity(UserEntity):
    ...

# GOOD - Simple composition
@dataclass
class User:
    id: int
    name: str
    role: Role

@dataclass
class Role:
    name: str
    permissions: list[str]
```

**When to use classes:**
* Resource management (file handles, connections) - use context managers
* Encapsulating external APIs or complex state machines
* Keep methods focused on the object's core responsibility

## 4. Workflow

### Development Cycle
1. **Edit**: Make changes following style guidelines
2. **Verify**:
   * `pyright` or `mypy .` (zero errors)
   * `pytest` (write tests for new functionality)
   * `nix flake show '.?submodules=1'` (no nix errors)
   * `./format.sh` (only required after all feature work is done)
3. **Commit**: Only after all checks pass

### Pre-Commit Checklist
- [ ] `pyright` or `mypy .` passes
- [ ] `pytest` passes
- [ ] `nix flake show '.?submodules=1'` succeeds
- [ ] New code has type hints and tests
- [ ] AGENTS.md and README.md updated if outdated

## 5. Reusable Components

### EnvAction

`EnvAction` in `py_start/__main__.py` provides argparse arguments with environment variable fallbacks:

```python
parser.add_argument(
    "-v", "--verbose",
    action=EnvAction,
    env_var="MYAPP_VERBOSE",
    nargs=0,
    help="show more detailed log messages",
)
```
