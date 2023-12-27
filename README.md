# Fibos Inscription Contract

The Fibos Inscription Contract integrates both ERC20 and UTXO models, wherein each Fibos inscription is akin to a banknote, annotated with 'value', 'inscription ID', and 'owner'. You have the flexibility to transfer the monetary value represented by the Fibos inscription, or directly hand over an inscription to another party.

When transferring the aggregate amount represented by multiple inscriptions, the inscriptions utilized are annihilated. Subsequently, a new inscription with the revised value is transferred to the recipient. Notably, if the transfer amount does not precisely match the sum of the used inscriptions, a new Fibos is generated for oneself. Transferring a Fibos inscription per se is tantamount to changing the 'owner' name on the amount to the recipient, while the inscription ID remains constant.

An inscription locking interface is incorporated to facilitate future trading contracts.

The inscription contract has been developed and fully tested, with ongoing plans to further refine and test trading functionalities in the future.

## ❤️ Core Methods:

✅ Inscription of Fibos: Directly transfer Fibos mainnet tokens to this contract.

🔒 Requirements:

1. Must transfer 10 Fibo.
2. Only external addresses can initiate the transfer.
3. The total number of current inscriptions has not reached the limit.

📢 Events Triggered:

1. TransferFiboEthers(address indexed from, address indexed to, uint256 value);
   Logs the transfer of mainnet tokens.
2. CreateFibos(address indexed owner, uint256 indexed id, uint256 value);
   Creates a new Fibos inscription.
3. Transfer(address indexed from, address indexed to, uint256 value);
   Transfers from the zero address to the 'to' address, one inscription containing 777 tokens.

## 👀 Read-Only Interfaces:

1. MAX_SUPPLY(): The maximum token supply defined in the code, a constant currently set at 77,700,000.
2. SINGLE_AMOUNT(): The number of tokens in a single inscription, currently set at 777.
3. stakingPool(): The staking pool contract address. This is where the mainnet tokens paid for inscribing are directly transferred.
4. fibos(uint256 id) returns (FIBOS): Input the ID of an inscription and receive information about it. If the returned content is all zeros, then the inscription does not exist.
```
struct FIBOS {
    uint256 id;
    uint256 amount;
    address owner;
}

```
5. name(): The name of the token, "FIBOScriptions".
6. symbol(): The symbol of the token, "FIBOs".
7. totalSupply(): The current total supply of the token, determined by the number of inscriptions. For example, one inscription increases supply by 777, ten inscriptions by 7770.
8. lastFibos(): The ID of the most recently inscribed Fibos. Since inscriptions in this contract represent UTXOs, they can be spent, so lastFibos does not indicate the total number of current inscriptions, nor is there a need to provide total inscription count data.
9. balanceOf(address account) returns (uint256): Queries the token balance of a user. Input an address to return the account's token balance.
10. ownerFibos(address owner) returns (uint256[]): Queries the inscription IDs owned by a user. Input a user's address to return their inscription IDs.
11. getFibosTotalValue(uint256[] fibosID) returns (uint256): Queries the total token amount in inscriptions. Input an array of inscription IDs to return the total token amount in these inscriptions.
12. getStake(address account) returns (uint256): Queries the amount of mainnet tokens spent by a user, i.e., how many Fibos tokens were used for inscriptions. Input an address to return the amount of Fibos, with a fixed-point precision of 18 decimal places.
13. getOwner(uint256 fibosId) returns (address): Queries the owner of a specific inscription. Input the ID of a Fibos to return its owner's address.
14. allowance(address owner, address spender) returns (uint256): Queries the allowance amount that one address has given to another. 'owner' is the grantor, and 'spender' is the grantee or the one who spends the money. Returns the amount of allowance.
15. getFibosPrice(uint256 fibosId) returns (uint256): Queries the current listing price of an inscription. Input the inscription ID to return the price.
16. isLocked(uint256 fibosId) returns (bool): Queries whether a specific inscription is locked, i.e., if it is listed. Returns true if it is listed.
17. getHoldersCount() returns (uint256): Queries the current number of inscription holders.
18. decimals() returns (uint8): Retrieves the decimal precision, which is 0.
19. getHoldersAddress() returns (address[] memory): Retrieves the addresses of all current inscription holders.

## 🖊️ Write Functions:

