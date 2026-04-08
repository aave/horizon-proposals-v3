// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveOracle} from 'aave-v3-origin/contracts/interfaces/IAaveOracle.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book-latest/AaveV3Ethereum.sol';
import {AaveV3Horizon_RLUSD_PriceFeed_20260404} from './AaveV3Horizon_RLUSD_PriceFeed_20260404.sol';

/**
 * @dev Test for RLUSD & USDC price feed update on Horizon.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_RLUSD_PriceFeed_20260404_Test -vv
 */
contract AaveV3Horizon_RLUSD_PriceFeed_20260404_Test is ProtocolV3HorizonTestBase {
  AaveV3Horizon_RLUSD_PriceFeed_20260404 internal proposal;

  address internal constant OLD_RLUSD_ORACLE = AaveV3EthereumHorizonAssets.RLUSD_ORACLE;
  address internal constant NEW_RLUSD_ORACLE = AaveV3EthereumAssets.RLUSD_ORACLE; // CAPO adapter

  address internal constant OLD_USDC_ORACLE = AaveV3EthereumHorizonAssets.USDC_ORACLE;
  address internal constant NEW_USDC_ORACLE = AaveV3EthereumAssets.USDC_ORACLE; // CAPO adapter

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24804293);
    proposal = new AaveV3Horizon_RLUSD_PriceFeed_20260404();
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3('AaveV3Horizon_RLUSD_PriceFeed_20260404', _pool(), _executePayload);
  }

  /**
   * @dev Verify the RLUSD oracle is updated to the CAPO adapter.
   */
  function test_RLUSD_PriceFeedUpdate() public {
    IAaveOracle oracle = IAaveOracle(AaveV3EthereumHorizon.ORACLE);
    address RLUSD = AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING;

    // BEFORE: Horizon oracle differs from V3 core
    assertEq(oracle.getSourceOfAsset(RLUSD), OLD_RLUSD_ORACLE, 'RLUSD oracle before');
    assertTrue(
      oracle.getSourceOfAsset(RLUSD) != AaveV3EthereumAssets.RLUSD_ORACLE,
      'RLUSD oracle should differ from V3 core before'
    );

    _executePayload();

    // AFTER: Horizon oracle matches V3 core
    assertEq(
      oracle.getSourceOfAsset(RLUSD),
      AaveV3EthereumAssets.RLUSD_ORACLE,
      'RLUSD oracle after'
    );
    uint256 price = oracle.getAssetPrice(RLUSD);
    assertGt(price, 0, 'RLUSD price must be positive');
  }

  /**
   * @dev Verify the USDC oracle is updated to the CAPO adapter.
   */
  function test_USDC_PriceFeedUpdate() public {
    IAaveOracle oracle = IAaveOracle(AaveV3EthereumHorizon.ORACLE);
    address USDC = AaveV3EthereumHorizonAssets.USDC_UNDERLYING;

    // BEFORE: Horizon oracle differs from V3 core
    assertEq(oracle.getSourceOfAsset(USDC), OLD_USDC_ORACLE, 'USDC oracle before');
    assertTrue(
      oracle.getSourceOfAsset(USDC) != AaveV3EthereumAssets.USDC_ORACLE,
      'USDC oracle should differ from V3 core before'
    );

    _executePayload();

    // AFTER: Horizon oracle matches V3 core
    assertEq(oracle.getSourceOfAsset(USDC), AaveV3EthereumAssets.USDC_ORACLE, 'USDC oracle after');
    uint256 price = oracle.getAssetPrice(USDC);
    assertGt(price, 0, 'USDC price must be positive');
  }

  /// @dev Override expected price feeds so the snapshot validator accepts the new oracles.
  function _expectedPriceFeed(address underlying) internal pure override returns (address) {
    if (underlying == AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING) {
      return NEW_RLUSD_ORACLE;
    }
    if (underlying == AaveV3EthereumHorizonAssets.USDC_UNDERLYING) {
      return NEW_USDC_ORACLE;
    }
    return super._expectedPriceFeed(underlying);
  }

  function _executePayload() internal {
    _executeHorizonPayload(address(proposal));
  }
}
