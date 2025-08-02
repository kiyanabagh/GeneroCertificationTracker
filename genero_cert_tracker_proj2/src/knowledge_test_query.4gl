IMPORT FGL knowledge_test_data


SCHEMA cert_trackerdb_2

PUBLIC DEFINE mr_ktest RECORD LIKE knowledgetest.*

PUBLIC TYPE t_ktest_rec RECORD LIKE knowledgetest.*
PUBLIC TYPE t_ktest_id LIKE knowledgetest.testid

FUNCTION query_ktest() RETURNS BOOLEAN

    DEFINE ktest_count INTEGER
    DEFINE where_clause STRING
    DEFINE can_nav BOOLEAN

    LET int_flag = FALSE

    CONSTRUCT BY NAME where_clause ON knowledgetest.*
    DISPLAY where_clause

    LET can_nav = FALSE

    IF int_flag THEN
        LET int_flag = FALSE
        CLEAR FORM
        MESSAGE "Canceled by ktest."
    ELSE
        LET ktest_count = get_ktest_count(where_clause)
        IF ktest_count > 0 THEN
            MESSAGE SFMT("%1 rows found.", ktest_count)
            IF ktest_select(where_clause) THEN
                CALL display_ktest()
                LET can_nav = TRUE
            END IF
        ELSE
            MESSAGE "No rows found."
        END IF
    END IF

    RETURN can_nav

END FUNCTION

FUNCTION get_ktest_count(p_where_clause STRING) RETURNS INTEGER

    DEFINE sql_text STRING
    DEFINE cust_cnt INTEGER

-- should we have this in a TRY/CATCH or with WHENEVER ERROR?
    WHENEVER ERROR CONTINUE
    LET sql_text = "SELECT COUNT(*) FROM knowledgetest WHERE " || p_where_clause

    PREPARE cust_cnt_stmt FROM sql_text
    EXECUTE cust_cnt_stmt INTO cust_cnt
    FREE cust_cnt_stmt
    DISPLAY cust_cnt
    RETURN cust_cnt

END FUNCTION

FUNCTION ktest_select(p_where_clause STRING) RETURNS BOOLEAN

    DEFINE sql_text STRING
    LET sql_text =
        "SELECT * FROM knowledgetest WHERE "
            || p_where_clause
            || " ORDER BY testid "
    TRY
        DECLARE ktest_cursor SCROLL CURSOR FROM sql_text
        OPEN ktest_cursor
    CATCH
        ERROR "SQL error: ", SQLERRMESSAGE
        RETURN FALSE
    END TRY

    IF NOT fetch_ktest(1) THEN
        MESSAGE "No rows in table."
        RETURN FALSE
    ELSE
        RETURN TRUE
    END IF

END FUNCTION

FUNCTION fetch_ktest(p_fetch_flag SMALLINT) RETURNS BOOLEAN

    CASE p_fetch_flag
        WHEN 0
            FETCH FIRST ktest_cursor INTO mr_ktest.*
        WHEN 1
            FETCH NEXT ktest_cursor INTO mr_ktest.*
        WHEN -1
            FETCH PREVIOUS ktest_cursor INTO mr_ktest.*
        WHEN 2
            FETCH LAST ktest_cursor INTO mr_ktest.*
        WHEN 3
            FETCH CURRENT ktest_cursor INTO mr_ktest.*
    END CASE

    RETURN (sqlca.sqlcode == 0)

END FUNCTION

FUNCTION fetch_rel_ktest(p_fetch_flag SMALLINT) RETURNS knowledge_test_data.t_ktest_id

    MESSAGE " "

    IF fetch_ktest(p_fetch_flag) THEN
        CALL display_ktest()
    ELSE
        IF p_fetch_flag == 1 THEN
            MESSAGE "End of list"
        ELSE
            MESSAGE "Beginning of list"
        END IF
    END IF

    RETURN mr_ktest.testid

END FUNCTION

FUNCTION display_ktest() RETURNS()

    DISPLAY BY NAME mr_ktest.*

END FUNCTION



FUNCTION query_ktest2(user_id) RETURNS BOOLEAN

    DEFINE ktest_count INTEGER
    DEFINE where_clause STRING
    DEFINE can_nav BOOLEAN
    DEFINE user_id LIKE knowledgetest.userid

    LET int_flag = FALSE

    LET where_clause = "knowledgetest.userid = \'" ||user_id|| "\'"
    
    DISPLAY where_clause

    LET can_nav = FALSE

    IF int_flag THEN
        LET int_flag = FALSE
        CLEAR FORM
        MESSAGE "Canceled by ktest."
    ELSE
        LET ktest_count = get_ktest_count(where_clause)
        IF ktest_count > 0 THEN
            MESSAGE SFMT("%1 rows found.", ktest_count)
            IF ktest_select(where_clause) THEN
                CALL display_ktest()
                LET can_nav = TRUE
            END IF
        ELSE
            MESSAGE "No rows found for " ||user_id|| ". Add a knowledgetest"

            
        END IF
    END IF

    RETURN can_nav

END FUNCTION