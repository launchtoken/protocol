 pragma solidity ^0.4.21;
 
 contract ERC20 {
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
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
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
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
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
    address token;
    address owner;
    uint price;
    bool finished = false;
    
    constructor(address _token, address _owner, uint _price) public {
        token = _token;
        owner = _owner;
        price = _price;
    }
    
    bool started = false;
    
    function finish() public {
        assert(started);
        finished = true;
    }
    
    function() public payable {
        assert(started);
        assert(!finished);
        
        ERC20 tok = ERC20(token);
        uint remaining = tok.balanceOf(this);
        
        uint amount = msg.value / price;
        
        assert(amount < remaining);
        
        tok.transfer(msg.sender, amount);
    }
    
    function withdraw() public {
        assert(msg.sender == owner);
        assert(finished);
        
        msg.sender.transfer(this.balance);
    }
    
}

contract TokenLauncher {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
    
    mapping(address => address) tokenOwners;
    mapping(address => address) crowdsaleOwners;
    mapping(address => address[]) ownersTokens;
    mapping(address => address[]) ownersCrowdsales;
    
    function launch( uint _initialSupply, string _name, string _symbol, uint _price, uint saleType, uint[10] _intArgs, address[10] _addressArgs) public {
        
        address token =  new TokenERC20(_initialSupply, _name, _symbol);        
        address crowdsale = new ConstantPriceCrowdsale(token, msg.sender, _price);
        
        ERC20 tok = ERC20(token);
        
        tok.transfer(crowdsale, _initialSupply);
                
        tokenOwners[token] = msg.sender;
        crowdsaleOwners[crowdsale] = msg.sender;
        ownersTokens[msg.sender].push(token);
        ownersCrowdsales[msg.sender].push(crowdsale);
    }
    
    function listTokens() public view returns (address[]) {
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
    }
}

contract TokenLauncherInterface {
    function launch(uint _initialSupply, string _name, string _symbol, uint _price, uint saleType,  uint[10] _intArgs, address[10] _addressArgs) public;
    function listTokens() public view returns (address[]);
    function listTokensForAddress(address _owner) public view returns (address[]);
    function listCrowdsales() public view returns (address[]) ;
    function listCrowdsalesForAddress(address _owner) public view returns (address[]);
}

contract LaunchToken {
    
    TokenLauncherInterface tokenLauncher;
    
    address owner;
    
    modifier onlyOwner { require(msg.sender == owner); _; }
    
    constructor(address _launcher) public {
        owner = msg.sender;
        tokenLauncher = TokenLauncherInterface(_launcher);
    }
    
    function launch(uint _initialSupply, string _name, string _symbol, uint _price, uint saleType,  uint[10] _intArgs, address[10] _addressArgs) public {
        tokenLauncher.launch( _initialSupply, _name, _symbol, _price, saleType, _intArgs, _addressArgs);
    }
    
    function upgradeLauncher(address _launcher) onlyOwner public {
        tokenLauncher = TokenLauncherInterface(_launcher);
    }
    
}

