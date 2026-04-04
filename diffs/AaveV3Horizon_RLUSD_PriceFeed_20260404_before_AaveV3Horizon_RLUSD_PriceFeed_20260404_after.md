## Reserve changes

### Reserves altered

#### RLUSD ([0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD](https://etherscan.io/address/0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD))

| description | value before | value after |
| --- | --- | --- |
| oracle | [0x26C46B7aD0012cA71F2298ada567dC9Af14E7f2A](https://etherscan.io/address/0x26C46B7aD0012cA71F2298ada567dC9Af14E7f2A) | [0xf0eaC18E908B34770FDEe46d069c846bDa866759](https://etherscan.io/address/0xf0eaC18E908B34770FDEe46d069c846bDa866759) |
| oracleDescription | RLUSD / USD | Capped RLUSD / USD |


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
        }
      }
    }
  }
}
```