IMPORT FGL utils

SCHEMA cert_trackerdb_2

PUBLIC TYPE t_ptest_rec RECORD LIKE practicaltest.*
PUBLIC TYPE t_ptest_id LIKE practicaltest.testid

PRIVATE DEFINE mr_ptest_rec t_ptest_rec

PUBLIC FUNCTION ptest_count(current_ptest t_ptest_id) RETURNS INTEGER
    DEFINE cnt INTEGER
    SELECT COUNT(*) INTO cnt FROM practicaltest WHERE testid = current_ptest
    RETURN cnt
END FUNCTION

PRIVATE FUNCTION ptest_name_exists(testid LIKE practicaltest.testid,
    current_ptest_id t_ptest_id)
    RETURNS BOOLEAN

    DEFINE test_id LIKE practicaltest.testid

    SELECT testid
        INTO test_id
        FROM practicaltest
        WHERE testid != current_ptest_id

    RETURN (sqlca.sqlcode == 0)

END FUNCTION

PUBLIC FUNCTION append_ptest_with_id(
    current_ptest t_ptest_id)
    RETURNS t_ptest_id
    RETURN appupd_ptest("B",current_ptest)
END FUNCTION

PUBLIC FUNCTION append_ptest(
    current_ptest t_ptest_id)
    RETURNS t_ptest_id
    RETURN appupd_ptest("A", current_ptest)
END FUNCTION

PUBLIC FUNCTION update_ptest(
    current_ptest t_ptest_id)
    RETURNS t_ptest_id
    RETURN appupd_ptest("U", current_ptest)
END FUNCTION

PRIVATE FUNCTION appupd_ptest(
    au_flag CHAR(1), current_ptest t_ptest_id)
    RETURNS t_ptest_id
   # DEFINE f_zip_postal STRING, f_phone_num LIKE ptest.phone_num

   CASE au_flag
    WHEN "A"
        MESSAGE "Append a new ptest."
        INITIALIZE mr_ptest_rec.* TO NULL
        LET mr_ptest_rec.testid = 0
    WHEN  "B" 
        MESSAGE "Append a new ptest."
        INITIALIZE mr_ptest_rec.* TO NULL
        LET mr_ptest_rec.userid = current_ptest
        LET mr_ptest_rec.testid = 0
    OTHERWISE
        MESSAGE "Update current ptest."
        SELECT *
            INTO mr_ptest_rec.*
            FROM practicaltest
            WHERE testid = current_ptest
        IF sqlca.sqlcode == NOTFOUND THEN
            ERROR "ptest record no longer exists in the database."
            RETURN 0
        END IF
    END CASE

    LET int_flag = FALSE

    INPUT BY NAME mr_ptest_rec.* WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
    BEFORE input
       CALL DIALOG.setFieldActive("testid", 0) 
       IF au_flag == "B" then
       CALL DIALOG.setFieldActive("userid", 0) 
       END IF
    END INPUT
    IF int_flag THEN
        LET int_flag = FALSE
        MESSAGE "Operation cancelled by ptest"
        RETURN current_ptest
    END IF

    IF au_flag == "A" OR au_flag == "B" THEN
        SELECT MAX(testid) + 1 INTO mr_ptest_rec.testid FROM practicaltest
        IF mr_ptest_rec.testid IS NULL THEN
        LET mr_ptest_rec.testid = 1
        END IF 
        DISPLAY BY NAME mr_ptest_rec.testid

        #logic so that if a person fails a scenario, the grade is automatically set to fail and the date is entered
        IF mr_ptest_rec.status == 5 THEN
        LET mr_ptest_rec.status = 0 
            IF mr_ptest_rec.date_completed IS NULL
            THEN 
            LET mr_ptest_rec.date_completed = TODAY
            END IF 
        END IF 
        TRY
            INSERT INTO practicaltest VALUES(mr_ptest_rec.*)
        CATCH
            ERROR SFMT("INSERT failed: %1", SQLERRMESSAGE)
            RETURN 0
        END TRY
        MESSAGE "Row appended"
    ELSE
    IF mr_ptest_rec.status == 5 THEN
        LET mr_ptest_rec.status = 0 
            IF mr_ptest_rec.date_completed IS NULL
            THEN 
            LET mr_ptest_rec.date_completed = TODAY
            END IF 
        END IF 
        TRY
            UPDATE practicaltest
                SET practicaltest.* = mr_ptest_rec.*
                    WHERE practicaltest.testid = mr_ptest_rec.testid
        CATCH
            ERROR SFMT("UPDATE failed: %1", SQLERRMESSAGE)
            RETURN 0
        END TRY
        IF sqlca.sqlerrd[3] == 1 THEN
            MESSAGE "Row updated"
        ELSE
            MESSAGE "Row no longer exists in the database"
        END IF
    END IF

    RETURN 0

END FUNCTION

PUBLIC FUNCTION delete_ptest(current_ptest t_ptest_id) RETURNS t_ptest_id

    IF NOT utils.mbox_yn("ptest", "Delete current ptest record?") THEN
        RETURN current_ptest
    END IF

    TRY
        DELETE FROM ptest WHERE ptestid = current_ptest
    CATCH
        ERROR SFMT("DELETE failed: %1", SQLERRMESSAGE)
        RETURN current_ptest
    END TRY
    IF sqlca.sqlerrd[3] == 1 THEN
        MESSAGE "Row deleted"
    ELSE
        MESSAGE "Row no longer exists in the database"
    END IF

    INITIALIZE mr_ptest_rec.* TO NULL
    DISPLAY BY NAME mr_ptest_rec.*

    RETURN 0

END FUNCTION


PUBLIC FUNCTION certification_complete_test(current_test_id) RETURNS boolean
    DEFINE current_test_id LIKE practicaltest.testid
    DEFINE passed_id LIKE user.userid

    
SELECT user.userid
INTO passed_id 
FROM practicaltest, knowledgetest, user
WHERE practicaltest.testid = current_test_id 
AND practicaltest.userid = knowledgetest.userid
AND practicaltest.grade = 1 
AND knowledgetest.grade >= 75

IF passed_id IS NOT NULL THEN
DISPLAY passed_id
UPDATE user 
    SET fully_certified = 1
    WHERE userid = passed_id
    
MESSAGE "This user is fully certified!"
 RETURN TRUE 
END IF 
RETURN false
END FUNCTION
