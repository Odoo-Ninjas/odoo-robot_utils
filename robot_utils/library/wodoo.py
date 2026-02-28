from subprocess import check_output, check_call
from pathlib import Path
import os


class wodoo(object):
    def command(self, shellcmd, output=True):
        path = self.get_odoo_home()

        cwd = Path(path)
        assert cwd.exists(), "Path {cwd} should exist."
        project_name = os.environ["project_name"]
        cmd = f'odoo -p "{project_name}" ' + shellcmd
        return self._cmd(cmd, cwd=cwd, output=True)

    def get_odoo_home(self):
        for path in [os.getenv("ODOO_HOME"), os.getenv("CUSTOMS_DIR"), os.getenv("HOST_CUSTOMS_DIR")]:
            if not path:
                continue
            path = Path(path)
            if path.exists():
                return path
        raise Exception(
            "ODOO_HOME or CUSTOMS_DIR or HOST_CUSTOMS_DIR environment variable is not set"
        )

    def _cmd(self, cmd, output=False, cwd=None):
        env = {}
        for key in ["PATH", "HOME"]:
            env[key] = os.environ[key]
        if not output:
            res = check_call(cmd, shell=True, cwd=cwd, env=env)
        else:
            res = check_output(cmd, encoding="utf8", shell=True, cwd=cwd, env=env)
            return res
