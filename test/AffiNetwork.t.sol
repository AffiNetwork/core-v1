// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/*
 █████╗ ███████╗███████╗██╗███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
██╔══██╗██╔════╝██╔════╝██║████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
███████║█████╗  █████╗  ██║██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
██╔══██║██╔══╝  ██╔══╝  ██║██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
██║  ██║██║     ██║     ██║██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝

V1.0.0                                                                                                                                                        
 */

import "forge-std/Test.sol";
import "../src/CampaignFactory.sol";
import "../src/CampaignContract.sol";
import "./Mocks/MockERC20.sol";
import "./Utils/BaseSetup.sol";

contract AffiNetworkTest is Test, BaseSetup {
    CampaignFactory public campaignFactory;
    CampaignContract public campaignContract;
    MockERC20 public mockERC20DAI;
    MockERC20 public mockERC20USDC;

    // address internal erc20MockAddr;

    function setUp() public override {
        super.setUp();
        campaignFactory = new CampaignFactory();
        vm.startPrank(owner);
        mockERC20DAI = new MockERC20("DAI", "DAI", 100 * (10**18), 18);
        mockERC20USDC = new MockERC20("USDC", "USDC", 100 * (10**6), 6);

        vm.stopPrank();
    }

    function testCreateCampaign() public {
        campaignContract = createCampaign("DAI");
        // check campaign exists
        assertEq(campaignContract.getCampaignDetails().bountyInfo.poolSize, 0);
    }

    function testFailWithLowBounty() public {
        CampaignContract.BountyInfo memory bountyInfo;

        bountyInfo.bounty = 1 * (10**18);
        bountyInfo.publisherShare = 60;
        bountyInfo.buyerShare = 40;
        bountyInfo.symbol = "DAI";
        bountyInfo.usdcAddress = address(mockERC20USDC);
        bountyInfo.daiAddress = address(mockERC20DAI);

        campaignFactory.CreateCampaign(
            30 days,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            owner,
            bountyInfo,
            "https://affi.network",
            "1337"
        );
    }

    function testCreateMultipleCampaigns() public {
        CampaignContract.BountyInfo memory bountyInfo;

        bountyInfo.bounty = 10 * (10**18);
        bountyInfo.publisherShare = 60;
        bountyInfo.buyerShare = 40;
        bountyInfo.symbol = "DAI";
        bountyInfo.usdcAddress = address(mockERC20USDC);
        bountyInfo.daiAddress = address(mockERC20DAI);

        campaignFactory.CreateCampaign(
            30 days,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            owner,
            bountyInfo,
            "https://affi.network",
            "1337"
        );

        campaignFactory.CreateCampaign(
            30 days,
            0xdeAdBEEf8F259C7AeE6E5B2AA729821864227E84,
            dev,
            bountyInfo,
            "https://brandface.io",
            "1337"
        );

        campaignContract = CampaignContract(campaignFactory.campaigns(0));

        CampaignContract campaignContractDev = CampaignContract(
            campaignFactory.campaigns(1)
        );

        assertEq(
            campaignContractDev.getCampaignDetails().contractAddress,
            0xdeAdBEEf8F259C7AeE6E5B2AA729821864227E84
        );
    }

    function testFundCampaign() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");

        mockERC20DAI.approve(address(campaignContract), 10e18);
        // mockERC20DAI.allowance(owner, address(campaignContract));

        campaignContract.fundCampaignPool("DAI", 10e18);

        assertEq(
            campaignContract.getCampaignDetails().bountyInfo.poolSize,
            10e18
        );
        vm.stopPrank();
    }

    function testWithdrawFromCampaign() public {
        vm.startPrank(owner);

        // set the time to 30 days
        vm.warp(block.timestamp + 30 days);

        campaignContract = createCampaign("DAI");
        campaignContract.withdrawFromCampaignPool("DAI");

        vm.stopPrank();
    }

    function testFailWithdrawFromCampaignWrongTime() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");
        campaignContract.withdrawFromCampaignPool("DAI");

        vm.stopPrank();
    }

    function testFailWithdrawFromCampaignNotOwner() public {
        campaignContract = createCampaign("DAI");
        campaignContract.withdrawFromCampaignPool("DAI");
    }

    function testFailIfAlreadyParticipated() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");
        campaignContract.participate("https://affi.network/0x1137");
        campaignContract.participate("https://affi.network/0x1137");
        vm.stopPrank();
    }

    function testFailParticipateAsOwner() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");
        campaignContract.participate("https://affi.network/0x1137");
        vm.stopPrank();
    }

    function testParticipateAsPublisher() public {
        campaignContract = createCampaign("DAI");

        vm.startPrank(publisher);

        campaignContract.participate("https://affi.network/0x1137");

        assertEq(campaignContract.totalPublishers(), 1);

        vm.stopPrank();
    }

    function testFailtoSealADealIfNotRoboAffi() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        campaignContract.sealADeal(publisher, buyer);
        vm.stopPrank();
    }

    function testSealADealByRoboAffiDAI() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");

        mockERC20DAI.approve(address(campaignContract), 100 * (10**18));

        campaignContract.fundCampaignPool("DAI", 100 * (10**18));

        vm.stopPrank();

        vm.startPrank(roboAffi);

        campaignContract.sealADeal(publisher, buyer);

        uint256 buyerAllowance = mockERC20DAI.allowance(
            address(campaignContract),
            buyer
        );
        uint256 publisherAllowance = mockERC20DAI.allowance(
            address(campaignContract),
            publisher
        );

        assertEq(mockERC20DAI.balanceOf(dev), 1 * 10**18);
        assertEq(buyerAllowance, 36 * 10**17);
        assertEq(publisherAllowance, 54 * 10**17);

        vm.stopPrank();
    }

    function testSealADealByRoboAffiUSDC() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("USDC");

        mockERC20USDC.approve(address(campaignContract), 100 * (10**6));

        campaignContract.fundCampaignPool("USDC", 100 * (10**6));

        vm.stopPrank();

        vm.startPrank(roboAffi);

        campaignContract.sealADeal(publisher, buyer);

        uint256 buyerAllowance = mockERC20USDC.allowance(
            address(campaignContract),
            buyer
        );
        uint256 publisherAllowance = mockERC20USDC.allowance(
            address(campaignContract),
            publisher
        );

        assertEq(mockERC20USDC.balanceOf(dev), 1 * 10**6);
        assertEq(buyerAllowance, 36 * 10**5);
        assertEq(publisherAllowance, 54 * 10**5);

        vm.stopPrank();
    }

    function createCampaign(string memory _symbol)
        internal
        returns (CampaignContract)
    {
        CampaignContract.BountyInfo memory bountyInfo;

        bountyInfo.publisherShare = 60;
        bountyInfo.buyerShare = 40;
        bountyInfo.usdcAddress = address(mockERC20USDC);
        bountyInfo.daiAddress = address(mockERC20DAI);

        if (keccak256(abi.encode(_symbol)) == keccak256(abi.encode("DAI"))) {
            bountyInfo.symbol = "DAI";
            bountyInfo.bounty = 10 * (10**18);
        } else {
            bountyInfo.symbol = "USDC";
            bountyInfo.bounty = 10 * (10**6);
        }

        campaignFactory.CreateCampaign(
            30 days,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            owner,
            bountyInfo,
            "https://affi.network",
            "1337"
        );

        campaignContract = CampaignContract(campaignFactory.campaigns(0));

        return campaignContract;
    }
}
