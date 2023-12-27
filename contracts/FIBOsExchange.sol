// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interface/IFiboScriptions.sol";
import "./interface/IExchangeErrors.sol";
import "./interface/IFIBOsExchange.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract FIBOsExchange is IFIBOsExchange, IExchangeErrors, ReentrancyGuardUpgradeable{
    IFiboScriptions public fibosScription;

    constructor(address _fibosScription) {
        fibosScription = IFiboScriptions(_fibosScription);
    }

    mapping(uint256 id => uint256) private _sellPrice;

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // 上架铭文
    function listFibos(uint256 fibosId, uint256 time, uint256 price) public nonReentrant returns (bool) {
        address owner = _msgSender();
        if(fibosScription.isLocked(fibosId)){
            revert LockedFibos(fibosId);
        }
        if(time < block.timestamp){
            revert InvalidTime(time);
        }
        fibosScription.setLockFibosTime(owner, fibosId, time);
        _sellPrice[fibosId] = price;
        emit ListFibos(owner, fibosId, time, price);
        return true;
    }
    
    // 用户设置上架的fibos价格
    function setFibosPrice(uint256 fibosId, uint256 newPrice) public {
        address owner = _msgSender();
        address actualOwner = fibosScription.getOwner(fibosId);
        if(owner != actualOwner){
            revert NotFibosOwner(owner, fibosId, actualOwner);
        }
        // 需要该fibos处于锁定状态。
        if(!fibosScription.isLocked(fibosId)){
            revert NotLockedFibos(fibosId);
        }
        _sellPrice[fibosId] = newPrice;
        emit SetFibosPrice(owner, fibosId, newPrice);
    }

    // 获取用户上架的fibos
    function userListedFibos(address account) public view returns (uint256[] memory) {
        uint256[] memory fibosIds = fibosScription.ownerFibos(account);
        uint256 listedFibosAmount;
        for(uint256 i; i < fibosIds.length; ++i){
            if(fibosScription.isLocked(fibosIds[i])){
                listedFibosAmount++;
            }
        }

        uint256[] memory result = new uint256[](listedFibosAmount);
        for(uint256 i; i < fibosIds.length; ++i){
            if(fibosScription.isLocked(fibosIds[i])){
                result[i] = fibosIds[i];
            }
        }
        return result;
    }

    // 得到fibos的价格。
    function getFibosPrice(uint256 fibosId) public view returns (uint256) {
        return _sellPrice[fibosId];
    }

    // 下架铭文
    function unlistFibos(uint256 fibosId) public nonReentrant returns (bool) {
        address owner = _msgSender();
        // 需要该fibos处于锁定状态。
        if(!fibosScription.isLocked(fibosId)){
            revert NotLockedFibos(fibosId);
        }
        fibosScription.setLockFibosTime(owner, fibosId, 0);
        _sellPrice[fibosId] = 0;
        emit UnlistFibos(owner, fibosId);
        return true;
    }

    // 用户自己修改fibos锁定时间。
    function setFibosTime(uint256 fibosId, uint256 newTime) public nonReentrant returns (bool) {
        address owner = _msgSender();
        // 需要该fibos处于锁定状态。
        if(!fibosScription.isLocked(fibosId)){
            revert NotLockedFibos(fibosId);
        }
        if(newTime < block.timestamp){
            revert InvalidTime(newTime);
        }
        fibosScription.setLockFibosTime(owner, fibosId, newTime);
        emit SetFibosTime(owner, fibosId, newTime);
        return true;
    }

    // 购买fibos。
    function buyFibos(uint256 fibosId) public payable nonReentrant returns (bool) {
        if(!fibosScription.isLocked(fibosId)){
            revert NotLockedFibos(fibosId);
        }

        uint256 sellPrice = _sellPrice[fibosId];

        // 需要支付的主网币大于等于该fibos的价格。
        if(msg.value < sellPrice){
            revert InvalidAmount(msg.value);
        }

        // 原来fibos的拥有者。
        address preFibosOwner = fibosScription.getOwner(fibosId);
        address buyer = _msgSender();

        // 把fibo转移到卖家。
        (bool success, ) = payable(preFibosOwner).call{value: sellPrice}('');
        require(success, "transfer FIBO to seller failed");

        // 如果msg.value多了，则把剩余的给买家。
        if(msg.value > sellPrice){
            (bool success_2, ) = payable(buyer).call{value: msg.value - sellPrice}('');
            require(success_2, "transfer FIBO to buyer failed");
        }

        // 先解锁fibos，再转移。
        fibosScription.setLockFibosTime(preFibosOwner, fibosId, 0);

        uint256[] memory fibosIds = new uint256[](1);
        fibosIds[0] = fibosId;
        fibosScription.transferFromFibos(preFibosOwner, buyer, fibosIds);
        
        emit BuyFibos(preFibosOwner, buyer, fibosId, sellPrice);

        return true;
    }

    receive() external payable {}

}