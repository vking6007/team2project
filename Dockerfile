# Type 2: Build Inside Container Approach
# This Dockerfile packages the app + Java together

# Use base image with Java 21
FROM openjdk:21-jdk-slim

# Install curl for health checks (needed for Jenkins verification)
RUN apt-get update -qq && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the jar file (built by Jenkins or Maven)
COPY target/team2project-0.0.1-SNAPSHOT.jar app.jar

# Expose port
EXPOSE 8085

# Set timezone
ENV TZ=UTC

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8085/actuator/health || exit 1

# Run the jar
ENTRYPOINT ["java", "-jar", "app.jar"]

