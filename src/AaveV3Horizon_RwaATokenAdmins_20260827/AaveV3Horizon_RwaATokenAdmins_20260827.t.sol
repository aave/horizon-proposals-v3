// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IAccessControl} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';
import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {ProtocolV3HorizonTestBase} from 'tests/utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3EthereumHorizon, AaveV3EthereumHorizonAssets} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';
import {AaveV3EthereumHorizonCustom} from 'src/utils/AaveV3EthereumHorizonCustom.sol';
import {AaveHorizonGovV3Helpers} from 'src/utils/AaveHorizonGovV3Helpers.sol';
import {IRwaATokenManager} from 'src/interfaces/IRwaATokenManager.sol';
import {Errors} from 'src/dependencies/Errors.sol';

interface IRwaAToken {
  function authorizedTransfer(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @dev Test for granting per-aToken authorized transfer roles on the RwaATokenManager
 *      to the RWA issuer wallets, via Emergency multisig batch (Safe Transaction Builder JSON).
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_RwaATokenAdmins_20260827 -vv
 */
contract AaveV3Horizon_RwaATokenAdmins_20260827 is ProtocolV3HorizonTestBase {
  address internal constant RWA_A_TOKEN_MANAGER = AaveV3EthereumHorizon.RWA_A_TOKEN_MANAGER;

  // issuer transfer admin wallets
  // https://etherscan.io/address/0xad309BB6f13074128b4F23EF9EA2fe8552AfCA83
  address internal constant SUPERSTATE_USTB_TRANSFER_ADMIN =
    0xad309BB6f13074128b4F23EF9EA2fe8552AfCA83;
  // https://etherscan.io/address/0x8abC89D9b56dFD90dA18e8E18CFaC9111100bDd1
  address internal constant SUPERSTATE_USCC_TRANSFER_ADMIN =
    0x8abC89D9b56dFD90dA18e8E18CFaC9111100bDd1;
  // https://etherscan.io/address/0x7Bf090B97f896fB77e852CC98aa52A8Cb7DC02eC
  address internal constant CENTRIFUGE_TRANSFER_ADMIN = 0x7Bf090B97f896fB77e852CC98aa52A8Cb7DC02eC;
  // https://etherscan.io/address/0x0C607d48fAe9ac1D3eA0c035864Ba3bAfB09D2d9
  address internal constant SECURITIZE_TRANSFER_ADMIN = 0x0C607d48fAe9ac1D3eA0c035864Ba3bAfB09D2d9;
  // https://etherscan.io/address/0x8003544D32eE074aA8A1fb72129Fa8Ef7fe02E5f
  address internal constant MIDAS_TRANSFER_ADMIN = 0x8003544D32eE074aA8A1fb72129Fa8Ef7fe02E5f;

  // existing aToken holders at the fork block, used to exercise authorized transfers
  address internal constant AUSTB_HOLDER = 0xcf25feDB1A51edC27DBA47C87c28be1c983168Fb;
  address internal constant AUSCC_HOLDER = 0x971B34b997843b82051b3e781d6A6d5A21BbDDA0;
  address internal constant AJTRSY_HOLDER = 0x0a1b0002E35dc2f0d9637DB78a4fBb9f734eB5eB;
  address internal constant AJAAA_HOLDER = 0xD5EfCd1BCB9336F4E02598E10554c696dAe4Ae2b;
  address internal constant AVBILL_HOLDER = 0x8e2DBe8cFC821E36Be5d95b7eB5A08f4d909Ef45;
  address internal constant AMGLOBAL_HOLDER = 0x882C825405fBBE45DCc1ad52b639aFbC4592EDb7;

  uint256 internal constant SAFE_NONCE = 14;

  string internal constant TX_BUILDER_JSON_PATH =
    './src/AaveV3Horizon_RwaATokenAdmins_20260827/AaveV3Horizon_RwaATokenAdmins_20260827.json';

  // Safe UI batch calldata: MultiSendCallOnly.multiSend of the 7 grants (operation = 1)
  bytes internal constant EXPECTED_SAFE_TX_DATA =
    hex'8d80ff0a0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000042f00803e5db3e26e88ad0a682a46c3e04cdd053d0eb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044b2761e350000000000000000000000004e58a2e433a739726134c83d2f07b2562e8dfdb3000000000000000000000000ad309bb6f13074128b4f23ef9ea2fe8552afca8300803e5db3e26e88ad0a682a46c3e04cdd053d0eb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044b2761e3500000000000000000000000008b798c40b9ab931356d9ab4235f548325c4cb800000000000000000000000008abc89d9b56dfd90da18e8e18cfac9111100bdd100803e5db3e26e88ad0a682a46c3e04cdd053d0eb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044b2761e35000000000000000000000000844f07ab09aa5dbdce6a9b1206ce150e1eadaccb0000000000000000000000007bf090b97f896fb77e852cc98aa52a8cb7dc02ec00803e5db3e26e88ad0a682a46c3e04cdd053d0eb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044b2761e35000000000000000000000000b0ec6c4482ac1ef77be239c0ac833cf37a27c8760000000000000000000000007bf090b97f896fb77e852cc98aa52a8cb7dc02ec00803e5db3e26e88ad0a682a46c3e04cdd053d0eb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044b2761e35000000000000000000000000c293744ffbcf46696d589f5c415e71bc491519cd0000000000000000000000000c607d48fae9ac1d3ea0c035864ba3bafb09d2d900803e5db3e26e88ad0a682a46c3e04cdd053d0eb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044b2761e35000000000000000000000000e1cfd16b8e4b1c86bb5b7a104cfefbc7b09326dd0000000000000000000000000c607d48fae9ac1d3ea0c035864ba3bafb09d2d900803e5db3e26e88ad0a682a46c3e04cdd053d0eb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044b2761e3500000000000000000000000049d3cde03813ee32dfd47f6aa3957d5f9cbab9850000000000000000000000008003544d32ee074aa8a1fb72129fa8ef7fe02e5f0000000000000000000000000000000000';

  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
  event TransferRwaAToken(
    address indexed caller,
    address indexed aToken,
    address indexed from,
    address to,
    uint256 amount
  );

  struct Grant {
    string symbol;
    address underlying;
    address aToken;
    address account;
    address holder; // existing aToken holder at fork block, address(0) if the reserve has no supply
  }

  Grant[] internal grants;

  IRwaATokenManager internal manager = IRwaATokenManager(RWA_A_TOKEN_MANAGER);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 25846481);

    grants.push(
      Grant({
        symbol: 'USTB',
        underlying: AaveV3EthereumHorizonAssets.USTB_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.USTB_A_TOKEN,
        account: SUPERSTATE_USTB_TRANSFER_ADMIN,
        holder: AUSTB_HOLDER
      })
    );
    grants.push(
      Grant({
        symbol: 'USCC',
        underlying: AaveV3EthereumHorizonAssets.USCC_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.USCC_A_TOKEN,
        account: SUPERSTATE_USCC_TRANSFER_ADMIN,
        holder: AUSCC_HOLDER
      })
    );
    grants.push(
      Grant({
        symbol: 'JTRSY',
        underlying: AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.JTRSY_A_TOKEN,
        account: CENTRIFUGE_TRANSFER_ADMIN,
        holder: AJTRSY_HOLDER
      })
    );
    grants.push(
      Grant({
        symbol: 'JAAA',
        underlying: AaveV3EthereumHorizonAssets.JAAA_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.JAAA_A_TOKEN,
        account: CENTRIFUGE_TRANSFER_ADMIN,
        holder: AJAAA_HOLDER
      })
    );
    grants.push(
      Grant({
        symbol: 'ACRED',
        underlying: AaveV3EthereumHorizonAssets.ACRED_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.ACRED_A_TOKEN,
        account: SECURITIZE_TRANSFER_ADMIN,
        holder: address(0) // no supply at fork block, supplied in test
      })
    );
    grants.push(
      Grant({
        symbol: 'VBILL',
        underlying: AaveV3EthereumHorizonAssets.VBILL_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.VBILL_A_TOKEN,
        account: SECURITIZE_TRANSFER_ADMIN,
        holder: AVBILL_HOLDER
      })
    );
    grants.push(
      Grant({
        symbol: 'mGLOBAL',
        underlying: AaveV3EthereumHorizonAssets.mGLOBAL_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.mGLOBAL_A_TOKEN,
        account: MIDAS_TRANSFER_ADMIN,
        holder: AMGLOBAL_HOLDER
      })
    );
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3('AaveV3Horizon_RwaATokenAdmins_20260827', _pool(), _executeGrants);
  }

