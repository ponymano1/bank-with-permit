// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Bank
 * @dev A secure bank contract that allows users to deposit and withdraw ERC20 tokens
 * @notice Supports both traditional approve/transferFrom and gasless permit deposits
 */
contract Bank is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    // 存储用户在不同token中的余额
    mapping(address => mapping(address => uint256)) public balances;

    // 存储支持的token列表
    mapping(address => bool) public supportedTokens;

    // 存储每个token的总存款量
    mapping(address => uint256) public totalDeposits;

    // 事件
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );
    event TokenAdded(address indexed token, uint256 timestamp);
    event TokenRemoved(address indexed token, uint256 timestamp);
    event EmergencyWithdraw(
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    // 错误定义
    error TokenNotSupported();
    error InvalidAmount();
    error InsufficientBalance();
    error InvalidTokenAddress();
    error TokenAlreadySupported();
    error TokenNotCurrentlySupported();

    constructor() Ownable(msg.sender) {}

    /**
     * @notice 添加支持的token
     * @param token token地址
     */
    function addSupportedToken(address token) external onlyOwner {
        if (token == address(0)) revert InvalidTokenAddress();
        if (supportedTokens[token]) revert TokenAlreadySupported();

        supportedTokens[token] = true;
        emit TokenAdded(token, block.timestamp);
    }

    /**
     * @notice 移除支持的token
     * @param token token地址
     */
    function removeSupportedToken(address token) external onlyOwner {
        if (!supportedTokens[token]) revert TokenNotCurrentlySupported();

        supportedTokens[token] = false;
        emit TokenRemoved(token, block.timestamp);
    }

    /**
     * @notice 普通存款方法
     * @param token token地址
     * @param amount 存款数量
     */
    function deposit(
        address token,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        if (!supportedTokens[token]) revert TokenNotSupported();
        if (amount == 0) revert InvalidAmount();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender][token] += amount;
        totalDeposits[token] += amount;

        emit Deposit(msg.sender, token, amount, block.timestamp);
    }

    /**
     * @notice 使用permit签名进行存款
     * @param token token地址
     * @param amount 存款数量
     * @param deadline permit截止时间
     * @param v 签名参数v
     * @param r 签名参数r
     * @param s 签名参数s
     */
    function depositWithPermit(
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant whenNotPaused {
        if (!supportedTokens[token]) revert TokenNotSupported();
        if (amount == 0) revert InvalidAmount();

        // 使用permit批准
        IERC20Permit(token).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // 转账
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender][token] += amount;
        totalDeposits[token] += amount;

        emit Deposit(msg.sender, token, amount, block.timestamp);
    }

    /**
     * @notice 提取token
     * @param token token地址
     * @param amount 提取数量
     */
    function withdraw(
        address token,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        if (!supportedTokens[token]) revert TokenNotSupported();
        if (amount == 0) revert InvalidAmount();
        if (balances[msg.sender][token] < amount) revert InsufficientBalance();

        balances[msg.sender][token] -= amount;
        totalDeposits[token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, token, amount, block.timestamp);
    }

    /**
     * @notice 提取所有余额
     * @param token token地址
     */
    function withdrawAll(address token) external nonReentrant whenNotPaused {
        if (!supportedTokens[token]) revert TokenNotSupported();

        uint256 amount = balances[msg.sender][token];
        if (amount == 0) revert InvalidAmount();

        balances[msg.sender][token] = 0;
        totalDeposits[token] -= amount;
        IERC20(token).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, token, amount, block.timestamp);
    }

    /**
     * @notice 获取用户余额
     * @param user 用户地址
     * @param token token地址
     * @return 用户余额
     */
    function getBalance(
        address user,
        address token
    ) external view returns (uint256) {
        return balances[user][token];
    }

    /**
     * @notice 获取合约中token总余额
     * @param token token地址
     * @return token总余额
     */
    function getTotalBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice 获取token总存款量
     * @param token token地址
     * @return token总存款量
     */
    function getTotalDeposits(address token) external view returns (uint256) {
        return totalDeposits[token];
    }

    /**
     * @notice 暂停合约
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice 恢复合约
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice 紧急提取函数（仅限owner）
     * @param token token地址
     * @param amount 提取数量
     */
    function emergencyWithdraw(
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
        emit EmergencyWithdraw(token, amount, block.timestamp);
    }
}
