*** Settings ***
Documentation       Interface to odoo-rpclib

Library             ../library/odoo.py
Library             ../library/tools.py
Library             Collections


*** Keywords ***
Technical Testname
    ${result}=    odoo.Technical Testname
    RETURN    ${result}

Odoo Conn
    [Arguments]
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ${conn}=    odoo._get Conn    ${host}    ${dbname}    ${user}    ${pwd}
    RETURN    ${conn}

Odoo Search
    [Arguments]
    ...    ${model}
    ...    ${domain}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${count}=${FALSE}
    ...    ${limit}=${NONE}
    ...    ${order}=${NONE}
    ...    ${offset}=0
    ...    ${lang}=en_US
    ...    ${context}=${NONE}
    IF    ${odoo_version} >= 17.0
        ${count}=    Convert To Boolean    ${count}
        IF    ${count}
            ${method}=    Set Variable    search_count
            ${kwparams}=    Create Dictionary
        ELSE
            ${kwparams}=    Create Dictionary    limit=${limit}    offset=${offset}    order=${order}
            ${method}=    Set Variable    search
        END
        Log To Console    Doing odoo execute with [${domain}] and ${kwparams}
        ${domain}=    Evaluate    ${domain}
        ${params}=    Eval    [d]    d=${domain}
        ${result}=    odoo.Rpc Client Execute
        ...    ${host}
        ...    ${dbname}
        ...    ${user}
        ...    ${pwd}
        ...    ${model}
        ...    ${method}
        ...    params=${params}
        ...    kwparams=${kwparams}
        ...    context=${context}
        ...    lang=${LANG}
    ELSE
        ${result}=    odoo.Rpc Client Search
        ...    ${host}
        ...    ${dbname}
        ...    ${user}
        ...    ${pwd}
        ...    ${model}
        ...    ${domain}
        ...    limit=${limit}
        ...    order=${order}
        ...    count=${count}
        ...    lang=${lang}
        ...    context=${context}
    END
    RETURN    ${result}

Odoo Search Records
    [Arguments]
    ...    ${model}
    ...    ${domain}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${count}=${FALSE}
    ...    ${limit}=${NONE}
    ...    ${order}=${NONE}
    ...    ${lang}=en_US
    ...    ${context}=${None}

    IF    ${odoo_version} >= 17.0
        IF    ${count}
            FAIL    Please do not use count=True for Odoo Search Records
        END
    END
    ${result}=    odoo.Rpc Client Search Records
    ...    ${host}
    ...    ${dbname}
    ...    ${user}
    ...    ${pwd}
    ...    ${model}
    ...    ${domain}
    ...    limit=${limit}
    ...    order=${order}
    ...    lang=${lang}
    ...    context=${context}
    RETURN    ${result}

Odoo Search Read Records
    [Arguments]
    ...    ${model}
    ...    ${domain}
    ...    ${fields}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${count}=${FALSE}
    ...    ${limit}=${NONE}
    ...    ${order}=${NONE}
    ...    ${offset}=0
    ...    ${lang}=en_US
    ...    ${context}=${None}
    ${result}=    odoo.Rpc Client Search Read Records
    ...    ${host}
    ...    ${dbname}
    ...    ${user}
    ...    ${pwd}
    ...    ${model}
    ...    ${domain}
    ...    ${fields}
    ...    limit=${limit}
    ...    order=${order}
    ...    count=${count}
    ...    offset=${offset}
    ...    lang=${lang}
    ...    context=${context}
    RETURN    ${result}

Odoo Load Data
    [Arguments]
    ...    ${filepath}
    ...    ${module_name}=robobase
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    odoo.Load File    ${host}    ${dbname}    ${user}    ${pwd}    ${filepath}    ${module_name}

Odoo Put File
    [Arguments]
    ...    ${file_path}
    ...    ${dest_path_on_odoo_container}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    odoo.Put File    ${host}    ${dbname}    ${user}    ${pwd}    ${file_path}    ${dest_path_on_odoo_container}

Odoo Create
    [Arguments]
    ...    ${model}
    ...    ${values}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${lang}=en_US
    ...    ${context}=${None}
    ${new_dict}=    Convert To Dictionary    ${values}
    Log to Console    Create new ${model} with dict: ${new_dict}
    ${result}=    odoo.Rpc Client Create
    ...    ${host}
    ...    ${dbname}
    ...    ${user}
    ...    ${pwd}
    ...    model=${model}
    ...    values=${new_dict}
    ...    lang=${lang}
    ...    context=${context}
    RETURN    ${result}

Odoo Write
    [Arguments]
    ...    ${model}
    ...    ${ids}
    ...    ${values}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${lang}=en_US
    ...    ${context}=${None}
    ${values}=    Odoo Convert To Dictionary    ${values}
    Log to Console    Write ${ids} ${model} with dict: ${values}
    ${result}=    odoo.Rpc Client Write
    ...    host=${host}
    ...    dbname=${dbname}
    ...    user=${user}
    ...    pwd=${pwd}
    ...    model=${model}
    ...    ids=${ids}
    ...    values=${values}
    ...    lang=${lang}
    ...    context=${context}
    RETURN    ${result}

