// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {HorizonRwaWhitelistHelper} from 'tests/utils/HorizonRwaWhitelistHelper.sol';

/**
 * @dev Superstate whitelisting on either side of the 2026-09-22 switch from AllowlistV3 to
 *      AllowlistV4.2. A whitelisted address must be able to receive USTB and USCC.
 *
 *      command: FOUNDRY_PROFILE=test forge test --match-contract HorizonRwaWhitelistHelperTest -vv
 */
contract HorizonRwaWhitelistHelperTest is HorizonRwaWhitelistHelper {
  // Proposal tests pin blocks this old, where the token implementation predates `allowlist()`.
  uint256 internal constant LEGACY_BLOCK = 25095755;
  // AllowlistV4.2 is deployed but the tokens still read AllowlistV3.
  uint256 internal constant PRE_SWITCH_BLOCK = 25988000;
  uint256 internal constant POST_SWITCH_BLOCK = 26034966;

  address internal spender;

  function setUp() public {
    spender = makeAddr('spender');
  }

  function test_superstate_legacyBlock() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), LEGACY_BLOCK);
    _assertCanReceiveSuperstate();
  }

  function test_superstate_preSwitch() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), PRE_SWITCH_BLOCK);
    _assertCanReceiveSuperstate();
  }

  function test_superstate_postSwitch() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), POST_SWITCH_BLOCK);
    _assertCanReceiveSuperstate();
  }

  function test_ustb_whitelisting() public {
    address token = AaveV3EthereumHorizonAssets.USTB_UNDERLYING;
    (address alice, address bob, uint256 amount) = _assertReceiveAndTransfer({
      token: token,
      source: AaveV3EthereumHorizonAssets.USTB_A_TOKEN
    });
    _assertTransferFrom({token: token, owner: bob, spender_: spender, to: alice, amount: amount});
  }

  function test_uscc_whitelisting() public {
    address token = AaveV3EthereumHorizonAssets.USCC_UNDERLYING;
    (address alice, address bob, uint256 amount) = _assertReceiveAndTransfer({
      token: token,
      source: AaveV3EthereumHorizonAssets.USCC_A_TOKEN
    });
    _assertTransferFrom({token: token, owner: bob, spender_: spender, to: alice, amount: amount});
  }

  function test_usyc_whitelisting() public {
    address token = AaveV3EthereumHorizonAssets.USYC_UNDERLYING;
    (address alice, address bob, uint256 amount) = _assertReceiveAndTransfer({
      token: token,
      source: AaveV3EthereumHorizonAssets.USYC_A_TOKEN
    });

    // USYC also requires the transferFrom caller to be whitelisted
    vm.prank(bob);
    IERC20(token).approve(spender, amount);
    vm.expectRevert(abi.encodeWithSignature('NotPermissioned()'));
    vm.prank(spender);
    IERC20(token).transferFrom(bob, alice, amount);

    _whitelistUsycRwa(spender);
    _assertTransferFrom({token: token, owner: bob, spender_: spender, to: alice, amount: amount});
  }

  function test_jtrsy_whitelisting() public {
    address token = AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING;
    (address alice, address bob, uint256 amount) = _assertReceiveAndTransfer({
      token: token,
      source: AaveV3EthereumHorizonAssets.JTRSY_A_TOKEN
    });
    _assertTransferFrom({token: token, owner: bob, spender_: spender, to: alice, amount: amount});
  }

  function test_jaaa_whitelisting() public {
    address token = AaveV3EthereumHorizonAssets.JAAA_UNDERLYING;
    (address alice, address bob, uint256 amount) = _assertReceiveAndTransfer({
      token: token,
      source: AaveV3EthereumHorizonAssets.JAAA_A_TOKEN
    });
    _assertTransferFrom({token: token, owner: bob, spender_: spender, to: alice, amount: amount});
  }

  function test_vbill_whitelisting() public {
    address token = AaveV3EthereumHorizonAssets.VBILL_UNDERLYING;
    (address alice, address bob, uint256 amount) = _assertReceiveAndTransfer({
      token: token,
      source: AaveV3EthereumHorizonAssets.VBILL_A_TOKEN
    });
    _assertTransferFrom({token: token, owner: bob, spender_: spender, to: alice, amount: amount});
  }

  function test_acred_whitelisting() public {
    address token = AaveV3EthereumHorizonAssets.ACRED_UNDERLYING;
    // the ACRED aToken holds no underlying at POST_SWITCH_BLOCK
    (address alice, address bob, uint256 amount) = _assertReceiveAndTransfer({
      token: token,
      source: ACRED_WHALE
    });
    _assertTransferFrom({token: token, owner: bob, spender_: spender, to: alice, amount: amount});
  }

  function test_mglobal_whitelisting() public {
    address token = AaveV3EthereumHorizonAssets.mGLOBAL_UNDERLYING;
    (address alice, address bob, uint256 amount) = _assertReceiveAndTransfer({
      token: token,
      source: AaveV3EthereumHorizonAssets.mGLOBAL_A_TOKEN
    });
    _assertTransferFrom({token: token, owner: bob, spender_: spender, to: alice, amount: amount});
  }

  function _assertReceiveAndTransfer(
    address token,
    address source
  ) internal returns (address, address, uint256) {
    vm.createSelectFork(vm.rpcUrl('mainnet'), POST_SWITCH_BLOCK);
    address alice = makeAddr('alice');
    address bob = makeAddr('bob');
    uint256 amount = 10 ** IERC20Detailed(token).decimals();

    vm.expectRevert();
    vm.prank(source);
    IERC20(token).transfer(makeAddr('outsider'), amount);

    address[] memory actors = new address[](2);
    actors[0] = alice;
    actors[1] = bob;
    _whitelistRwaUsers(actors);

    // receive
    _assertTransfer({token: token, from: source, to: alice, amount: amount});
    // transfer
    _assertTransfer({token: token, from: alice, to: bob, amount: amount});
    return (alice, bob, amount);
  }

  function _assertTransferFrom(
    address token,
    address owner,
    address spender_,
    address to,
    uint256 amount
  ) internal {
    vm.prank(owner);
    IERC20(token).approve(spender_, amount);

    uint256 ownerBalanceBefore = IERC20(token).balanceOf(owner);
    uint256 toBalanceBefore = IERC20(token).balanceOf(to);

    vm.prank(spender_);
    IERC20(token).transferFrom(owner, to, amount);

    assertEq(IERC20(token).balanceOf(owner), ownerBalanceBefore - amount, 'owner balance');
    assertEq(IERC20(token).balanceOf(to), toBalanceBefore + amount, 'recipient balance');
    assertEq(IERC20(token).allowance(owner, spender_), 0, 'allowance not spent');
  }

  function _assertTransfer(address token, address from, address to, uint256 amount) internal {
    uint256 fromBalanceBefore = IERC20(token).balanceOf(from);
    uint256 toBalanceBefore = IERC20(token).balanceOf(to);

    vm.prank(from);
    IERC20(token).transfer(to, amount);

    assertEq(IERC20(token).balanceOf(from), fromBalanceBefore - amount, 'sender balance');
    assertEq(IERC20(token).balanceOf(to), toBalanceBefore + amount, 'recipient balance');
  }

  function _assertCanReceiveSuperstate() internal {
    address recipient = makeAddr('recipient');
    _whitelistSuperstateRwa(recipient);

    // The aTokens hold the underlying and are allowlisted at every block above.
    _assertCanReceive({
      token: AaveV3EthereumHorizonAssets.USTB_UNDERLYING,
      sender: AaveV3EthereumHorizonAssets.USTB_A_TOKEN,
      recipient: recipient
    });
    _assertCanReceive({
      token: AaveV3EthereumHorizonAssets.USCC_UNDERLYING,
      sender: AaveV3EthereumHorizonAssets.USCC_A_TOKEN,
      recipient: recipient
    });
  }

  function _assertCanReceive(address token, address sender, address recipient) internal {
    uint256 amount = 1;
    assertGe(IERC20(token).balanceOf(sender), amount, 'sender has no balance');

    vm.prank(sender);
    IERC20(token).transfer(recipient, amount);

    assertEq(IERC20(token).balanceOf(recipient), amount, 'recipient did not receive');
  }
}
