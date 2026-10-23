// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IAaveOracle} from 'aave-v3-origin/contracts/interfaces/IAaveOracle.sol';
import {IAToken} from 'aave-v3-origin/contracts/interfaces/IAToken.sol';
import {DataTypes} from 'aave-v3-origin/contracts/protocol/libraries/types/DataTypes.sol';
import {IAaveV3ConfigEngine as IEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';
import {TestnetERC20} from 'aave-v3-origin/contracts/mocks/testnet-helpers/TestnetERC20.sol';
import {MockAggregator} from 'aave-v3-origin/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {AaveV3EthereumHorizon} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveV3PayloadHorizonEthereum} from 'src/utils/AaveV3PayloadHorizonEthereum.sol';
import {ProtocolV3HorizonTestBase} from 'tests/utils/ProtocolV3HorizonTestBase.sol';

contract ConfigEngineTestListing is AaveV3PayloadHorizonEthereum {
  address public immutable ASSET;
  address public immutable RWA_ASSET;
  address public immutable PRICE_FEED;

  constructor(address asset, address rwaAsset, address priceFeed) {
    ASSET = asset;
    RWA_ASSET = rwaAsset;
    PRICE_FEED = priceFeed;
  }

  function newListings() public view override returns (IEngine.Listing[] memory) {
    IEngine.Listing[] memory listings = new IEngine.Listing[](1);
    listings[0] = _listing(ASSET, 'TEST');
    return listings;
  }

  function newListingsCustom()
    public
    view
    override
    returns (IEngine.ListingWithCustomImpl[] memory)
  {
    IEngine.ListingWithCustomImpl[] memory listingsCustom = new IEngine.ListingWithCustomImpl[](1);
    listingsCustom[0] = IEngine.ListingWithCustomImpl({
      base: _listing(RWA_ASSET, 'RWATEST'),
      implementations: IEngine.TokenImplementations({
        aToken: AaveV3EthereumHorizonCustom.RWA_A_TOKEN_IMPL,
        vToken: AaveV3EthereumHorizonCustom.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL
      })
    });
    return listingsCustom;
  }

  function _listing(
    address asset,
    string memory assetSymbol
  ) internal view returns (IEngine.Listing memory) {
    return
      IEngine.Listing({
        asset: asset,
        assetSymbol: assetSymbol,
        priceFeed: PRICE_FEED,
        rateStrategyParams: AaveV3EthereumHorizonCustom.defaultRwaInterestRateInputData(),
        enabledToBorrow: EngineFlags.DISABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 50_00,
        liqThreshold: 60_00,
        liqBonus: 5_00,
        reserveFactor: 10_00,
        supplyCap: 1_000,
        borrowCap: 0,
        debtCeiling: 0,
        liqProtocolFee: 0
      });
  }
}

/**
 * @dev Fork test for the Horizon config engine at AaveV3EthereumHorizon.CONFIG_ENGINE.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_ConfigEngine_Test -vv
 */
contract AaveV3Horizon_ConfigEngine_Test is ProtocolV3HorizonTestBase {
  // https://etherscan.io/address/0xFB36A571995C04E6FcbC7611450E805c79535174
  address internal constant DEPLOYED_CONFIG_ENGINE = 0xFB36A571995C04E6FcbC7611450E805c79535174;
  // https://etherscan.io/address/0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
  address internal constant DAO_COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

  IEngine internal configEngine;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 26250993);
    configEngine = IEngine(AaveV3EthereumHorizonCustom.CONFIG_ENGINE);
  }

  function test_configEngine_address() public pure {
    assertEq(AaveV3EthereumHorizonCustom.CONFIG_ENGINE, DEPLOYED_CONFIG_ENGINE);
    assertEq(address(AaveV3EthereumHorizon.COLLECTOR), DAO_COLLECTOR);
  }

  function test_configEngine_constants() public view {
    assertEq(address(configEngine.POOL()), address(AaveV3EthereumHorizon.POOL));
    assertEq(
      address(configEngine.POOL_CONFIGURATOR()),
      address(AaveV3EthereumHorizon.POOL_CONFIGURATOR)
    );
    assertEq(address(configEngine.ORACLE()), address(AaveV3EthereumHorizon.ORACLE));
    assertEq(
      configEngine.REWARDS_CONTROLLER(),
      AaveV3EthereumHorizon.DEFAULT_INCENTIVES_CONTROLLER
    );
    assertEq(configEngine.COLLECTOR(), DAO_COLLECTOR);
    assertEq(
      configEngine.DEFAULT_INTEREST_RATE_STRATEGY(),
      AaveV3EthereumHorizonCustom.DEFAULT_INTEREST_RATE_STRATEGY
    );
    assertEq(configEngine.ATOKEN_IMPL(), AaveV3EthereumHorizon.DEFAULT_A_TOKEN_IMPL);
    assertEq(configEngine.VTOKEN_IMPL(), AaveV3EthereumHorizon.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL);
  }

  function test_listing() public {
    address priceFeed = address(new MockAggregator(1e8));
    address asset = address(new TestnetERC20('Test', 'TEST', 18, address(this)));
    address rwaAsset = address(new TestnetERC20('RWA Test', 'RWATEST', 6, address(this)));
    ConfigEngineTestListing payload = new ConfigEngineTestListing({
      asset: asset,
      rwaAsset: rwaAsset,
      priceFeed: priceFeed
    });

    _executeHorizonPayload(address(payload));

    _assertListing({
      asset: asset,
      aTokenImpl: AaveV3EthereumHorizonCustom.DEFAULT_A_TOKEN_IMPL,
      priceFeed: priceFeed
    });
    _assertListing({
      asset: rwaAsset,
      aTokenImpl: AaveV3EthereumHorizonCustom.RWA_A_TOKEN_IMPL,
      priceFeed: priceFeed
    });
  }

  function _assertListing(address asset, address aTokenImpl, address priceFeed) internal view {
    IPool pool = _pool();
    DataTypes.ReserveDataLegacy memory reserveData = pool.getReserveData(asset);

    assertEq(IAToken(reserveData.aTokenAddress).RESERVE_TREASURY_ADDRESS(), DAO_COLLECTOR);
    assertEq(_getProxyImplementation(reserveData.aTokenAddress), aTokenImpl);
    assertEq(
      _getProxyImplementation(reserveData.variableDebtTokenAddress),
      AaveV3EthereumHorizonCustom.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL
    );
    assertEq(
      reserveData.interestRateStrategyAddress,
      AaveV3EthereumHorizonCustom.DEFAULT_INTEREST_RATE_STRATEGY
    );
    assertEq(IAaveOracle(address(AaveV3EthereumHorizon.ORACLE)).getSourceOfAsset(asset), priceFeed);
  }
}
