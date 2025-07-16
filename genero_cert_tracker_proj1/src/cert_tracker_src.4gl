IMPORT FGL user_control_src
IMPORT FGL knowledge_test_src
IMPORT FGL practical_test_src

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
        CALL user_form_driver()
    ON ACTION edit_knowledge_test
        CALL knowledge_test_driver()
    ON ACTION edit_practical_test
        CALL practical_test_driver()
    ON ACTION query_tests
        DISPLAY "query tests"
    ON ACTION certification_info
        DISPLAY "certification info"
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




END MENU
CLOSE WINDOW w1
END MAIN


FUNCTION db_create_tables()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "CREATE TABLE User (
        userid VARCHAR(30) NOT NULL,
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100) NOT NULL,
        secondary_email VARCHAR(100),
        phone_num VARCHAR(11),
        company VARCHAR(100),
        contact_date DATE NOT NULL,
        reason_for_cert BIGINT,
        seeking_employment BOOLEAN,
        CONSTRAINT PK_User_1 PRIMARY KEY(userid))"
    EXECUTE IMMEDIATE "CREATE TABLE PracticalTest (
        userid VARCHAR(30) NOT NULL,
        testid VARCHAR(20) NOT NULL,
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
        userid VARCHAR(30) NOT NULL,
        testid VARCHAR(20) NOT NULL,
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
    DEFINE rec_company RECORD
        company VARCHAR(100),
        pass_knowledge INTEGER,
        fail_knowledge INTEGER,
        pass_practical INTEGER,
        fail_practical INTEGER
    END RECORD

    DEFINE rec_seeking RECORD
        seeking_employment BOOLEAN,
        pass_knowledge INTEGER,
        fail_knowledge INTEGER,
        pass_practical INTEGER,
        fail_practical INTEGER
    END RECORD

    DEFINE rec_reason RECORD
        reason_for_cert BIGINT,
        pass_knowledge INTEGER,
        fail_knowledge INTEGER,
        pass_practical INTEGER,
        fail_practical INTEGER
    END RECORD

    -- --------- SECTION 1: By Company ----------
    DECLARE c_company CURSOR FOR
        SELECT 
            u.company,
            SUM(CASE WHEN kt.grade = 1 THEN 1 ELSE 0 END) AS pass_knowledge,
            SUM(CASE WHEN kt.grade = 0 THEN 1 ELSE 0 END) AS fail_knowledge,
            SUM(CASE WHEN pt.grade = 1 THEN 1 ELSE 0 END) AS pass_practical,
            SUM(CASE WHEN pt.grade = 0 THEN 1 ELSE 0 END) AS fail_practical
        FROM User u
        LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid
        LEFT JOIN PracticalTest pt ON u.userid = pt.userid
        GROUP BY u.company
        ORDER BY u.company

    START REPORT counts_report_company
    FOREACH c_company INTO rec_company.*
        OUTPUT TO REPORT counts_report_company(rec_company.*)
    END FOREACH
    FINISH REPORT counts_report_company

    -- --------- SECTION 2: By Seeking Employment ----------
    DECLARE c_seeking CURSOR FOR
        SELECT 
            u.seeking_employment,
            SUM(CASE WHEN kt.grade = 1 THEN 1 ELSE 0 END) AS pass_knowledge,
            SUM(CASE WHEN kt.grade = 0 THEN 1 ELSE 0 END) AS fail_knowledge,
            SUM(CASE WHEN pt.grade = 1 THEN 1 ELSE 0 END) AS pass_practical,
            SUM(CASE WHEN pt.grade = 0 THEN 1 ELSE 0 END) AS fail_practical
        FROM User u
        LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid
        LEFT JOIN PracticalTest pt ON u.userid = pt.userid
        GROUP BY u.seeking_employment
        ORDER BY u.seeking_employment DESC

    START REPORT counts_report_seeking
    FOREACH c_seeking INTO rec_seeking.*
        OUTPUT TO REPORT counts_report_seeking(rec_seeking.*)
    END FOREACH
    FINISH REPORT counts_report_seeking

    -- --------- SECTION 3: By Reason for Certification ----------
    DECLARE c_reason CURSOR FOR
        SELECT 
            u.reason_for_cert,
            SUM(CASE WHEN kt.grade = 1 THEN 1 ELSE 0 END) AS pass_knowledge,
            SUM(CASE WHEN kt.grade = 0 THEN 1 ELSE 0 END) AS fail_knowledge,
            SUM(CASE WHEN pt.grade = 1 THEN 1 ELSE 0 END) AS pass_practical,
            SUM(CASE WHEN pt.grade = 0 THEN 1 ELSE 0 END) AS fail_practical
        FROM User u
        LEFT JOIN KnowledgeTest kt ON u.userid = kt.userid
        LEFT JOIN PracticalTest pt ON u.userid = pt.userid
        GROUP BY u.reason_for_cert
        ORDER BY u.reason_for_cert

    START REPORT counts_report_reason
    FOREACH c_reason INTO rec_reason.*
        OUTPUT TO REPORT counts_report_reason(rec_reason.*)
    END FOREACH
    FINISH REPORT counts_report_reason

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
        seeking CHAR(3),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        company VARCHAR(100),
        contact_date DATE
    END RECORD

    START REPORT open_to_work_report

    -- Prepare the data grouped by seeking_employment (Yes/No)
    PREPARE s FROM
        "SELECT CASE WHEN seeking_employment THEN 'Yes' ELSE 'No' END AS seeking, " ||
        "fname, lname, primary_email, company, contact_date " ||
        "FROM User " ||
        "ORDER BY seeking DESC, lname, fname"

    DECLARE otw_cur CURSOR FOR s

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
        grade BIGINT
    END RECORD

    DECLARE cur CURSOR FOR
        SELECT u.userid, u.fname, u.lname, u.primary_email, k.grade
          FROM User u, KnowledgeTest k
         WHERE u.userid = k.userid
           AND k.grade = 1  -- or your passing value
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
        p_grade BOOLEAN
    END RECORD

    DECLARE cur_full CURSOR FOR
        SELECT u.userid, u.fname, u.lname, u.primary_email, k.grade, p.grade
          FROM User u, KnowledgeTest k, PracticalTest p
         WHERE u.userid = k.userid
           AND u.userid = p.userid
           AND k.grade = 1
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

    DISPLAY "Enter the User ID of the person you want to report on:"
    PROMPT "User ID: " FOR p_userid

    DECLARE user_cur CURSOR FOR
        SELECT userid, fname, lname, primary_email, secondary_email,
               phone_num, company, contact_date, reason_for_cert, seeking_employment
          FROM User
         WHERE userid = p_userid

    START REPORT individual_report
    OPEN user_cur
    WHILE TRUE
        FETCH user_cur INTO rec_user.*
        IF SQLCA.SQLCODE <> 0 THEN
            EXIT WHILE
        END IF
        OUTPUT TO REPORT individual_report(rec_user.*)
    END WHILE
    CLOSE user_cur
    FINISH REPORT individual_report
