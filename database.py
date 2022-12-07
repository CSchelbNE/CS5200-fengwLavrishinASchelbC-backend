import sqlalchemy as sql
from sqlalchemy.ext.declarative import declarative_base

REMOTE_DATABASE_URL = "mysql+pymysql://admin:cs5200final@database-1.c5mdh4lrufto.us-east-2.rds.amazonaws.com" \
                      "/ticket_system"

# aws remote server password is cs5200finalproject
engine = sql.create_engine(REMOTE_DATABASE_URL,
                           connect_args=dict(host='database-1.c5mdh4lrufto.us-east-2.rds.amazonaws.com', port=3306))
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