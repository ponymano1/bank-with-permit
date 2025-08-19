# 部署脚本使用说明

本目录包含用于部署和管理 Bank 合约的脚本。

## 脚本列表

### 1. Deploy.s.sol - 部署脚本

用于部署 Bank 合约和 TigerToken 合约。

**功能：**

- 部署 TigerToken (1,000,000 个代币)
- 部署 Bank 合约
- 自动将 TigerToken 添加到 Bank 支持的代币列表中

**使用方法：**

```bash
# 设置环境变量
export PRIVATE_KEY=your_private_key_here

# 部署到本地网络
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# 部署到测试网
forge script script/Deploy.s.sol --rpc-url https://sepolia.infura.io/v3/YOUR_PROJECT_ID --broadcast

# 部署到主网
forge script script/Deploy.s.sol --rpc-url https://mainnet.infura.io/v3/YOUR_PROJECT_ID --broadcast
```

### 2. AddToken.s.sol - 添加代币脚本

用于向已部署的 Bank 合约添加新的 ERC20 代币。

**功能：**

- 验证代币合约信息 (名称、符号、小数位)
- 将代币添加到 Bank 支持的代币列表中
- 验证添加是否成功

**使用方法：**

```bash
# 设置环境变量
export PRIVATE_KEY=your_private_key_here
export BANK_ADDRESS=0x...  # Bank合约地址
export TOKEN_ADDRESS=0x... # 要添加的代币地址

# 执行脚本
forge script script/AddToken.s.sol --rpc-url https://sepolia.infura.io/v3/YOUR_PROJECT_ID --broadcast
```

## 环境变量配置

复制 `env.example` 文件为 `.env` 并填入实际值：

```bash
cp env.example .env
```

然后编辑 `.env` 文件：

```env
# 部署者私钥 (用于签名交易)
PRIVATE_KEY=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

# 网络配置 (可选)
RPC_URL=https://eth-mainnet.alchemyapi.io/v2/YOUR_API_KEY
CHAIN_ID=1

# 合约地址 (用于AddToken脚本)
BANK_ADDRESS=0x1234567890123456789012345678901234567890
TOKEN_ADDRESS=0x1234567890123456789012345678901234567890
```

## 注意事项

1. **私钥安全**：请确保私钥安全，不要提交到版本控制系统
2. **网络选择**：根据目标网络选择合适的 RPC URL
3. **Gas 费用**：确保账户有足够的 ETH 支付 gas 费用
4. **权限验证**：确保执行脚本的账户是 Bank 合约的 owner

## 验证部署

部署完成后，可以使用以下命令验证合约：

```bash
# 检查 Bank 合约是否支持 TigerToken
cast call <BANK_ADDRESS> "supportedTokens(address)(bool)" <TIGER_TOKEN_ADDRESS>

# 检查 Bank 合约 owner
cast call <BANK_ADDRESS> "owner()(address)"
```
