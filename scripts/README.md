# TypeScript 脚本使用说明

本目录包含使用 ethers 6 实现的 TypeScript 脚本，用于与 Bank 合约交互。

## 安装依赖

首先安装所需的依赖包：

```bash
npm install
```

## 脚本列表

### 1. depositWithPermit.ts - 使用 Permit 进行存款

这个脚本实现了通过 EIP-2612 permit 功能进行 gasless 存款。

**功能特性：**

- 自动创建 EIP-712 签名
- 验证代币是否被 Bank 支持
- 显示详细的交易信息和余额变化
- 支持自定义截止时间

**使用方法：**

1. **设置环境变量**：

```bash
# 复制环境变量示例文件
cp ../env.example .env

# 编辑 .env 文件，填入实际值
PRIVATE_KEY=your_private_key_here
RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
BANK_ADDRESS=0x...  # 已部署的Bank合约地址
TOKEN_ADDRESS=0x... # 要存款的代币地址
AMOUNT=10           # 存款数量（可选，默认10）
DEADLINE=1700000000 # 截止时间戳（可选，默认20分钟后）
```

2. **运行脚本**：

```bash
# 使用 npm script
npm run deposit

# 或直接使用 ts-node
npx ts-node scripts/depositWithPermit.ts
```

### 2. test.ts - 连接测试脚本

用于测试 ethers 6 连接和基本功能。

```bash
npm run test:ts
```

## 环境变量说明

| 变量名          | 必需 | 说明                                        |
| --------------- | ---- | ------------------------------------------- |
| `PRIVATE_KEY`   | ✅   | 用户私钥（用于签名交易）                    |
| `BANK_ADDRESS`  | ✅   | Bank 合约地址                               |
| `TOKEN_ADDRESS` | ✅   | 要存款的代币合约地址                        |
| `RPC_URL`       | ❌   | RPC 节点 URL（默认：http://localhost:8545） |
| `AMOUNT`        | ❌   | 存款数量（默认：10）                        |
| `DEADLINE`      | ❌   | permit 截止时间戳（默认：20 分钟后）        |

## 工作流程

1. **验证配置**：检查环境变量和网络连接
2. **获取代币信息**：读取代币名称、符号、小数位
3. **检查支持状态**：验证代币是否被 Bank 支持
4. **创建 Permit 签名**：
   - 获取当前 nonce
   - 创建 EIP-712 域名分隔符
   - 生成结构化签名数据
   - 使用私钥签名
5. **执行存款**：调用 Bank 合约的 `depositWithPermit` 方法
6. **验证结果**：检查交易确认和余额变化

## 错误处理

脚本包含完整的错误处理机制：

- 环境变量验证
- 网络连接检查
- 合约调用错误处理
- 签名验证
- 交易确认等待

## 示例输出

```
Configuration:
  RPC URL: https://sepolia.infura.io/v3/...
  Bank Address: 0x1234...
  Token Address: 0x5678...
  Amount: 10 tokens

Token Info:
  Name: Tiger Token
  Symbol: TIGER
  Decimals: 18

Token supported by Bank: true
Current balance in Bank: 0.0 tokens

=== Starting Deposit with Permit ===
Bank Address: 0x1234...
Token Address: 0x5678...
User Address: 0xabcd...
Amount: 10 tokens
Deadline: 2024-01-15T10:30:00.000Z
Amount in wei: 10000000000000000000

Current nonce: 0
Permit signature created: 0x...
Signature components:
  v: 27
  r: 0x...
  s: 0x...

Executing depositWithPermit...
Transaction hash: 0x...
Waiting for confirmation...
Transaction confirmed in block: 12345678

Deposited: 10.0 tokens

=== Deposit with Permit Completed Successfully ===
```

## 注意事项

1. **私钥安全**：确保私钥安全，不要提交到版本控制系统
2. **网络选择**：根据目标网络选择合适的 RPC URL
3. **Gas 费用**：确保账户有足够的 ETH 支付 gas 费用
4. **代币余额**：确保账户有足够的代币进行存款
5. **截止时间**：permit 签名有截止时间，过期后需要重新签名

## 故障排除

### 常见错误

1. **"Token is not supported"**

   - 确保代币已被添加到 Bank 支持的代币列表中
   - 使用 `AddToken.s.sol` 脚本添加代币

2. **"Invalid signature"**

   - 检查私钥是否正确
   - 确保截止时间未过期
   - 验证 nonce 是否正确

3. **"Insufficient balance"**

   - 确保账户有足够的代币余额
   - 检查代币合约是否正常工作

4. **"Transaction failed"**
   - 检查 gas 费用是否足够
   - 验证网络连接是否正常
   - 查看交易详情获取具体错误信息
