// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol';

import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IRevenueSplitter} from 'aave-v3-origin/contracts/treasury/IRevenueSplitter.sol';
import {IAToken} from 'aave-v3-origin/contracts/interfaces/IAToken.sol';
import {ConfiguratorInputTypes} from 'aave-v3-origin/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {IncentivizedERC20} from 'aave-v3-origin/contracts/protocol/tokenization/base/IncentivizedERC20.sol';
import {ATokenInstance} from 'aave-v3-origin/contracts/instances/ATokenInstance.sol';
import {ProtocolV3HorizonTestBase} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3Ethereum} from 'aave-address-book-latest/AaveV3Ethereum.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveHorizonGovV3Helpers} from 'src/utils/AaveHorizonGovV3Helpers.sol';

/**
 * @dev Test for emergency-ms driven batched aToken implementation updates.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_UpdateATokens_20260413 -vv
 */
contract AaveV3Horizon_UpdateATokens_20260413 is ProtocolV3HorizonTestBase {
  address internal constant A_TOKEN_IMPL = 0x9EB507147b99D3Cde32A53Bd5cd12bDEEaC26E5c;
  address internal constant RWA_A_TOKEN_IMPL = 0x5148d810B1DaE509d68f9d9219AD1d004EA32545;
  address internal constant NEW_TREASURY = address(AaveV3Ethereum.COLLECTOR);
  uint256 internal constant EMERGENCY_NONCE = 8;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'));
  }

  function test_updateATokenImpl_GHO_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonAssets.GHO_UNDERLYING, 'GHO');
  }

  function test_updateATokenImpl_USDC_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonAssets.USDC_UNDERLYING, 'USDC');
  }

  function test_updateATokenImpl_RLUSD_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING, 'RLUSD');
  }

  function test_updateATokenImpl_USTB_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonAssets.USTB_UNDERLYING, 'USTB');
  }

  function test_updateATokenImpl_USCC_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonAssets.USCC_UNDERLYING, 'USCC');
  }

  function test_updateATokenImpl_USYC_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonAssets.USYC_UNDERLYING, 'USYC');
  }

  function test_updateATokenImpl_JTRSY_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING, 'JTRSY');
  }

  function test_updateATokenImpl_JAAA_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonAssets.JAAA_UNDERLYING, 'JAAA');
  }

  function test_updateATokenImpl_VBILL_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonAssets.VBILL_UNDERLYING, 'VBILL');
  }

  function test_updateATokenImpl_ACRED_beforeAfter() public {
    _assertATokenImplUpdated(AaveV3EthereumHorizonCustom.ACRED_UNDERLYING, 'ACRED');
  }

  function test_revenueMint_beforeAfter() public {
    _executeFullTx();

    address[] memory assets = _allTargetAssets();
    for (uint256 i; i < assets.length; i++) {
      uint256 accruedAfter = _pool().getReserveData(assets[i]).accruedToTreasury;
      assertEq(accruedAfter, 0, 'accruedToTreasury must be 0 after mint');
    }
  }

  function test_revenueSplit_beforeAfter() public {
    address[] memory assets = _allTargetAssets();

    _executeFullTx();

    for (uint256 i; i < assets.length; i++) {
      address aToken = _pool().getReserveAToken(assets[i]);
      uint256 splitterBalanceAfter = IERC20(aToken).balanceOf(_treasuryForAsset(assets[i]));
      assertEq(splitterBalanceAfter, 0, 'splitter aToken balance must be 0 after split');
    }

    uint256 nativeRevenueAfter = address(_treasuryForAsset(assets[0])).balance;
    assertEq(nativeRevenueAfter, 0, 'native revenue must be 0 after split');
  }

  /// @dev Prints Safe tx fields and calldata for manual copy/paste.
  function test_printEmergencyUpdateATokensCalldata() public view {
    (address to, bytes memory data, uint8 operation) = _buildEmergencyUpdateATokensTx();
    console.log('=== Safe Transaction ===');
    console.log('safe:', AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY);
    console.log('to:', to);
    console.log('operation:', operation);
    console.log('nonce:', EMERGENCY_NONCE);
    console.log('calldata:');
    console.logBytes(data);
  }

  function _assertATokenImplUpdated(address underlying, string memory label) internal {
    address aTokenProxy = _pool().getReserveAToken(underlying);
    console.log('asset label:', label);
    console.log('aToken proxy:', aTokenProxy);
    console.log('reserve treasury:', IAToken(aTokenProxy).RESERVE_TREASURY_ADDRESS());

    address desiredImpl = _desiredImplForAsset(underlying);
    address implBefore = _getATokenImplementation(underlying);

    assertNotEq(
      implBefore,
      desiredImpl,
      string.concat('aToken impl should differ before for ', label)
    );
    assertNotEq(IAToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(), NEW_TREASURY);
    assertEq(ATokenInstance(implBefore).ATOKEN_REVISION(), 2);

    _executeFullTx();

    address implAfter = _getATokenImplementation(underlying);
    assertEq(implAfter, desiredImpl, string.concat('aToken impl mismatch after for ', label));
    assertEq(
      IAToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(),
      NEW_TREASURY,
      string.concat('treasury mismatch after for ', label)
    );
    assertEq(
      ATokenInstance(implAfter).ATOKEN_REVISION(),
      3,
      string.concat('aToken revision mismatch after for ', label)
    );
  }

  function _treasuryForAsset(address underlying) internal view returns (address) {
    return IAToken(_pool().getReserveAToken(underlying)).RESERVE_TREASURY_ADDRESS();
  }

  /// @dev Builds emergency multisig tx data for batched IPoolConfigurator.updateAToken calls.
  function _buildEmergencyUpdateATokensTx()
    internal
    view
    returns (address to, bytes memory data, uint8 operation)
  {
    address[] memory assets = _allTargetAssets();
    AaveHorizonGovV3Helpers.Action[] memory actions = new AaveHorizonGovV3Helpers.Action[](
      assets.length + 3
    );
    actions[0] = _buildMintToTreasuryAction(assets);
    actions[1] = _buildSplitRevenueAction(assets);
    actions[2] = _buildSplitNativeRevenueAction(_treasuryForAsset(assets[0]));
    for (uint256 i; i < assets.length; i++) {
      actions[i + 3] = _buildUpdateATokenAction(assets[i], _desiredImplForAsset(assets[i]));
    }
    return AaveHorizonGovV3Helpers.createEmergencyMultisigCalldata(actions);
  }

  function _executeFullTx() internal {
    // address[] memory assets = _allTargetAssets();
    // for (uint256 i; i < assets.length; i++) {
    //   address aTokenProxy = _pool().getReserveAToken(assets[i]);
    //   vm.store(aTokenProxy, bytes32(uint256(0)), bytes32(uint256(0))); // todo: delete
    // }

    (address to, bytes memory data, uint8 operation) = _buildEmergencyUpdateATokensTx();
    _executeEmergencyMultisigTx({to: to, data: data, operation: operation, nonce: EMERGENCY_NONCE});
  }

  function _buildUpdateATokenAction(
    address underlying,
    address implementation
  ) internal view returns (AaveHorizonGovV3Helpers.Action memory) {
    address aTokenProxy = _pool().getReserveAToken(underlying);
    ConfiguratorInputTypes.UpdateATokenInput memory input = ConfiguratorInputTypes
      .UpdateATokenInput({
        asset: underlying,
        name: IERC20Metadata(aTokenProxy).name(),
        symbol: IERC20Metadata(aTokenProxy).symbol(),
        implementation: implementation,
        params: bytes('')
      });
    address treasury = NEW_TREASURY;
    address incentivesController = address(
      IncentivizedERC20(aTokenProxy).getIncentivesController()
    );
    bytes4 legacyUpdateATokenSelector = bytes4(
      keccak256('updateAToken((address,address,address,string,string,address,bytes))')
    );
    return
      AaveHorizonGovV3Helpers.Action({
        to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
        data: abi.encodePacked(
          legacyUpdateATokenSelector,
          abi.encode(uint256(32)),
          abi.encode(
            input.asset,
            treasury,
            incentivesController,
            input.name,
            input.symbol,
            input.implementation,
            input.params
          )
        )
      });
  }

  function _buildMintToTreasuryAction(
    address[] memory assets
  ) internal pure returns (AaveHorizonGovV3Helpers.Action memory) {
    return
      AaveHorizonGovV3Helpers.Action({
        to: address(AaveV3EthereumHorizon.POOL),
        data: abi.encodeWithSignature('mintToTreasury(address[])', assets)
      });
  }

  function _buildSplitRevenueAction(
    address[] memory assets
  ) internal view returns (AaveHorizonGovV3Helpers.Action memory) {
    IERC20[] memory aTokens = new IERC20[](assets.length);
    for (uint256 i; i < assets.length; i++) {
      aTokens[i] = IERC20(_pool().getReserveAToken(assets[i]));
    }

    return
      AaveHorizonGovV3Helpers.Action({
        to: _treasuryForAsset(assets[0]),
        data: abi.encodeWithSelector(IRevenueSplitter.splitRevenue.selector, aTokens)
      });
  }

  function _buildSplitNativeRevenueAction(
    address treasury
  ) internal pure returns (AaveHorizonGovV3Helpers.Action memory) {
    return
      AaveHorizonGovV3Helpers.Action({
        to: treasury,
        data: abi.encodeWithSelector(IRevenueSplitter.splitNativeRevenue.selector)
      });
  }

  function _getATokenImplementation(address underlying) internal view returns (address) {
    address aTokenProxy = _pool().getReserveAToken(underlying);
    return _getProxyImplementation(aTokenProxy);
  }

  function _desiredImplForAsset(address underlying) internal pure returns (address) {
    if (
      underlying == AaveV3EthereumHorizonAssets.GHO_UNDERLYING ||
      underlying == AaveV3EthereumHorizonAssets.USDC_UNDERLYING ||
      underlying == AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING
    ) {
      return A_TOKEN_IMPL;
    }
    return RWA_A_TOKEN_IMPL;
  }

  function _allTargetAssets() internal pure returns (address[] memory assets) {
    assets = new address[](10);
    assets[0] = AaveV3EthereumHorizonAssets.GHO_UNDERLYING;
    assets[1] = AaveV3EthereumHorizonAssets.USDC_UNDERLYING;
    assets[2] = AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING;
    assets[3] = AaveV3EthereumHorizonAssets.USTB_UNDERLYING;
    assets[4] = AaveV3EthereumHorizonAssets.USCC_UNDERLYING;
    assets[5] = AaveV3EthereumHorizonAssets.USYC_UNDERLYING;
    assets[6] = AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING;
    assets[7] = AaveV3EthereumHorizonAssets.JAAA_UNDERLYING;
    assets[8] = AaveV3EthereumHorizonAssets.VBILL_UNDERLYING;
    assets[9] = AaveV3EthereumHorizonCustom.ACRED_UNDERLYING;
  }
}
