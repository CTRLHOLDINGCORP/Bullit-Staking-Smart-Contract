// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ITNT20.sol";
import "./IUniswapV2Pair.sol";

interface IStakingLP {
    /**
     ***
     *** Struct Definitions
     ***
     **/

    enum STATUS {
        Claimed,
        Locked,
        Unlocked
    }

    struct StakingPeriod {
        string periodName;
        uint256 duration;
        uint256 periodAPR;
    }

    struct SuperNFT {
        address smartContractAddress;
        uint256 boostingPercentage;
    }

    struct LockedNFT {
        address smartContractAddress;
        uint256 tokenID;
        uint256 unlockDate;
        string url; //Get
    }

    struct StakingRecord {
        uint256 stakedLPs;
        string stakingPeriodName;
        uint256 stakingRewards;
        uint256 APR;
        uint256 boostingPercentage;
        uint256 lockedDate;
        uint256 unlockedDate;
        address boostNFT;
        STATUS status;
    }

    struct Stakeholder {
        address stakeholderAddress;
        uint256 totalStakedLPs;
        uint256 claimedLPs;
        uint256 unlockedLPs; //Get
        uint256 totalRewards;
        uint256 claimedRewards;
        uint256 unlockedRewards; //Get
        uint256 nextUnlockDate;
        LockedNFT[] lockedNFTsList; //Get
        // mapping(address => LockedNFT) lockedNFTsList;
        StakingRecord[] stakingList;
    }

    /**
     ***
     *** User Functionalities
     ***
     **/

    function getVestingCount() external view returns (uint256 vestingCount_);
    
    function getTNT20Token() external view returns (ITNT20 tnt20Token_);

    function getLPToken() external view returns (IUniswapV2Pair lpToken_);

    function getsuperNFTList()
        external
        view
        returns (SuperNFT[] memory superNFT_);

    function getStakingDeadlineDate()
        external
        view
        returns (uint256 stakingDeadlineDate_);

    function stakeLPToken(
        uint256 _stakedLPs,
        string memory _stakingPeriodName,
        address _nftAddress
    ) external;

    function unstakeLPToken() external;

    function getStakeholderStats()
        external
        view
        returns (
            Stakeholder memory stakeholderData_,
            uint256 nftBoostingPeriod_
        );

    function getStakeholderStakingList(uint256 _pageNo, uint256 _perPage)
        external
        view
        returns (StakingRecord[] memory stakingList_);

    function getLockedNFTInfo(address _nftAddress)
        external
        view
        returns (LockedNFT memory lockedNFT_, uint256 boostingPercentage_);

    function getLockedNFTsList()
        external
        view
        returns (
            LockedNFT[] memory lockedNFTsList_,
            uint256[] memory boostingPercentagesList_
        );

    function lockNFT(address _nftAddress, uint256 _tokenID) external;

    function unlockNFT(address _nftAddress) external;

    function boostStaking(uint256 _stakingIndex, address _nftAddress) external;

    function getStakingPeriodsList()
        external
        view
        returns (StakingPeriod[] memory stakingPeriodsList_);

    function getBULTPerLP() external view returns (uint256 bultPerLP_);

    // /**
    //  ***
    //  *** Owner Functionalities
    //  ***
    //  **/

    // // Settings functionalities

    function setVestingCount(uint256 _vestingCount) external;

    function setTNT20Token(address _tnt20Address) external;

    function setLPToken(address _lpAddress) external;

    function setSuperNFT(address _NFTAddress, uint256 boostingPercentage)
        external;

    function setStakingDeadlineDate(uint256 _stakingDeadlineDate) external;

    // // Control Pannel Functionalities
    function getStakingStats()
        external
        view
        returns (
            uint256 totalStakedLPs_,
            uint256 totalDistributedRewards_,
            uint256 stakingDeadlineDate_,
            uint256 vestingStartingDate_,
            uint256 vestingDuration_,
            uint256 availableRewardsEachPeriod_,
            uint256 periodAllowedToAddNFT_
        );

    function getStakeholdersList(uint256 _pageNo, uint256 _perPage)
        external
        view
        returns (Stakeholder[] memory stakeholdersList_);

    function calculateIfCanStake(
        uint256 _stakedLPs,
        string memory _stakingPeriodName,
        address _nftAddress
    ) external view returns (bool canStake_, uint256 maxStakingRewards_, uint256 calculatedStakingRewards_);
}
