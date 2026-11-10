// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from 'forge-std/Vm.sol';
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

  function ATOKEN_ADMIN_ROLE() external pure returns (bytes32);
}

/**
 * @dev Test for the Emergency multisig batch (Safe Transaction Builder JSON) that executes the
 *      mWIN & HINC listing payload, then grants the per-aToken authorized transfer roles on the
 *      RwaATokenManager for aMWIN and aHINC.
 * command: FOUNDRY_PROFILE=test forge test --match-contract AaveV3Horizon_mWINHINCListingBatch_20261110 -vv
 */
contract AaveV3Horizon_mWINHINCListingBatch_20261110 is ProtocolV3HorizonTestBase {
  address internal constant RWA_A_TOKEN_MANAGER = AaveV3EthereumHorizon.RWA_A_TOKEN_MANAGER;

  // https://etherscan.io/address/0xB45F91eb35e806408597AdCe4153ce06A18B839d
  address internal constant LISTING_PAYLOAD = 0xB45F91eb35e806408597AdCe4153ce06A18B839d;

  // aTokens created by the listing payload
  // https://etherscan.io/address/0x6d094e48Ee2E7C43787aFa0ec5aCcC5F644F976C
  address internal constant MWIN_A_TOKEN = 0x6d094e48Ee2E7C43787aFa0ec5aCcC5F644F976C;
  // https://etherscan.io/address/0x30a62C38265B9Df787d22E62e52C541051B4bCdF
  address internal constant HINC_A_TOKEN = 0x30a62C38265B9Df787d22E62e52C541051B4bCdF;

  // issuer transfer admin wallets granted in this batch
  // https://etherscan.io/address/0x8003544D32eE074aA8A1fb72129Fa8Ef7fe02E5f
  address internal constant MIDAS_TRANSFER_ADMIN = 0x8003544D32eE074aA8A1fb72129Fa8Ef7fe02E5f;
  // https://etherscan.io/address/0x59c1eAcEc450c57Dcb9b8725d0F96635C2b676Ee
  address internal constant SECURITIZE_HINC_TRANSFER_ADMIN =
    0x59c1eAcEc450c57Dcb9b8725d0F96635C2b676Ee;

  // issuer transfer admin wallets granted by AaveV3Horizon_RwaATokenAdmins_20260827
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

  uint256 internal constant SAFE_NONCE = 15;

  string internal constant TX_BUILDER_JSON_PATH =
    './src/AaveV3Horizon_mWINHINCListingBatch_20261110/AaveV3Horizon_mWINHINCListingBatch_20261110.json';

  // Safe UI batch calldata: MultiSendCallOnly.multiSend of the listing execution and the 2 grants
  // (operation = 1)
  bytes internal constant EXPECTED_SAFE_TX_DATA =
    hex'8d80ff0a0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000028b0009e8e1408a68778ceddc1938729ea126710e7dda00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000104025d36a9000000000000000000000000b45f91eb35e806408597adce4153ce06a18b839d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000096578656375746528290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000803e5db3e26e88ad0a682a46c3e04cdd053d0eb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044b2761e350000000000000000000000006d094e48ee2e7c43787afa0ec5accc5f644f976c0000000000000000000000008003544d32ee074aa8a1fb72129fa8ef7fe02e5f00803e5db3e26e88ad0a682a46c3e04cdd053d0eb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044b2761e3500000000000000000000000030a62c38265b9df787d22e62e52c541051b4bcdf00000000000000000000000059c1eacec450c57dcb9b8725d0f96635c2b676ee000000000000000000000000000000000000000000';

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
  }

  // grants made by this batch
  Grant[] internal grants;
  // grants made by AaveV3Horizon_RwaATokenAdmins_20260827, which must stay untouched
  Grant[] internal existingGrants;

  IRwaATokenManager internal manager = IRwaATokenManager(RWA_A_TOKEN_MANAGER);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 26372600);

    grants.push(
      Grant({
        symbol: 'mWIN',
        underlying: AaveV3EthereumHorizonCustom.MWIN_UNDERLYING,
        aToken: MWIN_A_TOKEN,
        account: MIDAS_TRANSFER_ADMIN
      })
    );
    grants.push(
      Grant({
        symbol: 'HINC',
        underlying: AaveV3EthereumHorizonCustom.HINC_UNDERLYING,
        aToken: HINC_A_TOKEN,
        account: SECURITIZE_HINC_TRANSFER_ADMIN
      })
    );

    existingGrants.push(
      Grant({
        symbol: 'USTB',
        underlying: AaveV3EthereumHorizonAssets.USTB_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.USTB_A_TOKEN,
        account: SUPERSTATE_USTB_TRANSFER_ADMIN
      })
    );
    existingGrants.push(
      Grant({
        symbol: 'USCC',
        underlying: AaveV3EthereumHorizonAssets.USCC_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.USCC_A_TOKEN,
        account: SUPERSTATE_USCC_TRANSFER_ADMIN
      })
    );
    existingGrants.push(
      Grant({
        symbol: 'JTRSY',
        underlying: AaveV3EthereumHorizonAssets.JTRSY_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.JTRSY_A_TOKEN,
        account: CENTRIFUGE_TRANSFER_ADMIN
      })
    );
    existingGrants.push(
      Grant({
        symbol: 'JAAA',
        underlying: AaveV3EthereumHorizonAssets.JAAA_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.JAAA_A_TOKEN,
        account: CENTRIFUGE_TRANSFER_ADMIN
      })
    );
    existingGrants.push(
      Grant({
        symbol: 'ACRED',
        underlying: AaveV3EthereumHorizonAssets.ACRED_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.ACRED_A_TOKEN,
        account: SECURITIZE_TRANSFER_ADMIN
      })
    );
    existingGrants.push(
      Grant({
        symbol: 'VBILL',
        underlying: AaveV3EthereumHorizonAssets.VBILL_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.VBILL_A_TOKEN,
        account: SECURITIZE_TRANSFER_ADMIN
      })
    );
    existingGrants.push(
      Grant({
        symbol: 'mGLOBAL',
        underlying: AaveV3EthereumHorizonAssets.mGLOBAL_UNDERLYING,
        aToken: AaveV3EthereumHorizonAssets.mGLOBAL_A_TOKEN,
        account: MIDAS_TRANSFER_ADMIN
      })
    );
  }

  /**
   * @dev Full test suite: snapshots, state diff, validations, e2e.
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3('AaveV3Horizon_mWINHINCListingBatch_20261110', _pool(), _executeBatch);
  }

  /// @dev The batch is the next Emergency multisig tx at the fork block, the listing payload is
  /// deployed, and neither asset is listed yet.
  function test_forkState() public view {
    assertEq(
      // Safe nonce, storage slot 5
      uint256(vm.load(AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY, bytes32(uint256(5)))),
      SAFE_NONCE,
      'batch must be the next emergency multisig tx'
    );
    assertGt(LISTING_PAYLOAD.code.length, 0, 'listing payload not deployed');
    for (uint256 i; i < grants.length; ++i) {
      assertEq(
        _pool().getReserveAToken(grants[i].underlying),
        address(0),
        string.concat(grants[i].symbol, ': already listed')
      );
      assertEq(grants[i].aToken.code.length, 0, string.concat(grants[i].symbol, ': aToken exists'));
    }
  }

  /// @dev Sanity of the live manager wiring: it holds ATOKEN_ADMIN on the pool ACL, the
  /// Emergency multisig is its sole expected DEFAULT_ADMIN, and role derivation matches source.
  function test_managerSetup() public {
    _executeBatch();

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
      assertTrue(
        IAccessControl(address(AaveV3EthereumHorizon.ACL_MANAGER)).hasRole(
          IRwaAToken(grants[i].aToken).ATOKEN_ADMIN_ROLE(),
          RWA_A_TOKEN_MANAGER
        ),
        string.concat(grants[i].symbol, ': manager must hold ATOKEN_ADMIN on the ACL manager')
      );
      assertEq(
        manager.getAuthorizedTransferRole(grants[i].aToken),
        keccak256(abi.encode(keccak256('AUTHORIZED_TRANSFER'), grants[i].aToken)),
        'per-aToken role derivation mismatch'
      );
    }
  }

  /// @dev Every aToken in the batch is the one the listing payload creates, and is an RwaAToken.
  function test_aTokens_matchListedReserves() public {
    _executeBatch();

    IPool pool = _pool();
    for (uint256 i; i < grants.length; ++i) {
      assertEq(
        pool.getReserveAToken(grants[i].underlying),
        grants[i].aToken,
        string.concat(grants[i].symbol, ': aToken != listed aToken')
      );
      assertEq(
        _getImplementation(grants[i].aToken),
        AaveV3EthereumHorizonCustom.RWA_A_TOKEN_IMPL,
        string.concat(grants[i].symbol, ': aToken is not an RwaAToken')
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
      vm.keyExistsJson(json, string.concat('.transactions[', vm.toString(grants.length), ']')),
      'missing transactions'
    );
    assertFalse(
      vm.keyExistsJson(json, string.concat('.transactions[', vm.toString(grants.length + 1), ']')),
      'unexpected extra transaction'
    );

    // the listing executes first, so the grants target the aTokens it creates
    assertEq(
      vm.parseJsonAddress(json, '.transactions[0].to'),
      AaveV3EthereumHorizonCustom.HORIZON_EXECUTOR,
      'tx 0 target != executor'
    );
    assertEq(vm.parseJsonString(json, '.transactions[0].value'), '0', 'tx 0 value != 0');
    assertEq(
      vm.parseJsonString(json, '.transactions[0].contractMethod.name'),
      'executeTransaction',
      'tx 0 method'
    );
    assertEq(
      vm.parseJsonAddress(json, '.transactions[0].contractInputsValues.target'),
      LISTING_PAYLOAD,
      'tx 0 target payload'
    );
    assertEq(
      vm.parseJsonString(json, '.transactions[0].contractInputsValues.value'),
      '0',
      'tx 0 call value'
    );
    assertEq(
      vm.parseJsonString(json, '.transactions[0].contractInputsValues.signature'),
      'execute()',
      'tx 0 signature'
    );
    assertEq(
      vm.parseJsonString(json, '.transactions[0].contractInputsValues.data'),
      '0x',
      'tx 0 data'
    );
    assertEq(
      vm.parseJsonString(json, '.transactions[0].contractInputsValues.withDelegatecall'),
      'true',
      'tx 0 withDelegatecall'
    );

    for (uint256 i; i < grants.length; ++i) {
      string memory base = string.concat('.transactions[', vm.toString(i + 1), ']');
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
      .createEmergencyMultisigCalldata(_batchActions());

    assertEq(to, AaveHorizonGovV3Helpers.MULTI_SEND_CALL_ONLY, 'safe tx target mismatch');
    assertEq(data, EXPECTED_SAFE_TX_DATA, 'safe tx calldata mismatch');
    assertEq(operation, 1, 'safe tx operation mismatch');
  }

  /// @dev Exactly the expected (aToken, account) pairs hold the transfer role, before and after
  /// execution, across every RWA aToken and every issuer wallet.
  function test_rolesGranted_matrix() public {
    address[] memory accounts = _uniqueAccounts();
    address[] memory aTokens = _allRwaATokens();

    // before: only the existing grants
    for (uint256 t; t < aTokens.length; ++t) {
      for (uint256 a; a < accounts.length; ++a) {
        assertEq(
          manager.hasAuthorizedTransferRole(aTokens[t], accounts[a]),
          _isExistingGrant(aTokens[t], accounts[a]),
          string.concat(
            'unexpected role state before execution: aToken ',
            vm.toString(aTokens[t]),
            ' account ',
            vm.toString(accounts[a])
          )
        );
      }
    }

    _executeBatch();

    for (uint256 t; t < aTokens.length; ++t) {
      for (uint256 a; a < accounts.length; ++a) {
        assertEq(
          manager.hasAuthorizedTransferRole(aTokens[t], accounts[a]),
          _isExistingGrant(aTokens[t], accounts[a]) || _isNewGrant(aTokens[t], accounts[a]),
          string.concat(
            'unexpected role state: aToken ',
            vm.toString(aTokens[t]),
            ' account ',
            vm.toString(accounts[a])
          )
        );
      }
      // the multisig and the executor administer nothing here and must not hold the transfer role
      assertFalse(
        manager.hasAuthorizedTransferRole(
          aTokens[t],
          AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY
        ),
        'emergency multisig must not hold transfer role'
      );
      assertFalse(
        manager.hasAuthorizedTransferRole(aTokens[t], AaveV3EthereumHorizonCustom.HORIZON_EXECUTOR),
        'executor must not hold transfer role'
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

  /// @dev The grants made by AaveV3Horizon_RwaATokenAdmins_20260827 are still in place.
  function test_existingGrants_untouched() public {
    _executeBatch();

    for (uint256 i; i < existingGrants.length; ++i) {
      assertTrue(
        manager.hasAuthorizedTransferRole(existingGrants[i].aToken, existingGrants[i].account),
        string.concat(existingGrants[i].symbol, ': existing grant lost')
      );
    }
  }

  /// @dev The execution emits exactly one RoleGranted per grant, sent by the multisig.
  function test_events() public {
    vm.recordLogs();
    for (uint256 i; i < grants.length; ++i) {
      vm.expectEmit(RWA_A_TOKEN_MANAGER);
      emit RoleGranted(
        manager.getAuthorizedTransferRole(grants[i].aToken),
        grants[i].account,
        AaveV3EthereumHorizonCustom.HORIZON_EMERGENCY
      );
    }
    _executeBatch();

    uint256 managerLogs;
    Vm.Log[] memory logs = vm.getRecordedLogs();
    for (uint256 i; i < logs.length; ++i) {
      if (logs[i].emitter == RWA_A_TOKEN_MANAGER) {
        ++managerLogs;
      }
    }
    assertEq(managerLogs, grants.length, 'unexpected manager events');
  }

  /// @dev Midas can move aMWIN of a supplier through the manager.
  function test_authorizedTransfer_mwin() public {
    _executeBatch();

    Grant memory grant = grants[0];
    assertEq(grant.aToken, MWIN_A_TOKEN, 'grant index mismatch');

    _whitelistRwaPool(_pool());
    address supplier = makeAddr('mwinSupplier');
    _whitelistMwinRwa(supplier);

    // 2 mWIN, within the supply cap of 80; the supplier's wallet ends at 0, which mWIN allows
    uint256 amount = 2e18;
    deal(grant.underlying, supplier, amount);
    _supplyRwa(grant.underlying, supplier, amount);

    _assertAuthorizedTransferWorks(grant, supplier);
  }

  /// @dev Securitize can move aHINC of a supplier through the manager.
  function test_authorizedTransfer_hinc() public {
    _executeBatch();

    Grant memory grant = grants[1];
    assertEq(grant.aToken, HINC_A_TOKEN, 'grant index mismatch');

    _whitelistRwaPool(_pool());
    address supplier = makeAddr('hincSupplier');
    _whitelistHincRwa(supplier);

    // 10 HINC, within the supply cap of 10,000
    uint256 amount = 10e6;
    _dealRwaToken(grant.underlying, supplier, amount);
    _supplyRwa(grant.underlying, supplier, amount);

    _assertAuthorizedTransferWorks(grant, supplier);
  }

  /// @dev Without the grant, the new admins cannot transfer; the exact AccessControl revert is
  /// enforced.
  function test_authorizedTransfer_reverts_beforeExecution() public {
    for (uint256 i; i < grants.length; ++i) {
      _expectMissingTransferRoleRevert(grants[i].aToken, grants[i].account);
      vm.prank(grants[i].account);
      manager.transferRwaAToken({
        aToken: grants[i].aToken,
        from: makeAddr('from'),
        to: makeAddr('recipient'),
        amount: 1
      });
    }
  }

  /// @dev After execution, random users and non-matching admins still cannot transfer, including
  /// Securitize's existing wallet on aHINC and the new HINC wallet on aACRED and aVBILL.
  function test_authorizedTransfer_reverts_unauthorized() public {
    _executeBatch();

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
        if (_isExistingGrant(aTokens[t], accounts[a]) || _isNewGrant(aTokens[t], accounts[a])) {
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
    _executeBatch();

    for (uint256 i; i < grants.length; ++i) {
      _expectMissingRoleRevert(grants[i].account, bytes32(0));
      vm.prank(grants[i].account);
      manager.grantAuthorizedTransferRole(grants[i].aToken, makeAddr('attacker'));

      _expectMissingRoleRevert(grants[i].account, bytes32(0));
      vm.prank(grants[i].account);
      manager.revokeAuthorizedTransferRole(grants[i].aToken, grants[i].account);
    }
  }

  /// @dev The grant does not confer pool-level power: a grantee calling the aToken directly
  /// (bypassing the manager) must be rejected, and plain transfers stay disabled.
  function test_directATokenPaths_stayDisabled() public {
    _executeBatch();

    address holder = makeAddr('holder');
    for (uint256 i; i < grants.length; ++i) {
      vm.expectRevert(bytes(Errors.CALLER_NOT_ATOKEN_TRANSFER_ADMIN));
      vm.prank(grants[i].account);
      IRwaAToken(grants[i].aToken).authorizedTransfer(holder, makeAddr('recipient'), 1);

      vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));
      vm.prank(holder);
      IERC20(grants[i].aToken).transfer(makeAddr('recipient'), 1);
    }
  }

  /// @dev The multisig can revoke a granted role, after which transfers revert again.
  function test_emergencyMultisig_canRevoke() public {
    _executeBatch();

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
        from: makeAddr('from'),
        to: makeAddr('recipient'),
        amount: 1
      });
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  function _executeBatch() internal {
    (address to, bytes memory data, uint8 operation) = AaveHorizonGovV3Helpers
      .createEmergencyMultisigCalldata(_batchActions());
    _executeEmergencyMultisigTx({to: to, data: data, operation: operation, nonce: SAFE_NONCE});
  }

  /// @dev The listing execution followed by one grant per aToken.
  function _batchActions() internal view returns (AaveHorizonGovV3Helpers.Action[] memory) {
    AaveHorizonGovV3Helpers.Action[] memory actions = new AaveHorizonGovV3Helpers.Action[](
      grants.length + 1
    );
    (address executor, bytes memory executeData, ) = AaveHorizonGovV3Helpers.createExecutorCalldata(
      LISTING_PAYLOAD
    );
    actions[0] = AaveHorizonGovV3Helpers.Action({to: executor, data: executeData});
    for (uint256 i; i < grants.length; ++i) {
      actions[i + 1] = AaveHorizonGovV3Helpers.Action({
        to: RWA_A_TOKEN_MANAGER,
        data: abi.encodeCall(
          IRwaATokenManager.grantAuthorizedTransferRole,
          (grants[i].aToken, grants[i].account)
        )
      });
    }
    return actions;
  }

  function _supplyRwa(address underlying, address supplier, uint256 amount) internal {
    vm.startPrank(supplier);
    IERC20(underlying).approve(address(_pool()), amount);
    _pool().supply({asset: underlying, amount: amount, onBehalfOf: supplier, referralCode: 0});
    vm.stopPrank();
  }

  /// @dev Transfers 1% of the holder's balance via the manager and checks balances and event.
  function _assertAuthorizedTransferWorks(Grant memory grant, address holder) internal {
    uint256 holderBalance = IERC20(grant.aToken).balanceOf(holder);
    assertGt(holderBalance, 0, string.concat(grant.symbol, ': holder has no balance'));

    uint256 amount = holderBalance / 100;
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

  function _isNewGrant(address aToken, address account) internal view returns (bool) {
    return _contains(grants, aToken, account);
  }

  function _isExistingGrant(address aToken, address account) internal view returns (bool) {
    return _contains(existingGrants, aToken, account);
  }

  function _contains(
    Grant[] storage list,
    address aToken,
    address account
  ) internal view returns (bool) {
    for (uint256 i; i < list.length; ++i) {
      if (list[i].aToken == aToken && list[i].account == account) {
        return true;
      }
    }
    return false;
  }

  function _uniqueAccounts() internal pure returns (address[] memory) {
    address[] memory accounts = new address[](6);
    accounts[0] = SUPERSTATE_USTB_TRANSFER_ADMIN;
    accounts[1] = SUPERSTATE_USCC_TRANSFER_ADMIN;
    accounts[2] = CENTRIFUGE_TRANSFER_ADMIN;
    accounts[3] = SECURITIZE_TRANSFER_ADMIN;
    accounts[4] = MIDAS_TRANSFER_ADMIN;
    accounts[5] = SECURITIZE_HINC_TRANSFER_ADMIN;
    return accounts;
  }

  /// @dev All RWA aTokens after the listing, including aUSYC which deliberately has no grant.
  function _allRwaATokens() internal view returns (address[] memory) {
    address[] memory aTokens = new address[](grants.length + existingGrants.length + 1);
    for (uint256 i; i < grants.length; ++i) {
      aTokens[i] = grants[i].aToken;
    }
    for (uint256 i; i < existingGrants.length; ++i) {
      aTokens[grants.length + i] = existingGrants[i].aToken;
    }
    aTokens[aTokens.length - 1] = AaveV3EthereumHorizonAssets.USYC_A_TOKEN;
    return aTokens;
  }

  function _getImplementation(address proxy) internal view returns (address) {
    return
      address(
        uint160(
          uint256(
            vm.load(proxy, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
          )
        )
      );
  }
}
