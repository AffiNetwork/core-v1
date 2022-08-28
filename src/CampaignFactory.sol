// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./CampaignContract.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

/*
 █████╗ ███████╗███████╗██╗███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
██╔══██╗██╔════╝██╔════╝██║████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
███████║█████╗  █████╗  ██║██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
██╔══██║██╔══╝  ██╔══╝  ██║██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
██║  ██║██║     ██║     ██║██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝

V1.0.0                                                                                                                                                        
 */

contract CampaignFactory {
    address[] public campaigns;

    uint256 id;

    function CreateCampaign(
        //uint256 _id,
        //uint256 _startTime,
        uint256 _duration,
        uint256 _publisherShare,
        uint256 _buyerShare,
        // uint256 _poolSize,
        address _contractAddress,
        address _creatorAddress,
        string memory _redirectUrl // string memory _symbol
    ) external {
        ++id;
        CampaignContract campaign = new CampaignContract(
            id,
            block.timestamp,
            _duration,
            _publisherShare,
            _buyerShare,
            // _poolSize,
            _contractAddress,
            _creatorAddress,
            _redirectUrl
            // _symbol
        );

        campaigns.push(address(campaign));
    }
}
