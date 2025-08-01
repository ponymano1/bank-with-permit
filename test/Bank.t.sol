// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Bank.sol";
import "../src/TigerToken.sol";

contract BankTest is Test {
    Bank public bank;
    TigerToken public tigerToken;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    uint256 public constant INITIAL_SUPPLY = 1000000 ether; // 1M tokens
    uint256 public constant USER_INITIAL_BALANCE = 10000 ether; // 10K tokens

    function setUp() public {
        vm.prank(owner);
        bank = new Bank();

        // 部署TigerToken
        tigerToken = new TigerToken("TigerToken", "TIGER", 18, INITIAL_SUPPLY);

        // 给用户分发token
        tigerToken.transfer(user1, USER_INITIAL_BALANCE);
        tigerToken.transfer(user2, USER_INITIAL_BALANCE);

        // 添加token到支持列表
        vm.prank(owner);
        bank.addSupportedToken(address(tigerToken));
    }

    function testInitialSetup() public view {
        assertEq(tigerToken.name(), "TigerToken");
        assertEq(tigerToken.symbol(), "TIGER");
        assertEq(tigerToken.decimals(), 18);
        assertEq(tigerToken.totalSupply(), INITIAL_SUPPLY);
        assertTrue(bank.supportedTokens(address(tigerToken)));
    }

    function testAddSupportedToken() public {
        TigerToken newToken = new TigerToken(
            "NewTiger",
            "NTIGER",
            18,
            INITIAL_SUPPLY
        );

        vm.prank(owner);
        bank.addSupportedToken(address(newToken));

        assertTrue(bank.supportedTokens(address(newToken)));
    }

    function testRemoveSupportedToken() public {
        vm.prank(owner);
        bank.removeSupportedToken(address(tigerToken));

        assertFalse(bank.supportedTokens(address(tigerToken)));
    }

    function testDeposit() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        tigerToken.approve(address(bank), depositAmount);
        bank.deposit(address(tigerToken), depositAmount);
        vm.stopPrank();

        assertEq(bank.getBalance(user1, address(tigerToken)), depositAmount);
        assertEq(
            tigerToken.balanceOf(user1),
            USER_INITIAL_BALANCE - depositAmount
        );
        assertEq(bank.getTotalDeposits(address(tigerToken)), depositAmount);
    }

    function testDepositWithPermit() public {
        uint256 depositAmount = 1000 * 10 ** 18;
        uint256 deadline = block.timestamp + 1 hours;

        // 创建permit签名
        (uint8 v, bytes32 r, bytes32 s) = _getPermitSignature(
            user1,
            address(bank),
            depositAmount,
            deadline
        );

        vm.prank(user1);
        bank.depositWithPermit(
            address(tigerToken),
            depositAmount,
            deadline,
            v,
            r,
            s
        );

        assertEq(bank.getBalance(user1, address(tigerToken)), depositAmount);
        assertEq(
            tigerToken.balanceOf(user1),
            USER_INITIAL_BALANCE - depositAmount
        );
    }

    function testWithdraw() public {
        uint256 depositAmount = 1000 * 10 ** 18;
        uint256 withdrawAmount = 500 * 10 ** 18;

        // 先存款
        vm.startPrank(user1);
        tigerToken.approve(address(bank), depositAmount);
        bank.deposit(address(tigerToken), depositAmount);

        // 提取
        bank.withdraw(address(tigerToken), withdrawAmount);
        vm.stopPrank();

        assertEq(
            bank.getBalance(user1, address(tigerToken)),
            depositAmount - withdrawAmount
        );
        assertEq(
            tigerToken.balanceOf(user1),
            USER_INITIAL_BALANCE - depositAmount + withdrawAmount
        );
    }

    function testWithdrawAll() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        // 先存款
        vm.startPrank(user1);
        tigerToken.approve(address(bank), depositAmount);
        bank.deposit(address(tigerToken), depositAmount);

        // 提取全部
        bank.withdrawAll(address(tigerToken));
        vm.stopPrank();

        assertEq(bank.getBalance(user1, address(tigerToken)), 0);
        assertEq(tigerToken.balanceOf(user1), USER_INITIAL_BALANCE);
    }

    function testPauseUnpause() public {
        vm.prank(owner);
        bank.pause();

        vm.startPrank(user1);
        tigerToken.approve(address(bank), 1000 * 10 ** 18);

        vm.expectRevert("Pausable: paused");
        bank.deposit(address(tigerToken), 1000 * 10 ** 18);
        vm.stopPrank();

        vm.prank(owner);
        bank.unpause();

        vm.startPrank(user1);
        bank.deposit(address(tigerToken), 1000 * 10 ** 18);
        vm.stopPrank();

        assertEq(bank.getBalance(user1, address(tigerToken)), 1000 * 10 ** 18);
    }

    function testFailDepositUnsupportedToken() public {
        TigerToken unsupportedToken = new TigerToken(
            "Unsupported",
            "UNSUP",
            18,
            INITIAL_SUPPLY
        );

        vm.prank(user1);
        bank.deposit(address(unsupportedToken), 1000);
    }

    function testFailWithdrawInsufficientBalance() public {
        vm.prank(user1);
        bank.withdraw(address(tigerToken), 1000 * 10 ** 18);
    }

    function testFailAddTokenByNonOwner() public {
        TigerToken newToken = new TigerToken(
            "NewTiger",
            "NTIGER",
            18,
            INITIAL_SUPPLY
        );

        vm.prank(user1);
        bank.addSupportedToken(address(newToken));
    }

    function testGetTotalBalance() public {
        uint256 depositAmount1 = 1000 * 10 ** 18;
        uint256 depositAmount2 = 2000 * 10 ** 18;

        // user1存款
        vm.startPrank(user1);
        tigerToken.approve(address(bank), depositAmount1);
        bank.deposit(address(tigerToken), depositAmount1);
        vm.stopPrank();

        // user2存款
        vm.startPrank(user2);
        tigerToken.approve(address(bank), depositAmount2);
        bank.deposit(address(tigerToken), depositAmount2);
        vm.stopPrank();

        assertEq(
            bank.getTotalBalance(address(tigerToken)),
            depositAmount1 + depositAmount2
        );
        assertEq(
            bank.getTotalDeposits(address(tigerToken)),
            depositAmount1 + depositAmount2
        );
    }

    function testEmergencyWithdraw() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        // user1存款
        vm.startPrank(user1);
        tigerToken.approve(address(bank), depositAmount);
        bank.deposit(address(tigerToken), depositAmount);
        vm.stopPrank();

        uint256 ownerBalanceBefore = tigerToken.balanceOf(owner);

        // 紧急提取
        vm.prank(owner);
        bank.emergencyWithdraw(address(tigerToken), depositAmount);

        assertEq(
            tigerToken.balanceOf(owner),
            ownerBalanceBefore + depositAmount
        );
    }

    // 辅助函数：创建permit签名
    function _getPermitSignature(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 nonce = tigerToken.nonces(owner_);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner_,
                spender,
                value,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                tigerToken.DOMAIN_SEPARATOR(),
                structHash
            )
        );

        uint256 privateKey;
        if (owner_ == user1) {
            privateKey = 0x2;
        } else if (owner_ == user2) {
            privateKey = 0x3;
        }

        (v, r, s) = vm.sign(privateKey, digest);
    }
}
