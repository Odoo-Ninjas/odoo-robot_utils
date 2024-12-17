*** Comments ***
# odoo-require: crm,sale_stock, sale_management
# odoo-uninstall: partner_autocomplete


*** Settings ***
Documentation       Testing Basic Functions of the Robot Keywords

Library             OperatingSystem
Resource            ../keywords/odoo.robot

Test Setup          Setup Test


*** Test Cases ***
Test Many2one
    Capture Page Screenshot
    MainMenu    contacts.menu_contacts
    Capture Page Screenshot

    Odoo Search Unlink    res.partner    [('name', '=', 'Mickey Mouse')]

    # V15 is create
    Wait To Click    //button[contains(text(), 'New') or contains(text(), 'Create')]

    WriteInField    fieldname=name    value=Mickey Mouse    ignore_auto_complete=True
    WriteInField    category_id    value=Services
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
    Wait To Click    //button[contains(@class, 'o_list_button_add')]
    Write In Field    partner_id    Deco Addict
    Screenshot

    Wait To Click    //div[@id='order_line' or @name='order_line']//a[text() = 'Add a product']
    IF    ${odoo_version} < 16.0
        ${data}=    Create Dictionary    product_id=E-COM11    product_uom_qty=25
    ELSE
        ${data}=    Create Dictionary    product_template_id=E-COM11    product_uom_qty=25
    END
    Write One2many    order_line    ${data}
    Form Save
    Check if there are orderlines    ${LastId}

Test One2many-Field By Field
    ${LastId}=    Odoo Search    sale.order    []    order=id desc    limit=1
    MainMenu    sale.sale_menu_root
    ClickMenu    sale.sale_order_menu
    ClickMenu    sale.menu_sale_order
    Wait To Click    //button[contains(@class, 'o_list_button_add')]
    Write In Field    partner_id    Deco Addict
    Screenshot

    Wait To Click    //div[@id='order_line' or @name='order_line']//a[text() = 'Add a product']
    IF    ${odoo_version} < 16.0
        Write In Field    product_id    E-COM11    parent=order_line
    ELSE
        Write In Field    product_template_id    E-COM11    parent=order_line
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
    Login
    ${count}=    Odoo Search    res.partner    [('name', '=', 'Deco Addict')]    count=${TRUE}
    IF    not ${count}
        Odoo Create    res.partner    ${{ {'name': 'Deco Addict'} }}
    END
