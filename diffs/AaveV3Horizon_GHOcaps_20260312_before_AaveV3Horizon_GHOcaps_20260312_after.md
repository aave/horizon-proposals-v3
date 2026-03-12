## Reserve changes

### Reserves altered

#### GHO ([0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f](https://etherscan.io/address/0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f))

| description | value before | value after |
| --- | --- | --- |
| supplyCap | 55,000,000 GHO | 45,000,000 GHO |
| borrowCap | 43,000,000 GHO | 35,000,000 GHO |


## Raw diff

```json
{
  "reserves": {
    "0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f": {
      "borrowCap": {
        "from": 43000000,
        "to": 35000000
      },
      "supplyCap": {
        "from": 55000000,
        "to": 45000000
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
        "0xfd2dab4be6d07bba0109696859cf3ea9f610b92569d2a062e705af4b9c58ff16": {
          "previousValue": "0x10000000000000000000000000003473bc00029020c003e80512000000000000",
          "newValue": "0x10000000000000000000000000002aea540002160ec003e80512000000000000"
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
          "previousValue": "0x000000000000000000000000000000000000000000000000000000000000002a",
          "newValue": "0x000000000000000000000000000000000000000000000000000000000000002b"
        }
      }
    }
  }
}
```