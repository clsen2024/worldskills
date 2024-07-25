FROM python:3.12-alpine
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
RUN apk update
RUN apk add curl  
CMD ["python3", "main.py"]