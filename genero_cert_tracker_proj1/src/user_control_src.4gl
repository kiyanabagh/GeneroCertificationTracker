IMPORT FGL utils

SCHEMA db_creation_test
    TYPE t_user_rec RECORD LIKE User.*
    TYPE t_userarray DYNAMIC ARRAY OF t_user_rec
    DEFINE userarr t_userarray

    --may need to add company to db
DEFINE useratt DYNAMIC ARRAY OF RECORD --make another dynamic array of record to search with userid
    --office_num STRING,
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
    
FUNCTION user_form_driver()
  DEFINE sql_cond STRING,
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
         
    OPEN WINDOW w2 WITH FORM "user_info_form"
     {OPEN FORM fca FROM "user_info_form" --open and display my db form, this form has all of the fields
        DISPLAY FORM fca}

    MENU
        ON ACTION query_users
          WHILE TRUE --create a scenario where the search query field can be autopopulated and can be used directly without creating any action button
        --loop only functions when the sql condition has something
            LET sql_cond = userid_query() --call acclist query to get sql condition
            IF sql_cond IS NULL THEN 
               EXIT WHILE
            END IF

            LET userid = userarr_display(sql_cond) --
            CASE
            WHEN userid < 0
               EXIT WHILE
            WHEN userid == 0
               MESSAGE "Now rows found!"
            OTHERWISE
               MESSAGE SFMT("account #%1 was selected",userid)
            END CASE
        END WHILE

        ON ACTION input_user
            
            CALL userarr_input()
        ON ACTION QUIT
            EXIT MENU
        
    END MENU
    CLOSE WINDOW w2

 
END FUNCTION

FUNCTION userid_query() RETURNS STRING
DEFINE sql_cond STRING

  CLEAR FORM 

  LET int_flag = FALSE
  --allows user to query on all fields in the form
  CONSTRUCT BY NAME sql_cond ON user.userid, user.fname, user.lname, user.primary_email, user.secondary_email, user.company, user.contact_date, user.reason_for_cert, user.seeking_employment, user.phone_num --make an sql query based on fields in the userid field

  IF int_flag THEN
     RETURN NULL
  ELSE
     RETURN sql_cond 
  END IF

END FUNCTION

PRIVATE FUNCTION userarr_fill(sql_cond STRING) RETURNS INTEGER
  DEFINE sql_text STRING,
         rec t_user_rec,
         x INTEGER

  LET sql_text = "SELECT * FROM User" --creates initial sql query to get all entries in user table
  
  IF sql_cond IS NOT NULL THEN
     LET sql_text = sql_text || " WHERE " || sql_cond --make full query with the where condition
  END IF
  
  LET sql_text = sql_text || " ORDER BY user.userid"

  DECLARE ca_curs CURSOR FROM sql_text --defining a cursor with the sql query

  --empty the array before you fill it again
    CALL userarr.clear()
    CALL useratt.clear()

    --takes all of the records on by one into the variable
  FOREACH ca_curs INTO rec.* --for the sql query into account
     LET x = x + 1 --incrementing index of array to store vals of db
     LET userarr[x] = rec --stores all user info from the query in the userarr
  END FOREACH

  CLOSE ca_curs
  FREE ca_curs

  RETURN userarr.getLength() --returns the number of user entries returned by the 

END FUNCTION

PRIVATE FUNCTION userarr_display(sql_cond STRING) RETURNS (LIKE User.userid)
  DEFINE cnt INTEGER,
         x INTEGER

  LET cnt = userarr_fill(sql_cond)  --gets a count of the number of rows returned
  IF cnt == 0 THEN
     RETURN 0
  END IF

  LET int_flag = FALSE --unsets the actions so you can do another action
