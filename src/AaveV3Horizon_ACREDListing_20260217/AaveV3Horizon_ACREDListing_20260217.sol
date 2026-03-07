// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3PayloadHorizonEthereum} from 'src/utils/AaveV3PayloadHorizonEthereum.sol';
import {IAaveV3ConfigEngine as IEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';

/**
 * @title Horizon Phase Three Listing — ACRED
 * @author Aave Labs
 * @dev Lists ACRED (Apollo Diversified Credit Securitize Fund) as an RWA collateral asset
 *      on the Horizon pool with an ACRED/GHO eMode.
 */
contract AaveV3Horizon_ACREDListing_20260217 is AaveV3PayloadHorizonEthereum {
  address public constant ACRED = AaveV3EthereumHorizonCustom.ACRED_UNDERLYING;
  address public constant ACRED_PRICE_FEED = AaveV3EthereumHorizonCustom.ACRED_PRICE_FEED;
  uint8 public constant ACRED_EMODE_CATEGORY = 3;

  function newListingsCustom()
    public
    pure
    override
    returns (IEngine.ListingWithCustomImpl[] memory)
  {
    IEngine.ListingWithCustomImpl[] memory listingsCustom = new IEngine.ListingWithCustomImpl[](1);

    listingsCustom[0] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: ACRED,
        assetSymbol: 'ACRED',
        priceFeed: ACRED_PRICE_FEED,
        rateStrategyParams: AaveV3EthereumHorizonCustom.defaultRwaInterestRateInputData(),
        enabledToBorrow: EngineFlags.DISABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 66_00,
        liqThreshold: 76_00,
        liqBonus: 9_00,
        reserveFactor: EngineFlags.KEEP_CURRENT,
        supplyCap: 30_000,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: 0
      }),
      IEngine.TokenImplementations({
        aToken: AaveV3EthereumHorizonCustom.RWA_A_TOKEN_IMPL,
        vToken: AaveV3EthereumHorizonCustom.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL
      })
    );

    return listingsCustom;
  }

  function assetsEModeUpdates() public pure override returns (IEngine.AssetEModeUpdate[] memory) {
    IEngine.AssetEModeUpdate[] memory assetsEMode = new IEngine.AssetEModeUpdate[](2);

    // ACRED as collateral in eMode 3
    assetsEMode[0] = IEngine.AssetEModeUpdate({
      asset: ACRED,
      eModeCategory: ACRED_EMODE_CATEGORY,
      collateral: EngineFlags.ENABLED,
      borrowable: EngineFlags.DISABLED
    });

    // GHO as borrowable in eMode 3
    assetsEMode[1] = IEngine.AssetEModeUpdate({
      asset: AaveV3EthereumHorizonAssets.GHO_UNDERLYING,
      eModeCategory: ACRED_EMODE_CATEGORY,
      collateral: EngineFlags.DISABLED,
      borrowable: EngineFlags.ENABLED
    });

    return assetsEMode;
  }

  function eModeCategoriesUpdates()
    public
    pure
    override
    returns (IEngine.EModeCategoryUpdate[] memory)
  {
    IEngine.EModeCategoryUpdate[] memory eModeCategories = new IEngine.EModeCategoryUpdate[](1);

    // ACRED GHO
    eModeCategories[0] = IEngine.EModeCategoryUpdate({
      eModeCategory: ACRED_EMODE_CATEGORY,
      ltv: 68_00,
      liqThreshold: 78_00,
      liqBonus: 9_00,
      label: 'ACRED GHO'
    });

    return eModeCategories;
  }
}
