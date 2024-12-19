*** Settings ***
Library    SeleniumLibrary

*** Variables ***

${JS_REMOVE_CURSOR}    var cursor = document.getElementById('rf-mouse-cursor'); \
                        if (cursor) cursor.remove();


*** Keywords ***

Add Cursor 
	${JS_ADD_CURSOR}=  Catenate  SEPARATOR=\n
	...       var cursor = document.createElement('div'); \
  ...       cursor.id = 'rf-mouse-cursor'; \
  ...       cursor.style.position = 'absolute'; \
  ...       cursor.style.width = '20px'; \
  ...       cursor.style.height = '20px'; \
  ...       cursor.style.borderRadius = '50%'; \
  ...       cursor.style.backgroundColor = 'red'; \
  ...       cursor.style.zIndex = '9999'; \
  ...       cursor.style['box-shadow'] = '0 0px 8px rgba(101, 101, 101, 0.04)';
  ...       document.body.appendChild(cursor); \
  ...       document.addEventListener('mousemove', function(e) { \
  ...         cursor.style.left = e.pageX + 'px'; \
  ...         cursor.style.top = e.pageY + 'px'; \
  ...       });
	Execute Javascript    ${JS_ADD_CURSOR}
  RETURN  ${NONE}

Remove Cursor
	Execute Javascript    ${JS_REMOVE_CURSOR}