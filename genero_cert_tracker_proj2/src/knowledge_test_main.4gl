IMPORT FGL knowledge_test_query
IMPORT FGL knowledge_test_data

SCHEMA cert_trackerdb_2

PUBLIC TYPE t_ktest_rec RECORD LIKE knowledgetest.*
PUBLIC TYPE t_ktest_id LIKE knowledgetest.testid

FUNCTION ktest_form_driver()
    DEFINE current_ktest t_ktest_id

    DEFER INTERRUPT

    OPEN WINDOW w3 WITH FORM "knowledge_test_form"

    MENU "ktests"
        BEFORE MENU 
            CALL setup_dialog(DIALOG, FALSE)
        ON ACTION query ATTRIBUTES(COMMENT = "Search for customers")
            VAR can_nav = knowledge_test_query.query_ktest()
            CALL setup_dialog(DIALOG, can_nav)
            IF can_nav THEN
                LET current_ktest = knowledge_test_query.fetch_rel_ktest(0)
            END IF
        ON ACTION first
            LET current_ktest = knowledge_test_query.fetch_rel_ktest(0)
        ON ACTION next
            LET current_ktest = knowledge_test_query.fetch_rel_ktest(1)
        ON ACTION previous
            LET current_ktest = knowledge_test_query.fetch_rel_ktest(-1)
        ON ACTION last
            LET current_ktest = knowledge_test_query.fetch_rel_ktest(2)
        ON ACTION append
            LET current_ktest = knowledge_test_data.append_ktest(current_ktest)
            IF current_ktest > 0 THEN
                LET current_ktest = knowledge_test_query.fetch_rel_ktest(3)
            END IF
            CALL setup_dialog(DIALOG, (current_ktest > 0))
            if knowledge_test_data.certification_complete_test2(current_ktest) THEN 
                    DISPLAY "yayyy"
            END if
        ON ACTION update
            LET current_ktest = knowledge_test_data.update_ktest(current_ktest)
            IF current_ktest > 0 THEN
                LET current_ktest = knowledge_test_query.fetch_rel_ktest(3)
            END IF
            
            CALL setup_dialog(DIALOG, (current_ktest > 0))
            if knowledge_test_data.certification_complete_test2(current_ktest) THEN 
                    DISPLAY "yayyy"
            END if
        ON ACTION delete
            LET current_ktest = knowledge_test_data.delete_ktest(current_ktest)
            CALL setup_dialog(DIALOG, (current_ktest > 0))
        ON ACTION quit
            EXIT MENU
        ON ACTION close
            EXIT MENU
        ON ACTION exit
            EXIT MENU

    END MENU
CLOSE WINDOW w3
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


FUNCTION ktest_form_driver_forid(current_ktest)
    DEFINE current_ktest LIKE knowledgetest.testid

    DEFER INTERRUPT

    OPEN WINDOW w3 WITH FORM "knowledge_test_form"

    MENU "knowledge test"
        BEFORE MENU 
            CALL setup_dialog(DIALOG, FALSE)
        ON ACTION query ATTRIBUTES(TEXT = "View User's Knowledge Tests")
            VAR can_nav = knowledge_test_query.query_ktest2(current_ktest)
            CALL setup_dialog(DIALOG, can_nav)
            IF can_nav THEN
                LET current_ktest = knowledge_test_query.fetch_rel_ktest(0)
            END IF
        ON ACTION first
            LET current_ktest = knowledge_test_query.fetch_rel_ktest(0)
        ON ACTION next
            LET current_ktest = knowledge_test_query.fetch_rel_ktest(1)
        ON ACTION previous
            LET current_ktest = knowledge_test_query.fetch_rel_ktest(-1)
        ON ACTION last
            LET current_ktest = knowledge_test_query.fetch_rel_ktest(2)
        ON ACTION APPEND ATTRIBUTES(Text = "Add New Knowledge Test")
            LET current_ktest = knowledge_test_data.append_ktest_with_id(current_ktest)
            IF current_ktest > 0 THEN
                LET current_ktest = knowledge_test_query.fetch_rel_ktest(3)
            END IF
            CALL setup_dialog(DIALOG, (current_ktest > 0))
            IF knowledge_test_data.certification_complete_test2(current_ktest) THEN
            DISPLAY "yayyy"
            END IF 
        ON ACTION update
            LET current_ktest = knowledge_test_data.update_ktest(current_ktest)
            IF current_ktest > 0 THEN
                LET current_ktest = knowledge_test_query.fetch_rel_ktest(3)
            END IF
    
            CALL setup_dialog(DIALOG, (current_ktest > 0))
            if knowledge_test_data.certification_complete_test2(current_ktest) THEN 
                    DISPLAY "yayyy"
            END if

        ON ACTION delete
            LET current_ktest = knowledge_test_data.delete_ktest(current_ktest)
            CALL setup_dialog(DIALOG, (current_ktest > 0))
        ON ACTION quit
            EXIT MENU
        ON ACTION close
            EXIT MENU
        ON ACTION exit
            EXIT MENU

    END MENU
CLOSE WINDOW w3
END function


