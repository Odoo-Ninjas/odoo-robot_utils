*** Comments ***
# odoo-require: crm,sale_stock, sale_management


*** Settings ***
Documentation       Testing Basic Functions of the Robot Keywords

Library             OperatingSystem
Library             SeleniumLibrary
Library             ../library/tools.py
Resource            ../keywords/odoo.robot
# Test Setup    Login


*** Test Cases ***
Test Is List
    ${alist}=    Create List    a b c
    ${islist}=    Set Variable    ${{ isinstance(${alist}, list) }}
    Assert    ${islist}
    IF    ${{ isinstance(${alist}, list) }}
        Log2    if --> a list
    ELSE
        Log2    if --> not a list
    END

Test Empty String
    ${result}=    Is Empty String    abcd
    Log2    ${result}
    Assert    not ${result}
    ${result}=    Is Empty String    1235
    Assert    not ${result}
    ${result}=    Is Empty String    ${None}
    Assert    ${result}
    ${result}=    Is Empty String    ${TRUE}
    Assert    ${result}

    ${emptystring}=    Set Variable    ${{ 'a' }}
    ${result}=    Is Empty String    the_string1=${emptystring}
    Assert    ${result}
    ${result}=    Is Empty String    ${NONE}
    Assert    '${result}' == '${True}'
    ${result}=    Is Empty String    ${None}
    Assert    '${result}' == '${True}'
    ${result}=    Is Empty String    None
    Assert    '${result}' == '${False}'
    ${result}=    Is Empty String    ${{ None }}
    Assert    '${result}' == '${True}'

    ${result}=    IsEmptyString    ${NONE}
    Assert    '${result}' == '${TRUE}'
    ${result}=    IsEmptyString    ${{ '' }}
    Assert    '${result}' == '${TRUE}'

Test Prepend
    ${result}=    _prepend_parent    a1    /parent1
    Assert    '''${result}''' == '/parent1a1'
    ${result}=    _prepend_parent    a1    ${{ None }}
    Assert    '''${result}''' == 'a1'
    ${result}=    _prepend_parent    a1    ${NONE}
    Assert    '''${result}''' == 'a1'

    ${xpaths}=    Create List
    ...    //div[@name='a1']//input
    ...    //div[@name='a2']//input
    ${xpaths}=    _prepend_parent    ${xpaths}    //vorne
    Log2    ${xpaths}
    ${is_list}=  Is List  ${xpaths}
    Assert  ${is_list} == True
    ${el}   Get From List  ${xpaths}  0
    Assert  "${el}" == "//vorne//div[@name='a1']//input"
    # Assert  ${xpaths}[1] == '//vorne//div[@name='a2']//input'
