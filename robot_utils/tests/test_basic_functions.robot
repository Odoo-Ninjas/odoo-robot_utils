#odoo-require: crm
*** Settings ***
Library    		OperatingSystem
Library    		SeleniumLibrary
Documentation   Testing Basic Functions of the Robot Keywords
Resource        ../keywords/odoo.robot
Test Setup      Login

*** Variables ***

*** Keywords ***

*** Test Cases ***

Create A Partner
    Capture Page Screenshot
    MainMenu  contacts.menu_contacts
    Capture Page Screenshot

    Odoo Search Unlink  res.partner  [('name', '=', 'Mickey Mouse')]

    Wait To Click  //button[contains(text(), 'New')]

    WriteInField  fieldname=name  value=Mickey Mouse  ignore_auto_complete=True
    WriteInField   category_id  value=Services
    Wait To Click  //button[contains(@class, 'o_form_button_save')]

    ${partners}=  			Odoo Search             res.partner  []  order=id desc  limit=1
    ${value}=               Odoo Read Field  		res.partner  ${partners}  category_id
    Log To Console          ${value}
    Assert                  bool(${value})