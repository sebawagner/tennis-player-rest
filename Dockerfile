FROM eclipse-temurin:21-jdk-alpine as build
WORKDIR /workspace/app

COPY gradle gradle
COPY build.gradle settings.gradle gradlew ./
COPY src src

RUN ./gradlew bootJar -x test
RUN mkdir -p build/dependency && (cd build/dependency; jar -xf ../libs/*.jar)

FROM eclipse-temurin:21-jre-alpine
VOLUME /tmp

# Install curl and other debug tools
RUN apk add --no-cache curl jq bash

# Set New Relic variables
ENV NEW_RELIC_APP_NAME="Tennis Player Rest API"
ENV NEW_RELIC_LICENSE_KEY="YOUR_NEW_RELIC_LICENSE_KEY"
ENV NEW_RELIC_LOG_LEVEL="info"
# Set higher log level for debugging
ENV NEW_RELIC_LOG_LEVEL="finest"

# Download and install New Relic Java agent
RUN mkdir -p /opt/newrelic
RUN curl -o /tmp/newrelic.zip https://download.newrelic.com/newrelic/java-agent/newrelic-agent/current/newrelic-java.zip \
    && unzip /tmp/newrelic.zip -d /opt \
    && rm /tmp/newrelic.zip

ARG DEPENDENCY=/workspace/app/build/dependency
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app

# Copy New Relic config file from resources to agent directory
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes/newrelic.yml /opt/newrelic/

# Create a proper startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "========== DEBUGGING NEW RELIC CONFIGURATION ==========="' >> /start.sh && \
    echo 'echo "Checking New Relic installation and config:"' >> /start.sh && \
    echo 'ls -la /opt/newrelic' >> /start.sh && \
    echo 'echo ""' >> /start.sh && \
    echo 'echo "Contents of newrelic.yml file:"' >> /start.sh && \
    echo 'cat /opt/newrelic/newrelic.yml' >> /start.sh && \
    echo 'echo ""' >> /start.sh && \
    echo 'echo "Checking for production section in newrelic.yml:"' >> /start.sh && \
    echo 'grep -A 5 "production:" /opt/newrelic/newrelic.yml || echo "production section not found"' >> /start.sh && \
    echo 'echo ""' >> /start.sh && \
    echo 'echo "Environment variables:"' >> /start.sh && \
    echo 'echo "NEW_RELIC_APP_NAME: $NEW_RELIC_APP_NAME"' >> /start.sh && \
    echo 'echo "NEW_RELIC_LOG_LEVEL: $NEW_RELIC_LOG_LEVEL"' >> /start.sh && \
    echo 'echo "NEW_RELIC_LICENSE_KEY: [hidden for security]"' >> /start.sh && \
    echo 'echo ""' >> /start.sh && \
    echo 'echo "Starting application with New Relic agent..."' >> /start.sh && \
    echo 'java -javaagent:/opt/newrelic/newrelic.jar -cp app:app/lib/* org.nz.arrakeen.tennisplayerrest.TennisPlayerRestApplication' >> /start.sh && \
    chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
