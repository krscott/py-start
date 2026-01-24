{
  buildPythonPackage,
  lib,
  pytestCheckHook,
  python-dotenv,
  setproctitle,
  setuptools,
}:
buildPythonPackage {
  name = "py-start";
  src = lib.cleanSource ./.;
  pyproject = true;

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [
    python-dotenv
    setproctitle
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  # pythonImportsCheck = [ "py_start" ];

  meta = {
    mainProgram = "pystart";
    # description = "A short description of my application";
    # homepage = "https://github.com";
    # license = lib.licenses.mit;
  };
}
