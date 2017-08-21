var Splitter =   artifacts.require("./Splitter.sol");
var ServiceUsers = artifacts.require("ServiceUsers");
var ServiceProvider = artifacts.require("ServiceProvider");
var Exchange = artifacts.require("Exchange");

module.exports = function(deployer) {
  deployer.deploy(Splitter);
  deployer.deploy(ServiceUsers);
  deployer.deploy(ServiceProvider);
  deployer.deploy(Exchange);
};
