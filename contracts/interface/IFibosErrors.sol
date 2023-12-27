// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFibosErrors {
    error InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error InvalidSender(address sender);
    error InvalidReceiver(address receiver);
    error InvalidAmount(uint256 amount);
    error InsufficientFibos(address, uint256[], uint256);
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error InvalidApprover(address approver);
    error InvalidSpender(address spender);
    error NotOwner(address from, uint256 fibosID, address actualOwner);
    error NotEOA(address sender);
    error NonexistentFibos(uint256 id);
    error MaxSupplyReached();
    error LockedFibos(uint256 id);
}
