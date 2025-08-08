IMPORT FGL user_main
IMPORT FGL knowledge_test_main
IMPORT FGL practical_test_main

--executable file

MAIN
DATABASE certtracker --connect to db

--uncomment commands below to clear and rebuild bd
{
CALL db_drop_tables()
CALL db_create_tables()
}
-- open main menu form 

OPEN WINDOW w1 WITH FORM "main_menu_form"
MENU 
    ON ACTION QUIT
        EXIT PROGRAM
    ON ACTION input_user
        CALL user_main.user_form_driver()
    ON ACTION edit_knowledge_test
        CALL knowledge_test_main.ktest_form_driver()        
    ON ACTION edit_practical_test
        CALL practical_test_main.ptest_form_driver()
    ON ACTION print_counts_report
        CALL print_counts_report()
    ON ACTION print_ranking_report
        CALL print_ranking_report()
    ON ACTION print_in_progress_report
        CALL print_in_progress_report()
    ON ACTION print_general_report
        CALL print_general_report()
    ON ACTION print_grouped_report
        CALL print_grouped_report()
    ON ACTION print_open_to_work_report
        CALL print_open_to_work_report()
    ON ACTION print_individual_report
        CALL print_individual_report()
    ON ACTION print_passed_knowledge_test
        CALL print_passed_knowledge_test_report()
    ON ACTION print_fully_certified
        CALL print_fully_certified_report()
    ON ACTION lookup_userid
        CALL print_lookup_userid_report()


END MENU
CLOSE WINDOW w1

END MAIN


FUNCTION db_create_tables()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "CREATE TABLE User (
        userid BIGINT NOT NULL,
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100) NOT NULL,
        secondary_email VARCHAR(100),
        phone_num VARCHAR(11),
        company VARCHAR(100),
        contact_date DATE NOT NULL,
        reason_for_cert BIGINT,
        seeking_employment BOOLEAN,
        fully_certified BOOLEAN,
        payment_recieved BOOLEAN,
        test_url varchar(100),
        lockout_date DATE,
        CONSTRAINT PK_User_1 PRIMARY KEY(userid))"
    EXECUTE IMMEDIATE "CREATE TABLE PracticalTest (
        userid BIGINT NOT NULL,
        testid BIGINT NOT NULL,
        grade BOOLEAN,
        status BIGINT NOT NULL,
        scenario BIGINT NOT NULL,
        date_started DATE NOT NULL,
        date_completed DATE,
        comment VARCHAR(300),
        genero_version VARCHAR(50) NOT NULL,
        CONSTRAINT PK_PracticalTest_1 PRIMARY KEY(testid),
        CONSTRAINT FK_PracticalTest_User_1 FOREIGN KEY(userid)
            REFERENCES User(userid))"
    EXECUTE IMMEDIATE "CREATE TABLE Certification (
        userid VARCHAR(30) NOT NULL,
        certid VARCHAR(30) NOT NULL,
        date DATE NOT NULL,
        CONSTRAINT PK_Certification_1 PRIMARY KEY(certid),
        CONSTRAINT FK_Certification_User_1 FOREIGN KEY(userid)
            REFERENCES User(userid))"
    EXECUTE IMMEDIATE "CREATE TABLE KnowledgeTest (
        userid BIGINT NOT NULL,
        testid BIGINT NOT NULL,
        grade BIGINT,
        date_completed DATE,
        genero_version VARCHAR(50),
        CONSTRAINT PK_KnowledgeTest_1 PRIMARY KEY(testid),
        CONSTRAINT FK_KnowledgeTest_User_1 FOREIGN KEY(userid)
            REFERENCES User(userid))"

END FUNCTION

#+ Drop all tables from database.
FUNCTION db_drop_tables()
    WHENEVER ERROR CONTINUE

    EXECUTE IMMEDIATE "DROP TABLE User"
    EXECUTE IMMEDIATE "DROP TABLE PracticalTest"
    EXECUTE IMMEDIATE "DROP TABLE Certification"
    EXECUTE IMMEDIATE "DROP TABLE KnowledgeTest"

END FUNCTION


