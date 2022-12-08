import passlib.exc
import sqlalchemy.exc

from database import get_db
from sqlalchemy.engine import Engine
from fastapi import Response, status, HTTPException, Depends
from fastapi import APIRouter
from utils import hash, verify_password
from schemas import User, Credentials, Survey

end_user_router = APIRouter(
    prefix="/users",
    tags=['users']
)


@end_user_router.post("/add-user")
def add_new_user(user: User, db: Engine = Depends(get_db)):
    hashed_password = hash(user.password)  # hashed pw is stored in models.User.password
    conn = db.connect()
    with conn.begin() as trans:
        try:
            new_user = conn.execute(f"""CALL createUser(%s,%s,%s,%s,%s,%s)""", (str(hashed_password),
                                                                        str(user.type), str(user.name),
                                                                        str(user.address),
                                                                        str(user.email), str(user.campus))).first()
            trans.commit()
            return new_user
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




@end_user_router.get("/user", response_model_exclude_none=True)
def get_users(db: Engine = Depends(get_db)):
    return db.execute("""SELECT * FROM users""").all()


@end_user_router.post("/login", response_model_exclude_none=True)
def login(credentials: Credentials, db: Engine = Depends(get_db)):
    conn = db.connect()
    with conn.begin() as trans:
        try:
            conn = db.connect()
            trans = conn.begin()
            # in DB - find 1st matching username
            result = conn.execute(f"""SELECT * FROM users WHERE name = %s""", (str(credentials.username),)).first()
            trans.commit()
            if verify_password(credentials.password, result.password):
                return result  # if inputted pw matches stored(hashed) pw, return the user

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

        except AttributeError:
            print("***** AttributeError: Ensure username is valid *****")
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                                detail=f"Invalid login credentials")

        except passlib.exc.UnknownHashError:
            print("***** passlib.exc.UnknownHashError: User potentially has unhashed password stored in DB *****")
