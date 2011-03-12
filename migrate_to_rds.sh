#!/usr/bin/env bash

SCRIPT_NAME=$0

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME OPTIONS


Required:
 -H DATABASE_HOST
 -D DATABASE_NAME        the database name
 -U DATABASE_USER        the database user
 -P DATABASE_PASSWORD    the database password

EOF
}

die() {
    message=$1
    error_code=$2

    echo "$SCRIPT_NAME: $message" 1>&2
    usage
    exit $error_code
}

while getopts "hH:D:U:P:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        H)
            export DATABASE_HOST="$OPTARG"
            ;;
        D)
            export DATABASE_NAME="$OPTARG"
            ;;
        U)
            export DATABASE_USER="$OPTARG"
            ;;
        P)
            export DATABASE_PASSWORD="$OPTARG"
            ;;
        [?])
            die "unknown option $opt" 10
            ;;
    esac
done

if [ -z "$DATABASE_HOST" ]; then
    die "URL is required" 1
fi

if [ -z "$DATABASE_NAME" ]; then
    die "DATABASE_NAME is required" 2
fi

if [ -z "$DATABASE_USER" ]; then
    die "DATABASE_NAME is required" 3
fi

if [ -z "$DATABASE_PASSWORD" ]; then
    die "DATABASE_PASSWORD is required" 4
fi

dump_sql() {
    mysqldump --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME > local_db_dump.sql
}

load_sql() {
    mysql --host=$DATABASE_HOST --user=$DATABASE_USER --password=$DATABASE_PASSWORD $DATABASE_NAME < local_db_dump.sql
}

dump_sql && load_sql
