// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IERC20Permit} from 'aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {IAToken} from 'aave-v3-origin/contracts/interfaces/IAToken.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveV3Horizon_mWINHINCListing_20261023} from 'src/AaveV3Horizon_mWINHINCListing_20261023/AaveV3Horizon_mWINHINCListing_20261023.sol';
import {ProtocolV3HorizonTestBase} from 'tests/utils/ProtocolV3HorizonTestBase.sol';

/**
 * @dev Fork tests for `supplyWithPermit` on every Horizon reserve whose underlying implements EIP-2612.
 *      The EIP-712 domain of each token is hardcoded, since issuers deviate from `name()` and the
 *      default version. VBILL, ACRED, mGLOBAL and mWIN have no `permit`.
 *      command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_SupplyWithPermit_Test -vv
 */
contract AaveV3Horizon_SupplyWithPermit_Test is ProtocolV3HorizonTestBase {
  bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 internal constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  IPool internal pool;
  address internal user;
  uint256 internal userPk;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 26254000);
    _executeHorizonPayload(address(new AaveV3Horizon_mWINHINCListing_20261023()));

    pool = _pool();
    (user, userPk) = makeAddrAndKey('permitSigner');
    // an EOA, so tokens verify the signature with ecrecover instead of ERC-1271
    assertEq(user.code.length, 0);

    _whitelistRwaPool(pool);
    address[] memory actors = new address[](1);
    actors[0] = user;
    _whitelistRwaUsers(actors);
  }

  function test_supplyWithPermit_USTB() public {
    _testSupplyWithPermit({
      asset: AaveV3EthereumHorizonAssets.USTB_UNDERLYING,
      name: 'Invesco Short Duration US Government Securities Fund',
      version: '1.3.0',
      isRwa: true
    });
  }

  function test_supplyWithPermit_USCC() public {
    _testSupplyWithPermit({
      asset: AaveV3EthereumHorizonAssets.USCC_UNDERLYING,
      name: 'Bitwise Crypto Carry Fund',
      version: '1.3.0',
      isRwa: true
    });
  }

  function test_supplyWithPermit_USYC() public {
    _testSupplyWithPermit({
      asset: AaveV3EthereumHorizonAssets.USYC_UNDERLYING,
      name: 'US Yield Coin',
      version: '2',
      isRwa: true
    });
  }

  function test_supplyWithPermit_JTRSY() public {
    _testSupplyWithPermit({
      asset: AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING,
      name: 'Centrifuge',
      version: '1',
      isRwa: true
    });
  }

  function test_supplyWithPermit_JAAA() public {
    _testSupplyWithPermit({
      asset: AaveV3EthereumHorizonAssets.JAAA_UNDERLYING,
      name: 'Centrifuge',
      version: '1',
      isRwa: true
    });
  }

  function test_supplyWithPermit_HINC() public {
    _testSupplyWithPermit({
      asset: AaveV3EthereumHorizonCustom.HINC_UNDERLYING,
      name: 'Neuberger Securitize High Income Tokenized Fund',
      version: '1',
      isRwa: true
    });
  }

  function test_supplyWithPermit_USDC() public {
    _testSupplyWithPermit({
      asset: AaveV3EthereumHorizonAssets.USDC_UNDERLYING,
      name: 'USD Coin',
      version: '2',
      isRwa: false
    });
  }

  function test_supplyWithPermit_GHO() public {
    _testSupplyWithPermit({
      asset: AaveV3EthereumHorizonAssets.GHO_UNDERLYING,
      name: 'Gho Token',
      version: '1',
      isRwa: false
    });
  }

  function test_supplyWithPermit_RLUSD() public {
    _testSupplyWithPermit({
      asset: AaveV3EthereumHorizonAssets.RLUSD_UNDERLYING,
      name: 'RLUSD',
      version: '1',
      isRwa: false
    });
  }

  function _testSupplyWithPermit(
    address asset,
    string memory name,
    string memory version,
    bool isRwa
  ) internal {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        block.chainid,
        asset
      )
    );
    assertEq(IERC20Permit(asset).DOMAIN_SEPARATOR(), domainSeparator);

    // removes the supply cap so a full reserve can't revert the supply before the permit is used
    vm.prank(AaveV3EthereumHorizonCustom.HORIZON_EXECUTOR);
    AaveV3EthereumHorizon.POOL_CONFIGURATOR.setSupplyCap(asset, 0);

    uint256 amount = 100 * 10 ** IERC20Detailed(asset).decimals();
    if (_needsWhaleDeal(asset)) {
      _dealRwaToken(asset, user, amount);
    } else {
      deal(asset, user, amount);
    }

    uint256 nonce = IERC20Permit(asset).nonces(user);
    uint256 deadline = vm.getBlockTimestamp() + 1 days;
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        domainSeparator,
        keccak256(abi.encode(PERMIT_TYPEHASH, user, address(pool), amount, nonce, deadline))
      )
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    if (isRwa) {
      vm.expectEmit(address(pool));
      emit IPool.ReserveUsedAsCollateralEnabled(asset, user);
    }
    vm.expectEmit(address(pool));
    emit IPool.Supply({
      reserve: asset,
      user: user,
      onBehalfOf: user,
      amount: amount,
      referralCode: 0
    });

    vm.prank(user);
    pool.supplyWithPermit({
      asset: asset,
      amount: amount,
      onBehalfOf: user,
      referralCode: 0,
      deadline: deadline,
      permitV: v,
      permitR: r,
      permitS: s
    });

    assertEq(IERC20Permit(asset).nonces(user), nonce + 1);
    assertEq(IERC20(asset).allowance(user, address(pool)), 0);
    assertEq(IERC20(asset).balanceOf(user), 0);
    // RWA reserves have borrowing disabled, so their liquidity index stays at 1 ray
    if (isRwa) assertEq(IAToken(pool.getReserveAToken(asset)).scaledBalanceOf(user), amount);
  }
}
