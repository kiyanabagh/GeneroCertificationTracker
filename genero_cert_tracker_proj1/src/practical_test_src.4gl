IMPORT FGL utils
{logic working successfully now}
SCHEMA db_creation_test

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

  DEFINE sql_cond STRING,
    userid LIKE practicaltest.userid,
    testid LIKE practicaltest.testid,
    grade LIKE practicaltest.grade,
    date_completed LIKE practicaltest.date_completed,
    genero_version LIKE practicaltest.genero_version

    LET record_count = ptest_record_count()
    
    OPEN WINDOW w3 WITH FORM "practical_test_form"
    MENU
    ON ACTION query_ptests
          WHILE TRUE --create a scenario where the search query field can be autopopulated and can be used directly without creating any action button
        --loop only functions when the sql condition has something
            LET sql_cond = ptestid_query() --call acclist query to get sql condition
            IF sql_cond IS NULL THEN 
               EXIT WHILE
            END IF

            LET testid = ptestarr_display(sql_cond) --
            CASE
            WHEN testid < 0
               EXIT WHILE
            WHEN testid == 0
               MESSAGE "Now rows found!"
            OTHERWISE
               MESSAGE SFMT("ptest #%1 was selected",testid)
               --CALL ptestarr_input() --works, need to update for back and ok
               EXIT WHILE --logic here works! returns to the main menu after something is selected
            END CASE
        END WHILE

        ON ACTION input_practicaltest
            
            CALL ptestarr_input()
        ON ACTION QUIT
            EXIT MENU
        
    END MENU

    CLOSE WINDOW w3
END FUNCTION


FUNCTION ptestid_query() RETURNS STRING
DEFINE sql_cond STRING

  CLEAR FORM 

  LET int_flag = FALSE
  --allows user to query on all fields in the form
  CONSTRUCT BY NAME sql_cond ON practicaltest.userid, practicaltest.testid, practicaltest.grade, practicaltest.genero_version, practicaltest.date_completed, practicaltest.date_started, practicaltest.scenario, practicaltest.status

  IF int_flag THEN
     RETURN NULL
  ELSE
     RETURN sql_cond 
  END IF

END FUNCTION

PRIVATE FUNCTION ptestarr_fill(sql_cond STRING) RETURNS INTEGER
  DEFINE sql_text STRING,
         rec t_ptest_rec,
         x INTEGER

  LET sql_text = "SELECT * FROM practicaltest" --creates initial sql query to get all entries in practicaltest table
  
  IF sql_cond IS NOT NULL THEN
     LET sql_text = sql_text || " WHERE " || sql_cond --make full query with the where condition
  END IF
  
  LET sql_text = sql_text || " ORDER BY practicaltest.userid"

  DECLARE ca_curs CURSOR FROM sql_text --defining a cursor with the sql query

  --empty the array before you fill it again
    CALL ptestarr.clear()
    CALL ptestatt.clear()

    --takes all of the records on by one into the variable
  FOREACH ca_curs INTO rec.* --for the sql query into account
     LET x = x + 1 --incrementing index of array to store vals of db
     LET ptestarr[x] = rec --stores all user info from the query in the ktestarr
  END FOREACH

  CLOSE ca_curs
  FREE ca_curs

  RETURN ptestarr.getLength() --returns the number of user entries returned by the 

END FUNCTION

PRIVATE FUNCTION ptestarr_display(sql_cond STRING) RETURNS (LIKE practicaltest.userid)
  DEFINE cnt INTEGER,
         x INTEGER

  LET cnt = ptestarr_fill(sql_cond)  --gets a count of the number of rows returned
  IF cnt == 0 THEN
     RETURN 0
  END IF

  LET int_flag = FALSE --unsets the actions so you can do another action
