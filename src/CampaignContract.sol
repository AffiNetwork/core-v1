// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

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

    address public immutable owner;

    // Address of  Affi robot that pays the parties
    // from anvil till deployment
    address public constant RoboAffi =
        0x976EA74026E726554dB657fA54763abd0C3a0aa9;

    // campaign structure
    struct Campaign {
        uint256 id;
        uint256 startTime;
        uint256 endDate;
        address contractAddress;
        address creatorAddress;
        bool isOpen;
        string redirectUrl;
        string network;
        /* stack not too deep anymore :| */
        BountyInfo bountyInfo;
    }

    struct BountyInfo {
        uint256 publisherShare;
        uint256 buyerShare;
        uint256 bounty;
    }

    // campaign tracking
    Campaign public campaign;

    uint256 public totalPublishers;

    // keeps publisher URL to the buyers' address
    mapping(address => string) public publishers;

    // keeps sales by each publisher
    mapping(address => address[]) public sales;

    // keeps share for each publisher and buyer.
    mapping(address => uint256) public shares;

    // keep the total shares waiting to be withdraw
    uint256 public totalPendingShares;

    // erc20 token used for payment
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
    error poolIsDrained();
    // minimal bounty paid is $1
    error bountyNeedTobeAtLeastOne();
    error noShareAvailable();
    // campaign is open
    error CampaignIsOpen();
    // participation is close
    error participationClose();
    // pool size must be bigger than bounty
    error poolSizeShouldBeBiggerThanBounty();
    // =============================================================
    //                            EVENTS
    // =============================================================

    event CampaignFunded(uint256 indexed id, uint256 funds);
    event PublisherRegistered(address indexed publisher);
    event DealSealed(
        address indexed publisher,
        address indexed buyer,
        uint256 publisherShare,
        uint256 buyerShare
    );

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
          as it also requires approval, we separate the logic.  
     */
    constructor(
        uint256 _id,
        uint256 _endDate,
        address _contractAddress,
        address _creatorAddress,
        BountyInfo memory _bountyInfo,
        address _paymentTokenAddress,
        string memory _redirectUrl,
        string memory _network
    ) {
        owner = _creatorAddress;

        if (!(_endDate >= block.timestamp + 30 days))
            revert campaignDurationTooShort();

        // stablecoin
        paymentToken = ERC20(_paymentTokenAddress);

        if (!(_bountyInfo.bounty >= (1 * 10**getPaymentTokenDecimals())))
            revert bountyNeedTobeAtLeastOne();

        campaign.id = _id;
        campaign.startTime = block.timestamp;
        campaign.endDate = _endDate;
        campaign.contractAddress = _contractAddress;
        campaign.creatorAddress = _creatorAddress;
        campaign.redirectUrl = _redirectUrl;
        campaign.network = _network;

        campaign.bountyInfo.publisherShare = _bountyInfo.publisherShare;
        campaign.bountyInfo.buyerShare = _bountyInfo.buyerShare;
        campaign.bountyInfo.bounty = _bountyInfo.bounty;

        // not open till funding
        campaign.isOpen = false;
    }

    // =============================================================
    //                          OPERATIONS
    // =============================================================

    /** 
    @notice Fund campaign with paymentToken. (DAI or USDC)
    Funding is allowed only once for now .
    @dev  after the campaign is successfully funded, the campaign is officially open 
    */
    function fundCampaignPool(uint256 _funds) external isOwner {
        if (campaign.isOpen) revert CampaignIsOpen();

        if (_funds < (100 * campaign.bountyInfo.bounty))
            revert poolSizeShouldBeBiggerThanBounty();

        paymentToken.safeTransferFrom(owner, address(this), _funds);
        // we open the campaign after the transfer
        campaign.isOpen = true;

        emit CampaignFunded(campaign.id, _funds);
    }

    /**
        @dev if the campaign time is ended, the campaign creator can take their tokens 
         back.
     */
    function withdrawFromCampaignPool() external isOwner {
        if (block.timestamp < campaign.endDate) revert withdrawTooEarly();
        campaign.isOpen = false;
        // owner can only withdraw money left
        uint256 balance = paymentToken.balanceOf(address(this));
        uint256 availableForWithdraw = balance - totalPendingShares;

        paymentToken.safeTransfer(owner, availableForWithdraw);
    }

    /**
        @notice Publisher participation. Allow the publisher to save his link on-chain.
        @dev The participant can not be the creator. 
         We write the URL generator by our URL generator (off-chain) along with their address to the campaign. 
     */
    function participate(string calldata _url) external {
        if (msg.sender == owner) revert ownerCantParticipate();
        if (block.timestamp >= campaign.endDate) revert participationClose();
        if (bytes(publishers[msg.sender]).length > 0)
            revert alreadyRegistered();

        publishers[msg.sender] = _url;

        // update total publishers
        totalPublishers++;

        emit PublisherRegistered(msg.sender);
    }

    /// @notice This function can be called by a publisher or buyer. It will transfer their shares
    function releaseShare() external {
        if (shares[msg.sender] == 0) revert noShareAvailable();

        uint256 shareForRelease = shares[msg.sender];
        // decrease pending shares
        totalPendingShares -= shareForRelease;
        // reset state
        shares[msg.sender] = 0;
        // transfer
        paymentToken.safeTransfer(msg.sender, shareForRelease);
    }

    // =============================================================
    //                     ROBOAFFI OPERATIONS
    // =============================================================

    /**
    @dev This function is called automatically by Robo Affi; it allows all parties to receive their share after a sale.
     */
    function sealADeal(address _publisher, address _buyer) external isRoboAffi {
        uint256 bounty = campaign.bountyInfo.bounty;
        uint256 buyerShare = campaign.bountyInfo.buyerShare;
        // uint256 publisherShare = campaign.bountyInfo.publisherShare;
        uint256 paymentTokenBalance = getPaymentTokenBalance();

        // check if pool still have fund
        if (bounty > paymentTokenBalance) revert poolIsDrained();

        // Affi network fees 10%
        // 50% of all of these token will be transferred to staking contract later
        uint256 affiShare = ((bounty * 10) / 100);

        // cuts affishare from a single bounty
        bounty -= affiShare;

        paymentToken.safeTransfer(
            // affi network valut
            0x2f66c75A001Ba71ccb135934F48d844b46454543,
            affiShare
        );

        uint256 buyerTokenShare = ((bounty * buyerShare) / 100);

        // cuts buyer share from a single bounty
        bounty -= buyerTokenShare;

        // allocate whats left to publisher
        uint256 publisherTokenShare = bounty;

        shares[_publisher] += publisherTokenShare;
        shares[_buyer] += buyerTokenShare;

        totalPendingShares += publisherTokenShare + buyerTokenShare;

        sales[_publisher].push(_buyer);

        emit DealSealed(
            _publisher,
            _buyer,
            publisherTokenShare,
            buyerTokenShare
        );
    }

    // =============================================================
    //                     UTILS
    // =============================================================

    function getPaymentTokenDecimals() public view returns (uint256) {
        return paymentToken.decimals();
    }

    function getCampaignDetails() external view returns (Campaign memory) {
        return campaign;
    }

    /// @notice Return the current balance of paymentToken in the contract
    function getPaymentTokenBalance() public view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }
}
