// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolDataProvider} from 'aave-v3-origin/contracts/interfaces/IPoolDataProvider.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveHorizonGovV3Helpers} from 'src/utils/AaveHorizonGovV3Helpers.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {console2 as console} from 'forge-std/console2.sol';

/**
 * @dev Test for GHO caps update via multisig transaction.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_CentrifugeSupplyCaps_20260515 -vv
 */
contract AaveV3Horizon_CentrifugeSupplyCaps_20260515 is ProtocolV3HorizonTestBase {
  address internal constant OPS_TARGET = 0x9641d764fc13c8B624c04430C7356C1C7C8102e2;
  bytes internal constant OPS_DATA =
    hex'8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001320083cb1b4af26eef6463ac20afbac9c0e2e017202f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044571f03e50000000000000000000000005a0f93d040de44e78f251b03c43be9cf317dcf640000000000000000000000000000000000000000000000000000000000c65d400083cb1b4af26eef6463ac20afbac9c0e2e017202f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044571f03e50000000000000000000000008c213ee79581ff4984583c6a801e5263418c4b8600000000000000000000000000000000000000000000000000000000009896800000000000000000000000000000';
  uint256 internal constant OPS_NONCE = 50;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 25101206);
  }

  function _executeMultiSupplyCapsUpdate() internal {
    _executeOpsMultisigTx({to: OPS_TARGET, data: OPS_DATA, operation: 1, nonce: OPS_NONCE});
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3(
      'AaveV3Horizon_CentrifugeSupplyCaps_20260515',
      _pool(),
      _executeMultiSupplyCapsUpdate
    );
  }

  /**
   * @dev Custom before/after assertions for the GHO caps change.
   */
  function test_JTRSYSupplyCapsChange() public {
    (, uint256 supplyCapBefore) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING
      )
    );
    assertEq(supplyCapBefore, 37_100_000, 'Supply cap before');
    _executeMultiSupplyCapsUpdate();

    (, uint256 supplyCapAfter) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING
      )
    );
    assertEq(supplyCapAfter, 10_000_000, 'Supply cap after');
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
    assertEq(supplyCapBefore, 10_000_000, 'Supply cap before');
    _executeMultiSupplyCapsUpdate();

    (, uint256 supplyCapAfter) = (
      IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER).getReserveCaps(
        AaveV3EthereumHorizonAssets.JAAA_UNDERLYING
      )
    );
    assertEq(supplyCapAfter, 13_000_000, 'Supply cap after');
  }

  function test_calldata() public pure {
    AaveHorizonGovV3Helpers.Action[] memory actions = new AaveHorizonGovV3Helpers.Action[](2);
    actions[0] = AaveHorizonGovV3Helpers.Action({
      to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
      data: abi.encodeCall(
        AaveV3EthereumHorizon.POOL_CONFIGURATOR.setSupplyCap,
        (AaveV3EthereumHorizonAssets.JAAA_UNDERLYING, 13_000_000)
      )
    });
    actions[1] = AaveHorizonGovV3Helpers.Action({
      to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
      data: abi.encodeCall(
        AaveV3EthereumHorizon.POOL_CONFIGURATOR.setSupplyCap,
        (AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING, 10_000_000)
      )
    });
    (address to, bytes memory data, uint8 operation) = AaveHorizonGovV3Helpers
      .createOpsMultisigCalldata(actions);
    assertEq(to, OPS_TARGET, 'ops target mismatch');
    assertEq(data, OPS_DATA, 'ops calldata mismatch');
    assertEq(operation, 1, 'ops operation mismatch');
  }
}
