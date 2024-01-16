// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";

contract Networking is OwnableUpgradeable {
    struct UserDetails {
        uint256 totalInvestment; // user's total deposit
        uint256 depositTime;
        uint256 totalDistributeRI; // total claimed Daily interest
        uint256 refereeCount;
        uint256 claimedIncome;
        uint256 withdrawedReward;
        uint256 totalReward;
        uint256 token;
        address referrerAddress;
        uint8 rank;
        uint256 depositCount;
    }

    address public stakeToken;
    address public rewardWallet;
    uint256 serviceChargeAmount;
    uint128 public ROIpercent;
    uint128 public ROITime;
    uint128 public maxDeposit;
    uint128 public minDeposit;
    uint128 public minWithdrawalAmount;

    mapping(address => uint256) public referralIncome;
    mapping(address => uint256) public claimedROIIncome;
    mapping(address => UserDetails) public Details;
    mapping(uint8 => mapping(uint8 => uint128)) public packageThreshold;
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
    event withdrawIncome(
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

    constructor() {
        // _disableInitializers();
    }

    function initialize(
        address _stakeToken,
        uint8[] memory ranks,
        uint8[] memory levels,
        uint128[] memory ROIPercentage,
        uint128 _ROIPercent
    ) external initializer {
        __Ownable_init(msg.sender);
        stakeToken = _stakeToken;
        rewardWallet = owner();
        Details[owner()].totalInvestment = 1;
        ROIpercent = _ROIPercent;
        uint8 levels_length = uint8(levels.length);
        uint8 ranks_length = uint8(ranks.length);
        uint8 flag = 0;
        for (uint i = 0; i < ranks_length; i++) {
            for (uint j = 0; j < levels_length; j++) {
                packageThreshold[ranks[i]][levels[j]] = ROIPercentage[flag];
                flag++;
            }
        }
    }

    function deposit(uint8 _rank, address _referrer, uint256 amount) public {
        address user = msg.sender;
        uint256 timeNow = block.timestamp;

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

        if (
            _referrer != address(0) &&
            Details[Details[user].referrerAddress].totalInvestment == 0
        ) {
            revert InvalidReferrer();
        }

        _calculateRewards(user);

        Details[user].rank = _rank;
        Details[_referrer].refereeCount += 1;
        Details[user].depositTime = timeNow;
        Details[user].totalInvestment += amount;
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

    function distributeRI(
        address _user,
        uint256 _amount
    ) internal returns (uint256) {
        address[] memory referrers = new address[](6);
        referrers[0] = Details[_user].referrerAddress;
        uint8 i;

        for (i = 1; i < 6; i++) {
            referrers[i] = Details[referrers[i - 1]].referrerAddress;
            if (referrers[i] == address(0)) {
                break;
            }
        }
        uint256 numReferrers = i; // Number of valid referrers

        uint256 remainingReward = _amount;

        uint256[] memory rewardShares = new uint256[](numReferrers);

        for (i = 0; i < numReferrers; i++) {
            if (referrers[i] != address(0)) {
                rewardShares[i] =
                    (_amount * getAmountPercentage(i + 1, _user)) /
                    10000;

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

        Details[msg.sender].totalReward += remainingReward;
    }

    function getAmountPercentage(
        uint8 position,
        address user
    ) internal view returns (uint256) {
        console.log( packageThreshold[Details[user].rank][position]);

        return packageThreshold[Details[user].rank][position];
    }

    function setPackage(
        uint8 rank,
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

    function _calculateRewards(address _user) public returns (uint256 reward) {
        UserDetails storage details = Details[_user];
        uint256 time = (block.timestamp - details.depositTime) / 86400;
        uint256 TotalROI = ((Details[_user].totalInvestment *
            time *
            ROIpercent) / 10000);
    console.log("total ROI", TotalROI);
        if (TotalROI >= details.totalInvestment * 2) {
            TotalROI = details.totalInvestment * 2;

            serviceChargeAmount += (TotalROI * 5000) / 10000;
            reward = TotalROI - (TotalROI * 5000) / 10000;
        } else {
            revert ROINotReady();
        }

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

    function setROITime(uint128 _time) public onlyOwner returns (uint128) {
        if (_time == 0) {
            revert ZeroAmount();
        }
        return ROITime = _time;
    }

    function withdrawReward(uint256 _amount) public {
        UserDetails storage details = Details[msg.sender];
        if (_amount < minWithdrawalAmount) {
            revert BelowMinLimit();
        }

        if (_amount > Details[msg.sender].totalInvestment) {
            revert InvalidWithdrawalAmount();
        }
        uint256 time = (block.timestamp - details.depositTime) / 86400;
        uint256 TotalROI = ((Details[msg.sender].totalInvestment *
            time *
            ROIpercent) / 10000);
        if (TotalROI >= details.totalInvestment * 2) {
            _calculateRewards(msg.sender);
            Details[msg.sender].totalReward += referralIncome[msg.sender];
            referralIncome[msg.sender] = 0;
            Details[msg.sender].depositTime = block.timestamp;
            console.log("Total reward", Details[msg.sender].totalReward);
            details.withdrawedReward += _amount;
            details.totalReward -= _amount;
            console.log("Total reward 2", Details[msg.sender].totalReward);
            SafeERC20.safeTransfer(IERC20(stakeToken), msg.sender, _amount);
        } else if (
            details.withdrawedReward > 0 && _amount <= details.totalReward
        ) {
            Details[msg.sender].totalReward += referralIncome[msg.sender];
            referralIncome[msg.sender] = 0;
            Details[msg.sender].depositTime = block.timestamp;
            console.log("Total reward", Details[msg.sender].totalReward);
            details.withdrawedReward += _amount;
            details.totalReward -= _amount;
            console.log("Total reward 2", Details[msg.sender].totalReward);
            SafeERC20.safeTransfer(IERC20(stakeToken), msg.sender, _amount);
        } else {
            revert ROINotReady();
        }

        emit withdrawIncome(msg.sender, _amount, block.timestamp);
    }

    function seeDeposit(
        address user,
        uint256 depositCount
    ) external view returns (uint256) {
        return Details[user].totalInvestment;
    }
}
