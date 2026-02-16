// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';
import {IERC20} from 'aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/forge-std/src/interfaces/IERC20.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPoolConfigurator} from 'aave-v3-origin/contracts/interfaces/IPoolConfigurator.sol';
import {IACLManager} from 'aave-v3-origin/contracts/interfaces/IACLManager.sol';
import {AaveV3HorizonEthereum} from './AaveV3HorizonEthereum.sol';
import {HorizonRwaWhitelistHelper} from './HorizonRwaWhitelistHelper.sol';

/**
 * @dev Adapted from ProtocolV3TestBase for the Horizon market (currently at Aave v3.3).
 * - GHO is listed as a normal reserve like prime market, removes special branches.
 * - Enable eMode before supplying if available.
 * - Skip liquidation with receiveAToken=true when collateral is RWA, since it is disabled.
 * - Adds helper to return all actors used in E2E test such that they may be whitelisted to hold RWA tokens.
 * - Update errors to v3.3 string format.
 */
abstract contract ProtocolV3HorizonTestBase is ProtocolV3TestBase, HorizonRwaWhitelistHelper {
  string public constant BORROW_CAP_EXCEEDED = '50';
  string public constant SUPPLY_CAP_EXCEEDED = '51';

  /**
   * @dev Execute a Horizon payload by granting it POOL_ADMIN role and calling execute() directly.
   * Horizon has no standard Aave governance payloads controller — it uses a multisig executor.
   * This simulates the executor's delegatecall execution path for testing.
   */
  function _executeHorizonPayload(address payload) internal {
    address aclAdmin = IPoolAddressesProvider(AaveV3HorizonEthereum.POOL_ADDRESSES_PROVIDER)
      .getACLAdmin();
    vm.startPrank(aclAdmin);
    IACLManager(AaveV3HorizonEthereum.ACL_MANAGER).addPoolAdmin(payload);
    vm.stopPrank();
    (bool success, bytes memory resultData) = payload.call(abi.encodeWithSignature('execute()'));
    require(success, string(resultData));
  }

  /**
   * @dev runs the default test suite that should run on any proposal touching the aave protocol which includes:
   * - diffing the config
   * - checking if the changes are plausible (no conflicting config changes etc)
   * - running an e2e testsuite over all assets
   */
  function defaultTest_v3_3(
    string memory reportName,
    IPool pool,
    address payload
  ) public returns (ReserveConfig[] memory, ReserveConfig[] memory) {
    string memory beforeString = string(abi.encodePacked(reportName, '_before'));
    ReserveConfig[] memory configBefore = createConfigurationSnapshot(beforeString, pool);

    uint256 startGas = gasleft();

    vm.startStateDiffRecording();
    _executeHorizonPayload(payload);
    string memory rawDiff = vm.getStateDiffJson();

    uint256 gasUsed = startGas - gasleft();
    assertLt(gasUsed, (block.gaslimit * 95) / 100, 'BLOCK_GAS_LIMIT_EXCEEDED'); // 5% is kept as a buffer

    string memory afterString = string(abi.encodePacked(reportName, '_after'));
    ReserveConfig[] memory configAfter = createConfigurationSnapshot(afterString, pool);
    string memory output = vm.serializeString('root', 'raw', rawDiff);
    vm.writeJson(output, string(abi.encodePacked('./reports/', afterString, '.json')));

    diffReports(beforeString, afterString);

    configChangePlausibilityTest(configBefore, configAfter);

    // whitelist E2E actors on RWA compliance systems before running E2E
    _whitelistRwaActors(pool, _testActors());

    e2eTest_v3_3(pool);
    return (configBefore, configAfter);
  }

  /**
   * @dev Makes a e2e test including withdrawals/borrows and supplies to various reserves.
   * @param pool the pool that should be tested
   */
  function e2eTest_v3_3(IPool pool) public {
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    ReserveConfig memory collateralConfig = _goodCollateral(configs);
    uint256 snapshot = vm.snapshotState();
    for (uint256 i; i < configs.length; i++) {
      if (_includeInE2e(configs[i])) {
        e2eTestAsset_v3_3(pool, collateralConfig, configs[i]);
        vm.revertToState(snapshot);
      } else {
        console.log('E2E: TestAsset %s SKIPPED', configs[i].symbol);
      }
    }
  }

  struct E2ETestAssetLocalVars {
    address emodeCollateralSupplier;
    address regularCollateralSupplier;
    address borrower; // chosen per test asset based on eMode compatibility
    address testAssetSupplier;
    address liquidator;
    uint256 collateralAssetAmount;
    uint256 testAssetAmount;
    uint256 snapshotAfterDeposits;
    uint256 aTokenTotalSupply;
    uint256 variableDebtTokenTotalSupply;
    uint256 borrowAmount;
    uint256 snapshotBeforeRepay;
  }

  function e2eTestAsset_v3_3(
    IPool pool,
    ReserveConfig memory collateralConfig,
    ReserveConfig memory testAssetConfig
  ) public {
    console.log(
      'E2E: Collateral %s, TestAsset %s',
      collateralConfig.symbol,
      testAssetConfig.symbol
    );
    E2ETestAssetLocalVars memory vars;
    vars.emodeCollateralSupplier = makeAddr('emodeCollateralSupplier');
    vars.regularCollateralSupplier = makeAddr('regularCollateralSupplier');
    vars.testAssetSupplier = makeAddr('testAssetSupplier');
    vars.liquidator = makeAddr('liquidator');
    require(collateralConfig.usageAsCollateralEnabled, 'COLLATERAL_CONFIG_MUST_BE_COLLATERAL');
    vars.collateralAssetAmount = _getTokenAmountByDollarValue(pool, collateralConfig, 100_000);
    vars.testAssetAmount = _getTokenAmountByDollarValue(pool, testAssetConfig, 10_000);

    // remove caps as they should not prevent testing
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IPoolConfigurator poolConfigurator = IPoolConfigurator(addressesProvider.getPoolConfigurator());
    vm.startPrank(addressesProvider.getACLAdmin());
    if (collateralConfig.supplyCap != 0) {
      poolConfigurator.setSupplyCap(collateralConfig.underlying, 0);
    }
    if (testAssetConfig.supplyCap != 0) {
      poolConfigurator.setSupplyCap(testAssetConfig.underlying, 0);
    }
    if (testAssetConfig.borrowCap != 0) {
      poolConfigurator.setBorrowCap(testAssetConfig.underlying, 0);
    }
    vm.stopPrank();

    // eMode supplier enters eMode; regular supplier stays in eMode 0
    _enableIfEMode(collateralConfig, pool, vars.emodeCollateralSupplier);
    _deposit(collateralConfig, pool, vars.emodeCollateralSupplier, vars.collateralAssetAmount);
    _deposit(collateralConfig, pool, vars.regularCollateralSupplier, vars.collateralAssetAmount);
    _deposit(testAssetConfig, pool, vars.testAssetSupplier, vars.testAssetAmount);

    uint256 snapshotAfterDeposits = vm.snapshotState();

    // test deposits and withdrawals
    vars.aTokenTotalSupply = IERC20(testAssetConfig.aToken).totalSupply();
    vars.variableDebtTokenTotalSupply = IERC20(testAssetConfig.variableDebtToken).totalSupply();

    vm.prank(addressesProvider.getACLAdmin());
    poolConfigurator.setSupplyCap(
      testAssetConfig.underlying,
      vars.aTokenTotalSupply / 10 ** testAssetConfig.decimals + 1
    );
    vm.prank(addressesProvider.getACLAdmin());
    poolConfigurator.setBorrowCap(
      testAssetConfig.underlying,
      vars.variableDebtTokenTotalSupply / 10 ** testAssetConfig.decimals + 1
    );

    // caps should revert when supplying slightly more
    vm.expectRevert(bytes(SUPPLY_CAP_EXCEEDED));
    vm.prank(vars.testAssetSupplier);
    pool.deposit({
      asset: testAssetConfig.underlying,
      amount: 11 ** testAssetConfig.decimals,
      onBehalfOf: vars.testAssetSupplier,
      referralCode: 0
    });
    if (testAssetConfig.borrowingEnabled) {
      vars.borrowAmount = 11 ** testAssetConfig.decimals;

      if (vars.aTokenTotalSupply < vars.borrowAmount) {
        vm.prank(addressesProvider.getACLAdmin());
        poolConfigurator.setSupplyCap(testAssetConfig.underlying, 0);

        _deposit(
          testAssetConfig,
          pool,
          vars.testAssetSupplier,
          vars.borrowAmount - vars.aTokenTotalSupply
        );

        _deposit(
          collateralConfig,
          pool,
          vars.regularCollateralSupplier,
          (vars.collateralAssetAmount * vars.borrowAmount) / vars.aTokenTotalSupply
        );
      }

      vm.expectRevert(bytes(BORROW_CAP_EXCEEDED));
      vm.prank(vars.regularCollateralSupplier);
      pool.borrow({
        asset: testAssetConfig.underlying,
        amount: vars.borrowAmount,
        interestRateMode: 2,
        referralCode: 0,
        onBehalfOf: vars.regularCollateralSupplier
      });
    }

    vm.revertToState(snapshotAfterDeposits);

    _withdraw(testAssetConfig, pool, vars.testAssetSupplier, vars.testAssetAmount / 2);
    _withdraw(testAssetConfig, pool, vars.testAssetSupplier, type(uint256).max);

    vm.revertToState(snapshotAfterDeposits);

    // always test non-emode: borrow/repay/liquidation
    if (testAssetConfig.borrowingEnabled) {
      _testBorrowRepayLiquidation(
        pool,
        collateralConfig,
        testAssetConfig,
        vars.regularCollateralSupplier,
        vars.testAssetAmount,
        snapshotAfterDeposits
      );
    }

    // eMode: additional borrow/repay test if asset is eMode-borrowable
    if (
      testAssetConfig.borrowingEnabled &&
      _isBorrowableInCollateralEMode(pool, collateralConfig, testAssetConfig)
    ) {
      vm.revertToState(snapshotAfterDeposits);
      _testBorrowRepayLiquidation(
        pool,
        collateralConfig,
        testAssetConfig,
        vars.emodeCollateralSupplier,
        vars.testAssetAmount,
        snapshotAfterDeposits
      );
    }

    vm.revertToState(snapshotAfterDeposits);

    // test flashloans
    if (testAssetConfig.isFlashloanable) {
      _flashLoan({
        config: testAssetConfig,
        pool: pool,
        user: vars.regularCollateralSupplier,
        receiverAddress: address(this),
        amount: vars.testAssetAmount,
        interestRateMode: 0
      });

      if (testAssetConfig.borrowingEnabled) {
        _flashLoan({
          config: testAssetConfig,
          pool: pool,
          user: vars.regularCollateralSupplier,
          receiverAddress: address(this),
          amount: vars.testAssetAmount,
          interestRateMode: 2
        });
      }
    }
  }

  function _testBorrowRepayLiquidation(
    IPool pool,
    ReserveConfig memory collateralConfig,
    ReserveConfig memory testAssetConfig,
    address borrower,
    uint256 testAssetAmount,
    uint256 snapshotAfterDeposits
  ) internal {
    // borrow and repay
    _borrow({config: testAssetConfig, pool: pool, user: borrower, amount: testAssetAmount});

    uint256 snapshotBeforeRepay = vm.snapshotState();

    _repay({
      config: testAssetConfig,
      pool: pool,
      user: borrower,
      amount: testAssetAmount,
      withATokens: false
    });

    vm.revertToState(snapshotBeforeRepay);

    _repay({
      config: testAssetConfig,
      pool: pool,
      user: borrower,
      amount: testAssetAmount,
      withATokens: true
    });

    vm.revertToState(snapshotAfterDeposits);

    // liquidation
    _borrow({config: testAssetConfig, pool: pool, user: borrower, amount: testAssetAmount});

    if (testAssetConfig.underlying != collateralConfig.underlying) {
      _changeAssetPrice(pool, testAssetConfig, 1000_00);
    } else {
      _setAssetLtvAndLiquidationThreshold({
        pool: pool,
        config: testAssetConfig,
        newLtv: 5_00,
        newLiquidationThreshold: 5_00
      });
    }

    uint256 snapshotBeforeLiquidation = vm.snapshotState();

    _liquidationCall({
      collateralConfig: collateralConfig,
      debtConfig: testAssetConfig,
      pool: pool,
      liquidator: makeAddr('liquidator'),
      borrower: borrower,
      debtToCover: type(uint256).max,
      receiveAToken: false
    });

    vm.revertToState(snapshotBeforeLiquidation);

    if (!_isRwaToken(collateralConfig)) {
      _liquidationCall({
        collateralConfig: collateralConfig,
        debtConfig: testAssetConfig,
        pool: pool,
        liquidator: makeAddr('liquidator'),
        borrower: borrower,
        debtToCover: type(uint256).max,
        receiveAToken: true
      });
    }
  }

  function _isRwaToken(ReserveConfig memory config) internal view returns (bool) {
    bytes32 IMPL_SLOT = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
    address impl = address(uint160(uint256(vm.load(config.aToken, IMPL_SLOT))));
    return impl == AaveV3HorizonEthereum.RWA_ATOKEN_IMPL;
  }

  function _enableIfEMode(ReserveConfig memory config, IPool pool, address user) internal {
    vm.prank(user);
    pool.setUserEMode(0);

    // eMode id 0 is skipped intentionally as it is the reserved default
    for (uint256 id = 1; id <= 255; ++id) {
      uint256 reserveId = pool.getReserveData(config.underlying).id;
      if ((pool.getEModeCategoryCollateralBitmap(uint8(id)) >> reserveId) & 1 != 0) {
        vm.prank(user);
        pool.setUserEMode(uint8(id));
        break;
      }
    }
  }

  /**
   * @dev returns a "good" collateral in the list
   */
  function _goodCollateral(
    ReserveConfig[] memory configs
  ) internal pure returns (ReserveConfig memory config) {
    for (uint256 i = 0; i < configs.length; i++) {
      if (
        // not frozen etc
        // usable as collateral
        // not isolated asset as we can only borrow stablecoins against it
        // ltv is not 0
        _includeInE2e(configs[i]) &&
        configs[i].usageAsCollateralEnabled &&
        configs[i].debtCeiling == 0 &&
        configs[i].ltv != 0
      ) return configs[i];
    }
    revert('ERROR: No usable collateral found');
  }

  /**
   * @dev Checks if testAsset is borrowable in any eMode where collateral is accepted.
   */
  function _isBorrowableInCollateralEMode(
    IPool pool,
    ReserveConfig memory collateralConfig,
    ReserveConfig memory testAssetConfig
  ) internal view returns (bool) {
    uint256 collateralReserveId = pool.getReserveData(collateralConfig.underlying).id;
    uint256 testReserveId = pool.getReserveData(testAssetConfig.underlying).id;
    for (uint256 id = 1; id <= 255; ++id) {
      bool collateralInEMode = (pool.getEModeCategoryCollateralBitmap(uint8(id)) >>
        collateralReserveId) &
        1 !=
        0;
      bool borrowableInEMode = (pool.getEModeCategoryBorrowableBitmap(uint8(id)) >> testReserveId) &
        1 !=
        0;
      if (collateralInEMode && borrowableInEMode) return true;
    }
    return false;
  }

  function _testActors() internal returns (address[] memory actors) {
    actors = new address[](4);
    actors[0] = makeAddr('emodeCollateralSupplier');
    actors[1] = makeAddr('regularCollateralSupplier');
    actors[2] = makeAddr('testAssetSupplier');
    actors[3] = makeAddr('liquidator');
  }
}