FUNCTION print_counts_report()
    DEFINE rec_count RECORD
        section CHAR(20),
        group_value VARCHAR(100),
        passed_kt INTEGER,
        failed_kt INTEGER,
        passed_pt INTEGER,
        failed_pt INTEGER
    END RECORD

    DECLARE count_cur CURSOR FOR
        -- Group by Company
        SELECT 'COMPANY' AS section, company AS group_value,
            SUM(CASE WHEN kt.grade = TRUE THEN 1 ELSE 0 END) AS passed_kt,
            SUM(CASE WHEN kt.grade = FALSE THEN 1 ELSE 0 END) AS failed_kt,
            SUM(CASE WHEN pt.grade = TRUE THEN 1 ELSE 0 END) AS passed_pt,
            SUM(CASE WHEN pt.grade = FALSE THEN 1 ELSE 0 END) AS failed_pt
        FROM User u
            LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid
            LEFT JOIN PracticalTest pt ON u.userid = pt.userid
        GROUP BY company

        UNION ALL

        -- Group by Open To Work (seeking_employment)
        SELECT 'OTW' AS section,
            (CASE WHEN u.seeking_employment THEN 'Yes' ELSE 'No' END) AS group_value,
            SUM(CASE WHEN kt.grade = TRUE THEN 1 ELSE 0 END) AS passed_kt,
            SUM(CASE WHEN kt.grade = FALSE THEN 1 ELSE 0 END) AS failed_kt,
            SUM(CASE WHEN pt.grade = TRUE THEN 1 ELSE 0 END) AS passed_pt,
            SUM(CASE WHEN pt.grade = FALSE THEN 1 ELSE 0 END) AS failed_pt
        FROM User u
            LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid
            LEFT JOIN PracticalTest pt ON u.userid = pt.userid
        GROUP BY u.seeking_employment

        UNION ALL

        -- Group by Reason for Cert
        SELECT 'REASON' AS section, CAST(u.reason_for_cert AS CHAR(20)) AS group_value,
            SUM(CASE WHEN kt.grade = TRUE THEN 1 ELSE 0 END) AS passed_kt,
            SUM(CASE WHEN kt.grade = FALSE THEN 1 ELSE 0 END) AS failed_kt,
            SUM(CASE WHEN pt.grade = TRUE THEN 1 ELSE 0 END) AS passed_pt,
            SUM(CASE WHEN pt.grade = FALSE THEN 1 ELSE 0 END) AS failed_pt
        FROM User u
            LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid
            LEFT JOIN PracticalTest pt ON u.userid = pt.userid
        GROUP BY u.reason_for_cert

        ORDER BY section, group_value
    ;

    START REPORT counts_report
    OPEN count_cur
    WHILE TRUE
        FETCH count_cur INTO rec_count.*
        IF SQLCA.SQLCODE <> 0 THEN
            EXIT WHILE
        END IF
        OUTPUT TO REPORT counts_report(rec_count.*)
    END WHILE
    CLOSE count_cur
    FINISH REPORT counts_report
END FUNCTION

FUNCTION print_ranking_report()
    DEFINE rec_rank RECORD
        score INTEGER,
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        company VARCHAR(100),
        seeking_employment BOOLEAN
    END RECORD

    DEFINE rank INTEGER

    -- Declare cursor, without ROW_NUMBER()
    DECLARE c_rank CURSOR FOR
        SELECT
            COALESCE(kt.grade, 0) + COALESCE(pt.grade, 0) AS score,
            u.fname, u.lname, u.primary_email, u.company, u.seeking_employment
        FROM User u
        LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid
        LEFT JOIN PracticalTest pt ON u.userid = pt.userid
        ORDER BY score DESC, u.lname, u.fname
    ;

    LET rank = 1

    START REPORT ranking_report
    FOREACH c_rank INTO rec_rank.*
        OUTPUT TO REPORT ranking_report(rank, rec_rank.*)
        LET rank = rank + 1
    END FOREACH
    FINISH REPORT ranking_report
END FUNCTION

FUNCTION print_in_progress_report()
    DEFINE rec_progress RECORD
        status BIGINT,
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        company VARCHAR(100),
        testid VARCHAR(20),
        scenario BIGINT,
        date_started DATE,
        date_completed DATE
    END RECORD

    -- You might want to order by status first for grouping
    DECLARE c_progress CURSOR FOR
        SELECT
            pt.status,
            u.fname, u.lname, u.primary_email, u.company,
            pt.testid, pt.scenario, pt.date_started, pt.date_completed
        FROM PracticalTest pt
        LEFT JOIN User u ON pt.userid = u.userid
        ORDER BY pt.status, u.lname, u.fname
    ;

    START REPORT in_progress_report
    FOREACH c_progress INTO rec_progress.*
        OUTPUT TO REPORT in_progress_report(rec_progress.*)
    END FOREACH
    FINISH REPORT in_progress_report
END FUNCTION

