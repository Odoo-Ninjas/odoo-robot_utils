from subprocess import check_call, Popen, PIPE, STDOUT
from pathlib import Path
import os
import sys


class wodoo(object):
    def command(self, shellcmd, output=True):
        path = self.get_odoo_home()

        cwd = Path(path)
        assert cwd.exists(), "Path {cwd} should exist."
        project_name = os.environ["project_name"]
        cmd = f"git config --global --add safe.directory '{cwd}'"
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
            batchfile = []
            for k, v in env.items():
                batchfile.append(f'export {k}=\'{v}\'')
            batchfile.append("\n")
            batchfile.append(cmd)
            Path("/tmp/cmd").write_text("\n".join(batchfile))

            proc = Popen(
                cmd, shell=True, cwd=cwd, env=env,
                stdout=PIPE, stderr=STDOUT,
                encoding="utf8"
            )
            lines = []
            assert proc.stdout
            while True:
                line = proc.stdout.readline()
                if not line:
                    break
                sys.stdout.write(line)
                sys.stdout.flush()
                lines.append(line)
            proc.wait()
            res = "".join(lines)
            return res
