## Reserve changes

### Reserve altered

#### USCC ([0x14d60E7FDC0D71d8611742720E4C50E7a974020c](https://etherscan.io/address/0x14d60E7FDC0D71d8611742720E4C50E7a974020c))

| description | value before | value after |
| --- | --- | --- |
| supplyCap | 29,000,000 USCC | 15,000,000 USCC |


#### GHO ([0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f](https://etherscan.io/address/0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f))

| description | value before | value after |
| --- | --- | --- |
| supplyCap | 45,000,000 GHO | 35,000,000 GHO |


#### USTB ([0x43415eB6ff9DB7E26A15b704e7A3eDCe97d31C4e](https://etherscan.io/address/0x43415eB6ff9DB7E26A15b704e7A3eDCe97d31C4e))

| description | value before | value after |
| --- | --- | --- |
| supplyCap | 1,800,000 USTB | 3,600,000 USTB |


#### JAAA ([0x5a0F93D040De44e78F251b03c43be9CF317Dcf64](https://etherscan.io/address/0x5a0F93D040De44e78F251b03c43be9CF317Dcf64))

| description | value before | value after |
| --- | --- | --- |
| supplyCap | 40,000,000 JAAA | 10,000,000 JAAA |


## Raw diff

```json
{
  "reserves": {
    "0x14d60E7FDC0D71d8611742720E4C50E7a974020c": {
      "supplyCap": {
        "from": 29000000,
        "to": 15000000
      }
    },
    "0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f": {
      "supplyCap": {
        "from": 45000000,
        "to": 35000000
      }
    },
    "0x43415eB6ff9DB7E26A15b704e7A3eDCe97d31C4e": {
      "supplyCap": {
        "from": 1800000,
        "to": 3600000
      }
    },
    "0x5a0F93D040De44e78F251b03c43be9CF317Dcf64": {
      "supplyCap": {
        "from": 40000000,
        "to": 10000000
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
        "0x11567aab4cd72d4842d11c42514ff879ac1d304b8bb2969ce8bddb1f43474e61": {
          "previousValue": "0x100000000000000000000000000001b774000000000000000106283c23282260",
          "newValue": "0x1000000000000000000000000000036ee8000000000000000106283c23282260"
        },
        "0x3e3cd529c7fd49079eabd02ec66b1f8c8d0cba5b926a12093d4fd96d7317f0c6": {
          "previousValue": "0x10000000000000000000000000002625a0000000000000000106290421981fa4",
          "newValue": "0x1000000000000000000000000000098968000000000000000106290421981fa4"
        },
        "0xd5ce75cb182c08131629ee08dd3321e186ca2940f202ad7ebc1489790f40d199": {
          "previousValue": "0x10000000000000000000000000001ba814000000000000000106290422602134",
          "newValue": "0x10000000000000000000000000000e4e1c000000000000000106290422602134"
        },
        "0xfd2dab4be6d07bba0109696859cf3ea9f610b92569d2a062e705af4b9c58ff16": {
          "previousValue": "0x10000000000000000000000000002aea540002160ec003e80512000000000000",
          "newValue": "0x10000000000000000000000000002160ec0002160ec003e80512000000000000"
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
          "previousValue": "0x000000000000000000000000000000000000000000000000000000000000002c",
          "newValue": "0x000000000000000000000000000000000000000000000000000000000000002d"
        }
      }
    }
  }
}
```