FUNCTION print_general_report()
    DEFINE rec_user RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        secondary_email VARCHAR(100),
        phone_num VARCHAR(11),
        company VARCHAR(100),
        contact_date DATE,
        reason_for_cert BIGINT,
        seeking_employment BOOLEAN
    END RECORD

    DEFINE rec_ktest RECORD
        testid VARCHAR(20),
        grade BOOLEAN,
        date_completed DATE,
        genero_version VARCHAR(50)
    END RECORD

    DEFINE rec_ptest RECORD
        testid VARCHAR(20),
        grade BOOLEAN,
        status BIGINT,
        scenario BIGINT,
        date_started DATE,
        date_completed DATE,
        comment VARCHAR(300),
        genero_version VARCHAR(50)
    END RECORD

    DECLARE c_user CURSOR FOR
        SELECT
            userid, fname, lname, primary_email, secondary_email,
            phone_num, company, contact_date, reason_for_cert, seeking_employment
        FROM User
        ORDER BY lname, fname

    START REPORT general_report
    FOREACH c_user INTO rec_user.*
        OUTPUT TO REPORT general_report(rec_user.*)
    END FOREACH
    FINISH REPORT general_report
END FUNCTION

FUNCTION print_grouped_report()
    DEFINE group_choice INTEGER
    DEFINE sql_stmt STRING
    DEFINE rec_group RECORD
        group_val CHAR(100),
        fname VARCHAR(50),
        lname VARCHAR(50),
        score INTEGER,
        primary_email VARCHAR(100)
    END RECORD

     LET group_choice = 0

    MENU "How do you want to group the report?"
        COMMAND "Company"
            LET group_choice = 1
            EXIT MENU
        COMMAND "Seeking Employment"
            LET group_choice = 2
            EXIT MENU
        COMMAND "Reason for Cert"
            LET group_choice = 3
            EXIT MENU
        COMMAND "Cancel"
            LET group_choice = 0
            EXIT MENU
    END MENU

    IF group_choice = 1 THEN
        LET sql_stmt =
            "SELECT u.company AS group_val, u.fname, u.lname, " ||
            "COALESCE(kt.grade,0) + COALESCE(pt.grade,0) AS score, u.primary_email " ||
            "FROM User u " ||
            "LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid " ||
            "LEFT JOIN PracticalTest pt ON u.userid = pt.userid " ||
            "ORDER BY u.company, u.lname, u.fname"
    ELSE
        IF group_choice = 2 THEN
            LET sql_stmt =
                "SELECT CASE WHEN u.seeking_employment THEN 'Yes' ELSE 'No' END AS group_val, " ||
                "u.fname, u.lname, COALESCE(kt.grade,0) + COALESCE(pt.grade,0) AS score, u.primary_email " ||
                "FROM User u " ||
                "LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid " ||
                "LEFT JOIN PracticalTest pt ON u.userid = pt.userid " ||
                "ORDER BY group_val DESC, u.lname, u.fname"
        ELSE
            IF group_choice = 3 THEN
                LET sql_stmt =
                    "SELECT CAST(u.reason_for_cert AS CHAR(30)) AS group_val, " ||
                    "u.fname, u.lname, COALESCE(kt.grade,0) + COALESCE(pt.grade,0) AS score, u.primary_email " ||
                    "FROM User u " ||
                    "LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid " ||
                    "LEFT JOIN PracticalTest pt ON u.userid = pt.userid " ||
                    "ORDER BY group_val, u.lname, u.fname"
            ELSE
                DISPLAY "Invalid choice. Defaulting to Company."
                LET sql_stmt =
                    "SELECT u.company AS group_val, u.fname, u.lname, " ||
                    "COALESCE(kt.grade,0) + COALESCE(pt.grade,0) AS score, u.primary_email " ||
                    "FROM User u " ||
                    "LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid " ||
                    "LEFT JOIN PracticalTest pt ON u.userid = pt.userid " ||
                    "ORDER BY u.company, u.lname, u.fname"
            END IF
        END IF
    END IF

    START REPORT grouped_report

    PREPARE s FROM sql_stmt
    DECLARE group_cur CURSOR FOR s

    OPEN group_cur
    WHILE TRUE
        FETCH group_cur INTO rec_group.*
        IF SQLCA.SQLCODE <> 0 THEN
            EXIT WHILE
        END IF
        OUTPUT TO REPORT grouped_report(rec_group.*)
    END WHILE
    CLOSE group_cur

    FINISH REPORT grouped_report
END FUNCTION