--record1 is the name of the form, double click outside the form to change the name
  DISPLAY ARRAY userarr TO record1.* ATTRIBUTES(UNBUFFERED)
  --tranfering userarr dynamic array values to the screen array (populating the form)
     BEFORE DISPLAY  
        MESSAGE ""
        CALL DIALOG.setArrayAttributes("record1", useratt) --dialog box that appears on screen
        --CALL DIALOG.setSelectionMode("sa_acct", 1)
        --this empties everything and starts it froms scratch so when you hit the next button, it gets refreshed
     BEFORE ROW 
        LET x = DIALOG.getCurrentRow("record1")  
        DISPLAY userarr[x].userid, --you can lowk remove this, it is overwriting the display we did earlier
                userarr[x].fname,
                userarr[x].lname,
                userarr[x].primary_email,
                userarr[x].secondary_email,
                userarr[x].contact_date,
                userarr[x].seeking_employment,
                userarr[x].phone_num,
                userarr[x].reason_for_cert
                
     AFTER DISPLAY
        LET x = DIALOG.getCurrentRow("record1") --just a dialog box
     ON ACTION refresh ATTRIBUTES(TEXT="Refresh",ACCELERATOR="F5")
        LET cnt = userarr_fill(sql_cond)
  END DISPLAY

  IF int_flag THEN
     RETURN -1
  ELSE
     RETURN userarr[x].userid
  END IF


END FUNCTION



PRIVATE FUNCTION userarr_input() RETURNS ()
  DEFINE x INTEGER
  DEFINE op CHAR(1)
  --DEFINE f ui.Form 

  LET int_flag = FALSE

  INPUT ARRAY userarr FROM record1.* --get an input array from the screen array
          ATTRIBUTES(UNBUFFERED, --your form fills and your program vars are filled automatially, auto synch
                     CANCEL = FALSE,
                     WITHOUT DEFAULTS)

     BEFORE DELETE --to delete from the form, delete button
        DISPLAY "BEFORE DELETE: op=",op
        IF op == "N" THEN
           LET x = arr_curr() --pointer in cursor to get the current row
           IF NOT utils.mbox_yn("user",
                "Are you sure you want to delete this record?") --make sure user wants to delete the reord
           THEN
              CANCEL DELETE
           END IF
           TRY
              DELETE FROM User
                  WHERE userid = userarr[x].userid --delete the record from the order array where the orderid matches what was in the screen array
           CATCH
              ERROR SQLERRMESSAGE
              CANCEL DELETE
           END TRY
        END IF

     AFTER DELETE --after the row has been deleted, give message
        DISPLAY "AFTER DELETE: op=",op
        IF op == "N" THEN
           MESSAGE "Record has been deleted successfully"
        ELSE
           LET op = "N"
        END IF


     ON ROW CHANGE 
        DISPLAY "ON ROW CHANGE: op=",op
        IF op != "I" THEN LET op = "M" END IF

    
     BEFORE INSERT --make insert button, insert onto bottom
        
        DISPLAY "BEFORE INSERT: op=",op
        LET op = "T" --?
        LET x = arr_curr() --x is the current array
        LET userarr[x].userid = 1000 + arr_curr() --set default values for what you insert
        LET userarr[x].userid = "<undefined>"

     AFTER INSERT
        DISPLAY "AFTER INSERT: op=",op
        LET op = "I"

     BEFORE ROW
        DISPLAY "BEFORE ROW: op=",op
        LET op = "N"

        --sees if a name is like valid or not, it cant have a number
     AFTER ROW
        DISPLAY "AFTER ROW: op=",op
        IF int_flag THEN EXIT INPUT END IF
        LET x = arr_curr() 
        IF op == "I" THEN
           TRY --insert the orders 
              INSERT INTO User VALUES ( userarr[x].* )
              MESSAGE "Record has been inserted successfully"
           CATCH
              ERROR SQLERRMESSAGE
              NEXT FIELD CURRENT
           END TRY

        END IF
        IF op == "M" THEN
           TRY --update orders
              LET x = arr_curr()
              UPDATE user SET user.* = userarr[x].*
                  WHERE userid = userarr[x].userid
              MESSAGE "Record has been updated successfully"
           CATCH
              ERROR "Could not update the record in database!"
              NEXT FIELD CURRENT
           END TRY
        END IF

  END INPUT

END FUNCTION
