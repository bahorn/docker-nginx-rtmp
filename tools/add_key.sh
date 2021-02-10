#!/bin/sh

KEY=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | xxd -ps -c 32`

echo $KEY
redis-cli set $KEY true
