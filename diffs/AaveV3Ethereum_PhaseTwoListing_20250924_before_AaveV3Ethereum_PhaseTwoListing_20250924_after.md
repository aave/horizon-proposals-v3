## Reserve changes

### Reserves added

#### ACRED ([0x17418038ecF73BA4026c4f428547BF099706F27B](https://etherscan.io/address/0x17418038ecF73BA4026c4f428547BF099706F27B))

| description | value |
| --- | --- |
| decimals | 6 |
| isActive | true |
| isFrozen | false |
| supplyCap | 15,000,000 ACRED |
| borrowCap | 0 ACRED |
| debtCeiling | 0 $ [0] |
| isSiloed | false |
| isFlashloanable | false |
| oracle | [0x60AEd7d20AC6328f7BA771aD58931c996aff30E8](https://etherscan.io/address/0x60AEd7d20AC6328f7BA771aD58931c996aff30E8) |
| oracleDecimals | 8 |
| oracleDescription | ACRED NAV - Aave LlamaGuard |
| oracleLatestAnswer | 1097.139724 |
| usageAsCollateralEnabled | true |
| ltv | 66 % [6600] |
| liquidationThreshold | 76 % [7600] |
| liquidationBonus | 9 % |
| liquidationProtocolFee | 0 % [0] |
| reserveFactor | 0 % [0] |
| aToken | [0xc293744fFbcf46696D589f5C415e71BC491519cD](https://etherscan.io/address/0xc293744fFbcf46696D589f5C415e71BC491519cD) |
| variableDebtToken | [0x1f30d2B155FcDA0F7551dc8BE5dE6a84977685D4](https://etherscan.io/address/0x1f30d2B155FcDA0F7551dc8BE5dE6a84977685D4) |
| borrowingEnabled | false |
| isBorrowableInIsolation | false |
| interestRateStrategy | [0x87593272C06f4FC49EC2942eBda0972d2F1Ab521](https://etherscan.io/address/0x87593272C06f4FC49EC2942eBda0972d2F1Ab521) |
| aTokenName | Aave Horizon RWA ACRED |
| aTokenSymbol | aHorRwaACRED |
| aTokenUnderlyingBalance | 0 ACRED [0] |
| id | 9 |
| isPaused | false |
| variableDebtTokenName | Aave Horizon RWA Variable Debt ACRED |
| variableDebtTokenSymbol | variableDebtHorRwaACRED |
| virtualBalance | 0 ACRED [0] |
| optimalUsageRatio | 99 % |
| maxVariableBorrowRate | 0 % |
| baseVariableBorrowRate | 0 % |
| variableRateSlope1 | 0 % |
| variableRateSlope2 | 0 % |
| interestRate | ![ir](https://dash.onaave.com/api/static?variableRateSlope1=0&variableRateSlope2=0&optimalUsageRatio=990000000000000000000000000&baseVariableBorrowRate=0&maxVariableBorrowRate=0) |


## Emodes changed

### EMode: VBILL GHO(id: 1)



### EMode: USTB GHO(id: 2)



### EMode: (id: 3)



### EMode: USCC GHO(id: 4)



### EMode: ACRED GHO(id: 5)

| description | value before | value after |
| --- | --- | --- |
| eMode.label | - | ACRED GHO |
| eMode.ltv | 85 % | 90 % |
| eMode.liquidationThreshold | 89 % | 92 % |
| eMode.liquidationBonus | 3.1 % | 3 % |
| eMode.borrowableBitmap |  | GHO |
| eMode.collateralBitmap |  | ACRED |


### EMode: USYC GHO(id: 6)



### EMode: (id: 7)



### EMode: JTRSY GHO(id: 8)



### EMode: (id: 9)



### EMode: JAAA GHO(id: 10)



## Raw diff

```json
{
  "eModes": {
    "5": {
      "borrowableBitmap": {
        "from": "0",
        "to": "1"
      },
      "collateralBitmap": {
        "from": "0",
        "to": "512"
      },
      "label": {
        "from": "",
        "to": "ACRED GHO"
      },
      "liquidationBonus": {
        "from": 10310,
        "to": 10300
      },
      "liquidationThreshold": {
        "from": 8900,
        "to": 9200
      },
      "ltv": {
        "from": 8500,
        "to": 9000
      }
    }
  },
  "reserves": {
    "0x17418038ecF73BA4026c4f428547BF099706F27B": {
      "from": null,
      "to": {
        "aToken": "0xc293744fFbcf46696D589f5C415e71BC491519cD",
        "aTokenName": "Aave Horizon RWA ACRED",
        "aTokenSymbol": "aHorRwaACRED",
        "aTokenUnderlyingBalance": "0",
        "borrowCap": 0,
        "borrowingEnabled": false,
        "debtCeiling": 0,
        "decimals": 6,
        "id": 9,
        "interestRateStrategy": "0x87593272C06f4FC49EC2942eBda0972d2F1Ab521",
        "isActive": true,
        "isBorrowableInIsolation": false,
        "isFlashloanable": false,
        "isFrozen": false,
        "isPaused": false,
        "isSiloed": false,
        "liquidationBonus": 10900,
        "liquidationProtocolFee": 0,
        "liquidationThreshold": 7600,
        "ltv": 6600,
        "oracle": "0x60AEd7d20AC6328f7BA771aD58931c996aff30E8",
        "oracleDecimals": 8,
        "oracleDescription": "ACRED NAV - Aave LlamaGuard",
        "oracleLatestAnswer": "109713972400",
        "reserveFactor": 0,
        "supplyCap": 15000000,
        "symbol": "ACRED",
        "underlying": "0x17418038ecF73BA4026c4f428547BF099706F27B",
        "usageAsCollateralEnabled": true,
        "variableDebtToken": "0x1f30d2B155FcDA0F7551dc8BE5dE6a84977685D4",
        "variableDebtTokenName": "Aave Horizon RWA Variable Debt ACRED",
        "variableDebtTokenSymbol": "variableDebtHorRwaACRED",
        "virtualBalance": "0"
      }
    }
  },
  "strategies": {
    "0x17418038ecF73BA4026c4f428547BF099706F27B": {
      "from": null,
      "to": {
        "address": "0x87593272C06f4FC49EC2942eBda0972d2F1Ab521",
        "baseVariableBorrowRate": "0",
        "maxVariableBorrowRate": "0",
        "optimalUsageRatio": "990000000000000000000000000",
        "variableRateSlope1": "0",
        "variableRateSlope2": "0"
      }
    }
  },
  "raw": {
    "0x09e88e877b39d883bafd46b65e7b06cc56963041": {
      "label": null,
      "contract": null,
      "balanceDiff": null,
      "nonceDiff": {
        "previousValue": 19,
        "newValue": 21
      },
      "stateDiff": {}
    },
    "0x1f30d2b155fcda0f7551dc8be5de6a84977685d4": {
      "label": null,
      "contract": "lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
      "balanceDiff": null,
      "nonceDiff": {
        "previousValue": 0,
        "newValue": 1
      },
      "stateDiff": {
        "0x0000000000000000000000000000000000000000000000000000000000000000": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000001"
        },
        "0x0000000000000000000000000000000000000000000000000000000000000001": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000000"
        },
        "0x0000000000000000000000000000000000000000000000000000000000000035": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0xfcc36732be75315bc3ea4a97a48ad0efd9201c685c492a6e112c3a728a76a52e"
        },
        "0x0000000000000000000000000000000000000000000000000000000000000037": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000000017418038ecf73ba4026c4f428547bf099706f27b"
        },
        "0x000000000000000000000000000000000000000000000000000000000000003b": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000049"
        },
        "0x000000000000000000000000000000000000000000000000000000000000003c": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x7661726961626c6544656274486f72527761414352454400000000000000002e"
        },
        "0x000000000000000000000000000000000000000000000000000000000000003d": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d306"
        },
        "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000000015f03e5de87c12cb2e2b8e5d6ecef0a9e21ab269",
          "label": "Implementation slot"
        },
        "0xbbe3212124853f8b0084a66a2d057c2966e251e132af3691db153ab65f0d1a4d": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x4161766520486f72697a6f6e20525741205661726961626c6520446562742041"
        },
        "0xbbe3212124853f8b0084a66a2d057c2966e251e132af3691db153ab65f0d1a4e": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x4352454400000000000000000000000000000000000000000000000000000000"
        }
      }
    },
    "0x83cb1b4af26eef6463ac20afbac9c0e2e017202f": {
      "label": null,
      "contract": "lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
      "balanceDiff": null,
      "nonceDiff": {
        "previousValue": 19,
        "newValue": 21
      },
      "stateDiff": {}
    },
    "0x87593272c06f4fc49ec2942ebda0972d2f1ab521": {
      "label": null,
      "contract": null,
      "balanceDiff": null,
      "nonceDiff": null,
      "stateDiff": {
        "0xd9f17190d51c7c6ccff6023e08820bc1546c793ba2da7b81159172f5a770cefd": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000000000000000000000000000000000000000000026ac"
        }
      }
    },
    "0x898e245d83ad255dc57b04978d0b4a12b94a557f": {
      "label": null,
      "contract": null,
      "balanceDiff": null,
      "nonceDiff": {
        "previousValue": 19,
        "newValue": 21
      },
      "stateDiff": {}
    },
    "0x985bcfab7e0f4ef2606cc5b64fc1a16311880442": {
      "label": null,
      "contract": null,
      "balanceDiff": null,
      "nonceDiff": null,
      "stateDiff": {
        "0xd9f17190d51c7c6ccff6023e08820bc1546c793ba2da7b81159172f5a770cefd": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000000060aed7d20ac6328f7ba771ad58931c996aff30e8"
        }
      }
    },
    "0xae05cd22df81871bc7cc2a04becfb516bfe332c8": {
      "label": null,
      "contract": "lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
      "balanceDiff": null,
      "nonceDiff": null,
      "stateDiff": {
        "0x000000000000000000000000000000000000000000000000000000000000003b": {
          "previousValue": "0x0000000000000000000000000000000000000000000000090000000000000000",
          "newValue": "0x00000000000000000000000000000000000000000000000a0000000000000000"
        },
        "0x50039cf134a124858bd88bbc9225ec3c537b89a0e9237ce39fe1813e6edf8257": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000284622c42134",
          "newValue": "0x0000000000000000000000000000000000000000000000000200283c23f02328"
        },
        "0x50039cf134a124858bd88bbc9225ec3c537b89a0e9237ce39fe1813e6edf8258": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x41435245442047484f0000000000000000000000000000000000000000000012"
        },
        "0x50039cf134a124858bd88bbc9225ec3c537b89a0e9237ce39fe1813e6edf8259": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000001"
        },
        "0x748ad6d0c5a24a04515706b6da6a7b0cb9e1a9408b9f3a5672a42f933d02d13e": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000000017418038ecf73ba4026c4f428547bf099706f27b"
        },
        "0xe7569c1de36b7b382c11b8838312b8b7a0397157bf8b3c82731f39ca7162a47e": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x10000000000000000000000000000e4e1c0000000000000001062a941db019c8"
        },
        "0xe7569c1de36b7b382c11b8838312b8b7a0397157bf8b3c82731f39ca7162a47f": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000"
        },
        "0xe7569c1de36b7b382c11b8838312b8b7a0397157bf8b3c82731f39ca7162a480": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000"
        },
        "0xe7569c1de36b7b382c11b8838312b8b7a0397157bf8b3c82731f39ca7162a481": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000009000000000000000000000000000000000000000000"
        },
        "0xe7569c1de36b7b382c11b8838312b8b7a0397157bf8b3c82731f39ca7162a482": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x000000000000000000000000c293744ffbcf46696d589f5c415e71bc491519cd"
        },
        "0xe7569c1de36b7b382c11b8838312b8b7a0397157bf8b3c82731f39ca7162a484": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000001f30d2b155fcda0f7551dc8be5de6a84977685d4"
        },
        "0xe7569c1de36b7b382c11b8838312b8b7a0397157bf8b3c82731f39ca7162a485": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000000087593272c06f4fc49ec2942ebda0972d2f1ab521"
        },
        "0xe7569c1de36b7b382c11b8838312b8b7a0397157bf8b3c82731f39ca7162a487": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000000"
        }
      }
    },
    "0xc293744ffbcf46696d589f5c415e71bc491519cd": {
      "label": null,
      "contract": "lib/aave-helpers/lib/aave-address-book/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
      "balanceDiff": null,
      "nonceDiff": {
        "previousValue": 0,
        "newValue": 1
      },
      "stateDiff": {
        "0x0000000000000000000000000000000000000000000000000000000000000000": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000002"
        },
        "0x0000000000000000000000000000000000000000000000000000000000000001": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000000"
        },
        "0x0000000000000000000000000000000000000000000000000000000000000037": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x4161766520486f72697a6f6e205257412041435245440000000000000000002c"
        },
        "0x0000000000000000000000000000000000000000000000000000000000000038": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x61486f7252776141435245440000000000000000000000000000000000000018"
        },
        "0x0000000000000000000000000000000000000000000000000000000000000039": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000001d5d386a90cea8acea9fa75389e97cf5f1ae21d306"
        },
        "0x000000000000000000000000000000000000000000000000000000000000003b": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x30583e048a84131cbbabc7db1dcad99465e1449e1b86507835a45d3354ee7fad"
        },
        "0x000000000000000000000000000000000000000000000000000000000000003c": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000000070cc725b8f05e0f230b05c4e91abc651e121354f"
        },
        "0x000000000000000000000000000000000000000000000000000000000000003d": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x00000000000000000000000017418038ecf73ba4026c4f428547bf099706f27b"
        },
        "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000008ca2a49c7df42e67f9a532f0d383d648fb7fe4c9",
          "label": "Implementation slot"
        }
      }
    },
    "0xefd5df7b87d2dce6dd454b4240b3e0a4db562321": {
      "label": null,
      "contract": null,
      "balanceDiff": null,
      "nonceDiff": null,
      "stateDiff": {
        "0x9dfc34013f2697a5578fe627227cbf092b03e48663008cad18bf62ab9b8bdc7b": {
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000001"
        }
      }
    }
  }
}
```