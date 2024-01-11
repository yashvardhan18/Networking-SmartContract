// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// contract NetworkMarketing is SafeERC20, OwnableUpgradeable{
//     address public owner;
//     address public token;
//     mapping(address => Investor) public investors;
    
//     uint256 constant MIN_INVESTMENT = 100 ether;
//     uint256 constant MAX_INVESTMENT = 2500000 ether;
//     uint256 constant MIN_WITHDRAWAL = 50 ether;
//     uint256 constant DOUBLE_TIME = 130 days;

//     enum Position {
//         Iron,
//         Silver,
//         Gold,
//         Diamond,
//         Platinum,
//         Rhodium
//     }

//     struct Investor {
//         uint256 investment;
//         uint256 totalWithdrawn;
//         uint256 lastInvestmentTime;
//         address referrer;
//         uint8 level;
//         Position position;
//     }

//     function initialize(){
//        __Ownable_init(msg.sender);
//     }

//     // modifier onlyOwner() {
//     //     require(msg.sender == owner, "Only owner can perform this action");
//     //     _;
//     // }

//     function invest(address _referrer, uint256 _amount) external  {
//         require(msg.value >= MIN_INVESTMENT && msg.value <= MAX_INVESTMENT, "Invalid investment amount");
//         // require(investors[msg.sender].investment == 0, "You can only invest once");
        
//         if (investors[_referrer].investment > 0 && _referrer != msg.sender) {
//             investors[msg.sender].referrer = _referrer;
//         }
//         SafeERC20.safeTransferFrom(token, msg.sender, address(this), _amount);

//         investors[msg.sender].investment = _amount;
//         investors[msg.sender].lastInvestmentTime = block.timestamp;
//     }

//     function withdraw() external {
//         Investor storage investor = investors[msg.sender];
//         require(investor.investment > 0, "You haven't invested yet");
        
//         uint256 profit = calculateProfit(msg.sender);
//         require(profit >= MIN_WITHDRAWAL, "Insufficient balance to withdraw");
        
//         investor.totalWithdrawn += profit;
//         investor.investment = 0;
        
//         payable(msg.sender).transfer(profit);
//     }

//     function calculateProfit(address _investor) internal view returns (uint256) {
//         Investor storage investor = investors[_investor];
//         uint256 timeDiff = block.timestamp - investor.lastInvestmentTime;
//         uint256 daysPassed = timeDiff / 1 days;
        
//         if (daysPassed >= DOUBLE_TIME / 1 days) {
//             return investor.investment * 2;
//         }
//         return 0;
//     }

//     function updatePosition(address _investor, Position _position) external onlyOwner {
//         investors[_investor].position = _position;
//     }

//     function updateLevel(address _investor, uint8 _level) external onlyOwner {
//         investors[_investor].level = _level;
//     }

//     function getInvestorDetails(address _investor) external view returns (uint256, uint256, uint256, address, uint8, Position) {
//         Investor memory investor = investors[_investor];
//         return (investor.investment, investor.totalWithdrawn, investor.lastInvestmentTime, investor.referrer, investor.level, investor.position);
//     }
// }
