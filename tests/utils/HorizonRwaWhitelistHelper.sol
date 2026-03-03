// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/forge-std/src/interfaces/IERC20.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

/**
 * @dev Helper for whitelisting E2E test actors on RWA compliance systems used
 *      by Horizon pool assets.  Each RWA issuer has its own compliance mechanism:
 *        - Superstate  (USTB, USCC) — AllowList.setEntityIdForAddress
 *        - Centrifuge  (JTRSY, JAAA) — RestrictionManager.endorse
 *        - Circle/USYC             — RolesAuthority.setUserRole
 *        - Securitize  (VBILL, ACRED) — RegistryService.addWallet
 *
 *      Override `_whitelistRwaActors` in concrete tests to add whitelisting for
 *      newly listed assets.
 */
abstract contract HorizonRwaWhitelistHelper is Test {
  // ── Superstate (USTB, USCC) ──────────────────────────────────────────
  address internal constant SUPERSTATE_ALLOWLIST_V2 = 0x02f1fA8B196d21c7b733EB2700B825611d8A38E5;
  uint256 internal constant SUPERSTATE_ROOT_ENTITY_ID = 1;

  // ── Centrifuge (JTRSY, JAAA) ─────────────────────────────────────────
  address internal constant CENTRIFUGE_HOOK = 0xa2C98F0F76Da0C97039688CA6280d082942d0b48;
  address internal constant CENTRIFUGE_WARD = 0xFEE13c017693a4706391D516ACAbF6789D5c3157;

  // ── Circle (USYC) ────────────────────────────────────────────────────
  uint8 internal constant CIRCLE_USYC_AUTHORIZED_ROLE = 19;
  address internal constant CIRCLE_SET_USER_ROLE_AUTHORIZED_CALLER =
    0xDbE01f447040F78ccbC8Dfd101BEc1a2C21f800D;

  // ── Securitize (VBILL, ACRED) ────────────────────────────────────────
  address internal constant SECURITIZE_ADMIN = 0xDA8e2d926D28a86aeE933d928357583aae5D3b85;
  string internal constant VBILL_SECURITIZE_FUND_ID = 'f27e20ca73314651b387da0aa9116f30';
  string internal constant ACRED_SECURITIZE_FUND_ID = '69023a78d57776eca9542d33';

  // ── Whale addresses for tokens incompatible with foundry `deal` ────
  // Securitize DS-protocol tokens store balances in an external data store,
  // so cannot use native foundry deal. Transfer from a real holder instead.
  address internal constant ACRED_WHALE = 0xa0759A0DFdE5395a1892aEd90eB5665698CFaa05;

  // ─── Orchestrator ────────────────────────────────────────────────────

  /**
   * @dev Whitelists all E2E test actors on every known RWA compliance system.
   *      Override in test contracts to add whitelisting for newly listed assets.
   */
  function _whitelistRwaActors(address[] memory actors) internal virtual {
    for (uint256 i; i < actors.length; i++) {
      // Superstate (USTB, USCC)
      _whitelistSuperstateRwa(actors[i]);
      // Circle (USYC) — msg.sender in transferFrom must also be whitelisted
      _whitelistUsycRwa(actors[i]);
      // Centrifuge (JTRSY, JAAA)
      _whitelistCentrifugeRwa(actors[i]);
      // Securitize (VBILL)
      _whitelistVbillRwa(actors[i]);
      // Securitize (ACRED) — only if listed (aToken exists)
      _whitelistAcredRwa(actors[i]);
    }
  }

  function _whitelistPoolContracts(IPool pool) internal {
    // Superstate (USTB, USCC)
    _whitelistSuperstateRwa(pool.getReserveAToken(AaveV3EthereumHorizonAssets.USTB_UNDERLYING));
    _whitelistSuperstateRwa(pool.getReserveAToken(AaveV3EthereumHorizonAssets.USCC_UNDERLYING));
    // Circle (USYC)
    _whitelistUsycRwa(pool.getReserveAToken(AaveV3EthereumHorizonAssets.USYC_UNDERLYING));
    // Circle (USYC) — msg.sender in transferFrom must also be whitelisted
    _whitelistUsycRwa(address(pool));
    // Centrifuge (JTRSY, JAAA)
    _whitelistCentrifugeRwa(pool.getReserveAToken(AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING));
    _whitelistCentrifugeRwa(pool.getReserveAToken(AaveV3EthereumHorizonAssets.JAAA_UNDERLYING));
    // Securitize (VBILL)
    _whitelistVbillRwa(pool.getReserveAToken(AaveV3EthereumHorizonAssets.VBILL_UNDERLYING));
    // Securitize (ACRED) — only if listed (aToken exists)
    _whitelistAcredRwa(pool.getReserveAToken(AaveV3EthereumHorizonCustom.ACRED_UNDERLYING));
  }

  // ─── Per-issuer helpers ──────────────────────────────────────────────

  function _whitelistSuperstateRwa(address addressToWhitelist) internal {
    (bool success, bytes memory data) = SUPERSTATE_ALLOWLIST_V2.call(
      abi.encodeWithSignature('owner()')
    );
    require(success, 'Failed to call owner()');
    address owner = abi.decode(data, (address));

    vm.prank(owner);
    (success, ) = SUPERSTATE_ALLOWLIST_V2.call(
      abi.encodeWithSignature(
        'setEntityIdForAddress(uint256,address)',
        SUPERSTATE_ROOT_ENTITY_ID,
        addressToWhitelist
      )
    );

    // Verify whitelisted
    (success, data) = SUPERSTATE_ALLOWLIST_V2.call(
      abi.encodeWithSignature('addressEntityIds(address)', addressToWhitelist)
    );
    require(success && abi.decode(data, (uint256)) != 0, 'Superstate: address not whitelisted');
  }

  function _whitelistCentrifugeRwa(address addressToWhitelist) internal {
    (bool success, bytes memory data) = CENTRIFUGE_HOOK.call(abi.encodeWithSignature('root()'));
    require(success, 'Failed to call root()');
    address root = abi.decode(data, (address));

    // Ensure CENTRIFUGE_WARD is authorized on root (wards mapping at slot 0)
    bytes32 wardSlot = keccak256(abi.encode(CENTRIFUGE_WARD, uint256(0)));
    vm.store(root, wardSlot, bytes32(uint256(1)));

    vm.prank(CENTRIFUGE_WARD);
    (success, ) = root.call(abi.encodeWithSignature('endorse(address)', addressToWhitelist));
    require(success, 'Failed to call endorse()');

    // Verify whitelisted
    (success, data) = root.call(abi.encodeWithSignature('endorsed(address)', addressToWhitelist));
    require(success && abi.decode(data, (bool)), 'Centrifuge: address not endorsed');
  }

  function _whitelistUsycRwa(address addressToWhitelist) internal {
    (bool success, bytes memory data) = AaveV3EthereumHorizonAssets.USYC_UNDERLYING.call(
      abi.encodeWithSignature('authority()')
    );
    require(success, 'Failed to call authority()');
    address authority = abi.decode(data, (address));

    vm.prank(CIRCLE_SET_USER_ROLE_AUTHORIZED_CALLER);
    (success, ) = authority.call(
      abi.encodeWithSignature(
        'setUserRole(address,uint8,bool)',
        addressToWhitelist,
        CIRCLE_USYC_AUTHORIZED_ROLE,
        true
      )
    );
    require(success, 'Failed to call setUserRole()');

    // Verify whitelisted
    (success, data) = authority.call(
      abi.encodeWithSignature(
        'doesUserHaveRole(address,uint8)',
        addressToWhitelist,
        CIRCLE_USYC_AUTHORIZED_ROLE
      )
    );
    require(success && abi.decode(data, (bool)), 'USYC: address not whitelisted');
  }

  function _whitelistVbillRwa(address addressToWhitelist) internal {
    _whitelistSecuritizeRwa(
      AaveV3EthereumHorizonAssets.VBILL_UNDERLYING,
      SECURITIZE_ADMIN,
      VBILL_SECURITIZE_FUND_ID,
      addressToWhitelist
    );
  }

  function _whitelistAcredRwa(address addressToWhitelist) internal {
    _whitelistSecuritizeRwa(
      AaveV3EthereumHorizonCustom.ACRED_UNDERLYING,
      SECURITIZE_ADMIN,
      ACRED_SECURITIZE_FUND_ID,
      addressToWhitelist
    );
  }

  /**
   * @dev Generic Securitize whitelisting via RegistryService.addWallet.
   *      Reuse for any Securitize DS-protocol token (VBILL, ACRED, etc.) by supplying
   *      the token-specific admin and fund reference ID.
   */
  function _whitelistSecuritizeRwa(
    address token,
    address admin,
    string memory fundId,
    address addressToWhitelist
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSignature('REGISTRY_SERVICE()'));
    require(success, 'Failed to call REGISTRY_SERVICE()');
    (success, data) = token.call(
      abi.encodeWithSignature('getDSService(uint256)', abi.decode(data, (uint256)))
    );
    require(success, 'Failed to call getDSService()');
    address registryService = abi.decode(data, (address));

    // Ensure admin has a role on the trust service (role mapping at slot 1)
    (success, data) = token.call(abi.encodeWithSignature('TRUST_SERVICE()'));
    require(success, 'Failed to call TRUST_SERVICE()');
    (success, data) = token.call(
      abi.encodeWithSignature('getDSService(uint256)', abi.decode(data, (uint256)))
    );
    require(success, 'Failed to call getDSService() for trust');
    address trustService = abi.decode(data, (address));
    bytes32 roleSlot = keccak256(abi.encode(admin, uint256(1)));
    vm.store(trustService, roleSlot, bytes32(uint256(2)));

    vm.prank(admin);
    (success, ) = registryService.call(
      abi.encodeWithSignature('addWallet(address,string)', addressToWhitelist, fundId)
    );

    // confirm the address already has a role (e.g. aToken = special wallet)
    if (success) {
      // Newly added — verify via isWallet
      (success, data) = registryService.call(
        abi.encodeWithSignature('isWallet(address)', addressToWhitelist)
      );
      require(success && abi.decode(data, (bool)), 'Securitize: addWallet ok but isWallet false');
    }
  }

  /// @dev Returns true if `token` requires tokens from whale instead of foundry's `deal`.
  function _needsWhaleDeal(address token) internal pure returns (bool) {
    return token == AaveV3EthereumHorizonCustom.ACRED_UNDERLYING;
  }

  /// @dev Returns the whale address for `token`.
  function _getWhale(address token) internal pure returns (address) {
    if (_needsWhaleDeal(token)) {
      return ACRED_WHALE;
    } else {
      revert('_getWhale: no whale configured');
    }
  }

  /// @dev Transfers `amount` of `token` to `recipient` from a known whale.
  /// @notice Assumes `recipient` is already whitelisted to hold the token, otherwise reverts.
  function _dealRwaToken(address token, address recipient, uint256 amount) internal {
    address whale = _getWhale(token);
    require(IERC20(token).balanceOf(whale) >= amount, 'whale has insufficient balance');

    vm.prank(whale);
    IERC20(token).transfer(recipient, amount);
  }
}