FUNCTION print_open_to_work_report()
    DEFINE rec_otw RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        company VARCHAR(100),
        contact_date DATE
    END RECORD

    DECLARE otw_cur CURSOR FOR
        SELECT userid, fname, lname, primary_email, company, contact_date
          FROM User
         WHERE seeking_employment = 1
         ORDER BY lname, fname

    START REPORT open_to_work_report
    OPEN otw_cur
    WHILE TRUE
        FETCH otw_cur INTO rec_otw.*
        IF SQLCA.SQLCODE <> 0 THEN
            EXIT WHILE
        END IF
        OUTPUT TO REPORT open_to_work_report(rec_otw.*)
    END WHILE
    CLOSE otw_cur
    FINISH REPORT open_to_work_report
END FUNCTION

FUNCTION print_passed_knowledge_test_report()
    DEFINE rec_passed RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        grade BIGINT,
        date_completed DATE
    END RECORD

    DECLARE cur CURSOR FOR
        SELECT u.userid, u.fname, u.lname, u.primary_email, k.grade, k.date_completed
          FROM User u, KnowledgeTest k
         WHERE u.userid = k.userid
           AND k.grade >= 75
         ORDER BY u.lname, u.fname

    START REPORT passed_knowledge_report
    OPEN cur
    WHILE TRUE
        FETCH cur INTO rec_passed.*
        IF SQLCA.SQLCODE <> 0 THEN
            EXIT WHILE
        END IF
        OUTPUT TO REPORT passed_knowledge_report(rec_passed.*)
    END WHILE
    CLOSE cur
    FINISH REPORT passed_knowledge_report
END FUNCTION

FUNCTION print_fully_certified_report()
    DEFINE rec_full RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        k_grade BIGINT,
        k_date DATE,
        p_grade BOOLEAN,
        p_date DATE
    END RECORD

    DECLARE cur_full CURSOR FOR
        SELECT u.userid, u.fname, u.lname, u.primary_email, 
               k.grade, k.date_completed, p.grade, p.date_completed
          FROM User u, KnowledgeTest k, PracticalTest p
         WHERE u.userid = k.userid
           AND u.userid = p.userid
           AND k.grade >= 75
           AND p.grade = TRUE
         ORDER BY u.lname, u.fname

    START REPORT fully_certified_report
    OPEN cur_full
    WHILE TRUE
        FETCH cur_full INTO rec_full.*
        IF SQLCA.SQLCODE <> 0 THEN
            EXIT WHILE
        END IF
        OUTPUT TO REPORT fully_certified_report(rec_full.*)
    END WHILE
    CLOSE cur_full
    FINISH REPORT fully_certified_report
END FUNCTION

FUNCTION print_individual_report()
    DEFINE p_userid VARCHAR(30)
    DEFINE seeking_txt CHAR(3)
    DEFINE rec RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        secondary_email VARCHAR(100),
        phone_num VARCHAR(11),
        company VARCHAR(100),
        contact_date DATE,
        reason_for_cert BIGINT,
        seeking_employment BOOLEAN,
        k_testid VARCHAR(20),
        k_grade BOOLEAN,
        k_date_completed DATE,
        k_genero_version VARCHAR(50),
        p_testid VARCHAR(20),
        p_grade BOOLEAN,
        p_status BIGINT,
        p_scenario BIGINT,
        p_date_started DATE,
        p_date_completed DATE,
        p_comment VARCHAR(300),
        p_genero_version VARCHAR(50),
        certid VARCHAR(30),
        cert_date DATE
    END RECORD
    
    DISPLAY "Enter the User ID of the person you want to report on:"
    PROMPT "User ID: " FOR p_userid

    DECLARE all_info_cur CURSOR FOR
        SELECT
            u.userid, u.fname, u.lname, u.primary_email, u.secondary_email, u.phone_num,
            u.company, u.contact_date, u.reason_for_cert, u.seeking_employment,
            k.testid, k.grade, k.date_completed, k.genero_version,
            p.testid, p.grade, p.status, p.scenario, p.date_started, p.date_completed, p.comment, p.genero_version,
            c.certid, c.date
        FROM User u
        LEFT JOIN KnowledgeTest k ON u.userid = k.userid
        LEFT JOIN PracticalTest p ON u.userid = p.userid
        LEFT JOIN Certification c ON u.userid = c.userid
        WHERE u.userid = p_userid
        ORDER BY k.date_completed, p.date_completed, c.date

    START REPORT individual_report
    OPEN all_info_cur
    WHILE TRUE
        FETCH all_info_cur INTO rec.*
        IF SQLCA.SQLCODE <> 0 THEN
            EXIT WHILE
        END IF
        OUTPUT TO REPORT individual_report(rec.*)
    END WHILE
    CLOSE all_info_cur
    FINISH REPORT individual_report
