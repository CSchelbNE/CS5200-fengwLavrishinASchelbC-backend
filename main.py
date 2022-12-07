from fastapi import FastAPI # Fast api framework
from starlette.middleware.cors import CORSMiddleware
from end_user_operations import end_user_router
from ticket_operations import ticket_router
from admin_operations import admin_router
from technician_operations import technician_router

'''
Big cheats:
loopbackaddress:port/docs <- This gives you the natively generated documentation
for your api created by swagger_ui.
loopbackaddress:port/redoc <- Redoc documentation
"""CREATE TABLE UserID (email_address varchar(255) PRIMARY KEY);"""
^exceute syntax
'''
#To get automatic refresh -> uvicorn main:app --reload
#git

# Causes the models in models.py to generate their respective relational tables in the db on run
app = FastAPI()


app.include_router(end_user_router)
app.include_router(ticket_router)
app.include_router(admin_router)
app.include_router(technician_router)

# app.include_router(auth.router)
#
# Handles cross origin requests from front and backend
origins = [
    "http://localhost:3000",
    "https://localhost:3000/",
    "localhost:3000/*",
    "https://storied-cheesecake-d437f5.netlify.app:0/"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)
#
# if __name__ == "__main__":
#     uvicorn.run("main:app", host="localhost", port=8000, reload=True)