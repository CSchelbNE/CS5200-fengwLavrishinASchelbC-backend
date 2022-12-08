DROP DATABASE IF EXISTS ticket_system;
CREATE DATABASE ticket_system;
USE ticket_system;



DROP TABLE IF EXISTS campus;
create table campus (
	campus_id SERIAL PRIMARY KEY,
    location ENUM("Boston","Burlington","Charlotte","London","Nahant",
    "Portland","San Francisco | Bay Area", "Seattle", "Toronto") NOT NULL
);

INSERT INTO campus (location) value ("Boston");
INSERT INTO campus (location) value ("Burlington");
INSERT INTO campus (location) value ("Charlotte");
INSERT INTO campus (location) value ("London");
INSERT INTO campus (location) value ("Nahant");
INSERT INTO campus (location) value ("Portland");
INSERT INTO campus (location) value ("San Francisco | Bay Area");
INSERT INTO campus (location) value ("Seattle");
INSERT INTO campus (location) value ("Toronto");


DROP TABLE IF EXISTS users;
create table users(
	user_id SERIAL primary key,
	password VARCHAR(64) not null,
    type VARCHAR(10) not null,
	name varchar(64) NOT NULL UNIQUE,
	address varchar(128) not null,
	email varchar(64) not null UNIQUE,
    campus BIGINT UNSIGNED NOT NULL,
    CONSTRAINT campus_fk1 foreign key(campus) references campus(campus_id)
		on update restrict on delete restrict
);


DROP TABLE IF EXISTS ticket;
create table ticket(
ticket_id SERIAL primary key,
priority varchar(64) not null,
date_created date not null,
status varchar(64) not null,
user_id BIGINT UNSIGNED,
CONSTRAINT ticket_fk1 foreign key(user_id) references users(user_id)
on update restrict on delete restrict
);

DROP TABLE IF EXISTS problem; 
create table problem(
problem_id SERIAL primary key,
subject varchar(25) NOT NULL,
type varchar(64) NOT NULL,
description varchar(255) NOT NULL,
ticket_id BIGINT UNSIGNED,
CONSTRAINT problem_fk1 foreign key(ticket_id) references ticket(ticket_id)
on update restrict on delete CASCADE
);

DROP TABLE IF EXISTS approval;
create table approval(
	approval_id SERIAL primary key,
	status varchar(64) NOT NULL,
	ticket_id BIGINT UNSIGNED,
	CONSTRAINT approval_fk1 foreign key(ticket_id) references ticket(ticket_id)
	on update restrict on delete CASCADE
);

-- ticketAssignment table keeps track of the assignment of tickets to techs.
-- All assigned & unassigned tickets are listed here.
DROP TABLE IF EXISTS ticketAssignment;
CREATE TABLE ticketAssignment(
	assignment_id SERIAL PRIMARY KEY,
	ticket_id BIGINT UNSIGNED NOT NULL,
	tech_assigned_to BIGINT UNSIGNED,
	FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON UPDATE RESTRICT ON DELETE CASCADE,
	FOREIGN KEY (tech_assigned_to) REFERENCES users(user_id)
	ON UPDATE RESTRICT ON DELETE CASCADE
);


