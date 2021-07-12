#!/bin/sh
set -e

if [ "$1" = "java" ]; then
	java ${JAVA_OPTIONS} -jar /swym/helloworld.jar
fi
exec "$@"
