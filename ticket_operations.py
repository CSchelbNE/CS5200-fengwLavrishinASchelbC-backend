import sqlalchemy.exc

from database import get_db
from sqlalchemy.engine import Engine
from fastapi import APIRouter
from schemas import Ticket, Survey
from fastapi import status, HTTPException, Depends

ticket_router = APIRouter(
    prefix="/tickets",
    tags=['tickets']
)


@ticket_router.get("/get-tickets/{user_id}")
def get_users_tickets(user_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    try:
        res = conn.execute(f"""CALL selectTicketsByID(%s)""", (str(user_id),)).all()
        trans.commit()
        return res
    except sqlalchemy.exc.PendingRollbackError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="ROLLBACK OCCURRED")
    except sqlalchemy.exc.OperationalError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="OPS ERROR")
    except sqlalchemy.exc.InvalidRequestError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="INVALID REQ")
    except sqlalchemy.exc.InternalError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="INVALID REQ")


# SELECT * FROM ticket NATURAL JOIN problem WHERE user_id = %s

@ticket_router.get("/get-closed-tickets/{user_id}")
def get_users_closed_tickets(user_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    try:
        res = conn.execute(f"""CALL selectClosedTicketsByID(%s)""", (str(user_id),)).all()
        trans.commit()
        return res
    except sqlalchemy.exc.PendingRollbackError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="ROLLBACK OCCURRED")
    except sqlalchemy.exc.OperationalError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="OPS ERROR")
    except sqlalchemy.exc.InvalidRequestError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="INVALID REQ")
    except sqlalchemy.exc.InternalError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="INVALID REQ")


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
    conn.execute(f"""DELETE FROM ticket WHERE ticket_id = %s""", str(ticket_id))
    trans.commit()
    return {"ticket_id": ticket_id}


@ticket_router.post("/create-ticket")  # something here for if ticket == hardware: trigger
def create_ticket(ticket: Ticket, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    try:
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
    except sqlalchemy.exc.PendingRollbackError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="ROLLBACK OCCURRED")
    except sqlalchemy.exc.OperationalError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="OPS ERROR")
    except sqlalchemy.exc.InvalidRequestError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="INVALID REQ")
    except sqlalchemy.exc.InternalError as err:
        trans.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="INTERNAL ERROR")


@ticket_router.get("/get-comments/{ticket_id}")
def get_comments(ticket_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    with conn.begin() as trans:
        try:
            res = conn.execute(f"""CALL getCommentsByID(%s)""", (str(ticket_id))).all()
            trans.commit()
            return res
        except sqlalchemy.exc.PendingRollbackError as err:
            trans.rollback()
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="ROLLBACK OCCURRED")
        except sqlalchemy.exc.OperationalError as err:
            trans.rollback()
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="OPS ERROR")
        except sqlalchemy.exc.InvalidRequestError as err:
            print("HERE")
            trans.rollback()
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="INVALID REQ")
        except sqlalchemy.exc.InternalError as err:
            trans.rollback()
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="INTERNAL ERROR")


@ticket_router.post("/complete-survey/{ticket_id}")
def complete_survey(ticket_id: int, survey: Survey, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    conn.execute(f"""CALL fillOutSurvey(%s,%s,%s,%s)""", (str(survey.survey_body), str(survey.user_id),
                                                          str(ticket_id), survey.satisfaction_level))
    trans.commit()
