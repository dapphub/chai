#!/usr/bin/env bash
set -e
display_usage() {
  echo "Usage: ./set_constants.sh {mainnet|kovan|hevm}"
}
if [ "$#" -ne 1 ]; then
    display_usage
    exit 1
fi
if [ $1 = "mainnet" ]; then

#Mainnet deployment
CHAIN_ID=1
ADDRESS=0x06af07097c9eeb7fd685c692751d5c66db49c215
VAT=0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B
POT=0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7
JOIN=0x9759A6Ac90977b93B58547b4A71c78317f391A28
DAI=0x6B175474E89094C44Da98b954EedeAC495271d0F

elif [ $1 = "kovan" ]; then

#Kovan deployment
CHAIN_ID=42
ADDRESS=0x06af07097c9eeb7fd685c692751d5c66db49c215
VAT=0xbA987bDB501d131f766fEe8180Da5d81b34b69d9
POT=0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb
JOIN=0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c
DAI=0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
 
elif [ $1 = "hevm" ]; then

#Hevm test deployment

CHAIN_ID=99
ADDRESS=0xd122f8f92737fc00fb3d62d4ed9244d393663870
VAT=0x0F1c6673615352379AFC1a60e3D0234101D67eb2
POT=0xc351B89C286288B9201835f78dbbccaDA357671e
JOIN=0x2D6B98058E84Dcb8b57fb8C79613bD858af65975
DAI=0x959DC1D68ba3a9f6959239135bcbc854b781eb9a

else
    echo "unknown network"
    display_usage
    exit 1
fi
VERSION='1'
NAME="Chai"

DOMAIN_SEPARATOR=$(seth keccak \
     $(seth keccak $(seth --from-ascii "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"))\
$(echo $(seth keccak $(seth --from-ascii "$NAME"))\
$(seth keccak $(seth --from-ascii $VERSION))$(seth --to-uint256 $CHAIN_ID)\
$(seth --to-uint256 $ADDRESS) | sed 's/0x//g'))
sed -i -e "s/DOMAIN_SEPARATOR = .*;/DOMAIN_SEPARATOR = $DOMAIN_SEPARATOR;/g" ./src/chai.sol
sed -i -e "s/VatLike(.*);/VatLike($VAT);/g"    ./src/chai.sol
sed -i -e "s/PotLike(.*);/PotLike($POT);/g"    ./src/chai.sol
sed -i -e "s/JoinLike(.*);/JoinLike($JOIN);/g" ./src/chai.sol
sed -i -e "s/GemLike(.*);/GemLike($DAI);/g"    ./src/chai.sol
sed -i -e "s/GemLike(.*);/GemLike($DAI);/g"    ./src/chai.sol
sed -i -e "s/bytes(version)), .*,/bytes(version)), $CHAIN_ID,/g" ./src/chai.sol
