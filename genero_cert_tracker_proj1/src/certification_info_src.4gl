IMPORT FGL utils

SCHEMA cert_trackerdb_2

    TYPE t_cert_rec RECORD LIKE certification.*
    TYPE t_certarray DYNAMIC ARRAY OF t_cert_rec
    DEFINE certarr t_certarray

DEFINE certatt DYNAMIC ARRAY OF RECORD 
    userid LIKE certification.userid,
    certid LIKE certification.certid,
    DATE LIKE certification.date
    END RECORD

--the function called when knowledge test info button is selected from main menu
FUNCTION certification_driver()

--define function variables for the sql conditions and fields of the form
    DEFINE
        sql_cond STRING,
        userid LIKE certification.userid

    --open a window with the user info form
    OPEN WINDOW w2 WITH FORM "certification_info_form"

    MENU
        ON ACTION query_certification
            WHILE TRUE --create a scenario where the search query field can be autopopulated and can be used directly without creating any action button
                LET sql_cond =
                    certificationlist_query() --retrieve sql condition from form fields
                IF sql_cond IS NULL THEN
                    EXIT WHILE
                END IF

                LET userid = certificationarr_display(sql_cond)
                CASE
                    WHEN userid < 0
                        EXIT WHILE
                    WHEN userid == 0
                        MESSAGE "Now rows found!"
                    OTHERWISE
                        MESSAGE SFMT("certification #%1 was selected", userid)

                        CALL certification_update() --This allows you to update the user selected in the query
                        EXIT WHILE
                END CASE

            END WHILE

            --calls function to input, update, or delete user information
        ON ACTION input_certification
            CLEAR FORM
            CALL certification_input()

        ON ACTION QUIT
            EXIT MENU

    END MENU
    CLOSE WINDOW w2

END FUNCTION

FUNCTION certification_input()
    DEFINE x INTEGER, lname LIKE user.lname
    LET int_flag = FALSE
    CALL certarr.clear()

    INPUT ARRAY certarr
        FROM record1.* --get an input array from the screen array
        ATTRIBUTES(UNBUFFERED, --your form fills and your program vars are filled automatially, auto synch
            APPEND ROW = FALSE,
            DELETE ROW = FALSE,
            WITHOUT DEFAULTS)

        BEFORE INSERT --make insert button, insert onto bottom

            LET x = arr_curr() --x is the current array


        AFTER ROW
            IF int_flag THEN
                EXIT INPUT
            END IF
            LET x = arr_curr()

            TRY --insert the orders
                INSERT INTO certification VALUES(certarr[x].*)
                MESSAGE "Record has been inserted successfully"
            CATCH
                ERROR SQLERRMESSAGE
                NEXT FIELD CURRENT
            END TRY

    END INPUT

END FUNCTION

PRIVATE FUNCTION certificationlist_query() RETURNS STRING
    DEFINE sql_cond STRING

    CLEAR FORM --clear the form

    LET int_flag = FALSE
    --translates to select * from account (where certificationid = value) where is construct
    CONSTRUCT BY NAME sql_cond
        ON certification.* --make an sql query based on fields in the userid field

    CLEAR FORM
    IF int_flag THEN
        RETURN NULL
    ELSE
        RETURN sql_cond --return the sql condition
    END IF

END FUNCTION

PRIVATE FUNCTION certificationarr_fill(sql_cond STRING) RETURNS INTEGER
    DEFINE
        sql_text STRING,
        rec t_cert_rec,
        x INTEGER

    LET sql_text = "SELECT * FROM certification" --text to get all info from account

    IF sql_cond IS NOT NULL THEN
        LET sql_text =
            sql_text
                || " WHERE "
                || sql_cond --make full query with the where condition
    END IF

    LET sql_text = sql_text || " ORDER BY certification.userid"

    DECLARE ca_curs CURSOR FROM sql_text --defining a cursor with the sql query

    --empty the array before you fill it again
    CALL certarr.clear()
    CALL certatt.clear()

    --takes all of the records on by one into the variable
    FOREACH ca_curs INTO rec.* --for the sql query into account
        LET x = x + 1 --incrementing index of array to store vals of db
        LET certarr[x] = rec
    END FOREACH

    CLOSE ca_curs
    FREE ca_curs

    RETURN certarr.getLength()

END FUNCTION

PRIVATE FUNCTION certificationarr_display(sql_cond STRING) RETURNS(LIKE certification.userid)
    DEFINE
        cnt INTEGER,
        x INTEGER

    LET cnt =
        certificationarr_fill(sql_cond) --gets a count of the number of rows returned
    IF cnt == 0 THEN
        RETURN 0
    END IF

    LET int_flag = FALSE --unsets the actions so you can do another action
--sa_user is the name of the form, double click outside the form to change the name
    DISPLAY ARRAY certarr TO record1.* ATTRIBUTES(UNBUFFERED)
        --tranfering acctarr dynamic array values to the screen array (populating the form)
        BEFORE DISPLAY

            MESSAGE ""
            CALL DIALOG.setArrayAttributes(
                "record1", certatt) --dialog box that appears on screen

        AFTER DISPLAY
            LET x = DIALOG.getCurrentRow("record1") --just a dialog box
        ON ACTION refresh ATTRIBUTES(TEXT = "Refresh", ACCELERATOR = "F5")
            LET cnt = certificationarr_fill(sql_cond)
    END DISPLAY

    IF int_flag THEN
        RETURN -1
    ELSE
        RETURN certarr[x].userid
    END IF

END FUNCTION

FUNCTION certification_update()

    DEFINE x INTEGER

    LET int_flag = FALSE

    INPUT ARRAY certarr
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
                UPDATE certification
                    SET certification.* = certarr[x].*
                    WHERE certification.userid = certarr[x].userid
                MESSAGE "Record has been updated successfully"

            CATCH
                ERROR SQLERRMESSAGE
                NEXT FIELD CURRENT
            END TRY

    END INPUT
END FUNCTION