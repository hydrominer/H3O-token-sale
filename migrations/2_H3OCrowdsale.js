var H3OCrowdsale = artifacts.require("./H3OCrowdsale.sol");
var ETHUSD = artifacts.require("./ETHUSD.sol");
var H3O = artifacts.require("./H3O.sol");

module.exports = function(deployer) {
  const openingTime = Math.round((new Date(Date.now() - 86400000).getTime())/1000); // Yesterday
  const closingTime = Math.round((new Date().getTime() + (86400000 * 20))/1000); // Today + 20 days

  return deployer
    .then(() => {
      return deployer.deploy(H3O);
    })
    .then(() => {
      return deployer.deploy(ETHUSD);
    })
    .then(() => {
      return deployer.deploy(
          H3OCrowdsale, 
          openingTime, 
          closingTime, 
          "0xDbDE2F5106527eb42d434De38c84E04AAe4c3880", // Replace this wallet address with the last one (10th account) from Ganache UI. This will be treated as the beneficiary address.
          H3O.address,
          H3O.address,
          3000
        );
    });
};