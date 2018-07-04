pragma solidity ^0.4.24;

import './H3O.sol';
import '../node_modules/zeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol';
import '../node_modules/zeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol';
import '../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import "./ETHUSD.sol";

contract H3OCrowdsale is WhitelistedCrowdsale, TimedCrowdsale, ETHUSD {

  using SafeMath for uint256;

  //The Token beeing sold
  H3O public tokenReward;

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
      if (stage == CrowdsaleStage.Stage1) {
        setCurrentRate(((ethInCents.div(10)).mul(120)).div(100));//ETHUSD divided 0,7 USD 
      } else if (stage == CrowdsaleStage.Stage2) {
        setCurrentRate(((ethInCents.div(10)).mul(115)).div(100));//ETHUSD divided
      } else if (stage == CrowdsaleStage.Stage3) {
        setCurrentRate(((ethInCents.div(10)).mul(110)).div(100));//ETHUSD divided
      } else if (stage == CrowdsaleStage.Stage4) {
        setCurrentRate(((ethInCents.div(10)).mul(105)).div(100));//ETHUSD divided
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

  function buyTokens(address _beneficiary) public payable {
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
    require(tokenReward.transfer(tokenReward.owner(), _beneficiary, tokens));

    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _forwardFunds();
  }


  // REMOVE THIS FUNCTION ONCE YOU ARE READY FOR PRODUCTION
  function hasEnded() public view returns (uint256) {
    return ((ethInCents.div(10)).mul(120)).div(100);
  }
}