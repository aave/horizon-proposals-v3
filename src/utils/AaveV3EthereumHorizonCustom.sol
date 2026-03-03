// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveV3ConfigEngine as IEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {AaveV3EthereumHorizon} from 'aave-address-book-latest/AaveV3EthereumHorizon.sol';

library AaveV3EthereumHorizonCustom {
  function defaultRwaInterestRateInputData()
    internal
    pure
    returns (IEngine.InterestRateInputData memory)
  {
    return
      IEngine.InterestRateInputData({
        optimalUsageRatio: 99_00,
        baseVariableBorrowRate: 0,
        variableRateSlope1: 0,
        variableRateSlope2: 0
      });
  }

  // executor roles
  address public constant HORIZON_OPS = 0xE6ec1f0Ae6Cd023bd0a9B4d0253BDC755103253c;
  address public constant HORIZON_EMERGENCY = 0x13B57382c36BAB566E75C72303622AF29E27e1d3;
  address public constant HORIZON_EXECUTOR = 0x09e8E1408a68778CEDdC1938729Ea126710E7Dda;

  // from AaveV3EthereumHorizon address book
  address internal constant POOL = address(AaveV3EthereumHorizon.POOL);
  address internal constant DEFAULT_A_TOKEN_IMPL =
    address(AaveV3EthereumHorizon.DEFAULT_A_TOKEN_IMPL);
  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL =
    address(AaveV3EthereumHorizon.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL);

  // horizon deployments
  address internal constant CONFIG_ENGINE = 0x30dA3a613c5b492BB4277Aa2a5D81f4759Ba83Af;
  address internal constant RWA_A_TOKEN_IMPL = 0x8CA2a49c7Df42E67F9A532F0d383D648fB7Fe4C9;
  address internal constant DEFAULT_INTEREST_RATE_STRATEGY =
    0x87593272C06f4FC49EC2942eBda0972d2F1Ab521;

  // oracle param registry
  address public constant RWA_ORACLE_PARAMS_REGISTRY = 0x69D55D504BC9556E377b340D19818E736bbB318b;

  // horizon assets
  address public constant ACRED_UNDERLYING = 0x17418038ecF73BA4026c4f428547BF099706F27B;
  address public constant ACRED_PRICE_FEED = 0x60AEd7d20AC6328f7BA771aD58931c996aff30E8;
}
