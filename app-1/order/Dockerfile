FROM public.ecr.aws/amazonlinux/amazonlinux:2023

WORKDIR /app

COPY order .

RUN chmod +x order
RUN yum install -y shadow-utils

RUN useradd order
USER order

CMD ["./order"]