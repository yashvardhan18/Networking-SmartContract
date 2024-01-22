// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// import "hardhat/console.sol";

contract Networking is OwnableUpgradeable {
    struct UserDetails {
        uint256 totalInvestment; // user's total deposit
        uint256 depositTime;
        uint256 totalDistributeRI; // total claimed Daily interest
        uint256 refereeCount;
        uint256 claimedIncome;
        uint256 withdrawedReward;
        uint256 totalReward;
        uint256 roboReward;
        uint256 depositCount;
        uint256 roboCount;
        uint256 roboSubscriptionPeriod;
        uint8 rank;
        address referrerAddress;
    }

    address public stakeToken;
    address public companyRoboRewardWallet;
    uint256 serviceChargeAmount;
    uint128 public ROIpercent;
    uint128 public ROITime;
    uint128 public maxDeposit;
    uint128 public minDeposit;
    uint128 public minWithdrawalAmount;

    mapping(address => uint256) public referralIncome;
    mapping(address => UserDetails) public Details;
    mapping(uint8 => mapping(uint8 => uint128)) public packageThreshold;
    mapping(uint8 => uint256) roboFee;
    mapping(uint8 => uint256) roboLevelPercentage;

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
    error InvalidDepositAmount();

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
        uint8[] memory _ranks,
        uint8[] memory _levels,
        uint128[] memory _ROIPercentage,
        uint128[] memory _roboFee,
        uint128 _ROIPercent
    ) external initializer {
        __Ownable_init(msg.sender);
        stakeToken = _stakeToken;
        rewardWallet = owner();
        Details[owner()].totalInvestment = 1;
        ROIpercent = _ROIPercent;
        uint8 levels_length = uint8(_levels.length);
        uint8 ranks_length = uint8(_ranks.length);
        uint8 flag = 0;
        for (uint i = 0; i < ranks_length; i++) {
            roboFee[i] = _roboFee[i];
            for (uint j = 0; j < levels_length; j++) {
                packageThreshold[_ranks[i]][_levels[j]] = _ROIPercentage[flag];
                flag++;
            }
        }
    }

    function deposit(uint8 _rank, address _referrer, uint256 amount) external {
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
            _referrer = rewardWallet;
        }

        if (amount < 100000000 || amount > 25000000000000) {
            revert InvalidDepositAmount();
        }

        if (Details[user].totalInvestment == 0) {
            Details[user].referrerAddress = _referrer;
        }

        _calculateRewards(user);

        Details[user].rank = _rank;
        Details[_referrer].refereeCount += 1;
        Details[user].depositTime = timeNow;
        Details[user].totalInvestment += amount;
        Details[user].roboCount += 1;
        Details[user].roboSubscriptionPeriod = block.timestamp;
        roboRewardDistribution(Details[user].totalInvestment, msg.sender);
        SafeERC20.safeTransferFrom(
            IERC20(stakeToken),
            user,
            address(this),
            amount
        );
    }

    function roboRewardDistribution(
        uint256 _investmentAmount,
        address _user
    ) internal {
        uint fee;

        if (
            Details[_user].roboCount > 1 &&
            Details[_user].roboCount < 6 &&
            _investmentAmount >= _investmentAmount * 2
        ) {
            fee = 0;
        } else {
            if (
                _investmentAmount >= 100000000 &&
                _investmentAmount <= 2490000000
            ) {
                fee = roboFee[1];
            } else if (
                _investmentAmount >= 2500000000 &&
                _investmentAmount <= 9999000000
            ) {
                fee = roboFee[2];
            } else if (
                _investmentAmount >= 10000000000 &&
                _investmentAmount <= 24999000000
            ) {
                fee = roboFee[3];
            } else if (
                _investmentAmount >= 25000000000 &&
                _investmentAmount <= 999999000000
            ) {
                fee = roboFee[3];
            } else if (
                _investmentAmount >= 1000000000000 &&
                _investmentAmount <= 4999999000000
            ) {
                fee = roboFee[4];
            } else if (
                _investmentAmount >= 5000000000000 &&
                _investmentAmount <= 25000000000000
            ) {
                fee = roboFee[5];
            }

            companyRewardWallet += (fee * 7500) / 10000;

            uint distributionAmount = fee - ((fee * 7500) / 10000);

            address[] memory referrers = new address[](4);
            referrers[0] = Details[_user].referrerAddress;
            uint8 i;

            for (i = 1; i < 4; i++) {
                referrers[i] = Details[referrers[i - 1]].referrerAddress;
                if (referrers[i] == address(0)) {
                    break;
                }
            }

            uint256[] memory rewardShares = new uint256[](numReferrers);

            for (i = 0; i < numReferrers; i++) {
                if (referrers[i] != address(0)) {
                    rewardShares[i] =
                        (_amount * getRoboLevelPercentage(i + 1)) /
                        10000;
                    distributionAmount -= rewardShares[i];
                }

                Details[referrers[i]].roboReward = rewardShares[i];
            }

            if (distributionAmount > 0) {
                companyRewardWallet += distributionAmount;
            }
        }
    }

    function distributeROI(
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
                    (_amount * getAmountPercentage(i + 1, referrers[i])) /
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

        serviceChargeAmount += remainingReward;
    }

    function getAmountPercentage(
        uint8 position,
        address referrer
    ) internal view returns (uint256) {
        console.log(packageThreshold[Details[referrer].rank][position]);

        return packageThreshold[Details[referrer].rank][position];
    }

    function getRoboLevelPercentage(
        uint8 position
    ) internal view returns (uint256) {
        return roboLevelPercentage[position];
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

    function _calculateRewards(
        address _user
    ) internal returns (uint256 reward) {
        UserDetails storage details = Details[_user];
        uint256 time = (block.timestamp - details.depositTime) / 86400;
        uint256 TotalROI = ((Details[_user].totalInvestment *
            time *
            ROIpercent) / 10000);

        uint serviceCharge = (TotalROI * 5000) / 10000;
        reward = TotalROI - (TotalROI * 5000) / 10000;
        Details[msg.sender].totalReward += referralIncome[msg.sender] + reward;
        referralIncome[msg.sender] = 0;

        return distributeROI(_user, serviceCharge);
    }

    function setROIPercentage(
        uint128 _percent
    ) external onlyOwner returns (uint128) {
        if (_percent == 0) {
            revert ZeroAmount();
        }
        return ROIpercent = _percent;
    }

    function setROITime(uint128 _time) external onlyOwner returns (uint128) {
        if (_time == 0) {
            revert ZeroAmount();
        }
        return ROITime = _time;
    }

    function setMinWithdrawalLimit(uint256 _newLimit) external onlyOwner {
        minWithdrawalAmount = _newLimit;
    }

    function withdrawReward(uint256 _amount) external {
        UserDetails storage details = Details[msg.sender];
        if (_amount < minWithdrawalAmount) {
            revert BelowMinLimit();
        }

        if (_amount > Details[msg.sender].totalReward) {
            revert InvalidWithdrawalAmount();
        }

        if (Details[msg.sender].totalReward < minWithdrawalAmount) {
            revert ROINotReady();
        }

        _calculateRewards(msg.sender);

        Details[msg.sender].depositTime = block.timestamp;

        details.withdrawedReward += _amount;
        details.totalReward -= _amount;

        SafeERC20.safeTransfer(IERC20(stakeToken), msg.sender, _amount);

        emit withdrawIncome(msg.sender, _amount, block.timestamp);
    }

    function withdrawRoboIncome(uint256 _amount) external {
        address _user = msg.sender;
        if (_amount > Details[_user].roboReward) {
            revert InvalidWithdrawalAmount();
        }

        Details[_user].roboReward -= _amount;
        SafeERC20.safeTransfer(IERC20(stakeToken), _user, _amount);
    }

    function withdrawInvestment(uint256 _amount) external {
        address _user = msg.sender;
        if (_amount > Details[_user].totalInvestment) {
            revert InvalidWithdrawalAmount();
        }
        if (Details[_user].totalReward < Details[_user].totalInvestment) {
            revert ROINotReady();
        }

        Details[_user].totalInvestment -= _amount;
        SafeERC20.safeTransfer(IERC20(token), _user, _amount);
    }

    function withdrawServiceChargeAmountAndCompanyRoboReward(
        uint256 _serviceChargeAmount,
        uint256 _roboRewardAmount
    ) external onlyOwner {
        if (_serviceChargeAmount > serviceChargeAmount) {
            revert InvalidWithdrawalAmount();
        }
        if (_roboRewardAmount > companyRoboRewardWallet) {
            revert InvalidWithdrawalAmount();
        }
        serviceChargeAmount -= _serviceChargeAmount;
        companyRoboRewardWallet -= _roboRewardAmount;
        SafeERC20.safeTransfer(IERC20(token), owner(), _serviceChargeAmount);
        SafeERC20.safeTransfer(IERC20(token), owner(), _roboRewardAmount);
    }

    function seeInvestment(
        address user,
        uint256 depositCount
    ) external view returns (uint256) {
        return Details[user].totalInvestment;
    }
}
