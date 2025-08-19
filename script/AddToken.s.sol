// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Bank.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AddTokenScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // 从环境变量获取合约地址
        address bankAddress = vm.envAddress("BANK_ADDRESS");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");

        console.log("Adding token to Bank");
        console.log("Deployer:", deployer);
        console.log("Bank address:", bankAddress);
        console.log("Token address:", tokenAddress);

        Bank bank = Bank(bankAddress);

        // 检查token信息
        try ERC20(tokenAddress).name() returns (string memory name) {
            console.log("Token name:", name);
        } catch {
            console.log("Could not get token name");
        }

        try ERC20(tokenAddress).symbol() returns (string memory symbol) {
            console.log("Token symbol:", symbol);
        } catch {
            console.log("Could not get token symbol");
        }

        try ERC20(tokenAddress).decimals() returns (uint8 decimals) {
            console.log("Token decimals:", decimals);
        } catch {
            console.log("Could not get token decimals");
        }

        vm.startBroadcast(deployerPrivateKey);

        // 添加token到Bank
        bank.addSupportedToken(tokenAddress);

        vm.stopBroadcast();

        console.log("Token successfully added to Bank!");

        // 验证token是否已添加
        bool isSupported = bank.supportedTokens(tokenAddress);
        console.log("Token supported status:", isSupported);
    }
}
