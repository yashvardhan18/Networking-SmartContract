// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "../Interfaces/IUSDT.sol";

contract Usdc is IERC20, ERC20Burnable{
    constructor() ERC20("USDC", "USDC") {
        
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external  {
        require(to!=address(0),"Zero address sent");
        _mint(to, amount);
    }

   function decimals() public view virtual override(ERC20) returns (uint8) {
		return 6;
	}

    function transfer(address from, address to , uint256 _amount) external {
        require(to!=address(0),"Zero address sent");
        _transfer(from,to, _amount);
    }


}
