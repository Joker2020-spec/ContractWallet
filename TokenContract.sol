pragma solidity ^0.5.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private decimals;
    
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "The address calling the function is the owners address");
        _;
    }
    
    constructor () public {
        owner = msg.sender;
        decimals = 9;
        _totalSupply = 1000000 * (10 ** decimals);
        _balances[owner] = _balances[owner].add(_totalSupply);
    }

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract TimeLockTokens is ERC20 {
    
    bool walletsLocked;
    
    address[] public auth_keys;
    Locked[] times_locked;

    mapping (address => AuthKey) public authorized_keys;
    
    struct AuthKey {
        address payable key;
        uint deposits;
        uint withdraws;
        bool restricted;
    }
    
    struct Locked {
        address[] isLocked;
    }
    
    
    event AuthKeyAddded(address indexed auth_key);
    event DepositMade(address indexed key, address indexed recipient, uint amount, uint indexed time);
    event WithdrawlMade(address indexed _from, address indexed recipient, uint amount, uint indexed time);
    
    modifier isAuthorized() {
        require(authorized_keys[msg.sender].restricted = false);
        _;
    }
    
    modifier checkLock() {
        uint _lockCheck = getLocks();
        for (uint i = 0; i < times_locked.length; i++) {
            if(times_locked.length == _lockCheck) {
            revert("Unable to withdraw with this address untill lock is unlocked");
            }
        }
        _;
    }
    
    constructor () public {
        addAuthroizedKey(msg.sender);
    }
    
    function addAuthroizedKey(address payable auth_key) public {
        for (uint i = 0; i < auth_keys.length; i++) {
                if(auth_keys[i] == auth_key) {
                revert('Key already stored in array');
            }
        }
        authorized_keys[auth_key] = AuthKey({key: auth_key, deposits: 0, withdraws: 0, restricted: false});
        auth_keys.push(auth_key);
        emit AuthKeyAddded(auth_key);
    }
    
    function removeAuthKey(address bad_key) public returns (uint index) {
        for (uint i = 0; i < auth_keys.length; i++) {
            if (auth_keys[i] == bad_key) {
                delete(auth_keys[i]);
                auth_keys.length--;
                authorized_keys[bad_key].restricted = true;
            }
        }
        return auth_keys.length;
    }
    
    function deposit(address recipient, uint amount) public returns (bool success) {
        if (authorized_keys[msg.sender].restricted == false) {
            _transfer(msg.sender, recipient, amount);
                authorized_keys[msg.sender].deposits++;
        }    
        emit DepositMade(msg.sender, recipient, amount, block.timestamp);
        return success;
    }
    
    function withdraw(address recipient, uint amount) public checkLock() returns (bool success) {
        require(authorized_keys[msg.sender].deposits >= 0);
        // require(authorized_keys[msg.sender].restricted = false);
        _transfer(msg.sender, recipient, amount);
        authorized_keys[msg.sender].withdraws++;
        emit WithdrawlMade(msg.sender, recipient, amount, block.timestamp);
        return success;
    }
    
    function timeLock(uint amount_of_time, address[] memory lockedWallets) public onlyOwner returns (bool success) {
        uint time_block = amount_of_time;
        bool locked;
        require (time_block > 7 days, "The minimum locking period is 7 days, after this time the wallets can be unlocked");
        address[] memory lockedKeys = lockedWallets;
        Locked memory newLocks = Locked({isLocked: lockedKeys});
        times_locked.push(newLocks);
        locked = true;
        walletsLocked = true;
        return success;
    }
    
    function getLocks() public view returns (uint) {
        return(times_locked.length);
    }
}
