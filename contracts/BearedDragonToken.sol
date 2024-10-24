// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
}

// 模拟用token--鬃狮蜥币
contract BearedDragonToken is IERC20 {
    string public constant name = "BearedDragonToken";
    string public constant symbol = "BDT";
    uint8 public constant demicals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 _totalSupply = 10000 ether;

    constructor() {
        balances[msg.sender] = _totalSupply;
    }

    function getTotalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function getBalanceOf(address tokenOwner) public view returns(uint256) {
        return balances[tokenOwner];
    }

    function approve(address delegate, uint256 numTokens) public  returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        return true;
    }

    function getAllowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transfer(address receiver, uint256 tokenNum) public override balanceCheck(tokenNum) returns(bool) {
        balances[msg.sender] -= tokenNum;
        balances[receiver] += tokenNum;

        return true;
    }

    function transferFrom(address from, address to, uint256 tokenNum) public override allowanceCheck(from, tokenNum) returns(bool) {
        require(tokenNum <= balances[msg.sender], "insufficient balance");

        balances[from] -= tokenNum;
        balances[to] += tokenNum;
        allowed[from][msg.sender] -= tokenNum;

        return true;
    }

    modifier balanceCheck(uint256 tokenNum) {
        require(tokenNum <= balances[msg.sender], "insufficient balance");
        _;
    }

    modifier allowanceCheck(address from, uint256 tokenNum) {
        require(tokenNum <= allowed[from][msg.sender], "Insufficient allowance");
        _;
    }
}