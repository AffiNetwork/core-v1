// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
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
        users = utils.createUsers(5);
        owner = users[0];
        vm.label(owner, "Owner");
        dev = users[1];
        vm.label(dev, "Developer");
        publisher = users[2];
        vm.label(publisher, "Publisher");
        roboAffi = users[3];
        vm.label(roboAffi, "RoboAffi");
        buyer = users[4];
        vm.label(buyer, "Buyer");
    }
}
