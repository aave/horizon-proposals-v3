// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolDataProvider} from 'aave-v3-origin/contracts/interfaces/IPoolDataProvider.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

/**
 * @dev Test for GHO caps update via multisig transaction.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_GHOcaps_20260312_Test -vv
 */
contract AaveV3Horizon_GHOcaps_20260312_Test is ProtocolV3HorizonTestBase {
  address internal constant OPS_TARGET = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
  bytes internal constant OPS_DATA =
    hex'8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001320083cb1b4af26eef6463ac20afbac9c0e2e017202f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044571f03e500000000000000000000000040d16fc0246ad3160ccc09b8d0d3a2cd28ae6c2f0000000000000000000000000000000000000000000000000000000002aea5400083cb1b4af26eef6463ac20afbac9c0e2e017202f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044d14a098300000000000000000000000040d16fc0246ad3160ccc09b8d0d3a2cd28ae6c2f0000000000000000000000000000000000000000000000000000000002160ec00000000000000000000000000000';
  uint256 internal constant OPS_NONCE = 42;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24644395);
  }

  function _executeGHOcapsUpdate() internal {
    _executeOpsMultisigTx({to: OPS_TARGET, data: OPS_DATA, operation: 1, nonce: OPS_NONCE});
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3('AaveV3Horizon_GHOcaps_20260312', _pool(), _executeGHOcapsUpdate);
  }

  /**
   * @dev Custom before/after assertions for the GHO caps change.
   */
  function test_ghoCapsChange() public {
    (uint256 borrowCapBefore, uint256 supplyCapBefore) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.GHO_UNDERLYING
      )
    );

    assertEq(borrowCapBefore, 43_000_000, 'Borrow cap before');
    assertEq(supplyCapBefore, 55_000_000, 'Supply cap before');

    _executeGHOcapsUpdate();

    (uint256 borrowCapAfter, uint256 supplyCapAfter) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.GHO_UNDERLYING
      )
    );

    assertEq(borrowCapAfter, 35_000_000, 'Borrow cap after');
    assertEq(supplyCapAfter, 45_000_000, 'Supply cap after');
  }
}
