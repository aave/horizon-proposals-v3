## Reserve changes

### Reserves altered

#### GHO ([0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f](https://etherscan.io/address/0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f))

| description | value before | value after |
| --- | --- | --- |
| maxVariableBorrowRate | 3.25 % | 2.75 % |
| baseVariableBorrowRate | 3.25 % | 2.75 % |
| interestRate | ![before](https://dash.onaave.com/api/static?variableRateSlope1=0&variableRateSlope2=0&optimalUsageRatio=990000000000000000000000000&baseVariableBorrowRate=32500000000000000000000000&maxVariableBorrowRate=32500000000000000000000000) | ![after](https://dash.onaave.com/api/static?variableRateSlope1=0&variableRateSlope2=0&optimalUsageRatio=990000000000000000000000000&baseVariableBorrowRate=27500000000000000000000000&maxVariableBorrowRate=27500000000000000000000000) |

## Raw diff

```json
{
  "strategies": {
    "0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f": {
      "baseVariableBorrowRate": {
        "from": "32500000000000000000000000",
        "to": "27500000000000000000000000"
      },
      "maxVariableBorrowRate": {
        "from": "32500000000000000000000000",
        "to": "27500000000000000000000000"
      }
    }
  },
  "raw": {
    "0x87593272c06f4fc49ec2942ebda0972d2f1ab521": {
      "label": null,
      "contract": null,
      "balanceDiff": null,
      "nonceDiff": null,
      "stateDiff": {
        "0x8464d39f2e013f742832d01b64507041c699fe53e2b530f6afd3f7345d1a56ff": {
          "previousValue": "0x00000000000000000000000000000000000000000000000000000000014526ac",
          "newValue": "0x00000000000000000000000000000000000000000000000000000000011326ac"
        }
      }
    },
    "0xae05cd22df81871bc7cc2a04becfb516bfe332c8": {
      "label": null,
      "contract": "lib/aave-umbrella/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
      "balanceDiff": null,
      "nonceDiff": null,
      "stateDiff": {
        "0xfd2dab4be6d07bba0109696859cf3ea9f610b92569d2a062e705af4b9c58ff17": {
          "previousValue": "0x000000000003a8b35a10686b388acc92000000000342247f06b4ece14305dcd7",
          "newValue": "0x00000000000318bff17b99906f4ddd9e0000000003422b46f7cfdd5f9c6dbb2b"
        },
        "0xfd2dab4be6d07bba0109696859cf3ea9f610b92569d2a062e705af4b9c58ff18": {
          "previousValue": "0x00000000001ae22487c1042af080000000000000034bef77c6ca8416910757b1",
          "newValue": "0x000000000016bf59fcb70386cb80000000000000034c21e15c205970a47de302"
        },
        "0xfd2dab4be6d07bba0109696859cf3ea9f610b92569d2a062e705af4b9c58ff19": {
          "previousValue": "0x00000000000000000000000069b72cff00000000000000000000000000000000",
          "newValue": "0x00000000000000000000000069baa15700000000000000000000000000000000"
        },
        "0xfd2dab4be6d07bba0109696859cf3ea9f610b92569d2a062e705af4b9c58ff1e": {
          "previousValue": "0x0000000000000000000000000000000000000000000000066144807d7489192e",
          "newValue": "0x00000000000000000000000000000000000000000000000cf055b1fb3144fa48"
        }
      }
    },
    "0xe6ec1f0ae6cd023bd0a9b4d0253bdc755103253c": {
      "label": null,
      "contract": null,
      "balanceDiff": null,
      "nonceDiff": null,
      "stateDiff": {
        "0x0000000000000000000000000000000000000000000000000000000000000005": {
          "previousValue": "0x000000000000000000000000000000000000000000000000000000000000002b",
          "newValue": "0x000000000000000000000000000000000000000000000000000000000000002c"
        }
      }
    }
  }
}
```