  /// @dev Sanity of the live manager wiring: it holds ATOKEN_ADMIN on the pool ACL, the
  /// Emergency multisig is its sole expected DEFAULT_ADMIN, and role derivation matches source.
  function test_managerSetup() public view {
    assertTrue(
      IAccessControl(address(AaveV3EthereumHorizon.ACL_MANAGER)).hasRole(
        keccak256('ATOKEN_ADMIN'),
        RWA_A_TOKEN_MANAGER
      ),
      'manager must hold ATOKEN_ADMIN on the ACL manager'
    );

    IAccessControl acManager = IAccessControl(RWA_A_TOKEN_MANAGER);
    bytes32 defaultAdminRole = bytes32(0);
    assertTrue(
      acManager.hasRole(defaultAdminRole, AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY),
      'emergency multisig must be manager DEFAULT_ADMIN'
    );
    assertFalse(
      acManager.hasRole(defaultAdminRole, AaveV3EthereumHorizonCustom.HORIZON_OPS),
      'ops multisig must not be manager DEFAULT_ADMIN'
    );
    assertFalse(
      acManager.hasRole(defaultAdminRole, AaveV3EthereumHorizonCustom.HORIZON_EXECUTOR),
      'executor must not be manager DEFAULT_ADMIN'
    );

    assertEq(
      manager.AUTHORIZED_TRANSFER_ROLE(),
      keccak256('AUTHORIZED_TRANSFER'),
      'AUTHORIZED_TRANSFER_ROLE mismatch'
    );
    for (uint256 i; i < grants.length; ++i) {
      assertEq(
        manager.getAuthorizedTransferRole(grants[i].aToken),
        keccak256(abi.encode(keccak256('AUTHORIZED_TRANSFER'), grants[i].aToken)),
        'per-aToken role derivation mismatch'
      );
    }
  }

