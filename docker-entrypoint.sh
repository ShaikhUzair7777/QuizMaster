#!/bin/sh
set -eu

: "${PORT:=8080}"
case "$PORT" in
    ''|*[!0-9]*)
        echo "PORT must be a numeric TCP port." >&2
        exit 1
        ;;
esac

sed -i "s/<Connector port=\"8080\"/<Connector port=\"${PORT}\"/" \
    "${CATALINA_HOME}/conf/server.xml"

exec "${CATALINA_HOME}/bin/catalina.sh" run
