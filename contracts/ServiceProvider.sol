pragma solidity ^0.4.10;

import "./Exchange.sol";

/**
 * 
 * This contract implements the actual service provider, which has a customer base and contracts the 
 * exchange services from Exchange.
 *
 */ 
contract ServiceProvider {

    // the weak password came from an e-mail message
    // the strong password was delivered in person
    struct Authorization {
        bytes32 weakPassword;
        bytes32 strongPassword;
    }

    mapping(address => Authorization) usersPasswords; 

    mapping(address => Exchange) exchanges;

    address private owner;

    function ServiceProvider() {
        
        owner = msg.sender;
    }
    
    function() payable {}
    
    modifier onlyByOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier exchangeIsTrusted(address exchange) {
        require(exchanges[exchange] != Exchange(0x0));
        _;
    }
    
    function authorizeUser(address user, bytes32 weakPassword, bytes32 strongPassword)
    onlyByOwner()
    external
    returns(bool) {
        
        usersPasswords[user] = Authorization(weakPassword, strongPassword);
    }    
    
    function registerExchange(address exchange) 
    onlyByOwner()
    external
    returns(bool)
    {
        exchanges[exchange] = Exchange(exchange);
        return true;
    }

    // Remits the funds to a specific customer, from a specific customer base, in a specific currency through a specific exchange.
    function remit(address customer, bytes32 currency, address exchangeAddress)
    payable 
    onlyByOwner()
    exchangeIsTrusted(exchange)
    external
    returns(uint) {
        
        Exchange exchange = exchanges[exchangeAddress];
        
        var(retrievedWeakPassword, retrievedStrongPassword) = exchange.authenticateExchange(customer);

        Authorization storage localAuthorization = usersPasswords[customer];
        
        require(localAuthorization.weakPassword == retrievedWeakPassword && localAuthorization.strongPassword == retrievedStrongPassword);
        
        return exchanges[exchange].convertAndTransfer.value(msg.value)(customer, currency);
    }
}