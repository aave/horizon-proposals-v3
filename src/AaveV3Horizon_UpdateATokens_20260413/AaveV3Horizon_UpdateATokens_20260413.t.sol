// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2 as console} from 'forge-std/console2.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol';

import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IRevenueSplitter} from 'aave-v3-origin/contracts/treasury/IRevenueSplitter.sol';
import {IAToken} from 'aave-v3-origin/contracts/interfaces/IAToken.sol';
import {IncentivizedERC20} from 'aave-v3-origin/contracts/protocol/tokenization/base/IncentivizedERC20.sol';
import {ATokenInstance} from 'aave-v3-origin/contracts/instances/ATokenInstance.sol';
import {DataTypes} from 'aave-v3-origin/contracts/protocol/libraries/types/DataTypes.sol';
import {ProtocolV3HorizonTestBase} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3Ethereum} from 'aave-address-book-latest/AaveV3Ethereum.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveHorizonGovV3Helpers} from 'src/utils/AaveHorizonGovV3Helpers.sol';

/// @dev Minimal interface for the v3.3 PoolConfigurator's updateAToken, with struct
/// including treasury + incentivesController (absent in latest v3-origin).
interface IPoolConfiguratorV3_3 {
  struct UpdateATokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  function updateAToken(UpdateATokenInput calldata input) external;
}

/**
 * @dev Test for emergency-ms driven batched aToken implementation updates.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_UpdateATokens_20260413 -vv
 */
