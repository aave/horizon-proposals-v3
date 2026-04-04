// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolDataProvider} from 'aave-v3-origin/contracts/interfaces/IPoolDataProvider.sol';
import {IPoolConfigurator} from 'aave-v3-origin/contracts/interfaces/IPoolConfigurator.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveHorizonGovV3Helpers} from 'src/utils/AaveHorizonGovV3Helpers.sol';

/**
 * @dev Test for enabling flashloans on all Horizon stablecoins (GHO, USDC, RLUSD) via OPS multisig.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_StablecoinFlashloans_20260420_Test -vv
 */
contract AaveV3Horizon_StablecoinFlashloans_20260420_Test is ProtocolV3HorizonTestBase {
  uint256 internal constant OPS_NONCE = 46;

  IPoolDataProvider internal constant DATA_PROVIDER =
    IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24803845);
  }

  function _buildFlashloanActions()
    internal
    pure
    returns (AaveHorizonGovV3Helpers.Action[] memory)
  {
    AaveHorizonGovV3Helpers.Action[] memory actions = new AaveHorizonGovV3Helpers.Action[](3);
    actions[0] = AaveHorizonGovV3Helpers.Action({
      to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
      data: abi.encodeCall(
        IPoolConfigurator.setReserveFlashLoaning,
        (AaveV3EthereumHorizonAssets.GHO_UNDERLYING, true)
      )
    });
    actions[1] = AaveHorizonGovV3Helpers.Action({
      to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
      data: abi.encodeCall(
        IPoolConfigurator.setReserveFlashLoaning,
        (AaveV3EthereumHorizonAssets.USDC_UNDERLYING, true)
      )
    });
    actions[2] = AaveHorizonGovV3Helpers.Action({
      to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
      data: abi.encodeCall(
        IPoolConfigurator.setReserveFlashLoaning,
        (AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING, true)
      )
    });
    return actions;
  }

  function _executeStablecoinFlashloansUpdate() internal {
    (address to, bytes memory data, uint8 operation) = AaveHorizonGovV3Helpers
      .createOpsMultisigCalldata(_buildFlashloanActions());
    _executeOpsMultisigTx({to: to, data: data, operation: operation, nonce: OPS_NONCE});
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3(
      'AaveV3Horizon_StablecoinFlashloans_20260420',
      _pool(),
      _executeStablecoinFlashloansUpdate
    );
  }

  /**
   * @dev Verify flashloanable flag is enabled for all stablecoins after execution.
   */
  function test_stablecoinFlashloanable() public {
    // BEFORE
    assertFalse(
      DATA_PROVIDER.getFlashLoanEnabled(AaveV3EthereumHorizonAssets.GHO_UNDERLYING),
      'GHO flashloanable before'
    );
    assertFalse(
      DATA_PROVIDER.getFlashLoanEnabled(AaveV3EthereumHorizonAssets.USDC_UNDERLYING),
      'USDC flashloanable before'
    );
    assertFalse(
      DATA_PROVIDER.getFlashLoanEnabled(AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING),
      'RLUSD flashloanable before'
    );

    _executeStablecoinFlashloansUpdate();

    // AFTER
    assertTrue(
      DATA_PROVIDER.getFlashLoanEnabled(AaveV3EthereumHorizonAssets.GHO_UNDERLYING),
      'GHO flashloanable after'
    );
    assertTrue(
      DATA_PROVIDER.getFlashLoanEnabled(AaveV3EthereumHorizonAssets.USDC_UNDERLYING),
      'USDC flashloanable after'
    );
    assertTrue(
      DATA_PROVIDER.getFlashLoanEnabled(AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING),
      'RLUSD flashloanable after'
    );
  }
}
