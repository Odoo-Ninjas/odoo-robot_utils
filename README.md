# odoo-robot_utils

Helps together with wodoo-framework and cicd to quickly spinup robo tests.
This branch contains keywords used for the odoo version as the version of the branch.

## Setup

- clone this repository into your existing project /adoons_robot
- update submodules
- with wodoo framework: odoo setup robot

# odoo-robot_utils

Helps together with wodoo-framework and cicd to quickly spinup robo tests.

## Setup

  * clone this repository into your existing project 
  * 


## Simple Smoketest
```robotframework
# odoo-require: module1, module        name some odoo modules, which shall be installed beforehand

*** Settings ***
Documentation     Smoketest
Resource          keywords/odoo_ee.robot
Resource          ../../robot_utils/keywords/tools.robot
Resource          ../../robot_utils/keywords/odoo_client.robot
Resource          ../../robot_utils/keywords/styling.robot
Test Setup        Setup Smoketest


*** Keywords ***

*** Test Cases ***
Smoketest
    Search for the admin

*** Keywords ***
Setup Smoketest
    Login
    Click Element                    xpath=//a[@class[contains(., 'full')]]

Search for the admin
    Odoo Search                     model=res.users  domain=[]  count=False
    ${count}=  Odoo Search          model=res.users  domain=[('login', '=', 'admin')]  count=True
    Should Be Equal As Strings      ${count}  1
    Log To Console  ${count}

Misc
    Log To Console                  This is my unique token ${TOKEN}
    Log To Console                  This is the directory of the test: ${TEST_DIR}


```

## Impersonate User at Test

Provide an xml file:
```xml
<record model="res.users" id="purchase1">
    <field name="name">Purchaser</field>
    <field name="login">purchase1</field>
    <field name="groups_id" eval="[[6, 0, [
        ref('purchase.group_purchase_user').id,
    ]]"/>
</record>

```

```robotframework

*** Test Cases ***
BaseTest
    Odoo Load Data       ../data/basic_data/users.xml  robobase
    Odoo Make Same Passwords
    Login                user=purchase1
```


## Parallel executed test, wait till preparation is done

```robotframework
Log To Console  Checking ${TEST_RUN_INDEX}
IF  "${TEST_RUN_INDEX}" == "0"
    Log To Console  Now preparing the stuff
    Set Wait Marker  products_on_stock
END

Wait For Marker  products_on_stock
```

## Available Variables (also in loaded xml files)

* ODOO_DB
* ODOO_USER
* ODOO_PASSWORD
* ODOO_URL
* TOKEN