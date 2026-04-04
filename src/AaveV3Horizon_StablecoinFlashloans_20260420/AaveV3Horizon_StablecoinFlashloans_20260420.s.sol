// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {IPoolConfigurator} from 'aave-v3-origin/contracts/interfaces/IPoolConfigurator.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveHorizonGovV3Helpers} from 'src/utils/AaveHorizonGovV3Helpers.sol';

/**
 * @dev Log Safe-ready calldata for enabling flashloans on GHO, USDC, RLUSD.
 * command: forge script src/AaveV3Horizon_StablecoinFlashloans_20260420/AaveV3Horizon_StablecoinFlashloans_20260420.s.sol:LogSafeCalldata --rpc-url mainnet -vvvv
 */
contract LogSafeCalldata is Script {
  function run() external view {
    AaveHorizonGovV3Helpers.Action[] memory actions = new AaveHorizonGovV3Helpers.Action[](3);
    actions[0] = AaveHorizonGovV3Helpers.Action({
      to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
      data: abi.encodeCall(
        IPoolConfigurator.setReserveFlashLoaning,
        (AaveV3EthereumHorizonAssets.GHO_UNDERLYING, true)
      )
    });
    actions[1] = AaveHorizonGovV3Helpers.Action({
      to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
      data: abi.encodeCall(
        IPoolConfigurator.setReserveFlashLoaning,
        (AaveV3EthereumHorizonAssets.USDC_UNDERLYING, true)
      )
    });
    actions[2] = AaveHorizonGovV3Helpers.Action({
      to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
      data: abi.encodeCall(
        IPoolConfigurator.setReserveFlashLoaning,
        (AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING, true)
      )
    });

    AaveHorizonGovV3Helpers.createOpsMultisigCalldata(actions);
  }
}
