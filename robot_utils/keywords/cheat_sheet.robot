*** Variables ***
${STRING}=                  cat
${NUMBER}=                  ${1}
@{LIST}=                    one    two    three
&{DICTIONARY}=              string=${STRING}    number=${NUMBER}    list=@{LIST}

# &{DICTIONARY}=              string=${STRING}    number=${NUMBER}    list=@{LIST}
# better:
${values}=                       Create Dictionary  name=${CURRENT_TEST}
${ENVIRONMENT_VARIABLE}=    %{PATH=Default value}


Call a keyword that returns a value
    ${value}=    A keyword that returns a value
    Log    ${value}    # Return value

Do conditional IF - ELSE IF - ELSE execution
    IF    ${NUMBER} > 1
        Log    Greater than one.
    ELSE IF    "${STRING}" == "dog"
        Log    It's a dog!
    ELSE
        Log    Probably a cat.
    END

Evaluate Python expressions
    ${path}=    Evaluate    os.environ.get("PATH")
    ${path}=    Set Variable    ${{os.environ.get("PATH")}}


https://robocorp.com/docs/languages-and-frameworks/robot-framework/cheat-sheet