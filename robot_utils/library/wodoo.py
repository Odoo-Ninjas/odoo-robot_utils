from subprocess import check_output, check_call
from pathlib import Path
import os


class wodoo(object):
    def command(self, shellcmd, output=True):
        path = os.getenv("ODOO_HOME") or os.getenv("CUSTOMS_DIR") or os.getenv("HOST_CUSTOMS_DIR")
        if not path:
            raise Exception(
                "ODOO_HOME or CUSTOMS_DIR or HOST_CUSTOMS_DIR environment variable is not set"
            )

        cwd = Path(path)
        assert cwd.exists(), "Path {cwd} should exist."
        project_name = os.environ["project_name"]
        cmd = f'odoo -p "{project_name}" ' + shellcmd
        return self._cmd(cmd, cwd=cwd, output=True)

    def _cmd(self, cmd, output=False, cwd=None):
        env = {}
        for key in ["PATH", "HOME"]:
            env[key] = os.environ[key]
        if not output:
            res = check_call(cmd, shell=True, cwd=cwd, env=env)
        else:
            res = check_output(cmd, encoding="utf8", shell=True, cwd=cwd, env=env)
            return res
