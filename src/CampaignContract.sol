// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "forge-std/console.sol";

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
    address public constant RoboAffi =
        0x075edF3ae919FBef9933f666bb0A95C6b80b04ed;

    // campaign structure
    struct Campaign {
        uint256 id;
        uint256 startTime;
        uint256 duration;
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
    // minimal bounty paid is $10
    error bountyNeedTobeAtLeastTen();
    // minimal bounty paid is $30
    error fundsNeedToBeAtleastThirthy();
    // no share available for release
    error noShareAvailable();

    // =============================================================
    //                            EVENTS
    // =============================================================

    event CampaignFunded(uint256 indexed id, uint256 funds);
    event PublisherRegistered(address indexed publisher);
    event DealSealed(address indexed publisher, address indexed buyer);

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
        uint256 _duration,
        address _contractAddress,
        address _creatorAddress,
        BountyInfo memory _bountyInfo,
        address _paymentTokenAddress, 
        string memory _redirectUrl,
        string memory _network
    ) {
        owner = _creatorAddress;

        if (_duration < 30 days) revert campaignDurationTooShort();

        // stablecoin
        paymentToken = ERC20(_paymentTokenAddress);

        if (_bountyInfo.bounty < (10 * getPaymentTokenDecimals()))
            revert bountyNeedTobeAtLeastTen();
 
        campaign.id = _id;
        campaign.startTime = block.timestamp;
        campaign.duration = _duration;
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
    @dev  Assumption: advertiser fund the campaign with stables currently either DAI or USDC.
          after the campaign is funded successfully, the campaign is officially open 
     */
    function fundCampaignPool(uint256 _funds)
        external
        isOwner
    {
        if (_funds < (30 * getPaymentTokenDecimals()))
            revert fundsNeedToBeAtleastThirthy();

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
        if (block.timestamp < (campaign.startTime + campaign.duration)) revert withdrawTooEarly();
        campaign.isOpen = false;
        // owner can only withdraw money left
        uint256 balance = paymentToken.balanceOf(address(this));
        uint256 availableForWithdraw = balance - totalPendingShares;

        paymentToken.safeTransfer(owner,availableForWithdraw);
    }

    /**
    
    @dev The participant can not be the creator. 
         We write the URL generator by our URL generator (off-chain) along with their address to the campaign. 
     */

    function participate(string calldata _url) external {
        if (msg.sender == owner) revert ownerCantParticipate();

        if (bytes(publishers[msg.sender]).length > 0)
            revert alreadyRegistered();

        publishers[msg.sender] = _url;

        // update total publishers
        totalPublishers++;

        emit PublisherRegistered(msg.sender);
    }

    /// @notice This function can be call from a publisher or buyer. It will transfer the share they earn
    function releaseShare() external {
        if(shares[msg.sender] == 0)
            revert noShareAvailable();

        uint256 shareForRelease =  shares[msg.sender];
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
    @notice at current version cashback and publisher withdraws are limited to the time of the campaign.
     */
    function sealADeal(address _publisher, address _buyer) external isRoboAffi {
        uint256 bounty = campaign.bountyInfo.bounty;
        uint256 buyerShare = campaign.bountyInfo.buyerShare;
        uint256 publisherShare = campaign.bountyInfo.publisherShare;
        uint256 paymentTokenBalance = getPaymentTokenBalance();

        // check if pool still have money
        if(bounty > paymentTokenBalance) revert poolIsDrained();

        // Affi network fees 10%
        // 50% of all of these token will be transferred to staking contract later
        uint256 affiShare = (bounty * 10 * getPaymentTokenDecimals()) / paymentTokenBalance;
        bounty -= affiShare;

        paymentToken.safeTransfer(
            0x2f66c75A001Ba71ccb135934F48d844b46454543,
            affiShare
        );

        uint256 buyerTokenShare = (bounty *
            buyerShare *
            getPaymentTokenDecimals()) / paymentTokenBalance;

        uint256 publisherTokenShare = (bounty *
            publisherShare *
            getPaymentTokenDecimals()) / paymentTokenBalance;

        shares[_publisher] += publisherTokenShare;
        shares[_buyer] += buyerTokenShare;

        totalPendingShares += publisherTokenShare + buyerTokenShare;

        sales[_publisher].push(_buyer);

        emit DealSealed(_publisher, _buyer);
    }

    // =============================================================
    //                     UTILS
    // =============================================================

    function getPaymentTokenDecimals() internal view returns(uint256){
        return 10 ** paymentToken.decimals();
    }

    function getCampaignDetails() external view returns (Campaign memory) {
        return campaign;
    }

    /// @notice Return the current balance of paymentToken in the contract
    function getPaymentTokenBalance() public view returns(uint256){
        return paymentToken.balanceOf(address(this));
    }
}
