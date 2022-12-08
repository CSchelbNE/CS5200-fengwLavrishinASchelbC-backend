from database import get_db
from sqlalchemy.engine import Engine
from fastapi import Depends
from fastapi import APIRouter
from schemas import Approval

admin_router = APIRouter(
    prefix="/admin",
    tags=['admin']
)


@admin_router.get("/get-all-approvals")
def get_approvals(db: Engine = Depends(get_db)):
    return db.execute("""CALL getApprovals()""").all()


@admin_router.put("/status-change/{approval_id}")
def change_status(approval: Approval, approval_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    trans = conn.begin()
    edited_approval = db.execute(f"""CALL editApprovalStatus(%s, %s)""", (int(approval_id), str(approval.status))).first()
    trans.commit()
    return edited_approval
