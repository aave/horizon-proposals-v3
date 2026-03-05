// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IDefaultInterestRateStrategyV2} from 'aave-v3-origin/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {HorizonConfigAssertionHelper} from 'tests/utils/HorizonConfigAssertionHelper.sol';
import {AaveV3Horizon_ACREDListing_20260217} from 'src/AaveV3Horizon_ACREDListing_20260217/AaveV3Horizon_ACREDListing_20260217.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

abstract contract AaveV3Horizon_ACREDListing_20260217_TestBase is ProtocolV3HorizonTestBase {
  AaveV3Horizon_ACREDListing_20260217 internal proposal;

  ExpectedAssetConfig internal expectedAssetConfig;
  ExpectedEModeConfig internal expectedEModeConfig;

  function setUp() public virtual {
    _setExpectedConfig();
  }

  function _pool() internal pure returns (IPool) {
    return IPool(AaveV3EthereumHorizonCustom.POOL);
  }

  function _setExpectedConfig() internal virtual override {
    expectedAssetConfig = ExpectedAssetConfig({
      underlying: AaveV3EthereumHorizonCustom.ACRED_UNDERLYING,
      isRwa: true,
      oracle: AaveV3EthereumHorizonCustom.ACRED_PRICE_FEED,
      aTokenName: 'Aave Horizon RWA ACRED',
      aTokenSymbol: 'aHorRwaACRED',
      variableDebtTokenName: 'Aave Horizon RWA Variable Debt ACRED',
      variableDebtTokenSymbol: 'variableDebtHorRwaACRED',
      supplyCap: 30_000,
      borrowCap: 0,
      reserveFactor: 0,
      borrowingEnabled: false,
      flashloanable: false,
      ltv: 66_00,
      liquidationThreshold: 76_00,
      liquidationBonus: 100_00 + 9_00,
      debtCeiling: 0,
      liqProtocolFee: 0,
      rateData: IDefaultInterestRateStrategyV2.InterestRateData({
        optimalUsageRatio: 99_00,
        baseVariableBorrowRate: 0,
        variableRateSlope1: 0,
        variableRateSlope2: 0
      })
    });
    expectedEModeConfig = ExpectedEModeConfig({
      eModeCategory: 3,
      ltv: 68_00,
      liquidationThreshold: 78_00,
      liquidationBonus: 100_00 + 9_00,
      label: 'ACRED GHO',
      collateralAssets: _toAddressArray(AaveV3EthereumHorizonCustom.ACRED_UNDERLYING),
      borrowableAssets: _toAddressArray(AaveV3EthereumHorizonAssets.GHO_UNDERLYING)
    });
  }
}

/**
 * @dev Test for Horizon ACRED listing (pre-execution).
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_ACREDListing_20260217_Test -vv
 */
contract AaveV3Horizon_ACREDListing_20260217_Test is AaveV3Horizon_ACREDListing_20260217_TestBase {
  function setUp() public virtual override {
    super.setUp();
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24473387);
    proposal = new AaveV3Horizon_ACREDListing_20260217();
  }

  /**
   * @dev executes the generic test suite including e2e and config snapshots
   */
  function test_defaultProposalExecution() public virtual {
    defaultTest_v3_3('AaveV3Horizon_ACREDListing_20260217', _pool(), address(proposal));
  }

  /**
   * @dev verifies the exact config values set by the ACRED listing payload
   */
  function test_acredConfig() public virtual {
    IPool pool = _pool();

    // check eMode 3 before execution (has config values but no assets assigned)
    _assertEModeConfig(
      pool,
      ExpectedEModeConfig({
        eModeCategory: 3,
        ltv: 72_00,
        liquidationThreshold: 79_00,
        liquidationBonus: 100_00 + 7_50,
        label: '',
        collateralAssets: new address[](0),
        borrowableAssets: new address[](0)
      })
    );

    // execute payload
    _executeHorizonPayload(address(proposal));

    // verify ACRED asset config
    _assertAssetConfig(pool, expectedAssetConfig);

    // verify eMode 3 = ACRED GHO after execution
    _assertEModeConfig(pool, expectedEModeConfig);
  }
}

/**
 * @dev Post-execution fork test. Run after the payload has been executed on mainnet
 *      to validate the live state matches expected config and run full E2E.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_ACREDListing_20260217_PostExecution_Test -vv
 */
contract AaveV3Horizon_ACREDListing_20260217_PostExecution_Test is
  AaveV3Horizon_ACREDListing_20260217_TestBase
{
  function setUp() public virtual override {
    super.setUp();
    vm.skip(true, 'skipping post-execution test');
    // TODO: pin to block after on-chain execution
    vm.createSelectFork(vm.rpcUrl('mainnet'));
    proposal = AaveV3Horizon_ACREDListing_20260217(0xD7b0ed496C468aDb1702D8dFe08383644b57a544);
    _executeHorizonPayload(address(proposal));
  }

  function test_defaultProposalExecution() public {
    defaultTest_v3_3_postExecution(_pool());
  }

  function test_acredConfig() public {
    _assertAssetConfig(_pool(), expectedAssetConfig);
    _assertEModeConfig(_pool(), expectedEModeConfig);
  }
}
