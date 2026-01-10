import logging

log = logging.getLogger("py_start")


def greet(name: str):
    log.debug("Greeting user...")
    print(f"Hello, {name}!")
