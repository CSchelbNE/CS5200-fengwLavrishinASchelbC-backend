DROP DATABASE IF EXISTS ticket_system;
CREATE DATABASE ticket_system;
USE ticket_system;

DROP TABLE IF EXISTS users;
create table users(
	user_id SERIAL primary key,
	password char(64) not null,
    type VARCHAR(10) not null,
	name varchar(64) NOT NULL UNIQUE,
	address varchar(64) not null,
	email varchar(64) not null UNIQUE
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
SELECT * FROM ticket;








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
		SELECT * FROM problem NATURAL JOIN (SELECT ticket.ticket_id, priority, date_created, status, user_id, group_concat(name) as technicians
        FROM ticket LEFT OUTER JOIN (SELECT ticket_id, name, tech_assigned_to FROM users JOIN ticketAssignment ON user_id = 
        tech_assigned_to) AS T ON t.ticket_id = ticket.ticket_id GROUP BY ticket.ticket_id, priority, date_created, 
        status, user_id HAVING user_id = n_user_id) as T WHERE status="OPEN" OR status="REQUIRES APPROVAL";
END $$
DELIMITER ;
CALL selectTicketsByID(4);

DROP PROCEDURE IF EXISTS filterOpenTicketsByTechnician;
DELIMITER $$
CREATE PROCEDURE filterOpenTicketsByTechnician(IN n_tech_id BIGINT UNSIGNED)
	BEGIN 
		SELECT * FROM problem NATURAL JOIN (SELECT ticket.ticket_id, priority, date_created, status, user_id, 
        assignment_id, tech_assigned_to FROM ticket LEFT OUTER JOIN ticketAssignment ON ticket.ticket_id = 
        ticketAssignment.ticket_id WHERE status="OPEN" AND (ticket.ticket_id NOT IN (SELECT ticket_id FROM ticketAssignment WHERE tech_assigned_to = n_tech_id) or
        (select ISNULL(tech_assigned_to)))) AS T;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS filterAcceptedTicketsByTechnician;
DELIMITER $$
CREATE PROCEDURE filterAcceptedTicketsByTechnician(IN n_tech_id BIGINT UNSIGNED)
	BEGIN 
		SELECT * FROM problem NATURAL JOIN (SELECT * FROM ticket NATURAL JOIN (SELECT * FROM ticketAssignment WHERE tech_assigned_to = n_tech_id) AS T) AS T2;
		
END $$
DELIMITER ;

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
INSERT INTO users (password, name, address, email, type)
    VALUES("$2b$12$CVFokaV.Cxyp1emjsAq6ZOkYMhKJwbkgW4O729c8cUlpmYJbeKr9S", "admin1", "abcd", "admin@neu.edu", "admin"),
    ("$2b$12$Artl91bTDLq4l1X4k4WDG.3IMAdztyZ/6u71syfHPZRWecnoBB/Cy", "tech1", "abcd", "tech1@neu.edu", "tech"), 
     ("$2b$12$Artl91bTDLq4l1X4k4WDG.3IMAdztyZ/6u71syfHPZRWecnoBB/Cy", "tech2", "abcd", "tech2@neu.edu", "tech");