*** Settings ***
Documentation     Inventory Operations
Resource          keywords/odoo_13_ee.robot

*** Keywords ***

New Inventory for Product   [Arguments]     ${product}    ${quantity}    ${location}

ClickMenu    menu=stock.menu_stock_root
Button                
get_action_picking_tree_ready