#!/usr/bin/env bash
# bash generate random alphanumeric string
# ref: https://gist.github.com/earthgecko/3089509

# bash generate UUID
cat /proc/sys/kernel/random/uuid
od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'

# bash generate random 32 character alphanumeric string (upper and lowercase) 
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n1

# bash generate random 32 character alphanumeric string (lowercase only)
cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n1

# Random numbers in a range, more randomly distributed than $RANDOM which is not
# very random in terms of distribution of numbers.

# bash generate random number between 0 and 9
cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n1 | head --bytes 1

# bash generate random number between 0 and 99
NUMBER=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n1 | sed -e 's/^0*//' | head --bytes 2)
[[ "$NUMBER" == "" ]] && NUMBER=0

# bash generate random number between 0 and 999
NUMBER=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n1 | sed -e 's/^0*//' | head --bytes 3)
[[ "$NUMBER" == "" ]] && NUMBER=0