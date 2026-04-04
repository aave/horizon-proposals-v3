// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';
import {EthereumScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {AaveHorizonGovV3Helpers} from 'src/utils/AaveHorizonGovV3Helpers.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveV3Horizon_RLUSD_PriceFeed_20260404} from './AaveV3Horizon_RLUSD_PriceFeed_20260404.sol';

/**
 * @dev Deploy the payload and log Safe-ready calldata for Emergency MS execution.
 * command: make deploy-payload
 */
contract DeployEthereum is EthereumScript {
  function run() external {
    vm.startBroadcast();
    address payload = address(new AaveV3Horizon_RLUSD_PriceFeed_20260404());
    vm.stopBroadcast();

    (address to, bytes memory data, uint8 operation) = AaveHorizonGovV3Helpers
      .createExecutorCalldata(payload);

    console.log('=== Safe Transaction ===');
    console.log('safe:', AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY);
    console.log('to:', to);
    console.log('operation:', operation);
    console.log('calldata:');
    console.logBytes(data);
  }
}
