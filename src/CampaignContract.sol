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
        uint256 poolSize;
        string symbol;
        address daiAddress;
        address usdcAddress;
    }

    // campaign tracking
    Campaign public campaign;

    uint256 public totalPublishers;

    // keeps publisher URL to the buyers' address
    mapping(address => string) public publishers;

    // keeps sales by each publisher
    mapping(address => address[]) public sales;

    //ERC20s that Affi network supports
    ERC20 public immutable DAI;
    ERC20 public immutable USDC;
    // ERC20 public immutable AFFI

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
    error poolSizeNeedToBeAtleastThirthy();

    // =============================================================
    //                            EVENTS
    // =============================================================

    event CampaignFunded(uint256 indexed id, uint256 poolSize);
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
        uint256 _startTime,
        uint256 _duration,
        address _contractAddress,
        address _creatorAddress,
        BountyInfo memory _bountyInfo,
        string memory _redirectUrl,
        string memory _network
    ) {
        owner = _creatorAddress;

        if (_duration < 30 days) revert campaignDurationTooShort();

        DAI = ERC20(_bountyInfo.daiAddress);
        USDC = ERC20(_bountyInfo.usdcAddress);

        ERC20 token = getStableToken(_bountyInfo.symbol);

        if (_bountyInfo.bounty < (10 * (10**token.decimals())))
            revert bountyNeedTobeAtLeastTen();

        campaign.id = _id;
        campaign.startTime = _startTime;
        campaign.duration = _duration;
        campaign.contractAddress = _contractAddress;
        campaign.creatorAddress = _creatorAddress;
        campaign.redirectUrl = _redirectUrl;
        campaign.network = _network;

        campaign.bountyInfo.publisherShare = _bountyInfo.publisherShare;
        campaign.bountyInfo.buyerShare = _bountyInfo.buyerShare;
        campaign.bountyInfo.bounty = _bountyInfo.bounty;
        campaign.bountyInfo.symbol = _bountyInfo.symbol;

        // not open till funding
        campaign.isOpen = false;
    }

    // =============================================================
    //                          OPERATIONS
    // =============================================================

    /**
    @dev  Assumption: advertiser fund the campaign with stables currently either DAI or USDC.
          after the campaign is funded successfully, we upgrade the campaign pool size, and the state is officially open 
     */
    function fundCampaignPool(string calldata _symbol, uint256 _poolSize)
        external
        isOwner
    {
        ERC20 token = getStableToken(_symbol);

        campaign.bountyInfo.poolSize = _poolSize;

        if (_poolSize < (30 * (10**token.decimals())))
            revert poolSizeNeedToBeAtleastThirthy();

        campaign.isOpen = true;

        token.safeTransferFrom(owner, address(this), _poolSize);
        emit CampaignFunded(campaign.id, campaign.bountyInfo.poolSize);
    }

    /**
    @dev if the campaign time is ended, the campaign creator can take their tokens 
         back.
     */
    function withdrawFromCampaignPool(string memory _symbol) external isOwner {
        ERC20 token = getStableToken(_symbol);
        if (block.timestamp < campaign.duration) revert withdrawTooEarly();
        campaign.isOpen = false;
        token.safeTransfer(owner, campaign.bountyInfo.poolSize);
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

    function getCampaignDetails() external view returns (Campaign memory) {
        return campaign;
    }

    // =============================================================
    //                     ROBOAFFI OPERATIONS
    // =============================================================

    /**
    @dev This function is called automatically by Robo Affi; it allows all parties to receive their share after a sale.
    @notice at current version cashback and publisher withdraws are limited to the time of the campaign.
     */
    function sealADeal(address _publisher, address _buyer) external isRoboAffi {
        string memory symbol = campaign.bountyInfo.symbol;
        ERC20 token = getStableToken(symbol);
        uint256 bounty = campaign.bountyInfo.bounty;
        uint256 buyerShare = campaign.bountyInfo.buyerShare;
        uint256 publisherShare = campaign.bountyInfo.publisherShare;
        uint256 poolSize = campaign.bountyInfo.poolSize;

        // check if pool still have money
        if (bounty > poolSize) revert poolIsDrained();

        // Affi network fees 10%
        // 50% of all of these token will be transferred to staking contract later
        uint256 affiShare = (bounty * 10 * (10**token.decimals())) / poolSize;
        bounty -= affiShare;

        token.safeTransfer(
            0x2f66c75A001Ba71ccb135934F48d844b46454543,
            affiShare
        );

        uint256 buyerTokenShare = (bounty *
            buyerShare *
            (10**token.decimals())) / poolSize;

        uint256 publisherTokenShare = (bounty *
            publisherShare *
            (10**token.decimals())) / poolSize;

        // storage deduction
        campaign.bountyInfo.poolSize -= campaign.bountyInfo.bounty;

        // allow to withdraw cashback and bounty
        token.safeApprove(_publisher, publisherTokenShare);
        token.safeApprove(_buyer, buyerTokenShare);
        sales[_publisher].push(_buyer);

        emit DealSealed(_publisher, _buyer);
    }

    // =============================================================
    //                          UTILITIES
    // =============================================================

    function getStableToken(string memory _symbol)
        internal
        view
        returns (ERC20)
    {
        ERC20 token;
        if (keccak256(abi.encode(_symbol)) == keccak256(abi.encode("DAI"))) {
            token = DAI;
        }
        if (keccak256(abi.encode(_symbol)) == keccak256(abi.encode("USDC"))) {
            token = USDC;
        }

        return token;
    }
}
