// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';
import {IERC20} from 'aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/forge-std/src/interfaces/IERC20.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {ProtocolV3TestBase, ReserveConfig} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPoolConfigurator} from 'aave-v3-origin/contracts/interfaces/IPoolConfigurator.sol';
import {IACLManager} from 'aave-v3-origin/contracts/interfaces/IACLManager.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {HorizonRwaWhitelistHelper} from 'tests/utils/HorizonRwaWhitelistHelper.sol';
import {HorizonConfigAssertionHelper} from 'tests/utils/HorizonConfigAssertionHelper.sol';
import {Errors} from 'src/dependencies/Errors.sol';

/**
 * @dev Adapted from ProtocolV3TestBase for the Horizon market (currently at Aave v3.3).
 * - GHO is listed as a normal reserve like prime market, removes special branches.
 * - Enable eMode before supplying if available.
 * - Skip liquidation with receiveAToken=true when collateral is RWA, since it is disabled.
 * - Adds helper to return all actors used in E2E test such that they may be whitelisted to hold RWA tokens.
 * - Update errors to v3.3 string format.
 */
abstract contract ProtocolV3HorizonTestBase is
  ProtocolV3TestBase,
  HorizonRwaWhitelistHelper,
  HorizonConfigAssertionHelper
{
  struct E2ETestAssetLocalVars {
    uint256 collateralAssetAmount;
    uint256 testAssetAmount;
    uint256 aTokenTotalSupply;
    uint256 variableDebtTokenTotalSupply;
    uint256 borrowAmount;
  }

  // E2E test actors, reused across all asset tests
  address internal emodeCollateralSupplier;
  address internal regularCollateralSupplier;
  address internal testAssetSupplier;
  address internal liquidator;

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

    // pool-wide validations
    _runHorizonValidations(pool, configAfter);

    configChangePlausibilityTest(configBefore, configAfter);

    // whitelist E2E actors + aTokens on RWA compliance systems before running E2E
    _initTestActors();
    _whitelistRwaUsers(_testActorsArray());
    _whitelistRwaPool(pool);

    e2eTest_v3_3(pool);
    return (configBefore, configAfter);
  }

  /**
   * @dev Post-execution test suite. Forks after the payload has already been executed
   *      on mainnet and validates live state + runs full E2E without executing a payload.
   *      Skips aToken whitelisting since they are already whitelisted on mainnet.
   */
  function defaultTest_v3_3_postExecution(IPool pool) public {
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    _runHorizonValidations(pool, configs);

    _initTestActors();
    _whitelistRwaUsers(_testActorsArray());
    _whitelistRwaPool(pool);

    e2eTest_v3_3(pool);
  }

  /**
   * @dev Makes a e2e test including withdrawals/borrows and supplies to various reserves.
   * @param pool the pool that should be tested
   */
  function e2eTest_v3_3(IPool pool) public {
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    uint256 snapshot = vm.snapshotState();
    for (uint256 c; c < configs.length; c++) {
      if (!_isGoodCollateral(configs[c])) {
        continue;
      }
      for (uint256 i; i < configs.length; i++) {
        if (_includeInE2e(configs[i])) {
          e2eTestAsset_v3_3(pool, configs[c], configs[i]);
          vm.revertToState(snapshot);
        } else {
          console.log('E2E: TestAsset %s SKIPPED', configs[i].symbol);
        }
      }
    }
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
    _enableIfEMode(collateralConfig, pool, emodeCollateralSupplier);
    _supply(collateralConfig, pool, emodeCollateralSupplier, vars.collateralAssetAmount);
    _supply(collateralConfig, pool, regularCollateralSupplier, vars.collateralAssetAmount);
    _supply(testAssetConfig, pool, testAssetSupplier, vars.testAssetAmount);

    uint256 snapshotAfterDeposits = vm.snapshotState();

    // test deposits and withdrawals
    vars.aTokenTotalSupply = IERC20(testAssetConfig.aToken).totalSupply();
    vars.variableDebtTokenTotalSupply = IERC20(testAssetConfig.variableDebtToken).totalSupply();

    uint256 borrowCap = vars.variableDebtTokenTotalSupply / 10 ** testAssetConfig.decimals + 1;

    vm.prank(addressesProvider.getACLAdmin());
    poolConfigurator.setSupplyCap(
      testAssetConfig.underlying,
      vars.aTokenTotalSupply / 10 ** testAssetConfig.decimals + 1
    );
    vm.prank(addressesProvider.getACLAdmin());
    poolConfigurator.setBorrowCap(testAssetConfig.underlying, borrowCap);

    // caps should revert when supplying slightly more
    vm.expectRevert(bytes(Errors.SUPPLY_CAP_EXCEEDED));
    vm.prank(testAssetSupplier);
    pool.supply({
      asset: testAssetConfig.underlying,
      amount: 11 ** testAssetConfig.decimals,
      onBehalfOf: testAssetSupplier,
      referralCode: 0
    });
    if (testAssetConfig.borrowingEnabled) {
      // enough to exceed borrow cap
      vars.borrowAmount = 11 ** testAssetConfig.decimals;

      if (vars.aTokenTotalSupply < vars.borrowAmount) {
        vm.prank(addressesProvider.getACLAdmin());
        poolConfigurator.setSupplyCap(testAssetConfig.underlying, 0);

        _supply(
          testAssetConfig,
          pool,
          testAssetSupplier,
          vars.borrowAmount - vars.aTokenTotalSupply
        );

        _supply(
          collateralConfig,
          pool,
          regularCollateralSupplier,
          (vars.collateralAssetAmount * vars.borrowAmount) / vars.aTokenTotalSupply
        );
      }

      vm.expectRevert(bytes(Errors.BORROW_CAP_EXCEEDED));
      vm.prank(regularCollateralSupplier);
      pool.borrow({
        asset: testAssetConfig.underlying,
        amount: vars.borrowAmount,
        interestRateMode: 2,
        referralCode: 0,
        onBehalfOf: regularCollateralSupplier
      });
    }

    vm.revertToState(snapshotAfterDeposits);

    _withdraw(testAssetConfig, pool, testAssetSupplier, vars.testAssetAmount / 2);
    _withdraw(testAssetConfig, pool, testAssetSupplier, UINT256_MAX);

    vm.revertToState(snapshotAfterDeposits);

    // always test non-emode: borrow/repay/liquidation
    if (testAssetConfig.borrowingEnabled) {
      _testBorrowRepayLiquidation(
        pool,
        collateralConfig,
        testAssetConfig,
        regularCollateralSupplier,
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
        emodeCollateralSupplier,
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
        user: regularCollateralSupplier,
        receiverAddress: address(this),
        amount: vars.testAssetAmount,
        interestRateMode: 0
      });

      if (testAssetConfig.borrowingEnabled) {
        _flashLoan({
          config: testAssetConfig,
          pool: pool,
          user: regularCollateralSupplier,
          receiverAddress: address(this),
          amount: vars.testAssetAmount,
          interestRateMode: 2
        });
      }
    }
  }

  /**
   * @dev Execute a Horizon payload through the real executor path.
   * HORIZON_EMERGENCY calls HORIZON_EXECUTOR.executeTransaction() which delegatecalls
   * the payload. Matches the production multisig execution flow exactly.
   */
  function _executeHorizonPayload(address payload) internal {
    vm.startPrank(AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY);
    (bool success, bytes memory resultData) = AaveV3EthereumHorizonCustom.HORIZON_EXECUTOR.call(
      abi.encodeWithSignature(
        'executeTransaction(address,uint256,string,bytes,bool)',
        payload, // target
        0, // value
        'execute()', // signature
        '', // data
        true // withDelegatecall
      )
    );
    vm.stopPrank();
    if (!success) {
      if (resultData.length > 0) {
        assembly {
          revert(add(resultData, 32), mload(resultData))
        }
      }
      revert('_executeHorizonPayload: unknown error');
    }
  }

  function _initTestActors() internal {
    emodeCollateralSupplier = makeAddr('emodeCollateralSupplier');
    regularCollateralSupplier = makeAddr('regularCollateralSupplier');
    testAssetSupplier = makeAddr('testAssetSupplier');
    liquidator = makeAddr('liquidator');
  }

  function _testActorsArray() internal view returns (address[] memory actors) {
    actors = new address[](4);
    actors[0] = emodeCollateralSupplier;
    actors[1] = regularCollateralSupplier;
    actors[2] = testAssetSupplier;
    actors[3] = liquidator;
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
      liquidator: liquidator,
      borrower: borrower,
      debtToCover: UINT256_MAX,
      receiveAToken: false
    });

    vm.revertToState(snapshotBeforeLiquidation);

    if (!_isRwaToken(collateralConfig)) {
      _liquidationCall({
        collateralConfig: collateralConfig,
        debtConfig: testAssetConfig,
        pool: pool,
        liquidator: liquidator,
        borrower: borrower,
        debtToCover: UINT256_MAX,
        receiveAToken: true
      });
    } else {
      // attempting to borrow RWA should revert (borrowing disabled)
      vm.expectRevert(bytes(Errors.BORROWING_NOT_ENABLED));
      vm.prank(borrower);
      pool.borrow({
        asset: collateralConfig.underlying,
        amount: 1,
        interestRateMode: 2,
        referralCode: 0,
        onBehalfOf: borrower
      });
    }
  }

  function _isRwaToken(ReserveConfig memory config) internal view returns (bool) {
    address impl = address(uint160(uint256(vm.load(config.aToken, EIP1967_IMPL_SLOT))));
    return impl == AaveV3EthereumHorizonCustom.RWA_A_TOKEN_IMPL;
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

  function _isGoodCollateral(ReserveConfig memory config) internal pure returns (bool) {
    return
      _includeInE2e(config) &&
      config.usageAsCollateralEnabled &&
      config.debtCeiling == 0 &&
      config.ltv != 0;
  }

  /**
   * @dev Overrides `_deposit` to use whale transfers for tokens incompatible with
   *      foundry's `deal` (e.g. Securitize DSTokens that store balances in an external data store).
   */
  function _supply(
    ReserveConfig memory config,
    IPool pool,
    address user,
    uint256 amount
  ) internal virtual {
    if (_needsWhaleDeal(config.underlying)) {
      require(!config.isFrozen, 'DEPOSIT(): FROZEN_RESERVE');
      require(config.isActive, 'DEPOSIT(): INACTIVE_RESERVE');
      require(!config.isPaused, 'DEPOSIT(): PAUSED_RESERVE');

      uint256 aTokenBefore = IERC20(config.aToken).balanceOf(user);

      _dealRwaToken(config.underlying, user, amount);

      vm.startPrank(user);
      IERC20(config.underlying).approve(address(pool), amount);
      console.log('SUPPLY: %s, Amount: %s', config.symbol, amount);
      pool.supply(config.underlying, amount, user, 0);
      vm.stopPrank();

      uint256 aTokenAfter = IERC20(config.aToken).balanceOf(user);
      assertApproxEqAbs(aTokenAfter, aTokenBefore + amount, 2);
    } else {
      _deposit(config, pool, user, amount);
    }
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

  function _setExpectedConfig() internal virtual {}
}
