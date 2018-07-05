 pragma solidity ^0.4.24;

 contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }
    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }
    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    using SafeMath for uint;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address owner
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[owner] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

}

contract ConstantPriceCrowdsale{
    address public token;
    address public owner;
    uint public price;
    bool public finished = false;
    bool public started = false;
    bool public withdrawn = false;
    uint public raised = 0;
    //uint public minimum = 0;
    uint public initialBalance;

    bool public useWhitelist = false;

    mapping(address => bool) public whitelisted;

    event Started(address starter, uint initialBalance);
    event Finished(address finisher, uint initialBalance, uint availableBalance);
    event Withdrawn(address withdrawer, uint amount);
    event Whitelisted(address user);
    event Deposited(address user, uint deposit, uint gained);

    constructor(address _token, address _owner, uint _price, bool _whitelist) public {
        token = _token;
        owner = _owner;
        price = _price;
        useWhitelist = _whitelist;
    }

    function finish() public {
        assert(started);
        assert(msg.sender == owner);
        finished = true;

        emit Finished(msg.sender, initialBalance, currentBalance());
    }

    function start() public {
        assert(!started && !finished);
        assert(msg.sender == owner);
        started = true;

        initialBalance =  ERC20(token).balanceOf(this);

        emit Started(msg.sender, initialBalance);
    }

    function() public payable {
        assert(started);
        assert(!finished);

        if(useWhitelist && !whitelisted[msg.sender]) revert("not whitelisted");

        ERC20 tok = ERC20(token);
        uint remaining = tok.balanceOf(this);

        uint decimals = uint(tok.decimals());
        uint amount = (msg.value / price) * 10 ** decimals;

        assert(amount <= remaining);

        tok.transfer(msg.sender, amount);

        emit Deposited(msg.sender, msg.value, amount);
    }

    function withdraw() public {
        assert(msg.sender == owner);
        assert(finished);

        uint bal = address(this).balance;
        msg.sender.transfer(bal);

        withdrawn = true;
        raised = bal;

        emit Withdrawn(msg.sender, bal);
    }

    function whitelist(address user) public {
        assert(msg.sender == owner);

        whitelisted[user] = true;

        emit Whitelisted(user);
    }

    function currentBalance() public view returns(uint) {
        return ERC20(token).balanceOf(this);
    }

    function startingBalance() public view returns(uint) {
        if(started){
            return initialBalance;
        }else{
            return ERC20(token).balanceOf(this);
        }
    }

    function getAmountRaised() public view returns(uint){
        if(withdrawn){
            return raised;
        }else{
            return address(this).balance;
        }
    }

}

contract Crowdsale {
    address public token;
    address public owner;
    uint public price;
    bool public finished;
    bool public started;
    bool public withdrawn;
    uint public raised;
    uint public initialBalance;

    bool public useWhitelist;

    mapping(address => bool) public whitelisted;

    event Started(address starter, uint initialBalance);
    event Finished(address finisher, uint initialBalance, uint availableBalance);
    event Withdrawn(address withdrawer, uint amount);
    event Whitelisted(address user);
    event Deposited(address user, uint deposit, uint gained);

    function finish() public;
    function start() public;
    function() public payable;
    function withdraw() public;
    function whitelist(address user) public;
    function currentBalance() public view returns(uint);
    function startingBalance() public view returns(uint);
    function getAmountRaised() public view returns(uint);
}

