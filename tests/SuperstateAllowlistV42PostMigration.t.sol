// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IScaledBalanceToken} from 'aave-v3-origin/contracts/interfaces/IScaledBalanceToken.sol';
import {IAaveOracle} from 'aave-v3-origin/contracts/interfaces/IAaveOracle.sol';
import {IPriceOracleGetter} from 'aave-v3-origin/contracts/interfaces/IPriceOracleGetter.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

interface ISuperstateToken {
  function allowlist() external view returns (address);
}

interface IAllowlistV4_2 {
  function isAllowed(address addr, address token) external view returns (bool);
}

/// @dev Thrown by USTB/USCC when the sender or recipient is not allowlisted.
error InsufficientPermissions();

/**
 * @dev Horizon operations against the live allowlist, after USTB and USCC were repointed to
 *      AllowlistV4.2 on 2026-09-22. Nothing is simulated: the fork is pinned past the switch and
 *      every actor is an existing Horizon participant moving its own tokens. Only the collateral
 *      price and the liquidators' debt assets are cheated, neither of which grants a permission.
 *
 *      command: FOUNDRY_PROFILE=test forge test --match-contract SuperstateAllowlistV42PostMigration -vv
 */
contract SuperstateAllowlistV42PostMigration is Test {
  uint256 internal constant FORK_BLOCK = 26034966;

  uint256 internal constant TARGET_HEALTH_FACTOR = 0.97e18;

  address internal constant ALLOWLIST_V4_2 = 0xBcBC2b4FB2AbE1C598C9ea91E0b03338e4728D1f;

  // Existing suppliers, debt free at FORK_BLOCK.
  address internal constant USTB_SUPPLIER = 0x81286ac163aD542A9a9C9e4C42F181B003443A22;
  address internal constant USCC_SUPPLIER = 0xc242DEEF9E4dBdF394fE425630F9aa5762dB2faC;

  // Existing borrowers at FORK_BLOCK, each with a single RWA collateral and a single debt asset.
  address internal constant USTB_BORROWER = 0xBa5d9CC840745AeeeEEDaC5712e32F13AB8ea352;
  address internal constant USCC_BORROWER = 0x64471d103A7f77262529383D53Bdd28b260B1aE8;

  IPool internal constant POOL = AaveV3EthereumHorizon.POOL;
  IAaveOracle internal constant ORACLE = AaveV3EthereumHorizon.ORACLE;

  address internal ustbAToken;
  address internal usccAToken;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), FORK_BLOCK);

    ustbAToken = POOL.getReserveAToken(AaveV3EthereumHorizonAssets.USTB_UNDERLYING);
    usccAToken = POOL.getReserveAToken(AaveV3EthereumHorizonAssets.USCC_UNDERLYING);
  }

  /// @dev Both tokens read V4.2 at FORK_BLOCK, so everything below runs against the new allowlist.
  function test_bothTokensOnV4_2() public view {
    assertEq(
      ISuperstateToken(AaveV3EthereumHorizonAssets.USTB_UNDERLYING).allowlist(),
      ALLOWLIST_V4_2,
      'USTB not migrated'
    );
    assertEq(
      ISuperstateToken(AaveV3EthereumHorizonAssets.USCC_UNDERLYING).allowlist(),
      ALLOWLIST_V4_2,
      'USCC not migrated'
    );
  }

  function test_aTokenProvisioned_USTB() public view {
    assertTrue(
      IAllowlistV4_2(ALLOWLIST_V4_2).isAllowed(
        ustbAToken,
        AaveV3EthereumHorizonAssets.USTB_UNDERLYING
      ),
      'USTB aToken not allowed'
    );
  }

  function test_aTokenProvisioned_USCC() public view {
    assertTrue(
      IAllowlistV4_2(ALLOWLIST_V4_2).isAllowed(
        usccAToken,
        AaveV3EthereumHorizonAssets.USCC_UNDERLYING
      ),
      'USCC aToken not allowed'
    );
  }

  function test_withdrawAndSupply_USTB() public {
    _withdrawAndSupplyBack(AaveV3EthereumHorizonAssets.USTB_UNDERLYING, ustbAToken, USTB_SUPPLIER);
  }

  function test_withdrawAndSupply_USCC() public {
    _withdrawAndSupplyBack(AaveV3EthereumHorizonAssets.USCC_UNDERLYING, usccAToken, USCC_SUPPLIER);
  }

  function test_liquidation_USTB() public {
    _liquidate({
      collateral: AaveV3EthereumHorizonAssets.USTB_UNDERLYING,
      debtAsset: AaveV3EthereumHorizonAssets.GHO_UNDERLYING,
      borrower: USTB_BORROWER,
      liquidator: USTB_SUPPLIER
    });
  }

  function test_liquidation_USCC() public {
    _liquidate({
      collateral: AaveV3EthereumHorizonAssets.USCC_UNDERLYING,
      debtAsset: AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING,
      borrower: USCC_BORROWER,
      liquidator: USCC_SUPPLIER
    });
  }

  /// @dev Holder lists come from scripts/superstate-allowlist-holders.ts at FORK_BLOCK.
  function test_noHolderLockedOut_USTB() public {
    address[] memory holders = new address[](10);
    holders[0] = 0x16e47d275198ED65916a560bAB4Af6330c36Ae09;
    holders[1] = 0x27C09696061fFB6F186f4fC309b88f32EC19B6eD;
    holders[2] = 0x34Ada44769bD057A5121cBd111e9d3e4E55cA10e;
    holders[3] = 0x81286ac163aD542A9a9C9e4C42F181B003443A22;
    holders[4] = 0xa0a6282a3ADBc3d6b76cd1129CD17607316dc2C1;
    holders[5] = 0xb4370cf83BAE43BEb4539fA5882a128d0c772402;
    holders[6] = 0xBa5d9CC840745AeeeEEDaC5712e32F13AB8ea352;
    holders[7] = 0xC45f432f4002715C8Aae0B519e1135c882Cbb4f1;
    holders[8] = 0xcf25feDB1A51edC27DBA47C87c28be1c983168Fb;
    holders[9] = 0xFe9383C1F16E1F369B72681402685810B0a22a1D;
    _assertNoHolderLockedOut(AaveV3EthereumHorizonAssets.USTB_UNDERLYING, ustbAToken, holders);
  }

  function test_noHolderLockedOut_USCC() public {
    address[] memory holders = new address[](11);
    holders[0] = 0x3DcBf20aedDBa3f5c94FD55f75570710b4A60E2d;
    holders[1] = 0x55Fa9aAc40Af97FAaB697cc74d4dA452abf0272c;
    holders[2] = 0x64471d103A7f77262529383D53Bdd28b260B1aE8;
    holders[3] = 0x6475A5fD4c8B8387Df30c199339e510888E0374D;
    holders[4] = 0x80559941C1A741bC435cb6782b6F161d5772ac4B;
    holders[5] = 0x971B34b997843b82051b3e781d6A6d5A21BbDDA0;
    holders[6] = 0xa846D192Bdc1c16681bc726CA7b28E0be199cE92;
    holders[7] = 0xBA474Ab1642101968633525FB117fA12C5BCB4E6;
    holders[8] = 0xc242DEEF9E4dBdF394fE425630F9aa5762dB2faC;
    holders[9] = 0xd8383Ef64F49f7Bb16c60411080239863D9a823b;
    holders[10] = 0xeD8CF2891d7bd5B01a8eE5B702b73b39B1967968;
    _assertNoHolderLockedOut(AaveV3EthereumHorizonAssets.USCC_UNDERLYING, usccAToken, holders);
  }

  function test_nonAllowlistedRecipientRejected_USTB() public {
    _assertRecipientRejected(AaveV3EthereumHorizonAssets.USTB_UNDERLYING, USTB_SUPPLIER);
  }

  function test_nonAllowlistedRecipientRejected_USCC() public {
    _assertRecipientRejected(AaveV3EthereumHorizonAssets.USCC_UNDERLYING, USCC_SUPPLIER);
  }

  function test_nonAllowlistedSupplierRejected_USTB() public {
    _assertSupplierRejected(AaveV3EthereumHorizonAssets.USTB_UNDERLYING);
  }

  function test_nonAllowlistedSupplierRejected_USCC() public {
    _assertSupplierRejected(AaveV3EthereumHorizonAssets.USCC_UNDERLYING);
  }

  /**
   * @dev Exercises both directions of the underlying transfer without dealing the RWA: the
   *      supplier funds the supply leg out of its own withdrawal.
   */
  function _withdrawAndSupplyBack(address underlying, address aToken, address supplier) internal {
    uint256 aTokenBalanceBefore = IERC20(aToken).balanceOf(supplier);
    assertGt(aTokenBalanceBefore, 0, 'supplier holds no aToken');

    uint256 amount = aTokenBalanceBefore / 2;
    uint256 underlyingBalanceBefore = IERC20(underlying).balanceOf(supplier);

    vm.prank(supplier);
    POOL.withdraw(underlying, amount, supplier);

    assertEq(
      IERC20(underlying).balanceOf(supplier),
      underlyingBalanceBefore + amount,
      'withdraw did not deliver underlying'
    );

    vm.startPrank(supplier);
    IERC20(underlying).approve(address(POOL), amount);
    POOL.supply(underlying, amount, supplier, 0);
    vm.stopPrank();

    assertEq(
      IERC20(underlying).balanceOf(supplier),
      underlyingBalanceBefore,
      'supply did not consume underlying'
    );
    assertGe(
      IERC20(aToken).balanceOf(supplier),
      aTokenBalanceBefore,
      'aToken balance not restored'
    );
  }

  /**
   * @dev The only Horizon path that sends the RWA to a third party, so the liquidator has to be
   *      allowlisted. `receiveAToken = true` is not covered: RwaAToken reverts transferOnLiquidation.
   */
  function _liquidate(
    address collateral,
    address debtAsset,
    address borrower,
    address liquidator
  ) internal {
    (, , , , , uint256 healthFactorBefore) = POOL.getUserAccountData(borrower);
    uint256 price = ORACLE.getAssetPrice(collateral);
    vm.mockCall(
      address(ORACLE),
      abi.encodeWithSelector(IPriceOracleGetter.getAssetPrice.selector, collateral),
      abi.encode((price * TARGET_HEALTH_FACTOR) / healthFactorBefore)
    );

    (, , , , , uint256 healthFactor) = POOL.getUserAccountData(borrower);
    assertLt(healthFactor, 1e18, 'borrower not liquidatable');
    assertGt(healthFactor, 0.95e18, 'close factor is not 50%');

    uint256 borrowerDebt = IERC20(POOL.getReserveVariableDebtToken(debtAsset)).balanceOf(borrower);
    deal(debtAsset, liquidator, borrowerDebt);

    uint256 collateralBefore = IERC20(collateral).balanceOf(liquidator);

    vm.startPrank(liquidator);
    IERC20(debtAsset).approve(address(POOL), type(uint256).max);
    POOL.liquidationCall({
      collateralAsset: collateral,
      debtAsset: debtAsset,
      borrower: borrower,
      debtToCover: type(uint256).max,
      receiveAToken: false
    });
    vm.stopPrank();

    assertGt(
      IERC20(collateral).balanceOf(liquidator),
      collateralBefore,
      'liquidator did not receive collateral'
    );
  }

  /**
   * @dev The scaled balances must add up to the scaled total supply exactly, so the list cannot miss
   *      a holder. Each holder then withdraws 1 unit, which only succeeds if the token lets the
   *      aToken send the underlying to that holder.
   */
  function _assertNoHolderLockedOut(
    address underlying,
    address aToken,
    address[] memory holders
  ) internal {
    uint256 scaledSum;
    for (uint256 i; i < holders.length; ++i) {
      scaledSum += IScaledBalanceToken(aToken).scaledBalanceOf(holders[i]);
    }
    assertEq(scaledSum, IScaledBalanceToken(aToken).scaledTotalSupply(), 'holder list incomplete');

    for (uint256 i; i < holders.length; ++i) {
      assertTrue(
        IAllowlistV4_2(ALLOWLIST_V4_2).isAllowed(holders[i], underlying),
        'holder not allowed'
      );

      uint256 underlyingBefore = IERC20(underlying).balanceOf(holders[i]);
      vm.prank(holders[i]);
      POOL.withdraw(underlying, 1, holders[i]);
      assertEq(
        IERC20(underlying).balanceOf(holders[i]),
        underlyingBefore + 1,
        'holder could not withdraw'
      );
    }
  }

  /// @dev Negative control: without it the tests above could pass against an open allowlist.
  function _assertRecipientRejected(address underlying, address supplier) internal {
    address stranger = makeAddr('stranger');
    assertFalse(
      IAllowlistV4_2(ALLOWLIST_V4_2).isAllowed(stranger, underlying),
      'stranger unexpectedly allowed'
    );

    uint256 amount = 1e6;
    vm.prank(supplier);
    POOL.withdraw(underlying, amount, supplier);

    vm.prank(supplier);
    vm.expectRevert(InsufficientPermissions.selector);
    IERC20(underlying).transfer(stranger, amount);
  }

  /// @dev Same control on the inbound leg, where the non-allowlisted account is the source.
  function _assertSupplierRejected(address underlying) internal {
    address stranger = makeAddr('stranger');
    deal(underlying, stranger, 1e6);

    vm.startPrank(stranger);
    IERC20(underlying).approve(address(POOL), 1e6);
    vm.expectRevert(InsufficientPermissions.selector);
    POOL.supply(underlying, 1e6, stranger, 0);
    vm.stopPrank();
  }
}
