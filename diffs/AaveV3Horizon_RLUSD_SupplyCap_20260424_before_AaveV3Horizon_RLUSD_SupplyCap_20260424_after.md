## Reserve changes

### Reserves altered

#### RLUSD ([0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD](https://etherscan.io/address/0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD))

| description | value before | value after |
| --- | --- | --- |
| supplyCap | 221,500,000 RLUSD | 271,500,000 RLUSD |


## Raw diff

```json
{
  "reserves": {
    "0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD": {
      "supplyCap": {
        "from": 221500000,
        "to": 271500000
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
        "0x9c5488d84d2a2a7cd0c3bdfdf95e375dff32a113c880ebf8321378ed34906a20": {
          "previousValue": "0x1000000000000000000000000000d33d26000a40830003e80512000000000000",
          "newValue": "0x100000000000000000000000000102ec2e000a40830003e80512000000000000"
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
          "previousValue": "0x000000000000000000000000000000000000000000000000000000000000002f",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000030"
        }
      }
    }
  }
}
```