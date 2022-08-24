// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/ITNT20.sol";
import "./interfaces/TNT721/ITNT721.sol";
import "./interfaces/TNT721/ITNT721Enumerable.sol";
import "./interfaces/TNT721/ITNT721Metadata.sol";
import "./interfaces/IStakingLP.sol";

contract LPStaking is Ownable, IStakingLP {
    ITNT20 private token;
    IUniswapV2Pair private BULT_TFUEL_LP;

    uint256 private totalDistributedRewards;
    uint256 public totalReservedRewards;
    uint256 public stakingStartDate;
    uint256 private stakingDeadlineDate;
    uint256 private vestingEffectiveDate;
    uint256 private vestingDuration;
    uint256 private availableRewardsEachPeriod;
    uint256 private nftBoostingPeriod;
    uint256 private constant numberOfSecondsIn12Months = (30 days) * 12;
    uint256 private vestingCount = 24;
    uint256[] public owedStakingRewards = new uint256[](4);
    uint256 private initialVestingCount;
    address private feesAddress;
    uint256 private feesPercentage = ((2 * 10**16) /  100);

    address[] public superNFTsList;
    mapping(address => SuperNFT) public superNFTsMap;

    address[] stakeholderList;
    mapping(address => Stakeholder) public stakeholdersMap;

    mapping(address => mapping(address => LockedNFT)) stakeholdersLockedNFTs;

    string[] stakingPeriodList;
    mapping(string => StakingPeriod) public stakingPeriodMap;

    constructor(
        uint256 _stakingStartDate,
        uint256 _stakingDeadlineDate,
        uint256 _vestingDuration,
        uint256 _availableRewardsEachPeriod,
        address _token,
        address _BULT_TFUEL_LP
    ) {
        BULT_TFUEL_LP = IUniswapV2Pair(_BULT_TFUEL_LP);
        token = ITNT20(_token);

        stakingStartDate = _stakingStartDate;
        stakingDeadlineDate = _stakingDeadlineDate;
        vestingDuration = _vestingDuration;
        availableRewardsEachPeriod = _availableRewardsEachPeriod;

        vestingEffectiveDate = 1652140800; // 10-05-2022
        nftBoostingPeriod = 7 days;

        initialVestingCount = ((stakingStartDate - vestingEffectiveDate) / vestingDuration) - 1;

        stakingPeriodMap["3 months"] = StakingPeriod("3 months", 30 days * 3, 30);
        stakingPeriodList.push("3 months");

        stakingPeriodMap["6 months"] = StakingPeriod("6 months", 30 days * 6, 55);
        stakingPeriodList.push("6 months");

        stakingPeriodMap["9 months"] = StakingPeriod("9 months", 30 days * 9, 70);
        stakingPeriodList.push("9 months");

        stakingPeriodMap["12 months"] = StakingPeriod("12 months", 30 days * 12, 85);
        stakingPeriodList.push("12 months");
    }

    //----------------------Start modifier----------------------
    modifier isSenderAddressNonZero() {
        require(msg.sender != address(0x0), "Zero address not Allowed");
        _;
    }

    //----------------------End modifier----------------------

    //----------------------Start LPs functionalities----------------------

    function getTotalBULTInLPs() internal view returns (uint256 totalBULT_) {
        (, uint256 totalBultToken, ) = BULT_TFUEL_LP.getReserves();
        return totalBultToken;
    }

    function getBULTPerLP() public view override returns (uint256 bultPerLP_) {
        return
            (getTotalBULTInLPs() * 10**BULT_TFUEL_LP.decimals()) /
            BULT_TFUEL_LP.totalSupply();
    }

    //----------------------End LPs functionalities----------------------

    //----------------------Start Control Pannel Functionalities----------------------

    function setFeesAddress(address _feesAddress) external onlyOwner {
        require(msg.sender != address(0x0), "Fees Address cannot be zero address");
        feesAddress = _feesAddress;
    }

    function getFeesAddress() external onlyOwner view returns (address feesAddress_){
        return feesAddress;
    }

    function getStakingStats()
        external
        view
        onlyOwner
        returns (
            uint256 totalStakedLPs_,
            uint256 totalDistributedRewards_,
            uint256 stakingDeadlineDate_,
            uint256 vestingStartingDate_,
            uint256 vestingDuration_,
            uint256 availableRewardsEachPeriod_,
            uint256 nftBoostingPeriod_
        )
    {
        totalStakedLPs_ = BULT_TFUEL_LP.balanceOf(address(this));

        return (
            totalStakedLPs_,
            totalDistributedRewards,
            stakingDeadlineDate,
            vestingEffectiveDate,
            vestingDuration,
            availableRewardsEachPeriod,
            nftBoostingPeriod
        );
    }

    function getStakeholdersList(uint256 _pageNo, uint256 _perPage)
        external
        view
        onlyOwner
        returns (Stakeholder[] memory stakeholdersList_)
    {
        require(
            (_pageNo * _perPage) <= stakeholderList.length, // BUG Here
            "Page is Out of Range"
        );
        uint256 no_stakeholders = (stakeholderList.length -
            (_pageNo * _perPage)) < _perPage
            ? (stakeholderList.length - (_pageNo * _perPage))
            : _perPage;
        Stakeholder[] memory stakeholders = new Stakeholder[](no_stakeholders);

        for (uint256 i = 0; i < stakeholders.length; i++) {
            stakeholders[i] = stakeholdersMap[
                stakeholderList[(_pageNo * _perPage) + i]
            ];
        }

        return (stakeholders);
    }

    //----------------------End Control Pannel Functionalities----------------------

    //----------------------Start Settings Functionalities----------------------

    function getVestingCount() external view returns (uint256 vestingCount_) {
        return vestingCount;
    }

    function setVestingCount(uint256 _vestingCount) external onlyOwner {
        require(_vestingCount != 0, "Vesting Count should be greater than zero");
        uint256 currentVestingCount = (block.timestamp - vestingEffectiveDate) / vestingDuration;
        require(_vestingCount > currentVestingCount, "Cannot insert vesting count in the Past");
        vestingCount = _vestingCount;
    }

    function getTNT20Token() external view returns (ITNT20 tnt20Token_) {
        return token;
    }

    function setTNT20Token(address _tnt20Address) external onlyOwner {
        require(_tnt20Address != address(0x0), "Token Address cannot be zero address");
        token = ITNT20(_tnt20Address);
    }

    function getLPToken() external view returns (IUniswapV2Pair lpToken_) {
        return BULT_TFUEL_LP;
    }

    function setLPToken(address _lpAddress) external onlyOwner {
        require(_lpAddress != address(0x0), "LP Token Address cannot be zero address");
        BULT_TFUEL_LP = IUniswapV2Pair(_lpAddress);
    }

    function getsuperNFTList()
        external view returns (SuperNFT[] memory superNFT_)
    {
        superNFT_ = new SuperNFT[](superNFTsList.length);
        for (uint256 i = 0; i < superNFTsList.length; i++)
            superNFT_[i] = superNFTsMap[superNFTsList[i]];

        return superNFT_;
    }

    function setSuperNFT(address _NFTAddress, uint256 _boostingPercentage)
        external onlyOwner
    {
        require(_NFTAddress != address(0x0), "NFT Address cannot be zero address");
        require(_boostingPercentage > 0, "The boosting percentage must be greater than zero");

        if (superNFTsMap[_NFTAddress].smartContractAddress == address(0x0)) {
            superNFTsMap[_NFTAddress] = SuperNFT(_NFTAddress, _boostingPercentage);
            superNFTsList.push(_NFTAddress);
        } else {
            superNFTsMap[_NFTAddress].boostingPercentage = _boostingPercentage;
        }
    }

    function getStakingDeadlineDate()
        external view returns (uint256 stakingDeadlineDate_)
    {
        return stakingDeadlineDate;
    }

    function setStakingDeadlineDate(uint256 _stakingDeadlineDate)
        external onlyOwner
    {
        require(
            _stakingDeadlineDate > block.timestamp,
            "The staking deadline date must be greater than now"
        );
        stakingDeadlineDate = _stakingDeadlineDate;
    }

    //----------------------End Settings Functionalities----------------------

    //----------------------Start User Functionalities----------------------

    function stakeLPToken(
        uint256 _stakedLPs,
        string memory _stakingPeriodName,
        address _nftAddress
    ) external isSenderAddressNonZero {
        require(_stakedLPs > 0, "Stake amount must be greater then zero");
        require(BULT_TFUEL_LP.balanceOf(msg.sender) >= _stakedLPs, "Insufficient available LP tokens");
        require(BULT_TFUEL_LP.allowance(msg.sender, address(this)) >= _stakedLPs, "The transfer of the amount must be approved first");
        require(bytes(stakingPeriodMap[_stakingPeriodName].periodName).length > 0, "Invalid Staking Period");
        require(block.timestamp <= stakingDeadlineDate, "Staking period is over");

        uint256 stakingUnlockDate = block.timestamp + stakingPeriodMap[_stakingPeriodName].duration;

        if (stakeholdersLockedNFTs[msg.sender][_nftAddress].smartContractAddress != address(0x0)){
            if (stakeholdersLockedNFTs[msg.sender][_nftAddress].unlockDate < stakingUnlockDate) {
                stakeholdersLockedNFTs[msg.sender][_nftAddress].unlockDate = stakingUnlockDate;
            }
        } 

        (bool canStake, , uint256 stakingRewards) = calculateIfCanStake(_stakedLPs, _stakingPeriodName, _nftAddress);

        require(canStake, "Insuffecient Staking Rewards For This Period");

        if (stakeholdersMap[msg.sender].stakeholderAddress == address(0x0)) {
            stakeholdersMap[msg.sender].stakeholderAddress = msg.sender;
            stakeholderList.push(msg.sender);
        }

        stakeholdersMap[msg.sender].totalRewards += stakingRewards;
        stakeholdersMap[msg.sender].totalStakedLPs += _stakedLPs;
        stakeholdersMap[msg.sender].stakingList.push(
            StakingRecord(
                _stakedLPs,
                _stakingPeriodName,
                stakingRewards,
                stakingPeriodMap[_stakingPeriodName].periodAPR,
                superNFTsMap[stakeholdersLockedNFTs[msg.sender][_nftAddress].smartContractAddress].boostingPercentage,
                block.timestamp,
                stakingUnlockDate,
                stakeholdersLockedNFTs[msg.sender][_nftAddress].smartContractAddress,
                STATUS.Locked
            )
        );

        BULT_TFUEL_LP.transferFrom(msg.sender, address(this), _stakedLPs);
        owedStakingRewards[syncOwedStakingRewardArray(stakingUnlockDate) - 1] += stakingRewards;
        totalReservedRewards += stakingRewards;
    }

    function syncOwedStakingRewardArray(uint256 _stakingUnlockDate) internal returns (uint256 owedBlock){
        uint256 owedBlockCount = ((_stakingUnlockDate - stakingStartDate) / vestingDuration) + 1;
        for (uint256 i = owedStakingRewards.length; i < owedBlockCount; i++)
            owedStakingRewards.push(0);
        return owedBlockCount;
    }

    function calculateIfCanStake(
        uint256 _stakedLPs,
        string memory _stakingPeriodName,
        address _nftAddress
    ) public view returns (bool canStake_, uint256 maxStakingRewards_, uint256 calculatedStakingRewards_) {
        if (bytes(stakingPeriodMap[_stakingPeriodName].periodName).length == 0)
            return (false, 0, 0);

        uint256 stakingRewards = calculateStakingReward(
            _stakedLPs,
            stakingPeriodMap[_stakingPeriodName].periodAPR,
            superNFTsMap[_nftAddress].boostingPercentage,
            stakingPeriodMap[_stakingPeriodName].duration
        );

        uint256 owedBlockCount = (((block.timestamp +
            stakingPeriodMap[_stakingPeriodName].duration) - stakingStartDate) /
            vestingDuration) + 1;

        uint256 maxStakingRewards = getMaxStakingRewards(owedBlockCount);

        return (maxStakingRewards > stakingRewards, maxStakingRewards, stakingRewards);
    }

    function getMaxStakingRewards(uint256 _owedBlockNumber) internal view returns (uint256 maxStakingRewards_){
               
        uint256 totalOwed = 0;
        uint256 totalVesting = 0;
        uint256 currentavailableStaking = 0;
        
        uint owerBlockNumberLength = _owedBlockNumber > owedStakingRewards.length ? owedStakingRewards.length : _owedBlockNumber;
        for(uint256 i = 0; i < owerBlockNumberLength; i++){
            totalOwed += owedStakingRewards[i];
        }

        totalVesting = ((_owedBlockNumber + initialVestingCount > vestingCount ? vestingCount : _owedBlockNumber + initialVestingCount) ) * availableRewardsEachPeriod;  
        maxStakingRewards_ = totalVesting - totalOwed;

        for(uint256 i = _owedBlockNumber; i < owedStakingRewards.length; i++)
            if(owedStakingRewards[i] != 0){
                totalOwed += owedStakingRewards[i];
                totalVesting = ((i + 1 + initialVestingCount) > vestingCount ? vestingCount : (i + 1 + initialVestingCount)) * availableRewardsEachPeriod;
                currentavailableStaking = totalVesting - totalOwed;

                if(maxStakingRewards_ > currentavailableStaking)
                    maxStakingRewards_ = currentavailableStaking;
            }

        return maxStakingRewards_;
    }

    function unstakeLPToken() external isSenderAddressNonZero {
        uint256 totalClaimedRewards;
        uint256 totalClaimedLPs;

        for (uint256 i = 0; i < stakeholdersMap[msg.sender].stakingList.length;i++) {
            if (stakeholdersMap[msg.sender].stakingList[i].unlockedDate <= block.timestamp &&
                stakeholdersMap[msg.sender].stakingList[i].status != STATUS.Claimed
            ) {
                totalClaimedRewards += stakeholdersMap[msg.sender].stakingList[i].stakingRewards;
                totalClaimedLPs += stakeholdersMap[msg.sender].stakingList[i].stakedLPs;
                stakeholdersMap[msg.sender].stakingList[i].status = STATUS.Claimed;
            }
        }

        if (totalClaimedRewards > 0) {
            uint feesAmount = (totalClaimedRewards * feesPercentage) / 10**16;
            token.transfer(msg.sender, totalClaimedRewards - feesAmount);
            token.transfer(feesAddress, feesAmount);

            BULT_TFUEL_LP.transfer(msg.sender, totalClaimedLPs);
            stakeholdersMap[msg.sender].claimedLPs += totalClaimedLPs;
            stakeholdersMap[msg.sender].claimedRewards += totalClaimedRewards;
            totalDistributedRewards += totalClaimedRewards;
        }
    }

    function getStakeholderStats()
        public view
        returns (Stakeholder memory stakeholderData_,uint256 nftBoostingPeriod_)
    {
        stakeholderData_ = stakeholdersMap[msg.sender];

        uint256 nextUnlockDate = 2**256 - 1;

        for (uint256 i = 0; i < stakeholdersMap[msg.sender].stakingList.length; i++) {
            if (nextUnlockDate >= stakeholdersMap[msg.sender].stakingList[i].unlockedDate &&
                block.timestamp <= stakeholdersMap[msg.sender].stakingList[i].unlockedDate)
                nextUnlockDate = stakeholdersMap[msg.sender].stakingList[i].unlockedDate;

            if (block.timestamp >= stakeholdersMap[msg.sender].stakingList[i].unlockedDate &&
                stakeholdersMap[msg.sender].stakingList[i].status != STATUS.Claimed) {
                stakeholderData_.unlockedLPs += stakeholdersMap[msg.sender].stakingList[i].stakedLPs;
                stakeholderData_.unlockedRewards += stakeholdersMap[msg.sender].stakingList[i].stakingRewards;
                stakeholderData_.stakingList[i].status = STATUS.Unlocked;
            }
        }

        stakeholderData_.nextUnlockDate = nextUnlockDate == 2**256 - 1 ? 0 : nextUnlockDate;

        stakeholderData_.lockedNFTsList = new LockedNFT[](superNFTsList.length);
        for (uint256 i = 0; i < superNFTsList.length; i++)
            stakeholderData_.lockedNFTsList[i] = stakeholdersLockedNFTs[msg.sender][superNFTsList[i]];

        return (stakeholderData_, nftBoostingPeriod); // What is nftBoostingPeriod
    }

    function getStakeholderStakingList(uint256 _pageNo, uint256 _perPage)
        external view returns (StakingRecord[] memory stakingList_)
    {
        require((_pageNo * _perPage) <= stakeholdersMap[msg.sender].stakingList.length,"Page is Out of Range");

        uint256 no_stakings = (stakeholdersMap[msg.sender].stakingList.length - (_pageNo * _perPage)) < _perPage
            ? (stakeholdersMap[msg.sender].stakingList.length - (_pageNo * _perPage)) : _perPage;
        stakingList_ = new StakingRecord[](no_stakings);

        for (uint256 i = 0; i < stakingList_.length; i++) {
            stakingList_[i] = stakeholdersMap[msg.sender].stakingList[(_pageNo * _perPage) + i];
            if (block.timestamp >= stakeholdersMap[msg.sender].stakingList[i].unlockedDate &&
                stakeholdersMap[msg.sender].stakingList[i].status != STATUS.Claimed)
                stakingList_[i].status = STATUS.Unlocked;
        }

        return stakingList_;
    }

    function getLockedNFTInfo(address _nftAddress)
        external view returns (LockedNFT memory lockedNFT_, uint256 boostingPercentage_)
    {
        require(superNFTsMap[_nftAddress].smartContractAddress != address(0x0), "The NFt address not supported");
        return (stakeholdersLockedNFTs[msg.sender][_nftAddress],superNFTsMap[_nftAddress].boostingPercentage);
    }

    function getLockedNFTsList() external view 
        returns (LockedNFT[] memory lockedNFTsList_, uint256[] memory boostingPercentagesList_)
    {
        boostingPercentagesList_ = new uint256[](superNFTsList.length);
        lockedNFTsList_ = new LockedNFT[](superNFTsList.length);
        for (uint256 i = 0; i < superNFTsList.length; i++) {
            lockedNFTsList_[i] = stakeholdersLockedNFTs[msg.sender][superNFTsList[i]];
            boostingPercentagesList_[i] = superNFTsMap[superNFTsList[i]].boostingPercentage;
        }

        return (lockedNFTsList_, boostingPercentagesList_);
    }

    function lockNFT(address _nftAddress, uint256 _tokenID)
        external isSenderAddressNonZero
    {
        require(_nftAddress != address(0x0), "NFT Address cannt be address zero");
        require(superNFTsMap[_nftAddress].smartContractAddress != address(0x0), "The NFt address is not supported");
        require(ITNT721Enumerable(_nftAddress).ownerOf(_tokenID) == msg.sender, "You are not the owner of the NFT");
        require(ITNT721(_nftAddress).getApproved(_tokenID) == address(this), "You must give us approval on NFT");
        require(stakeholdersLockedNFTs[msg.sender][_nftAddress].smartContractAddress == address(0x0), "NFT is already Locked");

        string memory url = ITNT721Metadata(_nftAddress).tokenURI(_tokenID);

        stakeholdersLockedNFTs[msg.sender][_nftAddress] =
            LockedNFT(_nftAddress, _tokenID, 0, url);

        ITNT721(_nftAddress).transferFrom(msg.sender, address(this), _tokenID);
    }

    function unlockNFT(address _nftAddress)
        external isSenderAddressNonZero
    {
        require(_nftAddress != address(0x0), "NFT Address cannt be address zero");
        require(stakeholdersLockedNFTs[msg.sender][_nftAddress].smartContractAddress != address(0x0), "The NFT not locked");
        require(stakeholdersLockedNFTs[msg.sender][_nftAddress].unlockDate <= block.timestamp, "You cannot unlock the NFT because the lock period has not expired");

        ITNT721(_nftAddress).transferFrom(address(this), msg.sender, stakeholdersLockedNFTs[msg.sender][_nftAddress].tokenID);

        delete stakeholdersLockedNFTs[msg.sender][_nftAddress];
    }

    function boostStaking(uint256 _stakingIndex, address _nftAddress)
        external isSenderAddressNonZero
    {
        require(_stakingIndex >= 0 && _stakingIndex < stakeholdersMap[msg.sender].stakingList.length, "Invalid Staking Index");
        require(_nftAddress != address(0x0), "NFT Address cannot be address zero");
        require(stakeholdersLockedNFTs[msg.sender][_nftAddress].smartContractAddress != address(0x0), "The NFT not locked");
        require(stakeholdersMap[msg.sender].stakingList[_stakingIndex].lockedDate + nftBoostingPeriod >= block.timestamp, "Staked LPs cannot be Boosted");

        uint256 unlockedDate = stakeholdersMap[msg.sender].stakingList[_stakingIndex].unlockedDate;
        uint256 stakedLPs = stakeholdersMap[msg.sender].stakingList[_stakingIndex].stakedLPs;
        uint256 boostingPercentage = superNFTsMap[_nftAddress].boostingPercentage;

        (bool canStake, , uint256 stakingRewards) = 
            calculateIfCanStake(stakedLPs, stakeholdersMap[msg.sender].stakingList[_stakingIndex].stakingPeriodName, _nftAddress);

        require(canStake, "Not enough tokens this month");

        stakeholdersMap[msg.sender].stakingList[_stakingIndex].boostingPercentage = boostingPercentage;
        stakeholdersMap[msg.sender].stakingList[_stakingIndex].stakingRewards = stakingRewards;
        stakeholdersMap[msg.sender].stakingList[_stakingIndex].boostNFT = _nftAddress;
        stakeholdersMap[msg.sender].totalRewards += stakingRewards -stakeholdersMap[msg.sender].stakingList[_stakingIndex].stakingRewards;

        if (stakeholdersLockedNFTs[msg.sender][_nftAddress].unlockDate < unlockedDate)
            stakeholdersLockedNFTs[msg.sender][_nftAddress].unlockDate = unlockedDate;
    }

    function calculateStakingReward(
        uint256 _stakedLPs,
        uint256 _stakingPeriodApr,
        uint256 _boostingPercentage,
        uint256 _duration
    ) internal view returns (uint256) {
        return
            ((_stakedLPs * getBULTPerLP() * (((_stakingPeriodApr + _boostingPercentage) * 10**token.decimals()) / 100) *2) /
                ((numberOfSecondsIn12Months * 10**token.decimals()) / _duration)) / 10**BULT_TFUEL_LP.decimals();
    }

    function getStakingPeriodsList()
        external view returns (StakingPeriod[] memory stakingPeriodsList_)
    {
        stakingPeriodsList_ = new StakingPeriod[](stakingPeriodList.length);
        for (uint256 i = 0; i < stakingPeriodList.length; i++)
            stakingPeriodsList_[i] = stakingPeriodMap[stakingPeriodList[i]];
        return stakingPeriodsList_;
    }

    //----------------------End User Functionalities----------------------
}
