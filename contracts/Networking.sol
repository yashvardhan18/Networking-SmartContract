// SPDX-License-Identifier: MIT

/**
 * @title Networking Contract
 * @dev A contract for managing user investments, rewards, and referrals.
 */
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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
    uint256 companyRoboReward;
    uint256 public serviceChargeAmount;
    uint128 public ROIpercent;
    uint128 public maxDeposit;
    uint128 public minDeposit;
    uint256 public minWithdrawalAmount;
    uint8 flag = 0;

    // Mappings
    mapping(address => uint256) public referralIncome;
    mapping(address => UserDetails) public Details;
    mapping(uint8 => mapping(uint8 => uint128)) public packageThreshold;
    mapping(uint => uint256) roboFee;
    mapping(uint => uint256) roboLevelPercentage;
    mapping(address => bool) blacklistedUsers;

    // Errors
    error ZeroAmount();
    error ZeroAddress();
    error InvalidRank();
    error InvalidIncomePercentage();
    error InvalidReferrer();
    error BelowMinLimit();
    error InvalidLevel();
    error InvalidUser();
    error InvalidWithdrawalAmount();
    error InvalidDepositAmount();
    error UserBlackListed();

    // Events
    event depositAmount(
        address indexed user,
        address indexed referrer,
        uint256 indexed amount,
        uint256 depositTime,
        uint256 totalInvestment
    );
    event withdrawIncome(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    event withdrawnInvestment(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    event withdrawnRoboIncome(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed timestamp
    );
    event RankUpgrade(address indexed user, uint8 indexed rank);

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
        for (uint i = 0; i < _roboFee.length; i++) {
            roboFee[i] = _roboFee[i];
        }
        for (uint i = 0; i < _ranks.length; i++) {
            roboLevelPercentage[i] = _roboLevelPercentage[i];
            for (uint j = 0; j < _levels.length; j++) {
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
        if (amount < minDeposit || amount > maxDeposit) {
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
            (Details[user].roboSubscriptionPeriodStart + 15780000 <= timeNow &&
                Details[user].investmentDoubleCount == 1) ||
            Details[user].roboCount == 0
        ) {
            roboRewardDistribution(msg.sender);
        } else {
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

        emit depositAmount(
            user,
            _referrer,
            amount,
            block.timestamp,
            Details[user].totalInvestment
        );
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
        } else if (_investmentAmount <= 5000000000000) {
            fee = roboFee[6];
        }

        companyRoboReward += (fee * 7500) / 10000;

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
                rewardShares[i] =
                    (distributionAmount * getRoboLevelPercentage(i)) /
                    10000;

                distributionAmount -= rewardShares[i];
            }

            Details[referrers[i]].roboReward += rewardShares[i];
        }
        Details[_user].roboCount += 1;
        Details[_user].roboSubscriptionPeriodStart = block.timestamp;

        if (distributionAmount > 0) {
            companyRoboReward += distributionAmount;
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
    function setMinDepositAmount(uint128 _newLimit) external onlyOwner {
        minDeposit = _newLimit;
    }

    function setMaxDepositAmount(uint128 _newLimit) external onlyOwner {
        maxDeposit = _newLimit;
    }
    /**
     * @notice  Sets the percentage for a level of a rank.
     * @dev     Allows the owner to set the percentage for a level of a rank.
     * @param   rank  The rank of the network.
     * @param   level  The level of the rank.
     * @param   _income  The percentage to be set.
     */
    function setPackage(
        uint8 rank,
        uint8 level,
        uint128 _income
    ) external onlyOwner {
        if (rank < 1 || rank > 6) {
            revert InvalidRank();
        }
        if (level < 1 || level > 6) {
            revert InvalidLevel();
        }
 
        if (
            _income < packageThreshold[rank][level + 1] ||
            _income > packageThreshold[rank][level - 1]
        ) {
            revert InvalidIncomePercentage();
        }
        packageThreshold[rank][level] = _income;
    }

    function _calculateRewards(address _user) public returns (uint256 reward) {
        UserDetails storage details = Details[_user];
        uint256 time = (block.timestamp - details.depositTime) / 86400;
        uint256 TotalROI = ((Details[_user].totalInvestment *
            time *
            ROIpercent) / 10000);

        uint serviceCharge = (TotalROI * 5000) / 10000;
        reward = TotalROI - serviceCharge;
        Details[_user].totalReward += referralIncome[msg.sender] + reward;
        referralIncome[_user] = 0;

        return distributeROI(_user, serviceCharge);
    }

    // /**
    //  * @notice  Sets the rank for the Users..
    //  * @dev     Allows the owner to set the rank for the user.
    //  * @param   _user  address of the user.
    //  * @param   _newRank  new rank for the user.
    //  */
    function setRefferersRank(address _user, uint8 _newRank) external onlyOwner{
    
    if(_user == address(0)){
        revert ZeroAddress();
    }

    if(_newRank <=0 || _newRank >6){
        revert  InvalidRank();
    }

        Details[_user].rank = _newRank;
    }

    /**
     * @notice Sets the ROI percentage for the network.
     * @dev Allows the owner to set the ROI percentage for the network.
     * @param _percent The new ROI percentage.
     */

    function setROIPercentage(uint128 _percent) external onlyOwner {
        if (_percent == 0) {
            revert ZeroAmount();
        }
        ROIpercent = _percent;
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
     */
    function withdrawReward() external {
        if(blacklistedUsers[msg.sender]){
            revert UserBlackListed();
        }
        address _user = msg.sender;
        UserDetails storage details = Details[msg.sender];
        _calculateRewards(msg.sender);

        uint RoiAmount = details.totalReward;
        uint RoboReward = details.roboReward;
        if (RoiAmount+RoboReward < minWithdrawalAmount) {
            revert InvalidWithdrawalAmount();
        }

        details.depositTime = block.timestamp;

        details.withdrawedReward += details.totalReward + details.roboReward;
        details.totalReward = 0;
        details.roboReward = 0;


        IERC20(stakeToken).safeTransfer(_user, RoiAmount);
        IERC20(stakeToken).safeTransfer(_user, RoboReward);

        emit withdrawIncome(_user, RoiAmount, block.timestamp);
        emit withdrawnRoboIncome(_user, RoboReward, block.timestamp);
    }

    // /**
    //  * @notice Allows a user to withdraw their robo income.
    //  * @dev Handles the withdrawal of robo income for a user.
    //  * @param _amount The amount to be withdrawn.
    //  */
    // function withdrawRoboIncome(uint256 _amount) external {
    //     address _user = msg.sender;

    //     if (_amount > Details[_user].roboReward) {
    //         revert InvalidWithdrawalAmount();
    //     }

    //     Details[_user].roboReward -= _amount;
    //     IERC20(stakeToken).safeTransfer(_user, _amount);

    //     emit withdrawnRoboIncome(_user, _amount, block.timestamp);
    // }

    /**
     * @notice Allows a user to withdraw their investment.
     * @dev Handles the withdrawal of the user's investment.
     */
    function withdrawInvestment() external {
        address _user = msg.sender;
        if (Details[_user].totalInvestment == 0) {
            revert InvalidUser();
        }
        _calculateRewards(_user);
        uint _investmentAmount = Details[_user].totalInvestment;
        if (block.timestamp < Details[_user].depositTime + (_investmentAmount / ROIpercent)) {
            uint256 preMatureFine = (Details[_user].totalInvestment * 3000) /
                10000;
            _investmentAmount -= preMatureFine;
            blacklistedUsers[msg.sender] = true;
        }

        Details[_user].totalInvestment = 0;
        Details[_user].roboSubscriptionPeriodStart = 0;
        SafeERC20.safeTransfer(IERC20(stakeToken), _user, _investmentAmount);

        emit withdrawnInvestment(_user, _investmentAmount, block.timestamp);
    }

    /**
     * Withdraw Service Charge and Company Robo Reward
     * @dev Allows the owner to withdraw service charge and company robo reward.
     */
    function withdrawServiceChargeAmountAndCompanyRoboReward() external onlyOwner {

        // Transfers the deducted amounts to the owner
        SafeERC20.safeTransfer(
            IERC20(stakeToken),
            owner(),
            serviceChargeAmount
        );
        SafeERC20.safeTransfer(IERC20(stakeToken), owner(), companyRoboReward);
    }

    /**
     * @notice See Investment
     * @dev Allows external callers to view the total investment of a user.
     * @param user The address of the user.
     * @return The total investment of the specified user.
     */
    function seeInvestment(address user) external view returns (uint256) {
        if (msg.sender != user) {
            revert InvalidUser();
        }
        return Details[user].totalInvestment;
    }

    /**
     * @notice  See total ROI amount
     * @dev     Allows users to view the total reward amount of the user.
     * @param   user  .
     * @return  uint256  .
     */
    function TotalReferralIncome(address user) external view returns (uint256) {
        if (msg.sender != user) {
            revert InvalidUser();
        }
        return referralIncome[user];
    }

        /**
     * @notice  See total ROI amount
     * @dev     Allows users to view the total reward amount of the user.
     * @param   _user  .
     * @return  uint256.
     */
    function TotalROIIncome(address _user) public view returns (uint256 ) {

        UserDetails storage details = Details[_user];
        uint256 time = (block.timestamp - details.depositTime) / 86400;
        return ((Details[_user].totalInvestment *
            time *
            ROIpercent) / 10000);
    }
    /**
     * @notice  See total reward amount
     * @dev     Allows users to view the total reward amount of the user.
     * @param   _user  .
     * @return  uint256  .
     */
    function Totalreward(address _user) external view returns (uint256) {

        
        return (TotalROIIncome(_user) + Details[_user].roboReward);
    }

    /**
     * @notice  See total robo reward amount
     * @dev     Allows users to view the total robo reward amount of the user.
     * @param   user  .
     * @return  uint256  .
     */
    function RoboIncome(address user) external view returns (uint256) {
        if (msg.sender != user) {
            revert InvalidUser();
        }
        return Details[user].roboReward;
    }

    /**
     * @notice  See total robo reward amount
     * @dev  Allows users to view the total robo reward amount of the user.
     * @return  uint256  .
     */
    function CompanyRoboAndServiceChargeIncome()
        external
        view
        returns (uint256, uint256)
    {
        if (msg.sender != owner()) {
            revert InvalidUser();
        }
        return (companyRoboReward, serviceChargeAmount);
    }
}
