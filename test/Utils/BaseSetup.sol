// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "forge-std/Test.sol";
import "./Utils.sol";

contract BaseSetup is Test {
    address payable[] internal users;
    address internal owner;
    address internal dev;
    address internal user;
    address internal publisher;
    address internal roboAffi;
    address internal buyer;

    Utils internal utils;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(4);
        owner = users[0];
        vm.label(owner, "Owner");
        dev = users[1];
        vm.label(dev, "Developer");
        publisher = users[2];
        vm.label(publisher, "Publisher");
        roboAffi = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
        vm.label(roboAffi, "RoboAffi");
        buyer = users[3];
        vm.label(buyer, "Buyer");
    }
}
