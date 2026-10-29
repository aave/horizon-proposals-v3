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
  struct MwinRoles {
    bool fromGreenlisted;
    bool fromExempt;
    bool toGreenlisted;
    bool toExempt;
  }

  uint256 internal constant MWIN_DEBT_TO_COVER = 50_000e18;

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
    _whitelistMwinRwa(user);

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
    _exemptMwinMinBalance(pool.getReserveAToken(mWin));

    // borrower supplies 2 mWIN (~$262k) and borrows 150k GHO in default mode (67% LTV, 72% LT)
    address borrower = makeAddr('mwinBorrower');
    _whitelistMwinRwa(borrower);
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
    _whitelistMwinRwa(liquidator);
    _whitelistMwinRwa(exemptLiquidator);
    _exemptMwinMinBalance(exemptLiquidator);

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
   * @dev The tests below each make the same call twice on the same state: first reverting on the
   *      1-mWIN minimum, then succeeding once M_WIN_MIN_BALANCE_EXEMPT_ROLE is granted to the
   *      account the check failed on. The RWA aToken is the recipient on supply and the sender on
   *      withdraw and liquidation, so it needs the exemption as well as liquidators.
   */
  function test_mwinMinBalance_withdraw_userNeedsExemption() public {
    IPool pool = _setUpMwin({aTokenExempt: true});
    address user = _supplyMwin(pool, 'mwinUser', 2e18);

    vm.expectRevert(bytes('MTMB: min balance not met'));
    vm.prank(user);
    pool.withdraw(_mwin(), 0.5e18, user);

    _exemptMwinMinBalance(user);
    vm.prank(user);
    pool.withdraw(_mwin(), 0.5e18, user);
    assertEq(IERC20(_mwin()).balanceOf(user), 0.5e18);
  }

  function test_mwinMinBalance_supply_aTokenNeedsExemption() public {
    IPool pool = _setUpMwin({aTokenExempt: false});
    address user = _greenlistedMwinUser('mwinUser');
    address aToken = pool.getReserveAToken(_mwin());
    _dealAndApproveMwin(pool, user, 0.5e18);

    vm.expectRevert(bytes('MTMB: min balance not met'));
    vm.prank(user);
    pool.supply(_mwin(), 0.5e18, user, 0);

    _exemptMwinMinBalance(aToken);
    vm.prank(user);
    pool.supply(_mwin(), 0.5e18, user, 0);
    assertEq(IERC20(_mwin()).balanceOf(aToken), 0.5e18);
  }

  function test_mwinMinBalance_withdraw_aTokenNeedsExemption() public {
    IPool pool = _setUpMwin({aTokenExempt: false});
    address user = _supplyMwin(pool, 'mwinUser', 1.5e18);
    address aToken = pool.getReserveAToken(_mwin());

    vm.expectRevert(bytes('MTMB: min balance not met'));
    vm.prank(user);
    pool.withdraw(_mwin(), 1e18, user);

    _exemptMwinMinBalance(aToken);
    vm.prank(user);
    pool.withdraw(_mwin(), 1e18, user);
    assertEq(IERC20(_mwin()).balanceOf(aToken), 0.5e18);
  }

  function test_mwinMinBalance_liquidation_aTokenNeedsExemption() public {
    IPool pool = _setUpMwin({aTokenExempt: false});
    address borrower = _openLiquidatableMwinPosition(pool, 1.5e18, 112_500e18);
    address liquidator = _greenlistedMwinUser('mwinLiquidator');
    _exemptMwinMinBalance(liquidator);
    address aToken = pool.getReserveAToken(_mwin());
    _dealAndApproveGho(pool, liquidator);

    vm.expectRevert(bytes('MTMB: min balance not met'));
    _liquidateMwin(pool, liquidator, borrower);

    _exemptMwinMinBalance(aToken);
    _liquidateMwin(pool, liquidator, borrower);
    uint256 aTokenBalance = IERC20(_mwin()).balanceOf(aToken);
    assertGt(aTokenBalance, 0, 'aToken emptied');
    assertLt(aTokenBalance, 1e18, 'aToken left with at least 1 mWIN');
  }

  function test_mwinMinBalance_liquidation_liquidatorNeedsExemption() public {
    IPool pool = _setUpMwin({aTokenExempt: true});
    address borrower = _openLiquidatableMwinPosition(pool, 2e18, 150_000e18);
    address liquidator = _greenlistedMwinUser('mwinLiquidator');
    _dealAndApproveGho(pool, liquidator);

    vm.expectRevert(bytes('MTMB: min balance not met'));
    _liquidateMwin(pool, liquidator, borrower);

    _exemptMwinMinBalance(liquidator);
    _liquidateMwin(pool, liquidator, borrower);
    uint256 seized = IERC20(_mwin()).balanceOf(liquidator);
    assertGt(seized, 0, 'no mWIN seized');
    assertLt(seized, 1e18, 'seized at least 1 mWIN');
  }

  /**
   * @dev For each path, runs the same transfer under every combination of greenlist role and
   *      min balance exemption on its two mWIN parties, with amounts that leave both parties
   *      holding between 0 and 1 mWIN. mWIN checks the greenlist on both parties before the
   *      transfer and the 1-mWIN minimum on both after it.
   */
  function test_mwinRoles_supply() public {
    IPool pool = _setUpMwin({aTokenExempt: false});
    address user = _greenlistedMwinUser('mwinUser');
    address aToken = pool.getReserveAToken(_mwin());
    _dealAndApproveMwin(pool, user, 1e18);

    uint256 snapshot = vm.snapshotState();
    for (uint256 i; i < 16; i++) {
      vm.revertToState(snapshot);
      MwinRoles memory roles = _mwinRolesCase(i);
      _setMwinRoles(user, roles.fromGreenlisted, roles.fromExempt);
      _setMwinRoles(aToken, roles.toGreenlisted, roles.toExempt);

      bool succeeds = _expectMwinTransferOutcome(roles);
      vm.prank(user);
      pool.supply(_mwin(), 0.5e18, user, 0);
      if (succeeds) {
        assertEq(IERC20(_mwin()).balanceOf(user), 0.5e18, 'user balance');
        assertEq(IERC20(_mwin()).balanceOf(aToken), 0.5e18, 'aToken balance');
      }
    }
  }

  function test_mwinRoles_withdraw() public {
    IPool pool = _setUpMwin({aTokenExempt: false});
    address user = _supplyMwin(pool, 'mwinUser', 1.5e18);
    address aToken = pool.getReserveAToken(_mwin());

    uint256 snapshot = vm.snapshotState();
    for (uint256 i; i < 16; i++) {
      vm.revertToState(snapshot);
      MwinRoles memory roles = _mwinRolesCase(i);
      _setMwinRoles(aToken, roles.fromGreenlisted, roles.fromExempt);
      _setMwinRoles(user, roles.toGreenlisted, roles.toExempt);

      bool succeeds = _expectMwinTransferOutcome(roles);
      vm.prank(user);
      pool.withdraw(_mwin(), 0.75e18, user);
      if (succeeds) {
        assertEq(IERC20(_mwin()).balanceOf(aToken), 0.75e18, 'aToken balance');
        assertEq(IERC20(_mwin()).balanceOf(user), 0.75e18, 'user balance');
      }
    }
  }

  function test_mwinRoles_liquidation() public {
    IPool pool = _setUpMwin({aTokenExempt: false});
    address borrower = _openLiquidatableMwinPosition(pool, 1.5e18, 112_500e18);
    address liquidator = makeAddr('mwinLiquidator');
    address aToken = pool.getReserveAToken(_mwin());
    _dealAndApproveGho(pool, liquidator);

    uint256 snapshot = vm.snapshotState();
    for (uint256 i; i < 16; i++) {
      vm.revertToState(snapshot);
      MwinRoles memory roles = _mwinRolesCase(i);
      _setMwinRoles(aToken, roles.fromGreenlisted, roles.fromExempt);
      _setMwinRoles(liquidator, roles.toGreenlisted, roles.toExempt);

      bool succeeds = _expectMwinTransferOutcome(roles);
      _liquidateMwin(pool, liquidator, borrower);
      if (succeeds) {
        uint256 seized = IERC20(_mwin()).balanceOf(liquidator);
        assertGt(seized, 0, 'no mWIN seized');
        assertLt(seized, 1e18, 'seized at least 1 mWIN');
        assertEq(IERC20(_mwin()).balanceOf(aToken), 1.5e18 - seized, 'aToken balance');
      }
    }
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
   * @dev the aToken treasury must be the DAO Collector, not a RevenueSplitter
   */
  function _assertTreasuryIsCollector(IPool pool, address underlying) internal view {
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

  function _mwin() internal pure returns (address) {
    return AaveV3EthereumHorizonCustom.MWIN_UNDERLYING;
  }

  /// @dev executes the payload and greenlists the mWIN aToken, with or without the min balance exemption
  function _setUpMwin(bool aTokenExempt) internal returns (IPool) {
    IPool pool = _pool();
    _executeHorizonPayload(address(proposal));
    address aToken = pool.getReserveAToken(_mwin());
    _whitelistMwinRwa(aToken);
    if (aTokenExempt) _exemptMwinMinBalance(aToken);
    return pool;
  }

  function _greenlistedMwinUser(string memory name) internal returns (address user) {
    user = makeAddr(name);
    _whitelistMwinRwa(user);
  }

  function _dealAndApproveMwin(IPool pool, address user, uint256 amount) internal {
    deal(_mwin(), user, amount);
    vm.prank(user);
    IERC20(_mwin()).approve(address(pool), amount);
  }

  function _supplyMwin(
    IPool pool,
    string memory name,
    uint256 amount
  ) internal returns (address user) {
    user = _greenlistedMwinUser(name);
    _dealAndApproveMwin(pool, user, amount);
    vm.prank(user);
    pool.supply(_mwin(), amount, user, 0);
  }

  /// @dev supplies mWIN, borrows GHO in default mode, then drops the mWIN price 30%, putting the position below the liquidation threshold
  function _openLiquidatableMwinPosition(
    IPool pool,
    uint256 collateral,
    uint256 debt
  ) internal returns (address borrower) {
    borrower = _supplyMwin(pool, 'mwinBorrower', collateral);
    vm.prank(borrower);
    pool.borrow(AaveV3EthereumHorizonAssets.GHO_UNDERLYING, debt, 2, 0, borrower);

    ReserveConfig memory mwinConfig;
    mwinConfig.underlying = _mwin();
    _changeAssetPrice(pool, mwinConfig, 70_00);
    (, , , , , uint256 healthFactor) = pool.getUserAccountData(borrower);
    assertLt(healthFactor, 1e18, 'borrower not liquidatable');
  }

  function _dealAndApproveGho(IPool pool, address liquidator) internal {
    deal(AaveV3EthereumHorizonAssets.GHO_UNDERLYING, liquidator, MWIN_DEBT_TO_COVER);
    vm.prank(liquidator);
    IERC20(AaveV3EthereumHorizonAssets.GHO_UNDERLYING).approve(address(pool), MWIN_DEBT_TO_COVER);
  }

  /// @dev covers 50k GHO, which seizes ~0.59 mWIN (50k * 1.08 bonus / ~$91.9k)
  function _liquidateMwin(IPool pool, address liquidator, address borrower) internal {
    vm.prank(liquidator);
    pool.liquidationCall({
      collateralAsset: _mwin(),
      debtAsset: AaveV3EthereumHorizonAssets.GHO_UNDERLYING,
      borrower: borrower,
      debtToCover: MWIN_DEBT_TO_COVER,
      receiveAToken: false
    });
  }

  /// @dev bit 0: sender greenlisted, bit 1: sender exempt, bit 2: recipient greenlisted, bit 3: recipient exempt
  function _mwinRolesCase(uint256 i) internal pure returns (MwinRoles memory) {
    return
      MwinRoles({
        fromGreenlisted: i & 1 != 0,
        fromExempt: i & 2 != 0,
        toGreenlisted: i & 4 != 0,
        toExempt: i & 8 != 0
      });
  }

  /// @dev expects the revert, if any, and returns whether the transfer succeeds. Both parties end
  ///      between 0 and 1 mWIN, so each needs both roles.
  function _expectMwinTransferOutcome(MwinRoles memory roles) internal returns (bool) {
    if (!roles.fromGreenlisted || !roles.toGreenlisted) {
      vm.expectRevert(bytes('WMAC: hasnt role'));
      return false;
    }
    if (!roles.fromExempt || !roles.toExempt) {
      vm.expectRevert(bytes('MTMB: min balance not met'));
      return false;
    }
    return true;
  }

  function _setMwinRoles(address account, bool greenlisted, bool exempt) internal {
    _setMidasRole(MWIN_GREENLISTED_ROLE, account, greenlisted);
    _setMidasRole(MWIN_MIN_BALANCE_EXEMPT_ROLE, account, exempt);
  }
}
