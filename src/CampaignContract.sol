// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Import this file to use console.log
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
    using SafeERC20 for ERC20;

    // campaign structure
    struct CampaignOnChain {
        uint256 id;
        uint256 startTime;
        uint256 duration;
        uint256 publisherShare;
        uint256 buyerShare;
        uint256 poolSize;
        string symbol;
        address contractAddress;
        address creatorAddress;
        bool isOpen;
        string redirectUrl;
    }
    // store campaign
    CampaignOnChain public campaignOnChain;

    // keeps the participants -> Campaign.id
    mapping(address => uint256) participants;

    //address owner;
    ERC20 public constant DAI =
        ERC20(0x5FbDB2315678afecb367f032d93F642f64180aa3); //ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 public constant USDC =
        ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    //address constant AFFI = 0xe11A86849d99F524cAC3E7A0Ec1241828e332C62;

    function getStableToken(string memory _symbol)
        internal
        pure
        returns (ERC20)
    {
        if (
            keccak256(abi.encodePacked(_symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return DAI;
        }
        return USDC;
    }

    constructor(
        uint256 _id,
        uint256 _startTime,
        uint256 _duration,
        uint256 _publisherShare,
        uint256 _buyerShare,
        address _contractAddress,
        address _creatorAddress,
        string memory _redirectUrl
    ) {
        campaignOnChain.id = _id;
        campaignOnChain.startTime = _startTime;
        campaignOnChain.duration = _duration;
        campaignOnChain.publisherShare = _publisherShare;
        campaignOnChain.buyerShare = _buyerShare;
        campaignOnChain.contractAddress = _contractAddress;
        campaignOnChain.creatorAddress = _creatorAddress;
        campaignOnChain.redirectUrl = _redirectUrl;
        campaignOnChain.isOpen = false;
    }

    function fundCampaignPool(string memory _symbol, uint256 _poolSize)
        external
    {
        ERC20 token = getStableToken(_symbol);
        token.approve(msg.sender, _poolSize);
        token.safeTransferFrom(msg.sender, address(this), _poolSize);
    }

    function withdrawFromCampaignPool(string memory _symbol) external {
        ERC20 token = getStableToken(_symbol);

        campaignOnChain.isOpen = false;
        token.safeTransfer(msg.sender, campaignOnChain.poolSize);
    }

    function getCampaignDetails()
        external
        view
        returns (CampaignOnChain memory)
    {
        return campaignOnChain;
    }
}