contract TokenLauncher {
    using SafeMath for uint;

    address owner;
    constructor() public {
        owner = msg.sender;
    }

    address[] public tokens;
    address[] public crowdsales;

    // token => (user => balance)
    mapping(address => mapping(address => uint) ) balances;

    /*mapping(address => address) public tokenOwners;
    mapping(address => address) public crowdsaleOwners;
    mapping(address => address[]) public ownersTokens;
    mapping(address => address[]) public ownersCrowdsales;*/

    event TokenLaunched(address owner, address token, uint initialSupply, string symbol, string name,  address crowdsale, uint quantityForSale);
    //event CrowdsaleLaunched(address owner, address token, address crowdsale, string symbol, string name, uint quantityForSale);

    function launch(address _token, uint _initialSupply, string _name, string _symbol, uint _price, uint _saleType, bool _whitelist, uint _quantityForSale) public returns (address, address) { //uint[10] _intArgs, address[10] _addressArgs

        address token = _token==address(0) ? _launchToken(_initialSupply, _name, _symbol) : _token;
        address crowdsale = _saleType!=0 ? _launchSale(token, _quantityForSale, _price, _saleType, _whitelist) : address(0);

        emit TokenLaunched(tx.origin, token, _initialSupply, _symbol, _name, crowdsale, _quantityForSale);

        return (token, crowdsale);
    }

    /*function launchToken(uint _initialSupply, string _name, string _symbol) public returns (address){
        address token = _launchToken(_initialSupply, _name, _symbol);

        balances[token][tx.origin] = _initialSupply;

        emit TokenLaunched(tx.origin, token, _initialSupply, _symbol, _name, address(0), 0);
        return token;
    }

    function launchCrowdsale(address _token, uint _quantity, uint _price, uint _saleType, bool _whitelist) public returns (address) {
        if(balances[_token][tx.origin] < _quantity) revert("not enough balance");
        balances[_token][tx.origin] = balances[_token][tx.origin].sub(_quantity);

        address crowdsale = _launchSale(_token, _quantity, _price, _saleType, _whitelist);
        ERC20 tok = ERC20(_token);

        emit CrowdsaleLaunched(tx.origin, _token, crowdsale, tok.symbol(), tok.name(), _quantity);
        return crowdsale;
    }*/

    function _launchToken(uint _initialSupply, string _name, string _symbol) internal returns(address) {

        address token =  new TokenERC20(_initialSupply, _name, _symbol, this);

        /*tokens.push(token);
        tokenOwners[token] = tx.origin;
        ownersTokens[tx.origin].push(token);*/

        return token;
    }

    function _launchSale(address _token, uint _quantity, uint _price, uint saleType, bool _whitelist) internal returns (address) {
        address crowdsale = new ConstantPriceCrowdsale(_token, tx.origin, _price, _whitelist);

        tokens.push(_token);
        crowdsales.push(crowdsale);

        ERC20 tok = ERC20(_token);
        uint decimals = uint(tok.decimals());
        uint amount = _quantity * 10 ** decimals;

        tok.transfer(crowdsale, amount);

        /*crowdsales.push(crowdsale);
        crowdsaleOwners[crowdsale] = tx.origin;
        ownersCrowdsales[tx.origin].push(crowdsale);*/

        return crowdsale;
    }

    /*function listTokens() public view returns (address[]) {
        return ownersTokens[msg.sender];
    }

    function listTokensForAddress(address _owner) public view returns (address[]) {
        return ownersTokens[_owner];
    }

    function listCrowdsales() public view returns (address[]) {
        return ownersCrowdsales[msg.sender];
    }

    function listCrowdsalesForAddress(address _owner) public view returns (address[]) {
        return ownersCrowdsales[_owner];
    }*/
}

contract TokenLauncherInterface {
    function launch(address _token, uint _initialSupply, string _name, string _symbol, uint _price, uint _saleType, bool _whitelist, uint _quantityForSale) public returns (address, address);
    //function launchToken(uint _initialSupply, string _name, string _symbol) public returns (address);
    //function launchCrowdsale(address _token, uint _quantity, uint _price, uint _saleType, bool _whitelist) public returns (address);

    /*function listTokens() public view returns (address[]);
    function listTokensForAddress(address _owner) public view returns (address[]);
    function listCrowdsales() public view returns (address[]) ;
    function listCrowdsalesForAddress(address _owner) public view returns (address[]);*/
}

