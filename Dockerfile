FROM maven:3.8.3-openjdk-17 as builder

COPY src /usr/src/app/src
COPY pom.xml /usr/src/app

RUN mvn -f /usr/src/app/pom.xml clean package

FROM  eclipse-temurin:17-jre-alpine

RUN adduser --no-create-home -u 1000 -D appuser

# Configure working directory
RUN mkdir /app && chown -R appuser /app

USER 1000

COPY --from=builder /usr/src/app/target/side-project-0.0.1-SNAPSHOT.jar /app/app.jar

WORKDIR /app

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
