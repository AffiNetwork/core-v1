// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/CampaignFactory.sol";
import "../test/Mocks/MockERC20.sol";

contract DeployFactory is Script {
    function run() external {
        if (
            keccak256(abi.encode(vm.envString("DEPLOY"))) ==
            keccak256(abi.encode("LOCAL"))
        ) {
            vm.startBroadcast();

            ERC20 mockERC20DAI = new MockERC20(
                "DAI",
                "DAI",
                3000 * (10**18),
                18
            );
            ERC20 mockERC20USDC = new MockERC20(
                "USDC",
                "USDC",
                3000 * (10**6),
                6
            );

            uint256 buyerShare = 40;
            uint256 costOfAcquisition = 10 * (10**18);

            CampaignFactory campaignFactory = new CampaignFactory(
                address(mockERC20DAI),
                address(mockERC20USDC)
            );

            campaignFactory.createCampaign(
                block.timestamp + 30 days + 15 minutes,
                0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
                msg.sender,
                "DAI",
                "https://affi.network",
                "1337",
                buyerShare,
                costOfAcquisition
            );

            address campaignContractAddress = campaignFactory.campaigns(0);

            CampaignContract campaignContract = CampaignContract(
                campaignContractAddress
            );

            mockERC20DAI.approve(campaignContractAddress, 1000 * (10**18));

            campaignContract.fundCampaignPool(1000 * (10**18));

            uint256 campaignBalance = mockERC20DAI.balanceOf(
                address(campaignContractAddress)
            );

            console.logUint(campaignBalance);
            console.logAddress(campaignContractAddress);

            console.log(
                "Factory : %s  |  DAI : %s | USDC : %s",
                address(campaignFactory),
                address(mockERC20DAI),
                address(mockERC20USDC)
            );

            vm.stopBroadcast();
        }

        if (
            keccak256(abi.encode(vm.envString("DEPLOY"))) ==
            keccak256(abi.encode("MUMBAI"))
        ) {
            uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
            vm.startBroadcast(deployerPrivateKey);

            new CampaignFactory(
                vm.envAddress("MUMBAI_DAI_ADDRESS"),
                vm.envAddress("MUMBAI_USDC_ADDRESS")
            );

            vm.stopBroadcast();
        }

        if (
            keccak256(abi.encode(vm.envString("DEPLOY"))) ==
            keccak256(abi.encode("POLYGON"))
        ) {
            uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
            vm.startBroadcast(deployerPrivateKey);

            new CampaignFactory(
                vm.envAddress("POLYGON_DAI_ADDRESS"),
                vm.envAddress("POLYGON_USDC_ADDRESS")
            );

            vm.stopBroadcast();
        }
    }
}
