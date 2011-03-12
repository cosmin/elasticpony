#!/usr/bin/env bash

SCRIPT_NAME=$0

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME OPTIONS


Required:
 -b BUCKET_NAME          the bucket name
 -l LOCATION             the local path to upload (recursively)

Credentials:
 -k ACCESS_KEY           the AWS access key. From your Security Credentials
 -s AWS_SECRET_KEY       the AWS secret key. From your Security Credentials
EOF
}

die() {
    message=$1
    error_code=$2

    echo "$SCRIPT_NAME: $message" 1>&2
    usage
    exit $error_code
}

while getopts "hb:l:k:s:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        b)
            export BUCKET_NAME="$OPTARG"
            ;;
        l)
            export LOCATION="$OPTARG"
            ;;
        k)
            export ACCESS_KEY="$OPTARG"
            ;;
        s)
            SECRET_KEY="$OPTARG"
            touch ~/.aws.secret.key
            chmod 600 ~/.aws.secret.key
            echo -n "$SECRET_KEY" > ~/.aws.secret.key
            SECRET_KEY_FILE="$HOME/.aws.secret.key"
            ;;
        [?])
            die "unknown option $opt" 10
            ;;
        esac
done


if [ -z "$BUCKET_NAME" ]; then
    die "BUCKET_NAME is required" 1
fi

if [ -z "$LOCATION" ]; then
    die "LOCATION is required" 2
else
    if [ ! -d "$LOCATION" ]; then
        die "LOCATION must point to a directory that exists" 3
    else
        export LOCATION_PATH=$(cd $LOCATION && pwd)
    fi
fi

if [ -z "$ACCESS_KEY" ]; then
    die "ACCESS_KEY is required" 4
fi

if [ -z "SECRET_KEY" ]; then
    die "SECRET_KEY is required" 5
fi

extract_s3_bash() {
    wget https://s3.amazonaws.com/cloudinitfiles/s3-bash.tgz
    tar zxvf s3-bash.tgz
}

get_mime() {
    python -c "import mimetypes; print mimetypes.guess_type(\"$1\")[0] or \"text/plain\""
}

upload_files() {
    HEADER_FILE=`mktemp -t xzawsXXXXXX`
    echo "X-Amz-Acl: public-read" > $HEADER_FILE
    for file in `find $LOCATION_PATH -type f | sed "s|$LOCATION_PATH/||g"`; do
        FULL_PATH="$LOCATION_PATH/$file"
        MIME=`get_mime $FULL_PATH`
        ./s3-bash/s3-put -a "$HEADER_FILE" -k "$ACCESS_KEY" -s "$SECRET_KEY_FILE" -T "$FULL_PATH" -c "$MIME" "/$BUCKET_NAME/$file"
    done
    rm $HEADER_FILE
}

extract_s3_bash
upload_files
