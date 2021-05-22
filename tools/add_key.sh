#!/bin/sh

NAME=$1
KEY=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | xxd -ps -c 32`

echo $NAME
echo $KEY
echo $NAME\?key=$KEY

redis-cli set $NAME $KEY
