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
        // campaign is active
        assertEq(campaignContract.isCampaignActive(), true);
        campaignContract.increaseCOA(doubleCOA);

        assertEq(
            campaignContract.getCampaignDetails().costOfAcquisition,
            doubleCOA
        );

        vm.stopPrank();
    }

    function testIncreaseCOARevertsIfCampaignIsInactive() public {
        vm.startPrank(owner);
        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);

        // withdraw force close campaign
        vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);
        campaignContract.withdrawFromCampaignPool();

        vm.expectRevert();

        campaignContract.increaseCOA(funds);

        vm.stopPrank();
    }

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

        // doesn't matter if buyer release or not
        // vm.prank(buyer);
        // campaignContract.releaseShare();

        vm.prank(roboAffi);
        vm.expectRevert(notEnoughFunds.selector);
        // // we should not be able create more than 50 deals
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

    function testRevertsIfIncreaseTimeIsLessThanPrevious() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        uint256 end = campaignContract.getCampaignDetails().endDate;
        // less than a day
        vm.expectRevert();
        campaignContract.increaseTime(end - 1 days);

        vm.stopPrank();
    }

    function testEndToEnd() public {
        // owner create and fund the campaign
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        // at this point both total deposits and total balance should be equal
        assertEq(campaignContract.totalDeposits(), funds);
        assertEq(mockERC20DAI.balanceOf(address(campaignContract)), funds);
        vm.stopPrank();

        // lets say we make 5 deals
        vm.prank(roboAffi);
        campaignContract.sealADeal(publisher, buyer, 5);

        // total fee should be 10% of 5 deals
        assertEq(
            campaignContract.totalFees(),
            5 *
                ((campaignContract.getCampaignDetails().costOfAcquisition *
                    10) / 100)
        );

        //toal pending should be 90% of 5 deals
        assertEq(
            campaignContract.totalPendingShares(),
            5 *
                ((campaignContract.getCampaignDetails().costOfAcquisition *
                    90) / 100)
        );

        // now we are going to release some shares
        vm.prank(publisher);
        campaignContract.releaseShare();

        uint256 publisherTotalSoFar = (
            campaignContract.getCampaignDetails().publisherShare
        ) *
            5 *
            1e17; // convert to dai

        // get 10% of pubblisherTotalSoFar
        uint256 protocolFee = (publisherTotalSoFar * 10) / 100;

        // the balance of publisher after release should be equal to 5 deals - 10% protocol fee
        assertEq(
            mockERC20DAI.balanceOf(address(publisher)),
            publisherTotalSoFar - protocolFee
        );

        // we only can do 95 more deals or it reverts
        vm.startPrank(roboAffi);
        vm.expectRevert(notEnoughFunds.selector);

        campaignContract.sealADeal(publisher, buyer, 96);
        vm.stopPrank();

        // so far so good the campaign is active
        assertEq(campaignContract.isCampaignActive(), true);

        // lets do 30 more deals
        vm.prank(roboAffi);
        campaignContract.sealADeal(publisher, buyer, 30);

        // this time we release the buyer share to make sure campaign still active
        vm.prank(buyer);
        campaignContract.releaseShare();

        assertEq(campaignContract.isCampaignActive(), true);

        // if we do   100 - (30  + 5)  deals then pool is drained nso campaign is not  active anymore
        vm.prank(roboAffi);
        campaignContract.sealADeal(publisher, buyer, 65);

        assertEq(campaignContract.isCampaignActive(), false);

        // now owner can not increase time because its not active (no funds)
        vm.startPrank(owner);
        uint256 end = campaignContract.getCampaignDetails().endDate;
        vm.expectRevert();
        campaignContract.increaseTime(end + 7 days);
        vm.stopPrank();

        // owner increase pool budget
        vm.startPrank(owner);
        deal(address(mockERC20DAI), owner, 1000 * (10**18));
        mockERC20DAI.approve(address(campaignContract), 1000 * (10**18));
        campaignContract.increasePoolBudget(1000 * (10**18));
        vm.stopPrank();

        assertEq(campaignContract.isCampaignActive(), true);

        // owner can increase extend duration as well (but not more than 30 days)
        vm.startPrank(owner);
        campaignContract.increaseTime(end + 7 days);
        assertEq(campaignContract.getCampaignDetails().endDate, end + 7 days);

        // owner can withdraw from campaign pool after campaign end
        vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);

        campaignContract.withdrawFromCampaignPool();

        // deposit is 0 now
        // assertEq(campaignContract.totalDeposits(), 0);
        // campaign is not active
        assertEq(campaignContract.isCampaignActive(), false);

        // owner can ressurect the campaign
        mockERC20DAI.approve(address(campaignContract), 100 * (10**18));
        campaignContract.increasePoolBudget(100 * 1e18);

        //total deposits should be 100 now
        // assertEq(campaignContract.totalDeposits(), 100 * 1e18);

        //  campaign is resurrected
        assertEq(campaignContract.isCampaignActive(), true);

        vm.stopPrank();
    }

    // campaign is resurrected

    // now owner deposit some funds and increase time

    function testIsCampaignActiveOwnerWithdraw() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);
        vm.stopPrank();

        assertEq(campaignContract.isCampaignActive(), true);
        // make some deals
        vm.prank(roboAffi);
        campaignContract.sealADeal(publisher, buyer, 5);

        // withdraw and retest
        vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);
        vm.prank(owner);
        campaignContract.withdrawFromCampaignPool();

        // deposit is 0 now
        assertEq(campaignContract.totalDeposits(), 0);
        // campaign is not active
        assertEq(campaignContract.isCampaignActive(), false);
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

    function testReviveCampaignAfterAllRoboAffiDeals() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);
        vm.stopPrank();

        vm.startPrank(roboAffi);
        // we make 99 deals first and campaign should be still active
        campaignContract.sealADeal(address(0xb), address(0xa), 99);
        assertEq(campaignContract.isCampaignActive(), true);
        // now we do one more deal and campaign should be closed
        campaignContract.sealADeal(address(0xb), address(0xa), 1);
        assertEq(campaignContract.isCampaignActive(), false);
        vm.stopPrank();
    }

    function testReviveAClosedCampaignAfterWithdraw() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        uint256 endDate = campaignContract.getCampaignDetails().endDate;
        // increase the time and withdraw the funds
        vm.warp(endDate + 1 days);
        // console.log(block.timestamp);
        campaignContract.withdrawFromCampaignPool();

        assertEq(campaignContract.isCampaignActive(), false);

        // give more tokens to the owner
        deal(address(mockERC20DAI), owner, 100 * (10**18));
        mockERC20DAI.approve(address(campaignContract), 100 * (10**18));

        campaignContract.increasePoolBudget(100 * (10**18));

        assertEq(campaignContract.isCampaignActive(), true);
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

    function testIncreaseTimeRevertsifTimeStampIsLessThanAday() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        // future 12 hours
        uint256 newDate = block.timestamp + 12 hours;
        // should revert because 12 hours is less than a day
        vm.expectRevert();
        campaignContract.increaseTime(newDate);
    }

    function testIncreaseTimeStampbyOwner() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("DAI");

        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        uint256 beforeIncrease = campaignContract.getCampaignDetails().endDate;
        // increase the time by 7 days
        campaignContract.increaseTime(
            campaignContract.getCampaignDetails().endDate + 7 days
        );
        uint256 afterIncrease = campaignContract.getCampaignDetails().endDate;

        // check if the time is increased
        assertEq(afterIncrease, beforeIncrease + 7 days);
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
