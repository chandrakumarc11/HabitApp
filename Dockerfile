# ---------- Build stage ----------
FROM maven:3.9.12-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src

RUN mvn clean package -DskipTests


# ---------- Runtime stage ----------
FROM eclipse-temurin:21-jre

WORKDIR /app

RUN groupadd --system appgroup \
    && useradd --system --gid appgroup appuser

COPY --from=builder /app/target/habit-tracker.jar app.jar

RUN chown appuser:appgroup /app/app.jar

USER appuser

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]
