from datetime import date
from subprocess import check_output, check_call
import arrow
from pathlib import Path
import json
import shutil
import os
import time
import uuid
import xmlrpc.client
from robot.api.deco import keyword
from robot.utils.dotdict import DotDict
from robot.libraries.BuiltIn import BuiltIn


class wodoo(object):
    def command(self, shellcmd, output=True):
        path = os.getenv("ODOO_HOME", os.getenv("CUSTOMS_DIR", os.getenv("HOST_CUSTOMS_DIR")))
        if not path:
            raise Exception(
                "ODOO_HOME or CUSTOMS_DIR or HOST_CUSTOMS_DIR environment variable is not set")
        
        cwd = Path(path)
        assert cwd.exists(), "Path {cwd} should exist."
        project_name = os.environ['project_name']
        cmd = f'odoo -p "{project_name}" ' + shellcmd
        return self._cmd(cmd, cwd=cwd, output=True)

    def _cmd(self, cmd, output=False, cwd=None):
        env = {}
        for key in ['PATH', 'HOME']:
            env[key] = os.environ[key]
        if not output:
            res = check_call(cmd, shell=True, cwd=cwd, env=env)
        else:
            res = check_output(cmd, encoding="utf8", shell=True, cwd=cwd, env=env)
            return res
