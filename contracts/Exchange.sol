pragma solidity ^0.4.10;

/**
 * 
 * This contract implements the Exchange shop, which converts the rates
 * and remits the funds to the intended receiver.
 * 
 */ 
contract Exchange {
    
    struct FX {
        uint commission;
        uint rate;
    }
    
    // the weak password came from an e-mail message
    // the strong password was delivered in person
    // both passwords are expected to BE ENCODED by the sender
    struct Authorization {
        bytes32 weakPassword;
        bytes32 strongPassword;
    }
    
    address private owner;
    
    mapping(address => Authorization) usersPasswords;    
    
    mapping(bytes32 => FX) fxs;
    
    modifier onlyByOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Exchange() {        
        owner = msg.sender;
    }

    modifier dealsWithSymbol(bytes32 symbol) {
        require(fxs[symbol].commission != 0);
        _;
    }

    modifier sentEnoughBalance(bytes32 symbol, uint value) {
        require(fxs[symbol].commission < value);
        _;
    }

    function addSymbols(bytes32[] symbols, uint[] commissions, uint[] rates)
    onlyByOwner()
    external
    returns(bool) 
    {
        require(symbols.length == commissions.length);
        require(symbols.length == rates.length);
                
        uint numSymbols = symbols.length;

        for (uint i = 0 ; i < numSymbols ; i++) {
            fxs[symbols[i]] = FX(commissions[i], rates[i]);
        }

        return true;
    }

    function getSymbolRate(bytes32 symbol)
    constant
    external
    returns(uint)
    {
        return fxs[symbol].rate;
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
    function convertAndTransfer(address user, bytes32 symbol) 
    payable 
    dealsWithSymbol(symbol)
    sentEnoughBalance(symbol, msg.value)
    external    
    returns (uint) 
    {
        uint totalValue = msg.value - fxs[symbol].commission;
        
        // the rate would be applied here, however, there should be more going under the
        // hood since a real conversion would be applied
        //totalValue = totalValue * fxs[symbol].rate;
        
        user.transfer(totalValue);
        
        return (totalValue);
    }
}