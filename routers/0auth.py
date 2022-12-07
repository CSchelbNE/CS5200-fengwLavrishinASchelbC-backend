# import sys
# sys.path.append('../')
# from fastapi import Depends,status,HTTPException
# from fastapi.security import OAuth2PasswordBearer
# from jose import JWTError, jwt #import the jwt token
# #Timedelta calculates the time different from whatever is passed in as its arguments
# from datetime import datetime, timedelta
#
#
# # Declares the URL that the client/user will use to send the password/username data to get a token
# oauth2_scheme = OAuth2PasswordBearer(tokenUrl='login')
#
#
# # Eventually move the secret_key #
# SECRET_KEY = '21897615e5b0c3b065d7756e08ade51271b0c5c645b0446871294a5470cab848'
# ALGORITHM = 'HS256'
# ACCESS_TOKEN_EXPIRATION_MINS = 45
#
# def create_access_token(data : dict):
#     # Do not modify the passed in data, this would be catastrophic
#     to_encode = data.copy()
#
#     #expire = The current time of authentication + 45 mins
#     expire = datetime.now() + timedelta(minutes=ACCESS_TOKEN_EXPIRATION_MINS)
#
#     # Add the expiration time to the dictionary passed in
#     to_encode.update({"exp":expire})
#
#     # Pass the dictionary to encode, the key and the algorithm to jose module
#     encoded_jwt_token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
#
#     # Return the token
#     return encoded_jwt_token
#
#
# def verify_access_token(token:str, credentials_exception):
#     try:
#         token_payload = jwt.decode(token, SECRET_KEY, algorithms=ALGORITHM)
#
#         # Can this code be reduced to less lines?
#         id :str = token_payload.get('userid')
#
#         if not id:
#             raise credentials_exception
#
#         token_data = schemas.TokenData(id=id)
#     # Error type from jose library
#     except JWTError:
#         raise credentials_exception
