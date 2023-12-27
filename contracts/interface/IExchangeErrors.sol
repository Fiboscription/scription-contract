// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IExchangeErrors {
    error NotFibosOwner(address from, uint256 fibosID, address actualOwner);
    error NotLockedFibos(uint256 id);
    error InvalidTime(uint256 time);
    error LockedFibos(uint256 id);
    error InvalidAmount(uint256 amount);

}