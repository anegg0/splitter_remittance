pragma solidity ^0.4.10;

/**
 * 
 * This contract implements the Exchange shop, which converts the rates
 * and remits the funds to the intended receiver.
 * 
 */ 
contract Exchange {
    
    event Transfer(address indexed sender, address indexed receiver, uint indexed amount, bytes32 currency);

    // the weak password came from an e-mail message
    // the strong password was delivered in person
    // both passwords are expected to BE ENCODED by the sender
    struct Authorization {
        bytes32 weakPassword;
        bytes32 strongPassword;
    }    
    
    mapping(address => Authorization) usersPasswords;        

    address private owner;
    uint    public  commission;

    function Exchange(uint _commission) {        
        owner = msg.sender;
        commission = _commission;
    }

    modifier onlyByOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier sentEnoughBalance(uint value) {
        require(commission < value);
        _;
    }

    modifier hasEnoughFunds(uint value) {
        require(this.balance <= value);
        _;
    }

    function updateCommission(uint newCommission)
    external
    returns(bool)
    {
        commission = newCommission;
        return true;
    }

    function authorizeUser(address user, bytes32 weakPassword, bytes32 strongPassword)
    onlyByOwner()
    external
    returns(bool) {
        
        usersPasswords[user] = Authorization(weakPassword, strongPassword);
        return true;
    }

    function authenticateExchange(address user) 
    external
    constant 
    returns (bytes32 weakPassword, bytes32 strongPassword) 
    {
        Authorization storage auth = usersPasswords[user];
        
        weakPassword = auth.weakPassword;
        strongPassword = auth.strongPassword;
    }
    
    // Returns the value paid to the receiver.
    function convertAndTransfer(address user, bytes32 currency) 
    payable 
    sentEnoughBalance(msg.value)
    external    
    returns (uint) 
    {
        uint totalValue = msg.value - commission;
                    
        Transfer(msg.sender, user, totalValue, currency);

        return (totalValue);
    }

    function withdraw()
    onlyByOwner()
    hasEnoughFunds(msg.value)
    external
    returns(bool)
    {
        owner.transfer(msg.value);
        return true;
    }
}