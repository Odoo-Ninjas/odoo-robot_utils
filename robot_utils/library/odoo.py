import json
import base64
import os
from pathlib import Path
from copy import deepcopy
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from robot.utils.dotdict import DotDict

DEFAULT_LANG = "en_US"


def _convert_fields(fields):
    if isinstance(fields, str):
        fields = fields.split(",")
        fields = list(map(lambda x: x.strip(), fields))
    return fields


class Encoder(json.JSONEncoder):
    """
    Make values compatible.
    """

    def default(self, obj):
        if isinstance(obj, DotDict):
            return json.JSONEncoder.default(self, dict(obj))
        return json.JSONEncoder.default(self, obj)


def convert_args(method):
    def _convert_ids(ids):
        if isinstance(ids, str):
            ids = ids.split(",")
        if isinstance(ids, list):
            ids = list(map(int, ids))
        if ids and isinstance(ids, int):
            ids = [ids]
        return ids

    def wrapper(*args, **kwargs):
        if "fields" in kwargs:
            kwargs["fields"] = _convert_fields(kwargs["fields"])
        if "ids" in kwargs:
            kwargs["ids"] = _convert_ids(kwargs["ids"])
        if "id" in kwargs and kwargs["id"]:
            kwargs["id"] = _convert_ids(kwargs["id"])[0]
        result = method(*args, **kwargs)

        return result

    return wrapper


