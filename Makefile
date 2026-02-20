# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build --sizes
test   :; forge test -vvv

test-contract :; forge test --match-contract ${filter} -vv

# Deploys payload to list ACRED asset. `make deploy-acred`
deploy-acred :; 
	FOUNDRY_PROFILE=${CHAIN} forge script src/AaveV3Horizon_ACREDListing_20260217/ACREDListing_20260217.s.sol:DeployEthereum \
		--rpc-url ${CHAIN} --account ${ACCOUNT} --slow --gas-estimate-multiplier 150 \
		--chain ${CHAIN} --verifier-url ${VERIFIER_URL} \
		--sig "run()" \
		$(if ${DRY},, --broadcast --verify) \

# Utilities
download :; cast etherscan-source --chain ${chain} -d src/etherscan/${chain}_${address} ${address}
git-diff :
	@mkdir -p diffs
	@npx prettier ${before} ${after} --write
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md
