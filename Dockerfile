FROM python:3.9-alpine
LABEL org.opencontainers.image.authors="carmelo[DOT]califano[AT]gmail[DOT]com"

WORKDIR /srv
ADD app.py requirements.txt ./

RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 5000

ENTRYPOINT ["python3", "./app.py"]
