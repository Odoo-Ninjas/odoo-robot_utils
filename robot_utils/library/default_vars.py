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

    try:
        test = BuiltIn().get_variable_value(_make_robot_key("ODOO_PASSWORD"))
    except:
        test = None
    if not test:
        raise Exception(
            "Please define ODOO_PASSWORD in .robot-vars file. "
            "Or run at least one time 'odoo set-password'."
        )


def _make_robot_key(k):
    return f"${{{k}}}"


def _load_robot_vars():
    path = Path(".robot-vars")
    if not path.exists():
        return
    vars = json.loads(path.read_text())
    for k, v in vars.items():
        robotkey = _make_robot_key(k)
        BuiltIn().set_global_variable(robotkey, v)


def _load_default_values_from_env():
    for k,v in os.environ.items():
        robotkey = _make_robot_key(k)
        try:
            BuiltIn().get_variable_value(robotkey)
        except:
            BuiltIn().set_global_variable(robotkey, v)

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
