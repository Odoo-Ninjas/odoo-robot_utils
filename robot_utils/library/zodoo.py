from subprocess import check_call
from pathlib import Path
import json
import os
from urllib.request import Request, urlopen
from robot.libraries.BuiltIn import BuiltIn

class zodoo(object):
    def _get_project_name(self):
        context = BuiltIn().get_library_instance("BuiltIn")
        project_name = context.get_variable_value("${project_name}")
        return project_name

    def _get_trigger_url(self):
        return os.getenv("CODING_TRIGGER_URL")

    def command(self, shellcmd, output=True):
        trigger_url = self._get_trigger_url()
        if trigger_url:
            return self._cmd_via_trigger(trigger_url, shellcmd)

        path = self.get_odoo_home()
        cwd = Path(path)
        assert cwd.exists(), "Path {cwd} should exist."
        project_name = self._get_project_name()
        cmd = f'odoo -p "{project_name}" ' + shellcmd if project_name else f'odoo ' + shellcmd
        return self._cmd(cmd, cwd=cwd, output=True)

    def _cmd_via_trigger(self, trigger_url, shellcmd):
        BuiltIn().log_to_console(f"\nExecuting via trigger: {shellcmd}")
        url = f"{trigger_url}/odoo-command"
        data = json.dumps({"command": shellcmd}).encode()
        req = Request(url, data=data, headers={"Content-Type": "application/json"})
        try:
            resp = urlopen(req, timeout=300)
            result = json.loads(resp.read())
            if result.get("stdout"):
                BuiltIn().log_to_console(result["stdout"])
            if result.get("stderr"):
                BuiltIn().log_to_console(result["stderr"])
            return result.get("stdout", "")
        except Exception as e:
            BuiltIn().log_to_console(f"\nTrigger error: {e}")
            return ""

    def update_docker_compose(self, service, environment):
        RUN_DIR = Path(os.getenv("HOST_RUN_DIR"))
        compose_file = RUN_DIR / 'docker-compose.yml'
        assert compose_file.exists(), f"docker-compose.yml should exist in {RUN_DIR}"
        import yaml
        with open(compose_file) as f:
            compose = yaml.safe_load(f)
        for key, value in environment.items():
            compose['services'][service]['environment'][key] = value
        with open(compose_file, 'w') as f:
            yaml.dump(compose, f)

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
            check_call(cmd, shell=True, cwd=cwd, env=env)
        else:
            old_dir = os.getcwd()
            os.chdir(str(cwd) if cwd else old_dir)
            old_env = os.environ.copy()
            os.environ.update(env)
            BuiltIn().log_to_console(f"\nExecuting command: {cmd}")
            try:
                os.system(cmd)
            finally:
                os.chdir(old_dir)
                os.environ.clear()
                os.environ.update(old_env)
            return ""
