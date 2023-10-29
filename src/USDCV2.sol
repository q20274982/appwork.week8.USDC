// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// - 製作一個白名單
// - 只有白名單內的地址可以轉帳
// - 白名單內的地址可以無限 mint token

interface IWhiteList {}

contract USDC {
    // Ownable
    address private _owner;
    // Pausable
    address public pauser;
    bool public paused = false;
    // Blacklistable
    address public blacklister;
    mapping(address => bool) internal blacklisted;
    // FiatTokenV1
    string public name;
    string public symbol;
    uint8 public decimals;
    string public currency;
    address public masterMinter;
    bool internal initialized;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply_ = 0;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;
    // Rescuable
    address private _rescuer;
    // EIP712Domain
    bytes32 public DOMAIN_SEPARATOR;
    // EIP3009
    mapping(address => mapping(bytes32 => bool)) private _authorizationStates;
    // EIP2612
    mapping(address => uint256) private _permitNonces;
    // FiatTokenV2
    uint8 internal _initializedVersion;
}

contract WhiteList {
    mapping(address => bool) public whiteList;

    function isInWhiteList(address addr) public view returns (bool) {
        return whiteList[addr];
    }

    function addToWhiteList(address addr) public returns (bool) {
        whiteList[addr] = true;
        return true;
    }
}

contract USDCV2 is USDC, WhiteList {
    function VERSIONV2() public pure returns (string memory) {
        return "USDCV2";
    }

    function balanceOf(address addr) public view returns (uint256) {
        return balances[addr];
    }

    function mint(address _to, uint256 _amount) public returns (bool) {
        require(whiteList[_to] == true, "_to not in whiteList");
        totalSupply_ = totalSupply_ + _amount;
        balances[_to] = balances[_to] + _amount;

        return true;
    }

    function transfer(address _to, uint256 amount) public returns (bool) {
        require(whiteList[msg.sender] == true, "msg.sender not in whiteList");
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(amount <= balances[msg.sender], "ERC20: transfer amount exceeds balance");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[_to] = balances[_to] + amount;

        return true;
    }
}
