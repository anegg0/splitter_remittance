var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {

  var contract;  

  var owner = accounts[0];
  var testAccount1 = accounts[1];
  var testAccount2 = accounts[2];

  beforeEach(function() {
    return Splitter.new()
      .then(function(instance) {
        contract = instance;        
      });
  });


  it("should split between receivers", function() {

    var funds = 4;    
    var expectedFunds = funds / 2;

    return contract.getAvailableFunds.call({from: testAccount1})
    .then(fundsAcc1 => {
      assert.equal(0, fundsAcc1, "test account 1 already had available funds");
      return contract.getAvailableFunds.call({from: testAccount2})
    })
    .then(fundsAcc2 => {
      assert.equal(0, fundsAcc2, "test account 2 already had available funds");
      return contract.credit(testAccount1, testAccount2, {from: owner, value: funds})
    })    
    .then(result => contract.getAvailableFunds.call({from: testAccount1}))
    .then(newFundsAcc1 => {
      assert.equal(expectedFunds, newFundsAcc1, "test account 1 did not receive the expected funds");
      return contract.getAvailableFunds.call({from: testAccount2});
    })
    .then(newFundsAcc2 => assert.equal(expectedFunds, newFundsAcc2, "test account 2 did not receive the expected funds"));
  });


  it("should credit remainder back to sender", function() {

    var funds = 5; 
    var ownerExpectedFunds = funds % 2;

    return contract.getAvailableFunds.call({from: owner})
    .then(fundsOwner => {
      assert.equal(0, fundsOwner, "sender already had available funds");
      return contract.credit(testAccount1, testAccount2, {from: owner, value: funds})
    })   
    .then(result => contract.getAvailableFunds.call({from: owner}))
    .then(newFundsOwner => assert.equal(ownerExpectedFunds, newFundsOwner, "sender did not receive the expected funds"));
  });


  it("should allow funds claiming", function() {

    var funds = 5;  
    var expectedFunds = 4;

    return contract.getAvailableFunds.call({from: testAccount1})
    .then(accFunds => {
      assert.equal(0, accFunds, "account already had available funds");
      return contract.credit(testAccount1, testAccount1, {from: owner, value: funds})
    })   
    .then(result => contract.getAvailableFunds.call({from: testAccount1}))
    .then(newFunds => {
      assert.equal(expectedFunds, newFunds.toNumber(), "account did not receive the expected funds");
      return contract.claim({from: testAccount1});
    })
    .then(res => contract.claim.call({from: testAccount1}))
    .then(res2 => assert.isFalse(res2, "account could claim the funds twice"));    

  });


  it("should forbid splits if contract is finished", function() {

    var funds = 4;    
    var expectedFunds = funds / 2;

    return contract.killed.call()
    .then(finished => {
      assert.isFalse(finished, "contract was finished from the beginning");
      //return contract.credit(receivers, {from: owner, value: funds});
    })  
    .then(cr => contract.finishContract({from: owner}))    
    .then(fc => contract.killed.call())
    .then(finishedNow => {
      assert.isTrue(finishedNow, "contract did not finish after command");
      return contract.credit.call(testAccount1,testAccount2, {from: owner, value: funds});
    })
    .catch(err => assert.isTrue((err+"").indexOf("Error: Error: VM Exception while executing eth_call: invalid opcode") !== -1, "contract received split request after killed"));    
  });


  it("should funds claiming after contract is finished", function() {

    var funds = 5;
    var expectedFunds = 4;    

    return contract.getAvailableFunds.call({from: testAccount1})
    .then(accFunds => {
      assert.equal(0, accFunds, "account already had available funds");
      return contract.credit(testAccount1, testAccount1, {from: owner, value: funds})
    })   
    .then(result => contract.finishContract())
    .then(finished => contract.getAvailableFunds.call({from: testAccount1}))
    .then(newFunds => {
      assert.equal(expectedFunds, newFunds, "account did not receive the funds");
      return contract.claim.call({from: testAccount1});
    })
    .then(res => assert.isTrue(res, "account could not claim funds"));
  });
});
