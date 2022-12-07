from backend.database import get_db
from sqlalchemy.engine import Engine
from fastapi import Depends
from fastapi import APIRouter
from backend.schemas import Ticket, Survey

ticket_router = APIRouter(
    prefix="/tickets",
    tags=['tickets']
)


@ticket_router.get("/get-tickets/{user_id}")
def get_users_tickets(user_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    # return db.execute(f"""CALL selectTicketsByID(%s)""", (str(user_id),)).all()
    allTickets = db.execute(f"""CALL selectTicketsByID(%s)""", (str(user_id),)).all()
    trans.commit()
    return allTickets

# SELECT * FROM ticket NATURAL JOIN problem WHERE user_id = %s

@ticket_router.get("/get-closed-tickets/{user_id}")
def get_users_closed_tickets(user_id: int, db: Engine = Depends(get_db)):
    print(user_id)
    return db.execute(f"""CALL selectClosedTicketsByID(%s)""", (str(user_id),)).all()


@ticket_router.put("/edit-ticket/{ticket_id}")
def edit_ticket(ticket: Ticket, ticket_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    edited_ticket = db.execute(f"""call updateTicketProblem(%s,%s,%s,%s)""", (str(ticket.subject), str(ticket.type),
                                                                              str(ticket.description),
                                                                              str(ticket_id))).first()
    trans.commit()
    return edited_ticket


@ticket_router.delete("/delete-ticket/{ticket_id}")
def delete_ticket(ticket_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    # conn.execute(f"""DELETE FROM ticket WHERE ticket_id = %s""", str(ticket_id))
    conn.execute(f"""CALL deleteFromTicket(%s)""", (str(ticket_id)))
    trans.commit()
    return {"ticket_id": ticket_id}


@ticket_router.post("/create-ticket")  # something here for if ticket == hardware: trigger
def create_ticket(ticket: Ticket, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    if (ticket.type == "Hardware"):
        new_ticket = conn.execute(f"""call createTicketWithApproval(%s,%s,%s,%s,%s,%s,%s)""",
                                  (str(ticket.subject), str(ticket.type),
                                   str(ticket.description), str(ticket.priority), str(ticket.status),
                                   str(ticket.date_created),
                                   str(ticket.user_id))).first()
    else:
        new_ticket = conn.execute(f"""call createTicket(%s,%s,%s,%s,%s,%s,%s)""",
                                  (str(ticket.subject), str(ticket.type),
                                   str(ticket.description), str(ticket.priority), str(ticket.status),
                                   str(ticket.date_created),
                                   str(ticket.user_id))).first()
    trans.commit()
    return new_ticket


@ticket_router.get("/get-comments/{ticket_id}")
def get_comments(ticket_id: int, db: Engine = Depends(get_db)):
    print(ticket_id)
    return db.execute(f"""CALL getCommentsByID(%s)""", (str(ticket_id))).all()


@ticket_router.post("/complete-survey/{ticket_id}")
def complete_survey(ticket_id: int, survey: Survey, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    conn.execute(f"""CALL fillOutSurvey(%s,%s,%s,%s)""", (str(survey.survey_body), str(survey.user_id),
                                                          str(ticket_id), survey.satisfaction_level))
    trans.commit()
