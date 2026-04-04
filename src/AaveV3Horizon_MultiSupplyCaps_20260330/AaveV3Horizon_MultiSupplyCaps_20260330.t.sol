// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolDataProvider} from 'aave-v3-origin/contracts/interfaces/IPoolDataProvider.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

/**
 * @dev Test for GHO caps update via multisig transaction.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_MultiSupplyCaps_20260330 -vv
 */
contract AaveV3Horizon_MultiSupplyCaps_20260330 is ProtocolV3HorizonTestBase {
  address internal constant OPS_TARGET = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
  bytes internal constant OPS_DATA =
    hex'8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000002640083cb1b4af26eef6463ac20afbac9c0e2e017202f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044571f03e500000000000000000000000014d60e7fdc0d71d8611742720e4c50e7a974020c0000000000000000000000000000000000000000000000000000000000e4e1c00083cb1b4af26eef6463ac20afbac9c0e2e017202f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044571f03e500000000000000000000000040d16fc0246ad3160ccc09b8d0d3a2cd28ae6c2f0000000000000000000000000000000000000000000000000000000002160ec00083cb1b4af26eef6463ac20afbac9c0e2e017202f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044571f03e500000000000000000000000043415eb6ff9db7e26a15b704e7a3edce97d31c4e000000000000000000000000000000000000000000000000000000000036ee800083cb1b4af26eef6463ac20afbac9c0e2e017202f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044571f03e50000000000000000000000005a0f93d040de44e78f251b03c43be9cf317dcf64000000000000000000000000000000000000000000000000000000000098968000000000000000000000000000000000000000000000000000000000';
  uint256 internal constant OPS_NONCE = 44;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24770689);
  }

  function _executeMultiSupplyCapsUpdate() internal {
    _executeOpsMultisigTx({to: OPS_TARGET, data: OPS_DATA, operation: 1, nonce: OPS_NONCE});
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3(
      'AaveV3Horizon_MultiSupplyCaps_20260330',
      _pool(),
      _executeMultiSupplyCapsUpdate
    );
  }

  /**
   * @dev Custom before/after assertions for the GHO caps change.
   */
  function test_GhoSupplyCapsChange() public {
    (, uint256 supplyCapBefore) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.GHO_UNDERLYING
      )
    );
    assertEq(supplyCapBefore, 45_000_000, 'Supply cap before');
    _executeMultiSupplyCapsUpdate();

    (, uint256 supplyCapAfter) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.GHO_UNDERLYING
      )
    );
    assertEq(supplyCapAfter, 35_000_000, 'Supply cap after');
  }

  /**
   * @dev Custom before/after assertions for the JAAA caps change.
   */
  function test_JAAASupplyCapsChange() public {
    (, uint256 supplyCapBefore) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.JAAA_UNDERLYING
      )
    );
    assertEq(supplyCapBefore, 40_000_000, 'Supply cap before');
    _executeMultiSupplyCapsUpdate();

    (, uint256 supplyCapAfter) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.JAAA_UNDERLYING
      )
    );
    assertEq(supplyCapAfter, 10_000_000, 'Supply cap after');
  }

  /**
   * @dev Custom before/after assertions for the USCC caps change.
   */
  function test_USCCSupplyCapsChange() public {
    (, uint256 supplyCapBefore) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.USCC_UNDERLYING
      )
    );
    assertEq(supplyCapBefore, 29_000_000, 'Supply cap before');
    _executeMultiSupplyCapsUpdate();

    (, uint256 supplyCapAfter) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.USCC_UNDERLYING
      )
    );
    assertEq(supplyCapAfter, 15_000_000, 'Supply cap after');
  }

  /**
   * @dev Custom before/after assertions for the USTB caps change.
   */
  function test_USTBSupplyCapsChange() public {
    (, uint256 supplyCapBefore) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.USTB_UNDERLYING
      )
    );
    assertEq(supplyCapBefore, 1_800_000, 'Supply cap before');
    _executeMultiSupplyCapsUpdate();

    (, uint256 supplyCapAfter) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.USTB_UNDERLYING
      )
    );
    assertEq(supplyCapAfter, 3_600_000, 'Supply cap after');
  }
}
