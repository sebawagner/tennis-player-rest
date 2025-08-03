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

# Add debug script to verify New Relic configuration at startup
RUN echo '#!/bin/bash \n\
echo "========== DEBUGGING NEW RELIC CONFIGURATION ==========" \n\
echo "Checking New Relic installation and config:" \n\
ls -la /opt/newrelic \n\
echo "\\nContents of newrelic.yml file:" \n\
cat /opt/newrelic/newrelic.yml \n\
echo "\\nChecking for production section in newrelic.yml:" \n\
grep -A 5 "production:" /opt/newrelic/newrelic.yml \n\
echo "\\nEnvironment variables:" \n\
echo "NEW_RELIC_APP_NAME: $NEW_RELIC_APP_NAME" \n\
echo "NEW_RELIC_LOG_LEVEL: $NEW_RELIC_LOG_LEVEL" \n\
echo "NEW_RELIC_LICENSE_KEY: [hidden for security]" \n\
echo "\\nStarting application with New Relic agent..." \n\
echo "==========================================================" \n\
exec java -javaagent:/opt/newrelic/newrelic.jar -cp app:app/lib/* org.nz.arrakeen.tennisplayerrest.TennisPlayerRestApplication \n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Use the debug entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
