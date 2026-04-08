## Reserve changes

### Reserve altered

#### RLUSD ([0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD](https://etherscan.io/address/0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD))

| description | value before | value after |
| --- | --- | --- |
| oracle | [0x26C46B7aD0012cA71F2298ada567dC9Af14E7f2A](https://etherscan.io/address/0x26C46B7aD0012cA71F2298ada567dC9Af14E7f2A) | [0xf0eaC18E908B34770FDEe46d069c846bDa866759](https://etherscan.io/address/0xf0eaC18E908B34770FDEe46d069c846bDa866759) |
| oracleDescription | RLUSD / USD | Capped RLUSD / USD |


#### USDC ([0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48](https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48))

| description | value before | value after |
| --- | --- | --- |
| oracle | [0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6](https://etherscan.io/address/0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6) | [0x3f73F03aa83B2A48ed27E964eD0fDb590332095B](https://etherscan.io/address/0x3f73F03aa83B2A48ed27E964eD0fDb590332095B) |
| oracleDescription | USDC / USD | Capped USDC / USD |
| oracleLatestAnswer | 0.99991 | 0.99995436 |


## Raw diff

```json
{
  "reserves": {
    "0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD": {
      "oracle": {
        "from": "0x26C46B7aD0012cA71F2298ada567dC9Af14E7f2A",
        "to": "0xf0eaC18E908B34770FDEe46d069c846bDa866759"
      },
      "oracleDescription": {
        "from": "RLUSD / USD",
        "to": "Capped RLUSD / USD"
      }
    },
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
      "oracle": {
        "from": "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6",
        "to": "0x3f73F03aa83B2A48ed27E964eD0fDb590332095B"
      },
      "oracleDescription": {
        "from": "USDC / USD",
        "to": "Capped USDC / USD"
      },
      "oracleLatestAnswer": {
        "from": "99991000",
        "to": "99995436"
      }
    }
  },
  "raw": {
    "0x985bcfab7e0f4ef2606cc5b64fc1a16311880442": {
      "label": null,
      "contract": null,
      "balanceDiff": null,
      "nonceDiff": null,
      "stateDiff": {
        "0x4e4f22273bf5bc307ce4d44de9b696fde788cba6119ef3bd24dc8a4ace26ced8": {
          "previousValue": "0x00000000000000000000000026c46b7ad0012ca71f2298ada567dc9af14e7f2a",
          "newValue": "0x000000000000000000000000f0eac18e908b34770fdee46d069c846bda866759"
        },
        "0xc6521c8ea4247e8beb499344e591b9401fb2807ff9997dd598fd9e56c73a264d": {
          "previousValue": "0x0000000000000000000000008fffffd4afb6115b954bd326cbe7b4ba576818f6",
          "newValue": "0x0000000000000000000000003f73f03aa83b2a48ed27e964ed0fdb590332095b"
        }
      }
    }
  }
}
```