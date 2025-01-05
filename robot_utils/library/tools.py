import inspect
from datetime import date
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
import inspect
import os
from pathlib import Path
import logging
logger = logging.getLogger()
current_dir = Path(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe()))))


def load_default_environment():
    path = Path(".robot-vars")
    if not path.exists():
        return
    data = json.loads(path.read_text())
    for k,v in data.items():
        if k not in os.environ:
            os.environ[k] = v

    # TODO lost test filename

class Encoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, DotDict):
            return dict(obj)
        return super().default(obj)


class tools(object):
    def _odoo(self, server, db, username, password):
        """
        I'm sitting here xmlrpc.client.
        :return: None
        """
        common = xmlrpc.client.ServerProxy(f"{server}/xmlrpc/2/common")
        uid = common.authenticate(db, username, password, {})
        odoo = xmlrpc.client.ServerProxy(f"{server}/xmlrpc/2/object")
        return odoo, uid

    def execute_sql(self, server, db, user, password, sql, context=None):
        odoo, uid = self._odoo(server, db, user, password)
        odoo.execute_kw(db, uid, password, "robot.data.loader", "execute_sql", [sql])
        return True

    def get_res_id(self, server, db, user, password, model, module, name):
        odoo, uid = self._odoo(server, db, user, password)
        ir_model_obj = odoo.execute_kw(
            db,
            uid,
            password,
            "ir.model.data",
            "search_read",
            [[["model", "=", model], ["module", "=", module], ["name", "=", name]]],
            {
                "fields": [
                    "res_id",
                ]
            },
        )
        if not ir_model_obj:
            return False
        return ir_model_obj[0]["res_id"]

    def make_same_passwords(self, server, db, user, password):
        odoo, uid = self._odoo(server, db, user, password)
        sql = (
            "update res_users set password = "
            "(select password from res_users where id = 1)"
        )
        odoo.execute_kw(db, uid, password, "robot.data.loader", "execute_sql", [sql])

    def do_get_guid(self):
        return str(uuid.uuid4())

    def get_current_date(self):
        return date.today()

    def get_now(self):
        return arrow.get().datetime

    def copy_file(self, source, destination):
        shutil.copy(source, destination)

    def get_json_content(self, filepath):
        return json.loads(Path(filepath).absolute().read_text())

    def set_dict_key(self, data, key, value):
        data[key] = value

    def get_menu_res_id(self, server, db, user, password, module, name):
        return self.get_res_id(
            server, db, user, password, model="ir.ui.menu", module=module, name=name
        )

    def get_button_res_id(self, server, db, user, password, model, module, name):
        return self.get_res_id(
            server, db, user, password, model=model, module=module, name=name
        )

    def internal_set_wait_marker(self, server, db, user, password, name):
        odoo, uid = self._odoo(server, db, "admin", password)
        marker_name = f"robot-marker{name}"

        exists = odoo.execute_kw(
            db,
            uid,
            password,
            "ir.config_parameter",
            "search_count",
            [[["key", "=", marker_name]]],
        )
        if not exists:
            odoo.execute_kw(
                db,
                uid,
                password,
                "ir.config_parameter",
                "create",
                [
                    {
                        "key": marker_name,
                        "value": "1",
                    },
                ],
            )

    def internal_wait_for_marker(self, server, db, user, password, name, timeout=120):
        odoo, uid = self._odoo(server, db, user, password)
        deadline = arrow.get().shift(seconds=timeout)
        marker_name = f"robot-marker{name}"
        while arrow.get() < deadline:
            if odoo.execute_kw(
                db,
                uid,
                password,
                "ir.config_parameter",
                "search",
                [[["key", "=", marker_name]]],
            ):
                break
            time.sleep(1)
        else:
            raise Exception("Timeout")

    def odoo_convert_to_dictionary(self, value):
        value = value or {}
        return json.loads(json.dumps(value, cls=Encoder))

    def list_all_variables(self):
        context = BuiltIn().get_library_instance("BuiltIn")
        variables = context.get_variables()
        return variables

    def get_function_parameters(self, keyword):
        fkeyword = BuiltIn().run_keyword(keyword)
        signature = inspect.signature(fkeyword)
        return signature.parameters

    def My_Assert(self, expr, msg=""):
        if expr is False or expr is True:
            return expr
        if isinstance(expr, (int, float)):
            return bool(expr)

        if not isinstance(expr, str):
            raise Exception(f"Expression must be string at assert not: {type(expr)} {expr}")

        res = bool(eval(expr))
        if not res:
            msg = f"Assertion failed: {expr}\n{msg}"
            raise Exception(msg)

    def libraryDirectory(self):
        return str(current_dir)

    def Base64_Encode_File_Content(self, filepath):
        import base64
        bytes = Path(filepath).read_bytes()
        return base64.b64encode(bytes).decode('utf8')

    def Get_Var_Type(self, var):
        return str(type(var))

    def Is_Empty_String(self, var):
        # logger.error(f"Checking is empty string: var: {var} type: {type(var)} and result is {not bool(var)}")
        return not bool(var)

    def Is_Not_Empty_String(self, var):
        return not self.Is_Empty_String(var)

    def Is_List(self, var):
        return isinstance(var, (tuple, list))

    def eval(self, expr, **vars):
        """
        Usage:
        ${item}=      Eval  m[0].state  m=${modules}
        """
        return eval(expr, vars)

    def prepend_parent_in_tools(self, path, parent, xpath_parent):
        # Check if path is a list
        is_list = isinstance(path, (tuple, list))

        if is_list:
            new_path=[]
            for item in path:
                item = ''.join(filter(bool, [xpath_parent, parent, item]))
                new_path.append(item)
            path = new_path
        else:
            path = ''.join(filter(bool, [xpath_parent, parent, path]))
        return path

    def Get_File_Name(self, path):
        return Path(path).name

    def get_current_time_ms(self):
        return time.time() * 1000

    def get_elapsed_time_ms(self, start_time):
        return (time.time() * 1000) - start_time