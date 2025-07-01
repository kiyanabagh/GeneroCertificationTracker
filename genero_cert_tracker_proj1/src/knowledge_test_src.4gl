IMPORT FGL utils

SCHEMA db_creation_test

    TYPE t_ktest_rec RECORD LIKE knowledgetest.*
    TYPE t_ktestarray DYNAMIC ARRAY OF t_ktest_rec
    DEFINE ktestarr t_ktestarray

DEFINE ktestatt DYNAMIC ARRAY OF RECORD 
    userid LIKE knowledgetest.userid,
    testid LIKE knowledgetest.testid,
    grade LIKE knowledgetest.grade,
    date_completed LIKE knowledgetest.date_completed,
    genero_version LIKE knowledgetest.genero_version
    END RECORD
    

FUNCTION knowledge_test_driver()

  DEFINE sql_cond STRING,
    userid LIKE knowledgetest.userid,
    testid LIKE knowledgetest.testid,
    grade LIKE knowledgetest.grade,
    date_completed LIKE knowledgetest.date_completed,
    genero_version LIKE knowledgetest.genero_version

    
    OPEN WINDOW w3 WITH FORM "knowledge_test_form"
    MENU
    ON ACTION query_ktests
          WHILE TRUE --create a scenario where the search query field can be autopopulated and can be used directly without creating any action button
        --loop only functions when the sql condition has something
            LET sql_cond = testid_query() --call acclist query to get sql condition
            IF sql_cond IS NULL THEN 
               EXIT WHILE
            END IF

            LET testid = ktestarr_display(sql_cond) --
            CASE
            WHEN testid < 0
               EXIT WHILE
            WHEN testid == 0
               MESSAGE "Now rows found!"
            OTHERWISE
               MESSAGE SFMT("ktest #%1 was selected",testid)
            END CASE
        END WHILE

        ON ACTION input_knowledgetest
            
            CALL ktestarr_input()
        ON ACTION QUIT
            EXIT MENU
        
    END MENU

    CLOSE WINDOW w3
END FUNCTION


FUNCTION testid_query() RETURNS STRING
DEFINE sql_cond STRING

  CLEAR FORM 

  LET int_flag = FALSE
  --allows user to query on all fields in the form
  CONSTRUCT BY NAME sql_cond ON knowledgetest.userid, knowledgetest.testid, knowledgetest.grade, knowledgetest.genero_version, knowledgetest.date_completed

  IF int_flag THEN
     RETURN NULL
  ELSE
     RETURN sql_cond 
  END IF

END FUNCTION

PRIVATE FUNCTION ktestarr_fill(sql_cond STRING) RETURNS INTEGER
  DEFINE sql_text STRING,
         rec t_ktest_rec,
         x INTEGER

  LET sql_text = "SELECT * FROM knowledgetest" --creates initial sql query to get all entries in knowledgetest table
  
  IF sql_cond IS NOT NULL THEN
     LET sql_text = sql_text || " WHERE " || sql_cond --make full query with the where condition
  END IF
  
  LET sql_text = sql_text || " ORDER BY knowledgetest.userid"

  DECLARE ca_curs CURSOR FROM sql_text --defining a cursor with the sql query

  --empty the array before you fill it again
    CALL ktestarr.clear()
    CALL ktestatt.clear()

    --takes all of the records on by one into the variable
  FOREACH ca_curs INTO rec.* --for the sql query into account
     LET x = x + 1 --incrementing index of array to store vals of db
     LET ktestarr[x] = rec --stores all user info from the query in the ktestarr
  END FOREACH

  CLOSE ca_curs
  FREE ca_curs

  RETURN ktestarr.getLength() --returns the number of user entries returned by the 

END FUNCTION

PRIVATE FUNCTION ktestarr_display(sql_cond STRING) RETURNS (LIKE knowledgetest.userid)
  DEFINE cnt INTEGER,
         x INTEGER

  LET cnt = ktestarr_fill(sql_cond)  --gets a count of the number of rows returned
  IF cnt == 0 THEN
     RETURN 0
  END IF

  LET int_flag = FALSE --unsets the actions so you can do another action
--record1 is the name of the form, double click outside the form to change the name
  DISPLAY ARRAY ktestarr TO record1.* ATTRIBUTES(UNBUFFERED)
  --tranfering ktestarr dynamic array values to the screen array (populating the form)
     BEFORE DISPLAY  
        MESSAGE ""
        CALL DIALOG.setArrayAttributes("record1", ktestatt) --dialog box that appears on screen
        --CALL DIALOG.setSelectionMode("sa_acct", 1)
        --this empties everything and starts it froms scratch so when you hit the next button, it gets refreshed
     BEFORE ROW 
        LET x = DIALOG.getCurrentRow("record1")  
        DISPLAY ktestarr[x].userid, --you can lowk remove this, it is overwriting the display we did earlier
                ktestarr[x].testid,
                ktestarr[x].genero_version,
                ktestarr[x].grade,
                ktestarr[x].date_completed
                
     AFTER DISPLAY
        LET x = DIALOG.getCurrentRow("record1") --just a dialog box
     ON ACTION refresh ATTRIBUTES(TEXT="Refresh",ACCELERATOR="F5")
        LET cnt = ktestarr_fill(sql_cond)
  END DISPLAY

  IF int_flag THEN
     RETURN -1
  ELSE
     RETURN ktestarr[x].userid
  END IF


END FUNCTION



PRIVATE FUNCTION ktestarr_input() RETURNS ()
  DEFINE x INTEGER
  DEFINE op CHAR(1)
   DEFINE l_count INTEGER
  --DEFINE f ui.Form 

  LET int_flag = FALSE

  INPUT ARRAY ktestarr FROM record1.* --get an input array from the screen array
          ATTRIBUTES(UNBUFFERED, --your form fills and your program vars are filled automatially, auto synch
                     CANCEL = FALSE,
                     WITHOUT DEFAULTS)

     BEFORE DELETE --to delete from the form, delete button
        DISPLAY "BEFORE DELETE: op=",op
        IF op == "N" THEN
           LET x = arr_curr() --pointer in cursor to get the current row
           IF NOT utils.mbox_yn("knowledgetest",
                "Are you sure you want to delete this record?") --make sure user wants to delete the reord
           THEN
              CANCEL DELETE
           END IF
           TRY
              DELETE FROM knowledgetest
                  WHERE testid = ktestarr[x].testid --delete the record from the order array where the orderid matches what was in the screen array
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
        LET ktestarr[x].testid = 100 + arr_curr() --set default values for what you insert
        LET ktestarr[x].userid = "<undefined>"

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
            SELECT COUNT(*) INTO l_count FROM user WHERE ktestarr[x].userid==userid
            IF l_count = 0 
                THEN ERROR "Invalid user ID." 
            ELSE
    
               TRY --insert the orders 
                  INSERT INTO knowledgetest VALUES ( ktestarr[x].* )
                  MESSAGE "Record has been inserted successfully"
               CATCH
                  ERROR SQLERRMESSAGE
                  NEXT FIELD CURRENT
               END TRY
            END IF 
        END IF
        IF op == "M" THEN
           TRY --update orders
              LET x = arr_curr()
              UPDATE knowledgetest SET knowledgetest.* = ktestarr[x].*
                  WHERE testid = ktestarr[x].testid
              MESSAGE "Record has been updated successfully"
           CATCH
              ERROR "Could not update the record in database!"
              NEXT FIELD CURRENT
           END TRY
        END IF

  END INPUT

END FUNCTION

