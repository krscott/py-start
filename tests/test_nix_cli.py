"""Regression tests for the installed Nix executable, selected explicitly by path."""

import os
import subprocess
from pathlib import Path

import pytest

pytestmark = pytest.mark.integration


@pytest.fixture
def nix_cli() -> Path:
    executable = os.environ.get("PYSTART_NIX_EXECUTABLE")
    if executable is None:
        pytest.skip("Set PYSTART_NIX_EXECUTABLE to the installed Nix command")
    path = Path(executable)
    assert path.is_absolute() and path.is_file(), f"Invalid Nix executable: {path}"
    return path


@pytest.fixture
def cli_env() -> dict[str, str]:
    env = os.environ.copy()
    for name in (
        "PYSTART_VERBOSE",
        "PYTHONPATH",
        "PYTHONHOME",
        "PYTHON_DOTENV_DISABLED",
    ):
        env.pop(name, None)
    return env


@pytest.mark.parametrize("module", ["dotenv", "sitecustomize"])
@pytest.mark.parametrize("args", [["--help"], ["Alice"]])
def test_caller_pythonpath(
    nix_cli: Path, cli_env: dict[str, str], tmp_path: Path, module: str, args: list[str]
) -> None:
    (tmp_path / f"{module}.py").write_text(
        'raise RuntimeError("Imported caller module")\n'
    )
    cli_env["PYTHONPATH"] = str(tmp_path)
    result = subprocess.run(
        [str(nix_cli), *args], cwd=tmp_path, env=cli_env, capture_output=True, text=True
    )
    assert result.returncode == 0, result.stderr
    if args == ["--help"]:
        assert "usage:" in result.stdout
    else:
        assert result.stdout == "Hello, Alice!\n"
    assert result.stderr == ""


def test_caller_pythonhome(
    nix_cli: Path, cli_env: dict[str, str], tmp_path: Path
) -> None:
    cli_env["PYTHONHOME"] = str(tmp_path / "missing-python")
    result = subprocess.run(
        [str(nix_cli)], cwd=tmp_path, env=cli_env, capture_output=True, text=True
    )
    assert result.returncode == 0, result.stderr
    assert result.stdout == "Hello, World!\n"
    assert result.stderr == ""


@pytest.mark.parametrize("settings", ["environment", "dotenv", "override"])
def test_application_settings(
    nix_cli: Path, cli_env: dict[str, str], tmp_path: Path, settings: str
) -> None:
    (tmp_path / "dotenv.py").write_text(
        'raise RuntimeError("Imported caller dotenv")\n'
    )
    cli_env["PYTHONPATH"] = str(tmp_path)
    cli_env["PYTHONHOME"] = str(tmp_path / "missing-python")
    if settings in {"dotenv", "override"}:
        (tmp_path / ".env").write_text("PYSTART_VERBOSE=1\n")
    if settings == "environment":
        cli_env["PYSTART_VERBOSE"] = "1"
    elif settings == "override":
        cli_env["PYSTART_VERBOSE"] = "0"
    result = subprocess.run(
        [str(nix_cli), "Alice"],
        cwd=tmp_path,
        env=cli_env,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    assert result.stdout == "Hello, Alice!\n"
    assert result.stderr == ("" if settings == "override" else "Greeting user...\n")
