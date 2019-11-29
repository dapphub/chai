#!/bin/bash
display_usage() {
  echo "Usage: <spender> <nonce> <allowed> [expiry]"
}

if [ $# -lt 3 ];  then
    disply_usage
    exit 1
fi

if [ -z ${ETH_FROM+x} ]; then
    echo "ETH_FROM must be set";
    exit 1
fi

#Domain separator data
VERSION='1'
NAME="Chai"
CHAIN_ID=1
ADDRESS=0x06af07097c9eeb7fd685c692751d5c66db49c215


DOMAIN_SEPARATOR=$(seth keccak \
     $(seth keccak $(seth --from-ascii "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"))\
$(echo $(seth keccak $(seth --from-ascii "$NAME"))\
$(seth keccak $(seth --from-ascii $VERSION))$(seth --to-uint256 $CHAIN_ID)\
$(seth --to-uint256 $ADDRESS) | sed 's/0x//g'))
#echo $DOMAIN_SEPARATOR

#Permit type data
permit_TYPEHASH=$(seth keccak $(seth --from-ascii "Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)"))
#echo $permit_TYPEHASH

#permit data
HOLDER=$ETH_FROM
SPENDER=$1
NONCE=$2
ALLOWED=$3
DEADLINE=${4:-0}

echo "Sign the following permit?"
echo "HOLDER $HOLDER"
echo "SPENDER $SPENDER"
echo "NONCE $NONCE"
echo "ALLOWED $ALLOWED"
echo "DEADLINE $DEADLINE"
#echo "domain separator:"
#echo $DOMAIN_SEPARATOR
#echo $permit_TYPEHASH

echo "Enter passphrase for $ETH_FROM"

MESSAGE=0x1901\
$(echo $DOMAIN_SEPARATOR\
$(seth keccak \
$permit_TYPEHASH\
$(echo $(seth --to-uint256 $HOLDER)\
$(seth --to-uint256 $SPENDER)\
$(seth --to-uint256 $NONCE)\
$(seth --to-uint256 $DEADLINE)\
$(seth --to-uint256 $ALLOWED)\
      | sed 's/0x//g')) \
      | sed 's/0x//g')
#echo "MESSAGE" $MESSAGE
SIG=$(ethsign msg --no-prefix --data $MESSAGE)
#echo $SIG
##JSON output
printf '{"permit": {"holder":"%s","spender":"%s","nonce":"%s", "expiry": "%s", "allowed": "%s", "v": "%s", "r": "%s", "s": "%s"}}\n' "$HOLDER" "$SPENDER" "$NONCE" "$DEADLINE" "$ALLOWED" $((0x$(echo "$SIG" | cut -c 131-132))) $(echo "$SIG" | cut -c 1-66) "0x"$(echo "$SIG" | cut -c 67-130)
