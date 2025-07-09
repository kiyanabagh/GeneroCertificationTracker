IMPORT FGL utils
{Glitchy Input User info, after you input a user, to exit the page, you have to click cancel
}

SCHEMA cert_trackerdb_2 --connect to db schema
TYPE t_user_rec RECORD LIKE User.*
TYPE t_userarray DYNAMIC ARRAY OF t_user_rec
DEFINE userarr t_userarray
DEFINE rec t_user_rec
--define temporary storage array of user records for future use
DEFINE useratt DYNAMIC ARRAY OF RECORD
    userid LIKE user.userid,
    fname LIKE user.fname,
    lname LIKE user.lname,
    primary_email LIKE user.primary_email,
    secondary_email LIKE user.secondary_email,
    seeking_employment LIKE user.seeking_employment,
    company LIKE USER.company,
    contact_date LIKE user.contact_date,
    phone_num LIKE user.phone_num,
    reason_for_cert LIKE user.reason_for_cert
END RECORD

--the function called by cert_tracker_src, acts as main
FUNCTION user_form_driver()
--define function variables for the sql conditions and fields of the form
    DEFINE
        sql_cond STRING,
        userid LIKE user.userid

    --open a window with the user info form
    OPEN WINDOW w2 WITH FORM "user_info_form"

    MENU
        ON ACTION query_users
            WHILE TRUE --create a scenario where the search query field can be autopopulated and can be used directly without creating any action button
                LET sql_cond =
                    userlist_query() --retrieve sql condition from form fields
                IF sql_cond IS NULL THEN
                    EXIT WHILE
                END IF

                LET userid = userarr_display(sql_cond)
                CASE
                    WHEN userid < 0
                        EXIT WHILE
                    WHEN userid == 0
                        MESSAGE "Now rows found!"
                    OTHERWISE
                        MESSAGE SFMT("user #%1 was selected", userid)

                        CALL user_update() --This allows you to update the user selected in the query
                        EXIT WHILE
                END CASE

            END WHILE

            --calls function to input, update, or delete user information
        ON ACTION input_user
            CLEAR FORM
            CALL user_input()

        ON ACTION QUIT
            EXIT MENU

    END MENU
    CLOSE WINDOW w2

END FUNCTION

FUNCTION user_input()
    DEFINE x INTEGER
    LET int_flag = FALSE
    CALL userarr.clear()

    INPUT ARRAY userarr
        FROM record1.* --get an input array from the screen array
        ATTRIBUTES(UNBUFFERED, --your form fills and your program vars are filled automatially, auto synch
            APPEND ROW = FALSE,
            DELETE ROW = FALSE,
            WITHOUT DEFAULTS)

        BEFORE INSERT --make insert button, insert onto bottom

            LET x = arr_curr() --x is the current array

        BEFORE ROW
            CALL DIALOG.setFieldActive("userid", FALSE)

        AFTER ROW
            IF int_flag THEN
                EXIT INPUT
            END IF
            LET x = arr_curr()

            TRY --insert the orders
                LET userarr[x].userid = userarr[x].fname || userarr[x].lname
                INSERT INTO user VALUES(userarr[x].*)
                MESSAGE "Record has been inserted successfully"
            CATCH
                ERROR SQLERRMESSAGE
                NEXT FIELD CURRENT
            END TRY

    END INPUT

END FUNCTION

PRIVATE FUNCTION userlist_query() RETURNS STRING
    DEFINE sql_cond STRING

    CLEAR FORM --clear the form

    LET int_flag = FALSE
    --translates to select * from account (where userid = value) where is construct
    CONSTRUCT BY NAME sql_cond
        ON user.* --make an sql query based on fields in the userid field

    CLEAR FORM
    IF int_flag THEN
        RETURN NULL
    ELSE
        RETURN sql_cond --return the sql condition
    END IF

END FUNCTION

PRIVATE FUNCTION userarr_fill(sql_cond STRING) RETURNS INTEGER
    DEFINE
        sql_text STRING,
        rec t_user_rec,
        x INTEGER

    LET sql_text = "SELECT * FROM user" --text to get all info from account

    IF sql_cond IS NOT NULL THEN
        LET sql_text =
            sql_text
                || " WHERE "
                || sql_cond --make full query with the where condition
    END IF

    LET sql_text = sql_text || " ORDER BY user.userid"

    DECLARE ca_curs CURSOR FROM sql_text --defining a cursor with the sql query

    --empty the array before you fill it again
    CALL userarr.clear()
    CALL useratt.clear()

    --takes all of the records on by one into the variable
    FOREACH ca_curs INTO rec.* --for the sql query into account
        LET x = x + 1 --incrementing index of array to store vals of db
        LET userarr[x] = rec
    END FOREACH

    CLOSE ca_curs
    FREE ca_curs

    RETURN userarr.getLength()

END FUNCTION

PRIVATE FUNCTION userarr_display(sql_cond STRING) RETURNS(LIKE user.userid)
    DEFINE
        cnt INTEGER,
        x INTEGER

    LET cnt =
        userarr_fill(sql_cond) --gets a count of the number of rows returned
    IF cnt == 0 THEN
        RETURN 0
    END IF

    LET int_flag = FALSE --unsets the actions so you can do another action
--sa_user is the name of the form, double click outside the form to change the name
    DISPLAY ARRAY userarr TO record1.* ATTRIBUTES(UNBUFFERED)
        --tranfering acctarr dynamic array values to the screen array (populating the form)
        BEFORE DISPLAY

            MESSAGE ""
            CALL DIALOG.setArrayAttributes(
                "record1", useratt) --dialog box that appears on screen

        AFTER DISPLAY
            LET x = DIALOG.getCurrentRow("record1") --just a dialog box
        ON ACTION refresh ATTRIBUTES(TEXT = "Refresh", ACCELERATOR = "F5")
            LET cnt = userarr_fill(sql_cond)
    END DISPLAY

    IF int_flag THEN
        RETURN -1
    ELSE
        RETURN userarr[x].userid
    END IF

END FUNCTION

FUNCTION user_update()

    DEFINE x INTEGER

    LET int_flag = FALSE

    INPUT ARRAY userarr
        FROM record1.* --get an input array from the screen array
        ATTRIBUTES(UNBUFFERED, --your form fills and your program vars are filled automatially, auto synch
            APPEND ROW = FALSE,
            INSERT ROW = FALSE,
            DELETE ROW = FALSE,
            WITHOUT DEFAULTS)

        BEFORE INSERT --make insert button, insert onto bottom
            LET x = arr_curr() --x is the current array

        BEFORE ROW
            CALL DIALOG.setFieldActive("userid", FALSE)

        AFTER ROW
            IF int_flag THEN
                EXIT INPUT
            END IF
            LET x = arr_curr()

            TRY --insert the orders
                UPDATE USER
                    SET user.* = userarr[x].*
                    WHERE user.userid = userarr[x].userid
                MESSAGE "Record has been updated successfully"

            CATCH
                ERROR SQLERRMESSAGE
                NEXT FIELD CURRENT
            END TRY

    END INPUT
END FUNCTION
