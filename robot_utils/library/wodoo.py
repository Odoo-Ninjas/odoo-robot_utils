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
    def command(self, shellcmd):
        path = os.getenv("ODOO_HOME", os.getenv("CUSTOMS_DIR"))
        if not path:
            raise Exception(
                "ODOO_HOME or CUSTOMS_DIR environment variable is not set")
        
        cwd = Path(path)
        assert cwd.exists(), "Path {cwd} should exist."
        cmd = 'odoo -p "$project_name" ' + shellcmd
        return self._cmd(cmd, cwd=cwd, output=True)

    def _cmd(self, cmd, output=False, cwd=None):
        if cwd:
            cmd = f"cd '{cwd}' || exit -1;" f"{cmd}"
        if not output:
            res = check_call(cmd, shell=True)
        else:
            res = check_output(cmd, encoding="utf8", shell=True)
            return res
