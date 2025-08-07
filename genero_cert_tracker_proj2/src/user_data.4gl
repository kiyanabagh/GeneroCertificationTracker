IMPORT FGL utils
IMPORT FGL knowledge_test_main
IMPORT FGL practical_test_main

SCHEMA cert_trackerdb_2

PUBLIC TYPE t_user_rec RECORD LIKE user.*
PUBLIC TYPE t_user_id LIKE user.userid

PRIVATE DEFINE mr_user_rec t_user_rec

PUBLIC FUNCTION user_count(current_user t_user_id) RETURNS INTEGER
    DEFINE cnt INTEGER
    SELECT COUNT(*) INTO cnt FROM user WHERE userid = current_user
    RETURN cnt
END FUNCTION

PRIVATE FUNCTION user_name_exists(
    current_user_first_name LIKE user.fname,
    current_user_last_name LIKE user.lname,
    current_user_id t_user_id)
    RETURNS BOOLEAN

    DEFINE first_name LIKE user.fname
    DEFINE last_name LIKE user.lname

    SELECT fname, lname
        INTO first_name, last_name
        FROM user
        WHERE fname = current_user_first_name
            AND lname = current_user_last_name
            AND userid != current_user_id

    RETURN (sqlca.sqlcode == 0)

END FUNCTION

PUBLIC FUNCTION append_user(
    current_user t_user_id)
    RETURNS t_user_id
    RETURN appupd_user("A", current_user)
END FUNCTION

PUBLIC FUNCTION update_user(
    current_user t_user_id)
    RETURNS t_user_id
    RETURN appupd_user("U", current_user)
END FUNCTION

PRIVATE FUNCTION appupd_user(
    au_flag CHAR(1), current_user t_user_id)
    RETURNS t_user_id


    IF au_flag == "A" THEN
        MESSAGE "Append a new user."
        INITIALIZE mr_user_rec.* TO NULL
        LET mr_user_rec.userid = 0
    ELSE
        MESSAGE "Update current user."
        SELECT *
            INTO mr_user_rec.*
            FROM user
            WHERE userid = current_user
        IF sqlca.sqlcode == NOTFOUND THEN
            ERROR "user record no longer exists in the database."
            RETURN 0
        END IF
    END IF

    LET int_flag = FALSE

    INPUT BY NAME mr_user_rec.* WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
    BEFORE input
       CALL DIALOG.setFieldActive("userid", 0) 
    END INPUT

    IF int_flag THEN
        LET int_flag = FALSE
        MESSAGE "Operation cancelled by user"
        RETURN current_user
    END IF

    IF au_flag == "A" THEN
        SELECT MAX(userid) + 1 INTO mr_user_rec.userid FROM USER
        IF mr_user_rec.userid IS NULL THEN
            LET mr_user_rec.userid = 1
        END IF
        IF mr_user_rec.payment_recieved IS NULL THEN
           LET  mr_user_rec.payment_recieved = 0
        END if
        DISPLAY BY NAME mr_user_rec.userid
        IF mr_user_rec.payment_recieved IS NULL THEN
           LET  mr_user_rec.payment_recieved = 0
        END IF
        
        TRY
            INSERT INTO user VALUES(mr_user_rec.*)
        CATCH
            ERROR SFMT("INSERT failed: %1", SQLERRMESSAGE)
            RETURN 0
        END TRY
        MESSAGE "Row appended"
    ELSE
        TRY
            UPDATE USER
                SET user.* = mr_user_rec.*
                    WHERE user.userid = mr_user_rec.userid
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

PUBLIC FUNCTION delete_user(current_user t_user_id) RETURNS t_user_id

    IF NOT utils.mbox_yn("user", "Delete current user record?") THEN
        RETURN current_user
    END IF

    TRY
        DELETE FROM user WHERE userid = current_user
    CATCH
        ERROR SFMT("DELETE failed: %1", SQLERRMESSAGE)
        RETURN current_user
    END TRY
    IF sqlca.sqlerrd[3] == 1 THEN
        MESSAGE "Row deleted"
    ELSE
        MESSAGE "Row no longer exists in the database"
    END IF

    INITIALIZE mr_user_rec.* TO NULL
    DISPLAY BY NAME mr_user_rec.*

    RETURN 0

END FUNCTION

Public FUNCTION view_knowledge_tests(current_user t_user_id) RETURNS t_user_id

    CALL knowledge_test_main.ktest_form_driver_forid(current_user)
RETURN current_user
END FUNCTION

Public FUNCTION view_practical_tests(current_user t_user_id) RETURNS t_user_id

    CALL practical_test_main.ptest_form_driver_forid(current_user)
RETURN current_user
END FUNCTION

PUBLIC FUNCTION check_is_certified(current_user t_user_id) RETURNS BOOLEAN 
DEFINE counts INTEGER 

SELECT COUNT(*)
INTO counts 
FROM practicaltest, knowledgetest, user
WHERE practicaltest.userid = current_user
AND knowledgetest.userid = current_user
AND knowledgetest.userid = practicaltest.userid 
AND knowledgetest.grade >= 75
AND practicaltest.grade = 1
AND user.userid = current_user
AND user.fully_certified != 1

IF counts > 0 THEN 
        TRY
            UPDATE USER
                SET fully_certified = 1
                    WHERE userid = current_user
        CATCH
            ERROR SFMT("UPDATE failed: %1", SQLERRMESSAGE)
            RETURN 0
        END TRY
END IF 

        IF sqlca.sqlerrd[3] == 1 THEN
            DISPLAY "user: "||current_user|| "is fully certified"
           RETURN True
        ELSE
            RETURN False
        END IF

END FUNCTION 

