pragma solidity ^0.5.12;

contract MyWallet {
    
    uint public max_withdrawl;
    uint public min_withdrawl;
    uint public max_keys = 5;
    uint public contract_balance;
    address payable public owner;
    
    address payable[] public auth_keys;
    
    mapping (address => uint) public times_withdrawn;
    mapping (address => bool) public key_is_authorized;
    
    event AuthKeyAddded(address indexed auth_key);
    event DepositMade(address indexed key, uint indexed amount);
    event WithdrawlMade(address indexed key, uint indexed amount, uint indexed time);
    
    modifier onlyAuthKey() {
        require(key_is_authorized[msg.sender] = true);
        _;
    }
    
    constructor () public {
        max_withdrawl = 1000 ether;
        min_withdrawl = 1 szabo;
        max_keys = 1;
        owner = msg.sender;
        auth_keys.push(owner) - 1;
        times_withdrawn[msg.sender] = 0;
        key_is_authorized[msg.sender] = true;
    }
    
    function addAuthroizedKey(address payable auth_key) public onlyAuthKey {
        require(max_keys <= 4, "There are 4 keys or less");
        for (uint i = 0; i < auth_keys.length; i++) {
                if(auth_keys[i] == auth_key) {
                revert('Key already stored in array');
            }
        }
        auth_keys.push(auth_key);
        times_withdrawn[auth_key] = 0;
        key_is_authorized[auth_key] = true;
        max_keys = max_keys + 1;
        emit AuthKeyAddded(auth_key);
    }
    
    function removeAuthKey(address bad_key) public onlyAuthKey returns (uint index) {
        for (uint i = 0; i < auth_keys.length; i++) {
            if (auth_keys[i] == bad_key) {
                delete(auth_keys[i]);
                auth_keys.length--;
                key_is_authorized[bad_key] = false;
            }
        }
        max_keys = max_keys - 1;
        return auth_keys.length;
    }

    function deposit() public payable returns (bool success) {
        address(this).balance == address(this).balance + msg.value;
        contract_balance = address(this).balance; 
        emit DepositMade(msg.sender, msg.value);
        return success;
    }
    
    function withdraw(uint amount) public onlyAuthKey returns (bool success) {
        require(max_withdrawl >= amount && amount >= min_withdrawl);
        msg.sender.transfer(amount);
        address(this).balance == address(this).balance - amount;
        contract_balance = contract_balance - amount;
        times_withdrawn[msg.sender]++;
        emit WithdrawlMade(msg.sender, amount, block.timestamp);
        return success;
    }
    
    function () external payable {
        require(msg.data.length == 0);
    }
    
}
