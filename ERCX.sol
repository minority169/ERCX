// based on https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./IERCX.sol";

contract ERCX is IERCX {

	using SafeMath for uint256;

	address payable private _owner;
	address payable[] private _investors;
	uint256 private _totalSupply;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => bool) private _investorRegistered;

	constructor(uint256 supply) public payable {
		_owner = msg.sender;
		_mint(_owner, supply);
	}

	function transferIncome(uint256 income) public payable returns (uint256) {
		uint256 coef = income.div(_totalSupply);
		for (uint i = 0; i < _investors.length; i++) {
			uint256 balance = _balances[_investors[i]];
			if (balance > 0) {
				_investors[i].transfer(balance.mul(coef));
			}
		}
		return coef;
	}

	function () external payable {
		transferIncome(msg.value);
	}
	
	function totalSupply() public view returns (uint256) {
        	return _totalSupply;
    	}

	function balanceOf(address account) public view returns (uint256) {
        	return _balances[account];
    	}

	function transfer(address payable recipient, uint256 amount) public returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 value) public returns (bool) {
		_approve(msg.sender, spender, value);
		return true;
	}

	function transferFrom(address sender, address payable recipient, uint256 amount) public returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
		return true;
	}

	function _transfer(address sender, address payable recipient, uint256 amount) internal {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		if (!validInvestor(recipient)) {
			_investors.push(recipient);
			_investorRegistered[recipient] = true;
		}

		_balances[sender] = _balances[sender].sub(amount);
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	function _mint(address payable account, uint256 amount) internal {
		require(account != address(0), "ERC20: mint to the zero address");

		if (!validInvestor(account)) {
			_investors.push(account);
			_investorRegistered[account] = true;
		}

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 value) internal {
		require(account != address(0), "ERC20: burn from the zero address");

		_totalSupply = _totalSupply.sub(value);
		_balances[account] = _balances[account].sub(value);
		emit Transfer(account, address(0), value);
	}

	function _approve(address owner, address spender, uint256 value) internal {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	function _burnFrom(address account, uint256 amount) internal {
		_burn(account, amount);
		_approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
	}

	function validInvestor(address investor) internal returns (bool) {
		return _investorRegistered[investor];
	}
}
