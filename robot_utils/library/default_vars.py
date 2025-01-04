import json
import os
import subprocess
from pathlib import Path
from robot.libraries.BuiltIn import BuiltIn

defaults = {
    "BROWSER_WIDTH": "1024",
    "BROWSER_HEIGHT": "768",
    "SELENIUM_TIMEOUT": 10,
    "browser": "firefox",
    "BROWSER_HEADLESS": "0",
}

# if tests are run manually
def load_default_vars():
    _load_from_settings()
    _load_robot_vars()
    _load_default_values_from_env()
    _load_default_values()
    _load_test_defaults()

    try:
        test = BuiltIn().get_variable_value(_make_robot_key("ODOO_PASSWORD"))
    except:
        test = None
    if not test:
        raise Exception(
            "Please define ODOO_PASSWORD in .robot-vars file. "
            "Or run at least one time 'odoo set-password'."
        )

def _prepare_test_token(varsfile):
    content = json.loads(varsfile.read_text())
    content.setdefault("TOKEN", 1)
    content['TOKEN'] = int(content['TOKEN']) + 1
    varsfile.write_text(json.dumps(content, indent=2))
    TOKEN = "#" + str(content['TOKEN']).zfill(3)
    b = BuiltIn()
    b.set_global_variable(_make_robot_key("TOKEN"), TOKEN)
    test = b.get_variable_value(_make_robot_key("TOKEN"))
    assert TOKEN == test

def _make_robot_key(k):
    return f"${{{k}}}"

def os_get_env(key):
    if key not in os.environ:
        raise Exception(f"Please define {key} in environment variables.")
    return os.environ[key]

def _load_test_defaults():
    """
    Sets:

    -  SUITE_PATH

    """
    path = str(Path(BuiltIn().get_variable_value("${SUITE SOURCE}")).parent)
    BuiltIn().set_global_variable("${SUITE_PATH}", path)

    # For uploading files (selenium not stable - they change and adapt to fulfill
    # W3C:
    # https://github.com/SeleniumHQ/selenium/issues/10352
    b = BuiltIn()
    PORT = b.get_variable_value(_make_robot_key("ODOO_PORT"))
    ODOO_URL = os_get_env("ROBO_ODOO_HOST")
    if PORT and ":" not in ODOO_URL.split("://")[-1]:
        ODOO_URL += ":" + str(PORT)
    b.set_global_variable(_make_robot_key("ODOO_URL"), ODOO_URL)
    b.set_global_variable(_make_robot_key("DIRECTORY UPLOAD FILES LOCAL"), os_get_env("ROBO_UPLOAD_FILES_DIR_LOCAL"))
    b.set_global_variable(_make_robot_key("DIRECTORY UPLOAD FILES BROWSER DRIVER"), os_get_env("ROBO_UPLOAD_FILES_DIR_BROWSER_DRIVER"))


def _load_robot_vars():
    candidates = [
        '.robot-vars',
        '/opt/src/.robot-vars',
    ]
    for candidate in candidates:
        path = Path(candidate)
        if not path.exists():
            continue
        vars = json.loads(path.read_text())
        _prepare_test_token(path)
        for k, v in vars.items():
            if k == "TOKEN":
                continue
            robotkey = _make_robot_key(k)
            BuiltIn().set_global_variable(robotkey, v)
        break
    else:
        raise Exception("Please define .robot-vars file.")
    


def _load_default_values_from_env():
    for k,v in os.environ.items():
        robotkey = _make_robot_key(k)
        try:
            BuiltIn().get_variable_value(robotkey)
        except:
            BuiltIn().set_global_variable(robotkey, v)

    if "ODOO_HOME" in os.environ.keys():
        BuiltIn().set_global_variable(_make_robot_key("CUSTOMS_DIR"), os.environ["ODOO_HOME"])

def _load_default_values():
    for k, v in defaults.items():
        robotkey = _make_robot_key(k)
        try:
            test = BuiltIn().get_variable_value(robotkey)
        except:
            test = None
        if not test:
            BuiltIn().set_global_variable(robotkey, v)


def _load_from_settings():
    ret = subprocess.run(["odoo", "setting"], encoding="utf8", stdout=subprocess.PIPE)
    MAX = 5
    for i in range(MAX):
        for line in ret.stdout.splitlines():
            if line.strip().startswith("#"):
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip()
            if value:
                os.environ[key] = value
                robotkey = f"${{{key}}}"
                try:
                    # some recursive ones
                    BuiltIn().set_global_variable(robotkey, value)
                except:
                    if i == MAX - 1:
                        raise