  /// @dev Every aToken in the batch matches the live pool reserve data.
  function test_aTokens_matchLivePool() public view {
    IPool pool = _pool();
    for (uint256 i; i < grants.length; ++i) {
      assertEq(
        pool.getReserveAToken(grants[i].underlying),
        grants[i].aToken,
        string.concat(grants[i].symbol, ': aToken != live pool aToken')
      );
    }
  }

  /// @dev The Safe Transaction Builder JSON contains exactly the expected grants.
  function test_txBuilderJson() public view {
    string memory json = vm.readFile(TX_BUILDER_JSON_PATH);

    assertEq(vm.parseJsonString(json, '.chainId'), '1', 'chainId');
    assertEq(
      vm.parseJsonAddress(json, '.meta.createdFromSafeAddress'),
      AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY,
      'createdFromSafeAddress != emergency multisig'
    );

    assertTrue(
      vm.keyExistsJson(json, string.concat('.transactions[', vm.toString(grants.length - 1), ']')),
      'missing transactions'
    );
    assertFalse(
      vm.keyExistsJson(json, string.concat('.transactions[', vm.toString(grants.length), ']')),
      'unexpected extra transaction'
    );

    for (uint256 i; i < grants.length; ++i) {
      string memory base = string.concat('.transactions[', vm.toString(i), ']');
      assertEq(
        vm.parseJsonAddress(json, string.concat(base, '.to')),
        RWA_A_TOKEN_MANAGER,
        'tx target != manager'
      );
      assertEq(vm.parseJsonString(json, string.concat(base, '.value')), '0', 'tx value != 0');
      assertEq(
        vm.parseJsonString(json, string.concat(base, '.contractMethod.name')),
        'grantAuthorizedTransferRole',
        'tx method'
      );
      assertEq(
        vm.parseJsonAddress(json, string.concat(base, '.contractInputsValues.aToken')),
        grants[i].aToken,
        string.concat(grants[i].symbol, ': json aToken mismatch')
      );
      assertEq(
        vm.parseJsonAddress(json, string.concat(base, '.contractInputsValues.account')),
        grants[i].account,
        string.concat(grants[i].symbol, ': json account mismatch')
      );
    }
  }

