// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';
import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IRevenueSplitter} from 'aave-v3-origin/contracts/treasury/IRevenueSplitter.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {EthereumScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

/**
 * @dev Calls splitRevenue on the Horizon RevenueSplitter for each relevant pool aToken
 * individually (try/catch) to handle underflows due to aToken rounding
 * command: forge script scripts/SplitHorizonRevenue.s.sol:SplitHorizonRevenue --rpc-url mainnet --account ${ACCOUNT} --broadcast
 */
contract SplitHorizonRevenue is EthereumScript {
  function run() external broadcast {
    IRevenueSplitter splitter = IRevenueSplitter(address(AaveV3EthereumHorizon.COLLECTOR));
    IPool pool = AaveV3EthereumHorizon.POOL;

    address[] memory reserves = new address[](3);
    reserves[0] = AaveV3EthereumHorizonAssets.USDC_UNDERLYING;
    reserves[1] = AaveV3EthereumHorizonAssets.GHO_UNDERLYING;
    reserves[2] = AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING;
    IERC20[] memory singleAsset = new IERC20[](1);

    for (uint16 i; i < reserves.length; i++) {
      address underlying = reserves[i];
      singleAsset[0] = IERC20(pool.getReserveAToken(underlying));
      try splitter.splitRevenue(singleAsset) {
        console.log('splitRevenue success for', address(singleAsset[0]));
      } catch {
        console.log('splitRevenue failed for', address(singleAsset[0]));
      }
    }
  }
}
