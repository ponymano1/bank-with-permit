// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TigerToken
 * @dev ERC20 token with permit functionality
 * @notice This token supports gasless approvals via EIP-2612 permit
 */
contract TigerToken is ERC20, ERC20Permit, Ownable {
    uint8 private _decimals;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals_ The number of decimals for the token
     * @param totalSupply_ The total supply of tokens to create
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 totalSupply_
    ) ERC20(name, symbol) ERC20Permit(name) Ownable(msg.sender) {
        _decimals = decimals_;
        _mint(msg.sender, totalSupply_);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
