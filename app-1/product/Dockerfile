FROM public.ecr.aws/amazonlinux/amazonlinux:2023

WORKDIR /app

COPY product .

RUN chmod +x product
RUN yum install -y shadow-utils

RUN useradd product
USER product

CMD ["./product"]