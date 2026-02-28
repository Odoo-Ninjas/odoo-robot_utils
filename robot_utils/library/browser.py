import os
import subprocess
import selenium
import sys
import importlib.util
import inspect
import os
from pathlib import Path
from selenium.webdriver.remote.webdriver import WebDriver as RemoteDriver
from selenium.common.exceptions import SessionNotCreatedException
from selenium.webdriver.remote.file_detector import UselessFileDetector

from pathlib import Path
from robot.libraries.BuiltIn import BuiltIn
import logging

logger = logging.getLogger(__name__)

current_dir = Path(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe()))))

def load_module_from_file(module_name: str, path: str):
    path = str(Path(path).resolve())
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load spec for {path}")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = mod
    spec.loader.exec_module(mod)
    return mod

tools = load_module_from_file(
    "tools",
    current_dir / 'tools.py'
)

from tools import _make_robot_key
from tools import get_variable


def disable_remote_file_detector(driver):
    # verhindert, dass Selenium versucht /se/file zu benutzen
    driver.file_detector = UselessFileDetector()

class RemoteDriver2(RemoteDriver):
    def __init__(
        self, *args, do_start_session=False, desired_session_id=None, **kwargs
    ):
        self.do_start_session = do_start_session
        self.desired_session_id = desired_session_id
        super().__init__(*args, **kwargs)

    def start_session(self, capabilities: dict, *args, **kwargs) -> None:
        if not self.do_start_session:
            self.session_id = self.desired_session_id
            return
        super().start_session(capabilities, *args, **kwargs)


def clear_sessions():
    cmd = os.getenv("ROBO_WEBDRIVER_KILL_SWITCH")
    if not cmd:
        raise Exception(
            "Please configure ROBO_WEBDRIVER_KILL_SWITCH environment variable, example: curl http://localhost:4445/restart"
        )
    subprocess.run(cmd, shell=True, check=True)


def get_driver_for_browser(
    download_path,
    headless,
    try_reuse_session=True,
    clear_session_before=False,
    trycount=1,
):
    logger.info(f"Getting Driver For Browser: headless={headless}")
    if try_reuse_session:
        clear_session_before = False

    if clear_session_before:
        clear_sessions()

    bd = BrowserDriver(download_path, headless)
    instance = BuiltIn().get_library_instance("SeleniumLibrary")
    try:
        driver = bd.get_webdriver(try_reuse_session=try_reuse_session)
    except SessionNotCreatedException as e:
        if trycount == 1:
            return get_driver_for_browser(
                download_path,
                headless,
                try_reuse_session=False,
                clear_session_before=clear_session_before,
                trycount=trycount + 1,
            )
        raise
    logger.info(f"Got web-driver")
    instance.register_driver(driver, alias="robodriver")
    return driver



class BrowserDriver(object):
    def __init__(self, download_path, headless):
        browser = get_variable("ROBO_WEBDRIVER_BROWSER")
        assert browser in [
            "chrome",
            "firefox",
        ], f"{browser} is not a supported browser."
        self.browser = browser
        self.download_path = str(Path(download_path).absolute())
        self.headless = headless

        self.optionsClass = f"{browser.capitalize()}Options"
        self.optionsMethod = f"_add_options_for_{browser}"

    def get_webdriver(self, try_reuse_session=True):
        options = self.create_options()
        sessionId = None
        WEBDRIVER_HOST = get_variable("ROBO_WEBDRIVER_HOST") # path to geckodriver --host <ip> --port <port> example: 192.168.64.2:4444
        session_file = Path("/tmp/seleniumsession")
        if session_file.exists() and try_reuse_session:
            sessionId = session_file.read_text().strip()

        try:
            driver = RemoteDriver2(
                command_executor=f"http://{WEBDRIVER_HOST}",
                options=options,
                desired_session_id=sessionId,
                do_start_session=not sessionId,
            )
            if not driver.session_id:
                raise selenium.common.exceptions.InvalidSessionIdException()
            session_file.write_text(driver.session_id)
            # make simple to call to challence invalid sessionid exception
            driver.get_cookie("testcookie")
        except selenium.common.exceptions.InvalidSessionIdException:
            driver = RemoteDriver2(
                command_executor=f"http://{WEBDRIVER_HOST}",
                options=options,
                do_start_session=True,
            )
            session_file.write_text(driver.session_id)
        disable_remote_file_detector(driver)
        return driver

    def create_options(self):
        options = getattr(selenium.webdriver, self.optionsClass)()
        if os.getenv("ROBO_FORCE_HEADLESS") == "1" or self.headless:
            options.add_argument("--headless")
        BROWSER_WIDTH = BuiltIn().get_variable_value("${BROWSER_WIDTH}")
        BROWSER_HEIGHT = BuiltIn().get_variable_value("${BROWSER_HEIGHT}")
        options.add_argument(f"--window-size={BROWSER_WIDTH},{BROWSER_HEIGHT}")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-popup-blocking")
        res = getattr(self, self.optionsMethod)(options)
        return res

    def _add_options_for_chrome(self, options):
        options.add_experimental_option(
            "prefs",
            {
                "download.default_directory": self.download_path,
                "download.prompt_for_download": False,
                "download.directory_upgrade": True,
                "download.extensions_to_open": "",
                "plugins.always_open_pdf_externally": True,
            },
        )
        options.add_argument("--disable-gpu")
        options.add_argument("--disable-web-security")
        options.add_argument("--disable-site-isolation-trials")
        return options

    def _add_options_for_firefox(self, options):
        options.set_preference(
            "browser.helperApps.neverAsk.saveToDisk",
            "application/pdf,text/plain,application/octet-stream",
        )
        options.set_preference("browser.download.folderList", 2)
        options.set_preference("browser.download.manager.showWhenStarting", False)
        options.set_preference("browser.download.dir", self.download_path)
        options.set_preference(
            "browser.helperApps.neverAsk.saveToDisk", "application/pdf"
        )
        options.set_preference("pdfjs.disabled", True)
        return options
