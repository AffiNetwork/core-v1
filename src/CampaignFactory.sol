// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
 * each campaign packed with campaign details structure.
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

    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed campaignAddress,
        address campaignCreator
    );

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
        string calldata _paymentTokenSymbol,
        string memory _network,
        uint256 _publisherShare,
        uint256 _costOfAcquisition
    ) external {
        // Increment campaign ID
        unchecked {
            ++id;
        }

        CampaignContract campaign = new CampaignContract(
            id,
            _duration,
            _contractAddress,
            _creatorAddress,
            getPaymentTokenAddress(_paymentTokenSymbol),
            _network,
            _publisherShare,
            _costOfAcquisition
        );

        campaigns.push(address(campaign));

        emit CampaignCreated(id, address(campaign), _creatorAddress);
    }

    // =============================================================
    //                          UTILITIES
    // =============================================================

    function getPaymentTokenAddress(string memory _paymentTokenSymbol)
        internal
        view
        returns (address _paymentTokenAddress)
    {
        if (
            keccak256(abi.encodePacked(_paymentTokenSymbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return DAI;
        }
        if (
            keccak256(abi.encodePacked(_paymentTokenSymbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return USDC;
        }
    }
}
