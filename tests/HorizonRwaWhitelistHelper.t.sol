// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {HorizonRwaWhitelistHelper} from 'tests/utils/HorizonRwaWhitelistHelper.sol';

/**
 * @dev Superstate whitelisting on AllowlistV4.2. A whitelisted address must be able to receive
 *      USTB and USCC.
 *
 *      command: FOUNDRY_PROFILE=test forge test --match-contract HorizonRwaWhitelistHelperTest -vv
 */
contract HorizonRwaWhitelistHelperTest is HorizonRwaWhitelistHelper {
  // The tokens still read AllowlistV3.
  uint256 internal constant PRE_SWITCH_BLOCK = 25988000;
  uint256 internal constant POST_SWITCH_BLOCK = 26034966;

  function test_superstate_postSwitch() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), POST_SWITCH_BLOCK);
    _assertCanReceiveSuperstate();
  }

  function test_superstate_reverts_unknownAllowlist() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), PRE_SWITCH_BLOCK);
    vm.expectRevert(bytes('Superstate: unknown allowlist'));
    this.whitelistSuperstateRwa(makeAddr('recipient'));
  }

  function whitelistSuperstateRwa(address addressToWhitelist) external {
    _whitelistSuperstateRwa(addressToWhitelist);
  }

  function _assertCanReceiveSuperstate() internal {
    address recipient = makeAddr('recipient');
    _whitelistSuperstateRwa(recipient);

    // The aTokens hold the underlying and are allowlisted.
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
