// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";

contract Networking is OwnableUpgradeable {
    struct UserDetails {
        uint256 totalInvestment; // user's total deposit
        uint256 claimedDistributeRI; // total claimed Daily interest
        uint256 refereeCount;
        uint256 claimedIncome; 
        uint256 withdrawedIncome;
        uint256 token;
        address referrerAddress;
        string rank;
        uint256 depositCount;
        mapping(uint256 => uint256)depositAmount;
        mapping(uint256=>bool) depositClaimed;
        mapping(uint256 => uint256) depositTime;
    }

    address public stakeToken;
    address public rewardWallet;
    uint256 serviceChargeAmount;
    // uint128 public countMembers;
    uint128 public ROIpercent;
    uint128 public ROITime;
    uint128 public maxDeposit;
    uint128 public minDeposit;
    uint128 public minWithdrawalAmount;

    mapping(address => uint256) public referralIncome;
    mapping(address => uint256) public claimedROIIncome;
    mapping(address => UserDetails) public Details;
    mapping(string => mapping(uint8 => uint128)) public packageThreshold;
    // mapping(uint8 => uint256) public levelThreshold;
    mapping(address => uint8) public referrerCount;

    error ZeroAmount();
    error InvalidRank();
    error InvalidReferrer();
    error BelowMinLimit();
    error AboveMaxLimit();
    error InvalidLevel();
    error notVerified();
    error InfeasibleAmount();
    error invalidAddress();
    error ROINotReady();
    error InvalidWithdrawalAmount();


    event Staked(
        address indexed user,
        address indexed referrer,
        uint256 depositTime,
        uint256 indexed amount,
        uint256 totalInvestment
    );
    event allocatedRankIncome(
        address indexed referrer,
        uint256 indexed amount,
        uint256 indexed timestamp
    );
    event allocatedLevelIncome(
        address indexed sender,
        address indexed receiver,
        uint256 indexed amount,
        uint256 timestamp
    );
    //event for allocatedDirectIncome
    event allocatedDirectIncome( 
        address indexed sender,
        address indexed receiver,
        uint256 indexed amount,
        uint256 timestamp
    );
    event withdrawNexaIncome(
        address indexed receiver,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    event withdrawDirectIncome(
        address indexed receiver,
        uint256 indexed amount,
        uint256 indexed timestamp
    );
    event claimedDailyIncome(
        address indexed receiver,
        uint256 indexed amount,
        uint256 indexed timestamp
    );
    event rankUpgrade(
        address indexed user,
        uint8 indexed newRank,
        uint256 indexed timestamp
    );
    event LockUser(
        address indexed user,
        uint256 indexed timestamp,
        bool LockDirectIncome,
        bool LockRankIncome,
        bool LockROIIncome,
        bool LockLevelIncome
    );

    constructor() {
        // _disableInitializers();
    }

    function initialize(address _stakeToken,string [] memory ranks, uint8[] memory levels, uint128[] memory ROIPercentage) external initializer {
        __Ownable_init(msg.sender);
        stakeToken = _stakeToken;
        rewardWallet = owner();
        Details[owner()].totalInvestment = 1;
        uint8 length_levels = uint8(levels.length);
        uint8 ranks_levels = uint8(ranks.length);

        for(uint i =0;i< ranks.length; i++){
            for(uint j=0; j< levels.length; j++){
                packageThreshold[ranks[i]][levels[j]] = ROIPercentage[j];
            }
        }
    

    }

    function deposit(string memory _rank, uint8 level, address _referrer, uint256 amount) public {
        address user = msg.sender;
        uint256 timeNow = block.timestamp;

        if (level == 0 && level > 6) {
            revert notVerified();
        }

        if (_referrer == msg.sender) {
            revert InvalidReferrer();
        }

        if (_referrer != address(0)) {
            if (Details[_referrer].totalInvestment == 0) {
                revert InvalidReferrer();
            }
        } else {
            // _referrer = rewardWallet;
        }

        if (Details[user].totalInvestment == 0) {
            Details[user].referrerAddress = _referrer;
            
            referrerCount[_referrer] += 1;
        }
        console.log("test");
        console.log(_referrer);

        if (
            _referrer != address(0) &&
            Details[Details[user].referrerAddress].totalInvestment == 0
        ) {
            revert InvalidReferrer();
        }
        Details[user].rank = _rank;
        Details[_referrer].refereeCount+=1;
        Details[user].depositCount +=1;
        Details[user].depositTime[Details[user].depositCount]= timeNow;
        Details[user].depositAmount[Details[user].depositCount] = amount;
        
        SafeERC20.safeTransferFrom(
            IERC20(stakeToken),
            user,
            address(this),
            amount
        );
        emit Staked(
            user,
            Details[user].referrerAddress,
            timeNow,
            amount,
            Details[user].totalInvestment
        );
    }
    function seeDeposit(address user, uint256 depositCount) external view returns(uint256){
        return Details[user].depositAmount[depositCount];
    }
    function distributeRI(address _user, uint256 _amount) internal returns (uint256){
        address[] memory referrers = new address[](6);
        referrers[0] = Details[_user].referrerAddress;
        uint8 i;
        // uint8 j;
        //populating the 15 members in referer array for the user
        for (i = 1; i < 6; i++) {
            referrers[i] = Details[referrers[i - 1]].referrerAddress;
            if (referrers[i] == address(0)) {
                break;
            }
        }
        uint256 numReferrers = i; // Number of valid referrers
        uint256 remainingReward = _amount;
        uint256[] memory rewardShares = new uint256[](numReferrers);
        // Calculate reward shares for each referrer
        for (i = 0; i < numReferrers; i++) {
            if (referrers[i] != address(0)) {
                rewardShares[i] = (_amount * getAmountPercentage(i,referrers[i])) / 10000;
              
                remainingReward -= rewardShares[i];
            }
            referralIncome[referrers[i]] += rewardShares[i];
            emit allocatedLevelIncome(
                msg.sender,
                referrers[i],
                rewardShares[i],
                block.timestamp
            );
        }
        return remainingReward;
    }

    function getAmountPercentage(
        uint8 position,
        address referrer
    ) internal view returns (uint256) {

      return packageThreshold[Details[referrer].rank][position];
    }

    function setPackage(
        string memory rank,
        uint8 level,
        uint128 _income
    ) external onlyOwner returns (uint128) {
        if (level == 0 && level > 6) {
            revert InvalidRank();
        }
        if (
            packageThreshold[rank][level] <= packageThreshold[rank][level] &&
           packageThreshold[rank][level] >= packageThreshold[rank][level]
        ) {
            revert InvalidRank();
        }
        packageThreshold[rank][level] = _income;
        return _income;
    }

    function _calculateRewards(
        address _user,
        uint256 depositCount
    ) public returns (uint256 reward) {
    
        UserDetails storage details = Details[_user];
        uint256 time = block.timestamp - details.depositTime[depositCount];
        uint256 Totalreward =
            ((details.depositAmount[depositCount] * time * ROIpercent)/10000)+ referralIncome[_user];
            referralIncome[_user] = 0;
        reward = Totalreward - (Totalreward * 5000) / 10000;
        serviceChargeAmount += (Totalreward * 5000) / 10000;
        
        return distributeRI(_user, reward);
    }

    function setROIPercentage(
        uint128 _percent
    ) public onlyOwner returns (uint128) {
        if (_percent == 0) {
            revert ZeroAmount();
        }
        return ROIpercent = _percent;
    }

    function setROITime(
        uint128 _time
    ) public onlyOwner returns (uint128) {
        if (_time == 0) {
            revert ZeroAmount();
        }
        return ROITime = _time;
    }
    // function LevelIncome(address _user, uint256 _amount) internal {
    //     address[] memory referrers = new address[](16);
    //     referrers[0] = Details[_user].referrerAddress;
    //     uint8 i;
    //     // uint8 j;
    //     //populating the 15 members in referer array for the user
    //     for (i = 1; i < 16; i++) {
    //         referrers[i] = Details[referrers[i - 1]].referrerAddress;
    //         if (referrers[i] == address(0)) {
    //             break;
    //         }
    //     }
    //     uint256 numReferrers = i; // Number of valid referrers
    //     uint256 remainingReward = _amount;
    //     uint256[] memory rewardShares = new uint256[](numReferrers);
    //     // Calculate reward shares for each referrer
    //     for (i = 0; i < numReferrers; i++) {
    //         if (referrers[i] != address(0)) {
                
    //             if (x > rewardShares[i]) {
    //                 rewardShares[i] = (_amount * getLevelAmountPercentage(i,_user)) / 100;
    //             } else {
    //                 rewardShares[i] = x;
    //             }
    //             remainingReward -= rewardShares[i];
    //         }
    //         referralIncome[referrers[i]] += rewardShares[i];
    //         emit allocatedLevelIncome(
    //             msg.sender,
    //             referrers[i],
    //             rewardShares[i],
    //             block.timestamp
    //         );
    //     }
    // }

    // function getLevelAmountPercentage(
    //     uint8 level,
    //     address _user
    // ) internal pure returns (uint256) {
    //     if (position == 0 && referrerCount[_user] >= 16) {
    //         return 50; // Percentage for the first level
    //     } else if (position == 1 && referrerCount[_user] == 15) {
    //         return 10; // Percentage for the second level
    //     } else if (position == 2 && referrerCount[_user] == 14) {
    //         return 5; // Percentage for the third level
    //     }
    //     else {
    //         return 1; // Percentage for the rest
    //     }
    // }
    function withdrawReward(uint256 _amount, uint256 depositCount) public {
        UserDetails storage details = Details[msg.sender];
        if(_amount < minWithdrawalAmount){
            revert InvalidWithdrawalAmount();
        }
        if(details.depositAmount[depositCount]==0){
            // revert ;
        }
        address user = msg.sender;
        uint256 time = block.timestamp - details.depositTime[depositCount];
        if(time > ROITime){
            revert ROINotReady();
        }
        uint256 roiIncome = _calculateRewards(user,depositCount);
        // uint256 remainingReward = distributeRI(msg.sender, roiIncome);
    if(_amount > referralIncome[user]){
        revert InvalidWithdrawalAmount();
    }
//========================================================================================================//

        referralIncome[user] -= _amount;
        claimedROIIncome[user] += roiIncome;
        details.withdrawedIncome += _amount;
      details.depositAmount[depositCount] = 0;
        SafeERC20.safeTransfer(IERC20(stakeToken), user, _amount);

        // details.depositTime = block.timestamp;
    }
    // function withdrawToken() public {
    //     address user = msg.sender;
    //     UserDetails storage details = Details[user];
    //     uint256 tokenIncome = details.token;
    //     // details.lockedIncome = (tokenIncome * 50) / 100;
    //     details.swapIncome = tokenIncome - details.lockedIncome;
    // }
}