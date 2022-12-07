from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")  # Defines the crypto scheme as bcrypt


# used to generate a hashed version of a plaintext string
def hash(password: str):
    return pwd_context.hash(password)


# Verifies if the stored hash mashes the input plaintext
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)