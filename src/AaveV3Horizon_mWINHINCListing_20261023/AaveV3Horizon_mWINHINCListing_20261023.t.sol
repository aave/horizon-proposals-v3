// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IAToken} from 'aave-v3-origin/contracts/interfaces/IAToken.sol';
import {IDefaultInterestRateStrategyV2} from 'aave-v3-origin/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import {IRwaOracleParameterRegistry} from 'src/interfaces/IRwaOracleParameterRegistry.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3Horizon_mWINHINCListing_20261023} from 'src/AaveV3Horizon_mWINHINCListing_20261023/AaveV3Horizon_mWINHINCListing_20261023.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3Ethereum} from 'aave-address-book-latest/AaveV3Ethereum.sol';

abstract contract AaveV3Horizon_mWINHINCListing_20261023_TestBase is ProtocolV3HorizonTestBase {
  struct ExpectedLlamaGuardConfig {
    address underlying;
    uint64 maxExpectedApy;
    uint32 upperBoundTolerance;
    uint32 lowerBoundTolerance;
    uint32 maxDiscount;
    uint80 lookbackWindowSize;
  }

  AaveV3Horizon_mWINHINCListing_20261023 internal proposal;

  ExpectedAssetConfig internal expectedMwinConfig;
  ExpectedEModeConfig internal expectedMwinEModeConfig;
  ExpectedLlamaGuardConfig internal expectedMwinLlamaGuardConfig;
  ExpectedAssetConfig internal expectedHincConfig;
  ExpectedEModeConfig internal expectedHincEModeConfig;
  ExpectedLlamaGuardConfig internal expectedHincLlamaGuardConfig;

  function setUp() public virtual {
    _setExpectedConfig();
  }

  function _setExpectedConfig() internal virtual override {
    expectedMwinConfig = ExpectedAssetConfig({
      underlying: AaveV3EthereumHorizonCustom.MWIN_UNDERLYING,
      isRwa: true,
      oracle: AaveV3EthereumHorizonCustom.MWIN_PRICE_FEED,
      aTokenName: 'Aave Horizon RWA mWIN',
      aTokenSymbol: 'aHorRwamWIN',
      variableDebtTokenName: 'Aave Horizon RWA Variable Debt mWIN',
      variableDebtTokenSymbol: 'variableDebtHorRwamWIN',
      supplyCap: 80,
      borrowCap: 0,
      reserveFactor: 0,
      borrowingEnabled: false,
      flashloanable: false,
      ltv: 67_00,
      liquidationThreshold: 72_00,
      liquidationBonus: 100_00 + 8_00,
      debtCeiling: 0,
      liqProtocolFee: 0,
      rateData: IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: 99_00,
        baseVariableBorrowRate: 0,
        variableRateSlope1: 0,
        variableRateSlope2: 0
      })
    });
    expectedMwinEModeConfig = ExpectedEModeConfig({
      eModeCategory: 7,
      ltv: 69_00,
      liquidationThreshold: 74_00,
      liquidationBonus: 100_00 + 8_00,
      label: 'mWIN GHO',
      collateralAssets: _toAddressArray(AaveV3EthereumHorizonCustom.MWIN_UNDERLYING),
      borrowableAssets: _toAddressArray(AaveV3EthereumHorizonAssets.GHO_UNDERLYING)
    });
    expectedMwinLlamaGuardConfig = ExpectedLlamaGuardConfig({
      underlying: AaveV3EthereumHorizonCustom.MWIN_UNDERLYING,
      maxExpectedApy: 8_00,
      upperBoundTolerance: 50,
      lowerBoundTolerance: 1_00,
      maxDiscount: 2_50,
      lookbackWindowSize: 4
    });

    expectedHincConfig = ExpectedAssetConfig({
      underlying: AaveV3EthereumHorizonCustom.HINC_UNDERLYING,
      isRwa: true,
      oracle: AaveV3EthereumHorizonCustom.HINC_PRICE_FEED,
      aTokenName: 'Aave Horizon RWA HINC',
      aTokenSymbol: 'aHorRwaHINC',
      variableDebtTokenName: 'Aave Horizon RWA Variable Debt HINC',
      variableDebtTokenSymbol: 'variableDebtHorRwaHINC',
      supplyCap: 10_000,
      borrowCap: 0,
      reserveFactor: 0,
      borrowingEnabled: false,
      flashloanable: false,
      ltv: 55_00,
      liquidationThreshold: 67_00,
      liquidationBonus: 100_00 + 8_00,
      debtCeiling: 0,
      liqProtocolFee: 0,
      rateData: IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: 99_00,
        baseVariableBorrowRate: 0,
        variableRateSlope1: 0,
        variableRateSlope2: 0
      })
    });
    expectedHincEModeConfig = ExpectedEModeConfig({
      eModeCategory: 9,
      ltv: 57_00,
      liquidationThreshold: 69_00,
      liquidationBonus: 100_00 + 8_00,
      label: 'HINC GHO',
      collateralAssets: _toAddressArray(AaveV3EthereumHorizonCustom.HINC_UNDERLYING),
      borrowableAssets: _toAddressArray(AaveV3EthereumHorizonAssets.GHO_UNDERLYING)
    });
    expectedHincLlamaGuardConfig = ExpectedLlamaGuardConfig({
      underlying: AaveV3EthereumHorizonCustom.HINC_UNDERLYING,
      maxExpectedApy: 8_00,
      upperBoundTolerance: 50,
      lowerBoundTolerance: 2_00,
      maxDiscount: 2_50,
      lookbackWindowSize: 4
    });
  }
}

