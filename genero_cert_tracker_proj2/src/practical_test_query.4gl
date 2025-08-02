IMPORT FGL practical_test_data


SCHEMA cert_trackerdb_2

PUBLIC DEFINE mr_ptest RECORD LIKE practicaltest.*

PUBLIC TYPE t_ptest_rec RECORD LIKE practicaltest.*
PUBLIC TYPE t_ptest_id LIKE practicaltest.testid

FUNCTION query_ptest() RETURNS BOOLEAN

    DEFINE ptest_count INTEGER
    DEFINE where_clause STRING
    DEFINE can_nav BOOLEAN

    LET int_flag = FALSE

    CONSTRUCT BY NAME where_clause ON practicaltest.*
    DISPLAY where_clause

    LET can_nav = FALSE

    IF int_flag THEN
        LET int_flag = FALSE
        CLEAR FORM
        MESSAGE "Canceled by ptest."
    ELSE
        LET ptest_count = get_ptest_count(where_clause)
        IF ptest_count > 0 THEN
            MESSAGE SFMT("%1 rows found.", ptest_count)
            IF ptest_select(where_clause) THEN
                CALL display_ptest()
                LET can_nav = TRUE
            END IF
        ELSE
            MESSAGE "No rows found."
        END IF
    END IF

    RETURN can_nav

END FUNCTION

FUNCTION get_ptest_count(p_where_clause STRING) RETURNS INTEGER

    DEFINE sql_text STRING
    DEFINE cust_cnt INTEGER

-- should we have this in a TRY/CATCH or with WHENEVER ERROR?
    WHENEVER ERROR CONTINUE
    LET sql_text = "SELECT COUNT(*) FROM practicaltest WHERE " || p_where_clause

    PREPARE cust_cnt_stmt FROM sql_text
    EXECUTE cust_cnt_stmt INTO cust_cnt
    FREE cust_cnt_stmt
    DISPLAY cust_cnt
    RETURN cust_cnt

END FUNCTION

FUNCTION ptest_select(p_where_clause STRING) RETURNS BOOLEAN

    DEFINE sql_text STRING
    LET sql_text =
        "SELECT * FROM practicaltest WHERE "
            || p_where_clause
            || " ORDER BY testid "
    TRY
        DECLARE ptest_cursor SCROLL CURSOR FROM sql_text
        OPEN ptest_cursor
    CATCH
        ERROR "SQL error: ", SQLERRMESSAGE
        RETURN FALSE
    END TRY

    IF NOT fetch_ptest(1) THEN
        MESSAGE "No rows in table."
        RETURN FALSE
    ELSE
        RETURN TRUE
    END IF

END FUNCTION

FUNCTION fetch_ptest(p_fetch_flag SMALLINT) RETURNS BOOLEAN

    CASE p_fetch_flag
        WHEN 0
            FETCH FIRST ptest_cursor INTO mr_ptest.*
        WHEN 1
            FETCH NEXT ptest_cursor INTO mr_ptest.*
        WHEN -1
            FETCH PREVIOUS ptest_cursor INTO mr_ptest.*
        WHEN 2
            FETCH LAST ptest_cursor INTO mr_ptest.*
        WHEN 3
            FETCH CURRENT ptest_cursor INTO mr_ptest.*
    END CASE

    RETURN (sqlca.sqlcode == 0)

END FUNCTION

FUNCTION fetch_rel_ptest(p_fetch_flag SMALLINT) RETURNS practical_test_data.t_ptest_id

    MESSAGE " "

    IF fetch_ptest(p_fetch_flag) THEN
        CALL display_ptest()
    ELSE
        IF p_fetch_flag == 1 THEN
            MESSAGE "End of list"
        ELSE
            MESSAGE "Beginning of list"
        END IF
    END IF

    RETURN mr_ptest.testid

END FUNCTION

FUNCTION display_ptest() RETURNS()

    DISPLAY BY NAME mr_ptest.*

END FUNCTION



FUNCTION query_ptest2(user_id) RETURNS BOOLEAN

    DEFINE ptest_count INTEGER
    DEFINE where_clause STRING
    DEFINE can_nav BOOLEAN
    DEFINE user_id LIKE practicaltest.userid

    LET int_flag = FALSE

    LET where_clause = "practicaltest.userid = \'" ||user_id|| "\'"
    
    DISPLAY where_clause

    LET can_nav = FALSE

    IF int_flag THEN
        LET int_flag = FALSE
        CLEAR FORM
        MESSAGE "Canceled by ptest."
    ELSE
        LET ptest_count = get_ptest_count(where_clause)
        IF ptest_count > 0 THEN
            MESSAGE SFMT("%1 rows found.", ptest_count)
            IF ptest_select(where_clause) THEN
                CALL display_ptest()
                LET can_nav = TRUE
            END IF
        ELSE
            MESSAGE "No rows found for " ||user_id|| ". Add a practicaltest"

            
        END IF
    END IF

    RETURN can_nav

END FUNCTION