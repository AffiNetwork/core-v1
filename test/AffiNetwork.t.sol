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

error notEnoughFunds();

contract AffiNetworkTest is Test, BaseSetup {
    CampaignFactory public campaignFactory;
    CampaignContract public campaignContract;
    MockERC20 public mockERC20DAI;
    MockERC20 public mockERC20USDC;

    // address internal erc20MockAddr;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);
        mockERC20DAI = new MockERC20("DAI", "DAI", 1000 * (10**18), 18);
        mockERC20USDC = new MockERC20("USDC", "USDC", 1000 * (10**6), 6);

        campaignFactory = new CampaignFactory(
            address(mockERC20DAI),
            address(mockERC20USDC)
        );

        vm.stopPrank();
    }

    function testDeployFactory() public {
        campaignFactory = new CampaignFactory(
            address(mockERC20DAI),
            address(mockERC20USDC)
        );

        // assert if function create campaign exists
        assertEq(
            campaignFactory.createCampaign.selector,
            bytes4(
                keccak256(
                    "createCampaign(uint256,address,address,string,string,uint256,uint256)"
                )
            )
        );
    }

    function testCreateCampaign() public {
        campaignContract = createCampaign("DAI");
        // check campaign exists
        uint256 availableFunds = campaignContract.getPaymentTokenBalance();
        assertEq(availableFunds, 0);
    }

    function testCreateMultipleCampaigns() public {
        uint256 publisherShare = 40;
        uint256 costOfAcquisition = 10 * (10**18);

        campaignFactory.createCampaign(
            block.timestamp + 30 days,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            owner,
            "DAI",
            // "https://affi.network",
            "1337",
            publisherShare,
            costOfAcquisition
        );

        campaignFactory.createCampaign(
            block.timestamp + 30 days,
            0xdeAdBEEf8F259C7AeE6E5B2AA729821864227E84,
            dev,
            "DAI",
            // "https://brandface.io",
            "1337",
            publisherShare,
            costOfAcquisition
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
        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);

        uint256 availableFunds = campaignContract.getPaymentTokenBalance();

        assertEq(availableFunds, funds);
        vm.stopPrank();
    }

    function testFailFundCampaignWhenOpen() public {
        vm.startPrank(owner);
        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);
        fundCampaign("DAI", funds);

        vm.stopPrank();
    }

    function testFundCampaignWithoutEnoughFundingReverts() public {
        vm.startPrank(owner);

        uint256 publisherShare = 40;
        uint256 costOfAcquisition = 10 * (10**18);

        campaignFactory.createCampaign(
            block.timestamp + 40 days,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            owner,
            "DAI",
            // "https://affi.network",
            "1337",
            publisherShare,
            costOfAcquisition
        );

        campaignContract = CampaignContract(campaignFactory.campaigns(0));

        // for a $10 COA pool should be $100 so revert
        uint256 funds = 100 * (10**18);
        vm.expectRevert();
        campaignContract.fundCampaignPool(funds);

        vm.stopPrank();
    }

    function testGetPaymentTokenDecimals() public {
        vm.startPrank(owner);
        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);

        uint256 decimal = campaignContract.getPaymentTokenDecimals();

        assertEq(decimal, 18);
    }

    function testCampaignIncreasePoolBudget() public {
        vm.startPrank(owner);
        uint256 funds = 500 * (10**18);

        uint256 costOfAcquisition = 5 * (10**18);

        uint256 publisherShare = 40;

        campaignFactory.createCampaign(
            block.timestamp + 40 days,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            owner,
            "DAI",
            // "https://affi.network",
            "1337",
            publisherShare,
            costOfAcquisition
        );

        campaignContract = CampaignContract(campaignFactory.campaigns(0));

        // approve for fund
        mockERC20DAI.approve(address(campaignContract), funds);
        campaignContract.fundCampaignPool(funds);

        // approve for top-up
        mockERC20DAI.approve(address(campaignContract), funds);

        campaignContract.increasePoolBudget(funds);

        // so the fund is doubled
        assertEq(mockERC20DAI.balanceOf(address(campaignContract)), funds * 2);
    }

    function testIncreaseCOARevertsIfthereIsNotEnoughBalance() public {
        vm.startPrank(owner);

        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);

        // withdraw force close campaign
        vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);
        campaignContract.withdrawFromCampaignPool();

        uint256 doubleCOA = campaignContract
            .getCampaignDetails()
            .costOfAcquisition * 2;

        vm.expectRevert();
        campaignContract.increaseCOA(doubleCOA);

        vm.stopPrank();
    }

    function testIncreaseCOA() public {
        vm.startPrank(owner);

        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);

        uint256 doubleCOA = campaignContract
            .getCampaignDetails()
            .costOfAcquisition * 2;

        campaignContract.increaseCOA(doubleCOA);

        assertEq(
            campaignContract.getCampaignDetails().costOfAcquisition,
            doubleCOA
        );

        vm.stopPrank();
    }

    // function testIncreaseCOARevertsIfCampaignIsClosed() public {
    //     vm.startPrank(owner);
    //     uint256 funds = 1000 * (10**18);
    //     campaignContract = createCampaign("DAI");
    //     fundCampaign("DAI", funds);

    //     // withdraw force close campaign
    //     vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);
    //     campaignContract.withdrawFromCampaignPool();

    //     vm.expectRevert();
    //     // amount doesnt matter it shoudn't go through
    //     campaignContract.increaseCOA(funds);

    //     vm.stopPrank();
    // }

    function testIncreaseCOAReverts() public {
        vm.startPrank(owner);

        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);

        // decrease the COA
        uint256 halfCOA = campaignContract
            .getCampaignDetails()
            .costOfAcquisition / 2;

        vm.expectRevert();
        campaignContract.increaseCOA(halfCOA);

        vm.stopPrank();
    }

    function testDoubleFundCampaignReverts() public {
        vm.startPrank(owner);
        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");

        mockERC20DAI.approve(address(campaignContract), funds);

        campaignContract.fundCampaignPool(funds);
        vm.expectRevert();
        campaignContract.fundCampaignPool(funds);

        vm.stopPrank();
    }

    function testWithdrawFromCampaign() public {
        vm.startPrank(owner);

        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);
        // set the time to 30 days
        vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);

        campaignContract.withdrawFromCampaignPool();

        assertEq(mockERC20DAI.balanceOf(owner), funds);
        vm.stopPrank();
    }

    function testWithdrawFromCampaignIfPendingShares() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        // set the time to 30 days
        vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);

        vm.stopPrank();

        vm.startPrank(roboAffi);

        campaignContract.sealADeal(publisher, buyer, 1);

        uint256 affiShare = 1 * 10**18;
        uint256 buyerShares = 36 * 10**17;
        uint256 publisherShares = 54 * 10**17;

        vm.stopPrank();

        vm.startPrank(owner);
        campaignContract.withdrawFromCampaignPool();

        assertEq(
            mockERC20DAI.balanceOf(owner),
            funds - affiShare - (buyerShares + publisherShares)
        );

        vm.stopPrank();
    }

    function testWithdrawFromCampaignWrongTimeReverts() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");

        // set the time to 10 day
        vm.warp(block.timestamp + 10 days);
        vm.expectRevert();
        campaignContract.withdrawFromCampaignPool();

        vm.stopPrank();
    }

    function testFailWithdrawFromCampaignNotOwner() public {
        campaignContract = createCampaign("DAI");
        campaignContract.withdrawFromCampaignPool();
    }

    function testAlreadyParticipatedReverts() public {
        vm.startPrank(dev);
        campaignContract = createCampaign("DAI");
        campaignContract.participate();
        vm.expectRevert();
        campaignContract.participate();

        vm.stopPrank();
    }

    // wiered on foundry coverage this only works for spcific condition
    // function testFailAlreadyParticipated() public {
    //     vm.startPrank(dev);
    //     campaignContract = createCampaign("DAI");
    //     campaignContract.participate("https://affi.network/0x1137");
    //     campaignContract.participate("https://affi.network/0x1137");
    //     vm.stopPrank();
    // }

    function testParticipateAsOwnerReverts() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");
        vm.expectRevert();
        campaignContract.participate();
        vm.stopPrank();
    }

    function testParticipateIfCampaignDoneReverts() public {
        campaignContract = createCampaign("DAI");

        // set the time to 31 days
        vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);
        vm.expectRevert();
        campaignContract.participate();
    }

    function testParticipateAsPublisher() public {
        campaignContract = createCampaign("DAI");

        vm.startPrank(publisher);

        campaignContract.participate();

        assertEq(campaignContract.totalPublishers(), 1);

        vm.stopPrank();
    }

    // check of the pool has enough funds
    function testifPoolHasEnoughFounds() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");
        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        vm.stopPrank();
        vm.prank(roboAffi);
        // lets say we first create 50 deals
        campaignContract.sealADeal(publisher, buyer, 50);
        // publisher release his shares
        vm.prank(publisher);
        campaignContract.releaseShare();

        vm.prank(roboAffi);
        vm.expectRevert(notEnoughFunds.selector);
        // we should not be able create more than 50 deals
        // we create 51 more deals and it should revert
        campaignContract.sealADeal(publisher, buyer, 51);
    }

    function testFailtoSealADealIfNotRoboAffi() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        campaignContract.sealADeal(publisher, buyer, 1);
        vm.stopPrank();
    }

    function testIncraseBudget() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);
        // give more tokens to the owner
        deal(address(mockERC20DAI), owner, 1000 * (10**18));
        mockERC20DAI.approve(address(campaignContract), 1000 * (10**18));
        campaignContract.increasePoolBudget(1000 * (10**18));

        assertEq(
            mockERC20DAI.balanceOf(address(campaignContract)),
            2000 * (10**18)
        );

        vm.stopPrank();
    }

    function testRevertsIfIncreaseTimeIsLessThanOneDay() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        vm.expectRevert();
        // less than a day
        campaignContract.increaseTime(12 hours);
        vm.stopPrank();
    }

    function testCampaignStatus() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);
        // campaign is open
        assertEq(campaignContract.isCampaignOpen(), true);

        // withdraw now and campaign should be closed
        vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);
        campaignContract.withdrawFromCampaignPool();
        assertEq(campaignContract.isCampaignOpen(), false);
    }

    function testReviveAClosedCampaign() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        uint256 endDate = campaignContract.getCampaignDetails().endDate;
        // increase the time and withdraw the funds
        vm.warp(endDate + 1 days);
        campaignContract.withdrawFromCampaignPool();

        // give more tokens to the owner
        deal(address(mockERC20DAI), owner, 100 * (10**18));
        mockERC20DAI.approve(address(campaignContract), 100 * (10**18));

        campaignContract.increasePoolBudget(100 * (10**18));

        // current campaign balance
        assertEq(
            mockERC20DAI.balanceOf(address(campaignContract)),
            100 * (10**18)
        );

        // campaign still closed though
        // increase the time by 7 days
        campaignContract.increaseTime(endDate + 7 days);
    }

    function testReviveRevertsIfNotEnoughBalanceByOnwer() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        uint256 endDate = campaignContract.getCampaignDetails().endDate;
        // increase the time and withdraw the funds
        vm.warp(endDate + 1 days);
        campaignContract.withdrawFromCampaignPool();

        // should revert because there is
        vm.expectRevert();
        campaignContract.increaseTime(endDate + 7 days);
    }

    function testIncreaseTimeStampbyOwner() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        // increase the time by 7 days
        campaignContract.increaseTime(7 days);
        assertEq(
            campaignContract.getCampaignDetails().endDate,
            block.timestamp + 7 days
        );
    }

    function testSealADealByRoboAffiDAI() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");
        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        vm.stopPrank();

        vm.startPrank(roboAffi);

        campaignContract.sealADeal(publisher, buyer, 1);

        uint256 publisherShares = 36 * 10**17;
        uint256 buyerShares = 54 * 10**17;

        assertEq(mockERC20DAI.balanceOf(dev), 1 * 10**18);
        assertEq(campaignContract.shares(buyer), buyerShares);
        assertEq(campaignContract.shares(publisher), publisherShares);
        assertEq(
            campaignContract.totalPendingShares(),
            buyerShares + publisherShares
        );

        vm.stopPrank();
    }

    function testSealADealByRoboAffiDAIBatch() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");
        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        vm.stopPrank();

        vm.startPrank(roboAffi);

        campaignContract.sealADeal(publisher, buyer, 10);
        uint256 publisherShares = 36 * 10**18;
        uint256 buyerShares = 54 * 10**18;

        assertEq(mockERC20DAI.balanceOf(dev), 10 * 10**18);
        assertEq(campaignContract.shares(buyer), buyerShares);
        assertEq(campaignContract.shares(publisher), publisherShares);
        assertEq(
            campaignContract.totalPendingShares(),
            buyerShares + publisherShares
        );

        vm.stopPrank();
    }

    function testSealADealByRoboAffiUSDC() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("USDC");
        uint256 funds = 1000 * (10**6);
        fundCampaign("USDC", funds);

        vm.stopPrank();
        vm.startPrank(roboAffi);

        campaignContract.sealADeal(publisher, buyer, 1);

        uint256 publisherShares = 36 * 10**5;
        uint256 buyerShares = 54 * 10**5;

        assertEq(mockERC20USDC.balanceOf(dev), 1 * 10**6);
        assertEq(campaignContract.shares(buyer), buyerShares);
        assertEq(campaignContract.shares(publisher), publisherShares);
        assertEq(
            campaignContract.totalPendingShares(),
            buyerShares + publisherShares
        );

        vm.stopPrank();
    }

    function testBuyerReleaseShareReverts() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("USDC");
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectRevert();
        campaignContract.releaseShare();
        vm.stopPrank();
    }

    function testPublisherReleaseShare() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("USDC");
        uint256 funds = 1000 * (10**6);
        fundCampaign("USDC", funds);

        vm.stopPrank();

        vm.startPrank(roboAffi);
        campaignContract.sealADeal(publisher, buyer, 1);
        vm.stopPrank();

        vm.startPrank(publisher);
        uint256 publisherShares = 36 * 10**5;
        campaignContract.releaseShare();

        uint256 availableFunds = campaignContract.getPaymentTokenBalance();
        uint256 affiShare = 1 * 10**6;

        assertEq(mockERC20USDC.balanceOf(publisher), publisherShares);
        assertEq(availableFunds, (funds - publisherShares - affiShare));
        vm.stopPrank();
    }

    function createCampaign(string memory _symbol)
        internal
        returns (CampaignContract)
    {
        uint256 publisherShare = 40;
        uint256 costOfAcquisition = 0;

        if (keccak256(abi.encode(_symbol)) == keccak256(abi.encode("DAI"))) {
            costOfAcquisition = 10 * (10**18);
        } else {
            costOfAcquisition = 10 * (10**6);
        }

        campaignFactory.createCampaign(
            block.timestamp + 40 days,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            owner,
            _symbol,
            // "https://affi.network",
            "1337",
            publisherShare,
            costOfAcquisition
        );

        campaignContract = CampaignContract(campaignFactory.campaigns(0));

        return campaignContract;
    }

    function fundCampaign(string memory _tokenSymbol, uint256 _amount)
        internal
    {
        if (
            keccak256(abi.encode(_tokenSymbol)) == keccak256(abi.encode("DAI"))
        ) {
            mockERC20DAI.approve(address(campaignContract), _amount);
        } else {
            mockERC20USDC.approve(address(campaignContract), _amount);
        }
        campaignContract.fundCampaignPool(_amount);
    }
}
