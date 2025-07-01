#+ Database creation script for SQLite
#+
#+ Note: This script is a helper script to create an empty database schema
#+       Adapt it to fit your needs

MAIN
    DATABASE certtrackerdb

    CALL db_drop_tables()
    CALL db_create_tables()
END MAIN

#+ Create all tables in database.
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
        genero_version VARCHAR(50),
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
        grade BOOLEAN,
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


