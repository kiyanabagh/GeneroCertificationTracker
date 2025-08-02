IMPORT FGL user_data

SCHEMA cert_trackerdb_2

PUBLIC DEFINE mr_user RECORD LIKE user.*

PUBLIC TYPE t_user_rec RECORD LIKE user.*
PUBLIC TYPE t_user_id LIKE user.userid

FUNCTION query_user() RETURNS BOOLEAN

    DEFINE user_count INTEGER
    DEFINE where_clause STRING
    DEFINE can_nav BOOLEAN

    LET int_flag = FALSE

    CONSTRUCT BY NAME where_clause ON user.*

    LET can_nav = FALSE

    IF int_flag THEN
        LET int_flag = FALSE
        CLEAR FORM
        MESSAGE "Canceled by user."
    ELSE
        LET user_count = get_user_count(where_clause)
        IF user_count > 0 THEN
            MESSAGE SFMT("%1 rows found.", user_count)
            IF user_select(where_clause) THEN
                CALL display_user()
                LET can_nav = TRUE
            END IF
        ELSE
            MESSAGE "No rows found."
        END IF
    END IF

    RETURN can_nav

END FUNCTION

FUNCTION get_user_count(p_where_clause STRING) RETURNS INTEGER

    DEFINE sql_text STRING
    DEFINE cust_cnt INTEGER

-- should we have this in a TRY/CATCH or with WHENEVER ERROR?
    LET sql_text = "SELECT COUNT(*) FROM user WHERE " || p_where_clause
    PREPARE cust_cnt_stmt FROM sql_text
    EXECUTE cust_cnt_stmt INTO cust_cnt
    FREE cust_cnt_stmt
    RETURN cust_cnt

END FUNCTION

FUNCTION user_select(p_where_clause STRING) RETURNS BOOLEAN

    DEFINE sql_text STRING
    LET sql_text =
        "SELECT * FROM user WHERE "
            || p_where_clause
            || " ORDER BY userid "
    TRY
        DECLARE user_cursor SCROLL CURSOR FROM sql_text
        OPEN user_cursor
    CATCH
        ERROR "SQL error: ", SQLERRMESSAGE
        RETURN FALSE
    END TRY

    IF NOT fetch_user(1) THEN
        MESSAGE "No rows in table."
        RETURN FALSE
    ELSE
        RETURN TRUE
    END IF

END FUNCTION

FUNCTION fetch_user(p_fetch_flag SMALLINT) RETURNS BOOLEAN

    CASE p_fetch_flag
        WHEN 0
            FETCH FIRST user_cursor INTO mr_user.*
        WHEN 1
            FETCH NEXT user_cursor INTO mr_user.*
        WHEN -1
            FETCH PREVIOUS user_cursor INTO mr_user.*
        WHEN 2
            FETCH LAST user_cursor INTO mr_user.*
        WHEN 3
            FETCH CURRENT user_cursor INTO mr_user.*
    END CASE

    RETURN (sqlca.sqlcode == 0)

END FUNCTION

FUNCTION fetch_rel_user(p_fetch_flag SMALLINT) RETURNS user_data.t_user_id

    MESSAGE " "

    IF fetch_user(p_fetch_flag) THEN
        CALL display_user()
    ELSE
        IF p_fetch_flag == 1 THEN
            MESSAGE "End of list"
        ELSE
            MESSAGE "Beginning of list"
        END IF
    END IF

    RETURN mr_user.userid

END FUNCTION

FUNCTION display_user() RETURNS()

    DISPLAY BY NAME mr_user.*

END FUNCTION