# Image
FROM python:3.10.1-slim-buster
RUN apt-get update && apt-get install -y netcat

# Init
WORKDIR /app
COPY . /app/
RUN pip install --upgrade pip

# VENV
RUN python3 -m venv venv
RUN /bin/bash -c "source venv/bin/activate"

# Requirements
RUN pip install -r requirements.txt

# ENV
ENV FLASK_APP=app.py

# Database
RUN chmod +x init_database.sh
RUN /bin/sh init_database.sh

# Run
EXPOSE 5000
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000", "--debug"]
