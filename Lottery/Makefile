-include .env

.PHONY:all test deploy

build :; forge build

test :; forge test

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit

deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account hasu_acc --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv



verify-contract-manually:
forge verify-contract <CONTRACT ADDRESS> src/Raffle.sol:Raffle --etherscan-api-key $(ETHERSCAN_API_KEY) --rpc-url $(SEPOLIA_RPC_URL) --show-standard-json-input > json.json
// [0x7C35FD39cd7Fd5dB2C8d691bC3B00cB19F65C2A4]
