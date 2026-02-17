// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {AaveV3Ethereum_PhaseTwoListing_20250924} from './AaveV3Ethereum_PhaseTwoListing_20250924.sol';

/**
 * @dev Deploy Horizon Phase Two Listing payload.
 *      After deployment, the Horizon executor multisig calls:
 *        executeTransaction(payloadAddress, 0, "execute()", "", true)
 *
 * deploy-command: make deploy-ledger contract=src/20250924_AaveV3Ethereum_PhaseTwoListing/PhaseTwoListing_20250924.s.sol:DeployEthereum chain=mainnet
 * verify-command: FOUNDRY_PROFILE=deploy npx catapulta-verify -b broadcast/PhaseTwoListing_20250924.s.sol/1/run-latest.json
 */
contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    new AaveV3Ethereum_PhaseTwoListing_20250924();
  }
}
