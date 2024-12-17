*** Settings ***
Library    Process
Library    debugpy
Library    ../library/tools.py
Library    ../library/debug.py


*** Variables ***
${IS_COBOT_CONTAINER}    ${None}

*** Keywords ***
Wait For Remote Debugger
    # TODO for later; does not wait at wait
    ${IS_COBOT_CONTAINER}=    Get Environment Variable    IS_COBOT_CONTAINER    default=0
    ${ROBOT_REMOTE_DEBUGGING}=    Get Environment Variable    ROBOT_REMOTE_DEBUGGING    default=0
    ${remote_debug}=              tools.Eval  str(v)\=\="1" and str(v1)\=\="1"  v=${IS_COBOT_CONTAINER}  v1=${ROBOT_REMOTE_DEBUGGING}
    IF    ${remote_debug}
        Run Keyword  debug.Start
    END
    Log       Debugging Started!
    RETURN


# mkdir .vscode
# touch .vscode/launch.json
# {
#    "version": "0.2.0",
#    "configurations": [
#    {
#    "name": "Attach to Robot Framework Debugger",
#    "type": "python",
#    "request": "attach",
#    "connect": {
#    "host": "localhost",
#    "port": 5678
#    },
#    "pathMappings": [
#    {
#    "localRoot": "${workspaceFolder}",
#    "remoteRoot": "/path/to/your/remote/script"
#    }
#    ]
#    }
#    ]
# }