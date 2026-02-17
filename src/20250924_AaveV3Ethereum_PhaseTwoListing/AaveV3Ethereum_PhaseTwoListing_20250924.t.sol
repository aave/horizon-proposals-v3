// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {AaveV3HorizonEthereum} from '../utils/AaveV3HorizonEthereum.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from '../utils/ProtocolV3HorizonTestBase.sol';
import {AaveV3Ethereum_PhaseTwoListing_20250924} from './AaveV3Ethereum_PhaseTwoListing_20250924.sol';

/**
 * @dev Test for Horizon ACRED listing
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/20250924_AaveV3Ethereum_PhaseTwoListing/AaveV3Ethereum_PhaseTwoListing_20250924.t.sol -vv
 */
contract AaveV3Ethereum_PhaseTwoListing_20250924_Test is ProtocolV3HorizonTestBase {
  AaveV3Ethereum_PhaseTwoListing_20250924 internal proposal;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24473387);
    proposal = new AaveV3Ethereum_PhaseTwoListing_20250924();
  }

  /**
   * @dev executes the generic test suite including e2e and config snapshots
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3(
      'AaveV3Ethereum_PhaseTwoListing_20250924',
      IPool(AaveV3HorizonEthereum.POOL),
      address(proposal)
    );
  }
}
