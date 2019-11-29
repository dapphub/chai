all    :; dapp build
clean  :; dapp clean
deploy :; dapp create Chai
test:
	NETWORK=hevm ./bin/set_constants
	dapp test || NETWORK=mainnet ./bin/set_constants
	NETWORK=mainnet ./bin/set_constants
