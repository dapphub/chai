SOLC_VERSION="0.5.12"

all    :; dapp build
clean  :; dapp clean
deploy :; dapp create Chai
test:
	NETWORK=hevm ./bin/set_constants
	dapp --use solc:${SOLC_VERSION} test || NETWORK=mainnet ./bin/set_constants
	NETWORK=mainnet ./bin/set_constants
