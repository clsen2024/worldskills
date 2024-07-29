FROM public.ecr.aws/docker/library/python:3.9-alpine

WORKDIR /app
COPY app.py ./

RUN apk --no-cache add curl
RUN pip3 install flask

CMD ["python3", "app.py"]