END FUNCTION

FUNCTION print_lookup_userid_report()
    DEFINE search_fname VARCHAR(50)
    DEFINE search_lname VARCHAR(50)
    DEFINE rec_user RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100)
    END RECORD

    PROMPT "Enter first name: " FOR search_fname
    PROMPT "Enter last name: " FOR search_lname

    LET search_fname = search_fname CLIPPED
    LET search_lname = search_lname CLIPPED

    -- One cursor, universal filter
    DECLARE lookup_cur CURSOR FOR
        SELECT userid, fname, lname, primary_email
          FROM User
         WHERE (UPPER(fname) = UPPER(search_fname) OR search_fname = '')
           AND (UPPER(lname) = UPPER(search_lname) OR search_lname = '')
         ORDER BY lname, fname

    START REPORT lookup_userid_report
    OPEN lookup_cur
    WHILE TRUE
        FETCH lookup_cur INTO rec_user.*
        IF SQLCA.SQLCODE <> 0 THEN
            EXIT WHILE
        END IF
        OUTPUT TO REPORT lookup_userid_report(rec_user.*)
    END WHILE
    CLOSE lookup_cur
    FINISH REPORT lookup_userid_report
END FUNCTION


-- ********************REPORT BLOCKS********************
REPORT counts_report(rec_count)
    DEFINE rec_count RECORD
        section CHAR(20),
        group_value VARCHAR(100),
        passed_kt INTEGER,
        failed_kt INTEGER,
        passed_pt INTEGER,
        failed_pt INTEGER
    END RECORD

    DEFINE last_section CHAR(20)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Certification Counts Report"
            SKIP 1 LINE
            PRINT COLUMN 2, "Group",
                  COLUMN 25, "Passed(KT)",
                  COLUMN 38, "Failed(KT)",
                  COLUMN 51, "Passed(PT)",
                  COLUMN 64, "Failed(PT)"
            SKIP 1 LINE

        ON EVERY ROW
            IF last_section IS NULL OR rec_count.section <> last_section THEN
                SKIP 1 LINE
                PRINT "=== ", rec_count.section, " ==="
                LET last_section = rec_count.section
            END IF

            PRINT COLUMN 2, rec_count.group_value CLIPPED,
                  COLUMN 25, rec_count.passed_kt USING "###",
                  COLUMN 38, rec_count.failed_kt USING "###",
                  COLUMN 51, rec_count.passed_pt USING "###",
                  COLUMN 64, rec_count.failed_pt USING "###"
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Counts Report ---"
            SKIP 2 LINES

END REPORT



REPORT ranking_report(rec_rank)
    DEFINE rec_rank RECORD
        rank INTEGER,
        score INTEGER,
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        company VARCHAR(100),
        seeking_employment BOOLEAN
    END RECORD

    DEFINE open_to_work CHAR(3)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Ranking Report"
            SKIP 1 LINE
            PRINT COLUMN 2, "Rank",
                  COLUMN 15, "Score ",
                  COLUMN 23, "Name ",
                  COLUMN 40, "Primary Email",
                  COLUMN 58, "Company ",
                  COLUMN 75, "Open to work"
            SKIP 2 LINES

        ON EVERY ROW
            IF rec_rank.seeking_employment THEN
                LET open_to_work = "Yes"
            ELSE
                LET open_to_work = "No"
            END IF

            PRINT COLUMN 2, rec_rank.rank USING "###", 
                  COLUMN 15, rec_rank.score USING "###", 
                  COLUMN 23, rec_rank.lname CLIPPED, ", ", rec_rank.fname CLIPPED,
                  COLUMN 40, rec_rank.primary_email CLIPPED,
                  COLUMN 58, rec_rank.company CLIPPED,
                  COLUMN 75, open_to_work
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Ranking Report ---"
            SKIP 2 LINES

END REPORT

