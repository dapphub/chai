#Domain separator data
#Mainnet deployment
VERSION='1'
NAME="Chai"
CHAIN_ID=1
ADDRESS=0x06af07097c9eeb7fd685c692751d5c66db49c215


DOMAIN_SEPARATOR=$(seth keccak \
     $(seth keccak $(seth --from-ascii "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"))\
$(echo $(seth keccak $(seth --from-ascii "$NAME"))\
$(seth keccak $(seth --from-ascii $VERSION))$(seth --to-uint256 $CHAIN_ID)\
$(seth --to-uint256 $ADDRESS) | sed 's/0x//g'))
echo $DOMAIN_SEPARATOR
