var Exchange = artifacts.require("Exchange");

function hex2a(hexx) {
    var hex = hexx.toString();//force conversion
    var str = '';
    for (var i = 0; i < hex.length; i += 2) {

      var decCode = parseInt(hex.substr(i, 2), 16);
      if (decCode >= 32 && decCode <= 255) {
        str += String.fromCharCode(decCode);        
      }        
    }
    return str;
}

contract('Exchange', function(accounts) {

  var commission = 2;  

  var exchange;  

  var owner = accounts[0];
  var testAccount1 = accounts[1];
  var testAccount2 = accounts[2];

  beforeEach(function() {

    return Exchange.new(commission)
    .then(function(exInstance) {
      exchange = exInstance;      
    });
  });

  
  it("should update commission", function() {    

    return exchange.updateCommission(commission + 1)
    .then(ret => exchange.commission.call())
    .then(setCommission => assert.equal(setCommission, commission + 1, "commission was not set"));
  });
  

  it("should allow the authorization of users by owner only", function() {

    var weakPass = "pass1";
    var strongPass = "pass2";

    return exchange.authorizeUser(testAccount1, weakPass, strongPass)
    .then(res => exchange.authenticateExchange.call(testAccount1))
    .then(auth => {      

      var retWeak = hex2a(auth[0]).trim();
      var retStrong = hex2a(auth[1]).trim();      

      assert.equal(weakPass, retWeak, "weak passwords are different");
      assert.equal(strongPass, retStrong, "strong passwords are different");
      return exchange.authorizeUser(testAccount2, weakPass, strongPass, {from: testAccount1});
    })
    .catch(err => assert.isTrue((err+"").indexOf("Error: VM Exception while processing transaction: invalid opcode") !== -1, "unauthorized users could authorize other users"));
  });


  it("should refuse transactions if the funds are insufficient", function() {
    
    var invalidFunds = commission - 1;

    return exchange.convertAndTransfer(testAccount2, "BRL", {from: testAccount1, value: invalidFunds})    
    .catch(err => assert.isTrue((err+"").indexOf("Error: VM Exception while processing transaction: invalid opcode") !== -1, "could finish transaction with insufficient funds"));
  });


  it("should perform transactions", function() {
    
    var validFunds = commission + 1;

    return exchange.convertAndTransfer.call(testAccount2, "BRL", {from: testAccount1, value: validFunds})
    .then(ret => assert.equal(validFunds - commission, ret, "did not process comissions properly"))
    .catch(err => console.log("ERRR: "+err));
  });  

  it("contract should retain commissions", function() {

    var validFunds = commission + 1;

    web3.eth.getBalance.call(exchange.address, function(err,res){console.log("CAME1: "+res)});

    return exchange.convertAndTransfer(testAccount2, "BRL", {from: testAccount1, value: validFunds})    
    .then(ret2 => web3.eth.getBalance(exchange.address, function(err,res){console.log("CAME2: "+res)}))
    .catch(err => console.log("ERRR: "+err));
  });   
});
