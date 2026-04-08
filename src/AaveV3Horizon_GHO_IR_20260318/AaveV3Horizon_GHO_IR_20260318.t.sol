// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDefaultInterestRateStrategyV2} from 'aave-v3-origin/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import {ProtocolV3HorizonTestBase} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

/**
 * @dev Test for GHO interest rate update via multisig transaction.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_GHO_IR_20260318_Test -vv
 */
contract AaveV3Horizon_GHO_IR_20260318_Test is ProtocolV3HorizonTestBase {
  address internal constant OPS_TARGET = 0x83Cb1B4af26EEf6463aC20AFbAC9c0e2E017202F;
  bytes internal constant OPS_DATA =
    hex'6aabe21d00000000000000000000000040d16fc0246ad3160ccc09b8d0d3a2cd28ae6c2f0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000026ac000000000000000000000000000000000000000000000000000000000000011300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
  uint256 internal constant OPS_NONCE = 43;
  uint8 internal constant OPS_OPERATION = 0;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24684516);
  }

  function _executeGHOIRUpdate() internal {
    _executeOpsMultisigTx({
      to: OPS_TARGET,
      data: OPS_DATA,
      operation: OPS_OPERATION,
      nonce: OPS_NONCE
    });
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3('AaveV3Horizon_GHO_IR_20260318', _pool(), _executeGHOIRUpdate);
  }

  /**
   * @dev Custom before/after assertions for the GHO IR update.
   */
  function test_ghoIRUpdate() public {
    IDefaultInterestRateStrategyV2.InterestRateData memory interestRateDataBefore = (
      IDefaultInterestRateStrategyV2(AaveV3EthereumHorizonAssets.GHO_INTEREST_RATE_STRATEGY)
        .getInterestRateDataBps(AaveV3EthereumHorizonAssets.GHO_UNDERLYING)
    );

    assertEq(interestRateDataBefore.optimalUsageRatio, 99_00, 'Optimal usage ratio before');
    assertEq(
      interestRateDataBefore.baseVariableBorrowRate,
      3_25,
      'Base variable borrow rate before'
    );
    assertEq(interestRateDataBefore.variableRateSlope1, 0, 'Variable rate slope 1 before');
    assertEq(interestRateDataBefore.variableRateSlope2, 0, 'Variable rate slope 2 before');

    _executeGHOIRUpdate();

    IDefaultInterestRateStrategyV2.InterestRateData memory interestRateDataAfter = (
      IDefaultInterestRateStrategyV2(AaveV3EthereumHorizonAssets.GHO_INTEREST_RATE_STRATEGY)
        .getInterestRateDataBps(AaveV3EthereumHorizonAssets.GHO_UNDERLYING)
    );

    assertEq(interestRateDataAfter.optimalUsageRatio, 99_00, 'Optimal usage ratio after');
    assertEq(interestRateDataAfter.baseVariableBorrowRate, 2_75, 'Base variable borrow rate after');
    assertEq(interestRateDataAfter.variableRateSlope1, 0, 'Variable rate slope 1 after');
    assertEq(interestRateDataAfter.variableRateSlope2, 0, 'Variable rate slope 2 after');
  }
}
