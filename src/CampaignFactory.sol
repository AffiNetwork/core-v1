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
    uint256 id;

    // =============================================================
    //                            Factory Generation
    // =============================================================
    function CreateCampaign(
        uint256 _duration,
        address _contractAddress,
        address _creatorAddress,
        CampaignContract.BountyInfo memory _bountyInfo,
        string memory _redirectUrl // string memory _symbol
    ) external {
        ++id;

        CampaignContract campaign = new CampaignContract(
            id,
            block.timestamp,
            _duration,
            _contractAddress,
            _creatorAddress,
            _bountyInfo,
            _redirectUrl
        );

        campaigns.push(address(campaign));
    }
}
