from pydantic import BaseModel, EmailStr
from pydantic.types import Optional


class User(BaseModel):
    campus: str
    email: EmailStr
    name: str
    password: str
    address: str
    type: str


class Credentials(BaseModel):
    username: str
    password: str


class Ticket(BaseModel):
    description: str
    user_id: int
    subject: str
    status: str
    priority: str
    date_created: str
    type: str


class Approval(BaseModel):
    status: str
    description: str
    type: str
    approval_id: Optional[int]


class Comment(BaseModel):
    comment_body: str
    tech_id: int
    ticket_id: int


class Survey(BaseModel):
    survey_body: str
    satisfaction_level: int
    user_id: int
    ticket_id: int
