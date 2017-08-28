pragma solidity ^0.4.6;

/**
 * Splits values among users according to different rules.
 */ 
contract Splitter {
    
    mapping(address => uint) usersBalances;
    
    address private owner;
    
    bool public killed = false;
    
    function Splitter() {
        
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier valueIsValid() {
        require(msg.value > 0);
        _;
    }
    
    modifier hasEnoughFunds(uint value, uint numUsers) {
        require(value >= numUsers);
        _;
    }

    modifier isNotKilled() {
        require(killed == false);
        _;
    }     
    
    function getContractFunds() 
    constant
    external
    returns(uint)
    {
        return this.balance;
    }

    // Retrieves the funds available for a given user
    function getAvailableFunds() 
    constant 
    returns(uint) 
    {
        return usersBalances[msg.sender];
    }

    // Allows a user to send funds to be split
    // The funds are spread among the receivers, remaining funds
    // are returned to the sender
    function credit(address[] receivers)
    payable
    isNotKilled()
    hasEnoughFunds(msg.value, receivers.length)
    external
    returns(bool) {

        uint numReceivers = receivers.length;

        uint share = msg.value / numReceivers;
        uint remaining = msg.value % numReceivers;

        for (uint i = 0 ; i < numReceivers ; i++) {
            usersBalances[receivers[i]] += share;
        }

        if (remaining > 0) {
            usersBalances[msg.sender] += remaining;
        }
    }

    // Allows a user to claim her funds, if there are any
    function claim()     
    external
    returns(bool)
    {
        uint funds = usersBalances[msg.sender];

        if (funds > 0) {

            // decreases the funds to avoid reentrant attacks
            usersBalances[msg.sender] = 0;
            
            if (!msg.sender.send(funds)) {
                usersBalances[msg.sender] = funds;
                revert();
            }

            return true;
        }

        return false;
    }

    // Finishes the contract so that no more funds can be received and split
    function finishContract() 
    isNotKilled() 
    onlyOwner()
    external
    returns(bool) 
    {        
        killed = true;
        return killed;
    }    
}