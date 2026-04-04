// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3EthereumAssets} from 'aave-address-book-latest/AaveV3Ethereum.sol';
import {AaveV3PayloadHorizonEthereum} from 'src/utils/AaveV3PayloadHorizonEthereum.sol';
import {IAaveV3ConfigEngine as IEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';

/**
 * @title RLUSD Price Feed Update on Horizon
 * @author Aave Labs
 * @dev Switch RLUSD oracle to the CAPO adapter (same feed used on AaveV3Ethereum core).
 */
contract AaveV3Horizon_RLUSD_PriceFeed_20260404 is AaveV3PayloadHorizonEthereum {
  function priceFeedsUpdates() public pure override returns (IEngine.PriceFeedUpdate[] memory) {
    IEngine.PriceFeedUpdate[] memory updates = new IEngine.PriceFeedUpdate[](1);
    updates[0] = IEngine.PriceFeedUpdate({
      asset: AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING,
      priceFeed: AaveV3EthereumAssets.RLUSD_ORACLE
    });
    return updates;
  }
}
