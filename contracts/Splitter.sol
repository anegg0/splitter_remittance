pragma solidity ^0.4.6;

/**
 * Splits values among users according to different rules.
 */ 
contract Splitter {

    // maps users to their balances (used to speed up access)
    mapping(address => uint) usersPositions;
    
    // holds the actual users' balances, each user is represented by a position
    // whose address is found in usersPositions
    uint[]    private usersBalances;
    address[] private usersAddresses;
    
    address private alice;
    address private bob;
    address private carol;
    
    address private owner;
    
    bool    killed = false;
    
    function Splitter(address Alice, address Bob, address Carol) {
        
        alice = Alice;
        bob = Bob;
        carol = Carol;
        
        usersBalances.push(0);
        usersBalances.push(0);
        usersBalances.push(0);
        
        usersAddresses.push(alice);
        usersAddresses.push(bob);
        usersAddresses.push(carol);
        
        usersPositions[alice] = 0;
        usersPositions[bob] = 1;
        usersPositions[carol] = 2;
        
        owner = msg.sender;
    }
    
    modifier valueIsValid() {
        require(msg.value > 0);
        _;
    }
    
    modifier isNotKilled() {
        require(killed == false);
        _;
    }
    
    function getContractBalance() constant returns(uint) {
        return this.balance;
    }
    
    function getAliceBalance() constant returns(uint) {
        return getUserBalance(alice);
    }   
    
    function getBobBalance() constant returns(uint) {
        return getUserBalance(bob);
    }   
    
    function getCarolBalance() constant returns(uint) {
        return getUserBalance(carol);
    }      
    
    // Retrieves the balance for a given user
    function getUserBalance(address userAddress) constant returns(uint) {
        return usersBalances[usersPositions[userAddress]];
    }
    
    // Increases the balance for a given user
    function credit(uint position, uint amount) private {
        
        usersBalances[position] += amount;
    }
    
    // Transfer funds from one account to another
    function credit(address sender, address receiver, uint amount) private {
        
        uint position = usersPositions[receiver];
        
        if (position == 0 && sender != alice) {
            
            usersBalances.push(0);
            usersAddresses.push(receiver);
            
            position = usersBalances.length - 1;
            
            usersPositions[receiver] = position;
        }
        
        credit(position, amount);
    }
    
    // Checks if a user is already registered with the contract. 
    function isRegistered(address user) private constant returns(bool) {
        
        if (usersPositions[user] == 0) {
            
            return user == alice;
        }
        
        return true;
    }
    
    // splits the funds sent by the sender among every registered user
    // credits the remaining to the sender herself
    function splitAmongAllUsers(address sender, uint amount) private {
        
        uint senderPosition = usersPositions[sender];
        
        uint numUsers = usersBalances.length - 1;
        
        // if the amount is smaller than the number of users, the last registered
        // users receive it first, as the older users are more likely to have 
        // better balances        
        if (amount < numUsers) {
            
            uint userIndex = numUsers;
            uint division = amount;
            
            while (division > 0) {
                
                if (userIndex != senderPosition) {
                    credit(userIndex--, 1);
                    division--;
                }
            }
        }
        else {
            
            uint split = amount / numUsers;
            
            // splits the amount evenly among the users, crediting the remaining
            // to the sender
            for ( ; --numUsers >= 0 ; ) {
                if (numUsers != senderPosition) {
                    credit(numUsers, split);
                }
                else {
                    numUsers++;
                }
            }
            
            // if it exists, returns the remaining to the sender
            uint remaining = amount % numUsers;
            if (remaining > 0) {
                credit(senderPosition, remaining);
            }
        }
    }
    
    function getParameters() payable returns(uint,address) {
        return (msg.value, msg.sender);
    }

    // If from Alice, splits between Bob and Carol, if from someone else's, splits
    // among all registered users but the sender, whom will receive the division
    // remaining in case it is not even
    function split() valueIsValid() isNotKilled() payable returns(bool) {
        
        if (msg.sender == alice) {
         
            require(msg.value > 1);
            
            uint splitValue = msg.value / 2;
            uint remaining = msg.value % 2;
            
            credit(alice, bob, splitValue);
            credit(alice, carol, splitValue);
            
            if (remaining > 0) {
                credit(alice, alice, remaining);
            }
        }
        else {
           
           if (!isRegistered(msg.sender)) {
               // registers the current user
               credit(msg.sender, msg.sender, 0);
            }
           
            splitAmongAllUsers(msg.sender, msg.value);
        }
        
        return true;
    }
    
    // Splits the funds among a specific list of users
    function splitAmongReceivers(address[] receivers) valueIsValid() isNotKilled() payable returns(bool) {
        
        address sender = msg.sender;
        
        if (sender == alice) {
            return split();
        }
        
        uint numReceivers = receivers.length;
        
        require(msg.value >= numReceivers);
        
        
        uint splitFunds = msg.value / numReceivers;
        
        for (uint receiver = 0 ; receiver < numReceivers ; receiver++) {
            credit(sender, receivers[receiver], splitFunds);
        }
        
        return true;
    }
    
    // Finishes the contract sending the funds to the proper recipients and blocks
    // further interactions
    function finishContract() isNotKilled() returns(bool) {
        
        require(msg.sender == owner);
        
        killed = true;
        
        uint totalUsers = usersAddresses.length;
        
        for (uint i ; i < totalUsers ; i++) {
            if (usersBalances[i] > 0) {
                usersAddresses[i].transfer(usersBalances[i]);
            }
        }
        
        return true;
    }
}