Odoo Unlink
    [Arguments]
    ...    ${model}
    ...    ${ids}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${context}=${None}
    ${result}=    odoo.Rpc Client Execute
    ...    method=unlink
    ...    host=${host}
    ...    dbname=${dbname}
    ...    user=${user}
    ...    pwd=${pwd}
    ...    model=${model}
    ...    ids=${ids}
    ...    context=${context}
    RETURN    ${result}

Odoo Search Unlink
    [Arguments]
    ...    ${model}
    ...    ${domain}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${lang}=en_US
    ...    ${context}=${None}
    ...    ${limit}=${None}
    ...    ${offset}=0
    ...    ${order}=${None}
    ${ids}=    Odoo Search
    ...    ${model}
    ...    ${domain}
    ...    limit=${limit}
    ...    order=${order}
    ...    offset=${offset}
    ...    lang=${lang}
    ...    context=${context}
    IF    ${ids}
        ${result}=    Odoo Execute
        ...    ${model}
        ...    unlink
        ...    host=${host}
        ...    dbname=${dbname}
        ...    user=${user}
        ...    pwd=${pwd}
        ...    ids=${ids}
        ...    lang=${lang}
        ...    context=${context}
    END

    RETURN    ${True}

Odoo Ref Id
    [Arguments]
    ...    ${xml_id}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    Log to Console    XML ID: ${xml_id}
    ${result}=    odoo.Rpc Client Ref Id    ${host}    ${dbname}    ${user}    ${pwd}    ${xml_id}
    RETURN    ${result}

Odoo Ref
    [Arguments]
    ...    ${xml_id}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    Log to Console    XML ID: ${xml_id}
    ${result}=    odoo.Rpc Client Ref    ${host}    ${dbname}    ${user}    ${pwd}    ${xml_id}
    RETURN    ${result}

Odoo Execute
    [Documentation]    To execute @api.model function dont pass ids
    [Arguments]
    ...    ${model}
    ...    ${method}
    ...    ${ids}=${{None}}
    ...    ${params}=${{[]}}
    ...    ${kwparams}=${{{}}}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${lang}=en_US
    ...    ${context}=${None}
    ${result}=    odoo.Rpc Client Execute
    ...    ${host}
    ...    ${dbname}
    ...    ${user}
    ...    ${pwd}
    ...    ${model}
    ...    ${method}
    ...    ids=${ids}
    ...    params=${params}
    ...    kwparams=${kwparams}
    ...    lang=${lang}
    ...    context=${context}
    RETURN    ${result}

Odoo Read
    [Arguments]
    ...    ${model}
    ...    ${ids}
    ...    ${fields}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${lang}=en_US
    ...    ${context}=${None}
    ${result}=    odoo.Rpc Client Read
    ...    ${host}
    ...    ${dbname}
    ...    ${user}
    ...    ${pwd}
    ...    model=${model}
    ...    ids=${ids}
    ...    fields=${fields}
    ...    lang=${lang}
    ...    context=${context}
    RETURN    ${result}

Odoo Read Field
    [Arguments]
    ...    ${model}
    ...    ${id}
    ...    ${field}
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${lang}=en_US
    ...    ${context}=${None}
    ${result}=    odoo.Rpc Client Get Field
    ...    ${host}
    ...    ${dbname}
    ...    ${user}
    ...    ${pwd}
    ...    model=${model}
    ...    id=${id}
    ...    field=${field}
    ...    lang=${lang}
    ...    context=${context}
    RETURN    ${result}

Odoo Make Same Passwords
    [Arguments]
    ...    ${dbname}=${ROBO_ODOO_DB}
    ...    ${host}=${ODOO_URL}
    ...    ${user}=${ROBO_ODOO_USER}
    ...    ${pwd}=${ROBO_ODOO_PASSWORD}
    ...    ${context}=${None}
    ${result}=    tools.Make Same Passwords    ${host}    ${dbname}    ${user}    ${pwd}
    RETURN    ${result}

Wait Queuejobs Done
    # serialize can happen
    Wait Until Keyword Succeeds
    ...    99x
    ...    500ms
    ...    Run Keyword
    ...    Odoo Execute
    ...    robot.data.loader
    ...    method=wait_queuejobs

Odoo Current Employee
    ${emps}=    Odoo Search Records    hr.employee    [('user_id.login', '=', '${ROBO_ODOO_USER}')]
    ${l}=  Get Length  ${emps}

    IF  not ${l}
        FAIL  Employee not found for user ${ROBO_ODOO_USER}
    END
    RETURN  ${emps[0].id}

