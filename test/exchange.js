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

  var currencies = new Array("USD","GBP","BRL","EUR");
  var commissions = new Array(1, 1, 1, 4);
  var rates = new Array(2, 3, 4, 5);    

  var exchange;  

  var owner = accounts[0];
  var testAccount1 = accounts[1];
  var testAccount2 = accounts[2];

  beforeEach(function() {

    return Exchange.new()
    .then(function(exInstance) {
      exchange = exInstance;      
    });
  });

  
  it("should receive symbols, commissions and rates", function() {

    var index = 1;

    return exchange.addSymbols(currencies, commissions, rates)
    .then(ret => exchange.getSymbolRate.call(currencies[index]))
    .then(rate => assert.equal(rates[index], rate, "incorrect rate was returned"));    
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

    exchange.addSymbols(currencies, commissions, rates)
    .catch(err => console.log("Could not add symbols: "+err));

    index = currencies.length - 1;    
    var invalidFunds = commissions[index] - 1;

    return exchange.convertAndTransfer(testAccount2,currencies[index],{from: testAccount1, value: invalidFunds})    
    .catch(err => assert.isTrue((err+"").indexOf("Error: VM Exception while processing transaction: invalid opcode") !== -1, "could finish transaction with insufficient funds"));
  });


  it("should refuse transactions with unknown currencies", function() {

    return exchange.convertAndTransfer(testAccount2, "INX",{from: testAccount1, value: 10})    
    .catch(err => assert.isTrue((err+"").indexOf("Error: VM Exception while processing transaction: invalid opcode") !== -1, "could process transaction with unknown funds"));

  });


  it("should perform transactions", function() {

    exchange.addSymbols(currencies, commissions, rates)
    .catch(err => console.log("Could not add symbols: "+err));

    index = currencies.length - 1;    
    var validFunds = commissions[index] + 1;

    return exchange.convertAndTransfer.call(testAccount2,currencies[index],{from: testAccount1, value: validFunds})
    .then(ret => assert.equal(validFunds - commissions[index], ret, "did not process comissions properly"))
    .catch(err => console.log("ERRR: "+err));
  });  
});
