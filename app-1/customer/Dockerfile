FROM public.ecr.aws/amazonlinux/amazonlinux:2023

WORKDIR /app

COPY customer .

RUN chmod +x customer
RUN yum install -y shadow-utils

RUN useradd customer
USER customer

CMD ["./customer"]