END FUNCTION


REPORT counts_report_company(rec_company)
    DEFINE rec_company RECORD
        company VARCHAR(100),
        pass_knowledge INTEGER,
        fail_knowledge INTEGER,
        pass_practical INTEGER,
        fail_practical INTEGER
    END RECORD

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Counts Report by Company"
            SKIP 1 LINE
            PRINT "Company        Pass_Knowledge  Fail_Knowledge  Pass_Practical  Fail_Practical"
            SKIP 2 LINES

        ON EVERY ROW
            PRINT rec_company.company CLIPPED, "        ",
                  rec_company.pass_knowledge USING "###", "        ",
                  rec_company.fail_knowledge USING "###", "        ",
                  rec_company.pass_practical USING "###", "        ",
                  rec_company.fail_practical USING "###"
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Company Counts ---"
            SKIP 2 LINES

END REPORT

REPORT counts_report_seeking(rec_seeking)
    DEFINE rec_seeking RECORD
        seeking_employment BOOLEAN,
        pass_knowledge INTEGER,
        fail_knowledge INTEGER,
        pass_practical INTEGER,
        fail_practical INTEGER
    END RECORD

    DEFINE open_to_work CHAR(3)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Counts Report by Seeking Employment (Open to Work)"
            SKIP 1 LINE
            PRINT "OpenToWork     Pass_Knowledge  Fail_Knowledge  Pass_Practical  Fail_Practical"
            SKIP 2 LINES

        ON EVERY ROW
            IF rec_seeking.seeking_employment THEN
                LET open_to_work = "Yes"
            ELSE
                LET open_to_work = "No"
            END IF

            PRINT open_to_work, "        ",
                  rec_seeking.pass_knowledge USING "###", "        ",
                  rec_seeking.fail_knowledge USING "###", "        ",
                  rec_seeking.pass_practical USING "###", "        ",
                  rec_seeking.fail_practical USING "###"
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Open to Work Counts ---"
            SKIP 2 LINES

END REPORT

REPORT counts_report_reason(rec_reason)
    DEFINE rec_reason RECORD
        reason_for_cert BIGINT,
        pass_knowledge INTEGER,
        fail_knowledge INTEGER,
        pass_practical INTEGER,
        fail_practical INTEGER
    END RECORD

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Counts Report by Reason for Certification"
            SKIP 1 LINE
            PRINT "Reason        Pass_Knowledge  Fail_Knowledge  Pass_Practical  Fail_Practical"
            SKIP 2 LINES

        ON EVERY ROW
            PRINT rec_reason.reason_for_cert USING "#####", "        ",
                  rec_reason.pass_knowledge USING "###", "        ",
                  rec_reason.fail_knowledge USING "###", "        ",
                  rec_reason.pass_practical USING "###", "        ",
                  rec_reason.fail_practical USING "###"
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Reason for Cert Counts ---"
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
            PRINT "Rank  Score  Name                      Email                         Company             OpenToWork"
            SKIP 2 LINES

        ON EVERY ROW
            IF rec_rank.seeking_employment THEN
                LET open_to_work = "Yes"
            ELSE
                LET open_to_work = "No"
            END IF

            PRINT rec_rank.rank USING "###", "   ",
                  rec_rank.score USING "###", "   ",
                  rec_rank.lname CLIPPED, ", ", rec_rank.fname CLIPPED, "   ",
                  rec_rank.primary_email CLIPPED, "   ",
                  rec_rank.company CLIPPED, "   ",
                  open_to_work
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Ranking Report ---"
            SKIP 2 LINES