/**
 * @dev Test for Horizon mWIN & HINC listing (pre-execution).
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_mWINHINCListing_20261023_Test -vv
 */
contract AaveV3Horizon_mWINHINCListing_20261023_Test is
  AaveV3Horizon_mWINHINCListing_20261023_TestBase
{
  function setUp() public virtual override {
    super.setUp();
    vm.createSelectFork(vm.rpcUrl('mainnet'), 26254000);
    proposal = new AaveV3Horizon_mWINHINCListing_20261023();
  }

  /**
   * @dev executes the generic test suite including e2e and config snapshots
   */
  function _executeListing() internal {
    _executeHorizonPayload(address(proposal));
  }

  function test_defaultProposalExecution() public virtual {
    defaultTest_v3_3('AaveV3Horizon_mWINHINCListing_20261023', _pool(), _executeListing);
  }

  /**
   * @dev verifies the exact config values set for mWIN and its GHO eMode
   */
  function test_mwinConfig() public virtual {
    IPool pool = _pool();
    _assertEModeCategoryUnused(pool, proposal.MWIN_EMODE_CATEGORY());

    // execute payload
    _executeHorizonPayload(address(proposal));

    _assertAssetConfig(pool, expectedMwinConfig);
    _assertEModeConfig(pool, expectedMwinEModeConfig);
    _assertTreasuryIsCollector(pool, AaveV3EthereumHorizonCustom.MWIN_UNDERLYING);
  }

  /**
   * @dev verifies the exact config values set for HINC and its GHO eMode
   */
  function test_hincConfig() public virtual {
    IPool pool = _pool();
    _assertEModeCategoryUnused(pool, proposal.HINC_EMODE_CATEGORY());

    // execute payload
    _executeHorizonPayload(address(proposal));

    _assertAssetConfig(pool, expectedHincConfig);
    _assertEModeConfig(pool, expectedHincEModeConfig);
    _assertTreasuryIsCollector(pool, AaveV3EthereumHorizonCustom.HINC_UNDERLYING);
  }

  /**
   * @dev mWIN reverts any transfer leaving a non-exempt holder with a non-zero balance below
   *      1 mWIN. With the aToken greenlisted and exempt, a greenlisted user that is not exempt
   *      can only withdraw to a wallet balance of 0 or at least 1 mWIN. The same constraint
   *      applies to liquidators receiving seized mWIN, see test_mwinMinBalanceLiquidation.
   */
  function test_mwinMinBalance() public {
    IPool pool = _pool();
    _executeHorizonPayload(address(proposal));
    _whitelistRwaPool(pool);

    address user = makeAddr('mwinUser');
    address mWin = AaveV3EthereumHorizonCustom.MWIN_UNDERLYING;
    _grantMidasRole(MWIN_GREENLISTED_ROLE, user);

    deal(mWin, user, 2e18);
    vm.startPrank(user);
    IERC20(mWin).approve(address(pool), 2e18);
    pool.supply(mWin, 2e18, user, 0);

    vm.expectRevert(bytes('MTMB: min balance not met'));
    pool.withdraw(mWin, 0.5e18, user);

    pool.withdraw(mWin, 1e18, user);
    assertEq(IERC20(mWin).balanceOf(user), 1e18);
    vm.stopPrank();
  }

  /**
   * @dev A partial liquidation seizing less than 1 mWIN reverts for a greenlisted liquidator that
   *      is not exempt from the 1-mWIN minimum, and succeeds for one holding
   *      M_WIN_MIN_BALANCE_EXEMPT_ROLE. Liquidators therefore need that exemption from Midas.
   */
  function test_mwinMinBalanceLiquidation() public {
    IPool pool = _pool();
    _executeHorizonPayload(address(proposal));

    address mWin = AaveV3EthereumHorizonCustom.MWIN_UNDERLYING;
    address gho = AaveV3EthereumHorizonAssets.GHO_UNDERLYING;
    _whitelistMwinRwa(pool.getReserveAToken(mWin));

    // borrower supplies 2 mWIN (~$262k) and borrows 150k GHO in default mode (67% LTV, 72% LT)
    address borrower = makeAddr('mwinBorrower');
    _grantMidasRole(MWIN_GREENLISTED_ROLE, borrower);
    deal(mWin, borrower, 2e18);
    vm.startPrank(borrower);
    IERC20(mWin).approve(address(pool), 2e18);
    pool.supply(mWin, 2e18, borrower, 0);
    pool.borrow(gho, 150_000e18, 2, 0, borrower);
    vm.stopPrank();

    // a 30% mWIN price drop puts the position below the liquidation threshold
    ReserveConfig memory mwinConfig;
    mwinConfig.underlying = mWin;
    _changeAssetPrice(pool, mwinConfig, 70_00);
    (, , , , , uint256 healthFactor) = pool.getUserAccountData(borrower);
    assertLt(healthFactor, 1e18, 'borrower not liquidatable');

    // covering 50k GHO seizes ~0.59 mWIN (50k * 1.08 bonus / ~$91.9k)
    uint256 debtToCover = 50_000e18;
    address liquidator = makeAddr('mwinLiquidator');
    address exemptLiquidator = makeAddr('mwinExemptLiquidator');
    _grantMidasRole(MWIN_GREENLISTED_ROLE, liquidator);
    _whitelistMwinRwa(exemptLiquidator);

    deal(gho, liquidator, debtToCover);
    vm.startPrank(liquidator);
    IERC20(gho).approve(address(pool), debtToCover);
    vm.expectRevert(bytes('MTMB: min balance not met'));
    pool.liquidationCall(mWin, gho, borrower, debtToCover, false);
    vm.stopPrank();

    deal(gho, exemptLiquidator, debtToCover);
    vm.startPrank(exemptLiquidator);
    IERC20(gho).approve(address(pool), debtToCover);
    pool.liquidationCall(mWin, gho, borrower, debtToCover, false);
    vm.stopPrank();

    uint256 seized = IERC20(mWin).balanceOf(exemptLiquidator);
    assertGt(seized, 0, 'no mWIN seized');
    assertLt(seized, 1e18, 'seized at least 1 mWIN');
  }

  /**
   * @dev the Aave price source must be the feed LlamaRisk bounds in its parameter registry, with
   *      the LlamaGuard parameters from the approved risk reviews
   */
  function test_llamaGuardConfig() public {
    _executeHorizonPayload(address(proposal));

    _assertLlamaGuardConfig(expectedMwinLlamaGuardConfig);
    _assertLlamaGuardConfig(expectedHincLlamaGuardConfig);
  }

  /**
   * @dev the eMode category must be unused before execution (no collateral/borrowable assets, no label)
   */
  function _assertEModeCategoryUnused(IPool pool, uint8 eModeCategory) internal view {
    assertEq(pool.getEModeCategoryCollateralBitmap(eModeCategory), 0, 'emode collateral not empty');
    assertEq(pool.getEModeCategoryBorrowableBitmap(eModeCategory), 0, 'emode borrowable not empty');
    assertEq(bytes(pool.getEModeCategoryLabel(eModeCategory)).length, 0, 'emode label not empty');
  }

  /**
   * @dev the aToken treasury must be the DAO Collector, not a RevenueSplitter, and Horizon's
   *      collector must be the same contract as the v3 Core instance's collector
   */
  function _assertTreasuryIsCollector(IPool pool, address underlying) internal view {
    assertEq(
      address(AaveV3EthereumHorizon.COLLECTOR),
      address(AaveV3Ethereum.COLLECTOR),
      'collector is not the v3 core collector'
    );
    assertEq(
      IAToken(pool.getReserveAToken(underlying)).RESERVE_TREASURY_ADDRESS(),
      address(AaveV3EthereumHorizon.COLLECTOR),
      'aToken treasury'
    );
  }

  function _assertLlamaGuardConfig(ExpectedLlamaGuardConfig memory expected) internal view {
    IRwaOracleParameterRegistry registry = IRwaOracleParameterRegistry(
      AaveV3EthereumHorizonCustom.RWA_ORACLE_PARAMS_REGISTRY
    );
    assertEq(
      registry.getOracle(expected.underlying),
      AaveV3EthereumHorizon.ORACLE.getSourceOfAsset(expected.underlying),
      'llamaGuard.oracle'
    );

    (
      uint64 maxExpectedApy,
      uint32 upperBoundTolerance,
      uint32 lowerBoundTolerance,
      uint32 maxDiscount,
      uint80 lookbackWindowSize,
      bool isUpperBoundEnabled,
      bool isLowerBoundEnabled,

    ) = registry.getParametersForAsset(expected.underlying);
    assertEq(maxExpectedApy, expected.maxExpectedApy, 'llamaGuard.maxExpectedApy');
    assertEq(upperBoundTolerance, expected.upperBoundTolerance, 'llamaGuard.upperBoundTolerance');
    assertEq(lowerBoundTolerance, expected.lowerBoundTolerance, 'llamaGuard.lowerBoundTolerance');
    assertEq(maxDiscount, expected.maxDiscount, 'llamaGuard.maxDiscount');
    assertEq(lookbackWindowSize, expected.lookbackWindowSize, 'llamaGuard.lookbackWindowSize');
    assertTrue(isUpperBoundEnabled, 'llamaGuard.isUpperBoundEnabled');
    assertTrue(isLowerBoundEnabled, 'llamaGuard.isLowerBoundEnabled');
  }
}
