// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3HorizonEthereum} from './AaveV3HorizonEthereum.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.3 listing on v3 Horizon Ethereum.
 * @author Aave Labs
 */
abstract contract AaveV3PayloadHorizonEthereum is
  AaveV3Payload(IEngine(AaveV3HorizonEthereum.CONFIG_ENGINE))
{
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Horizon RWA', networkAbbreviation: 'HorRwa'});
  }
}
