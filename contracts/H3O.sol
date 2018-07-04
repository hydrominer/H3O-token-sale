pragma solidity ^0.4.24;


import "../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract H3O is StandardBurnableToken, Ownable {

  string public constant name = "H3O Token"; // solium-disable-line uppercase
  string public constant symbol = "H3O"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }

    /**
   * Associates this token with a current crowdsale, giving the crowdsale
   * an allowance of tokens from the crowdsale supply. This gives the
   * crowdsale the ability to call transferFrom to transfer tokens to
   * whomever has purchased them.
   *
   * @param _crowdSaleAddr The address of a crowdsale contract that will sell this token
   */
  function setCrowdsale(address _crowdSaleAddr) external onlyOwner {
      require(approve(_crowdSaleAddr, INITIAL_SUPPLY));
  }

}