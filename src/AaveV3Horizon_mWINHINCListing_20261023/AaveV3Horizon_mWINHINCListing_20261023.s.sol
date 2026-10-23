// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {AaveV3Horizon_mWINHINCListing_20261023} from './AaveV3Horizon_mWINHINCListing_20261023.sol';

/**
 * @dev Deploy Horizon mWIN & HINC Listing payload.
 * deploy-command: make deploy-payload
 */
contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    new AaveV3Horizon_mWINHINCListing_20261023();
  }
}
