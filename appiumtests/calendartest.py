#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2023 Fushan Wen <qydwhotmail@gmail.com>
# SPDX-License-Identifier: MIT

import unittest
from typing import Any, Final

from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy

WIDGET_ID: Final = "org.kde.plasma.calendar"


class CalendarTest(unittest.TestCase):
    """
    Tests for the calendar widget
    """

    driver: webdriver.Remote

    @classmethod
    def setUpClass(cls) -> None:
        """
        Opens the widget and initialize the webdriver
        """
        desired_caps: dict[str, Any] = {}
        desired_caps["app"] = f"plasmawindowed -p org.kde.plasma.nano {WIDGET_ID}"
        desired_caps["environ"] = {
            "QT_FATAL_WARNINGS": "1",
            "QT_LOGGING_RULES": "qt.accessibility.atspi.warning=false;kf.plasma.core.warning=false;kf.windowsystem.warning=false;kf.kirigami.warning=false",
        }
        cls.driver = webdriver.Remote(command_executor='http://127.0.0.1:4723', desired_capabilities=desired_caps)
        cls.driver.implicitly_wait = 10

    def tearDown(self) -> None:
        """
        Take screenshot when the current test fails
        """
        if not self._outcome.result.wasSuccessful():
            self.driver.get_screenshot_as_file(f"failed_test_shot_{WIDGET_ID}_#{self.id()}.png")

    def test_0_open(self) -> None:
        """
        Tests the widget can be opened
        """
        self.driver.find_element(AppiumBy.NAME, "Today")
        self.driver.find_element(AppiumBy.NAME, "Days")
        self.driver.find_element(AppiumBy.NAME, "Months")
        self.driver.find_element(AppiumBy.NAME, "Years")


if __name__ == '__main__':
    unittest.main()