--record1 is the name of the form, double click outside the form to change the name
  DISPLAY ARRAY ptestarr TO record1.* ATTRIBUTES(UNBUFFERED)
  --tranfering ktestarr dynamic array values to the screen array (populating the form)
     BEFORE DISPLAY  
        MESSAGE ""
        CALL DIALOG.setArrayAttributes("record1", ptestatt) --dialog box that appears on screen
        --CALL DIALOG.setSelectionMode("sa_acct", 1)
        --this empties everything and starts it froms scratch so when you hit the next button, it gets refreshed
     BEFORE ROW 
        LET x = DIALOG.getCurrentRow("record1")  
        DISPLAY ptestarr[x].userid, --you can lowk remove this, it is overwriting the display we did earlier
                ptestarr[x].testid,
                ptestarr[x].genero_version,
                ptestarr[x].grade,
                ptestarr[x].date_completed
                
     AFTER DISPLAY
        LET x = DIALOG.getCurrentRow("record1") --just a dialog box
     ON ACTION refresh ATTRIBUTES(TEXT="Refresh",ACCELERATOR="F5")
        LET cnt = ptestarr_fill(sql_cond)

    {need to change this functionality so that it saves the current info being displayed in a screen array }
    ON ACTION select_user ATTRIBUTES (TEXT="Select User") 
        CALL ptestatt.clear()
        
        CALL DIALOG.setArrayAttributes("record1", ptestatt)
        LET x = DIALOG.getCurrentRow("record1")  
        DISPLAY ptestarr[x].userid, --you can lowk remove this, it is overwriting the display we did earlier
                ptestarr[x].testid,
                ptestarr[x].genero_version,
                ptestarr[x].grade,
                ptestarr[x].date_completed
        CALL ptestarr_input()
        EXIT DISPLAY
     {   
    ON ACTION back
        EXIT DISPLAY
        RETURN -1
        }
  END DISPLAY

  IF int_flag THEN
     RETURN -1
  ELSE
     RETURN ptestarr[x].userid
  END IF


END FUNCTION



PRIVATE FUNCTION ptestarr_input() RETURNS ()
  DEFINE x INTEGER
  DEFINE op CHAR(1)
   DEFINE l_count INTEGER
  --DEFINE f ui.Form 

  LET int_flag = FALSE

  INPUT ARRAY ptestarr FROM record1.* --get an input array from the screen array
          ATTRIBUTES(UNBUFFERED, --your form fills and your program vars are filled automatially, auto synch
                     CANCEL = FALSE,
                     WITHOUT DEFAULTS)

     BEFORE DELETE --to delete from the form, delete button
        DISPLAY "BEFORE DELETE: op=",op
        IF op == "N" THEN
           LET x = arr_curr() --pointer in cursor to get the current row
           IF NOT utils.mbox_yn("practicaltest",
                "Are you sure you want to delete this record?") --make sure user wants to delete the reord
           THEN
              CANCEL DELETE
           END IF
           TRY
              DELETE FROM practicaltest
                  WHERE testid = ptestarr[x].testid --delete the record from the order array where the orderid matches what was in the screen array
                  LET record_count =-1
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
        LET ptestarr[x].testid = "pt_"||ptestarr.getLength() --set default values for what you insert
        LET ptestarr[x].userid = "<undefined>"

     AFTER INSERT
        DISPLAY "AFTER INSERT: op=",op
        LET op = "I"

     BEFORE ROW
        DISPLAY "BEFORE ROW: op=",op
        LET op = "N"
        CALL DIALOG.setFieldActive("testid", FALSE)

        --sees if a name is like valid or not, it cant have a number
     AFTER ROW
        DISPLAY "AFTER ROW: op=",op
        IF int_flag THEN EXIT INPUT END IF
        LET x = arr_curr() 
        IF op == "I" THEN
            SELECT COUNT(*) INTO l_count FROM user WHERE ptestarr[x].userid==userid
            IF l_count = 0 
                THEN ERROR "Invalid user ID." 
            ELSE
    
               TRY --insert the orders 
                  INSERT INTO practicaltest VALUES ( ptestarr[x].* )
                  MESSAGE "Record has been inserted successfully"
                  LET record_count =+1
                  EXIT INPUT
               CATCH
                  ERROR SQLERRMESSAGE
                  NEXT FIELD CURRENT
               END TRY
            
            END IF 
        END IF
        
        IF op == "M" THEN
           TRY --update orders
              LET x = arr_curr()
              UPDATE practicaltest SET practicaltest.* = ptestarr[x].*
                  WHERE testid = ptestarr[x].testid
              MESSAGE "Record has been updated successfully"
              EXIT INPUT
           CATCH
              ERROR "Could not update the record in database!"
              NEXT FIELD CURRENT
           END TRY
        END IF

  END INPUT

END FUNCTION

FUNCTION ptest_record_count()
    DEFINE sql_text STRING, 
    x INTEGER, 
    count_test_rec t_ptest_rec

    LET x = 0
    LET sql_text = "SELECT * FROM practicaltest"

    DECLARE count_curs CURSOR FROM sql_text
    
      FOREACH count_curs INTO count_test_rec.* --for the sql query into account
        LET x = x + 1 --incrementing index of array to store vals of db
        --stores all user info from the query in the ktestarr
  END FOREACH

  CLOSE ca_curs
  FREE ca_curs

  RETURN x
    
END FUNCTION

