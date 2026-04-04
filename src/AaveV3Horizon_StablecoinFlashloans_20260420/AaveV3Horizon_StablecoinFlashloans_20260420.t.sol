// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolDataProvider} from 'aave-v3-origin/contracts/interfaces/IPoolDataProvider.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

/**
 * @dev Test for enabling flashloans on all Horizon stablecoins (GHO, USDC, RLUSD) via multisig transaction.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_StablecoinFlashloans_20260420_Test -vv
 */
contract AaveV3Horizon_StablecoinFlashloans_20260420_Test is ProtocolV3HorizonTestBase {
  // TODO: update OPS_DATA with the actual multisend calldata that enables flashloans on all 3 stablecoins
  address internal constant OPS_TARGET = 0x83Cb1B4af26EEf6463aC20AFbAC9c0e2E017202F;
  bytes internal constant OPS_DATA =
    hex'f213ef0e000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000000000001';
  uint256 internal constant OPS_NONCE = 46;

  IPoolDataProvider internal constant DATA_PROVIDER =
    IPoolDataProvider(AaveV3EthereumHorizon.AAVE_PROTOCOL_DATA_PROVIDER);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24803845);
  }

  function _executeStablecoinFlashloansUpdate() internal {
    _executeOpsMultisigTx({to: OPS_TARGET, data: OPS_DATA, operation: 1, nonce: OPS_NONCE});
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
