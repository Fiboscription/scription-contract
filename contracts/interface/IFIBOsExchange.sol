// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFIBOsExchange {
    event BuyFibos(address indexed seller, address indexed buyer, uint256 fibosId, uint256 value);
    event ListFibos(address indexed owner, uint256 indexed fibosId, uint256 time, uint256 price);
    event UnlistFibos(address indexed owner, uint256 indexed fibosId);
    event SetFibosPrice(address indexed owner, uint256 indexed fibosId, uint256 newPrice);
    event SetFibosTime(address indexed owner, uint256 indexed fibosId, uint256 newTime);

}