import sqlalchemy as sql
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

REMOTE_DATABASE_URL = "mysql+pymysql://admin:cs5200finalproject@database-1.c5mdh4lrufto.us-east-2.rds.amazonaws.com" \
                      "/ticket_system"


username = "root"
password = "F1shg0d12345!"
# NO SPECIAL CHARACTERS IN THE PASSWORD THAT MIGHT CONFLICT WITH THE LOCALHOST STRING PARSING (@ IS BAD)
LOCAL_HOST_URL = "mysql+pymysql://" + username + ":" + \
                 password + "@localhost"

REMOTE_DATABASE_URL = "mysql+pymysql://admin:cs5200final@database-1.c5mdh4lrufto.us-east-2.rds.amazonaws.com" \
                      "/ticket_system"

# aws remote server password is cs5200finalproject
engine = sql.create_engine(LOCAL_HOST_URL,
                           connect_args=dict(host='localhost', port=3306))
while True:
    try:
        conn = engine.connect()
        Base = declarative_base()
        # session = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        conn.execute("USE ticket_system")
        print("Database connection was successful")
        break
    except Exception as error:
        print("Connection failed")
        print("Error:" + error.__str__())


def get_db():
    # db = session()
    try:
        yield conn
    finally:
        pass
    #     db.close()

