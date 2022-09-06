// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimal
    ) ERC20(name, symbol, decimal) {
        _mint(msg.sender, initialSupply);
    }
}