  /// @dev The batched Safe calldata built from the grants matches the pinned Safe UI bytes.
  function test_calldata() public view {
    (address to, bytes memory data, uint8 operation) = AaveHorizonGovV3Helpers
      .createEmergencyMultisigCalldata(_grantActions());

    assertEq(to, AaveHorizonGovV3Helpers.MULTI_SEND_CALL_ONLY, 'safe tx target mismatch');
    assertEq(data, EXPECTED_SAFE_TX_DATA, 'safe tx calldata mismatch');
    assertEq(operation, 1, 'safe tx operation mismatch');
  }

  /// @dev Exactly the expected (aToken, account) pairs hold the transfer role after execution.
  function test_rolesGranted_matrix() public {
    address[] memory accounts = _uniqueAccounts();
    address[] memory aTokens = _allRwaATokens();

    // before: nothing granted
    for (uint256 t; t < aTokens.length; ++t) {
      for (uint256 a; a < accounts.length; ++a) {
        assertFalse(
          manager.hasAuthorizedTransferRole(aTokens[t], accounts[a]),
          'role granted before execution'
        );
      }
    }

    _executeGrants();

    for (uint256 t; t < aTokens.length; ++t) {
      for (uint256 a; a < accounts.length; ++a) {
        assertEq(
          manager.hasAuthorizedTransferRole(aTokens[t], accounts[a]),
          _isExpectedGrant(aTokens[t], accounts[a]),
          string.concat(
            'unexpected role state: aToken ',
            vm.toString(aTokens[t]),
            ' account ',
            vm.toString(accounts[a])
          )
        );
      }
      // the multisig administers roles but must not hold the transfer role itself
      assertFalse(
        manager.hasAuthorizedTransferRole(
          aTokens[t],
          AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY
        ),
        'emergency multisig must not hold transfer role'
      );
    }

    // grantees must not have gained manager admin rights
    for (uint256 a; a < accounts.length; ++a) {
      assertFalse(
        IAccessControl(RWA_A_TOKEN_MANAGER).hasRole(bytes32(0), accounts[a]),
        'grantee must not be manager DEFAULT_ADMIN'
      );
    }
  }

  /// @dev The execution emits one RoleGranted per grant, sent by the multisig.
  function test_events() public {
    for (uint256 i; i < grants.length; ++i) {
      vm.expectEmit(RWA_A_TOKEN_MANAGER);
      emit RoleGranted(
        manager.getAuthorizedTransferRole(grants[i].aToken),
        grants[i].account,
        AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY
      );
    }
    _executeGrants();
  }

  /// @dev Each admin can move aTokens of an existing holder through the manager.
  function test_authorizedTransfer_byAdmin() public {
    _executeGrants();

    for (uint256 i; i < grants.length; ++i) {
      if (grants[i].holder == address(0)) {
        continue; // covered by test_authorizedTransfer_byAdmin_acred
      }
      _assertAuthorizedTransferWorks(grants[i], grants[i].holder);
    }
  }

  /// @dev ACRED has no supply at the fork block: whitelist a fresh supplier, supply from
  /// the whale, then exercise the authorized transfer.
  function test_authorizedTransfer_byAdmin_acred() public {
    _executeGrants();

    Grant memory grant = grants[4];
    assertEq(grant.aToken, AaveV3EthereumHorizonAssets.ACRED_A_TOKEN, 'grant index mismatch');

    address supplier = makeAddr('acredSupplier');
    _whitelistAcredRwa(supplier);
    _whitelistAcredRwa(grant.aToken);

    uint256 amount = 1e6; // 1 ACRED, within the supply cap of 1
    _dealRwaToken(grant.underlying, supplier, amount);

    vm.startPrank(supplier);
    IERC20(grant.underlying).approve(address(_pool()), amount);
    _pool().supply({
      asset: grant.underlying,
      amount: amount,
      onBehalfOf: supplier,
      referralCode: 0
    });
    vm.stopPrank();

    _assertAuthorizedTransferWorks(grant, supplier);
  }