class odoo(object):
    def technical_testname(self):
        testname = BuiltIn().get_variable_value("${TEST NAME}")
        if not testname:
            testname = BuiltIn().get_variable_value("${SUITE NAME}")
        testname = testname.lower().replace(" ", "_")
        return testname

    def _get_context(self, default_values, lang):
        res = dict(deepcopy(default_values or {}))  # transform robot dictionary
        res["lang"] = lang or DEFAULT_LANG
        return res

    def get_conn(self, host, dbname, user, pwd):
        ssl = host.startswith("https")
        host = host.split("://", 1)[-1]
        if ":" in host:
            host, port = host.split(":")
            port = int(port)
        else:
            port = 443 if ssl else 80
        logger.debug(f"Connection to odoo with {host} {dbname} user: {user} pw: {pwd}")
        dbname = dbname or "odoo"
        import odoorpc

        db = odoorpc.ODOO(
            host=host,
            port=port,
            protocol="jsonrpc",
            # version=self.version or None,
            # timeout=self.timeout,
        )
        db.json(
            "/web/session/authenticate",
            {
                "db": dbname,
                "login": user,
                "password": pwd,
            },
        )

        # be compatible with more than 1 database
        db.login(dbname, user, pwd)
        return db

    def rpc_client_search(
        self,
        host,
        dbname,
        user,
        pwd,
        model,
        domain,
        limit,
        order,
        offset=None,
        count=False,
        lang=DEFAULT_LANG,
        context=None,
    ):
        db = self.get_conn(host, dbname, user, pwd)
        context = self._get_context(context, lang)
        limit = int(limit) if limit else None
        domain = eval(domain)
        logger.debug(f"Searching for records with domain {domain} {type(domain)}")
        obj = db.env[model]
        kwparams = {
            x: y
            for x, y in {
                "offset": int(offset or 0),
                "count": count,
                "limit": limit,
                "order": order,
                "context": context,
            }.items()
            if y
        }

        return obj.search(domain, **kwparams)

    def rpc_client_search_records(
        self,
        host,
        dbname,
        user,
        pwd,
        model,
        domain,
        limit,
        order,
        count=False,
        offset=None,
        lang=DEFAULT_LANG,
        context=None,
    ):
        ids = self.rpc_client_search(
            host=host,
            dbname=dbname,
            user=user,
            pwd=pwd,
            model=model,
            domain=domain,
            limit=limit,
            order=order,
            count=count,
            offset=offset,
            lang=lang,
            context=context,
        )
        db = self.get_conn(host, dbname, user, pwd)
        return db.env[model].browse(ids)

    @convert_args
    def rpc_client_search_read_records(
        self,
        host,
        dbname,
        user,
        pwd,
        model,
        domain,
        fields,
        limit,
        order,
        count=False,
        offset=None,
        lang=DEFAULT_LANG,
        context=None,
    ):
        fields = _convert_fields(fields)
        db = self.get_conn(host, dbname, user, pwd)
        context = self._get_context(context, lang)
        limit = int(limit) if limit else None
        domain = eval(domain)
        logger.debug(f"Searching for records with domain {domain} {type(domain)}")
        kwparams = {
            x: y
            for x, y in {
                "offset": int(offset or 0),
                "count": count,
                "limit": limit,
                "order": order,
                offset: int(offset or 0),
                "context": context,
            }.items()
            if y
        }
        obj = db.env[model]
        ids = obj.search(
            domain,
            **kwparams,
        )
        res = obj.read(ids, fields=fields, context=context)
        return res

    @convert_args
    def rpc_client_read(
        self,
        host,
        dbname,
        user,
        pwd,
        model,
        ids,
        fields=[],
        lang=DEFAULT_LANG,
        context=None,
    ):
        fields = _convert_fields(fields)
        context = self._get_context(context, lang)
        db = self.get_conn(host, dbname, user, pwd)
        obj = db.env[model]
        return obj.read(ids, fields=fields, context=context)

    @convert_args
    def rpc_client_write(
        self,
        host,
        dbname,
        user,
        pwd,
        model,
        ids,
        values,
        lang=DEFAULT_LANG,
        context=None,
    ):
        context = self._get_context(context, lang)
        db = self.get_conn(host, dbname, user, pwd)
        obj = db.env[model]
        values = self._parse_values(values)
        return obj.write(ids, values, context=context)

    @convert_args
    def rpc_client_execute(
        self,
        host,
        dbname,
        user,
        pwd,
        model,
        method,
        ids=None,
        params=None,
        kwparams=None,
        context=None,
        lang=DEFAULT_LANG,
    ):
        params = params or []
        kwparams = kwparams or {}
        context = self._get_context(context, lang)
        db = self.get_conn(host, dbname, user, pwd)
        kwparams["context"] = context
        if ids:
            params.insert(0, ids)
        return db.execute_kw(model, method, params, kwparams)

    def rpc_client_create(
        self, host, dbname, user, pwd, model, values, context=None, lang=DEFAULT_LANG
    ):
        context = self._get_context(context, lang)
        db = self.get_conn(host, dbname, user, pwd)
        obj = db.env[model]
        values = self._parse_values(values)
        res = obj.create(values)
        res = obj.browse(res)
        return res

    def rpc_client_ref_id(
        self, host, dbname, user, pwd, xml_id, context=None, lang=DEFAULT_LANG
    ):
        context = self._get_context(context, lang)
        obj = self.rpc_client_ref(host, dbname, user, pwd, xml_id)
        return obj.id

    def rpc_client_ref(self, host, dbname, user, pwd, xml_id):
        xml_id = xml_id.lower()
        db = self.get_conn(host, dbname, user, pwd)
        res = db.env.ref(xml_id)
        return res

    @convert_args
    def rpc_client_get_field(
        self, host, dbname, user, pwd, model, id, field, context=None, lang=DEFAULT_LANG
    ):
        object_informations = self.rpc_client_read(
            host, dbname, user, pwd, model, [id], [field], context=context, lang=lang
        )
        if object_informations:
            object_information = object_informations[0]
            return object_information[field]
        else:
            return False

    def put_file(self, host, dbname, user, pwd, file_path, dest_path_on_odoo_container):
        file_path = Path(file_path).absolute()
        logger.debug(
            f"Putting file content from {file_path} to {dest_path_on_odoo_container}"
        )
        content = Path(file_path).read_bytes()
        content = base64.encodebytes(content).decode("utf-8")

        db = self.get_conn(host, dbname, user, pwd)
        obj = db.env["robot.data.loader"]
        return obj.put_file(content, dest_path_on_odoo_container)

    def load_file(self, host, dbname, user, pwd, filepath, module_name):
        bi = BuiltIn()
        vars = bi.get_variables()
        filepath = Path(filepath).absolute()
        logger.debug(f"FilePath: {filepath}, cwd: {os.getcwd()}")
        db = self.get_conn(host, dbname, user, pwd)
        obj = db.env["robot.data.loader"]
        filepath = Path(filepath)
        content = Path(filepath).read_text()
        suffix = filepath.suffix

        # replace some environment variables:
        test_name = self.technical_testname()
        content = content.replace("${CURRENT_TEST}", test_name)
        content = content.replace("${ODOO_DB}", dbname)
        content = content.replace("${ODOO_VERSION}", str(vars["${ROBO_ODOO_VERSION}"]))
        for var_name, value in vars.items():
            value = str(value)
            # replaces ${VAR_NAME}; in var_name there is ${ inside
            content = content.replace(f"{var_name}", str(value))

        module_name = module_name.lower()

        # will make problems if paths not matching on remote sides and local if used at put file
        # for c in ";\\';\"?-":
        #     module_name = module_name.replace(c, "_")
        obj.load_data(content, suffix, module_name, filename=filepath.name)

    def exec_sql(self, host, dbname, user, pwd, sql):
        db = self.get_conn(host, dbname, user, pwd)
        return db.execute("robot.data.loader", "execute_sql", [sql])

    def _parse_values(self, values):
        values = json.loads(json.dumps(values, cls=Encoder))
        return values
