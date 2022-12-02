*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    ${url}=    Get Secret    orders
    Open Available Browser    ${url}[url]

Get Orders
    Add text input    csv    label=Search query
    ${response}=    Run dialog
    Download    ${response.csv}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Click Button    css:.btn-dark

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    id:order
    ${alert}=    Does Page Contain Element    css:.alert-danger
    WHILE    ${alert}
        Click Button    id:order
        ${alert}=    Does Page Contain Element    css:.alert-danger
    END

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}orders${/}order_${order_number}.pdf
    RETURN    ${OUTPUT_DIR}${/}orders${/}order_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    Capture Element Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}orders${/}screenshot_${order_number}.png
    RETURN    ${OUTPUT_DIR}${/}orders${/}screenshot_${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To PDF    ${files}    ${pdf}

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}orders    orders.zip    include=*.pdf    recursive=True
