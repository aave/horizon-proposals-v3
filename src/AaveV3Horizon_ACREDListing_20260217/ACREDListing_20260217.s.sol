// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {AaveV3Horizon_ACREDListing_20260217} from './AaveV3Horizon_ACREDListing_20260217.sol';

/**
 * @dev Deploy Horizon ACRED Listing payload.
 * deploy-command: make deploy-payload
 */
contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    new AaveV3Horizon_ACREDListing_20260217();
  }
}
