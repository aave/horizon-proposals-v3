// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3PayloadHorizonEthereum} from 'src/utils/AaveV3PayloadHorizonEthereum.sol';
import {IAaveV3ConfigEngine as IEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';

/**
 * @title Horizon Listing — mWIN & HINC
 * @author Aave Labs
 * @dev Lists mWIN (Midas / Wellington Management) and HINC (Neuberger Securitize High Income
 *      Tokenized Fund) as RWA collateral assets on the Horizon pool, each with a GHO eMode.
 *      Parameters follow the LlamaRisk recommendations:
 *      - mWIN: https://governance.aave.com/t/arfc-onboard-mwin-midas-wellington-management-to-aave-horizon/25536/9
 *      - HINC: https://governance.aave.com/t/arfc-onboard-hinc-neuberger-securitize-high-income-tokenized-fund-to-aave-horizon/25500/7
 */
contract AaveV3Horizon_mWINHINCListing_20261023 is AaveV3PayloadHorizonEthereum {
  address public constant MWIN = AaveV3EthereumHorizonCustom.MWIN_UNDERLYING;
  address public constant MWIN_PRICE_FEED = AaveV3EthereumHorizonCustom.MWIN_PRICE_FEED;
  uint8 public constant MWIN_EMODE_CATEGORY = 7;

  address public constant HINC = AaveV3EthereumHorizonCustom.HINC_UNDERLYING;
  address public constant HINC_PRICE_FEED = AaveV3EthereumHorizonCustom.HINC_PRICE_FEED;
  uint8 public constant HINC_EMODE_CATEGORY = 9;

  function newListingsCustom()
    public
    pure
    override
    returns (IEngine.ListingWithCustomImpl[] memory)
  {
    IEngine.ListingWithCustomImpl[] memory listingsCustom = new IEngine.ListingWithCustomImpl[](2);

    listingsCustom[0] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: MWIN,
        assetSymbol: 'mWIN',
        priceFeed: MWIN_PRICE_FEED,
        rateStrategyParams: AaveV3EthereumHorizonCustom.defaultRwaInterestRateInputData(),
        enabledToBorrow: EngineFlags.DISABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 67_00,
        liqThreshold: 72_00,
        liqBonus: 8_00,
        reserveFactor: EngineFlags.KEEP_CURRENT,
        supplyCap: 80,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: 0
      }),
      IEngine.TokenImplementations({
        aToken: AaveV3EthereumHorizonCustom.RWA_A_TOKEN_IMPL,
        vToken: AaveV3EthereumHorizonCustom.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL
      })
    );

    listingsCustom[1] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: HINC,
        assetSymbol: 'HINC',
        priceFeed: HINC_PRICE_FEED,
        rateStrategyParams: AaveV3EthereumHorizonCustom.defaultRwaInterestRateInputData(),
        enabledToBorrow: EngineFlags.DISABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 55_00,
        liqThreshold: 67_00,
        liqBonus: 8_00,
        reserveFactor: EngineFlags.KEEP_CURRENT,
        supplyCap: 10_000,
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
    IEngine.AssetEModeUpdate[] memory assetsEMode = new IEngine.AssetEModeUpdate[](4);

    // mWIN as collateral in the mWIN GHO eMode
    assetsEMode[0] = IEngine.AssetEModeUpdate({
      asset: MWIN,
      eModeCategory: MWIN_EMODE_CATEGORY,
      collateral: EngineFlags.ENABLED,
      borrowable: EngineFlags.DISABLED
    });

    // GHO as borrowable in the mWIN GHO eMode
    assetsEMode[1] = IEngine.AssetEModeUpdate({
      asset: AaveV3EthereumHorizonAssets.GHO_UNDERLYING,
      eModeCategory: MWIN_EMODE_CATEGORY,
      collateral: EngineFlags.DISABLED,
      borrowable: EngineFlags.ENABLED
    });

    // HINC as collateral in the HINC GHO eMode
    assetsEMode[2] = IEngine.AssetEModeUpdate({
      asset: HINC,
      eModeCategory: HINC_EMODE_CATEGORY,
      collateral: EngineFlags.ENABLED,
      borrowable: EngineFlags.DISABLED
    });

    // GHO as borrowable in the HINC GHO eMode
    assetsEMode[3] = IEngine.AssetEModeUpdate({
      asset: AaveV3EthereumHorizonAssets.GHO_UNDERLYING,
      eModeCategory: HINC_EMODE_CATEGORY,
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
    IEngine.EModeCategoryUpdate[] memory eModeCategories = new IEngine.EModeCategoryUpdate[](2);

    // mWIN GHO
    eModeCategories[0] = IEngine.EModeCategoryUpdate({
      eModeCategory: MWIN_EMODE_CATEGORY,
      ltv: 69_00,
      liqThreshold: 74_00,
      liqBonus: 8_00,
      label: 'mWIN GHO'
    });

    // HINC GHO
    eModeCategories[1] = IEngine.EModeCategoryUpdate({
      eModeCategory: HINC_EMODE_CATEGORY,
      ltv: 57_00,
      liqThreshold: 69_00,
      liqBonus: 8_00,
      label: 'HINC GHO'
    });

    return eModeCategories;
  }
}
