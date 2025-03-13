# Use a Gradle image with Java 17 to build the application
FROM gradle:8.5-jdk17 AS build

# Set the working directory
WORKDIR /app

# Copy only the Gradle wrapper and build files first (for caching dependencies)
COPY gradle gradle
COPY gradlew .
COPY build.gradle .
COPY settings.gradle .

# Download dependencies first (improves build performance)
RUN ./gradlew dependencies --no-daemon

# Copy the source code and build the application
COPY src ./src
RUN ./gradlew clean build -x test --no-daemon

# Use a Java 17 runtime image to run the application
FROM eclipse-temurin:17-jre

# Set the working directory
WORKDIR /app

# Copy the built JAR file from the build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Expose port 8080
EXPOSE 8080

# Specify the command to run the application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
