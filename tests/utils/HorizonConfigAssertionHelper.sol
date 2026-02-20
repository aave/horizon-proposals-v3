// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {console2 as console} from 'forge-std/console2.sol';

import {AggregatorInterface} from 'aave-helpers/lib/aave-address-book/lib/aave-v3-origin/src/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {IERC20} from 'aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/forge-std/src/interfaces/IERC20.sol';
import {IERC20Metadata} from 'aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IAaveOracle} from 'aave-v3-origin/contracts/interfaces/IAaveOracle.sol';
import {IPriceOracleGetter} from 'aave-v3-origin/contracts/interfaces/IPriceOracleGetter.sol';
import {IACLManager} from 'aave-v3-origin/contracts/interfaces/IACLManager.sol';
import {IPoolAddressesProvider} from 'aave-v3-origin/contracts/interfaces/IPoolAddressesProvider.sol';
import {IDefaultInterestRateStrategyV2} from 'aave-v3-origin/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
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

  string public constant APPROVE_REVERTS = '80';

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
    // interest rate strategy params (in bps)
    IDefaultInterestRateStrategyV2.InterestRateData rateData;
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

  function _assertAssetConfig(IPool pool, ExpectedAssetConfig memory expected) internal {
    _assertReserveConfiguration(pool, expected);
    _assertAToken(pool, expected);
    _assertVariableDebtToken(pool, expected);
    _assertPriceFeed(pool, expected);
    _assertInterestRateStrategy(expected);
    if (expected.isRwa) {
      _assertRwaOracleRegistry(expected.underlying);
      _assertRwaATokenApproveReverts(pool, expected.underlying);
    }

    // full struct encode comparison sanity check
    ExpectedAssetConfig memory actual = _readAssetConfig(pool, expected.underlying);
    assertEq(abi.encode(actual), abi.encode(expected), 'asset config: full struct mismatch');
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
    assertEq(
      abi.encode(config),
      abi.encode(_toConfigMap(pool, expected)),
      'reserve config bitmap mismatch'
    );
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
    assertEq(AggregatorInterface(source).decimals(), 8, 'oracleDecimals');
  }

  function _assertInterestRateStrategy(ExpectedAssetConfig memory expected) internal view {
    IDefaultInterestRateStrategyV2 strategy = IDefaultInterestRateStrategyV2(
      AaveV3HorizonEthereum.DEFAULT_INTEREST_RATE_STRATEGY
    );
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = strategy
      .getInterestRateDataBps(expected.underlying);
    assertEq(rateData.optimalUsageRatio, expected.rateData.optimalUsageRatio, 'optimalUsageRatio');
    assertEq(
      rateData.baseVariableBorrowRate,
      expected.rateData.baseVariableBorrowRate,
      'baseVariableBorrowRate'
    );
    assertEq(
      rateData.variableRateSlope1,
      expected.rateData.variableRateSlope1,
      'variableRateSlope1'
    );
    assertEq(
      rateData.variableRateSlope2,
      expected.rateData.variableRateSlope2,
      'variableRateSlope2'
    );
    assertEq(
      abi.encode(rateData),
      abi.encode(expected.rateData),
      'interestRateData: struct mismatch'
    );
  }

  function _assertRwaOracleRegistry(address underlying) internal view {
    assertTrue(
      IRwaOracleParameterRegistry(AaveV3HorizonEthereum.RWA_ORACLE_PARAMS_REGISTRY).assetExists(
        underlying
      ),
      'rwaOracleRegistry: asset not registered'
    );
  }

  function _assertRwaATokenApproveReverts(IPool pool, address underlying) internal {
    address aToken = pool.getReserveAToken(underlying);
    vm.expectRevert(bytes(APPROVE_REVERTS));
    IERC20(aToken).approve(makeAddr('tmpUser'), 0);
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

    // encode comparison for scalar eMode fields
    DataTypes.CollateralConfig memory expectedCC = DataTypes.CollateralConfig({
      ltv: uint16(expected.ltv),
      liquidationThreshold: uint16(expected.liquidationThreshold),
      liquidationBonus: uint16(expected.liquidationBonus)
    });
    assertEq(abi.encode(cc), abi.encode(expectedCC), 'emode: collateral config struct mismatch');
  }

  // ─── Pool-wide validations ────────────────────────────────────────

  function _runHorizonValidations(IPool pool, ReserveConfig[] memory configs) internal {
    _validateAccessControl(pool);
    _validateOracles(pool, configs);
    _validateATokenImplementations(configs);
    _validateRwaOracleRegistrations(configs);
    _validateInterestRateStrategies(configs);
    _validateConfigSanity(configs);
  }

  function _validateAccessControl(IPool pool) internal view {
    IACLManager aclManager = IACLManager(
      IPoolAddressesProvider(pool.ADDRESSES_PROVIDER()).getACLManager()
    );

    // HORIZON_EXECUTOR: AssetListingAdmin + RiskAdmin only (listing executor)
    assertFalse(
      aclManager.isPoolAdmin(AaveV3HorizonEthereum.HORIZON_EXECUTOR),
      'VALIDATION: executor should not be pool admin'
    );
    assertFalse(
      aclManager.isEmergencyAdmin(AaveV3HorizonEthereum.HORIZON_EXECUTOR),
      'VALIDATION: executor should not be emergency admin'
    );
    assertTrue(
      aclManager.isAssetListingAdmin(AaveV3HorizonEthereum.HORIZON_EXECUTOR),
      'VALIDATION: executor should be asset listing admin'
    );
    assertTrue(
      aclManager.isRiskAdmin(AaveV3HorizonEthereum.HORIZON_EXECUTOR),
      'VALIDATION: executor should be risk admin'
    );

    // HORIZON_EMERGENCY: PoolAdmin + EmergencyAdmin only
    assertTrue(
      aclManager.isPoolAdmin(AaveV3HorizonEthereum.HORIZON_EMERGENCY),
      'VALIDATION: emergency should be pool admin'
    );
    assertTrue(
      aclManager.isEmergencyAdmin(AaveV3HorizonEthereum.HORIZON_EMERGENCY),
      'VALIDATION: emergency should be emergency admin'
    );
    assertFalse(
      aclManager.isAssetListingAdmin(AaveV3HorizonEthereum.HORIZON_EMERGENCY),
      'VALIDATION: emergency should not be asset listing admin'
    );
    assertFalse(
      aclManager.isRiskAdmin(AaveV3HorizonEthereum.HORIZON_EMERGENCY),
      'VALIDATION: emergency should not be risk admin'
    );

    // HORIZON_OPS: RiskAdmin only (operational multisig)
    assertFalse(
      aclManager.isPoolAdmin(AaveV3HorizonEthereum.HORIZON_OPS),
      'VALIDATION: ops should not be pool admin'
    );
    assertFalse(
      aclManager.isEmergencyAdmin(AaveV3HorizonEthereum.HORIZON_OPS),
      'VALIDATION: ops should not be emergency admin'
    );
    assertFalse(
      aclManager.isAssetListingAdmin(AaveV3HorizonEthereum.HORIZON_OPS),
      'VALIDATION: ops should not be asset listing admin'
    );
    assertTrue(
      aclManager.isRiskAdmin(AaveV3HorizonEthereum.HORIZON_OPS),
      'VALIDATION: ops should be risk admin'
    );
  }

  function _validateOracles(IPool pool, ReserveConfig[] memory configs) internal view {
    IAaveOracle oracle = IAaveOracle(
      IPoolAddressesProvider(pool.ADDRESSES_PROVIDER()).getPriceOracle()
    );
    for (uint256 i; i < configs.length; i++) {
      uint256 price = oracle.getAssetPrice(configs[i].underlying);
      assertTrue(price > 0, string.concat('VALIDATION: zero oracle price for ', configs[i].symbol));
      address source = oracle.getSourceOfAsset(configs[i].underlying);
      assertEq(
        AggregatorInterface(source).decimals(),
        8,
        string.concat('VALIDATION: unexpected oracle decimals for ', configs[i].symbol)
      );
      address expectedFeed = _expectedPriceFeed(configs[i].underlying);
      assertEq(
        source,
        expectedFeed,
        string.concat('VALIDATION: oracle source mismatch for ', configs[i].symbol)
      );
    }
  }

  function _expectedPriceFeed(address underlying) internal pure returns (address) {
    if (underlying == AaveV3HorizonEthereum.USTB_UNDERLYING) {
      return AaveV3HorizonEthereum.USTB_PRICE_FEED_ADAPTER;
    }
    if (underlying == AaveV3HorizonEthereum.USCC_UNDERLYING) {
      return AaveV3HorizonEthereum.USCC_PRICE_FEED_ADAPTER;
    }
    if (underlying == AaveV3HorizonEthereum.USYC_UNDERLYING) {
      return AaveV3HorizonEthereum.USYC_PRICE_FEED;
    }
    if (underlying == AaveV3HorizonEthereum.JTRSY_UNDERLYING) {
      return AaveV3HorizonEthereum.JTRSY_PRICE_FEED_ADAPTER;
    }
    if (underlying == AaveV3HorizonEthereum.JAAA_UNDERLYING) {
      return AaveV3HorizonEthereum.JAAA_PRICE_FEED_ADAPTER;
    }
    if (underlying == AaveV3HorizonEthereum.VBILL_UNDERLYING) {
      return AaveV3HorizonEthereum.VBILL_PRICE_FEED;
    }
    if (underlying == AaveV3HorizonEthereum.GHO_UNDERLYING) {
      return AaveV3HorizonEthereum.GHO_PRICE_FEED;
    }
    if (underlying == AaveV3HorizonEthereum.USDC_UNDERLYING) {
      return AaveV3HorizonEthereum.USDC_PRICE_FEED;
    }
    if (underlying == AaveV3HorizonEthereum.RLUSD_UNDERLYING) {
      return AaveV3HorizonEthereum.RLUSD_PRICE_FEED;
    }
    if (underlying == AaveV3HorizonEthereum.ACRED_UNDERLYING) {
      return AaveV3HorizonEthereum.ACRED_PRICE_FEED;
    }
  }

  function _validateATokenImplementations(ReserveConfig[] memory configs) internal {
    for (uint256 i; i < configs.length; i++) {
      address impl = address(uint160(uint256(vm.load(configs[i].aToken, EIP1967_IMPL_SLOT))));
      bool isRwa = impl == AaveV3HorizonEthereum.RWA_ATOKEN_IMPL;
      bool isStandard = impl == AaveV3HorizonEthereum.ATOKEN_IMPL;
      assertTrue(
        isRwa || isStandard,
        string.concat('VALIDATION: unknown aToken impl for ', configs[i].symbol)
      );
      // RWA aTokens must reject approve()
      if (isRwa) {
        vm.expectRevert(bytes('80'));
        IERC20(configs[i].aToken).approve(address(1), 0);
      }
    }
  }

  function _validateRwaOracleRegistrations(ReserveConfig[] memory configs) internal view {
    for (uint256 i; i < configs.length; i++) {
      address impl = address(uint160(uint256(vm.load(configs[i].aToken, EIP1967_IMPL_SLOT))));
      if (impl == AaveV3HorizonEthereum.RWA_ATOKEN_IMPL) {
        assertTrue(
          IRwaOracleParameterRegistry(AaveV3HorizonEthereum.RWA_ORACLE_PARAMS_REGISTRY).assetExists(
            configs[i].underlying
          ),
          string.concat('VALIDATION: RWA not in oracle registry for ', configs[i].symbol)
        );
      }
    }
  }

  function _validateInterestRateStrategies(ReserveConfig[] memory configs) internal view {
    IDefaultInterestRateStrategyV2 strategy = IDefaultInterestRateStrategyV2(
      AaveV3HorizonEthereum.DEFAULT_INTEREST_RATE_STRATEGY
    );
    for (uint256 i; i < configs.length; i++) {
      assertEq(
        configs[i].interestRateStrategy,
        address(strategy),
        string.concat('VALIDATION: unexpected IR strategy for ', configs[i].symbol)
      );
      IDefaultInterestRateStrategyV2.InterestRateData memory rateData = strategy
        .getInterestRateDataBps(configs[i].underlying);
      assertTrue(
        rateData.optimalUsageRatio > 0,
        string.concat('VALIDATION: zero optimalUsageRatio for ', configs[i].symbol)
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

  // ─── Read on-chain config into struct ────────────────────────────

  function _readAssetConfig(
    IPool pool,
    address underlying
  ) internal view returns (ExpectedAssetConfig memory c) {
    c.underlying = underlying;

    // aToken
    address aToken = pool.getReserveAToken(underlying);
    c.aTokenName = IERC20Metadata(aToken).name();
    c.aTokenSymbol = IERC20Metadata(aToken).symbol();
    address impl = address(uint160(uint256(vm.load(aToken, EIP1967_IMPL_SLOT))));
    c.isRwa = (impl == AaveV3HorizonEthereum.RWA_ATOKEN_IMPL);

    // variable debt token
    address vDebt = pool.getReserveVariableDebtToken(underlying);
    c.variableDebtTokenName = IERC20Metadata(vDebt).name();
    c.variableDebtTokenSymbol = IERC20Metadata(vDebt).symbol();

    // oracle
    IAaveOracle oracle = IAaveOracle(
      IPoolAddressesProvider(pool.ADDRESSES_PROVIDER()).getPriceOracle()
    );
    c.oracle = oracle.getSourceOfAsset(underlying);

    // config map
    DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(underlying);
    c.supplyCap = config.getSupplyCap();
    c.borrowCap = config.getBorrowCap();
    c.borrowingEnabled = config.getBorrowingEnabled();
    c.flashloanable = config.getFlashLoanEnabled();
    c.reserveFactor = config.getReserveFactor();
    c.ltv = config.getLtv();
    c.liquidationThreshold = config.getLiquidationThreshold();
    c.liquidationBonus = config.getLiquidationBonus();
    c.debtCeiling = config.getDebtCeiling();
    c.liqProtocolFee = config.getLiquidationProtocolFee();

    // rate data
    IDefaultInterestRateStrategyV2 strategy = IDefaultInterestRateStrategyV2(
      AaveV3HorizonEthereum.DEFAULT_INTEREST_RATE_STRATEGY
    );
    c.rateData = strategy.getInterestRateDataBps(underlying);
  }

  /**
   * @dev Reconstructs a ReserveConfigurationMap from expected values.
   *      Protocol-set fields (decimals, active, frozen, etc.) are copied from on-chain
   *      so the comparison isolates proposal-controlled fields.
   */
  function _toConfigMap(
    IPool pool,
    ExpectedAssetConfig memory expected
  ) internal view returns (DataTypes.ReserveConfigurationMap memory map) {
    map = pool.getConfiguration(expected.underlying);
    map.setLtv(expected.ltv);
    map.setLiquidationThreshold(expected.liquidationThreshold);
    map.setLiquidationBonus(expected.liquidationBonus);
    map.setBorrowingEnabled(expected.borrowingEnabled);
    map.setFlashLoanEnabled(expected.flashloanable);
    map.setReserveFactor(expected.reserveFactor);
    map.setBorrowCap(expected.borrowCap);
    map.setSupplyCap(expected.supplyCap);
    map.setDebtCeiling(expected.debtCeiling);
    map.setLiquidationProtocolFee(expected.liqProtocolFee);
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