contract AaveV3Horizon_UpdateATokens_20260413 is ProtocolV3HorizonTestBase {
  address internal constant A_TOKEN_IMPL = 0x9EB507147b99D3Cde32A53Bd5cd12bDEEaC26E5c;
  address internal constant RWA_A_TOKEN_IMPL = 0x5148d810B1DaE509d68f9d9219AD1d004EA32545;
  address internal constant NEW_TREASURY = address(AaveV3Ethereum.COLLECTOR);
  // multisg tx
  uint256 internal constant EMERGENCY_NONCE = 8;
  // from safe UI
  bytes internal constant EMERGENCY_DATA =
    hex'8d80ff0a0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000159300ae05cd22df81871bc7cc2a04becfb516bfe332c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001849cd199960000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000040d16fc0246ad3160ccc09b8d0d3a2cd28ae6c2f000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000008292bb45bf1ee4d140127049757c2e0ff06317ed00000000000000000000000043415eb6ff9db7e26a15b704e7a3edce97d31c4e00000000000000000000000014d60e7fdc0d71d8611742720e4c50e7a974020c000000000000000000000000136471a34f6ef19fe571effc1ca711fdb8e49f2b0000000000000000000000008c213ee79581ff4984583c6a801e5263418c4b860000000000000000000000005a0f93d040de44e78f251b03c43be9cf317dcf640000000000000000000000002255718832bc9fd3be1caf75084f4803da14ff0100000000000000000000000017418038ecf73ba4026c4f428547bf099706f27b0083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c000000000000000000000000000000000000000000000000000000000000002000000000000000000000000040d16fc0246ad3160ccc09b8d0d3a2cd28ae6c2f000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000009eb507147b99d3cde32a53bd5cd12bdeeac26e5c000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000144161766520486f72697a6f6e205257412047484f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a61486f7252776147484f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000009eb507147b99d3cde32a53bd5cd12bdeeac26e5c000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000154161766520486f72697a6f6e2052574120555344430000000000000000000000000000000000000000000000000000000000000000000000000000000000000b61486f725277615553444300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c00000000000000000000000000000000000000000000000000000000000000200000000000000000000000008292bb45bf1ee4d140127049757c2e0ff06317ed000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000009eb507147b99d3cde32a53bd5cd12bdeeac26e5c000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000164161766520486f72697a6f6e2052574120524c55534400000000000000000000000000000000000000000000000000000000000000000000000000000000000c61486f72527761524c555344000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c000000000000000000000000000000000000000000000000000000000000002000000000000000000000000043415eb6ff9db7e26a15b704e7a3edce97d31c4e000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000005148d810b1dae509d68f9d9219ad1d004ea32545000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000154161766520486f72697a6f6e2052574120555354420000000000000000000000000000000000000000000000000000000000000000000000000000000000000b61486f725277615553544200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c000000000000000000000000000000000000000000000000000000000000002000000000000000000000000014d60e7fdc0d71d8611742720e4c50e7a974020c000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000005148d810b1dae509d68f9d9219ad1d004ea32545000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000154161766520486f72697a6f6e2052574120555343430000000000000000000000000000000000000000000000000000000000000000000000000000000000000b61486f725277615553434300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000136471a34f6ef19fe571effc1ca711fdb8e49f2b000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000005148d810b1dae509d68f9d9219ad1d004ea32545000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000154161766520486f72697a6f6e2052574120555359430000000000000000000000000000000000000000000000000000000000000000000000000000000000000b61486f725277615553594300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c00000000000000000000000000000000000000000000000000000000000000200000000000000000000000008c213ee79581ff4984583c6a801e5263418c4b86000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000005148d810b1dae509d68f9d9219ad1d004ea32545000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000164161766520486f72697a6f6e20525741204a5452535900000000000000000000000000000000000000000000000000000000000000000000000000000000000c61486f725277614a54525359000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c00000000000000000000000000000000000000000000000000000000000000200000000000000000000000005a0f93d040de44e78f251b03c43be9cf317dcf64000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000005148d810b1dae509d68f9d9219ad1d004ea32545000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000154161766520486f72697a6f6e20525741204a4141410000000000000000000000000000000000000000000000000000000000000000000000000000000000000b61486f725277614a41414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c00000000000000000000000000000000000000000000000000000000000000200000000000000000000000002255718832bc9fd3be1caf75084f4803da14ff01000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000005148d810b1dae509d68f9d9219ad1d004ea32545000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000164161766520486f72697a6f6e20525741205642494c4c00000000000000000000000000000000000000000000000000000000000000000000000000000000000c61486f725277615642494c4c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083cb1b4af26eef6463ac20afbac9c0e2e017202f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a4bb01c37c000000000000000000000000000000000000000000000000000000000000002000000000000000000000000017418038ecf73ba4026c4f428547bf099706f27b000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d300000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000005148d810b1dae509d68f9d9219ad1d004ea32545000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000164161766520486f72697a6f6e2052574120414352454400000000000000000000000000000000000000000000000000000000000000000000000000000000000c61486f7252776141435245440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24873552);
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3('AaveV3Horizon_UpdateATokens_20260413', _pool(), _executeFullTx);
  }

  function test_updateATokenImpl_beforeAfter() public {
    address[] memory assets = _allTargetAssets();
    for (uint256 i; i < assets.length; i++) {
      uint256 snap = vm.snapshotState();
      _assertATokenImplUpdated(assets[i], IERC20Metadata(assets[i]).name());
      vm.revertToState(snap);
    }
  }

  function test_revenueMint_beforeAfter() public {
    address oldCollector = address(AaveV3EthereumHorizon.COLLECTOR);
    address[] memory assets = _allTargetAssets();

    uint256[] memory accruedBefore = new uint256[](assets.length);
    uint256[] memory oldCollectorScaledBalanceBefore = new uint256[](assets.length);

    for (uint256 i; i < assets.length; i++) {
      address aToken = _pool().getReserveAToken(assets[i]);
      accruedBefore[i] = _pool().getReserveData(assets[i]).accruedToTreasury;
      oldCollectorScaledBalanceBefore[i] = IAToken(aToken).scaledBalanceOf(oldCollector);
    }

    _executeFullTx();

    for (uint256 i; i < assets.length; i++) {
      address aToken = _pool().getReserveAToken(assets[i]);
      assertEq(
        _pool().getReserveData(assets[i]).accruedToTreasury,
        0,
        'accruedToTreasury must be 0 after mint'
      );
      assertEq(
        IAToken(aToken).scaledBalanceOf(oldCollector) - oldCollectorScaledBalanceBefore[i],
        accruedBefore[i],
        string.concat(
          'old collector scaled balance increase must equal accruedToTreasury before for ',
          IERC20Metadata(aToken).name()
        )
      );
    }
  }

  function test_calldata() public view {
    (address to, bytes memory data, uint8 operation) = _buildEmergencyUpdateATokensTx();
    assertEq(data, EMERGENCY_DATA, 'emergency MS tx data mismatch');

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

    // IAToken
    bytes32 domainSeparator = IAToken(aTokenProxy).DOMAIN_SEPARATOR();
    address underlyingAsset = IAToken(aTokenProxy).UNDERLYING_ASSET_ADDRESS();
    uint256 scaledTotalSupply = IAToken(aTokenProxy).scaledTotalSupply();

    // IncentivizedERC20
    string memory name = IncentivizedERC20(aTokenProxy).name();
    string memory symbol = IncentivizedERC20(aTokenProxy).symbol();
    uint256 decimals = IncentivizedERC20(aTokenProxy).decimals();
    address incentivesController = address(
      IncentivizedERC20(aTokenProxy).getIncentivesController()
    );
    uint256 totalSupply = IncentivizedERC20(aTokenProxy).totalSupply();
    DataTypes.ReserveDataLegacy memory reserveData = _pool().getReserveData(underlying);

    assertNotEq(
      _getATokenImplementation(underlying),
      _desiredImplForAssetBefore(underlying),
      string.concat('aToken impl should differ before for ', label)
    );
    assertEq(
      IAToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(),
      address(AaveV3EthereumHorizon.COLLECTOR)
    );
    assertNotEq(IAToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(), NEW_TREASURY);
    assertEq(ATokenInstance(_getATokenImplementation(underlying)).ATOKEN_REVISION(), 2);

    _executeFullTx();

    assertEq(
      _getATokenImplementation(underlying),
      _desiredImplForAssetAfter(underlying),
      string.concat('aToken impl mismatch after for ', label)
    );
    assertEq(
      IAToken(aTokenProxy).RESERVE_TREASURY_ADDRESS(),
      NEW_TREASURY,
      string.concat('treasury mismatch after for ', label)
    );
    assertEq(
      ATokenInstance(_getATokenImplementation(underlying)).ATOKEN_REVISION(),
      3,
      string.concat('aToken revision mismatch after for ', label)
    );
    // can increase from mintToTreasury
    assertGe(IncentivizedERC20(aTokenProxy).totalSupply(), totalSupply, 'totalSupply');
    assertGe(IAToken(aTokenProxy).scaledTotalSupply(), scaledTotalSupply, 'scaledTotalSupply');
    // unchanged fields
    assertEq(IncentivizedERC20(aTokenProxy).name(), name, 'name');
    assertEq(IncentivizedERC20(aTokenProxy).symbol(), symbol, 'symbol');
    assertEq(IncentivizedERC20(aTokenProxy).decimals(), decimals, 'decimals');
    assertEq(
      address(IncentivizedERC20(aTokenProxy).getIncentivesController()),
      incentivesController,
      'incentivesController'
    );
    assertEq(IAToken(aTokenProxy).DOMAIN_SEPARATOR(), domainSeparator, 'domainSeparator');
    assertEq(IAToken(aTokenProxy).UNDERLYING_ASSET_ADDRESS(), underlyingAsset, 'underlying');
    assertEq(_pool().getReserveData(underlying), reserveData, name);
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
      assets.length + 1
    );
    actions[0] = _buildMintToTreasuryAction(assets);
    for (uint256 i; i < assets.length; i++) {
      actions[i + 1] = _buildUpdateATokenAction(assets[i], _desiredImplForAssetBefore(assets[i]));
    }
    return AaveHorizonGovV3Helpers.createEmergencyMultisigCalldata(actions);
  }

  function _executeFullTx() internal {
    (address to, bytes memory data, uint8 operation) = _buildEmergencyUpdateATokensTx();
    _executeEmergencyMultisigTx({to: to, data: data, operation: operation, nonce: EMERGENCY_NONCE});
  }

  function _buildUpdateATokenAction(
    address underlying,
    address implementation
  ) internal view returns (AaveHorizonGovV3Helpers.Action memory) {
    address aTokenProxy = _pool().getReserveAToken(underlying);
    IPoolConfiguratorV3_3.UpdateATokenInput memory input = IPoolConfiguratorV3_3.UpdateATokenInput({
      asset: underlying,
      treasury: NEW_TREASURY,
      incentivesController: address(IncentivizedERC20(aTokenProxy).getIncentivesController()),
      name: IERC20Metadata(aTokenProxy).name(),
      symbol: IERC20Metadata(aTokenProxy).symbol(),
      implementation: implementation,
      params: bytes('')
    });
    return
      AaveHorizonGovV3Helpers.Action({
        to: address(AaveV3EthereumHorizon.POOL_CONFIGURATOR),
        data: abi.encodeCall(IPoolConfiguratorV3_3.updateAToken, (input))
      });
  }

  function _buildMintToTreasuryAction(
    address[] memory assets
  ) internal pure returns (AaveHorizonGovV3Helpers.Action memory) {
    return
      AaveHorizonGovV3Helpers.Action({
        to: address(AaveV3EthereumHorizon.POOL),
        data: abi.encodeCall(AaveV3EthereumHorizon.POOL.mintToTreasury, (assets))
      });
  }

  function _desiredImplForAssetBefore(address underlying) internal view returns (address) {
    address impl = _getATokenImplementation(underlying);
    if (impl == AaveV3EthereumHorizonCustom.DEFAULT_A_TOKEN_IMPL_PREV) {
      return A_TOKEN_IMPL;
    }
    if (impl == AaveV3EthereumHorizonCustom.RWA_A_TOKEN_IMPL_PREV) {
      return RWA_A_TOKEN_IMPL;
    }
    revert('unknown aToken implementation');
  }

  function _desiredImplForAssetAfter(address underlying) internal view returns (address) {
    address impl = _getATokenImplementation(underlying);
    if (impl == A_TOKEN_IMPL) {
      return A_TOKEN_IMPL;
    }
    if (impl == RWA_A_TOKEN_IMPL) {
      return RWA_A_TOKEN_IMPL;
    }
    revert('unknown aToken implementation');
  }

  function _getATokenImplementation(address underlying) internal view returns (address) {
    address aTokenProxy = _pool().getReserveAToken(underlying);
    return _getProxyImplementation(aTokenProxy);
  }

  function _allTargetAssets() internal view returns (address[] memory assets) {
    uint256 reservesCount = _pool().getReservesCount();
    assets = new address[](reservesCount);
    for (uint16 i; i < reservesCount; i++) {
      assets[i] = _pool().getReserveAddressById(i);
    }
  }

  function assertEq(
    DataTypes.ReserveDataLegacy memory a,
    DataTypes.ReserveDataLegacy memory b,
    string memory label
  ) internal pure {
    assertEq(a.configuration.data, b.configuration.data, string.concat('configuration ', label));
    assertEq(a.liquidityIndex, b.liquidityIndex, string.concat('liquidityIndex ', label));
    assertEq(
      a.currentLiquidityRate,
      b.currentLiquidityRate,
      string.concat('currentLiquidityRate ', label)
    );
    assertEq(
      a.variableBorrowIndex,
      b.variableBorrowIndex,
      string.concat('variableBorrowIndex ', label)
    );
    assertEq(
      a.currentVariableBorrowRate,
      b.currentVariableBorrowRate,
      string.concat('currentVariableBorrowRate ', label)
    );
    assertEq(
      a.currentStableBorrowRate,
      b.currentStableBorrowRate,
      string.concat('currentStableBorrowRate ', label)
    );
    assertEq(
      a.lastUpdateTimestamp,
      b.lastUpdateTimestamp,
      string.concat('lastUpdateTimestamp ', label)
    );
    assertEq(a.id, b.id, string.concat('id ', label));
    assertEq(a.aTokenAddress, b.aTokenAddress, string.concat('aTokenAddress ', label));
    assertEq(
      a.stableDebtTokenAddress,
      b.stableDebtTokenAddress,
      string.concat('stableDebtTokenAddress ', label)
    );
    assertEq(
      a.variableDebtTokenAddress,
      b.variableDebtTokenAddress,
      string.concat('variableDebtTokenAddress ', label)
    );
    assertEq(
      a.interestRateStrategyAddress,
      b.interestRateStrategyAddress,
      string.concat('interestRateStrategyAddress ', label)
    );
    assertEq(a.unbacked, b.unbacked, string.concat('unbacked ', label));
    assertEq(
      a.isolationModeTotalDebt,
      b.isolationModeTotalDebt,
      string.concat('isolationModeTotalDebt ', label)
    );
    assertEq(a.accruedToTreasury, 0, string.concat('accruedToTreasury ', label));
    // override accruedToTreasury to match the original value, to check the encoded data
    a.accruedToTreasury = b.accruedToTreasury;
    assertEq(abi.encode(a), abi.encode(b), string.concat('reserveData ', label));
  }
}
