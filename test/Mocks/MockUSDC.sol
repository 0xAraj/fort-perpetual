// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    //uint8 _decimals = 6;

    constructor() ERC20("MockUSDC", "USDC") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    // function decimals() public view override returns (uint8) {
    //     return _decimals;
    // }
}
