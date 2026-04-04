## Reserve changes

### Reserves altered

#### ACRED ([0x17418038ecF73BA4026c4f428547BF099706F27B](https://etherscan.io/address/0x17418038ecF73BA4026c4f428547BF099706F27B))

| description | value before | value after |
| --- | --- | --- |
| supplyCap | 30,000 ACRED | 1 ACRED |


## Raw diff

```json
{
  "reserves": {
    "0x17418038ecF73BA4026c4f428547BF099706F27B": {
      "supplyCap": {
        "from": 30000,
        "to": 1
      }
    }
  },
  "raw": {
    "0xae05cd22df81871bc7cc2a04becfb516bfe332c8": {
      "label": null,
      "contract": "lib/aave-umbrella/lib/aave-v3-origin/lib/solidity-utils/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
      "balanceDiff": null,
      "nonceDiff": null,
      "stateDiff": {
        "0xe7569c1de36b7b382c11b8838312b8b7a0397157bf8b3c82731f39ca7162a47e": {
          "previousValue": "0x10000000000000000000000000000007530000000000000001062a941db019c8",
          "newValue": "0x10000000000000000000000000000000001000000000000001062a941db019c8"
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
          "previousValue": "0x000000000000000000000000000000000000000000000000000000000000002d",
          "newValue": "0x000000000000000000000000000000000000000000000000000000000000002e"
        }
      }
    }
  }
}
```