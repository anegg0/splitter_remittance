pragma solidity ^0.4.6;

// Holds the users of the remittance service
contract ServiceUsers {
    
    mapping(address => uint) users;

    address private owner;
    
    function ServiceUsers() {
        owner = msg.sender;
    }
    
    function getOwner() constant returns(address) {
        return owner;
    }
     
    function userIsRegistered(address user) constant returns (bool) {
        return users[user] > 0;
    }

    function registerUser(address user, uint userId) returns(uint) {
        
        require(msg.sender == owner);
        
        users[user] = userId;
        
        return users[user];
    }
    
    function generateToken(address user, uint seed) returns (bytes32){
        
        require(userIsRegistered(user));
        
        return sha3(seed, users[user]);
    }
    
    // REMOVE THE METHODS BELOW
    function getUserBalance(address user) constant returns (uint) {
        return user.balance;
    }
    
    function getContractBalance() constant returns(uint) {
        return this.balance;
    }
    
    function getSender() constant returns(address) {
        return msg.sender;
    }
}

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
    
    address private owner;
    
    mapping(address => ServiceUsers) trustedUserBases;
    
    mapping(address => ServiceProvider) trustedServiceProviders;
    
    mapping(bytes32 => FX) fxs;
    
    modifier onlyByOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Exchange(bytes32[] symbols, uint[] commissions, uint[] rates) payable {
        
        require(symbols.length == commissions.length);
        require(symbols.length == rates.length);
        
        owner = msg.sender;
        
        uint numSymbols = symbols.length;
        
        for (uint i = 0 ; i < numSymbols ; i++) {
            fxs[symbols[i]] = FX(commissions[i], rates[i]);
        }
    }
    
    function isUserBaseRegistered(address base) private constant returns(bool) {
        
        return trustedUserBases[base] != ServiceUsers(0x0);   
    }
    
    function isServiceProviderRegistered(address provider) private constant returns(bool) {
        return trustedServiceProviders[provider] != ServiceProvider(0x0);   
    }
    
    function isSymbolRegistered(bytes32 symbol) constant returns(bool) {
        return fxs[symbol].commission != 0;
    }
    
    function isBalanceSufficient(bytes32 symbol, uint value) private constant returns(bool) {
        return fxs[symbol].commission < value;
    }
    
    // Trusted user base for token request
    function registerUserBase(address base) onlyByOwner() {
        
        trustedUserBases[base] = ServiceUsers(base);
    }
    
    // Trusted providers
    function registerServiceProvider(address provider) onlyByOwner() {
        
        trustedServiceProviders[provider] = ServiceProvider(provider);
    }
    
    // Checks that:
    // 1. The Exchange knows the ServiceProvider issuing the request.
    // 2. The Exchange knows the ServiceUsers base the ServiceProvider is referring to.
    // 3. If this Exchange is known by the ServiceProvider and the ServiceProvider is known by this Exchange and,
    //    if only the contract owners can register Exchanges and ServiceProviders, it is possible to say that the
    //    owners of both contracts know each other.
    function authenticateExchange(address userBase, address user, uint seed) constant returns (bytes32) {
        
        require(isServiceProviderRegistered(msg.sender));
        
        require(isUserBaseRegistered(userBase));
        
        return trustedUserBases[userBase].generateToken(user, seed);
    }
 
    // Returns the value paid to the receiver.
    function convertAndTransfer(address base, address user, bytes32 symbol) payable returns (uint) {
        
        require(isServiceProviderRegistered(msg.sender));
        
        require(isUserBaseRegistered(base));
        
        require(isSymbolRegistered(symbol));
        
        isBalanceSufficient(symbol, msg.value);
        
        uint totalValue = msg.value - fxs[symbol].commission;
        
        // the rate would be applied here, however, there should be more going under the
        // hood since a real conversion would be applied
        totalValue = totalValue * fxs[symbol].rate;
        
        user.transfer(totalValue);
        
        return (totalValue);
    }
    
    function getContractBalance() constant returns(uint) {
        
        return this.balance;
    }
    
    function() payable {}
}

/**
 * 
 * This contract implements the actual service provider, which has a customer base and contracts the 
 * exchange services from Exchange.
 *
 */ 
contract ServiceProvider {

    mapping(address => ServiceUsers) customers;

    mapping(address => Exchange) exchanges;

    address private owner;
    
    uint private seed;
    
    function ServiceProvider() payable {
        
        owner = msg.sender;
        seed = 0;
    }
    
    function() payable {}
    
    function registerCustomerBase(address base) {
        customers[base] = ServiceUsers(base);
    }
    
    function registerExchange(address exchange) {
        exchanges[exchange] = Exchange(exchange);
    }
    
    function isExchangeRegistered(address exchange) private constant returns(bool) {
        
        return exchanges[exchange] != Exchange(0x0);
    }
    
    function isCustomerRegistered(address customerBase, address customer) private constant returns(bool) {
        
        ServiceUsers base = customers[customerBase];
        
        return base != ServiceUsers(0x0) && base.userIsRegistered(customer);
    } 

    function areThereFunds(uint amount) private constant returns(bool) {
        return this.balance >= amount;
    }

    // Remits the funds to a specific customer, from a specific customer base, in a specific currency through a specific exchange.
    function remit(address customer, uint value, bytes32 currency, address customerBase, address exchange) returns(uint) {
        
        require(areThereFunds(value));
        
        require(isCustomerRegistered(customerBase, customer));
        
        require(isExchangeRegistered(exchange));
        
        bytes32 tokenFromBase = customers[customerBase].generateToken(customer, seed);
        
        bytes32 tokenFromExchange = exchanges[exchange].authenticateExchange(customerBase, customer, seed);
        
        require(tokenFromBase == tokenFromExchange);
        
        return exchanges[exchange].convertAndTransfer.value(value)(customerBase, customer, currency);
    }
}












