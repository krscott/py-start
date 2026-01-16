{
  buildPythonApplication,
  lib,
  mypy,
  python-dotenv,
  setuptools,
}:
buildPythonApplication {
  name = "py-start";
  src = lib.cleanSource ./.;
  pyproject = true;

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [
    mypy
    python-dotenv
  ];

  doCheck = false;

  pythonImportsCheck = [ "py_start" ];
}
