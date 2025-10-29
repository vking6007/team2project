# Multi-stage build for Spring Boot app

# 1) Build stage
FROM maven:3.9.6-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn -q -e -B -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -e -B -DskipTests clean package

# 2) Runtime stage
FROM eclipse-temurin:21-jre
ENV JAVA_OPTS=""
ENV APP_PORT=8085
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8085
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

