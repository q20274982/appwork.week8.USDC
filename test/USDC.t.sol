// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {USDC, USDCV2} from "../src/USDCV2.sol";

interface IUpgrade {
    function upgradeTo(address newImplementation) external;
}

contract USDCTest is Test {
    // proxy address & USDC erc20 address
    address public constant PROXY = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // admin address
    address public constant ADMIN = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
    // impl address https://etherscan.io/address/0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF
    address public constant ERC20_USDC = 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF;

    USDC proxyUSDC;
    USDCV2 proxyUSDCV2;
    IUpgrade proxy;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");
        proxy = IUpgrade(PROXY);
        proxyUSDC = USDC(address(proxy));
    }

    function test_IsUpgradeSuccess() public {
        vm.startPrank(ADMIN);
        bytes32 s0 = vm.load(address(proxy), bytes32(uint256(0)));
        bytes32 s1 = vm.load(address(proxy), bytes32(uint256(1)));
        bytes32 s2 = vm.load(address(proxy), bytes32(uint256(2)));

        proxy.upgradeTo(address(new USDCV2()));
        proxyUSDCV2 = USDCV2(address(proxy));

        bytes32 s0_ = vm.load(address(proxy), bytes32(uint256(0)));
        bytes32 s1_ = vm.load(address(proxy), bytes32(uint256(1)));
        bytes32 s2_ = vm.load(address(proxy), bytes32(uint256(2)));

        /**
         * check if the first three slots are the same
         * before and after the upgrade
         */
        assertEq(s0, s0_);
        assertEq(s1, s1_);
        assertEq(s2, s2_);

        vm.stopPrank();

        assertEq(proxyUSDCV2.VERSIONV2(), "USDCV2");
    }

    function test_addToWhilteList() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        /**
         * upgrade process
         */
        vm.startPrank(ADMIN);
        proxy.upgradeTo(address(new USDCV2()));
        proxyUSDCV2 = USDCV2(address(proxy));
        vm.stopPrank();

        /**
         * when calling addToWhiteList(user1) should
         * get true by calling isInWhiteList(user1)
         */
        proxyUSDCV2.addToWhiteList(user1);
        assertEq(proxyUSDCV2.isInWhiteList(user1), true);

        /**
         * when calling addToWhiteList(user2) should
         * get true by calling isInWhiteList(user2)
         */
        assertEq(proxyUSDCV2.isInWhiteList(user2), false);
    }

    function test_mint() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        uint256 dummyAmount = 1000;

        /**
         * upgrade process
         */
        vm.startPrank(ADMIN);
        proxy.upgradeTo(address(new USDCV2()));
        proxyUSDCV2 = USDCV2(address(proxy));
        vm.stopPrank();

        /**
         * pretend as user1
         */
        vm.startPrank(user1);
        uint256 amount = proxyUSDCV2.balanceOf(user1);
        assertEq(amount, 0);

        /**
         * add user1 to whiteList & mint 1000
         */
        proxyUSDCV2.addToWhiteList(user1);
        proxyUSDCV2.mint(user1, dummyAmount);

        /**
         * user1 should have 1000
         */
        uint256 amount_ = proxyUSDCV2.balanceOf(user1);
        assertEq(amount_, dummyAmount);

        vm.stopPrank();

        /**
         * pretend as user2
         */
        vm.startPrank(user2);

        /**
         * user2 mint without added to whilteList
         */
        vm.expectRevert("_to not in whiteList");
        proxyUSDCV2.mint(user2, dummyAmount);
        vm.stopPrank();
    }

    function test_transfer() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        uint256 dummyAmount = 1000;
        uint256 dummyAmount2 = 500;

        /**
         * upgrade process
         */
        vm.startPrank(ADMIN);
        proxy.upgradeTo(address(new USDCV2()));
        proxyUSDCV2 = USDCV2(address(proxy));
        vm.stopPrank();

        /**
         * add user1 to whiteList & mint 1000 & transfer 500 to user2
         */
        vm.startPrank(user1);
        proxyUSDCV2.addToWhiteList(user1);
        proxyUSDCV2.mint(user1, dummyAmount);
        proxyUSDCV2.transfer(user2, dummyAmount2);
        vm.stopPrank();

        assertEq(
            proxyUSDCV2.balanceOf(user1),
            dummyAmount - dummyAmount2 // 500
        );

        assertEq(
            proxyUSDCV2.balanceOf(user2),
            dummyAmount2 // 500
        );

        /**
         * user2 transfer without added to whilteList
         */
        vm.expectRevert("msg.sender not in whiteList");
        vm.prank(user2);
        proxyUSDCV2.transfer(user1, dummyAmount2);
    }
}
