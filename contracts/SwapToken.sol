// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "./ITokenSwap.sol";

contract TokenSwap {
    IERC20 public celoToken;
    IERC20 public nairaToken;
    address owner;
    address newOwner;
    uint256 public constant RATE = 1565;

    uint256 internal contractBalance;

    bool internal locked;

    event Swap(
        address indexed user,
        uint256 celoAmount,
        uint256 nairaAmount,
        bool celoToNaira
    );

    constructor(address _celoToken, address _nairaToken) {
        celoToken = IERC20(_celoToken);
        nairaToken = IERC20(_nairaToken);
    }

    modifier reentrancyGuard() {
        require(!locked, "Not allowed to re-enter");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access");
        _;
    }

    function swapUSDCToNaira(uint256 celoAmount) external reentrancyGuard {
        require(msg.sender != address(0), "Zero address not allowed");
        require(celoAmount > 0, "Amount must be greater than 0");
        uint256 nairaAmount = celoAmount * RATE;

        require(
            celoToken.transferFrom(msg.sender, address(this), celoAmount),
            "USDC transfer failed"
        );
        require(
            nairaToken.transfer(msg.sender, nairaAmount),
            "Naira transfer failed"
        );

        emit Swap(msg.sender, celoAmount, nairaAmount, true);
    }

    function swapNairaToCELO(uint256 nairaAmount) external reentrancyGuard {
        require(msg.sender != address(0), "Zero address not allowed");
        require(nairaAmount > 0, "Amount must be greater than 0");
        require(
            nairaAmount % RATE == 0,
            "Naira amount must be divisible by the rate"
        );

        uint256 celoAmount = nairaAmount / RATE;

        require(
            nairaToken.transferFrom(msg.sender, address(this), nairaAmount),
            "Naira transfer failed"
        );
        require(
            celoToken.transfer(msg.sender, celoAmount),
            "USDC transfer failed"
        );

        emit Swap(msg.sender, celoAmount, nairaAmount, false);
    }

    function getContractBalance() external view onlyOwner returns (uint256) {
        return contractBalance;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(msg.sender != address(0), "Zero address not allowed");
        require(_newOwner != address(0), "Zero address not allowed");
        newOwner = _newOwner;
    }

    function claimOwnership() external {
        require(msg.sender != address(0), "Zero address not allowed");
        require(msg.sender == newOwner, "Not your turn yet");
        owner = newOwner;

        newOwner = address(0);
    }
}