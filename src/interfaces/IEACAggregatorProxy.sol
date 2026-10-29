// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @dev Minimal interface for a Chainlink feed proxy (EACAggregatorProxy). Its aggregator is also
///      ConfirmedOwner, so `owner()` can be called on both.
interface IEACAggregatorProxy {
  function aggregator() external view returns (address);

  function owner() external view returns (address);
}
