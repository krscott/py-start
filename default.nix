{
  buildPythonPackage,
  lib,
  pythonOlder,
  pytestCheckHook,
  python-dotenv,
  setproctitle,
  setuptools,
}:
buildPythonPackage {
  name = "py-start";
  src = lib.cleanSource ./.;
  pyproject = true;
  disabled = pythonOlder "3.12";

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [
    python-dotenv
    setproctitle
  ];

  # Isolate the CLI before Python fixup adds the packaged dependency paths.
  postInstall = ''
    sed -i '1s/$/ -I/' "$out/bin/pystart"
  '';

  nativeCheckInputs = [
    pytestCheckHook
  ];

  # Skip integration tests during build (they require the installed executable)
  disabledTestMarks = [ "integration" ];

  # pythonImportsCheck = [ "py_start" ];

  meta = {
    mainProgram = "pystart";
    # description = "A short description of my application";
    # homepage = "https://github.com";
    # license = lib.licenses.mit;
  };
}
