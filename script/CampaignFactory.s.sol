// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/CampaignFactory.sol";
import "../test/Mocks/MockERC20.sol";

contract DeployFactory is Script {
    function run() external {
        vm.startBroadcast();

        ERC20 mockERC20DAI = new MockERC20("DAI", "DAI", 100 * (10**18), 18);
        ERC20 mockERC20USDC = new MockERC20("USDC", "USDC", 100 * (10**6), 6);

        CampaignContract.BountyInfo memory bountyInfo;

        bountyInfo.publisherShare = 60;
        bountyInfo.buyerShare = 40;

        bountyInfo.bounty = 10 * (10**6);

        CampaignFactory campaignFactory = new CampaignFactory(address(mockERC20DAI), address(mockERC20USDC));

        campaignFactory.createCampaign(
            30 days,
            0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
            msg.sender,
            bountyInfo,
            "USDC",
            "https://affi.network",
            "1337"
        );

        vm.makePersistent(address(campaignFactory));
        vm.makePersistent(address(mockERC20DAI));
        vm.makePersistent(address(mockERC20USDC));

        console.log(
            "Factory : %s | DAI : %s | USDC : %s",
            address(campaignFactory),
            address(mockERC20DAI),
            address(mockERC20USDC)
        );

        vm.stopBroadcast();
    }
}
