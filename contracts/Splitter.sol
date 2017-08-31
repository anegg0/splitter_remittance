pragma solidity ^0.4.6;

/**
 * Splits values among users according to different rules.
 */ 
contract Splitter {
    
	LogContractFinished(uint indexed blockNumber);

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

    // Retrieves the funds available for a given user
    function getAvailableFunds() 
    constant 
    returns(uint) 
    {
        return usersBalances[msg.sender];
    }

    // Splits funds between two receivers
    function credit(address receiver1, address receiver2)
    payable
    isNotKilled()
    hasEnoughFunds(msg.value, 2)
    external
    returns(bool) 
    {        
        uint share = msg.value / 2;
        uint remaining = msg.value % 2;

        usersBalances[receiver1] += share;
        usersBalances[receiver2] += share;

        if (remaining > 0) {
            usersBalances[msg.sender] += remaining;
        }

        return true;
    }

    // Allows a user to claim her funds, if there are any
    function claim()     
    external
    returns(bool)
    {
        uint funds = usersBalances[msg.sender];

        require(funds > 0);

		usersBalances[msg.sender] = 0;	
		msg.sender.transfer(funds);

		return true;
    }

    // Finishes the contract so that no more funds can be received and split
    function finishContract() 
    isNotKilled() 
    onlyOwner()
    external
    returns(bool) 
    {        
        killed = true;

        LogContractFinished(block.number);

        return killed;
    }    
}