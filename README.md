# odoo-robot_utils

Helps together with wodoo-framework and cicd to quickly spinup robo tests.

## Setup

  * clone this repository into your existing project 
  * 


## Simple Smoketest
```robot-framework
*** Settings ***
Documentation     Smoketest
Resource          keywords/odoo_13_ee.robot
Resource          keywords/pim_keywords.robot
Test Setup        Setup Smoketest


*** Keywords ***

*** Test Cases ***
Smoketest
    Search for the admin

*** Keywords ***
Setup Smoketest
    Setup PIM Demo Data
    Login

Search for the admin
    Odoo Search                     model=res.users  domain=[]  count=False
    ${count}=  Odoo Search          model=res.users  domain=[('login', '=', 'admin')]  count=True
    Should Be Equal As Strings      ${count}  1
    Log To Console  ${count}


```
