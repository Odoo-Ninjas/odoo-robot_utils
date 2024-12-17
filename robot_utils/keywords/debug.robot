# *** Settings ***
# Library    Process
# Library    debugpy
# Library    ../library/tools.py
# Library    ../library/debug.py


# *** Variables ***
# ${IS_COBOT_CONTAINER}    ${None}

# *** Keywords ***
# Wait For Remote Debugger

#     # TODO for later; does not wait at wait
#     ${ROBOT_REMOTE_DEBUGGING}=    Get Environment Variable    ROBOT_REMOTE_DEBUGGING    default=0
#     ${remote_debug}=              tools.Eval                  str(v)\=\="1"             v=${ROBOT_REMOTE_DEBUGGING}
#     IF    ${remote_debug}
#         Log To Console  -
#         Log To Console  Please connect now to the remote debugger. Configuration in launch.json is provided.
#         Run Keyword    debug.Start
#     END
#     Log       Debugging Started!
#     RETURN


# # mkdir .vscode
# # touch .vscode/launch.json
# # {
# #    "version": "0.2.0",
# #    "configurations": [
# #    {
# #    "name": "Attach to Robot Framework Debugger",
# #    "type": "python",
# #    "request": "attach",
# #    "connect": {
# #    "host": "localhost",
# #    "port": 5678
# #    },
# #    "pathMappings": [
# #    {
# #    "localRoot": "${workspaceFolder}",
# #    "remoteRoot": "/path/to/your/remote/script"
# #    }
# #    ]
# #    }
# #    ]
# # }