END REPORT

REPORT in_progress_report(rec_progress)
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

    DEFINE status_desc CHAR(20)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "In Progress Practical Tests Report"
            SKIP 1 LINE
            PRINT "Status        Name                  Email                  Company         TestID   Scenario   Start Date   End Date"
            SKIP 2 LINES

        ON EVERY ROW
            -- Translate status code to text
            CASE
                WHEN rec_progress.status = 0
                    LET status_desc = "Not Started"
                WHEN rec_progress.status = 1
                    LET status_desc = "In Progress"
                WHEN rec_progress.status = 2
                    LET status_desc = "Completed"
                OTHERWISE
                    LET status_desc = "Unknown"
            END CASE

            PRINT status_desc, "   ",
                  rec_progress.lname CLIPPED, ", ", rec_progress.fname CLIPPED, "   ",
                  rec_progress.primary_email CLIPPED, "   ",
                  rec_progress.company CLIPPED, "   ",
                  rec_progress.testid CLIPPED, "   ",
                  rec_progress.scenario USING "###", "   ",
                  rec_progress.date_started, "   ",
                  rec_progress.date_completed
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of In Progress Report ---"
            SKIP 2 LINES

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
        seeking CHAR(3),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        company VARCHAR(100),
        contact_date DATE
    END RECORD

    DEFINE last_seeking CHAR(3)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Open to Work Report"
            SKIP 1 LINE

        ON EVERY ROW
            IF last_seeking IS NULL OR rec_otw.seeking <> last_seeking THEN
                PRINT "====================================================="
                PRINT "Seeking Employment: ", rec_otw.seeking
                PRINT "-----------------------------------------------------"
                PRINT "Name                Email                   Company         Contact Date"
                PRINT "-----------------------------------------------------"
                LET last_seeking = rec_otw.seeking
            END IF

            PRINT rec_otw.lname CLIPPED, ", ", rec_otw.fname CLIPPED,
                  "      ",
                  rec_otw.primary_email CLIPPED,
                  "      ",
                  rec_otw.company CLIPPED,
                  "      ",
                  rec_otw.contact_date

            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Open to Work Report ---"
            SKIP 2 LINES

END REPORT

REPORT passed_knowledge_report(rec_passed)
    DEFINE rec_passed RECORD
        userid VARCHAR(30),
        fname VARCHAR(50),
        lname VARCHAR(50),
        primary_email VARCHAR(100),
        grade BIGINT
    END RECORD

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Users Who Passed the Certification Knowledge Test"
            SKIP 1 LINE

        ON EVERY ROW
            PRINT rec_passed.fname CLIPPED, " ", rec_passed.lname CLIPPED, " (UserID: ", rec_passed.userid, ")"
            PRINT "    Email: ", rec_passed.primary_email
            PRINT "    Knowledge Test Grade: ", rec_passed.grade
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
        p_grade BOOLEAN
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
            PRINT "    Knowledge Test: Pass"
            PRINT "    Practical Test: ", p_grade_txt
            SKIP 1 LINE

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Fully Certified Report ---"
            SKIP 2 LINES
END REPORT

REPORT individual_report(rec_user)
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

    DEFINE seeking_txt CHAR(3)

    FORMAT
        PAGE HEADER
            SKIP 2 LINES
            PRINT "Individual Report for ", rec_user.fname CLIPPED, " ", rec_user.lname CLIPPED
            SKIP 1 LINE

        ON EVERY ROW
            IF rec_user.seeking_employment THEN
                LET seeking_txt = "Yes"
            ELSE
                LET seeking_txt = "No"
            END IF

            PRINT "--------------------------------------------------------"
            PRINT "User ID: ", rec_user.userid
            PRINT "First Name: ", rec_user.fname
            PRINT "Last Name: ", rec_user.lname
            PRINT "Primary Email: ", rec_user.primary_email
            PRINT "Secondary Email: ", rec_user.secondary_email
            PRINT "Phone: ", rec_user.phone_num
            PRINT "Company: ", rec_user.company
            PRINT "Contact Date: ", rec_user.contact_date
            PRINT "Reason for Cert: ", rec_user.reason_for_cert
            PRINT "Seeking Employment: ", seeking_txt
            SKIP 2 LINES

        PAGE TRAILER
            SKIP 2 LINES
            PRINT "--- End of Individual Report ---"
            SKIP 2 LINES
END REPORT
