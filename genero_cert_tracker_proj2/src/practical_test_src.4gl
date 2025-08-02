IMPORT FGL utils
{logic working successfully now}
SCHEMA cert_trackerdb_2

    TYPE t_ptest_rec RECORD LIKE practicaltest.*
    TYPE t_ptestarray DYNAMIC ARRAY OF t_ptest_rec
    DEFINE ptestarr t_ptestarray

DEFINE ptestatt DYNAMIC ARRAY OF RECORD 
    userid LIKE practicaltest.userid,
    testid LIKE practicaltest.testid,
    grade LIKE practicaltest.grade,
    date_started LIKE practicaltest.date_started,
    date_completed LIKE practicaltest.date_completed,
    genero_version LIKE practicaltest.genero_version,
    scenario LIKE practicaltest.scenario,
    status LIKE practicaltest.status,
    reviewer_comment LIKE practicaltest.comment
    END RECORD
    
    DEFINE record_count INTEGER

    FUNCTION practical_test_driver()

--define function variables for the sql conditions and fields of the form
    DEFINE
        sql_cond STRING,
        testid LIKE practicaltest.testid

    --open a window with the user info form
    OPEN WINDOW w2 WITH FORM "practical_test_form"

    MENU
        ON ACTION query_practical_test
            WHILE TRUE --create a scenario where the search query field can be autopopulated and can be used directly without creating any action button
                LET sql_cond =
                    practical_testlist_query() --retrieve sql condition from form fields
                IF sql_cond IS NULL THEN
                    EXIT WHILE
                END IF

                LET testid = practical_testarr_display(sql_cond)
                CASE
                    WHEN testid < 0
                        EXIT WHILE
                    WHEN testid == 0
                        MESSAGE "Now rows found!"
                    OTHERWISE
                        MESSAGE SFMT("practical_test #%1 was selected", testid)

                        CALL practical_test_update() --This allows you to update the user selected in the query
                        EXIT WHILE
                END CASE

            END WHILE

            --calls function to input, update, or delete user information
        ON ACTION input_practical_test
            CLEAR FORM
            CALL practical_test_input()

        ON ACTION QUIT
            EXIT MENU

    END MENU
    CLOSE WINDOW w2

END FUNCTION

FUNCTION practical_test_input()
    DEFINE x INTEGER, lname LIKE user.lname
    LET int_flag = FALSE
    CALL ptestarr.clear()

    INPUT ARRAY ptestarr
        FROM record1.* --get an input array from the screen array
        ATTRIBUTES(UNBUFFERED, --your form fills and your program vars are filled automatially, auto synch
            APPEND ROW = FALSE,
            DELETE ROW = FALSE,
            WITHOUT DEFAULTS)

        BEFORE INSERT --make insert button, insert onto bottom

            LET x = arr_curr() --x is the current array

        BEFORE ROW
            CALL DIALOG.setFieldActive("testid", FALSE)

        AFTER ROW
            IF int_flag THEN
                EXIT INPUT
            END IF
            LET x = arr_curr()

            TRY --insert the orders
                SELECT user.lname INTO lname FROM USER WHERE user.userid = ptestarr[x].userid
                LET ptestarr[x].testid = ptestarr[x].genero_version || "_"|| lname
                INSERT INTO practicaltest VALUES(ptestarr[x].*)
                MESSAGE "Record has been inserted successfully"
            CATCH
                ERROR SQLERRMESSAGE
                NEXT FIELD CURRENT
            END TRY

    END INPUT

END FUNCTION

PRIVATE FUNCTION practical_testlist_query() RETURNS STRING
    DEFINE sql_cond STRING

    CLEAR FORM --clear the form

    LET int_flag = FALSE
    --translates to select * from account (where practical_testid = value) where is construct
    CONSTRUCT BY NAME sql_cond
        ON practicaltest.* --make an sql query based on fields in the userid field

    CLEAR FORM
    IF int_flag THEN
        RETURN NULL
    ELSE
        RETURN sql_cond --return the sql condition
    END IF

END FUNCTION

PRIVATE FUNCTION practical_testarr_fill(sql_cond STRING) RETURNS INTEGER
    DEFINE
        sql_text STRING,
        rec t_ptest_rec,
        x INTEGER

    LET sql_text = "SELECT * FROM practicaltest" --text to get all info from account

    IF sql_cond IS NOT NULL THEN
        LET sql_text =
            sql_text
                || " WHERE "
                || sql_cond --make full query with the where condition
    END IF

    LET sql_text = sql_text || " ORDER BY practicaltest.testid"

    DECLARE ca_curs CURSOR FROM sql_text --defining a cursor with the sql query

    --empty the array before you fill it again
    CALL ptestarr.clear()
    CALL ptestatt.clear()

    --takes all of the records on by one into the variable
    FOREACH ca_curs INTO rec.* --for the sql query into account
        LET x = x + 1 --incrementing index of array to store vals of db
        LET ptestarr[x] = rec
    END FOREACH

    CLOSE ca_curs
    FREE ca_curs

    RETURN ptestarr.getLength()

END FUNCTION

PRIVATE FUNCTION practical_testarr_display(sql_cond STRING) RETURNS(LIKE practicaltest.testid)
    DEFINE
        cnt INTEGER,
        x INTEGER

    LET cnt =
        practical_testarr_fill(sql_cond) --gets a count of the number of rows returned
    IF cnt == 0 THEN
        RETURN 0
    END IF

    LET int_flag = FALSE --unsets the actions so you can do another action
--sa_user is the name of the form, double click outside the form to change the name
    DISPLAY ARRAY ptestarr TO record1.* ATTRIBUTES(UNBUFFERED)
        --tranfering acctarr dynamic array values to the screen array (populating the form)
        BEFORE DISPLAY

            MESSAGE ""
            CALL DIALOG.setArrayAttributes(
                "record1", ptestatt) --dialog box that appears on screen

        AFTER DISPLAY
            LET x = DIALOG.getCurrentRow("record1") --just a dialog box
        ON ACTION refresh ATTRIBUTES(TEXT = "Refresh", ACCELERATOR = "F5")
            LET cnt = practical_testarr_fill(sql_cond)
    END DISPLAY

    IF int_flag THEN
        RETURN -1
    ELSE
        RETURN ptestarr[x].testid
    END IF

END FUNCTION

FUNCTION practical_test_update()

    DEFINE x INTEGER

    LET int_flag = FALSE

    INPUT ARRAY ptestarr
        FROM record1.* --get an input array from the screen array
        ATTRIBUTES(UNBUFFERED, --your form fills and your program vars are filled automatially, auto synch
            APPEND ROW = FALSE,
            INSERT ROW = FALSE,
            DELETE ROW = FALSE,
            WITHOUT DEFAULTS)

        BEFORE INSERT --make insert button, insert onto bottom
            LET x = arr_curr() --x is the current array

        BEFORE ROW
            CALL DIALOG.setFieldActive("testid", FALSE)
            CALL DIALOG.setFieldActive("userid", FALSE)

        AFTER ROW
            IF int_flag THEN
                EXIT INPUT
            END IF
            LET x = arr_curr()

            TRY --insert the orders
                UPDATE practicaltest
                    SET practicaltest.* = ptestarr[x].*
                    WHERE practicaltest.testid = ptestarr[x].testid
                MESSAGE "Record has been updated successfully"

            CATCH
                ERROR SQLERRMESSAGE
                NEXT FIELD CURRENT
            END TRY

    END INPUT
END FUNCTION