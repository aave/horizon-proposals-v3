## Reserve changes

### Reserve altered

#### GHO ([0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f](https://etherscan.io/address/0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f))

| description | value before | value after |
| --- | --- | --- |
| isFlashloanable | false | true |


#### RLUSD ([0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD](https://etherscan.io/address/0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD))

| description | value before | value after |
| --- | --- | --- |
| isFlashloanable | false | true |


#### USDC ([0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48](https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48))

| description | value before | value after |
| --- | --- | --- |
| isFlashloanable | false | true |


## Raw diff

```json
{
  "reserves": {
    "0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f": {
      "isFlashloanable": {
        "from": false,
        "to": true
      }
    },
    "0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD": {
      "isFlashloanable": {
        "from": false,
        "to": true
      }
    },
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
      "isFlashloanable": {
        "from": false,
        "to": true
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
          "newValue": "0x1000000000000000000000000000d33d26000a40830003e88512000000000000"
        },
        "0xed960c71bd5fa1333658850f076b35ec5565086b606556c3dd36a916b43ddf20": {
          "previousValue": "0x1000000000000000000000000000393870000337f98003e80506000000000000",
          "newValue": "0x1000000000000000000000000000393870000337f98003e88506000000000000"
        },
        "0xfd2dab4be6d07bba0109696859cf3ea9f610b92569d2a062e705af4b9c58ff16": {
          "previousValue": "0x10000000000000000000000000002160ec0002160ec003e80512000000000000",
          "newValue": "0x10000000000000000000000000002160ec0002160ec003e88512000000000000"
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
          "previousValue": "0x000000000000000000000000000000000000000000000000000000000000002e",
          "newValue": "0x000000000000000000000000000000000000000000000000000000000000002f"
        }
      }
    }
  }
}
```