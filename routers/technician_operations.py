from backend.database import get_db
from sqlalchemy.engine import Engine
from fastapi import Response, status, HTTPException, Depends
from fastapi import APIRouter
from backend.schemas import Comment

technician_router = APIRouter(
    prefix="/tech",
    tags=['tech']
)


@technician_router.get("/get-open-tickets/{tech_id}")
def get_all_open_tickets(tech_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    # return db.execute("""CALL filterOpenTicketsByTechnician(%s)""", (str(tech_id))).all()
    openTickets = db.execute(f"""CALL filterOpenTicketsByTechnician(%s)""", (str(tech_id))).all()
    trans.commit()
    return openTickets


@technician_router.put("/accept-ticket/")
def accept_open_ticket(ticket_id: int, tech_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    new_assignemnt = conn.execute(f"CALL assignOpenTicket(%s,%s)", (str(ticket_id), str(tech_id))).first()
    trans.commit()
    return new_assignemnt


@technician_router.get("/get-assigned-tickets/{tech_id}")
def get_assigned_tickets(tech_id: int, db: Engine = Depends(get_db)):
    return db.execute(f"""CALL filterAcceptedTicketsByTechnician(%s)""", (str(tech_id),)).all()


@technician_router.put("/close-ticket/{ticket_id}")
def close_ticket(ticket_id: int, db: Engine = Depends(get_db)):
    return db.execute(f"""CALL closeTicket(%s)""", (str(ticket_id))).first()


@technician_router.post("/create-comment/")
def create_comment(comment: Comment, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    result = db.execute(f"""CALL createComment(%s, %s, %s)""", (str(comment.comment_body), str(comment.ticket_id),
                                                              str(comment.tech_id))).first()
    trans.commit()
    return result


