pragma solidity ^0.4.11;

import './SLMToken.sol';
import './math/SafeMath.sol';
import './lifecycle/Pausable.sol';

/**
 * @title Crowdsale 
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet 
 * as they arrive.
 */
contract SLMICO is Pausable{
  using SafeMath for uint256;

  //Gas/GWei
  uint public minContribAmount = 0.01 ether;
  uint public maxGasPrice = 50000000000;

  // The token being sold
  SLMToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // need to be enabled to allow investor to participate in the ico
  bool public icoEnabled;

  // address where funds are collected
  address public multisignWallet;

  // amount of raised money in wei
  uint256 public weiRaised;

  // totalSupply
  uint256 constant public totalSupply = 100000000 * (10 ** 18);
  //pre sale cap
  uint256 constant public preSaleCap = 10000000 * (10 ** 18);
  //sale cap
  uint256 constant public initialICOCap = 60000000 * (10 ** 18);
  //founder share
  uint256 constant public tokensForFounder = 10000000 * (10 ** 18);
  //dev team share
  uint256 constant public tokensForDevteam = 10000000 * (10 ** 18);
  //Partners share
  uint256 constant public tokensForPartners = 5000000 * (10 ** 18);
  //Charity share
  uint256 constant public tokensForCharity = 3000000 * (10 ** 18);
  //Bounty share
  uint256 constant public tokensForBounty = 2000000 * (10 ** 18);
    
  //Sold presale tokens
  uint256 public soldPreSaleTokens; 
  uint256 public sentPreSaleTokens;

  //ICO tokens
  //Is calcluated as: initialICOCap + preSaleCap - soldPreSaleTokens
  uint256 public icoCap; 
  uint256 public icoSoldTokens; 
  bool public icoEnded;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {
    token = createTokenContract();
  }

  // creates the token to be sold. 
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (SLMToken) {
    return new SLMToken();
  }

  // enable token tranferability
  function enableTokenTransferability() onlyOwner {
    require(token != address(0));
    token.unpause(); 
  }

  // disable token tranferability
  function disableTokenTransferability() onlyOwner {
    require(token != address(0));
    token.pause(); 
  }

  // set total pre sale sold token
  // can not be changed once the ico is enabled
  // Ico cap is determined by SaleCap + PreSaleCap - soldPreSaleTokens 
  function setSoldPreSaleTokens(uint256 _soldPreSaleTokens) onlyOwner{
    require(!icoEnabled);
    require(_soldPreSaleTokens <= preSaleCap);
    soldPreSaleTokens = _soldPreSaleTokens;
  }

  // transfer pre sale tokend to investors
  // soldPreSaleTokens need to be set beforehand, and bigger than 0
  // the total amount to tranfered need to be less or equal to soldPreSaleTokens 
  function transferPreSaleTokens(uint256 tokens, address beneficiary) onlyOwner {
    require(soldPreSaleTokens > 0);
    uint256 newSentPreSaleTokens = sentPreSaleTokens.add(tokens);
    require(newSentPreSaleTokens <= soldPreSaleTokens);
    sentPreSaleTokens = newSentPreSaleTokens;
    token.transfer(beneficiary, tokens);
  }

  // set multisign wallet
  function setMultisignWallet(address _multisignWallet) onlyOwner{
    require(_multisignWallet != address(0));
    multisignWallet = _multisignWallet;
  }

  // set contribution dates
  function setContributionDates(uint256 _startTime, uint256 _endTime) onlyOwner{
    require(!icoEnabled);
    require(_startTime >= now);
    require(_endTime >= _startTime);
    startTime = _startTime;
    endTime = _endTime;
  }

  // enable ICO, need to be true to actually start ico
  // multisign wallet need to be set, because once ico started, invested funds is transfered to this address
  // once ico is enabled, following parameters can not be changed anymore:
  // startTime, endTime, soldPreSaleTokens
  function enableICO() onlyOwner{
    require(startTime >= now);
    require(!icoEnabled);
    require(multisignWallet != address(0));
    icoEnabled = true;
    icoCap = initialICOCap.add(preSaleCap).sub(soldPreSaleTokens);
  }


  // fallback function can be used to buy tokens
  function () payable whenNotPaused {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 returnWeiAmount;

    // calculate token amount to be created
    uint rate = getRate();
    uint256 tokens = weiAmount.mul(rate);

    uint256 newIcoSoldTokens = icoSoldTokens.add(tokens);

    if (newIcoSoldTokens > icoCap) {
        newIcoSoldTokens = icoCap;
        tokens = icoCap - icoSoldTokens;
        uint256 newWeiAmount = tokens.div(rate);
        returnWeiAmount = weiAmount.sub(newWeiAmount);
        weiAmount = newWeiAmount;
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.transfer(beneficiary, tokens);
    icoSoldTokens = newIcoSoldTokens;
    if (returnWeiAmount > 0){
        msg.sender.transfer(returnWeiAmount);
    }

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds(weiAmount);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds(uint256 weiAmount) internal {
    multisignWallet.transfer(weiAmount);
  }
  
  function transferUnsoldIcoTokens() onlyOwner { 
    require(hasEnded());
    require(icoSoldTokens < icoCap);
    uint256 unsoldTokens = icoCap.sub(icoSoldTokens);
    token.transfer(multisignWallet, unsoldTokens);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    bool icoTokensAvailable = icoSoldTokens < icoCap;
    return !icoEnded && icoEnabled && withinPeriod && nonZeroPurchase && icoTokensAvailable;
  }

  // end ico by owner, not really needed in normal situation
  function endIco() onlyOwner {
    require(!icoEnded);
    icoEnded = true;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return (icoEnded || icoSoldTokens >= icoCap || now > endTime);
  }


  function getRate() public constant returns(uint){
    require(now >= startTime);
    if (now < startTime.add(2 days)){
      // day 1, day 2
      return 420;
    }else if (now < startTime.add(4 days)){
      // day 3, day 4
      return 385;
    }else if (now < startTime.add(5 days)){
      // day 5
      return 358; //358.85
    }else if (now < endTime){
      // no discount
      return 350;
    }
  }

  // drain all eth for owner in an emergency situation
  function drain() onlyOwner {
    owner.transfer(this.balance);
  }
}
