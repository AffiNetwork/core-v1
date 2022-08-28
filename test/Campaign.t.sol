// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CampaignFactory.sol";
import "../src/CampaignContract.sol";

contract CampaignFactoryTest is Test {
    CampaignFactory public campaignFactory;
    CampaignContract public campaignContract;

    function setUp() public {
        campaignFactory = new CampaignFactory();
    }

    function testCreateCampaign() public {
        campaignFactory.CreateCampaign(
            3 days,
            40,
            60,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            "https://affi.network"
        );

        campaignContract = CampaignContract(campaignFactory.campaigns(0));

        console.logUint(campaignContract.getCampaignDetails().buyerShare);
    }
}
// function testIncrement() public {
//     counter.increment();
//     assertEq(counter.number(), 1);
// }
// function testSetNumber(uint256 x) public {
//     counter.setNumber(x);
//     assertEq(counter.number(), x);
// }
