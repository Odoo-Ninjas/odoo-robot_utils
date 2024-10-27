*** Comments ***
# odoo-require: crm,sale_stock, sale_management


*** Settings ***
Documentation       Testing Basic Functions of the Robot Keywords

Library             OperatingSystem
Library             SeleniumLibrary
Resource            ../keywords/odoo.robot

Test Setup          Login


*** Test Cases ***
Test One2many
    MainMenu    sale.sale_menu_root
    ClickMenu    sale.sale_order_menu
    ClickMenu    sale.menu_sale_order
    Wait To Click    //button[contains(@class, 'o_list_button_add')]
    Write In Field    partner_id    Deco Addict
    Screenshot

    Wait To Click    //a[text() = 'Add a product']
    Write In Field    product_template_id    Conference Chair    parent=order_line

Test Many2one
    Capture Page Screenshot
    MainMenu    contacts.menu_contacts
    Capture Page Screenshot

    Odoo Search Unlink    res.partner    [('name', '=', 'Mickey Mouse')]

    Wait To Click    //button[contains(text(), 'New')]

    WriteInField    fieldname=name    value=Mickey Mouse    ignore_auto_complete=True
    WriteInField    category_id    value=Services
    Wait To Click    //button[contains(@class, 'o_form_button_save')]

    ${partners}=    Odoo Search    res.partner    []    order=id desc    limit=1
    ${value}=    Odoo Read Field    res.partner    ${partners}    category_id
    Log To Console    ${value}
    Assert    bool(${value})