REPORT in_progress_report (rec_progress)
    DEFINE rec_progress RECORD
        status BIGINT,
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        company VARCHAR(100),
        testid VARCHAR(20),
        scenario BIGINT,
        date_started DATE,
        date_completed DATE
    END RECORD

    DEFINE status_desc CHAR(24)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "InProgress Practical Tests"
            SKIP 1 LINE
            PRINT COLUMN 2,  "Status",
                  COLUMN 44, "Name",
                  COLUMN 70, "Email",
                  COLUMN 112, "Company",
                  COLUMN 134,"TestID",
                  COLUMN 144,"Scen",
                  COLUMN 152,"Start Date",
                  COLUMN 167,"End Date"
            SKIP 1 LINE

        ON EVERY ROW
            CASE
                WHEN rec_progress.status = 1 LET status_desc = "Scenario sent"
                WHEN rec_progress.status = 2 LET status_desc = "Submitted for grading"
                WHEN rec_progress.status = 3 LET status_desc = "Grading in progress"
                WHEN rec_progress.status = 4 LET status_desc = "Grading complete - passed"
                WHEN rec_progress.status = 5 LET status_desc = "Grading complete - failed"
                OTHERWISE                    LET status_desc = "Unknown"
            END CASE

            PRINT COLUMN 2,  status_desc,
                  COLUMN 44, rec_progress.lname CLIPPED, ", ", rec_progress.fname CLIPPED,
                  COLUMN 70, rec_progress.primary_email CLIPPED,
                  COLUMN 112, rec_progress.company CLIPPED,
                  COLUMN 134, rec_progress.testid CLIPPED,
                  COLUMN 144, rec_progress.scenario USING "###",
                  COLUMN 152, rec_progress.date_started USING "yyyy-mm-dd",
                  COLUMN 167, rec_progress.date_completed USING "yyyy-mm-dd"
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 1 LINE
            PRINT "--- End of InProgress Report ---"
            SKIP 1 LINE
END REPORT



REPORT general_report(rec_user)
    DEFINE rec_user RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        secondary_email VARCHAR(100),
        phone_num VARCHAR(11),
        company VARCHAR(100),
        contact_date DATE,
        reason_for_cert BIGINT,
        seeking_employment BOOLEAN
    END RECORD

    DEFINE rec_ktest RECORD
        testid VARCHAR(20),
        grade BOOLEAN,
        date_completed DATE,
        genero_version VARCHAR(50)
    END RECORD

    DEFINE rec_ptest RECORD
        testid VARCHAR(20),
        grade BOOLEAN,
        status BIGINT,
        scenario BIGINT,
        date_started DATE,
        date_completed DATE,
        comment VARCHAR(300),
        genero_version VARCHAR(50)
    END RECORD

    DEFINE open_to_work CHAR(5)
    DEFINE ktest_grade_txt CHAR(5)
    DEFINE ptest_grade_txt CHAR(5)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "General User Report (All Info)"
            SKIP 1 LINE

        ON EVERY ROW
            IF rec_user.seeking_employment THEN
                LET open_to_work = "Yes"
            ELSE
                LET open_to_work = "No"
            END IF

            PRINT "--------------------------------------------------------"
            PRINT "Name: ", rec_user.fname CLIPPED, " ", rec_user.lname CLIPPED
            PRINT "User ID: ", rec_user.userid
            PRINT "Primary Email: ", rec_user.primary_email
            PRINT "Secondary Email: ", rec_user.secondary_email
            PRINT "Phone: ", rec_user.phone_num
            PRINT "Company: ", rec_user.company
            PRINT "Contact Date: ", rec_user.contact_date
            PRINT "Reason for Cert: ", rec_user.reason_for_cert
            PRINT "Seeking Employment: ", open_to_work
            PRINT " "
            PRINT "Knowledge Tests:"
            -- Print all knowledge tests for this user
            DECLARE kcur CURSOR FOR
                SELECT testid, grade, date_completed, genero_version
                FROM KnowledgeTest
                WHERE userid = rec_user.userid
            OPEN kcur
            WHILE TRUE
                FETCH kcur INTO rec_ktest.*
                IF SQLCA.SQLCODE <> 0 THEN
                    EXIT WHILE
                END IF
                IF rec_ktest.grade THEN
                    LET ktest_grade_txt = "Pass"
                ELSE
                    LET ktest_grade_txt = "Fail"
                END IF
                PRINT "  TestID: ", rec_ktest.testid,
                      "  Grade: ", ktest_grade_txt,
                      "  Date: ", rec_ktest.date_completed,
                      "  Version: ", rec_ktest.genero_version
            END WHILE
            CLOSE kcur

            PRINT "Practical Tests:"
            -- Print all practical tests for this user
            DECLARE pcur CURSOR FOR
                SELECT testid, grade, status, scenario, date_started, date_completed, comment, genero_version
                FROM PracticalTest
                WHERE userid = rec_user.userid
            OPEN pcur
            WHILE TRUE
                FETCH pcur INTO rec_ptest.*
                IF SQLCA.SQLCODE <> 0 THEN
                    EXIT WHILE
                END IF
                IF rec_ptest.grade THEN
                    LET ptest_grade_txt = "Pass"
                ELSE
                    LET ptest_grade_txt = "Fail"
                END IF
                PRINT "  TestID: ", rec_ptest.testid,
                      "  Grade: ", ptest_grade_txt,
                      "  Status: ", rec_ptest.status,
                      "  Scenario: ", rec_ptest.scenario,
                      "  Start: ", rec_ptest.date_started,
                      "  End: ", rec_ptest.date_completed,
                      "  Comment: ", rec_ptest.comment,
                      "  Version: ", rec_ptest.genero_version
            END WHILE
            CLOSE pcur

            SKIP 2 LINES

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of General Report ---"
            SKIP 2 LINES

