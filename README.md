# odoo-robot_utils

Helps together with wodoo-framework and cicd to quickly spinup robo tests.

## Setup

  * clone this repository into your existing project 
  * add robotests/utils to your addons-paths


## Simple Smoketest
```robotframework
# odoo-require: robot_utils, web_selenium
# odoo-required: module1, module        name some odoo modules, which shall be installed beforehand

*** Settings ***
Documentation     Smoketest
Resource          keywords/odoo_14_ee.robot  # insert YOUR appriorate version here
Test Setup        Setup Smoketest


*** Keywords ***

*** Test Cases ***
Smoketest
    Search for the admin

*** Keywords ***
Setup Smoketest
    Login

Search for the admin
    Odoo Search                     model=res.users  domain=[]  count=False
    ${count}=  Odoo Search          model=res.users  domain=[('login', '=', 'admin')]  count=True
    Should Be Equal As Strings      ${count}  1
    Log To Console  ${count}


```
