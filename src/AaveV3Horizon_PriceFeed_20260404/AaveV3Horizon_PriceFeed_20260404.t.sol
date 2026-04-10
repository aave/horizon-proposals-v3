// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveOracle} from 'aave-v3-origin/contracts/interfaces/IAaveOracle.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book-latest/AaveV3Ethereum.sol';
import {AaveV3Horizon_PriceFeed_20260404} from './AaveV3Horizon_PriceFeed_20260404.sol';

/**
 * @dev Test for RLUSD & USDC price feed update on Horizon.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_PriceFeed_20260404_Test -vv
 */
contract AaveV3Horizon_PriceFeed_20260404_Test is ProtocolV3HorizonTestBase {
  AaveV3Horizon_PriceFeed_20260404 internal proposal;

  address internal constant OLD_RLUSD_ORACLE = AaveV3EthereumHorizonAssets.RLUSD_ORACLE;
  address internal constant OLD_USDC_ORACLE = AaveV3EthereumHorizonAssets.USDC_ORACLE;

  address internal constant NEW_RLUSD_ORACLE = 0x9E7c31e9b3C76Ea759D9f7464210353862F0c957; // stable cap adapter
  address internal constant NEW_USDC_ORACLE = 0x46f94aff8cF7DdC8557eF69f7276087b01C8f363; // stable cap adapter

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24852499);
    proposal = new AaveV3Horizon_PriceFeed_20260404();
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3('AaveV3Horizon_PriceFeed_20260404', _pool(), _executePayload);
  }

  /**
   * @dev Verify the RLUSD oracle is updated to the CAPO adapter.
   */
  function test_RLUSD_PriceFeedUpdate() public {
    IAaveOracle oracle = IAaveOracle(AaveV3EthereumHorizon.ORACLE);
    address RLUSD = AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING;

    // BEFORE
    assertEq(oracle.getSourceOfAsset(RLUSD), OLD_RLUSD_ORACLE, 'RLUSD oracle before');
    assertNotEq(
      oracle.getSourceOfAsset(RLUSD),
      AaveV3EthereumAssets.RLUSD_ORACLE,
      'RLUSD oracle should differ from V3 core before'
    );

    _executePayload();

    // AFTER
    assertEq(oracle.getSourceOfAsset(RLUSD), NEW_RLUSD_ORACLE, 'RLUSD oracle after');
    uint256 price = oracle.getAssetPrice(RLUSD);
    assertGt(price, 0, 'RLUSD price must be positive');
  }

  /**
   * @dev Verify the USDC oracle is updated to the CAPO adapter.
   */
  function test_USDC_PriceFeedUpdate() public {
    IAaveOracle oracle = IAaveOracle(AaveV3EthereumHorizon.ORACLE);
    address USDC = AaveV3EthereumHorizonAssets.USDC_UNDERLYING;

    // BEFORE
    assertEq(oracle.getSourceOfAsset(USDC), OLD_USDC_ORACLE, 'USDC oracle before');
    assertTrue(
      oracle.getSourceOfAsset(USDC) != NEW_USDC_ORACLE,
      'USDC oracle should differ from V3 core before'
    );

    _executePayload();

    // AFTER
    assertEq(oracle.getSourceOfAsset(USDC), NEW_USDC_ORACLE, 'USDC oracle after');
    uint256 price = oracle.getAssetPrice(USDC);
    assertGt(price, 0, 'USDC price must be positive');
  }

  /// @dev Verify GHO oracle already matches V3 core (only other stablecoin within both pools).
  function test_GHO_OracleAlreadyMatchesV3Core() public view {
    IAaveOracle oracle = IAaveOracle(AaveV3EthereumHorizon.ORACLE);
    assertEq(
      oracle.getSourceOfAsset(AaveV3EthereumHorizonAssets.GHO_UNDERLYING),
      AaveV3EthereumAssets.GHO_ORACLE,
      'GHO oracle should already match V3 core'
    );
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
