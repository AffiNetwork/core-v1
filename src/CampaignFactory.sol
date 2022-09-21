// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./CampaignContract.sol";

/*
 █████╗ ███████╗███████╗██╗███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
██╔══██╗██╔════╝██╔════╝██║████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
███████║█████╗  █████╗  ██║██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
██╔══██║██╔══╝  ██╔══╝  ██║██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
██║  ██║██║     ██║     ██║██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝

V1.0.0                                                                                                                                                        
 */

/**
 * @title AffiNetwork Campaign Factory
 *
 * @dev Deploys a campaign and keeps its address to track them;
 * each campaign contains a bounty structure, owner, target contract address, and URL.
 */
contract CampaignFactory {
    // =============================================================
    //                            STORAGE
    // =============================================================
    address[] public campaigns;
    uint256 public id;


    //ERC20s that Affi network supports
    address public immutable DAI;
    address public immutable USDC;


   // =============================================================
    //                            EVENTS
    // =============================================================

    event CampaignCreated(uint256 indexed campaignId, address indexed campaignAddress);


    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(address _daiAddress, address _usdcAddress) {
        DAI = _daiAddress;
        USDC = _usdcAddress;
    }

    // =============================================================
    //                            Factory Generation
    // =============================================================
    function createCampaign(
        uint256 _duration,
        address _contractAddress,
        address _creatorAddress,
        CampaignContract.BountyInfo memory _bountyInfo,
        string calldata _paymentTokenSymbol, 
        string memory _redirectUrl,
        string memory _network
    ) external {
        ++id;

        CampaignContract campaign = new CampaignContract(
            id,
            _duration, 
            _contractAddress,
            _creatorAddress,
            _bountyInfo,
            getPaymentTokenAddress(_paymentTokenSymbol),
            _redirectUrl,
            _network
        );

        campaigns.push(address(campaign));
 
        emit CampaignCreated(id, address(campaign));
    } 

        // =============================================================
    //                          UTILITIES
    // =============================================================

    function getPaymentTokenAddress(string memory _paymentTokenSymbol)
        internal
        view
        returns (address _paymentTokenAddress)
    {
        if (keccak256(abi.encode(_paymentTokenSymbol)) == keccak256(abi.encode("DAI"))) {
            return  DAI;
        }
        if (keccak256(abi.encode(_paymentTokenSymbol)) == keccak256(abi.encode("USDC"))) {
            return USDC;
        }
    }

}
