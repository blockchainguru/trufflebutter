pragma solidity ^0.4.11;

import './token/PausableToken.sol';

contract SLMToken is PausableToken {
  string public name = "SLM";
  string public symbol = "SLM";
  uint256 public decimals = 18;

  // Set untransferable by default to the token
  bool public paused = false;
}
