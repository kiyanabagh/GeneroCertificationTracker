IMPORT FGL practical_test_query
IMPORT FGL practical_test_data

SCHEMA cert_trackerdb_2

PUBLIC TYPE t_ptest_rec RECORD LIKE practicaltest.*
PUBLIC TYPE t_ptest_id LIKE practicaltest.testid

FUNCTION ptest_form_driver()
    DEFINE current_ptest t_ptest_id

    DEFER INTERRUPT

    OPEN WINDOW w3 WITH FORM "practical_test_form"

    MENU "ptests"
        BEFORE MENU 
            CALL setup_dialog(DIALOG, FALSE)
        ON ACTION query ATTRIBUTES(COMMENT = "Search for customers")
            VAR can_nav = practical_test_query.query_ptest()
            CALL setup_dialog(DIALOG, can_nav)
            IF can_nav THEN
                LET current_ptest = practical_test_query.fetch_rel_ptest(0)
            END IF
        ON ACTION first
            LET current_ptest = practical_test_query.fetch_rel_ptest(0)
        ON ACTION next
            LET current_ptest = practical_test_query.fetch_rel_ptest(1)
        ON ACTION previous
            LET current_ptest = practical_test_query.fetch_rel_ptest(-1)
        ON ACTION last
            LET current_ptest = practical_test_query.fetch_rel_ptest(2)
        ON ACTION append
            LET current_ptest = practical_test_data.append_ptest(current_ptest)
            IF current_ptest > 0 THEN
                LET current_ptest = practical_test_query.fetch_rel_ptest(3)
            END IF
            CALL setup_dialog(DIALOG, (current_ptest > 0))
            if practical_test_data.certification_complete_test(current_ptest) THEN 
                DISPLAY "yayyy"
            END if
        ON ACTION update
            LET current_ptest = practical_test_data.update_ptest(current_ptest)
            IF current_ptest > 0 THEN
                LET current_ptest = practical_test_query.fetch_rel_ptest(3)
            END IF
            CALL setup_dialog(DIALOG, (current_ptest > 0))
            if practical_test_data.certification_complete_test(current_ptest) THEN 
                    DISPLAY "yayyy"
                END if
        ON ACTION delete
            LET current_ptest = practical_test_data.delete_ptest(current_ptest)
            CALL setup_dialog(DIALOG, (current_ptest > 0))
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


FUNCTION ptest_form_driver_forid(current_ptest)
    DEFINE current_ptest LIKE practicaltest.testid

    DEFER INTERRUPT

    OPEN WINDOW w3 WITH FORM "practical_test_form"

    MENU "practical test"
        BEFORE MENU 
            CALL setup_dialog(DIALOG, FALSE)
        ON ACTION query ATTRIBUTES(TEXT = "View User's practical Tests")
            VAR can_nav = practical_test_query.query_ptest2(current_ptest)
            CALL setup_dialog(DIALOG, can_nav)
            IF can_nav THEN
                LET current_ptest = practical_test_query.fetch_rel_ptest(0)
            END IF
        ON ACTION first
            LET current_ptest = practical_test_query.fetch_rel_ptest(0)
        ON ACTION next
            LET current_ptest = practical_test_query.fetch_rel_ptest(1)
        ON ACTION previous
            LET current_ptest = practical_test_query.fetch_rel_ptest(-1)
        ON ACTION last
            LET current_ptest = practical_test_query.fetch_rel_ptest(2)
        ON ACTION APPEND ATTRIBUTES(Text = "Add New practical Test")
            LET current_ptest = practical_test_data.append_ptest_with_id(current_ptest)
            IF current_ptest > 0 THEN
                LET current_ptest = practical_test_query.fetch_rel_ptest(3)
            END IF
            CALL setup_dialog(DIALOG, (current_ptest > 0))
            CALL setup_dialog(DIALOG, (current_ptest > 0))
            if practical_test_data.certification_complete_test(current_ptest) THEN 
                    DISPLAY "yayyy"
                END if
            
        ON ACTION update
            LET current_ptest = practical_test_data.update_ptest(current_ptest)
            IF current_ptest > 0 THEN
                LET current_ptest = practical_test_query.fetch_rel_ptest(3)
            END IF
            CALL setup_dialog(DIALOG, (current_ptest > 0))
            CALL setup_dialog(DIALOG, (current_ptest > 0))
            if practical_test_data.certification_complete_test(current_ptest) THEN 
                    DISPLAY "yayyy"
                END if


        ON ACTION delete
            LET current_ptest = practical_test_data.delete_ptest(current_ptest)
            CALL setup_dialog(DIALOG, (current_ptest > 0))
        ON ACTION quit
            EXIT MENU
        ON ACTION close
            EXIT MENU
        ON ACTION exit
            EXIT MENU

    END MENU
CLOSE WINDOW w3
END function


