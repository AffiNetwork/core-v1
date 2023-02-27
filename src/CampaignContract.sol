// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "forge-std/Test.sol";

/*
 █████╗ ███████╗███████╗██╗███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
██╔══██╗██╔════╝██╔════╝██║████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
███████║█████╗  █████╗  ██║██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
██╔══██║██╔══╝  ██╔══╝  ██║██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
██║  ██║██║     ██║     ██║██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝

V1.0.0                                                                                                                                                    
 */

contract CampaignContract {
    // using SafeERC20 for ERC20;
    using SafeTransferLib for ERC20;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // Address of the campaign owner
    address public immutable owner;

    // Address of Affi robot that pays the parties
    address public constant RoboAffi =
        0x976EA74026E726554dB657fA54763abd0C3a0aa9;
    // affi network multi-sig treasury
    address public constant AffiTreasury =
        0x2f66c75A001Ba71ccb135934F48d844b46454543;

    // campaign structure
    struct Campaign {
        uint256 id;
        uint256 startTime;
        uint256 endDate;
        address contractAddress;
        address creatorAddress;
        string network;
        uint256 publisherShare;
        uint256 costOfAcquisition;
    }

    // campaign tracking
    Campaign public campaign;
    // keeps total publisher for current campaign
    uint256 public totalPublishers;
    // keep the total shares waiting to be withdraw
    uint256 public totalPendingShares;
    // keeps track of total shares released
    uint256 public totalReleasedShares;
    // total protocol fees collected
    uint256 public totalFees;
    // keeps track of total deposits made
    uint256 public totalDeposits;
    // keeps publishers for this campaign
    mapping(address => bool) public publishers;
    // keeps share for each publisher or buyer for withdraw
    mapping(address => uint256) public shares;
    // ERC-20 token used for payment
    ERC20 public immutable paymentToken;

    // =============================================================
    //                            ERRORS
    // =============================================================

    // Not the campaign owner
    error notOwner();
    // operation requires Affi Robot
    error notAffiRobot();
    // can not withdraw yet
    error withdrawTooEarly();
    // campaigns need to be at least 30 days
    error campaignDurationTooShort();
    // can not participate in your own campaign
    error ownerCantParticipate();
    // participate one per address
    error alreadyRegistered();
    // not enough money in pool
    error notEnoughFunds();
    // minimal cost of acquisition paid is $1
    error costOfAcquisitionNeedTobeAtLeastOne();
    // user does not have any share to withdraw
    error noShareAvailable();
    // participation is close
    error participationClose();
    // pool size must be bigger than COA
    error poolSizeShouldBeBiggerThanCOA();
    // campaign is inActive
    error CampaignIsInActive();
    // can only increase COA
    error COAisSmallerThanPrevious();
    // can only increase time
    error timeIsSmallerThanPrevious();
    // can not make a deal if campaign duration is over
    error CampaignIsClosed();

    // =============================================================
    //                            EVENTS
    // =============================================================

    // campaign pool is funded
    event CampaignFunded(
        uint256 indexed id,
        address indexed campaignAddress,
        uint256 funds
    );
    event PublisherRegistered(address indexed publisher);

    // called by Robo Affi
    event DealSealed(
        address indexed publisher,
        address indexed buyer,
        uint256 commission,
        uint256 cashback,
        uint256 affiShare
    );

    // pool is drained or lock-time is passed
    event CampaignClosed(uint256 indexed id, address indexed campaignAddress);

    // party withdraws share
    event ShareReleased(uint256 amount, address indexed receiver);

    // =============================================================
    //                            MODIFIERS
    // =============================================================

    modifier isOwner() {
        if (msg.sender != owner) revert notOwner();
        _;
    }

    modifier isRoboAffi() {
        if (msg.sender != RoboAffi) revert notAffiRobot();
        _;
    }

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    /**
    @dev  the campaign is not opened till is funded by stable coins 
          as it also requires approval.
     */
    constructor(
        uint256 _id,
        uint256 _endDate,
        address _contractAddress,
        address _creatorAddress,
        address _paymentTokenAddress,
        string memory _network,
        uint256 _publisherShare,
        uint256 _costOfAcquisition
    ) {
        owner = _creatorAddress;

        if (!(_endDate >= block.timestamp + 30 days))
            revert campaignDurationTooShort();

        // stablecoin
        paymentToken = ERC20(_paymentTokenAddress);

        if (!(_costOfAcquisition >= (1 * 10**getPaymentTokenDecimals())))
            revert costOfAcquisitionNeedTobeAtLeastOne();

        campaign.id = _id;
        campaign.startTime = block.timestamp;
        campaign.endDate = _endDate;
        campaign.contractAddress = _contractAddress;
        campaign.creatorAddress = _creatorAddress;
        campaign.network = _network;
        campaign.publisherShare = _publisherShare;
        campaign.costOfAcquisition = _costOfAcquisition;
    }

    // =============================================================
    //                          OPERATIONS
    // =============================================================

    /** 
    @notice Fund campaign with paymentToken. (DAI or USDC)
    @dev  after the campaign is successfully funded, the campaign is officially open.
    */
    function fundCampaignPool(uint256 _funds) external isOwner {
        if (_funds < (100 * campaign.costOfAcquisition))
            revert poolSizeShouldBeBiggerThanCOA();

        totalDeposits += _funds;
        paymentToken.safeTransferFrom(owner, address(this), _funds);

        emit CampaignFunded(campaign.id, address(this), _funds);
    }

    /**
      @dev top-up an open campaign with more funds
     */
    function increasePoolBudget(uint256 _funds) external isOwner {
        totalDeposits += _funds;
        paymentToken.safeTransferFrom(owner, address(this), _funds);

        // emit same event as funding
        emit CampaignFunded(campaign.id, address(this), _funds);
    }

    /**
     @dev owner can increase costOfAcquisition but not decrease it.
         it require to have enough funds for the new COA.
     */
    function increaseCOA(uint256 _coa) external isOwner {
        // check if campaign is still parrticipating need to call increasePoolBudget first
        if (!isCampaignActive()) revert CampaignIsInActive();

        // can only increase COA
        if (_coa < campaign.costOfAcquisition)
            revert COAisSmallerThanPrevious();

        campaign.costOfAcquisition = _coa;
    }

    /**
    @dev  increase the campaign end date by _timestamp.
          it should be at least 1 day from now.
     */
    function increaseTime(uint256 _timestamp) external isOwner {
        // check if campaign is still parrticipating
        if (!isCampaignActive()) revert CampaignIsInActive();
        // need to be at least 1 day from now
        if (_timestamp <= block.timestamp + 1 days)
            revert campaignDurationTooShort();

        // can only increase time
        if (_timestamp <= campaign.endDate) revert timeIsSmallerThanPrevious();

        campaign.endDate = _timestamp;
    }

    /**
        @dev if the campaign time is ended, the campaign creator can take their left-over tokens 
         back.
     */
    function withdrawFromCampaignPool() external isOwner {
        // campaign should be closed
        if (isCampaignOpen()) revert withdrawTooEarly();

        // owner can only withdraw  left-over funds

        uint256 availableForWithdraw = totalDeposits -
            (totalPendingShares + totalReleasedShares + totalFees);

        // decrease totalDeposits
        totalDeposits -= availableForWithdraw;

        // transfer left-over funds to owner
        paymentToken.safeTransfer(owner, availableForWithdraw);

        emit CampaignClosed(campaign.id, address(this));
    }

    /**
        @dev Allows participate to register their wallet with the campaign.
         We write the URL generator by our URL generator (off-chain) along with their address to the campaign. 
     */
    function participate() external {
        if (msg.sender == owner) revert ownerCantParticipate();
        if (block.timestamp >= campaign.endDate) revert participationClose();
        if (publishers[msg.sender]) revert alreadyRegistered();

        publishers[msg.sender] = true;

        // update total publishers
        totalPublishers++;

        emit PublisherRegistered(msg.sender);
    }

    /**
    @dev  Used by both publisher and buyer to withdraw their share.
     */
    function releaseShare() external {
        if (shares[msg.sender] == 0) revert noShareAvailable();

        uint256 shareForRelease = shares[msg.sender];
        // decrease pending shares
        totalPendingShares -= shareForRelease;
        // increase total shares released
        totalReleasedShares += shareForRelease;
        // reset state
        shares[msg.sender] = 0;
        // transfer
        paymentToken.safeTransfer(msg.sender, shareForRelease);

        emit ShareReleased(shareForRelease, msg.sender);
    }

    /**
    @dev  returns true if the campaign is open by checking the end date.
     */
    function isCampaignOpen() public view returns (bool) {
        if (campaign.endDate >= block.timestamp) {
            return true;
        }
        return false;
    }

    /**
    @dev  return true if there is enough funds to pay for at least one COA.
     */
    function isCampaignActive() public view returns (bool) {
        // tD - (tR + tP +tF)  >= coa
        // calculate the balance left considering the total released and pending shares
        // if so it means campaign is still participating and can be increased or extended
        if (
            totalDeposits -
                (totalReleasedShares + totalPendingShares + totalFees) >=
            campaign.costOfAcquisition
        ) {
            return true;
        }
        return false;
    }

    // =============================================================
    //                     ROBOAFFI OPERATIONS
    // =============================================================

    /**
    @dev This function is called automatically by Robo Affi,
    it allows all parties to receive their share after a sale.
    it send Affi network fees to the Affi network treasury and the rest to the publisher and buyer.
    to keep transparency of deals we write the deal details on-chain.
     */
    function sealADeal(
        address _publisher,
        address _buyer,
        uint256 amount
    ) external isRoboAffi {
        // Robo Affi only  can only make deals for active campaigns
        if (!isCampaignOpen()) revert CampaignIsClosed();

        // check if there is enough funds to pay for the all deals or nothing
        //  tD- (tR + tP + tF) < (amount * coa)
        if (
            totalDeposits -
                (totalReleasedShares + totalPendingShares + totalFees) <
            (amount * campaign.costOfAcquisition)
        ) {
            revert notEnoughFunds();
        }

        // campaign details
        uint256 coa = campaign.costOfAcquisition;
        uint256 publisherShare = campaign.publisherShare;
        // uint256 paymentTokenBalance = getPaymentTokenBalance();
        // reset to zero  for each deal used by front-end
        uint256 publisherCurrentDealTotal = 0;
        uint256 buyerCurrentDealTotal = 0;
        uint256 affiShareCurrentDealTotal = 0;

        // Affi network fees 10%
        uint256 affiShare = ((coa * 10) / 100);
        // cuts AFFi network protocol from a single COA
        coa -= affiShare;

        // calculate publisher share
        uint256 publisherTokenShare = ((coa * publisherShare) / 100);
        // cuts publisher share from a single COA
        coa -= publisherTokenShare;

        // allocate whats left to buyer as cashback
        uint256 buyerTokenShare = coa;

        // we allocate tokens based on the amount of sales
        for (uint256 i = 0; i < amount; i++) {
            // transfer the protocol fees to affi network multi-sig treasury
            paymentToken.safeTransfer(AffiTreasury, affiShare);

            // update temporary deal total for front-end
            publisherCurrentDealTotal += publisherTokenShare;
            buyerCurrentDealTotal += buyerTokenShare;
            affiShareCurrentDealTotal += affiShare;
        }

        totalFees += affiShareCurrentDealTotal;

        // update the storage
        shares[_publisher] += publisherCurrentDealTotal;
        shares[_buyer] += buyerCurrentDealTotal;
        totalPendingShares += publisherCurrentDealTotal + buyerCurrentDealTotal;

        // emit total earning for current deal
        emit DealSealed(
            _publisher,
            _buyer,
            publisherCurrentDealTotal,
            buyerCurrentDealTotal,
            affiShareCurrentDealTotal
        );
    }

    // =============================================================
    //                     UTILS
    // =============================================================
    /**
    @dev  current token decimals. (18 for DAI, 6 for USDT)
     */
    function getPaymentTokenDecimals() public view returns (uint256) {
        return paymentToken.decimals();
    }

    /**
    @dev  returns the campaign details. utilized by front-end.
     */
    function getCampaignDetails() external view returns (Campaign memory) {
        return campaign;
    }

    /**
    @dev  returns the balance of the chosen payment token in the contract.
     */
    function getPaymentTokenBalance() public view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }
}
