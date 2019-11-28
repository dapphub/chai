all    :; dapp build
clean  :; dapp clean
test   :; ./bin/set_constants.sh hevm && dapp test && ./bin/set_constants.sh mainnet
deploy :; dapp create Sdai
