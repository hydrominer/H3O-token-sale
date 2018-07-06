pragma solidity ^0.4.24;

import './H3O.sol';
import "./ETHUSD.sol";
import '../node_modules/zeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol';
import '../node_modules/zeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol';
import '../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import '../node_modules/zeppelin-solidity/contracts/ReentrancyGuard.sol';

contract H3OCrowdsale is WhitelistedCrowdsale, TimedCrowdsale, ETHUSD, ReentrancyGuard {

  using SafeMath for uint256;

  //The Token beeing sold
  H3O public tokenReward;

  //Amount of Tokens unsold
  uint256 public tokensLeft;

  //Function to check how many tokens are left in the crowdsale
  function getTokensLeft() public view returns (uint256) {
    return tokensLeft;
  }

  // ICO Stage
  // ============
  enum CrowdsaleStage { Stage1, Stage2, Stage3, Stage4 }
  CrowdsaleStage public stage = CrowdsaleStage.Stage1; // By default it's Stage1
  // =============


  // Events
  event EthTransferred(string text);


  // Constructor
  // ============
  function H3OCrowdsale(uint256 _openingTime, uint256 _closingTime, address _wallet, StandardBurnableToken _token, address addressOfTokenUsedAsReward, uint256 _initialEthUsdCentsPrice) TimedCrowdsale(_openingTime, _closingTime) 
    Crowdsale(1, _wallet, _token) public {
      ethInCents = _initialEthUsdCentsPrice;
      tokenReward = H3O(addressOfTokenUsedAsReward);
      tokensLeft = tokenReward.INITIAL_SUPPLY();
    }
  // =============

  // ==================

  // Crowdsale Stage Management
  // =========================================================

  // Change Crowdsale Stage. Available Options: Stage1, Stage2, Stage3, Stage4
  function setCrowdsaleStage(uint value) private {

      CrowdsaleStage _stage;

      if (uint(CrowdsaleStage.Stage1) == value) {
        _stage = CrowdsaleStage.Stage1;
      } else if (uint(CrowdsaleStage.Stage2) == value) {
        _stage = CrowdsaleStage.Stage2;
      } else if (uint(CrowdsaleStage.Stage3) == value) {
        _stage = CrowdsaleStage.Stage3;
      } else if (uint(CrowdsaleStage.Stage4) == value) {
        _stage = CrowdsaleStage.Stage4;
      }

      stage = _stage;

      //Setting the current rate with oraclize and discounts
      //One token is equal to 0,1 dollar
      //The rest oft the equation is just a percentual equation of the Discount-stages
      if (stage == CrowdsaleStage.Stage1) {
        setCurrentRate((ethInCents.mul(120)).div(1000));
      } else if (stage == CrowdsaleStage.Stage2) {
        setCurrentRate((ethInCents.mul(115)).div(1000));
      } else if (stage == CrowdsaleStage.Stage3) {
        setCurrentRate((ethInCents.mul(110)).div(1000));
      } else if (stage == CrowdsaleStage.Stage4) {
        setCurrentRate((ethInCents.mul(105)).div(1000));
      }
  }

  // Change the current rate
  function setCurrentRate(uint256 _rate) private { 
      rate = _rate;
  }

  // ================ Stage Management Over =====================

  // Token Purchase
  // =========================
  function () external payable {
    
      if(now <= 1530375600) {
        setCrowdsaleStage(uint(CrowdsaleStage.Stage1));
      } else if (now > 1530375600 && now <= 1530376200) {
        setCrowdsaleStage(uint(CrowdsaleStage.Stage2));
      } else if (now > 1530376200 && now <= 1530376800) {
        setCrowdsaleStage(uint(CrowdsaleStage.Stage3));
      } else if (now > 1530376800) {
        setCrowdsaleStage(uint(CrowdsaleStage.Stage4));
      }

  // Set Crowdsale Stages depending on time
      buyTokens(msg.sender);
  }

  //Overwritten buyTokens function, which transfers tokens without minting new ones (fixed amount of tokens)
  function buyTokens(address _beneficiary) public payable nonReentrant {
    require(_beneficiary != address(0));

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    // Instead of minting new token transfer from
    // those assigned to the Crowdsale contract
    // token.mint(beneficiary, tokens);
    require(tokenReward.transferFrom(tokenReward.owner(), _beneficiary, tokens));

    tokensLeft = tokensLeft.sub(tokens);

    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _forwardFunds();
  }


  //A function to assign tokens to an address manually. It should be used for payments received in other currencies.
  //@param _amount: has to be in H3O-tokens without decimals, as those will be added in the first line of the function.
  function buyTokensOtherCurrencies(address _beneficiary, uint256 _amount) external onlyOwner nonReentrant {

    //Add tokens decimals
    uint256 tokens = _amount * (10 ** uint256(tokenReward.decimals()));

    _preValidatePurchase(_beneficiary, tokens);

    //transfering tokens from the crowdsale to beneficiary stated
    require(tokenReward.transferFrom(tokenReward.owner(), _beneficiary, tokens));

    //Substrakt Tokens from the remaining tokens.
    tokensLeft = tokensLeft.sub(tokens);

    TokenPurchase(_beneficiary ,_beneficiary, tokens, tokens);
  }

  //After the Crowdsale is over, this function can be called to transfer all unsold Tokens to a wallet
  function endCrowdsale(address _wallet) external onlyOwner nonReentrant {
    require(tokenReward.transferFrom(tokenReward.owner(), _wallet, tokensLeft));

    //Set tokensLeft to 0, signalising the end of the Crowdsale
    tokensLeft = 0;

    TokenPurchase(_wallet, _wallet, tokensLeft, tokensLeft);
  }

}