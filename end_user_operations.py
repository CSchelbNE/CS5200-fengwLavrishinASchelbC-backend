import passlib

from database import get_db
from sqlalchemy.engine import Engine
from fastapi import Response, status, HTTPException, Depends
from fastapi import APIRouter
from utils import hash, verify_password
from schemas import User, Credentials, Survey
from sqlalchemy.ext.asyncio.engine import AsyncEngine


end_user_router = APIRouter(
    prefix="/users",
    tags=['users']
)


@end_user_router.post("/add-user")
def add_new_user(user: User, db: AsyncEngine = Depends(get_db)):
    async with db.begin() as conn:
        hashed_password = hash(user.password)  # hashed pw is stored in models.User.password
        # conn = db.connect()
        # trans = conn.begin()
        new_user = await conn.execute(f"""CALL createUser(%s,%s,%s,%s,%s,%s)""", (str(hashed_password),
                                                    str(user.type), str(user.name), str(user.address),
                                                                            str(user.email), str(user.campus))).first()

        await db.dispose()
        return new_user


@end_user_router.get("/user", response_model_exclude_none=True)
def get_users(db: Engine = Depends(get_db)):
    # return db.execute("""SELECT * FROM users""").all()
    return db.execute("""CALL getUsers""").all()


@end_user_router.post("/login", response_model_exclude_none=True)
def login(credentials: Credentials, db: AsyncEngine = Depends(get_db)):
    async with db.begin() as conn:
        try:
            # in DB - find 1st matching username
            # result = conn.execute(f"""SELECT * FROM users WHERE name = %s""", (str(credentials.username),)).first()
            result = await conn.execute(f"""CALL getSpecificUser(%s)""", (str(credentials.username))).first()
            if verify_password(credentials.password, result.password):
                await db.dispose()
                return result  # if inputted pw matches stored(hashed) pw, return the user

        except AttributeError:
            print("***** AttributeError: Ensure username is valid *****")
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                                detail=f"Invalid login credentials")

        except passlib.exc.UnknownHashError:
            print("***** passlib.exc.UnknownHashError: User potentially has unhashed password stored in DB *****")





