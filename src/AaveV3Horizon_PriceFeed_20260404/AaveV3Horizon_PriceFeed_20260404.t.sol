// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveOracle} from 'aave-v3-origin/contracts/interfaces/IAaveOracle.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book-latest/AaveV3Ethereum.sol';
import {IPriceCapAdapterStable} from 'src/interfaces/IPriceCapAdapterStable.sol';
import {AaveV3Horizon_PriceFeed_20260404} from './AaveV3Horizon_PriceFeed_20260404.sol';

/**
 * @dev Test for RLUSD & USDC price feed update on Horizon.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_PriceFeed_20260404_Test -vv
 */
contract AaveV3Horizon_PriceFeed_20260404_Test is ProtocolV3HorizonTestBase {
  AaveV3Horizon_PriceFeed_20260404 internal proposal;

  address internal constant OLD_RLUSD_ORACLE = AaveV3EthereumHorizonAssets.RLUSD_ORACLE;
  address internal constant OLD_USDC_ORACLE = AaveV3EthereumHorizonAssets.USDC_ORACLE;

  address internal newRlusdOracle; // stable cap adapter
  address internal newUsdcOracle; // stable cap adapter

  IPriceCapAdapterStable internal rlusdAdapter;
  IPriceCapAdapterStable internal usdcAdapter;

  /// 10200 bps expressed in the 8-decimal feed precision used by the adapter.
  int256 internal constant EXPECTED_PRICE_CAP = int256(10200) * 1e4;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24852499);
    proposal = new AaveV3Horizon_PriceFeed_20260404();

    newRlusdOracle = proposal.NEW_RLUSD_ORACLE();
    newUsdcOracle = proposal.NEW_USDC_ORACLE();

    rlusdAdapter = IPriceCapAdapterStable(newRlusdOracle);
    usdcAdapter = IPriceCapAdapterStable(newUsdcOracle);
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3('AaveV3Horizon_PriceFeed_20260404', _pool(), _executePayload);
  }

  /// 1 BPS = 0.01% expressed in 1e18 precision
  uint256 internal constant ONE_BPS = 1e14;

  /**
   * @dev Verify the RLUSD oracle is updated to the cap adapter.
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
    uint256 priceBefore = oracle.getAssetPrice(RLUSD);

    _executePayload();

    // AFTER
    assertEq(oracle.getSourceOfAsset(RLUSD), newRlusdOracle, 'RLUSD oracle after');
    uint256 priceAfter = oracle.getAssetPrice(RLUSD);
    assertApproxEqRel(
      priceAfter,
      priceBefore,
      ONE_BPS,
      'RLUSD price must be within 1 BPS of prior'
    );
  }

  /**
   * @dev Verify the USDC oracle is updated to the cap adapter.
   */
  function test_USDC_PriceFeedUpdate() public {
    IAaveOracle oracle = IAaveOracle(AaveV3EthereumHorizon.ORACLE);
    address USDC = AaveV3EthereumHorizonAssets.USDC_UNDERLYING;

    // BEFORE
    assertEq(oracle.getSourceOfAsset(USDC), OLD_USDC_ORACLE, 'USDC oracle before');
    assertTrue(
      oracle.getSourceOfAsset(USDC) != newUsdcOracle,
      'USDC oracle should differ from V3 core before'
    );
    uint256 priceBefore = oracle.getAssetPrice(USDC);

    _executePayload();

    // AFTER
    assertEq(oracle.getSourceOfAsset(USDC), newUsdcOracle, 'USDC oracle after');
    uint256 priceAfter = oracle.getAssetPrice(USDC);
    assertApproxEqRel(priceAfter, priceBefore, ONE_BPS, 'USDC price must be within 1 BPS of prior');
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

  /// @dev RLUSD stable cap adapter constructor params.
  function test_RLUSD_AdapterParams() public view {
    assertEq(
      rlusdAdapter.ACL_MANAGER(),
      address(AaveV3EthereumHorizon.ACL_MANAGER),
      'RLUSD adapter ACL_MANAGER mismatch'
    );
    assertEq(
      rlusdAdapter.ASSET_TO_USD_AGGREGATOR(),
      AaveV3EthereumHorizonAssets.RLUSD_ORACLE,
      'RLUSD adapter underlying must be Horizon non-SVR Chainlink feed'
    );
    assertEq(rlusdAdapter.getPriceCap(), EXPECTED_PRICE_CAP, 'RLUSD adapter price cap mismatch');
  }

  /// @dev USDC stable cap adapter constructor params.
  function test_USDC_AdapterParams() public view {
    assertEq(
      usdcAdapter.ACL_MANAGER(),
      address(AaveV3EthereumHorizon.ACL_MANAGER),
      'USDC adapter ACL_MANAGER mismatch'
    );
    assertEq(
      usdcAdapter.ASSET_TO_USD_AGGREGATOR(),
      AaveV3EthereumHorizonAssets.USDC_ORACLE,
      'USDC adapter underlying must be Horizon non-SVR Chainlink feed'
    );
    assertEq(usdcAdapter.getPriceCap(), EXPECTED_PRICE_CAP, 'USDC adapter price cap mismatch');
  }

  function _executePayload() internal {
    _executeHorizonPayload(address(proposal));
  }

  /// @dev Override expected price feeds so the snapshot validator in defaultTest accepts the new oracles.
  function _expectedPriceFeed(address underlying) internal override returns (address) {
    if (underlying == AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING) {
      return newRlusdOracle;
    }
    if (underlying == AaveV3EthereumHorizonAssets.USDC_UNDERLYING) {
      return newUsdcOracle;
    }
    return super._expectedPriceFeed(underlying);
  }
}
