## Reserve changes

### Reserve altered

#### JAAA ([0x5a0F93D040De44e78F251b03c43be9CF317Dcf64](https://etherscan.io/address/0x5a0F93D040De44e78F251b03c43be9CF317Dcf64))

| description | value before | value after |
| --- | --- | --- |
| supplyCap | 10,000,000 JAAA | 13,000,000 JAAA |


#### JTRSY ([0x8c213ee79581Ff4984583C6a801e5263418C4b86](https://etherscan.io/address/0x8c213ee79581Ff4984583C6a801e5263418C4b86))

| description | value before | value after |
| --- | --- | --- |
| supplyCap | 37,100,000 JTRSY | 10,000,000 JTRSY |


## Raw diff

```json
{
  "reserves": {
    "0x5a0F93D040De44e78F251b03c43be9CF317Dcf64": {
      "supplyCap": {
        "from": 10000000,
        "to": 13000000
      }
    },
    "0x8c213ee79581Ff4984583C6a801e5263418C4b86": {
      "supplyCap": {
        "from": 37100000,
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
        "0x3e3cd529c7fd49079eabd02ec66b1f8c8d0cba5b926a12093d4fd96d7317f0c6": {
          "previousValue": "0x1000000000000000000000000000098968000000000000000106290421981fa4",
          "newValue": "0x10000000000000000000000000000c65d4000000000000000106290421981fa4"
        },
        "0xacf2ff196afce2b187be3a6e96c44dc0e53e0283955e075ab05e8f8d209afad1": {
          "previousValue": "0x100000000000000000000000000023619e000000000000000106286e22602198",
          "newValue": "0x1000000000000000000000000000098968000000000000000106286e22602198"
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
          "previousValue": "0x0000000000000000000000000000000000000000000000000000000000000032",
          "newValue": "0x0000000000000000000000000000000000000000000000000000000000000033"
        }
      }
    }
  }
}
```