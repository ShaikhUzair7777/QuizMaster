FROM maven:3.9-eclipse-temurin-25 AS build

WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn --batch-mode --no-transfer-progress clean verify

FROM eclipse-temurin:25-jre

ARG TOMCAT_VERSION=10.1.61
ARG TOMCAT_SHA512=35120a2b1182bac3d55438fbec0dc581d03b0f1c16ce692a930f3bb6a1097cf896b94b389152257071a87cb2928ac8c15f1bad08387c14acc7c17dbc1bb598fb

ENV CATALINA_HOME=/opt/tomcat
ENV PATH="${CATALINA_HOME}/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl tar \
    && curl --fail --silent --show-error --location \
        "https://archive.apache.org/dist/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
        --output /tmp/tomcat.tar.gz \
    && echo "${TOMCAT_SHA512}  /tmp/tomcat.tar.gz" | sha512sum --check --status \
    && mkdir -p "${CATALINA_HOME}" \
    && tar -xzf /tmp/tomcat.tar.gz --strip-components=1 -C "${CATALINA_HOME}" \
    && rm -f /tmp/tomcat.tar.gz \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --home-dir "${CATALINA_HOME}" --shell /usr/sbin/nologin quizmaster \
    && chown -R quizmaster:quizmaster "${CATALINA_HOME}"

WORKDIR ${CATALINA_HOME}
COPY --from=build --chown=quizmaster:quizmaster \
    /workspace/target/quizmaster.war ${CATALINA_HOME}/webapps/quizmaster.war
COPY --chown=quizmaster:quizmaster docker-entrypoint.sh /usr/local/bin/quizmaster-entrypoint
RUN chmod 755 /usr/local/bin/quizmaster-entrypoint

EXPOSE 8080
USER quizmaster
ENTRYPOINT ["/usr/local/bin/quizmaster-entrypoint"]
