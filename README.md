# Redis-getting-started
Just a tiny app to play with Redis

### The "manual" setup
Let's start by pulling (i.e. downloading) the images we'll be using:
```
$ docker pull redis:latest
$ docker pull python:3.9-alpine
```

The tiny app we'll be using is built on top of Flask and Redis modules:
```
from flask import Flask
from redis import Redis

app = Flask(__name__)
redis = Redis(host='redis', port=6379)

@app.route('/')
def hello():
    redis.incr('hits')
    return 'Hello World! I have been seen %s times.' % redis.get('hits')

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
```

Our app will run in a container whose definition is stored in a Dockerfile:
```
FROM python:3.9-alpine
MAINTAINER carmelo.califano@gmail.com

WORKDIR /srv
ADD app.py requirements.txt ./

RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 5000

ENTRYPOINT ["python3", "./app.py"]
```

Building the image is as simple as:
```
$ docker build -t carmelo0x99/redisweb:1.0 .
Sending build context to Docker daemon  121.3kB
Step 1/7 : FROM python:3.9-alpine
 ---> d314e28e240c
...
Step 6/7 : EXPOSE 5000
 ---> Running in ef11de81484a
Removing intermediate container ef11de81484a
 ---> ee45642365bb
Step 7/7 : ENTRYPOINT ["python3", "./app.py"]
 ---> Running in dfdf29e6eec2
Removing intermediate container dfdf29e6eec2
 ---> f063e545a62a
Successfully built f063e545a62a
Successfully tagged carmelo0x99/redisweb:1.0
```

A Docker network must be created so that the two containers can communicate:
```
$ docker network create redisnet
```

We can now spin up the containers and attach them to their own custom network:
```
$ docker run -d --rm --name redis redis:latest

$ docker run -d --rm --name web -p 5000:5000 carmelo0x99/redisweb:1.0

$ docker network connect redisnet redis

$ docker network connect redisnet web
```
**NOTE**: Redis listens on port 6379 but there's no need to publish the port externally, as only the "web" container will access it</br>
A test immediately shows that our app is running:
```
$ curl http://127.0.0.1:5000/
Hello World! I have been seen 1 times.%
```

To clean up:
```
$ docker stop redis
$ docker stop web
```

### The "declarative" method
A much recommended declarative approach allows us to define the desired setup through a configuration file. We'll use the following:
```
version: "3"

services:
  web:
    build: .
    command: python3 app.py
    container_name: web
    ports:
      - "5000:5000"
    networks:
      - redisnet
  redis:
    image: redis:latest
    container_name: redis
    networks:
      - redisnet

networks:
  redisnet:
    name: redisnet
```

The setup can be brought up with one single command as follows:
```
$ docker compose up -d
Creating web   ... done
Creating redis ... done
```

And the overall status can be shown as:
```
$ docker compose ps
NAME      COMMAND                  SERVICE     STATUS      PORTS
redis     "docker-entrypoint.s…"   redis       running     6379/tcp
web       "python3 ./app.py py…"   web         running     0.0.0.0:5000->5000/tcp, :::5000->5000/tcp
```

Notice how Redis starts counting the hits from scratch:
```
$ curl http://127.0.0.1:5000/
Hello World! I have been seen 1 times.%
```

Finally, to stop the services:
```
$ docker compose kill
Killing redis ... done
Killing web   ... done
```

### The fun part
Before stopping the services or while Redis is running in manual mode, one can log into Redis and interact with the DB manually:
```
$ docker exec -it redis bash
root@07736a5622e9:/data# redis-cli

127.0.0.1:6379> ping
PONG

127.0.0.1:6379> get hits
"1"

127.0.0.1:6379> quit

root@07736a5622e9:/data# exit
```

### More info
[Redis Quick Start](https://redis.io/topics/quickstart)

