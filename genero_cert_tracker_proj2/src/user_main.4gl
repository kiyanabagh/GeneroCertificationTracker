IMPORT FGL user_query_test
IMPORT FGL user_data

SCHEMA cert_trackerdb_2

PUBLIC DEFINE m_user_first_name LIKE user.fname
PUBLIC TYPE t_user_rec RECORD LIKE user.*
PUBLIC TYPE t_user_id LIKE user.userid

FUNCTION user_form_driver()
    DEFINE current_user t_user_id

    DEFER INTERRUPT

    OPEN WINDOW w2 WITH FORM "user_info_form"

    MENU "users"
        BEFORE MENU
            CALL setup_dialog(DIALOG, FALSE)
        ON ACTION query ATTRIBUTES(COMMENT = "Search for users")
            VAR can_nav = user_query_test.query_user()
            CALL setup_dialog(DIALOG, can_nav)
            IF can_nav THEN
                LET current_user = user_query_test.fetch_rel_user(0)
            END IF
        ON ACTION first
            LET current_user = user_query_test.fetch_rel_user(0)
        ON ACTION next
            LET current_user = user_query_test.fetch_rel_user(1)
        ON ACTION previous
            LET current_user = user_query_test.fetch_rel_user(-1)
        ON ACTION last
            LET current_user = user_query_test.fetch_rel_user(2)
        ON ACTION append
            LET current_user = user_data.append_user(current_user)
            IF current_user > 0 THEN
                LET current_user = user_query_test.fetch_rel_user(3)
            END IF
            CALL setup_dialog(DIALOG, (current_user > 0))
        ON ACTION update
            LET current_user = user_data.update_user(current_user)
            IF current_user > 0 THEN
                LET current_user = user_query_test.fetch_rel_user(3)
            END IF
            
            CALL setup_dialog(DIALOG, (current_user > 0))
        ON ACTION delete
            LET current_user = user_data.delete_user(current_user)
            CALL setup_dialog(DIALOG, (current_user > 0))
        ON ACTION quit
            EXIT MENU
        ON ACTION close
            EXIT MENU
        ON ACTION exit
            EXIT MENU
        ON ACTION view_knowledge_tests ATTRIBUTES(TEXT = "View User's Knowledge Tests")
            LET current_user = user_data.view_knowledge_tests(current_user)
            CALL setup_dialog(DIALOG, (current_user > 0))
            
        ON ACTION view_practical_tests ATTRIBUTES(TEXT = "View User's Practical Tests")
            LET current_user = user_data.view_practical_tests(current_user)
            CALL setup_dialog(DIALOG, (current_user > 0))
        
        
    END MENU
CLOSE WINDOW w2
END function

PRIVATE FUNCTION setup_dialog(dlg ui.Dialog, can_nav BOOLEAN) RETURNS()
    CALL dlg.setActionActive("first", can_nav)
    CALL dlg.setActionActive("next", can_nav)
    CALL dlg.setActionActive("previous", can_nav)
    CALL dlg.setActionActive("last", can_nav)
    CALL dlg.setActionActive("append", TRUE)
    CALL dlg.setActionActive("update", can_nav)
    CALL dlg.setActionActive("delete", can_nav)
    
END FUNCTION


