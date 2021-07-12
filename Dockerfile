FROM maven:3.8.1-openjdk-17-slim

MAINTAINER Rajesh Reddy <rajesh804@gmail.com>

RUN mkdir -p /swym
COPY target/helloworld*.jar /swym/helloworld.jar

COPY docker-entrypoint.sh /swym/docker-entrypoint.sh
RUN chmod +x /swym/docker-entrypoint.sh

WORKDIR /swym/

EXPOSE 8080

ENTRYPOINT ["/swym/docker-entrypoint.sh"]
CMD ["java"]
