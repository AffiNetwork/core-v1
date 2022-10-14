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

        vm.startPrank(owner);
        mockERC20DAI = new MockERC20("DAI", "DAI", 1000 * (10**18), 18);
        mockERC20USDC = new MockERC20("USDC", "USDC", 1000 * (10**6), 6);

        campaignFactory = new CampaignFactory(
            address(mockERC20DAI),
            address(mockERC20USDC)
        );

        vm.stopPrank();
    }

    function testCreateCampaign() public {
        campaignContract = createCampaign("DAI");
        // check campaign exists
        uint256 availableFunds = campaignContract.getPaymentTokenBalance();
        assertEq(availableFunds, 0);
    }

    function testCreateMultipleCampaigns() public {
        uint256 buyerShare = 40;
        uint256 costOfAcquisition = 10 * (10**18);

        campaignFactory.createCampaign(
            block.timestamp + 30 days,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            owner,
            "DAI",
            "https://affi.network",
            "1337",
            buyerShare,
            costOfAcquisition
        );

        campaignFactory.createCampaign(
            block.timestamp + 30 days,
            0xdeAdBEEf8F259C7AeE6E5B2AA729821864227E84,
            dev,
            "DAI",
            "https://brandface.io",
            "1337",
            buyerShare,
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

    function testFailFundCampaignWithoutEnoughFunding() public {
        vm.startPrank(owner);
        // for a $10 bount pool should be $1000 so revert
        uint256 funds = 100 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);
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

    function testFailFundCampaign() public {
        vm.startPrank(owner);
        uint256 funds = 1000 * (10**18);
        campaignContract = createCampaign("DAI");
        fundCampaign("DAI", funds);
        // FUNDS AGAIN
        fundCampaign("DAI", funds);
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

        campaignContract.sealADeal(publisher, buyer);

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

    function testFailWithdrawFromCampaignWrongTime() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");

        // set the time to 10 day
        vm.warp(block.timestamp + 10 days);
        campaignContract.withdrawFromCampaignPool();

        vm.stopPrank();
    }

    function testFailWithdrawFromCampaignNotOwner() public {
        campaignContract = createCampaign("DAI");
        campaignContract.withdrawFromCampaignPool();
    }

    function testFailAlreadyParticipated() public {
        vm.startPrank(dev);
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

    function testFailParticipateIfCampaignDone() public {
        campaignContract = createCampaign("DAI");

        // set the time to 31 days
        vm.warp(campaignContract.getCampaignDetails().endDate + 1 days);

        campaignContract.participate("https://affi.network/0x1137");
    }

    function testParticipateAsPublisher() public {
        campaignContract = createCampaign("DAI");

        vm.startPrank(publisher);

        campaignContract.participate("https://affi.network/0x1137");

        assertEq(campaignContract.totalPublishers(), 1);

        vm.stopPrank();
    }

    function testFailIfPendingIsBiggerThanTokenBalance() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("DAI");
        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        vm.stopPrank();
        vm.startPrank(roboAffi);
        // 100  + 1 deal
        for (uint256 i = 0; i <= 100 + 1; i++) {
            campaignContract.sealADeal(publisher, buyer);
        }
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
        uint256 funds = 1000 * (10**18);
        fundCampaign("DAI", funds);

        vm.stopPrank();

        vm.startPrank(roboAffi);

        campaignContract.sealADeal(publisher, buyer);

        uint256 buyerShares = 36 * 10**17;
        uint256 publisherShares = 54 * 10**17;

        assertEq(mockERC20DAI.balanceOf(dev), 1 * 10**18);
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

        campaignContract.sealADeal(publisher, buyer);

        uint256 buyerShares = 36 * 10**5;
        uint256 publisherShares = 54 * 10**5;

        assertEq(mockERC20USDC.balanceOf(dev), 1 * 10**6);
        assertEq(campaignContract.shares(buyer), buyerShares);
        assertEq(campaignContract.shares(publisher), publisherShares);
        assertEq(
            campaignContract.totalPendingShares(),
            buyerShares + publisherShares
        );

        vm.stopPrank();
    }

    function testFailBuyerReleaseShare() public {
        vm.startPrank(owner);
        campaignContract = createCampaign("USDC");
        vm.stopPrank();

        vm.startPrank(buyer);
        campaignContract.releaseShare();
        vm.stopPrank();
    }

    function testBuyerReleaseShare() public {
        vm.startPrank(owner);

        campaignContract = createCampaign("USDC");
        uint256 funds = 1000 * (10**6);
        fundCampaign("USDC", funds);

        vm.stopPrank();

        vm.startPrank(roboAffi);
        campaignContract.sealADeal(publisher, buyer);
        vm.stopPrank();

        vm.startPrank(buyer);
        uint256 buyerShares = 36 * 10**5;
        campaignContract.releaseShare();

        uint256 availableFunds = campaignContract.getPaymentTokenBalance();
        uint256 affiShare = 1 * 10**6;

        assertEq(mockERC20USDC.balanceOf(buyer), buyerShares);
        assertEq(availableFunds, (funds - buyerShares - affiShare));
        vm.stopPrank();
    }

    function createCampaign(string memory _symbol)
        internal
        returns (CampaignContract)
    {
        uint256 buyerShare = 40;
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
            "https://affi.network",
            "1337",
            buyerShare,
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