  /// @dev Without the grant, no admin can transfer; the exact AccessControl revert is enforced.
  function test_authorizedTransfer_reverts_beforeExecution() public {
    for (uint256 i; i < grants.length; ++i) {
      _expectMissingTransferRoleRevert(grants[i].aToken, grants[i].account);
      vm.prank(grants[i].account);
      manager.transferRwaAToken({
        aToken: grants[i].aToken,
        from: grants[i].holder,
        to: makeAddr('recipient'),
        amount: 1
      });
    }
  }

  /// @dev After execution, random users and non-matching admins still cannot transfer.
  function test_authorizedTransfer_reverts_unauthorized() public {
    _executeGrants();

    address randomUser = makeAddr('randomUser');
    address[] memory accounts = _uniqueAccounts();
    address[] memory aTokens = _allRwaATokens();

    for (uint256 t; t < aTokens.length; ++t) {
      _expectMissingTransferRoleRevert(aTokens[t], randomUser);
      vm.prank(randomUser);
      manager.transferRwaAToken({
        aToken: aTokens[t],
        from: makeAddr('from'),
        to: makeAddr('to'),
        amount: 1
      });

      for (uint256 a; a < accounts.length; ++a) {
        if (_isExpectedGrant(aTokens[t], accounts[a])) {
          continue;
        }
        _expectMissingTransferRoleRevert(aTokens[t], accounts[a]);
        vm.prank(accounts[a]);
        manager.transferRwaAToken({
          aToken: aTokens[t],
          from: makeAddr('from'),
          to: makeAddr('to'),
          amount: 1
        });
      }
    }
  }

  /// @dev Grantees hold only the transfer role: they cannot grant or revoke roles.
  function test_grantees_cannotGrantOrRevoke() public {
    _executeGrants();

    address[] memory accounts = _uniqueAccounts();
    for (uint256 a; a < accounts.length; ++a) {
      _expectMissingRoleRevert(accounts[a], bytes32(0));
      vm.prank(accounts[a]);
      manager.grantAuthorizedTransferRole(grants[0].aToken, makeAddr('attacker'));

      _expectMissingRoleRevert(accounts[a], bytes32(0));
      vm.prank(accounts[a]);
      manager.revokeAuthorizedTransferRole(grants[0].aToken, grants[0].account);
    }
  }

  /// @dev The grant does not confer pool-level power: a grantee calling the aToken
  /// directly (bypassing the manager) must be rejected, and plain transfers stay disabled.
  function test_directATokenPaths_stayDisabled() public {
    _executeGrants();

    for (uint256 i; i < grants.length; ++i) {
      vm.expectRevert(bytes(Errors.CALLER_NOT_ATOKEN_TRANSFER_ADMIN));
      vm.prank(grants[i].account);
      IRwaAToken(grants[i].aToken).authorizedTransfer(grants[i].holder, makeAddr('recipient'), 1);

      vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
      vm.prank(grants[i].holder == address(0) ? makeAddr('holder') : grants[i].holder);
      IERC20(grants[i].aToken).transfer(makeAddr('recipient'), 1);
    }
  }

