*** Comments ***
# odoo-require: crm,sale_stock, sale_management
# odoo-uninstall: partner_autocomplete


*** Settings ***
Documentation       Testing Basic Functions of the Robot Keywords

Library             OperatingSystem
Resource            ../keywords/odoo.robot
Resource            ../keywords/test_setup.robot
# 
Test Setup          Setup Test

*** Variables ***
${SNIPPET_MODE}    0
@{INSTALL_MODULES}   sale_management
@{UNINSTALL_MODULES}  ${NONE}


*** Test Cases ***
Test Many2one
    Capture Page Screenshot
    MainMenu    contacts.menu_contacts
    Capture Page Screenshot

    Odoo Search Unlink    res.partner    [('name', '=', 'Mickey Mouse')]

    # V15 is create
    ${css1}=          CSS Identifier With Text  button  New
    ${css2}=          CSS Identifier With Text  button  Create
    Wait To Click    ${css1},${css2}

    Write    fieldname=name    value=Mickey Mouse    ignore_auto_complete=True
    Write    category_id    value=Services
    Form Save

    ${partners}=    Odoo Search    res.partner    []    order=id desc    limit=1
    ${value}=    Odoo Read Field    res.partner    ${partners}    name
    Log To Console    ${value}
    Should Be Equal As Strings    ${value}    Mickey Mouse
    ${value}=    Odoo Read Field    res.partner    ${partners}    category_id
    Log To Console    ${value}
    Assert    bool(${value})

Test One2many-Give Dict
    ${LastId}=    Odoo Search    sale.order    []    order=id desc    limit=1
    MainMenu    sale.sale_menu_root
    ClickMenu    sale.sale_order_menu
    ClickMenu    sale.menu_sale_order
    Wait To Click    button.o_list_button_add
    Write    partner_id    Deco Addict
    Screenshot

    ${css}=  CSS Identifier With Text  div#order_line a, div[name='order_line'] a  Add a product
    Wait To Click     ${css}
    IF    ${odoo_version} < 16.0
        ${data}=    Create Dictionary    product_id=E-COM11    product_uom_qty=25
    ELSE
        ${data}=    Create Dictionary    product_template_id=E-COM11    product_uom_qty=25
    END
    Odoo Write One2many    order_line    ${data}
    Form Save
    Check if there are orderlines    ${LastId}

Test One2many-Field By Field
    ${LastId}=    Odoo Search    sale.order    []    order=id desc    limit=1
    MainMenu    sale.sale_menu_root
    ClickMenu    sale.sale_order_menu
    ClickMenu    sale.menu_sale_order
    Wait To Click    button.o_list_button_add
    Write    partner_id    Deco Addict
    Screenshot

    ${css}=  CSS Identifier With Text  div#order_line a, div[name='order_line'] a  Add a product
    Wait To Click    ${css}
    IF    ${odoo_version} < 16.0
        Write    product_id    E-COM11    parent=order_line
    ELSE
        Write    product_template_id    E-COM11    parent=order_line
    END
    Form Save
    Check if there are orderlines    ${LastId}


*** Keywords ***
Check if there are orderlines    [Arguments]    ${LastId}=
    ${LastId}=    Evaluate    (${LastId} or [0])[0]
    ${order}=    Odoo Search Read Records
    ...    sale.order
    ...    [('id', '>', ${LastId})]
    ...    order_line
    ...    order=id desc
    ...    limit=1
    ${order}=    Get From List    ${order}    0
    Assert    len(${order['order_line']}) > 0

Setup Test
    Setup Test Basic
    Login
    ${count}=    Odoo Search    res.partner    [('name', '=', 'Deco Addict')]    count=${TRUE}
    IF    not ${count}
        Odoo Create    res.partner    ${{ {'name': 'Deco Addict'} }}
    END
