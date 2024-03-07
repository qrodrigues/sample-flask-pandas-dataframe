flask shell << shell
from app import db;
db.create_all();
quit()
shell

flask load-data titanic-min.csv
