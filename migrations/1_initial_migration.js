var Splitter                       = artifacts.require("./Splitter.sol");
var ServiceProvider                = artifacts.require("./ServiceProvider.sol");
var Exchange                       = artifacts.require("Exchange");

module.exports = function(deployer) {
  deployer.deploy(Splitter);
 
  deployer.deploy(Exchange);
	  
  deployer.link(Exchange, ServiceProvider);  
  deployer.deploy(ServiceProvider);  
};
