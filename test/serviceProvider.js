var Exchange = artifacts.require("Exchange");
var ServiceProvider = artifacts.require("ServiceProvider");


contract('ServiceProvider', function(accounts) {

	var provider;
	var exchange;

  var owner = accounts[0];
  var testAccount1 = accounts[1];
  var testAccount2 = accounts[2];

  var weakPass = "pass1";
  var strongPass = "pass2";

  var currencies = new Array("USD","GBP","BRL","EUR");
  var commissions = new Array(1, 1, 1, 4);
  var rates = new Array(2, 3, 4, 5);    

	beforeEach(function() {		

      return ServiceProvider.new()
      .then(function(instance) {
        provider = instance;
      });
  });


  it("should forbid exchange registration if now by owner", function() {

    return Exchange.new()
    .then(ex => {
      exchange = ex;
      return provider.registerExchange(exchange.address, {from: testAccount1});      
    })   
    .catch(err => assert.isTrue((err+"").indexOf("Error: VM Exception while processing transaction: invalid opcode") !== -1, "user that is not the owner could register an exchange"));

  });

  it("should forbid user registration if not by owner", function() {

    provider.authorizeUser(testAccount2, {from: testAccount1})
    .catch(err => assert.isTrue((err+"").indexOf("Error: VM Exception while processing transaction: invalid opcode") !== -1, "user that is not the owner could register another user"));
  });


  it("should forbid remittance if not by owner", function() {    

    var index = 0;
    var funds = commissions[index] + 1;

    return Exchange.new()
    .then(ex => {
      exchange = ex;      
      return provider.registerExchange(exchange.address);      
    }) 
    .then(res1 => exchange.addSymbols(currencies, commissions, rates))
    .then(res2 => exchange.authorizeUser(testAccount1, weakPass, strongPass))
    .then(res3 => provider.authorizeUser(testAccount1, weakPass, strongPass))
    .then(res4 => provider.remit(testAccount1, currencies[index], exchange.address, {from: testAccount2, value: funds}))
    .catch(err => assert.isTrue((err+"").indexOf("Error: VM Exception while processing transaction: invalid opcode") !== -1, "user that is not the owner could remit funds"));    
  });


  it("should forbid remittance if unknwon currency", function() {

    var index = 0;
    var funds = commissions[index] + 1;

    return Exchange.new()
    .then(ex => {
      exchange = ex;      
      return provider.registerExchange(exchange.address);      
    }) 
    .then(res => exchange.addSymbols(currencies, commissions, rates))
    .then(res2 => exchange.authorizeUser(testAccount1, weakPass, strongPass))
    .then(res3 => provider.authorizeUser(testAccount1, weakPass, strongPass))
    .then(res4 => provider.remit(testAccount1, "UNK", exchange.address, {value: funds}))
    .catch(err => assert.isTrue((err+"").indexOf("Error: VM Exception while processing transaction: invalid opcode") !== -1, "transaction performed with unknown currency")); 
  });


  it("should forbid remittance if passwords to not match", function(){

    var index = 0;
    var funds = commissions[index] + 1;

    return Exchange.new()
    .then(ex => {
      exchange = ex;      
      return provider.registerExchange(exchange.address);      
    }) 
    .then(res => exchange.addSymbols(currencies, commissions, rates))
    .then(res2 => exchange.authorizeUser(testAccount1, weakPass, strongPass))
    .then(res3 => provider.authorizeUser(testAccount1, weakPass+"1", strongPass+"1"))
    .then(res4 => provider.remit(testAccount1, currencies[index], exchange.address, {value: funds}))    
    .catch(err => assert.isTrue((err+"").indexOf("Error: VM Exception while processing transaction: invalid opcode") !== -1, "transaction accomplished with non matching passwords")); 
  }); 


  it("should allow remittance by owner", function() {

    var index = 0;
    var funds = commissions[index] + 1;

    return Exchange.new()
    .then(ex => {
      exchange = ex;      
      return provider.registerExchange(exchange.address);      
    }) 
    .then(res => exchange.addSymbols(currencies, commissions, rates))
    .then(res2 => exchange.authorizeUser(testAccount1, weakPass, strongPass))
    .then(res3 => provider.authorizeUser(testAccount1, weakPass, strongPass))
    .then(res4 => provider.remit(testAccount1, currencies[index], exchange.address, {value: funds}))        
    .then(sent => assert.isTrue(JSON.stringify(sent).indexOf("transactionHash") !== -1, "intentional"));    
  });    
});