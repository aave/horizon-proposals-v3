// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {console2 as console} from 'forge-std/console2.sol';
import {IERC20Metadata} from 'aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IAaveOracle} from 'aave-v3-origin/contracts/interfaces/IAaveOracle.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol';
import {DataTypes} from 'aave-v3-origin/contracts/protocol/libraries/types/DataTypes.sol';
import {ReserveConfiguration} from 'aave-v3-origin/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {EModeConfiguration} from 'aave-v3-origin/contracts/protocol/libraries/configuration/EModeConfiguration.sol';
import {ReserveConfig} from 'aave-helpers/src/ProtocolV3TestBase.sol';
import {IRwaOracleParameterRegistry} from 'src/interfaces/IRwaOracleParameterRegistry.sol';
import {AaveV3HorizonEthereum} from 'src/utils/AaveV3HorizonEthereum.sol';

/**
 * @dev Config assertion helpers for Horizon proposals. Verifies that a payload
 *      set the exact intended parameter values for newly listed assets and eModes.
 *
 *      Also provides pool-wide validations (oracle prices, aToken implementations,
 *      config sanity) that run automatically on every proposal test.
 */
abstract contract HorizonConfigAssertionHelper is Test {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using EModeConfiguration for uint128;

  bytes32 internal constant EIP1967_IMPL_SLOT =
    bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);

  struct ExpectedAssetConfig {
    address underlying;
    bool isRwa;
    address oracle;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    uint256 supplyCap;
    uint256 borrowCap;
    uint256 reserveFactor;
    bool borrowingEnabled;
    bool flashloanable;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 debtCeiling;
    uint256 liqProtocolFee;
  }

  struct ExpectedEModeConfig {
    uint8 eModeCategory;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    string label;
    address[] collateralAssets;
    address[] borrowableAssets;
  }

  // ─── Per-asset config assertions ───────────────────────────────────

  function _assertAssetConfig(IPool pool, ExpectedAssetConfig memory expected) internal view {
    _assertReserveConfiguration(pool, expected);
    _assertAToken(pool, expected);
    _assertVariableDebtToken(pool, expected);
    _assertPriceFeed(pool, expected);
    _assertParamRegistry(expected);
  }

  function _assertReserveConfiguration(
    IPool pool,
    ExpectedAssetConfig memory expected
  ) internal view {
    DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(expected.underlying);
    assertEq(config.getSupplyCap(), expected.supplyCap, 'supplyCap');
    assertEq(config.getBorrowCap(), expected.borrowCap, 'borrowCap');
    assertEq(config.getBorrowingEnabled(), expected.borrowingEnabled, 'borrowingEnabled');
    assertEq(config.getFlashLoanEnabled(), expected.flashloanable, 'flashloanable');
    assertEq(config.getReserveFactor(), expected.reserveFactor, 'reserveFactor');
    assertEq(config.getLtv(), expected.ltv, 'ltv');
    assertEq(
      config.getLiquidationThreshold(),
      expected.liquidationThreshold,
      'liquidationThreshold'
    );
    assertEq(config.getLiquidationBonus(), expected.liquidationBonus, 'liquidationBonus');
    assertEq(config.getDebtCeiling(), expected.debtCeiling, 'debtCeiling');
    assertEq(config.getLiquidationProtocolFee(), expected.liqProtocolFee, 'liqProtocolFee');
    assertEq(config.getPaused(), false, 'paused');
  }

  function _assertAToken(IPool pool, ExpectedAssetConfig memory expected) internal view {
    address aToken = pool.getReserveAToken(expected.underlying);
    assertEq(IERC20Metadata(aToken).name(), expected.aTokenName, 'aTokenName');
    assertEq(IERC20Metadata(aToken).symbol(), expected.aTokenSymbol, 'aTokenSymbol');

    address impl = address(uint160(uint256(vm.load(aToken, EIP1967_IMPL_SLOT))));
    if (expected.isRwa) {
      assertEq(impl, AaveV3HorizonEthereum.RWA_ATOKEN_IMPL, 'rwaATokenImpl');
    } else {
      assertEq(impl, AaveV3HorizonEthereum.ATOKEN_IMPL, 'aTokenImpl');
    }
  }

  function _assertVariableDebtToken(IPool pool, ExpectedAssetConfig memory expected) internal view {
    address variableDebtToken = pool.getReserveVariableDebtToken(expected.underlying);
    assertEq(
      IERC20Metadata(variableDebtToken).name(),
      expected.variableDebtTokenName,
      'variableDebtTokenName'
    );
    assertEq(
      IERC20Metadata(variableDebtToken).symbol(),
      expected.variableDebtTokenSymbol,
      'variableDebtTokenSymbol'
    );

    address impl = address(uint160(uint256(vm.load(variableDebtToken, EIP1967_IMPL_SLOT))));
    assertEq(impl, AaveV3HorizonEthereum.VARIABLE_DEBT_TOKEN_IMPL, 'variableDebtTokenImpl');
  }

  function _assertPriceFeed(IPool pool, ExpectedAssetConfig memory expected) internal view {
    IAaveOracle oracle = IAaveOracle(
      IPoolAddressesProvider(pool.ADDRESSES_PROVIDER()).getPriceOracle()
    );
    address source = oracle.getSourceOfAsset(expected.underlying);
    assertEq(source, expected.oracle, 'oracleSource');

    uint256 price = oracle.getAssetPrice(expected.underlying);
    assertGt(price, 0, 'oraclePrice');
  }

  function _assertParamRegistry(ExpectedAssetConfig memory expected) internal view {
    assertEq(
      IRwaOracleParameterRegistry(AaveV3HorizonEthereum.RWA_ORACLE_PARAMS_REGISTRY).assetExists(
        expected.underlying
      ),
      true,
      'assetExists'
    );
  }

  // ─── eMode config assertions ──────────────────────────────────────

  function _assertEModeConfig(IPool pool, ExpectedEModeConfig memory expected) internal view {
    DataTypes.CollateralConfig memory cc = pool.getEModeCategoryCollateralConfig(
      expected.eModeCategory
    );
    assertEq(cc.ltv, expected.ltv, 'emode.ltv');
    assertEq(cc.liquidationThreshold, expected.liquidationThreshold, 'emode.liquidationThreshold');
    assertEq(cc.liquidationBonus, expected.liquidationBonus, 'emode.liquidationBonus');
    assertEq(pool.getEModeCategoryLabel(expected.eModeCategory), expected.label, 'emode.label');

    // verify collateral bitmap
    uint128 collateralBitmap = pool.getEModeCategoryCollateralBitmap(expected.eModeCategory);
    uint128 expectedCollateralBitmap;
    for (uint256 i; i < expected.collateralAssets.length; i++) {
      uint256 reserveId = pool.getReserveData(expected.collateralAssets[i]).id;
      assertTrue(
        collateralBitmap.isReserveEnabledOnBitmap(reserveId),
        string.concat('emode.collateral missing ', vm.toString(expected.collateralAssets[i]))
      );
      expectedCollateralBitmap = expectedCollateralBitmap.setReserveBitmapBit(reserveId, true);
    }
    assertEq(collateralBitmap, expectedCollateralBitmap, 'emode.collateralBitmap');

    // verify borrowable bitmap
    uint128 borrowableBitmap = pool.getEModeCategoryBorrowableBitmap(expected.eModeCategory);
    uint128 expectedBorrowableBitmap;
    for (uint256 i; i < expected.borrowableAssets.length; i++) {
      uint256 reserveId = pool.getReserveData(expected.borrowableAssets[i]).id;
      assertTrue(
        borrowableBitmap.isReserveEnabledOnBitmap(reserveId),
        string.concat('emode.borrowable missing ', vm.toString(expected.borrowableAssets[i]))
      );
      expectedBorrowableBitmap = expectedBorrowableBitmap.setReserveBitmapBit(reserveId, true);
    }
    assertEq(borrowableBitmap, expectedBorrowableBitmap, 'emode.borrowableBitmap');
  }

  // ─── Pool-wide validations ────────────────────────────────────────

  function _runHorizonValidations(IPool pool, ReserveConfig[] memory configs) internal view {
    _validateOracles(pool, configs);
    _validateATokenImplementations(configs);
    _validateConfigSanity(configs);
  }

  function _validateOracles(IPool pool, ReserveConfig[] memory configs) internal view {
    IAaveOracle oracle = IAaveOracle(
      IPoolAddressesProvider(pool.ADDRESSES_PROVIDER()).getPriceOracle()
    );
    for (uint256 i; i < configs.length; i++) {
      uint256 price = oracle.getAssetPrice(configs[i].underlying);
      assertTrue(price > 0, string.concat('VALIDATION: zero oracle price for ', configs[i].symbol));
    }
  }

  function _validateATokenImplementations(ReserveConfig[] memory configs) internal view {
    for (uint256 i; i < configs.length; i++) {
      address impl = address(uint160(uint256(vm.load(configs[i].aToken, EIP1967_IMPL_SLOT))));
      bool isRwa = impl == AaveV3HorizonEthereum.RWA_ATOKEN_IMPL;
      bool isStandard = impl == AaveV3HorizonEthereum.ATOKEN_IMPL;
      assertTrue(
        isRwa || isStandard,
        string.concat('VALIDATION: unknown aToken impl for ', configs[i].symbol)
      );
    }
  }

  function _validateConfigSanity(ReserveConfig[] memory configs) internal pure {
    for (uint256 i; i < configs.length; i++) {
      if (configs[i].usageAsCollateralEnabled) {
        assertTrue(
          configs[i].ltv <= configs[i].liquidationThreshold,
          string.concat('VALIDATION: ltv > liquidationThreshold for ', configs[i].symbol)
        );
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  function _toAddressArray(address a) internal pure returns (address[] memory arr) {
    arr = new address[](1);
    arr[0] = a;
  }

  function _toAddressArray(address a, address b) internal pure returns (address[] memory arr) {
    arr = new address[](2);
    arr[0] = a;
    arr[1] = b;
  }

  function _toAddressArray(
    address a,
    address b,
    address c
  ) internal pure returns (address[] memory arr) {
    arr = new address[](3);
    arr[0] = a;
    arr[1] = b;
    arr[2] = c;
  }
}
