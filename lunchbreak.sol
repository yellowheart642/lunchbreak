                                                                                                                                                                       
//   _      __ __  ____     __  __ __  ____   ____     ___   ____  __  _ 
//  | |    |  |  ||    \   /  ]|  |  ||    \ |    \   /  _] /    ||  |/ ]
//  | |    |  |  ||  _  | /  / |  |  ||  o  )|  D  ) /  [_ |  o  ||  ' / 
//  | |___ |  |  ||  |  |/  /  |  _  ||     ||    / |    _]|     ||    \
//  |     ||  :  ||  |  /   \_ |  |  ||  O  ||    \ |   [_ |  _  ||     \
//  |     ||     ||  |  \     ||  |  ||     ||  .  \|     ||  |  ||  .  |
//  |_____| \__,_||__|__|\____||__|__||_____||__|\_||_____||__|__||__|\_|
                                                                                                                            
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LunchBreak is ERC20, Ownable, ReentrancyGuard {

    mapping(address => uint256) private _lastInteraction;

    uint256 private constant INTERACTION_INTERVAL = 7 days;
    uint256 public constant TOTAL_SUPPLY = 347000000000 * 10 ** 18;

    string public constant LOGO_HASH = "InSeRtPiCtUrEhASh**";

    event TokensClaimed(address indexed claimer, address indexed inactiveUser, uint256 amount);
    event UserInteractionUpdated(address indexed user, uint256 timestamp);

    constructor() ERC20("Lunch Money", "LNCH") Ownable(msg.sender) {
        uint256 initialAllocation = TOTAL_SUPPLY;
        _mint(msg.sender, initialAllocation);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(this), "Cannot transfer tokens to the contract address");
        _updateUserInteraction(msg.sender);
        _updateUserInteraction(recipient);
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(this), "Cannot transfer tokens to the contract address");
        _updateUserInteraction(sender);
        _updateUserInteraction(recipient);
        return super.transferFrom(sender, recipient, amount);
    }

    receive() external payable {
        revert("Rejected");
    }

    function _updateUserInteraction(address user) private {
        _lastInteraction[user] = block.timestamp;
        emit UserInteractionUpdated(user, block.timestamp);
    }

    function claimInactiveTokens(address inactiveUser) external nonReentrant {
        require(inactiveUser != msg.sender && inactiveUser != address(this), "Cannot claim tokens from the contract address or yourself");
        require(_isInactive(inactiveUser), "User is not inactive");
        require(inactiveUser != address(0), "Invalid address provided");
        uint256 userBalance = balanceOf(inactiveUser);
        _transfer(inactiveUser, msg.sender, userBalance);
        emit TokensClaimed(msg.sender, inactiveUser, userBalance);
        _updateUserInteraction(msg.sender);
    }

    function isInactive(address user) public view returns (bool) {
        return _isInactive(user);
    }

    function _isInactive(address user) private view returns (bool) {
        if (user == address(this) || _lastInteraction[user] == 0) {
            return false;
        }
        return block.timestamp - _lastInteraction[user] >= INTERACTION_INTERVAL;
    }
}