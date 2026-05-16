// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorInterface} from 'aave-helpers/lib/aave-address-book/lib/aave-v3-origin/src/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {IAaveOracle} from 'aave-v3-origin/contracts/interfaces/IAaveOracle.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book-latest/AaveV3Ethereum.sol';
import {ChainlinkEthereum} from 'aave-address-book/ChainlinkEthereum.sol';
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
      'RLUSD adapter underlying must be Horizon feed'
    );
    assertEq(
      rlusdAdapter.ASSET_TO_USD_AGGREGATOR(),
      ChainlinkEthereum.RLUSD_USD,
      'RLUSD adapter underlying must equal the non-SVR Chainlink RLUSD/USD feed'
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
      'USDC adapter underlying must be Horizon feed'
    );
    assertEq(
      usdcAdapter.ASSET_TO_USD_AGGREGATOR(),
      ChainlinkEthereum.USDC_USD,
      'USDC adapter underlying must equal the non-SVR Chainlink USDC/USD feed'
    );
    assertEq(usdcAdapter.getPriceCap(), EXPECTED_PRICE_CAP, 'USDC adapter price cap mismatch');
  }

  /// @dev New adapters must report 8 decimals to match the oracle convention
  function test_newAdapters_decimals() public view {
    assertEq(AggregatorInterface(newRlusdOracle).decimals(), 8, 'RLUSD adapter decimals');
    assertEq(AggregatorInterface(newUsdcOracle).decimals(), 8, 'USDC adapter decimals');
  }

  /// @dev underlying Chainlink aggregators feeding each adapter report a fresh
  /// updatedAt (within USDC/USD and RLUSD/USD heartbeats)
  function test_oracleFreshness_preExec() public view {
    uint256 maxStaleness = 26 hours;

    address rlusdUnderlyingFeed = rlusdAdapter.ASSET_TO_USD_AGGREGATOR();
    (, int256 rlusdAnswer, , uint256 rlusdUpdatedAt, ) = AggregatorInterface(rlusdUnderlyingFeed)
      .latestRoundData();
    assertGt(rlusdAnswer, 0, 'RLUSD underlying answer should be > 0');
    assertGt(rlusdUpdatedAt, 0, 'RLUSD underlying updatedAt should be > 0');
    assertLt(
      block.timestamp - rlusdUpdatedAt,
      maxStaleness,
      'RLUSD underlying updatedAt older than heartbeat'
    );

    address usdcUnderlyingFeed = usdcAdapter.ASSET_TO_USD_AGGREGATOR();
    (, int256 usdcAnswer, , uint256 usdcUpdatedAt, ) = AggregatorInterface(usdcUnderlyingFeed)
      .latestRoundData();
    assertGt(usdcAnswer, 0, 'USDC underlying answer should be > 0');
    assertGt(usdcUpdatedAt, 0, 'USDC underlying updatedAt should be > 0');
    assertLt(
      block.timestamp - usdcUpdatedAt,
      maxStaleness,
      'USDC underlying updatedAt older than heartbeat'
    );
  }

  /// @dev new adapters are already deployed and live (latestAnswer > 0)
  /// and aligned with the currently configured oracles to within 1 BPS
  function test_priceFeeds_alignedPreExec() public view {
    int256 oldRlusd = AggregatorInterface(OLD_RLUSD_ORACLE).latestAnswer();
    int256 newRlusd = AggregatorInterface(newRlusdOracle).latestAnswer();
    assertGt(newRlusd, 0, 'new RLUSD adapter latestAnswer should be > 0');
    assertGt(oldRlusd, 0, 'old RLUSD oracle latestAnswer should be > 0');
    assertApproxEqRel(
      uint256(newRlusd),
      uint256(oldRlusd),
      ONE_BPS,
      'RLUSD: new adapter vs old oracle pre-exec diff > 1 BPS'
    );

    int256 oldUsdc = AggregatorInterface(OLD_USDC_ORACLE).latestAnswer();
    int256 newUsdc = AggregatorInterface(newUsdcOracle).latestAnswer();
    assertGt(newUsdc, 0, 'new USDC adapter latestAnswer should be > 0');
    assertGt(oldUsdc, 0, 'old USDC oracle latestAnswer should be > 0');
    assertApproxEqRel(
      uint256(newUsdc),
      uint256(oldUsdc),
      ONE_BPS,
      'USDC: new adapter vs old oracle pre-exec diff > 1 BPS'
    );
  }

  /// @dev after exec, exactly the two target reserves had
  /// their oracle source changed, all other reserves keep their prior source
  function test_noOldFeedRemainsAfterExec() public {
    IPool pool = _pool();
    IAaveOracle oracle = IAaveOracle(AaveV3EthereumHorizon.ORACLE);
    address[] memory reserves = pool.getReservesList();

    address[] memory sourcesBefore = new address[](reserves.length);
    for (uint256 i; i < reserves.length; ++i) {
      sourcesBefore[i] = oracle.getSourceOfAsset(reserves[i]);
    }

    _executePayload();

    address[] memory sourcesAfter = new address[](reserves.length);
    address[] memory replacedFeeds = new address[](reserves.length);
    uint256 replacedCount;
    for (uint256 i; i < reserves.length; ++i) {
      sourcesAfter[i] = oracle.getSourceOfAsset(reserves[i]);
      if (sourcesBefore[i] != sourcesAfter[i]) {
        replacedFeeds[replacedCount++] = sourcesBefore[i];
      }
    }

    assertEq(replacedCount, 2, 'expected exactly 2 reserves with oracle source change');

    for (uint256 i; i < reserves.length; ++i) {
      if (
        reserves[i] == AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING ||
        reserves[i] == AaveV3EthereumHorizonAssets.USDC_UNDERLYING
      ) {
        continue;
      }
      assertEq(
        sourcesAfter[i],
        sourcesBefore[i],
        string.concat('non-target reserve oracle changed: ', vm.toString(reserves[i]))
      );
    }

    for (uint256 i; i < reserves.length; ++i) {
      for (uint256 k; k < replacedCount; ++k) {
        assertNotEq(
          sourcesAfter[i],
          replacedFeeds[k],
          string.concat(
            'reserve ',
            vm.toString(reserves[i]),
            ' still uses replaced feed ',
            vm.toString(replacedFeeds[k])
          )
        );
      }
    }
  }

  /// @dev Reserves list is unchanged
  function test_reservesList_unchanged() public {
    IPool pool = _pool();
    address[] memory before = pool.getReservesList();

    _executePayload();

    address[] memory afterList = pool.getReservesList();
    assertEq(afterList.length, before.length, 'reservesList length changed');
    for (uint256 i; i < before.length; ++i) {
      assertEq(
        afterList[i],
        before[i],
        string.concat('reservesList[', vm.toString(i), '] changed')
      );
    }
  }

  /// @dev Underlying aggregators from each adapter with proper description
  function test_underlyingFeed_description() public view {
    assertEq(
      AggregatorInterface(rlusdAdapter.ASSET_TO_USD_AGGREGATOR()).description(),
      'RLUSD / USD',
      'RLUSD underlying description mismatch'
    );
    assertEq(
      AggregatorInterface(usdcAdapter.ASSET_TO_USD_AGGREGATOR()).description(),
      'USDC / USD',
      'USDC underlying description mismatch'
    );
  }

  /// @dev When the Chainlink feed reports a price above the adapter's cap, the
  /// pool oracle's `getAssetPrice` must bound to the cap
  function test_priceCapBounded_viaPool() public {
    _executePayload();

    IAaveOracle oracle = IAaveOracle(AaveV3EthereumHorizon.ORACLE);

    _assertCapBounded(oracle, AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING, rlusdAdapter, 'RLUSD');
    _assertCapBounded(oracle, AaveV3EthereumHorizonAssets.USDC_UNDERLYING, usdcAdapter, 'USDC');
  }

  function _assertCapBounded(
    IAaveOracle oracle,
    address underlying,
    IPriceCapAdapterStable adapter,
    string memory label
  ) internal {
    int256 priceCap = adapter.getPriceCap();
    int256 spike = priceCap + int256(1e7); // $0.10 above cap

    address underlyingFeed = adapter.ASSET_TO_USD_AGGREGATOR();
    vm.mockCall(
      underlyingFeed,
      abi.encodeWithSelector(AggregatorInterface.latestAnswer.selector),
      abi.encode(spike)
    );
    vm.mockCall(
      underlyingFeed,
      abi.encodeWithSelector(AggregatorInterface.latestRoundData.selector),
      abi.encode(uint80(1), spike, block.timestamp, block.timestamp, uint80(1))
    );

    uint256 priceFromPool = oracle.getAssetPrice(underlying);
    assertEq(
      priceFromPool,
      uint256(priceCap),
      string.concat(label, ': pool oracle price not clamped to cap on upstream spike')
    );

    vm.clearMockedCalls();
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