END REPORT

REPORT grouped_report(rec_group)
    DEFINE rec_group RECORD
        group_val CHAR(100),
        fname VARCHAR(50),
        lname VARCHAR(50),
        score INTEGER,
        primary_email VARCHAR(100)
    END RECORD

    DEFINE last_group CHAR(100)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Grouped Report"
            SKIP 1 LINE

        ON EVERY ROW
            IF last_group IS NULL OR rec_group.group_val <> last_group THEN
                PRINT "============================================================"
                PRINT "Group: ", rec_group.group_val
                PRINT "------------------------------------------------------------"
                PRINT "Name                Score    Email"
                PRINT "------------------------------------------------------------"
                LET last_group = rec_group.group_val
            END IF

            PRINT rec_group.lname CLIPPED, ", ", rec_group.fname CLIPPED,
                  "      ",
                  rec_group.score USING "##",
                  "      ",
                  rec_group.primary_email CLIPPED

            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Grouped Report ---"
            SKIP 2 LINES

END REPORT

REPORT open_to_work_report(rec_otw)
    DEFINE rec_otw RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        company VARCHAR(100),
        contact_date DATE
    END RECORD

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Open-To-Work Users"
            SKIP 1 LINE

        ON EVERY ROW
            PRINT rec_otw.fname CLIPPED, " ", rec_otw.lname CLIPPED, " (UserID: ", rec_otw.userid, ")"
            PRINT "    Email: ", rec_otw.primary_email
            PRINT "    Company: ", rec_otw.company
            PRINT "    Contact Date: ", rec_otw.contact_date
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Open-To-Work Report ---"
            SKIP 2 LINES
END REPORT

REPORT passed_knowledge_report(rec_passed)
    DEFINE rec_passed RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        grade BIGINT,
        date_completed DATE
    END RECORD

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Users Who Passed the Certification Knowledge Test"
            SKIP 1 LINE

        ON EVERY ROW
            PRINT rec_passed.fname CLIPPED, " ", rec_passed.lname CLIPPED, " (UserID: ", rec_passed.userid, ")"
            PRINT "    Email: ", rec_passed.primary_email
            PRINT "    Knowledge Test Grade: " || rec_passed.grade || ", Date Passed: " || rec_passed.date_completed
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Knowledge Test Passing Report ---"
            SKIP 2 LINES
END REPORT

REPORT fully_certified_report(rec_full)
    DEFINE rec_full RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        k_grade BIGINT,
        k_date DATE,
        p_grade BOOLEAN,
        p_date DATE
    END RECORD

    DEFINE p_grade_txt CHAR(4)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Users Who Are Fully Certified (Passed BOTH Tests)"
            SKIP 1 LINE

        ON EVERY ROW
            IF rec_full.p_grade THEN
                LET p_grade_txt = "Pass"
            ELSE
                LET p_grade_txt = "Fail"
            END IF

            PRINT rec_full.fname CLIPPED, " ", rec_full.lname CLIPPED, " (UserID: ", rec_full.userid, ")"
            PRINT "    Email: ", rec_full.primary_email
            PRINT "    Knowledge Test: Pass (Grade: " || rec_full.k_grade || ", Date: " || rec_full.k_date || ")"
            PRINT "    Practical Test: " || p_grade_txt || " (Date: " || rec_full.p_date || ")"

            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Fully Certified Report ---"
            SKIP 2 LINES
END REPORT

