// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolDataProvider} from 'aave-v3-origin/contracts/interfaces/IPoolDataProvider.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';

/**
 * @dev Test for GHO caps update via multisig transaction.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_ACREDSupplyCap_20260401 -vv
 */
contract AaveV3Horizon_ACREDSupplyCap_20260401 is ProtocolV3HorizonTestBase {
  address internal constant OPS_TARGET = 0x83Cb1B4af26EEf6463aC20AFbAC9c0e2E017202F;
  bytes internal constant OPS_DATA =
    hex'571f03e500000000000000000000000017418038ecf73ba4026c4f428547bf099706f27b0000000000000000000000000000000000000000000000000000000000000001';
  uint256 internal constant OPS_NONCE = 45;
  uint8 internal constant OPS_OPERATION = 0;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24786649);
  }

  function _executeACREDSupplyCapUpdate() internal {
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
    defaultTest_v3_3(
      'AaveV3Horizon_ACREDSupplyCap_20260401',
      _pool(),
      _executeACREDSupplyCapUpdate
    );
  }

  /**
   * @dev Custom before/after assertions for the ACRED supply cap change.
   */
  function test_ACREDSupplyCapsChange() public {
    (, uint256 supplyCapBefore) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonCustom.ACRED_UNDERLYING
      )
    );
    assertEq(supplyCapBefore, 30_000, 'Supply cap before');
    _executeACREDSupplyCapUpdate();

    (, uint256 supplyCapAfter) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonCustom.ACRED_UNDERLYING
      )
    );
    assertEq(supplyCapAfter, 1, 'Supply cap after');
  }
}
