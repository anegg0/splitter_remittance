var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {

  var contract;

  var alice = accounts[0];
  var bob   = accounts[1];
  var carol = accounts[2];

  beforeEach(function() {
    return Splitter.new(alice, bob, carol)
      .then(function(instance) {
        contract = instance;
      });
  });

  it("should start with no balance", function() {

    return Splitter.deployed().then(function(instance) {
      return instance.getContractBalance.call();
    }).then(function(balance) {
      assert.equal(balance.valueOf(), 0, "contract was not empty in its instantiation");
    });
  });

  it("should split evenly between Bob and Carol and send remaining to contract when transfered from Alice", function() {

    var aliceTransfer = 2;
    var expectedBobFunds = aliceTransfer / 2;
    var expectedCarolFunds = aliceTransfer / 2;
    var expectedContractFunds = aliceTransfer % 2;

    return Splitter.deployed()
    .then(function(instance) {      
      return instance.split({from: alice, value: 1});
    })
    .then(function(result) {
      console.log(result);
      assert.isTrue(result, "Alice transfered value was not processed");
      return web3.eth.getBalance(bob);
    })
    .then(function(bobFunds) {
      assert.strictEqual(bobFunds, expectedBobFunds, "Incorrect Bob resulting funds after Alice transaction");
      return web3.eth.getBalance(carol);
    })
    .then(function(carolFunds) {
      assert.strictEqual(carolFunds, expectedCarolFunds, "Incorrect Carol resulting funds after Alice transaction");
      return instance.getContractBalance.call();
    })
    .then(function(contractFunds) {
      assert.strictEqual(contractFunds, expectedContractFunds, "Incorrect remaining contract funds after Alice transaction");
    })
  })
});
