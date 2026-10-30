// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';
import {EthereumScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {GovV3Helpers} from 'aave-helpers/src/GovV3Helpers.sol';
import {AaveV3Horizon_mWINHINCListing_20261023} from './AaveV3Horizon_mWINHINCListing_20261023.sol';

/**
 * @dev Deploy Horizon mWIN & HINC Listing payload.
 * deploy-command: make deploy-payload
 */
contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    address payload = GovV3Helpers.deployDeterministic(
      type(AaveV3Horizon_mWINHINCListing_20261023).creationCode
    );
    console.log('payload:', payload);
  }
}
