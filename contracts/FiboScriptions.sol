// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interface/IFibosErrors.sol";
import "./interface/IFiboScriptions.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FiboScriptions is IFibosErrors, IFiboScriptions, ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    EnumerableSetUpgradeable.AddressSet private holders;
    uint256 public constant MAX_SUPPLY = 77700000;
    uint256 public constant SINGLE_AMOUNT = 777;
    address public stakingPool;
    address public fibosExchange;

    string private constant _name = "FiboScriptions";
    string private constant _symbol = "FIBOs";

    uint256 private _totalSupply;
    uint256 private _curID;

    struct FIBOS {
        uint256 id;
        uint256 amount;
        address owner;
    }

    mapping(address account => uint256) private _balances;
    mapping(address owner => uint256[]) private _ownedFibos;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    mapping(address account => uint256) private _stake;

    mapping(uint256 id => uint256) private _unlockTime;
    
    mapping(uint256 id => FIBOS) public fibos;

    modifier onlyExchange {
        require(msg.sender == fibosExchange, "onlyExchange");
        _;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() external initializer {
        __Ownable_init();
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function lastFibos() public view returns (uint256) {
        return _curID - 1;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function ownerFibos(address owner) public view returns (uint256[] memory) {
        uint256[] memory result = _ownedFibos[owner];
        return result;
    }

    function getOwnerFibosLength(address owner) public view returns (uint256) {
        return _ownedFibos[owner].length;
    }

    function getFibosTotalValue(uint256[] memory fibosID) public view returns (uint256) {
        uint256 totalFibosValue;
        for(uint256 i; i < fibosID.length; ++i){
            totalFibosValue += fibos[fibosID[i]].amount;
        }
        return totalFibosValue;
    }

    function getStake(address account) public view returns (uint256) {
        return _stake[account];
    }

    function getOwner(uint256 fibosId) public view returns (address) {
        return _requireOwned(fibosId);
    }

    function getHoldersCount() public view returns (uint256) {
        return holders.length();
    }

    function getHoldersAddress() public view returns (address[] memory) {
        return holders.values();
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public nonReentrant returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) public nonReentrant returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public nonReentrant returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function transferFibos(address to, uint256[] memory fibosIds) public nonReentrant returns (bool) {
        address owner = _msgSender();
        _transferFibos(owner, to, fibosIds);
        return true;
    }

    function transferFromFibos(address from, address to, uint256[] memory fibosIds) public nonReentrant returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, getFibosTotalValue(fibosIds));
        _transferFibos(from, to, fibosIds);
        return true;
    }

    function setFibosExchange(address _fibosExchange) public onlyOwner() returns (bool) {
        fibosExchange = _fibosExchange;
        return true;
    }

    function isLocked(uint256 fibosId) public view returns (bool) {
        return _unlockTime[fibosId] > block.timestamp;
    }

    function setStakingPoolAddr(address _stakingPool) public onlyOwner() returns (bool) {
        stakingPool = _stakingPool;
        return true;
    }
    
    function setLockFibosTime(address owner, uint256 fibosId, uint256 time) external onlyExchange() {
        if(owner != fibos[fibosId].owner){
            revert NotOwner(owner, fibosId, fibos[fibosId].owner);
        }
        _unlockTime[fibosId] = time;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert InvalidReceiver(address(0));
        }

        uint256 fromBalance = balanceOf(from);
        if (fromBalance < value) {
            revert InsufficientBalance(from, fromBalance, value);
        }

        uint256 tempValue;
        uint256 i;
        for(; i < _ownedFibos[from].length; ++i) {
            if (tempValue >= value) {
                break;
            }
            if (!isLocked(_ownedFibos[from][i])) {
                tempValue += fibos[_ownedFibos[from][i]].amount;
            }
        }

        if (tempValue < value) {
            revert InsufficientBalance(from, tempValue, value);
        }

        uint256[] memory consumeFibosID = new uint256[](i);
        for(uint256 j; j < i; ++j) {
            if (!isLocked(_ownedFibos[from][j])) {
                consumeFibosID[j] = _ownedFibos[from][j];
            }
        }

        _spendFibos(from, consumeFibosID, value);

        _createFibos(to, value);

        if(_balances[to] == 0) {
            holders.add(to);
        }

        _balances[from] = fromBalance - value;
        _balances[to] += value;

        if(_balances[from] == 0) {
            holders.remove(from);
        } 

        emit Transfer(from, to, value);
    }

    function _transferFibos(address from, address to, uint256[] memory fibosIds) internal returns (bool) {
        if (from == address(0)) {
            revert InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert InvalidReceiver(address(0));
        }

        for(uint256 i; i < fibosIds.length; ++i){
            if (! _checkOwner(from, fibosIds[i])) {
                revert NotOwner(from, fibosIds[i], fibos[fibosIds[i]].owner);
            }
            if(isLocked(fibosIds[i])){
                revert LockedFibos(fibosIds[i]);
            }
            fibos[fibosIds[i]].owner = to;
            _deleteFibos(from, fibosIds[i]);
            _ownedFibos[to].push(fibosIds[i]);
        }

        uint256 value = getFibosTotalValue(fibosIds);

        if(_balances[to] == 0) {
            holders.add(to);
        }

        _balances[from] -= value;
        _balances[to] += value;

        if(_balances[from] == 0) {
            holders.remove(from);
        } 

        emit TransferFibos(from, to, fibosIds);
        emit Transfer(from, to, value);
        return true;
    }

    function _spendFibos(address spender, uint256[] memory fibosIds, uint256 value) internal {
        uint256 totalFibosValue = getFibosTotalValue(fibosIds);
        if (totalFibosValue < value) {
            revert InsufficientFibos(spender, fibosIds, totalFibosValue);
        }

        for(uint256 i; i < fibosIds.length; ++i){
            _deleteFibos(spender, fibosIds[i]);
            delete fibos[fibosIds[i]];
        }
        if (totalFibosValue != value) {
            _createFibos(spender, totalFibosValue - value);
        }
        emit SpendFibos(spender, fibosIds, totalFibosValue);
    }

    function _deleteFibos(address account, uint256 fibosId) internal {
        for(uint256 i; i < _ownedFibos[account].length; ++i) {
            if (_ownedFibos[account][i] == fibosId) {
                uint256 lastIndex = _ownedFibos[account].length - 1;
                _ownedFibos[account][i] = _ownedFibos[account][lastIndex];
                _ownedFibos[account].pop();
            }
        }
    }

    function _createFibos(address account, uint256 value) internal {
        if (_balances[account] == 0){
            holders.add(account);
        }
        FIBOS memory newFibos = FIBOS(_curID, value, account);
        fibos[_curID] = newFibos;
        _ownedFibos[account].push(_curID);
        emit CreateFibos(account, _curID, value);
        _curID ++;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        if (owner == address(0)) {
            revert InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }

    function _requireOwned(uint256 fibosId) internal view returns (address) {
        address owner = fibos[fibosId].owner;
        if (owner == address(0)) {
            revert NonexistentFibos(fibosId);
        }
        return owner;
    }

    function _checkOwner(address inputAddress, uint256 fibosId) internal view returns (bool) {
        address owner = fibos[fibosId].owner;
        if(owner == inputAddress){
            return true;
        } else {
            return false;
        }
    }

    receive() external payable {
        if(msg.value != 10e18) {
            revert InvalidAmount(msg.value);
        }
        if (_msgSender() != tx.origin) {
            revert NotEOA(_msgSender());
        }
        if (_totalSupply >= MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        if(msg.value != 0) {
            (bool success, ) = payable(stakingPool).call{value: msg.value}('');
            require(success, "transfer FIBO to seller failed");
            emit TransferFiboEthers(_msgSender(), stakingPool, msg.value);
        }
        _createFibos(_msgSender(), SINGLE_AMOUNT);
        emit Transfer(address(0x0), _msgSender(), SINGLE_AMOUNT);
        _totalSupply += SINGLE_AMOUNT;
        _balances[_msgSender()] += SINGLE_AMOUNT;
        _stake[_msgSender()] += msg.value;
    }

}