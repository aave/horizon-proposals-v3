// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3HorizonEthereum} from '../utils/AaveV3HorizonEthereum.sol';
import {AaveV3PayloadHorizonEthereum} from '../utils/AaveV3PayloadHorizonEthereum.sol';
import {IAaveV3ConfigEngine as IEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';

/**
 * @title Horizon Phase Three Listing — ACRED
 * @author Aave Labs
 * @dev Lists ACRED (Apollo Diversified Credit Securitize Fund) as an RWA collateral asset
 *      on the Horizon pool with an ACRED/GHO eMode.
 */
contract AaveV3Horizon_ACREDListing_20260217 is AaveV3PayloadHorizonEthereum {
  address public constant ACRED = 0x17418038ecF73BA4026c4f428547BF099706F27B;
  address public constant ACRED_PRICE_FEED = 0x60AEd7d20AC6328f7BA771aD58931c996aff30E8;
  uint8 public constant ACRED_EMODE_CATEGORY = 5;

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
        rateStrategyParams: IEngine.InterestRateInputData({
          optimalUsageRatio: 99_00,
          baseVariableBorrowRate: 0,
          variableRateSlope1: 0,
          variableRateSlope2: 0
        }),
        enabledToBorrow: EngineFlags.DISABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 66_00,
        liqThreshold: 76_00,
        liqBonus: 9_00,
        reserveFactor: EngineFlags.KEEP_CURRENT,
        supplyCap: 15_000_000,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: 0
      }),
      IEngine.TokenImplementations({
        aToken: AaveV3HorizonEthereum.RWA_ATOKEN_IMPL,
        vToken: AaveV3HorizonEthereum.VARIABLE_DEBT_TOKEN_IMPL
      })
    );

    return listingsCustom;
  }

  function assetsEModeUpdates() public pure override returns (IEngine.AssetEModeUpdate[] memory) {
    IEngine.AssetEModeUpdate[] memory assetsEMode = new IEngine.AssetEModeUpdate[](2);

    // ACRED as collateral in eMode 1
    assetsEMode[0] = IEngine.AssetEModeUpdate({
      asset: ACRED,
      eModeCategory: ACRED_EMODE_CATEGORY,
      collateral: EngineFlags.ENABLED,
      borrowable: EngineFlags.DISABLED
    });

    // GHO as borrowable in eMode 1
    assetsEMode[1] = IEngine.AssetEModeUpdate({
      asset: AaveV3HorizonEthereum.GHO_UNDERLYING,
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
      ltv: 90_00,
      liqThreshold: 92_00,
      liqBonus: 3_00,
      label: 'ACRED GHO'
    });

    return eModeCategories;
  }
}
