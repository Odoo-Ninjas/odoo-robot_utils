from pathlib import Path
import subprocess
import debugpy
import os
import signal


SOCAT_FILE = Path("/tmp/debugpy.socat.pid")


class debug(object):

    def start(self):
        debugpy.listen(('0.0.0.0', 5678))
        debugpy.wait_for_client()