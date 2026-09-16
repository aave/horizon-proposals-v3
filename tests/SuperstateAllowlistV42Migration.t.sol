// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {console2 as console} from 'forge-std/console2.sol';
import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IAaveOracle} from 'aave-v3-origin/contracts/interfaces/IAaveOracle.sol';
import {IPriceOracleGetter} from 'aave-v3-origin/contracts/interfaces/IPriceOracleGetter.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

interface ISuperstateToken {
  function allowlist() external view returns (address);

  function setAllowlist(address allowlist) external;

  function owner() external view returns (address);

  function symbol() external view returns (string memory);
}

/// @dev Thrown by USTB/USCC when the sender or recipient is not allowlisted.
error InsufficientPermissions();

interface IAllowlistV4_2 {
  function isAllowed(address addr, address token) external view returns (bool);

  function VERSION() external pure returns (string memory);
}

/**
 * @dev Replays Horizon operations across the upcoming USTB/USCC allowlist switch.
 *      No allowlist state is mocked: actors are existing Horizon participants moving their own
 *      tokens. Only the USTB price and the liquidator's RLUSD are cheated.
 *
 *      command: FOUNDRY_PROFILE=test forge test --match-contract SuperstateAllowlistV42Migration -vv
 */
contract SuperstateAllowlistV42Migration is Test {
  uint256 internal constant FORK_BLOCK = 25988000;

  address internal constant ALLOWLIST_V4_2 = 0xBcBC2b4FB2AbE1C598C9ea91E0b03338e4728D1f;
  address internal constant ALLOWLIST_V3 = 0x02f1fA8B196d21c7b733EB2700B825611d8A38E5;

  // Existing suppliers, debt free at FORK_BLOCK.
  address internal constant USTB_SUPPLIER = 0x81286ac163aD542A9a9C9e4C42F181B003443A22;
  address internal constant USCC_SUPPLIER = 0xc242DEEF9E4dBdF394fE425630F9aa5762dB2faC;

  // Existing borrower at FORK_BLOCK: USTB is its only collateral, RLUSD its only debt.
  address internal constant USTB_BORROWER = 0xb6cbe8b123392eF6Aa72897bb85bd6515d2e8db7;

  IPool internal constant POOL = AaveV3EthereumHorizon.POOL;
  IAaveOracle internal constant ORACLE = AaveV3EthereumHorizon.ORACLE;

  address internal ustbAToken;
  address internal usccAToken;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), FORK_BLOCK);

    ustbAToken = POOL.getReserveAToken(AaveV3EthereumHorizonAssets.USTB_UNDERLYING);
    usccAToken = POOL.getReserveAToken(AaveV3EthereumHorizonAssets.USCC_UNDERLYING);
  }

  /// @dev Both tokens still read the old allowlist at FORK_BLOCK, so the tests below measure the switch.
  function test_preconditions() public view {
    assertEq(
      ISuperstateToken(AaveV3EthereumHorizonAssets.USTB_UNDERLYING).allowlist(),
      ALLOWLIST_V3,
      'USTB already migrated'
    );
    assertEq(
      ISuperstateToken(AaveV3EthereumHorizonAssets.USCC_UNDERLYING).allowlist(),
      ALLOWLIST_V3,
      'USCC already migrated'
    );
  }

  /// @dev The aTokens hold the underlying, so they are the addresses that must survive the switch.
  function test_aTokensProvisionedOnV4_2() public view {
    assertTrue(
      IAllowlistV4_2(ALLOWLIST_V4_2).isAllowed(
        ustbAToken,
        AaveV3EthereumHorizonAssets.USTB_UNDERLYING
      ),
      'USTB aToken not allowed'
    );
    assertTrue(
      IAllowlistV4_2(ALLOWLIST_V4_2).isAllowed(
        usccAToken,
        AaveV3EthereumHorizonAssets.USCC_UNDERLYING
      ),
      'USCC aToken not allowed'
    );
  }

  function test_withdrawAndSupply_USTB_beforeMigration() public {
    _withdrawAndSupplyBack(AaveV3EthereumHorizonAssets.USTB_UNDERLYING, ustbAToken, USTB_SUPPLIER);
  }

  function test_withdrawAndSupply_USTB_afterMigration() public {
    _migrateAllowlists();
    _withdrawAndSupplyBack(AaveV3EthereumHorizonAssets.USTB_UNDERLYING, ustbAToken, USTB_SUPPLIER);
  }

  function test_withdrawAndSupply_USCC_beforeMigration() public {
    _withdrawAndSupplyBack(AaveV3EthereumHorizonAssets.USCC_UNDERLYING, usccAToken, USCC_SUPPLIER);
  }

  function test_withdrawAndSupply_USCC_afterMigration() public {
    _migrateAllowlists();
    _withdrawAndSupplyBack(AaveV3EthereumHorizonAssets.USCC_UNDERLYING, usccAToken, USCC_SUPPLIER);
  }

  function test_liquidation_USTB_beforeMigration() public {
    _liquidateUstbCollateral();
  }

  function test_liquidation_USTB_afterMigration() public {
    _migrateAllowlists();
    _liquidateUstbCollateral();
  }

  /// @dev Negative control: without it the tests above could pass against an open allowlist.
  function test_nonAllowlistedRecipientStillRejected() public {
    _migrateAllowlists();

    address stranger = makeAddr('stranger');
    assertFalse(
      IAllowlistV4_2(ALLOWLIST_V4_2).isAllowed(
        stranger,
        AaveV3EthereumHorizonAssets.USTB_UNDERLYING
      ),
      'stranger unexpectedly allowed'
    );

    uint256 amount = 1e6;
    vm.prank(USTB_SUPPLIER);
    POOL.withdraw(AaveV3EthereumHorizonAssets.USTB_UNDERLYING, amount, USTB_SUPPLIER);

    vm.prank(USTB_SUPPLIER);
    vm.expectRevert(InsufficientPermissions.selector);
    IERC20(AaveV3EthereumHorizonAssets.USTB_UNDERLYING).transfer(stranger, amount);
  }

  /// @dev Same control on the inbound leg, where the non-allowlisted account is the source.
  function test_nonAllowlistedSupplierStillRejected() public {
    _migrateAllowlists();

    address stranger = makeAddr('stranger');
    deal(AaveV3EthereumHorizonAssets.USTB_UNDERLYING, stranger, 1e6);

    vm.startPrank(stranger);
    IERC20(AaveV3EthereumHorizonAssets.USTB_UNDERLYING).approve(address(POOL), 1e6);
    vm.expectRevert(InsufficientPermissions.selector);
    POOL.supply(AaveV3EthereumHorizonAssets.USTB_UNDERLYING, 1e6, stranger, 0);
    vm.stopPrank();
  }

  /// @dev The issuer side of the switch. No token upgrade is needed, only the pointer.
  function _migrateAllowlists() internal {
    _setAllowlist(AaveV3EthereumHorizonAssets.USTB_UNDERLYING);
    _setAllowlist(AaveV3EthereumHorizonAssets.USCC_UNDERLYING);

    console.log('Allowlist V4.2 version: %s', IAllowlistV4_2(ALLOWLIST_V4_2).VERSION());
  }

  function _setAllowlist(address token) internal {
    address tokenOwner = ISuperstateToken(token).owner();

    vm.prank(tokenOwner);
    ISuperstateToken(token).setAllowlist(ALLOWLIST_V4_2);

    assertEq(ISuperstateToken(token).allowlist(), ALLOWLIST_V4_2, 'allowlist not repointed');
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
  function _liquidateUstbCollateral() internal {
    address liquidator = USTB_SUPPLIER;
    address debtAsset = AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING;

    // Shallow drop on purpose: keeps the close factor at 50% so the liquidation leaves collateral
    // and debt above the dust threshold.
    uint256 price = ORACLE.getAssetPrice(AaveV3EthereumHorizonAssets.USTB_UNDERLYING);
    vm.mockCall(
      address(ORACLE),
      abi.encodeWithSelector(
        IPriceOracleGetter.getAssetPrice.selector,
        AaveV3EthereumHorizonAssets.USTB_UNDERLYING
      ),
      abi.encode((price * 96) / 100)
    );

    (, , , , , uint256 healthFactor) = POOL.getUserAccountData(USTB_BORROWER);
    assertLt(healthFactor, 1e18, 'borrower not liquidatable');
    assertGt(healthFactor, 0.95e18, 'close factor is not 50%');

    // RLUSD is not permissioned, so funding the liquidator grants no RWA permission.
    uint256 borrowerDebt = IERC20(POOL.getReserveVariableDebtToken(debtAsset)).balanceOf(
      USTB_BORROWER
    );
    deal(debtAsset, liquidator, borrowerDebt);

    uint256 collateralBefore = IERC20(AaveV3EthereumHorizonAssets.USTB_UNDERLYING).balanceOf(
      liquidator
    );

    vm.startPrank(liquidator);
    IERC20(debtAsset).approve(address(POOL), type(uint256).max);
    POOL.liquidationCall({
      collateralAsset: AaveV3EthereumHorizonAssets.USTB_UNDERLYING,
      debtAsset: debtAsset,
      borrower: USTB_BORROWER,
      debtToCover: type(uint256).max,
      receiveAToken: false
    });
    vm.stopPrank();

    assertGt(
      IERC20(AaveV3EthereumHorizonAssets.USTB_UNDERLYING).balanceOf(liquidator),
      collateralBefore,
      'liquidator did not receive USTB'
    );
  }
}
