// SPDX-License-Identifier: MIT

/**
 * @title Networking Contract
 * @dev A contract for managing user investments, rewards, and referrals.
 * @author [Author Name]
 */
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";

contract Networking is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // Struct to store user details
    struct UserDetails {
        uint256 totalInvestment; // User's total deposit
        uint256 depositTime;
        uint256 totalDistributeRI; // Total claimed Daily interest
        uint256 refereeCount;
        uint256 claimedIncome;
        uint256 withdrawedReward;
        uint256 totalReward;
        uint256 roboReward;
        uint256 roboCount;
        uint256 investmentDoubleCount;
        uint256 roboSubscriptionPeriodStart;
        uint8 rank;
        address referrerAddress;
    }

    // State variables
    address public stakeToken;
    uint256 companyRoboRewardWallet;
    uint256 public serviceChargeAmount;
    uint128 public ROIpercent;
    uint128 public ROITime;
    uint128 public maxDeposit;
    uint128 public minDeposit;
    uint128 public minWithdrawalAmount;

    // Mappings
    mapping(address => uint256) public referralIncome;
    mapping(address => UserDetails) public Details;
    mapping(uint8 => mapping(uint8 => uint128)) public packageThreshold;
    mapping(uint => uint256) roboFee;
    mapping(uint => uint256) roboLevelPercentage;

    // Errors
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

    // Events
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

    // Constructor
    constructor() {
        // _disableInitializers();
    }

    /**
     * @notice Initializes the Networking contract.
     * @dev Sets initial values and configurations for the contract.
     * @param _stakeToken The address of the token used for staking.
     * @param _ranks An array containing the ranks for the network.
     * @param _levels An array containing the levels for the network.
     * @param _ROIPercentage An array containing the ROI percentages for each level.
     * @param _roboLevelPercentage An array containing the fees for each robo level.
     * @param _ROIPercent The overall ROI percentage for the network.
     */
    function initialize(
        address _stakeToken,
        uint8[] memory _ranks,
        uint8[] memory _levels,
        uint128[] memory _ROIPercentage,
        uint128[] memory _roboFee,
        uint256[] memory _roboLevelPercentage,
        uint128 _ROIPercent
    ) external initializer {
        __Ownable_init(msg.sender);
        stakeToken = _stakeToken;
        Details[owner()].totalInvestment = 1;
        ROIpercent = _ROIPercent;
        uint8 levels_length = uint8(_levels.length);
        uint8 ranks_length = uint8(_ranks.length);
        uint8 roboFee_length = uint8(_roboFee.length);
        uint8 flag = 0;
        for (uint i = 0; i < roboFee_length; i++) {
            roboFee[i] = _roboFee[i];
        }
        for (uint i = 0; i < ranks_length; i++) {
            roboLevelPercentage[i] = _roboLevelPercentage[i];
            for (uint j = 0; j < levels_length; j++) {
                packageThreshold[_ranks[i]][_levels[j]] = _ROIPercentage[flag];
                flag++;
            }
        }
    }

    /**
     * @notice Allows a user to make a deposit.
     * @dev Handles user deposits and calculates rewards.
     * @param _rank The rank of the user.
     * @param _referrer The address of the referrer.
     * @param amount The amount to be deposited.
     */
    function deposit(uint8 _rank, address _referrer, uint256 amount) external {
        address user = msg.sender;
        uint256 timeNow = block.timestamp;
        uint _investmentAmount = Details[user].totalInvestment;
        // Check for valid referrer
        if (_referrer == msg.sender) {
            revert InvalidReferrer();
        }

        if (_referrer != address(0)) {
            if (Details[_referrer].totalInvestment == 0) {
                revert InvalidReferrer();
            }
        } else {
            _referrer = owner();
        }

        // Validate deposit amount
        if (amount < 100000000 || amount > 25000000000000) {
            revert InvalidDepositAmount();
        }

        // Set referrer if not set
        if (Details[user].totalInvestment == 0) {
            Details[user].referrerAddress = _referrer;
        }

        // Calculate and distribute rewards
        _calculateRewards(user);

        Details[user].rank = _rank;
        Details[_referrer].refereeCount += 1;
        Details[user].depositTime = timeNow;
        Details[user].totalInvestment += amount;
        if (
            (Details[user].roboSubscriptionPeriodStart + 15780000 <=
                block.timestamp &&
                Details[user].investmentDoubleCount == 1) ||
            Details[user].roboCount == 0
        ) {
            console.log("IF case");
            roboRewardDistribution(msg.sender);
        } else {

            console.log("Investment now",_investmentAmount);
            console.log("Investment after", Details[user].totalInvestment);

            if (Details[user].totalInvestment >= _investmentAmount * 2) {
                Details[user].investmentDoubleCount += 1;
                if ((Details[user].investmentDoubleCount % 6) == 0) {
                    roboRewardDistribution(msg.sender);
                } else {
                    Details[user].roboCount += 1;
                }
            }
        }

        IERC20(stakeToken).safeTransferFrom(user, address(this), amount);
    }

    /**
     * @notice Distributes robo rewards based on the user's investment amount.
     * @dev Handles the distribution of robo rewards.
     * @param _user The address of the user.
     */
    function roboRewardDistribution(address _user) internal {
        uint fee;

        uint256 _investmentAmount = Details[_user].totalInvestment;
        if (_investmentAmount >= 100000000 && _investmentAmount <= 499000000) {
            fee = roboFee[0];
        } else if (
            _investmentAmount >= 500000000 && _investmentAmount <= 2490000000
        ) {
            fee = roboFee[1];
        } else if (
            _investmentAmount >= 2500000000 && _investmentAmount <= 9999000000
        ) {
            fee = roboFee[2];
        } else if (
            _investmentAmount >= 10000000000 && _investmentAmount <= 24999000000
        ) {
            fee = roboFee[3];
        } else if (
            _investmentAmount >= 25000000000 &&
            _investmentAmount <= 999999000000
        ) {
            fee = roboFee[4];
        } else if (
            _investmentAmount >= 1000000000000 &&
            _investmentAmount <= 4999999000000
        ) {
            fee = roboFee[5];
        } else if (
            _investmentAmount >= 5000000000000 &&
            _investmentAmount <= 25000000000000
        ) {
            fee = roboFee[6];
        }

        companyRoboRewardWallet += (fee * 7500) / 10000;
        console.log("Robo fee", fee);
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
        uint256 numReferrers = i;
        uint256[] memory rewardShares = new uint256[](numReferrers);

        for (i = 0; i < numReferrers; i++) {
            if (referrers[i] != address(0)) {
                console.log("Level percent", getRoboLevelPercentage(i));
                rewardShares[i] =
                    (distributionAmount * getRoboLevelPercentage(i)) /
                    10000;
                console.log("referrers address", referrers[i]);
                console.log("referrers robo reward", rewardShares[i]);
                console.log("distribution amount", distributionAmount);

                distributionAmount -= rewardShares[i];
                console.log("distribution amount", distributionAmount);
            }

            Details[referrers[i]].roboReward += rewardShares[i];
        }
        Details[_user].roboCount += 1;
        Details[_user].roboSubscriptionPeriodStart = block.timestamp;

        if (distributionAmount > 0) {
            companyRoboRewardWallet += distributionAmount;
        }

        IERC20(stakeToken).safeTransferFrom(_user, address(this), fee);
    }

    /**
     * @notice Distributes ROI (Return on Investment) to the referrers.
     * @dev Handles the distribution of ROI to the referrers.
     * @param _user The address of the user.
     * @param _amount The total ROI amount.
     * @return The remaining reward after distribution.
     */
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
        }

        serviceChargeAmount += remainingReward;

        return remainingReward;
    }

    /**
     * @notice Gets the percentage based on the position and referrer's rank.
     * @dev Retrieves the percentage based on the position and referrer's rank.
     * @param position The position in the hierarchy.
     * @param referrer The address of the referrer.
     * @return The percentage for the given position and referrer's rank.
     */
    function getAmountPercentage(
        uint8 position,
        address referrer
    ) internal view returns (uint256) {
        // console.log(packageThreshold[Details[referrer].rank][position]);

        return packageThreshold[Details[referrer].rank][position];
    }

    /**
     * @notice Gets the robo level percentage for the given position.
     * @dev Retrieves the robo level percentage for the given position.
     * @param position The position in the robo hierarchy.
     * @return The robo level percentage for the given position.
     */
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

    /**
     * @notice Sets the ROI percentage for the network.
     * @dev Allows the owner to set the ROI percentage for the network.
     * @param _percent The new ROI percentage.
     * @return The new ROI percentage.
     */
    function setROIPercentage(
        uint128 _percent
    ) external onlyOwner returns (uint128) {
        if (_percent == 0) {
            revert ZeroAmount();
        }
        return ROIpercent = _percent;
    }

    /**
     * @notice Sets the ROI time for the network.
     * @dev Allows the owner to set the ROI time for the network.
     * @param _time The new ROI time.
     * @return The new ROI time.
     */
    function setROITime(uint128 _time) external onlyOwner returns (uint128) {
        if (_time == 0) {
            revert ZeroAmount();
        }
        return ROITime = _time;
    }

    /**
     * @notice Sets the minimum withdrawal limit.
     * @dev Allows the owner to set the minimum withdrawal limit.
     * @param _newLimit The new minimum withdrawal limit.
     */
    function setMinWithdrawalLimit(uint128 _newLimit) external onlyOwner {
        minWithdrawalAmount = _newLimit;
    }

    /**
     * @notice Allows a user to withdraw their reward.
     * @dev Handles the withdrawal of rewards for a user.
     * @param _amount The amount to be withdrawn.
     */
    function withdrawReward(uint256 _amount) external {
        UserDetails storage details = Details[msg.sender];
        _calculateRewards(msg.sender);
        if (_amount < minWithdrawalAmount) {
            revert BelowMinLimit();
        }

        if (_amount > Details[msg.sender].totalReward) {
            revert InvalidWithdrawalAmount();
        }

        if (Details[msg.sender].totalReward < minWithdrawalAmount) {
            revert ROINotReady();
        }

        Details[msg.sender].depositTime = block.timestamp;

        details.withdrawedReward += _amount;
        details.totalReward -= _amount;

        IERC20(stakeToken).safeTransfer(msg.sender, _amount);

        emit withdrawIncome(msg.sender, _amount, block.timestamp);
    }

    /**
     * @notice Allows a user to withdraw their robo income.
     * @dev Handles the withdrawal of robo income for a user.
     * @param _amount The amount to be withdrawn.
     */
    function withdrawRoboIncome(uint256 _amount) external {
        address _user = msg.sender;
        if (_amount > Details[_user].roboReward) {
            revert InvalidWithdrawalAmount();
        }

        Details[_user].roboReward -= _amount;
        IERC20(stakeToken).safeTransfer(_user, _amount);
    }

    /**
     * @notice Allows a user to withdraw their investment.
     * @dev Handles the withdrawal of the user's investment.
     * @param _amount The amount to be withdrawn.
     */
    function withdrawInvestment(uint256 _amount) external {
        address _user = msg.sender;
        if (_amount > Details[_user].totalInvestment) {
            revert InvalidWithdrawalAmount();
        }
        if (Details[_user].totalReward < Details[_user].totalInvestment) {
            revert ROINotReady();
        }

        Details[_user].totalInvestment -= _amount;
        SafeERC20.safeTransfer(IERC20(stakeToken), _user, _amount);
    }

    /**
     * Withdraw Service Charge and Company Robo Reward
     * @dev Allows the owner to withdraw service charge and company robo reward.
     */
    function withdrawServiceChargeAmountAndCompanyRoboReward(
        uint256 _serviceChargeAmount,
        uint256 _roboRewardAmount
    ) external onlyOwner {
        /**
         * @dev Checks if the requested service charge amount is valid.
         * @dev Reverts with "InvalidWithdrawalAmount" if the requested amount is greater than the available service charge.
         */
        if (_serviceChargeAmount > serviceChargeAmount) {
            revert InvalidWithdrawalAmount();
        }

        /**
         * @dev Checks if the requested robo reward amount is valid.
         * @dev Reverts with "InvalidWithdrawalAmount" if the requested amount is greater than the available company robo reward.
         */
        if (_roboRewardAmount > companyRoboRewardWallet) {
            revert InvalidWithdrawalAmount();
        }

        // Deducts the service charge and robo reward from the respective balances
        serviceChargeAmount -= _serviceChargeAmount;
        companyRoboRewardWallet -= _roboRewardAmount;

        // Transfers the deducted amounts to the owner
        SafeERC20.safeTransfer(
            IERC20(stakeToken),
            owner(),
            _serviceChargeAmount
        );
        SafeERC20.safeTransfer(IERC20(stakeToken), owner(), _roboRewardAmount);
    }

    /**
     * @notice See Investment
     * @dev Allows external callers to view the total investment of a user.
     * @param user The address of the user.
     * @return The total investment of the specified user.
     */
    function seeInvestment(address user) external view returns (uint256) {
        return Details[user].totalInvestment;
    }
}