1. ✅ transfer(address to, uint256 value) returns (bool)

   Function for transferring tokens, to be called by the user wishing to make a transfer. 'to' is the target address, and 'value' is the amount of tokens to be transferred. ⚠️Note: In this contract, tokens have no decimals; entering 10 means transferring 10 tokens, not 10e18. Returns true if the transaction is successful.

   🔒 Requirements:

   - The 'to' address cannot be the zero address.
   - 'value' must be less than or equal to the caller's balance.

   📢 Events Triggered:

   - SpendFibos(address **indexed** spender, uint256[] ids, uint256 values);
     
     Represents the spent inscriptions, akin to which banknotes were spent. 'spender' is the spender, 'ids' array contains the IDs of the spent inscriptions, and 'values' is the total token amount of these inscriptions.

   - CreateFibos(address **indexed** owner, uint256 **indexed** id, uint256 value);
     
     Creates a new inscription, analogous to converting the spent banknotes into new ones. 'owner' is the owner of the new inscription, 'id' is the new inscription's number which is always unique and incrementally generated, and 'value' is the price of this new inscription.

   - Transfer(address **indexed** from, address **indexed** to, uint256 value);
     
     Token transfer event, where 'from' is the sending address, 'to' is the receiving address, and 'value' is the amount of tokens transferred.

2. ✅ transferFrom(address from, address to, uint256 value) returns (bool)

   This function facilitates token transfer, similar to ERC20 tokens, and is called by an authorized address. It will spend the authorized spender's allowance.

   🔒 Requirements:

   - The caller must have an allowance greater than or equal to 'value'.
   - Both 'from' and 'to' addresses cannot be the zero address.
   - 'value' must be less than or equal to the balance of 'from'.

   📢 Events Triggered:

   - SpendFibos(address **indexed** spender, uint256[] ids, uint256 values);
     
     Reflects the spent inscriptions. 'spender' is the one who spends the inscriptions, 'ids' array includes the IDs of the spent inscriptions, and 'values' represents the total token amount of these inscriptions.

   - CreateFibos(address **indexed** owner, uint256 **indexed** id, uint256 value);
     
     Indicates the creation of a new inscription, signifying the transformation of the spent inscriptions into new ones. 'owner' is the owner of the new inscription, 'id' is the unique and incrementally generated number of the new inscription, and 'value' is its price.

   - Transfer(address **indexed** from, address **indexed** to, uint256 value);
     
     A token transfer event, where 'from' is the sender's address, 'to' is the recipient's address, and 'value' is the amount of tokens being transferred.

3. ✅ transferFibos(address to, uint256[] memory fibosIds) returns (bool)

   This function allows the transfer of specified inscription IDs to the 'to' address, to be called by the user wishing to transfer inscriptions. The 'fibosIds' array contains the IDs of the inscriptions being transferred. This mode of transfer does not destroy old inscriptions or generate new ones (hence no new inscription IDs are created); it simply updates the owner in the inscription, so the inscription ID remains unchanged.

   🔒 Requirements:

   - The 'to' address cannot be the zero address.
   - The inscription IDs in 'fibosIds' must indeed belong to the caller.
   - The inscriptions in 'fibosIds' are not in a listed or pending state for sale.

   📢 Events Triggered:

   - TransferFibos(address **indexed** from, address **indexed** to, uint256[] fibosId);
     
     Represents the transfer of specific inscriptions. 'from' is the sender, 'to' is the recipient, and 'fibosId' are the IDs of the transferred inscriptions.

   - Transfer(address **indexed** from, address **indexed** to, uint256 value);
     
     A token transfer event, where 'from' is the sender's address, 'to' is the recipient's address, and 'value' is the amount of tokens being transferred (in this case, the token amount is implied in the inscription IDs).

4. ✅ transferFromFibos(address from, address to, uint256[] memory fibosIds) returns (bool)

   This function is similar to transferFibos, with the key difference being that it is called by an authorized address to spend from another address ('from').

   🔒 Requirements:

   - The caller's authorized allowance must be greater than or equal to the total token value of the inscriptions in 'fibosIds'.
   - Both 'from' and 'to' addresses cannot be the zero address.
   - The inscription IDs in 'fibosIds' must genuinely belong to the 'from' address.
   - The inscriptions in 'fibosIds' are not in a listed or pending state for sale.

   📢 Events Triggered:

   - TransferFibos(address **indexed** from, address **indexed** to, uint256[] fibosId);
     
     Indicates the transfer of specific inscriptions. 'from' is the source address, 'to' is the destination address, and 'fibosId' are the IDs of the transferred inscriptions.

   - Transfer(address **indexed** from, address **indexed** to, uint256 value);
     
     A token transfer event, where 'from' is the sender's address, 'to' is the recipient's address, and 'value' is the amount of tokens being transferred (as represented by the inscription IDs in this case).

5. ✅ approve(address spender, uint256 value) returns (bool)

   This function sets an allowance, allowing the caller to authorize a 'spender' to spend a specified 'value' on their behalf.

   🔒 Requirements:

   - 'spender' cannot be the zero address.

   📢 Events Triggered:

   - Approval(address **indexed** owner, address **indexed** spender, uint256 value);
     
     Indicates the approval of an allowance. 'owner' is the address granting the permission, 'spender' is the one authorized to spend, and 'value' is the amount of tokens that the spender is authorized to use.

