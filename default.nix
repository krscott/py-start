{
  buildPythonApplication,
  lib,
  mypy,
  setuptools,
}:
buildPythonApplication {
  name = "py-start";
  src = lib.cleanSource ./.;
  pyproject = true;

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [
    mypy
  ];

  doCheck = false;

  pythonImportsCheck = [ "py_start" ];
}
