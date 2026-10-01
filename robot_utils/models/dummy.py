from odoo import api, fields, models


class RobotDummy(models.Model):
    _name = "robot.dummy"
    _description = "Dummy model for robot tests"

    name = fields.Char()

    @api.model
    def _robot_ensure_access(self):
        """Grant internal users full access to this model.

        Done in code instead of a security csv: robot_utils is shared by all
        odoo versions, and odoo 20 replaced ir.model.access / ir.model.access.csv
        with ir.access / ir.access.csv.
        """
        model = self.env["ir.model"].sudo().search([("model", "=", self._name)])
        group = self.env.ref("base.group_user")
        if "ir.access" in self.env:
            Access = self.env["ir.access"].sudo()
            vals = {"operation": "crud"}
        else:
            Access = self.env["ir.model.access"].sudo()
            vals = {
                "perm_read": True,
                "perm_write": True,
                "perm_create": True,
                "perm_unlink": True,
            }
        domain = [("model_id", "=", model.id), ("group_id", "=", group.id)]
        if not Access.search_count(domain):
            vals.update({"name": self._name, "model_id": model.id, "group_id": group.id})
            Access.create(vals)
