// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFiboScriptions {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event CreateFibos(address indexed owner, uint256 indexed id, uint256 value);
    event SpendFibos(address indexed spender, uint256[] ids, uint256 values);
    event TransferFibos(address indexed from, address indexed to, uint256[] fibosId);
    event TransferFiboEthers(address indexed from, address indexed to, uint256 value);
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function ownerFibos(address owner) external view returns (uint256[] memory);
    function getOwnerFibosLength(address owner) external view returns (uint256);
    function getFibosTotalValue(uint256[] memory fibosID) external returns (uint256);
    function getStake(address account) external returns (uint256);
    function getOwner(uint256 fibosId) external returns (address);
    function getHoldersCount() external returns (uint256);
    function transferFibos(address to, uint256[] memory fibosIds) external returns (bool);
    function transferFromFibos(address from, address to, uint256[] memory fibosIds) external returns (bool);
    function setLockFibosTime(address owner, uint256 fibosId, uint256 time) external;
    function isLocked(uint256 fibosId) external view returns (bool);
    function getHoldersAddress() external view returns (address[] memory);
}