REPORT individual_report(rec)
    DEFINE rec RECORD
        -- User info
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        secondary_email VARCHAR(100),
        phone_num VARCHAR(11),
        company VARCHAR(100),
        contact_date DATE,
        reason_for_cert BIGINT,
        seeking_employment BOOLEAN,
        -- KnowledgeTest
        kt_testid VARCHAR(20),
        kt_grade BOOLEAN,
        kt_date_completed DATE,
        kt_genero_version VARCHAR(50),
        -- PracticalTest
        pt_testid VARCHAR(20),
        pt_grade BOOLEAN,
        pt_status BIGINT,
        pt_scenario BIGINT,
        pt_date_started DATE,
        pt_date_completed DATE,
        pt_comment VARCHAR(300),
        pt_genero_version VARCHAR(50),
        -- Certification
        certid VARCHAR(30),
        cert_date DATE
    END RECORD

    DEFINE seeking_txt CHAR(3)
    DEFINE kt_grade_txt CHAR(6)
    DEFINE pt_grade_txt CHAR(6)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
        ON EVERY ROW
            -- Print user info (only once per user)
            IF rec.userid IS NOT NULL THEN
                IF rec.seeking_employment THEN
                    LET seeking_txt = "Yes"
                ELSE
                    LET seeking_txt = "No"
                END IF
                PRINT "--------------------------------------------------------"
                PRINT "Individual Report for ", rec.fname CLIPPED, " ", rec.lname CLIPPED
                PRINT "User ID: ", rec.userid
                PRINT "First Name: ", rec.fname
                PRINT "Last Name: ", rec.lname
                PRINT "Primary Email: ", rec.primary_email
                PRINT "Secondary Email: ", rec.secondary_email
                PRINT "Phone: ", rec.phone_num
                PRINT "Company: ", rec.company
                PRINT "Contact Date: ", rec.contact_date
                PRINT "Reason for Cert: ", rec.reason_for_cert
                PRINT "Seeking Employment: ", seeking_txt
                SKIP 1 LINE
            END IF

            -- Knowledge Test info
            IF rec.kt_testid IS NOT NULL THEN
                IF rec.kt_grade THEN
                    LET kt_grade_txt = "PASS"
                ELSE
                    LET kt_grade_txt = "FAIL"
                END IF
                PRINT "Knowledge Test:"
                PRINT "    Test ID: ", rec.kt_testid
                PRINT "    Grade: ", kt_grade_txt
                PRINT "    Date Completed: ", rec.kt_date_completed
                PRINT "    GenVer: ", rec.kt_genero_version
                SKIP 1 LINE
            END IF

            -- Practical Test info
            IF rec.pt_testid IS NOT NULL THEN
                IF rec.pt_grade THEN
                    LET pt_grade_txt = "PASS"
                ELSE
                    LET pt_grade_txt = "FAIL"
                END IF
                PRINT "Practical Test:"
                PRINT "    Test ID: ", rec.pt_testid
                PRINT "    Grade: ", pt_grade_txt
                IF rec.pt_status IS NOT NULL THEN PRINT "    Status: ", rec.pt_status END IF
                IF rec.pt_scenario IS NOT NULL THEN PRINT "    Scenario: ", rec.pt_scenario END IF
                IF rec.pt_date_started IS NOT NULL THEN PRINT "    Date Started: ", rec.pt_date_started END IF
                IF rec.pt_date_completed IS NOT NULL THEN PRINT "    Date Completed: ", rec.pt_date_completed END IF
                IF rec.pt_comment IS NOT NULL THEN PRINT "    Comment: ", rec.pt_comment END IF
                IF rec.pt_genero_version IS NOT NULL THEN PRINT "    GenVer: ", rec.pt_genero_version END IF
                SKIP 1 LINE
            END IF

            -- Certification info
            IF rec.certid IS NOT NULL THEN
                PRINT "Certification:"
                PRINT "    Cert ID: ", rec.certid
                PRINT "    Date: ", rec.cert_date
                SKIP 1 LINE
            END IF

        PAGE TRAILER
            SKIP 1 LINES
            PRINT "--- End of Individual Report ---"
END REPORT

REPORT lookup_userid_report(rec_user)
    DEFINE rec_user RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100)
    END RECORD

    FORMAT
        PAGE HEADER
            SKIP 1 LINE
            PRINT "UserID Lookup Results"
            SKIP 1 LINE
            PRINT "UserID", "   Name", "   Email"
            PRINT "-----------------------------------------------"
            SKIP 1 LINE
        ON EVERY ROW
            PRINT rec_user.userid CLIPPED, "   ", rec_user.fname CLIPPED, " ", rec_user.lname CLIPPED, "   ", rec_user.primary_email CLIPPED
        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Report ---"
END REPORT