DROP TABLE IF EXISTS comment;
CREATE TABLE comment (
	comment_id SERIAL PRIMARY KEY,
    comment_body VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS survey;
CREATE TABLE survey (
	survey_id SERIAL PRIMARY KEY,
    satisfaction_level INT, 
    survey_body VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS surveyAssignment; 
CREATE TABLE surveyAssignemnt (
		assignment_id SERIAL PRIMARY KEY,
        ticket_id BIGINT UNSIGNED,
        user_id BIGINT UNSIGNED,
        survey_id BIGINT UNSIGNED,
		FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
		FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE RESTRICT ON DELETE CASCADE,
		FOREIGN KEY (survey_id) REFERENCEs survey(survey_id) ON UPDATE RESTRICT ON DELETE RESTRICT	
);


DROP TABLE IF EXISTS commentAssignment;
CREATE TABLE commentAssignment (
	assignment_id SERIAL PRIMARY KEY,
    comment_id BIGINT UNSIGNED NOT NULL,
    ticket_id BIGINT UNSIGNED NOT NULL,
    tech_id BIGINT UNSIGNED NOT NULL,
    FOREIGN KEY (comment_id) REFERENCES comment(comment_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (tech_id) REFERENCEs users(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT	
);

DROP PROCEDURE IF EXISTS fillOutSurvey;
DELIMITER $$
CREATE PROCEDURE fillOutSurvey(IN n_survey_body VARCHAR(255), IN n_ticket_id BIGINT UNSIGNED,
		IN n_user_id BIGINT UNSIGNED, IN n_satisfaction_level BIGINT UNSIGNED)
	BEGIN
		declare n_survey_id BIGINT UNSIGNED;
        INSERT INTO survey (survey_body, satisfaction_level) VALUES (n_survey_body, n_satisfaction_level);
        SET n_survey_id = last_insert_id();
        INSERT INTO surveyAssignemnt (ticket_id, user_id, survey_id) VALUES (n_ticket_id, n_user_id, n_survey_id);
        SELECT * FROM survey WHERE n_survey_id;
END $$
DELIMITER ;



SELECT * FROM survey;
DROP PROCEDURE IF EXISTS createComment;
DELIMITER $$
CREATE PROCEDURE createComment(IN n_comment_body VARCHAR(255), IN n_ticket_id BIGINT UNSIGNED,
		IN n_tech_id BIGINT UNSIGNED)
	BEGIN
		declare n_comment_id BIGINT UNSIGNED;
        INSERT INTO comment (comment_body) VALUES (n_comment_body);
        SET n_comment_id = last_insert_id();
        INSERT INTO commentAssignment (comment_id, ticket_id, tech_id) VALUES (n_comment_id, n_ticket_id, n_tech_id);
        SELECT * FROM comment WHERE comment_id = n_comment_id;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS createUser;
DELIMITER $$
CREATE PROCEDURE createUser(IN n_password VARCHAR(64), IN n_type VARCHAR(10), 
		IN n_name VARCHAR(64), IN n_address VARCHAR(128), IN n_email VARCHAR(64), IN n_campus VARCHAR(64))
	BEGIN
		declare n_campus_id BIGINT UNSIGNED;
        declare n_user_id BIGINT UNSIGNED;
		SET n_campus_id = (SELECT campus_id FROM campus WHERE location=n_campus);
        INSERT INTO users (password, type, name, address, email, campus) VALUES (n_password, 
			n_type, n_name, n_address, n_email, n_campus_id);
		SET n_user_id = last_insert_id();
        SELECT * FROM users WHERE user_id = n_user_id;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS getCommentsByID;
DELIMITER $$
CREATE PROCEDURE getCommentsByID(IN n_ticket_id BIGINT UNSIGNED)
	BEGIN
		SELECT ticket_id, comment_id,comment_body,name FROM users JOIN (SELECT * FROM comment NATURAL JOIN commentAssignment) as 
        T ON T.tech_id = users.user_id HAVING T.ticket_id = n_ticket_id;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS createTicket;
DELIMITER $$
CREATE PROCEDURE createTicket(IN n_subject VARCHAR(25), IN n_type VARCHAR(64), IN n_description VARCHAR(255),
								IN n_priority VARCHAR(64), IN n_status VARCHAR(64), IN n_date_created DATE,
                                n_user_id BIGINT UNSIGNED)
	BEGIN
		declare n_ticket_id int unsigned default 0;
		INSERT INTO ticket (priority,date_created,status,user_id) VALUES (n_priority, n_date_created, n_status, n_user_id);
        SET n_ticket_id = last_insert_id();
        INSERT INTO problem (subject, type,description,ticket_id) VALUES (n_subject, n_type, n_description, n_ticket_id);
        SELECT * FROM ticket NATURAL JOIN problem WHERE ticket_id = n_ticket_id;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS createTicketWithApproval;
DELIMITER $$
CREATE PROCEDURE createTicketWithApproval(IN n_subject VARCHAR(25), IN n_type VARCHAR(64), IN n_description VARCHAR(255),
								IN n_priority VARCHAR(64), IN n_status VARCHAR(64), IN n_date_created DATE,
                                n_user_id BIGINT UNSIGNED)
	BEGIN
		declare n_ticket_id int unsigned default 0;
		INSERT INTO ticket (priority,date_created,status,user_id) VALUES (n_priority, n_date_created, n_status, n_user_id);
        SET n_ticket_id = last_insert_id();
        INSERT INTO problem (subject, type,description,ticket_id) VALUES (n_subject, n_type, n_description, n_ticket_id);
        INSERT INTO approval (status, ticket_id) VALUES ("REQUIRES APPROVAL",n_ticket_id);
        SELECT * FROM ticket NATURAL JOIN problem WHERE ticket_id = n_ticket_id;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS getApprovals;
DELIMITER $$
CREATE PROCEDURE getApprovals()
	BEGIN
		SELECT * FROM approval JOIN (SELECT * FROM problem NATURAL JOIN (SELECT email, user_id,
		priority, date_created, ticket_id, status FROM users NATURAL JOIN ticket) AS T)  
             AS p on p.ticket_id = approval.ticket_id WHERE approval.status = "REQUIRES APPROVAL"; 
END $$
DELIMITER ;








DROP PROCEDURE IF EXISTS updateTicketProblem;
DELIMITER $$
CREATE PROCEDURE updateTicketProblem(IN n_subject VARCHAR(25), IN n_type VARCHAR(64), 
				IN n_description VARCHAR(255), IN n_ticket_id BIGINT UNSIGNED)
	BEGIN
		UPDATE problem SET 
		description = n_description,
        subject = n_subject,
        type = n_type
        WHERE n_ticket_id = ticket_id;
        IF (n_type = "Hardware") THEN INSERT INTO approval (status, ticket_id) VALUES ("REQUIRES APPROVAL", n_ticket_id);
        END IF;
        IF (n_type != "Hardware") THEN DELETE FROM approval WHERE ticket_id = n_ticket_id;
        END IF;
		SELECT * FROM ticket NATURAL JOIN problem WHERE ticket_id = n_ticket_id;
END $$
DELIMITER ;

/*
DROP PROCEDURE IF EXISTS editApprovalStatus;
DELIMITER $$
CREATE PROCEDURE editApprovalStatus(IN app_id BIGINT UNSIGNED, IN new_status VARCHAR(64))
    BEGIN
        UPDATE approval SET `status` = new_status WHERE approval_id = app_id;
        SELECT * FROM approval WHERE approval_id = app_id;
END $$
DELIMITER ;
*/

DROP PROCEDURE IF EXISTS editApprovalStatus;
DELIMITER $$
CREATE PROCEDURE editApprovalStatus(IN app_id BIGINT UNSIGNED, IN new_status VARCHAR(64))
    BEGIN        
		UPDATE approval SET `status` = new_status WHERE approval_id = app_id;        
		UPDATE ticket SET `status` = new_status WHERE ticket_id =(SELECT ticket_id FROM approval WHERE approval_id = app_id);
        SELECT * FROM approval WHERE approval_id = app_id;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS deleteTicket;
DELIMITER $$
CREATE PROCEDURE deleteTicket(IN n_ticket_id BIGINT UNSIGNED)
	BEGIN 
		DECLARE d_approval_id BIGINT UNSIGNED;
        DECLARE d_ticket_id BIGINT UNSIGNED;
		SELECT * FROM approval RIGHT OUTER JOIN (SELECT * FROM ticket NATURAL JOIN problem WHERE status="OPEN") AS P on P.ticket_id = approval.ticket_id WHERE P.ticket_id = n_ticket_id;
		
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS assignOpenTicket;
DELIMITER $$
CREATE PROCEDURE assignOpenTicket(IN n_ticket_id BIGINT UNSIGNED, IN n_technician_id BIGINT UNSIGNED)
	BEGIN 
		DECLARE n_assignment_id BIGINT UNSIGNED;
		INSERT INTO ticketAssignment (ticket_id, tech_assigned_to) VALUES (n_ticket_id, n_technician_id);
        SET n_assignment_id = last_insert_id();
        SELECT * FROM ticketAssignment WHERE assignment_id = n_assignment_id;
END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS selectTicketsByID;
DELIMITER $$
CREATE PROCEDURE selectTicketsByID(IN n_user_id BIGINT UNSIGNED)
	BEGIN 
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
			BEGIN
            DECLARE errno INT;
			GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO;
			SELECT errno AS MYSQL_ERROR;
			ROLLBACK;
		END;
		SELECT * FROM problem NATURAL JOIN (SELECT ticket.ticket_id, priority, date_created, status, user_id, group_concat(name) as technicians
        FROM ticket LEFT OUTER JOIN (SELECT ticket_id, name, tech_assigned_to FROM users JOIN ticketAssignment ON user_id = 
        tech_assigned_to) AS T ON T.ticket_id = ticket.ticket_id GROUP BY ticket.ticket_id, priority, date_created, 
        status, user_id HAVING user_id = n_user_id) as A WHERE status="OPEN" OR status="REQUIRES APPROVAL";
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS filterOpenTicketsByTechnician;
DELIMITER $$
CREATE PROCEDURE filterOpenTicketsByTechnician(IN n_tech_id BIGINT UNSIGNED)
	BEGIN 
		SELECT * FROM problem NATURAL JOIN (SELECT ticket.ticket_id, priority, date_created, status, user_id, 
        assignment_id, tech_assigned_to FROM ticket LEFT OUTER JOIN ticketAssignment ON ticket.ticket_id = 
        ticketAssignment.ticket_id WHERE (status="OPEN" OR STATUS="APPROVED") AND (ticket.ticket_id NOT IN (SELECT ticket_id FROM ticketAssignment WHERE tech_assigned_to = n_tech_id) or
        (select ISNULL(tech_assigned_to)))) AS T;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS filterAcceptedTicketsByTechnician;
DELIMITER $$
CREATE PROCEDURE filterAcceptedTicketsByTechnician(IN n_tech_id BIGINT UNSIGNED)
	BEGIN 
		SELECT * FROM problem NATURAL JOIN 
        (SELECT * FROM ticket NATURAL JOIN (SELECT * FROM ticketAssignment WHERE tech_assigned_to 
        = n_tech_id) AS T WHERE ticket.status != "CLOSED") AS T2;
		
END $$
DELIMITER ;
SELECT * FROM ticket;
DROP PROCEDURE IF EXISTS selectClosedTicketsByID;
DELIMITER $$
CREATE PROCEDURE selectClosedTicketsByID(IN n_user_id BIGINT UNSIGNED)
    BEGIN         
		SELECT * FROM problem NATURAL JOIN (SELECT ticket.ticket_id, priority, date_created, status, user_id, group_concat(name) as technicians        FROM ticket LEFT OUTER JOIN (SELECT ticket_id, name, tech_assigned_to FROM users JOIN ticketAssignment ON user_id =         tech_assigned_to) AS T ON t.ticket_id = ticket.ticket_id GROUP BY ticket.ticket_id, priority, date_created,         status, user_id HAVING user_id = n_user_id) as T WHERE `status`="CLOSED" OR `status`="DENIED";
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS closeTicket;
DELIMITER $$
CREATE PROCEDURE closeTicket(IN n_ticket_id BIGINT UNSIGNED)
    BEGIN         
		UPDATE ticket SET status="CLOSED" WHERE ticket_id = n_ticket_id;
        SELECT * FROM ticket WHERE ticket_id = n_ticket_id;
END $$
DELIMITER ;

-- Admin Username: admin1 Password: abc123
-- Tech Username: tech1 Password: 123abc
call createUser("$2b$12$CVFokaV.Cxyp1emjsAq6ZOkYMhKJwbkgW4O729c8cUlpmYJbeKr9S","admin", 
	"admin1", "82 Washboard St, Boston MA 22125", "admin@neu.edu", "Boston");
call createUser("$2b$12$Artl91bTDLq4l1X4k4WDG.3IMAdztyZ/6u71syfHPZRWecnoBB/Cy", 
	"tech", "tech1", "Needle Rd, 19822", "tech1@neu.edu", "Seattle");
call createUser("$2b$12$Artl91bTDLq4l1X4k4WDG.3IMAdztyZ/6u71syfHPZRWecnoBB/Cy", "tech", "tech2", "162 Abracadabra Ln",
	"tech2@neu.edu", "San Francisco | Bay Area");
