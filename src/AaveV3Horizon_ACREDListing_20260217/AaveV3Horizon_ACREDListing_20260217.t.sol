// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool} from 'aave-v3-origin/contracts/interfaces/IPool.sol';
import {AaveV3HorizonEthereum} from 'src/utils/AaveV3HorizonEthereum.sol';
import {ProtocolV3HorizonTestBase, ReserveConfig} from 'src/utils/ProtocolV3HorizonTestBase.sol';
import {HorizonConfigAssertionHelper} from 'src/utils/HorizonConfigAssertionHelper.sol';
import {AaveV3Horizon_ACREDListing_20260217} from 'src/AaveV3Horizon_ACREDListing_20260217/AaveV3Horizon_ACREDListing_20260217.sol';

/**
 * @dev Test for Horizon ACRED listing
 * command: FOUNDRY_PROFILE=test forge test --match-path=src/AaveV3Horizon_ACREDListing_20260217/AaveV3Horizon_ACREDListing_20260217.t.sol -vv
 */
contract AaveV3Horizon_ACREDListing_20260217_Test is ProtocolV3HorizonTestBase {
  AaveV3Horizon_ACREDListing_20260217 internal proposal;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 24473387);
    proposal = new AaveV3Horizon_ACREDListing_20260217();
  }

  /**
   * @dev executes the generic test suite including e2e and config snapshots
   */
  function test_defaultProposalExecution() public {
    defaultTest_v3_3(
      'AaveV3Horizon_ACREDListing_20260217',
      IPool(AaveV3HorizonEthereum.POOL),
      address(proposal)
    );
  }

  /**
   * @dev verifies the exact config values set by the ACRED listing payload
   */
  function test_acredConfig() public {
    IPool pool = IPool(AaveV3HorizonEthereum.POOL);

    // check eMode 5 is set to previous default
    _assertEModeConfig(
      pool,
      ExpectedEModeConfig({
        eModeCategory: 5,
        ltv: 85_00,
        liquidationThreshold: 89_00,
        liquidationBonus: 100_00 + 3_10,
        label: '',
        collateralAssets: new address[](0),
        borrowableAssets: new address[](0)
      })
    );

    _executeHorizonPayload(address(proposal));

    _assertAssetConfig(
      pool,
      ExpectedAssetConfig({
        underlying: AaveV3HorizonEthereum.ACRED_UNDERLYING,
        isRwa: true,
        oracle: 0x60AEd7d20AC6328f7BA771aD58931c996aff30E8,
        aTokenName: 'Aave Horizon RWA ACRED',
        aTokenSymbol: 'aHorRwaACRED',
        variableDebtTokenName: 'Aave Horizon RWA Variable Debt ACRED',
        variableDebtTokenSymbol: 'variableDebtHorRwaACRED',
        supplyCap: 15_000_000,
        borrowCap: 0,
        reserveFactor: 0,
        borrowingEnabled: false,
        flashloanable: false,
        ltv: 66_00,
        liquidationThreshold: 76_00,
        liquidationBonus: 100_00 + 9_00,
        debtCeiling: 0,
        liqProtocolFee: 0
      })
    );

    // overwrite eMode 5 = ACRED GHO — ACRED is added as collateral alongside GHO
    _assertEModeConfig(
      pool,
      ExpectedEModeConfig({
        eModeCategory: 5,
        ltv: 90_00,
        liquidationThreshold: 92_00,
        liquidationBonus: 100_00 + 3_00,
        label: 'ACRED GHO',
        collateralAssets: _toAddressArray(AaveV3HorizonEthereum.ACRED_UNDERLYING),
        borrowableAssets: _toAddressArray(AaveV3HorizonEthereum.GHO_UNDERLYING)
      })
    );
  }
}
