import sqlalchemy.exc
from database import get_db
from sqlalchemy.engine import Engine
from fastapi import status, HTTPException, Depends
from fastapi import APIRouter
from schemas import Approval

admin_router = APIRouter(
    prefix="/admin",
    tags=['admin']
)


@admin_router.get("/get-all-approvals")
def get_approvals(db: Engine = Depends(get_db)):
    conn = db.connect()
    with conn.begin() as trans:
        try:
            result =  db.execute("""CALL getApprovals()""").all()
            trans.commit()
            return result
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


@admin_router.put("/status-change/{approval_id}")
def change_status(approval: Approval, approval_id: int, db: Engine = Depends(get_db)):
    conn = db.connect()
    with conn.begin() as trans:
        try:
            edited_approval = db.execute(f"""CALL editApprovalStatus(%s, %s)""", (int(approval_id), str(approval.status))).first()
            trans.commit()
            return edited_approval
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
