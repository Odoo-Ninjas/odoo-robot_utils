import tempfile
import time
import os
import arrow
import base64
from pathlib import Path
from odoo import api, models
import tempfile
from pathlib import Path
from odoo import api, models
from odoo.tools import convert_xml_import, convert_csv_import
import inspect


class DataLoader(models.AbstractModel):
    _name = "robot.data.loader"
    _description = "Robot-Test Data Loader"

    @api.model
    def get_latest_file_in_folder(
        self, parent_dir, glob, younger_than, wait_until_exists
    ):
        younger_than = arrow.get(younger_than)
        started = arrow.get()
        while (arrow.get() - started).total_seconds() < 20:
            files = list(
                sorted(
                    Path(parent_dir).glob(glob or "**/*"),
                    key=lambda x: x.stat().st_mtime,
                )
            )
            files = [x for x in files if arrow.get(x.stat().st_mtime) > younger_than]
            if files:
                file = files[-1]
                return {
                    "filename": file.name,
                    "filepath": str(file),
                    "content": base64.b64encode(file.read_bytes()).decode("ascii"),
                }
            if not wait_until_exists:
                break
        return {}

    @api.model
    def put_file(self, filecontent, dest_path):
        content = base64.b64decode(filecontent)
        dest_path = Path(dest_path)
        dest_path.parent.mkdir(exist_ok=True, parents=True)
        dest_path.write_bytes(content)
        return True

    @api.model
    def execute_sql(self, sql):
        if os.getenv("DEVMODE") != "1":
            raise Exception("Requires devmode")
        self.env.cr.execute(sql)
        try:
            res = self.env.cr.fetchall()
            return res
        except:
            return True

    @api.model
    def load_data(self, content, file_type, module_name, filename):
        """Does basically the same like what at update happens when installing a module and
        loads the xml and csv files.

        Args:
            content ([string]): filecontent
            file_type (string): csv or xml
            module_name (string): faked module name
            filename (string):

        """

        filepath = Path(tempfile.mkstemp(suffix=file_type)[1])
        filepath.write_text(content)

        # V17 changed params
        signature = inspect.signature(convert_csv_import)
        parameters = signature.parameters

        param1 = self.env.cr
        if "env" in parameters:
            param1 = self.env

        try:
            if file_type == ".xml":
                with open(filepath, "rb") as file:
                    convert_xml_import(
                        param1,
                        module_name,
                        file,
                        idref={},
                        noupdate=False,
                    )
            elif file_type == ".csv":
                convert_csv_import(
                    param1,
                    module=module_name,
                    fname=Path(filename).name,
                    csvcontent=content.encode("utf-8"),
                )
        finally:
            filepath.unlink()

        return True

    @api.model
    def wait_sqlcondition(self, sql):
        condition = None
        while condition or condition is None:
            self.env.cr.execute(sql)
            condition = self.env.cr.fetchall()[0][0]
            self.env.cr.commit()
            self.env.clear()
            time.sleep(0.5)
        return True

    @api.model
    def wait_queuejobs(self):
        def count(state):
            self.env.cr.execute(
                "select count(*) from queue_job where state =%s", (state,)
            )
            return self.env.cr.fetchone()[0]

        def _get_enqueued_job():
            self.env.cr.execute(
                "select id from queue_job where state not in ('done', 'failed') "
                "order by date_enqueued, id "
                "limit 1"
            )
            ids = [x[0] for x in self.env.cr.fetchall()]
            if ids:
                return ids[0]

        while True:
            self.env.cr.execute(
                "update queue_job "
                "set date_enqueued = eta "
                "where date_enqueued is null and eta is not null "
            )
            if count("pending") > 0 and not count("started") and not count("enqueued"):
                self.execute_sql(
                    "update queue_job "
                    "set eta = null, date_enqueued = (select now() at time zone 'utc') "
                    "where id in ("
                    "   select id from queue_job "
                    "   where state not in ('done', 'failed') "
                    "   order by eta"
                    "   limit 1"
                    ")"
                )

            self.wait_sqlcondition(
                "select count(*) from queue_job where "
                "state not in ('done', 'failed') and "
                "date_enqueued < (select now() at time zone 'utc');"
            )
            job_id = _get_enqueued_job()
            if not job_id:
                break
            self.execute_sql(
                "update queue_job "
                "set date_enqueued = (select now() at time zone 'utc') "
                f"where id={job_id}"
            )
            self.env.cr.commit()

        return True
