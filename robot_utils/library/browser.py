import os
import selenium
from selenium.webdriver.remote.webdriver import WebDriver as RemoteDriver
from selenium.webdriver import FirefoxOptions, ChromeOptions
import json
from pathlib import Path
from robot.libraries.BuiltIn import BuiltIn


def get_driver_for_browser(browser, download_path, headless):
    bd = BrowserDriver(browser, download_path, headless)
    instance = BuiltIn().get_library_instance("SeleniumLibrary")
    driver = bd.get_webdriver()
    instance.register_driver(driver, alias="firefox")
    return driver

class BrowserDriver(object):
    def __init__(self, browser, download_path, headless):
        assert browser in ['chrome', 'firefox'], f"{browser} is not a supported browser."
        self.browser = browser
        self.download_path = str(Path(download_path).absolute())
        self.headless = headless

        self.optionsClass = f"{browser.capitalize()}Options"
        self.optionsMethod = f"_add_options_for_{browser}"

    def get_webdriver(self):

        options = self.create_options()
        sessionId = None
        WEBDRIVER_HOST = os.environ["ROBO_WEBDRIVER_HOST"]  # path to geckodriver --host <ip> --port <port> example: 192.168.64.2:4444
        session_file = Path("/tmp/geckosession")
        if session_file.exists():
            sessionId = session_file.read_text().strip()

        try:
            options.sessionId = sessionId
            driver = RemoteDriver(command_executor=f"http://{WEBDRIVER_HOST}", options=options, session = sessionId)
            if not driver.session_id:
                raise selenium.common.exceptions.InvalidSessionIdException()
        except selenium.common.exceptions.InvalidSessionIdException:
            driver = RemoteDriver(command_executor=f"http://{WEBDRIVER_HOST}", options=options, start_session=True)
            Path("/tmp/geckosession").write_text(driver.session_id)
        return driver

    def create_options(self):
        options = getattr(selenium.webdriver, self.optionsClass)()
        if self.headless:
            options.add_argument("--headless")
        BROWSER_WIDTH = BuiltIn().get_variable_value("${BROWSER_WIDTH}")
        BROWSER_HEIGHT = BuiltIn().get_variable_value("${BROWSER_HEIGHT}")
        options.add_argument(
            f"--window-size={BROWSER_WIDTH},{BROWSER_HEIGHT}"
        )
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
# def get_selenium_browser_log():
#     instance = BuiltIn().get_library_instance("SeleniumLibrary")
#     return instance.driver.get_log("browser")




    # opts = FirefoxOptions()
    # opts.add_argument("--headless")
    # try:
    #     browser = webdriver.Firefox(options=opts)
    # except:
    #     log = Path("geckodriver.log")
    #     if log.exists():
    #         raise Exception(log.read_text())
    # else:
    #     browser.close()

"""


    def create_options(self):
        options = getattr(webdriver, self.optionsClass)()
        if self.headless:
            options.add_argument("--headless")
        options.add_argument(
            f"--window-size={os.environ['BROWSER_WIDTH']},{os.environ['BROWSER_HEIGHT']}"
        )
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-popup-blocking")
        return getattr(self, self.optionsMethod)(options)

    def _enable_download_in_headless_chrome(self, driver):
        There is currently a "feature" in chrome where
        headless does not allow file download:
        https://bugs.chromium.org/p/chromium/issues/detail?id=696481
        This method is a hacky work-around until the official chromedriver
        support for this.
        Requires chrome version 62.0.3196.0 or above.

        driver.command_executor._commands["send_command"] = (
            "POST",
            "/session/$sessionId/chromium/send_command",
        )
        params = {
            "cmd": "Page.setDownloadBehavior",
            "params": {"behavior": "allow", "downloadPath": self.path},
        }
        driver.execute("send_command", params)

"""
