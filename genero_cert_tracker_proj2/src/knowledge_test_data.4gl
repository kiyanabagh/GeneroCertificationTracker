IMPORT FGL utils

SCHEMA cert_trackerdb_2

PUBLIC TYPE t_ktest_rec RECORD LIKE knowledgetest.*
PUBLIC TYPE t_ktest_id LIKE knowledgetest.testid

PRIVATE DEFINE mr_ktest_rec t_ktest_rec

PUBLIC FUNCTION ktest_count(current_ktest t_ktest_id) RETURNS INTEGER
    DEFINE cnt INTEGER
    SELECT COUNT(*) INTO cnt FROM knowledgetest WHERE testid = current_ktest
    RETURN cnt
END FUNCTION

PRIVATE FUNCTION ktest_name_exists(testid LIKE knowledgetest.testid,
    current_ktest_id t_ktest_id)
    RETURNS BOOLEAN

    DEFINE test_id LIKE knowledgetest.testid

    SELECT testid
        INTO test_id
        FROM knowledgetest
        WHERE testid != current_ktest_id

    RETURN (sqlca.sqlcode == 0)

END FUNCTION

PUBLIC FUNCTION append_ktest_with_id(
    current_ktest t_ktest_id)
    RETURNS t_ktest_id
    RETURN appupd_ktest("B",current_ktest)
END FUNCTION

PUBLIC FUNCTION append_ktest(
    current_ktest t_ktest_id)
    RETURNS t_ktest_id
    RETURN appupd_ktest("A", current_ktest)
END FUNCTION

PUBLIC FUNCTION update_ktest(
    current_ktest t_ktest_id)
    RETURNS t_ktest_id
    RETURN appupd_ktest("U", current_ktest)
END FUNCTION

PRIVATE FUNCTION appupd_ktest(
    au_flag CHAR(1), current_ktest t_ktest_id)
    RETURNS t_ktest_id
   # DEFINE f_zip_postal STRING, f_phone_num LIKE ktest.phone_num

   CASE au_flag
    WHEN "A"
        MESSAGE "Append a new ktest."
        INITIALIZE mr_ktest_rec.* TO NULL
        LET mr_ktest_rec.testid = 0
    WHEN  "B" 
        MESSAGE "Append a new ktest."
        INITIALIZE mr_ktest_rec.* TO NULL
        LET mr_ktest_rec.userid = current_ktest
        LET mr_ktest_rec.testid = 0
    OTHERWISE
        MESSAGE "Update current ktest."
        SELECT *
            INTO mr_ktest_rec.*
            FROM knowledgetest
            WHERE testid = current_ktest
        IF sqlca.sqlcode == NOTFOUND THEN
            ERROR "ktest record no longer exists in the database."
            RETURN 0
        END IF
    END CASE

    LET int_flag = FALSE

    INPUT BY NAME mr_ktest_rec.* WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
    BEFORE input
       CALL DIALOG.setFieldActive("testid", 0) 
       IF au_flag == "B" then
       CALL DIALOG.setFieldActive("userid", 0) 
       END IF
    END INPUT
    IF int_flag THEN
        LET int_flag = FALSE
        MESSAGE "Operation cancelled by ktest"
        RETURN current_ktest
    END IF

    IF au_flag == "A" OR au_flag == "B" THEN
        SELECT MAX(testid) + 1 INTO mr_ktest_rec.testid FROM knowledgetest
        IF mr_ktest_rec.testid IS NULL THEN
        LET mr_ktest_rec.testid = 1
        END IF 
        DISPLAY BY NAME mr_ktest_rec.testid
        TRY
            INSERT INTO knowledgetest VALUES(mr_ktest_rec.*)
        CATCH
            ERROR SFMT("INSERT failed: %1", SQLERRMESSAGE)
            RETURN 0
        END TRY
        MESSAGE "Row appended"
    ELSE
        TRY
            UPDATE knowledgetest
                SET knowledgetest.* = mr_ktest_rec.*
                    WHERE knowledgetest.testid = mr_ktest_rec.testid
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

PUBLIC FUNCTION delete_ktest(current_ktest t_ktest_id) RETURNS t_ktest_id

    IF NOT utils.mbox_yn("ktest", "Delete current ktest record?") THEN
        RETURN current_ktest
    END IF

    TRY
        DELETE FROM knowledgetest WHERE testid = current_ktest
    CATCH
        ERROR SFMT("DELETE failed: %1", SQLERRMESSAGE)
        RETURN current_ktest
    END TRY
    IF sqlca.sqlerrd[3] == 1 THEN
        MESSAGE "Row deleted"
    ELSE
        MESSAGE "Row no longer exists in the database"
    END IF

    INITIALIZE mr_ktest_rec.* TO NULL
    DISPLAY BY NAME mr_ktest_rec.*

    RETURN 0

END FUNCTION

