# Multi-Line Documentation

```robotframework
Test Case 1
    [Documentation]
        | = Example Heading =
		| *bold* _italic_
        | Lorem ipsum dolor sit amet, consectetur adipisicing elit,
        | do eiusmod tempor incididunt ut labore et dolore sed magna
        | aliqua. Ut enim ad minim veniam, quis nostrud exercitation
        | ullamco laboris nisi ut aliquip ex ea commodo consequat.
```
# Show all variables
	${variables}=    Get All Variables
	Log To Console  ${variables}


# Multiline
  ${var1}=    Catenate  
  ... test1
  ... test2
  ... test3

# Dictionaries

```robotframework
${values}=      Create Dictionary
                ...   name=${name}
                ...   is_docker_host=True
                ...   external_url=http://testsite
                ...   ttype=dev
                ...   ssh_user=${ROBOTTEST_SSH_USER}
                ...   ssh_pubkey=${ROBOTTEST_SSH_PUBKEY}
                ...   ssh_key=${ROBOTTEST_SSH_KEY}
                ...   postgres_server_id=${postgres}
```

# x-nary
```robotframework
${decimalval} =   Set variable If
...               '${decimalval}'=='0'       //md-option[@value='0dp']
...               '${decimalval}'=='1'       //md-option[@value='1dp']
...               '${decimalval}'=='2'       //md-option[@value='2dp']
```

# Evaluate python
```robotframework
${click_move_left} =    Evaluate     int(${cell_width}/2) - 1
```

# IF blocks
```robotframework

IF '${var1}' == '2'

ELIF

ELSE

END
```