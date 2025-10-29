# ===============================
# Dockerfile for team2project
# ===============================

# Use lightweight JDK 21 base image
FROM openjdk:21-jdk-slim

# Install curl for health check support
RUN apt-get update -qq && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Spring Boot jar file (built by Maven in Jenkins)
COPY target/team2project-0.0.1-SNAPSHOT.jar app.jar

# Expose internal Spring Boot port
EXPOSE 8085

# Set timezone for consistency
ENV TZ=Asia/Kolkata

# Default environment variables (can be overridden by Jenkins)
ENV SPRING_PROFILES_ACTIVE=dev \
    SERVER_PORT=8085

# Run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