  /// @dev The multisig can revoke a granted role, after which transfers revert again.
  function test_emergencyMultisig_canRevoke() public {
    _executeGrants();

    for (uint256 i; i < grants.length; ++i) {
      vm.prank(AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY);
      manager.revokeAuthorizedTransferRole(grants[i].aToken, grants[i].account);

      assertFalse(
        manager.hasAuthorizedTransferRole(grants[i].aToken, grants[i].account),
        string.concat(grants[i].symbol, ': role not revoked')
      );

      _expectMissingTransferRoleRevert(grants[i].aToken, grants[i].account);
      vm.prank(grants[i].account);
      manager.transferRwaAToken({
        aToken: grants[i].aToken,
        from: grants[i].holder,
        to: makeAddr('recipient'),
        amount: 1
      });
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  function _executeGrants() internal {
    (address to, bytes memory data, uint8 operation) = AaveHorizonGovV3Helpers
      .createEmergencyMultisigCalldata(_grantActions());
    _executeEmergencyMultisigTx({to: to, data: data, operation: operation, nonce: SAFE_NONCE});
  }

  function _grantActions() internal view returns (AaveHorizonGovV3Helpers.Action[] memory) {
    AaveHorizonGovV3Helpers.Action[] memory actions = new AaveHorizonGovV3Helpers.Action[](
      grants.length
    );
    for (uint256 i; i < grants.length; ++i) {
      actions[i] = AaveHorizonGovV3Helpers.Action({
        to: RWA_A_TOKEN_MANAGER,
        data: abi.encodeCall(
          IRwaATokenManager.grantAuthorizedTransferRole,
          (grants[i].aToken, grants[i].account)
        )
      });
    }
    return actions;
  }

  /// @dev Transfers 1% of the holder's balance via the manager and checks balances and event.
  function _assertAuthorizedTransferWorks(Grant memory grant, address holder) internal {
    uint256 holderBalance = IERC20(grant.aToken).balanceOf(holder);
    assertGt(holderBalance, 0, string.concat(grant.symbol, ': holder has no balance'));

    // small amount, keeps the holder healthy if it has open borrows
    uint256 amount = holderBalance / 100 > 0 ? holderBalance / 100 : holderBalance;
    address recipient = makeAddr(string.concat(grant.symbol, 'recipient'));

    vm.expectEmit(RWA_A_TOKEN_MANAGER);
    emit TransferRwaAToken(grant.account, grant.aToken, holder, recipient, amount);

    vm.prank(grant.account);
    bool ok = manager.transferRwaAToken({
      aToken: grant.aToken,
      from: holder,
      to: recipient,
      amount: amount
    });
    assertTrue(ok, string.concat(grant.symbol, ': transferRwaAToken returned false'));

    assertApproxEqAbs(
      IERC20(grant.aToken).balanceOf(recipient),
      amount,
      2,
      string.concat(grant.symbol, ': recipient balance after transfer')
    );
    assertApproxEqAbs(
      IERC20(grant.aToken).balanceOf(holder),
      holderBalance - amount,
      2,
      string.concat(grant.symbol, ': holder balance after transfer')
    );
  }

  function _expectMissingTransferRoleRevert(address aToken, address account) internal {
    _expectMissingRoleRevert(account, manager.getAuthorizedTransferRole(aToken));
  }

  function _expectMissingRoleRevert(address account, bytes32 role) internal {
    vm.expectRevert(
      bytes(
        string.concat(
          'AccessControl: account ',
          vm.toLowercase(vm.toString(account)),
          ' is missing role ',
          vm.toString(role)
        )
      )
    );
  }

  function _isExpectedGrant(address aToken, address account) internal view returns (bool) {
    for (uint256 i; i < grants.length; ++i) {
      if (grants[i].aToken == aToken && grants[i].account == account) {
        return true;
      }
    }
    return false;
  }

  function _uniqueAccounts() internal pure returns (address[] memory) {
    address[] memory accounts = new address[](5);
    accounts[0] = SUPERSTATE_USTB_TRANSFER_ADMIN;
    accounts[1] = SUPERSTATE_USCC_TRANSFER_ADMIN;
    accounts[2] = CENTRIFUGE_TRANSFER_ADMIN;
    accounts[3] = SECURITIZE_TRANSFER_ADMIN;
    accounts[4] = MIDAS_TRANSFER_ADMIN;
    return accounts;
  }

  /// @dev All live RWA aTokens, including aUSYC which deliberately receives no grant.
  function _allRwaATokens() internal view returns (address[] memory) {
    address[] memory aTokens = new address[](grants.length + 1);
    for (uint256 i; i < grants.length; ++i) {
      aTokens[i] = grants[i].aToken;
    }
    aTokens[grants.length] = AaveV3EthereumHorizonAssets.USYC_A_TOKEN;
    return aTokens;
  }
}
