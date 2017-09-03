pragma solidity ^0.4.11;

import './token/PausableToken.sol';

contract SLMToken is PausableToken {
  string public name = "SLM";
  string public symbol = "SLM";
  uint256 public decimals = 18;
  uint256 INITIAL_SUPPLY = 100000000 * (10**18);

  // Set untransferable by default to the token
  bool public paused = true;
  function SLMToken() {
    // asign all tokens to the contract creator
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}