contract KYCRegistry {
    address public owner;

    mapping(address => string) public registry;

    event Registered(address user, string hash);

    constructor(address _owner) public {
        owner = _owner;
    }

    function register(address _user, string _hash) public {
        require(msg.sender == owner);

        registry[_user] = _hash;

        emit Registered(_user, _hash);
    }
}

contract LaunchToken {

    TokenLauncherInterface public tokenLauncher;

    address public owner;

    address[] public tokens;
    address[] public crowdsales;

    mapping(address => address) public tokenOwners;
    mapping(address => address[]) public ownersTokens;

    mapping(address => address) public crowdsaleOwners;
    mapping(address => address[]) public ownersCrowdsales;
    mapping(address => address[]) public tokensCrowdsales;
    mapping(address => address[2][]) public ownersTokenCrowdsaales;

    event TokenLaunched(address owner, address token, string symbol, string name, address crowdsale);
    //event CrowdsaleLaunched(address owner, address token, address crowdsale, string symbol, string name, uint quantityForSale);

    modifier onlyOwner { require(msg.sender == owner); _; }

    constructor() public {
        owner = msg.sender;
        address launcher = new TokenLauncher();
        tokenLauncher = TokenLauncherInterface(launcher);
    }

    function launch(address _token, uint _initialSupply, string _name, string _symbol, uint _price, uint _saleType, bool _whitelist, uint _quantityForSale) public {
        (address token, address crowdsale) = tokenLauncher.launch(_token, _initialSupply, _name, _symbol, _price, _saleType, _whitelist, _quantityForSale);

        _registerToken(token);
        if(crowdsale != address(0)) _registerCrowdsale(crowdsale, token);

        emit TokenLaunched(msg.sender, token, _symbol, _name, crowdsale);
    }

    /*function launchToken(uint _initialSupply, string _name, string _symbol) public {
        address token = tokenLauncher.launchToken(_initialSupply, _name, _symbol);
        _registerToken(token);
        emit TokenLaunched(msg.sender, token, _symbol, _name, address(0));
    }*/


    /*function launchCrowdsale(address _token, uint _quantity, uint _price, uint _saleType, bool _whitelist) public {
        address crowdsale = tokenLauncher.launchCrowdsale(_token, _quantity, _price, _saleType, _whitelist);
        _registerCrowdsale(crowdsale, _token);
        ERC20 tok = ERC20(_token);
        emit CrowdsaleLaunched(msg.sender, _token, crowdsale, tok.symbol(), tok.name(), _quantity);
    }*/

    function _registerCrowdsale(address crowdsale, address token) internal {
        crowdsaleOwners[crowdsale] = msg.sender;
        ownersCrowdsales[msg.sender].push(crowdsale);
        tokensCrowdsales[token].push(crowdsale);
        ownersTokenCrowdsaales[msg.sender].push([token, crowdsale]);
        crowdsales.push(crowdsale);
    }

    function _registerToken(address token) internal {
        tokenOwners[token] = msg.sender;
        ownersTokens[msg.sender].push(token);
        tokens.push(token);
    }

    //upgrade
    event LauncherUpgraded(address upgrader, address oldLauncher, address newLauncher);

    function upgradeLauncher(address _launcher) onlyOwner public {
        emit LauncherUpgraded(msg.sender, tokenLauncher, _launcher);
        tokenLauncher = TokenLauncherInterface(_launcher);
    }

    //track tokens

    function listTokens(address _owner) public view returns (address[]) {
        return ownersTokens[_owner];
    }
    function listCrowdsales(address _owner) public view returns (address[]) {
        return ownersCrowdsales[_owner];
    }
    function listTokensCrowdsales(address _token) public view returns (address[]) {
        return tokensCrowdsales[_token];
    }
    function listOwnersTokenCrowdsales(address _owner) public view returns (address[2][]){
        return ownersTokenCrowdsaales[_owner];
    }


    /*function getTokenLauncher() public view returns(address){
        return tokenLauncher;
    }*/
}
