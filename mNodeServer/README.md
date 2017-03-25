generate demo user:
node example.js


==========================================

status code:
server side
8899 : "forbid connect"
8900 : "jwt payload is null"
4400 : "no user in db"
4000 : "jwt expired"
4001 : "login fail!"
4002 : "no payload"
client side
5000 : "jwt verify failed"
5001 : "aes decrypt Failed"