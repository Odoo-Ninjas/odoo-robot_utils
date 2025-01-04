import os
import selenium
from selenium.webdriver.remote.webdriver import WebDriver as RemoteDriver
from selenium.webdriver import FirefoxOptions, ChromeOptions
from selenium.webdriver.remote import webdriver
import json
from pathlib import Path
from robot.libraries.BuiltIn import BuiltIn


class RemoteDriver2(RemoteDriver):
    def __init__(self, *args, do_start_session=False, desired_session_id=None, **kwargs):
        self.do_start_session = do_start_session
        self.desired_session_id = desired_session_id
        super().__init__(*args, **kwargs)

    def start_session(self, capabilities: dict, *args, **kwargs) -> None:
        if not self.do_start_session:
            self.session_id = self.desired_session_id
            return
        super().start_session(capabilities, *args, **kwargs)
        


def get_driver_for_browser(download_path, headless, try_reuse_session=True):
    bd = BrowserDriver(download_path, headless)
    instance = BuiltIn().get_library_instance("SeleniumLibrary")
    driver = bd.get_webdriver(try_reuse_session=try_reuse_session)
    instance.register_driver(driver, alias="robodriver")
    return driver


class BrowserDriver(object):
    def __init__(self, download_path, headless):
        browser = os.environ['ROBO_WEBDRIVER_BROWSER']
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
        WEBDRIVER_HOST = os.environ[
            "ROBO_WEBDRIVER_HOST"
        ]  # path to geckodriver --host <ip> --port <port> example: 192.168.64.2:4444
        session_file = Path("/tmp/seleniumsession")
        if session_file.exists() and try_reuse_session:
            sessionId = session_file.read_text().strip()

        try:
            driver = RemoteDriver2(
                command_executor=f"http://{WEBDRIVER_HOST}",
                options=options,
                desired_session_id=sessionId,
                do_start_session=not sessionId
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
        return getattr(self, self.optionsMethod)(options)

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
        return options

    def _add_options_for_firefox(self, options):
        options.set_preference("browser.download.folderList", 2)
        options.set_preference("browser.download.manager.showWhenStarting", False)
        options.set_preference("browser.download.dir", self.download_path)
        options.set_preference(
            "browser.helperApps.neverAsk.saveToDisk", "application/pdf"
        )
        options.set_preference("pdfjs.disabled", True)
        return options
