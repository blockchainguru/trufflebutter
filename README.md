# trufflebutter

Dillinger is a group of smart contracts for a comming ICO. 

# Deployment

  - set up all necessary ethereum environment: geth, truffle, we are using the last version of truffle(3.4.9) with support to solidity 4.15
  - git clone https://github.com/blockchainguru/trufflebutter.git
  - cd trufflebutter
  - testrpc(for test) or geth to run a synced node
  - truffle migrate


# Contract Management
The project are divided in 3 contracts: Token contracts, ICO contract and Vesting Contract.

## Token contract
Implemented using OpenZepplin project with some ajusts for this project. It is a ERC20 compatible token. 
- token total supply is set to 100 million in the constructor, assigned to the owner(ICO contract)
- The token is pausable in transferability which can bi turned on/off by the owner
- Even the transferability is disabled, owner can still make transactions, see whenNotPausedOrOwner modifier in PausableToken.sol

## ICO contract
All tokens are created during the ICO/Token creation, and is transfered to each entity.
This contract Provides following operations:
- Vesting
-- createVestingForFounder create vesting for owner with pre-set amount of tokens
-- delegateVestingContractOwner change the vesting contract owner for future vesting management, the new owner need to accept to validate this operation
- ICO
-- setSoldPreSaleTokens set total sold tokens in pre-sale
-- setMultisignWallet, set the wallet address, need to be done before the ico start.
-- setContributionDates set the contribution dates in unixtime integer, should be bigger then now and can not be changed once icoEnabled is set 
-- enableICO, once the dates are set and everything is ready, need to turn this flag on to actually start the ICO
-- function() and buyTokens, investors call these 2 functions to buy tokens in the active ico period, the exceed amount of contribution is returned to investors and the eth are transfered to multi-sign wallet automatically.
-- endIco(), once the ico is finished(contribution cap reached or the endtime is reached) owner must call this methos to do some extra operation liketransfer unsoldTokens to multisign. Even the ico is not finished, owner can call this method to force finishing it.
-- drain, transfer all eths to owner, it is not necessary indeed.

- Token management
-- enableTokenTransferability/disableTokenTransferability contrals token transferability

## Vesting contract
Contract to manage vesting
- setVestingToken can set the vesting token. no need to be called in this project!
- createVestingByDurationAndSplits(address user, uint total_amount, uint startDate, uint durationPerVesting, uint times) for example  createVestingByDurationAndSplits(address, 100*(10**18 <= we are using 18 decimal!), now, 1 year, 4) means you will send in total 100 tokens in 4 times, each time 25 tokens, start from now, and the duration between 2 release is 1 year, so it means you will recevie all the tokens in next 4 years!
- vest() the beneficiary can receive the token using this function
- drain() owner of the contract can drain all eth and tokens in case of emergency





