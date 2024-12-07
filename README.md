Helps together with wodoo-framework and cicd to quickly spinup robo tests.

# Setup

## Add gimera.yml config

```
- branch: main
  path: addons_robot
  type: integrated
  url: git@github.com:marcwimmer/odoo-robot_utils.git
```

```bash
gimera apply addons_robot
```

## MANIFEST addons-paths

Add the just created addons_robot to the addons paths in /MANIFEST

```python
...
    "addons_paths": [
        ...
        "addons_robot",
    ],
...
```

Create a test folder in /tests and put the robot-files there.

# Run a test
```bash
odoo robot run <filepath>

```


# Simple Smoketest

```robotframework
# odoo-require: module1, module        name some odoo modules, which shall be installed beforehand
# odoo-uninstall: partner_autocomplete

*** Settings ***
Documentation     Smoketest
Resource            ../../addons_robot/robot_utils/keywords/odoo.robot
Resource            ../../addons_robot/robot_utils/keywords/tools.robot
Resource            ../../addons_robot/robot_utils/keywords/wodoo.robot
Test Setup        Setup Smoketest


*** Test Cases ***
Smoketest
    Search for the admin

*** Keywords ***
Setup Smoketest
    Login
    MainMenu                         purchase.menu_purchase_root

Search for the admin
    Odoo Search                     model=res.users  domain=[]  count=False
    ${count}=  Odoo Search          model=res.users  domain=[('login', '=', 'admin')]  count=True
    Should Be Equal As Strings      ${count}  1
    Log To Console  ${count}

Misc
    Log To Console                  This is my unique token ${TOKEN}
    Log To Console                  This is the directory of the test: ${TEST_DIR}

Sample Trigger Cronjob
    ${cron_ids}=    Odoo Search    ir.cron    [('name', '=', 'zbs_pipeline_pusher')]
    Assert    len(${cron_ids}) == 1
    # Task could be executed at the moment
    Odoo Execute    ir.cron    ids=${cron_ids[0]}    method=method_direct_trigger

Sample Loop
    WHILE    ${TRUE}
        TRY
            IF    ${no_cron_start}
                Odoo Execute    zbs.instance    ids=${instance_id}    method=heartbeat_ui
            ELSE
                Zync Run Cron Pipeline Pusher
                Sleep    1s
            END
        EXCEPT
            Log To Console    Exception in Zync Run Cron Pipeline Pusher: ${ERROR}
            Log To Console    Ignoring and retrying
            Sleep    0.2s
        END
        ${state}=    Odoo Read Field    zbs.instance    ${instance_id}    state
        Log To Console    Instance ${instance_id} is in state ${state}
        IF    '${state}' in ${{['success', 'failed']}}    BREAK
    END

Samples
    # some samples:
    Should Be Equal As Strings    ${RUN_ODOO_QUEUEJOBS}    1
    Upload File    filecontent    ${pipeline_path}
    WriteInField    newname    ${newname}
    Odoo Command    kill odoo_cronjobs odoo_queuejobs    # cronjob cannot me modified right now came
    Wait To Click    xpath=//button[@name='ok']
    Wait Until Element Is Visible    xpath=//button[@name="add_worker"]
    ${id}=    Get Instance ID From Url    zbs.pipeline
    Screenshot
    Assert    '${button_record}[1]' == 'Contact'    Model ID should be set by many2one field

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

## Load pre-defined data from csv/xml

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