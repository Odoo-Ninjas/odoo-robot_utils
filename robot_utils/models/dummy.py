from odoo import fields, models


class RobotDummy(models.Model):
    _name = "robot.dummy"
    _description = "Dummy model for robot tests"

    name = fields.Char()
