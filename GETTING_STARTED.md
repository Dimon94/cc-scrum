# CC-Scrum 快速开始指南

## 🎯 5分钟快速体验

### 第一步：激活系统
```bash
# 检查代理状态
ls .claude/agents/

# 检查可用命令
ls .claude/slash_commands/
```

### 第二步：体验端到端工作流
让我们通过一个完整的例子来体验 CC-Scrum 的强大功能。

## 📖 完整示例：实现用户登录功能

### 场景设置
假设我们收到一个业务需求："用户需要能够安全地登录系统访问个人功能"

### 步骤 1：需求分析 (@po)
```
@po 将"用户需要能够安全地登录系统访问个人功能"转换为标准用户故事，包含验收标准和优先级
```

**预期输出：**
```markdown
## 用户故事 #001: 安全用户登录

**作为** 一个注册用户
**我想要** 通过用户名和密码安全登录系统
**以便** 我能够访问我的个人功能和数据

### 验收标准
- [ ] 用户可以使用用户名/邮箱和密码登录
- [ ] 登录失败时显示清晰的错误信息
- [ ] 登录成功后重定向到用户仪表板
- [ ] 实现账户锁定机制防止暴力破解
- [ ] 支持"记住我"功能
- [ ] 登录会话在30天后自动过期

### 业务价值
- 保护用户数据安全
- 提供个性化用户体验
- 满足数据保护合规要求

### 优先级
**Must Have** - 核心功能，影响系统可用性

### 估算
**8 故事点** (考虑安全实现复杂性)
```

### 步骤 2：智能任务分解 (/meta-todo)
```
/meta-todo "作为注册用户，我想要通过用户名和密码安全登录系统，以便访问个人功能" --tier=2 --background
```

**预期输出：**
```markdown
## Meta-Todo 分析结果

### 智能分析
- **复杂度等级**: Tier 2 (复杂功能)
- **预估总时间**: 18-24 小时
- **关键路径**: 6个核心任务
- **并行机会**: 3个任务可并行执行
- **背景任务**: 4个研究/准备任务已启动

### 任务分解树

**A1. 登录安全研究与设计** (2小时) [背景执行中]
├─ 依赖: 无
├─ 负责: @sec + @arch
├─ 交付物: 安全要求文档，架构设计
└─ 验收: 安全标准确定，技术方案评审通过

**A2. 数据库用户表设计** (1小时)
├─ 依赖: A1
├─ 负责: @arch + @dev
├─ 交付物: 数据库迁移脚本
└─ 验收: 用户表支持安全登录字段

**A3. 后端认证API实现** (6小时)
├─ 依赖: A2
├─ 负责: @dev
├─ 交付物: 登录API + 单元测试
└─ 验收: API通过所有测试，支持错误处理

**A4. 前端登录界面** (4小时) [可与A3并行]
├─ 依赖: A1 (设计规范)
├─ 负责: @dev
├─ 交付物: 登录表单 + 验证逻辑
└─ 验收: UI符合设计规范，验证逻辑完整

**A5. 会话管理实现** (3小时)
├─ 依赖: A3
├─ 负责: @dev
├─ 交付物: 会话管理中间件
└─ 验收: 安全会话管理，自动过期

**A6. 安全测试与加固** (4小时)
├─ 依赖: A3, A4, A5
├─ 负责: @sec + @qa
├─ 交付物: 安全测试报告，加固建议
└─ 验收: 通过安全扫描，无高危漏洞

**A7. 端到端测试** (2小时) [背景执行]
├─ 依赖: A6
├─ 负责: @qa
├─ 交付物: 自动化测试套件
└─ 验收: 覆盖所有用户场景，通过率>95%

### 背景任务进行中
🔄 **安全最佳实践研究** (WebSearch + WebFetch)
🔄 **现有认证模式分析** (Grep + Read)
🔄 **性能基准测试准备** (测试数据生成)
🔄 **UI组件库集成** (依赖分析)

### 风险评估
⚠️ **中等风险**: 安全实现复杂度可能影响进度
✅ **缓解措施**: 增加@sec专家Review，参考业界标准
```

### 步骤 3：架构审查 (@arch)
```
@arch 为用户登录功能提供技术架构建议，考虑安全性、性能和可扩展性，并创建ADR文档
```

**预期输出：**
```markdown
## 架构决策：用户登录系统

### 技术选型建议

**认证策略**
- **主选方案**: JWT + Refresh Token
- **理由**: 无状态设计，支持分布式部署，客户端存储友好
- **备选方案**: Session-based认证 (简单场景)

**密码安全**
- **算法**: bcrypt (cost factor: 12)
- **盐值**: 随机生成，每用户独立
- **密码策略**: 最少8字符，包含大小写字母和数字

**数据库设计**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  failed_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMP NULL,
  last_login TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
```

### 安全考虑
- **暴力破解防护**: 5次失败后锁定15分钟
- **会话管理**: 30天过期，支持提前刷新
- **HTTPS强制**: 所有认证相关请求
- **CSRF防护**: SameSite cookies + Token验证

### 性能目标
- **响应时间**: 登录请求 <200ms (95th percentile)
- **并发处理**: 支持1000 QPS登录请求
- **缓存策略**: Redis缓存用户会话状态

### 监控指标
- 登录成功率
- 平均响应时间
- 失败登录尝试
- 账户锁定频率
```

### 步骤 4：开发实现 (@dev)
```
@dev 实现登录功能的后端API，使用@arch提供的架构方案，展示关键代码变更
```

**预期输出：**
```markdown
## 登录功能实现

### 核心实现文件

**1. 用户模型 (models/User.js)**
```javascript
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

class User {
  static async authenticate(identifier, password) {
    const user = await this.findByEmailOrUsername(identifier);
    if (!user) return { success: false, error: 'Invalid credentials' };

    if (user.isLocked()) {
      return { success: false, error: 'Account temporarily locked' };
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      await user.incrementFailedAttempts();
      return { success: false, error: 'Invalid credentials' };
    }

    await user.resetFailedAttempts();
    return { success: true, user };
  }

  isLocked() {
    return this.locked_until && this.locked_until > new Date();
  }

  async incrementFailedAttempts() {
    this.failed_attempts += 1;
    if (this.failed_attempts >= 5) {
      this.locked_until = new Date(Date.now() + 15 * 60 * 1000); // 15分钟
    }
    await this.save();
  }
}
```

**2. 登录控制器 (controllers/AuthController.js)**
```javascript
const jwt = require('jsonwebtoken');

exports.login = async (req, res) => {
  const { identifier, password, rememberMe } = req.body;

  try {
    const result = await User.authenticate(identifier, password);

    if (!result.success) {
      return res.status(401).json({ error: result.error });
    }

    const expiresIn = rememberMe ? '30d' : '1d';
    const token = jwt.sign(
      { userId: result.user.id },
      process.env.JWT_SECRET,
      { expiresIn }
    );

    res.cookie('authToken', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: rememberMe ? 30 * 24 * 60 * 60 * 1000 : 24 * 60 * 60 * 1000
    });

    await result.user.updateLastLogin();

    res.json({
      success: true,
      user: {
        id: result.user.id,
        username: result.user.username,
        email: result.user.email
      }
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
```

### 测试覆盖
- ✅ 成功登录场景
- ✅ 错误密码处理
- ✅ 账户锁定机制
- ✅ JWT令牌生成
- ✅ 会话管理

### 代码变更摘要
- 新增: `models/User.js` (认证逻辑)
- 新增: `controllers/AuthController.js` (API端点)
- 新增: `middleware/auth.js` (认证中间件)
- 更新: `routes/api.js` (添加登录路由)
- 新增: `tests/auth.test.js` (测试用例)
```

### 步骤 5：质量保证 (@qa)
```
@qa 为登录功能创建全面的测试策略，确保覆盖率达到90%以上，包含边界条件和错误场景
```

**预期输出：**
```markdown
## 登录功能测试策略

### 测试覆盖矩阵

**单元测试 (70%)**
```javascript
describe('User Authentication', () => {
  test('should authenticate valid user', async () => {
    const result = await User.authenticate('john@example.com', 'password123');
    expect(result.success).toBe(true);
    expect(result.user.username).toBe('john');
  });

  test('should reject invalid password', async () => {
    const result = await User.authenticate('john@example.com', 'wrongpass');
    expect(result.success).toBe(false);
    expect(result.error).toContain('Invalid credentials');
  });

  test('should lock account after 5 failed attempts', async () => {
    for (let i = 0; i < 5; i++) {
      await User.authenticate('john@example.com', 'wrongpass');
    }
    const user = await User.findByEmail('john@example.com');
    expect(user.isLocked()).toBe(true);
  });
});
```

**集成测试 (20%)**
```javascript
describe('POST /api/auth/login', () => {
  test('should return JWT token for valid credentials', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ identifier: 'john@example.com', password: 'password123' });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.headers['set-cookie']).toBeDefined();
  });

  test('should rate limit failed attempts', async () => {
    // 模拟暴力破解
    const promises = Array(10).fill().map(() =>
      request(app).post('/api/auth/login')
        .send({ identifier: 'john@example.com', password: 'wrong' })
    );

    const responses = await Promise.all(promises);
    const tooManyRequests = responses.filter(r => r.status === 429);
    expect(tooManyRequests.length).toBeGreaterThan(0);
  });
});
```

**端到端测试 (10%)**
```javascript
describe('Login User Journey', () => {
  test('complete login flow', async () => {
    await page.goto('/login');
    await page.fill('#email', 'test@example.com');
    await page.fill('#password', 'password123');
    await page.click('#login-button');

    await page.waitForURL('/dashboard');
    expect(page.url()).toContain('/dashboard');

    const userMenu = await page.locator('#user-menu');
    expect(userMenu).toBeVisible();
  });
});
```

### 边界条件测试
- **极长用户名**: 500字符用户名处理
- **特殊字符密码**: Unicode字符，表情符号
- **并发登录**: 同一用户多设备登录
- **时区处理**: 不同时区的会话过期
- **网络异常**: 超时、断网恢复

### 性能测试
```javascript
// 负载测试脚本
const loadTest = {
  scenarios: {
    login_load: {
      executor: 'constant-vus',
      vus: 100,
      duration: '2m',
      exec: 'loginFlow'
    }
  },
  thresholds: {
    http_req_duration: ['p(95)<200'], // 95%请求在200ms内
    http_req_failed: ['rate<0.01'],   // 错误率<1%
  }
};
```

### 安全测试
- **SQL注入**: 恶意SQL语句输入
- **XSS攻击**: Script标签注入
- **CSRF**: 跨站请求伪造
- **暴力破解**: 自动化密码尝试
- **会话劫持**: Token安全性验证

### 覆盖率报告
- **语句覆盖率**: 92% ✅
- **分支覆盖率**: 89% ✅
- **函数覆盖率**: 95% ✅
- **行覆盖率**: 91% ✅

目标达成：总体覆盖率 91.75% > 90% ✅
```

### 步骤 6：安全审查 (@sec)
```
@sec 对登录功能实现进行全面安全审查，识别潜在安全风险并提供修复建议
```

**预期输出：**
```markdown
## 安全审查报告：用户登录功能

### 整体安全评级：🟢 GOOD (85/100)

### 安全检查清单

#### ✅ 通过的安全控制
1. **密码存储**: bcrypt哈希，适当的cost factor (12)
2. **会话管理**: HTTPOnly cookies，安全标志
3. **账户锁定**: 暴力破解防护机制
4. **输入验证**: 参数验证和清理
5. **错误处理**: 不泄露敏感信息的错误消息
6. **HTTPS强制**: 生产环境HTTPS要求

#### ⚠️ 需要改进的项目
1. **中等风险**: 缺少CSRF token验证
   ```javascript
   // 建议修复
   const csrfToken = req.headers['x-csrf-token'];
   if (!csrfToken || !validateCSRFToken(csrfToken, req.session)) {
     return res.status(403).json({ error: 'CSRF token invalid' });
   }
   ```

2. **低风险**: 登录尝试日志记录不足
   ```javascript
   // 建议添加
   logger.warn('Failed login attempt', {
     identifier: identifier,
     ip: req.ip,
     userAgent: req.get('User-Agent'),
     timestamp: new Date()
   });
   ```

### OWASP Top 10 合规性检查

**A01 - Broken Access Control** ✅
- 实现了适当的认证机制
- 会话管理正确实施

**A02 - Cryptographic Failures** ✅
- 密码安全哈希存储
- JWT使用强密钥签名

**A03 - Injection** ✅
- 使用参数化查询
- 输入验证已实施

**A05 - Security Misconfiguration** ⚠️
- 建议添加安全响应头
```javascript
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  next();
});
```

**A07 - Identification and Authentication Failures** ✅
- 实施账户锁定
- 强密码策略（需要确认）

### 渗透测试结果

**自动化扫描工具**
```bash
# OWASP ZAP扫描结果
High Risk: 0
Medium Risk: 1 (CSRF)
Low Risk: 2 (安全头缺失)
```

**手动测试场景**
1. **暴力破解测试**: ✅ 防护有效
2. **会话固定攻击**: ✅ 防护有效
3. **时序攻击**: ✅ 使用安全比较
4. **注入攻击**: ✅ 防护有效

### 修复优先级

**🔴 高优先级**
- 无

**🟡 中优先级**
1. 实施CSRF保护
2. 添加安全响应头

**🟢 低优先级**
1. 增强登录尝试日志
2. 实施速率限制

### 安全加固建议

**立即实施 (本Sprint)**
```javascript
// 1. CSRF保护中间件
const csrf = require('csurf');
app.use(csrf({ cookie: true }));

// 2. 安全头中间件
const helmet = require('helmet');
app.use(helmet());
```

**后续改进 (下个Sprint)**
1. 实施双因素认证
2. 异常登录地点检测
3. 设备指纹识别
4. 高级威胁检测

### 合规性确认
- ✅ GDPR: 用户数据处理透明
- ✅ CCPA: 隐私控制实施
- ✅ PCI DSS: 不处理支付卡数据
- ✅ SOX: 审计日志充分

**最终建议**: 修复中等风险问题后可以部署到生产环境
```

### 步骤 7：综合评审 (/review)
```
/review staged
```

**预期输出：**
```markdown
📋 **综合代码评审报告**

**状态:** 🟡 NEEDS IMPROVEMENT
**总体评分:** 82/100

## 🤖 自动化检查
✅ **LINT**: 通过 (0 errors, 2 warnings)
✅ **TYPECHECK**: 通过
✅ **TESTS**: 通过 (覆盖率: 91.75%)
⚠️ **SECURITY**: 发现1个中等风险问题
✅ **BUILD**: 构建成功

## 👥 代理评审
🟢 **@dev**: 88/100 - 代码质量良好，架构清晰
⚠️ **@sec**: 75/100 - 需要解决CSRF保护问题
🟢 **@qa**: 93/100 - 优秀的测试覆盖率和策略
🟢 **@arch**: 85/100 - 遵循架构设计原则

## ✅ DoD 合规性: 81/100

🟢 **测试要求**: 91.75%覆盖率 (目标: 80%) ✅
⚠️ **安全要求**: 1个中等风险 (目标: 0高/严重)
🟢 **代码标准**: 所有检查通过 ✅
🟢 **文档**: API文档已更新 ✅
🟢 **部署就绪**: staging环境测试通过 ✅

## 💡 改进建议
1. 实施CSRF保护机制 (安全要求)
2. 添加Helmet安全响应头
3. 增强错误日志记录
4. 考虑添加API速率限制

## 🎯 行动项目
**合并前必须完成:**
- [ ] 修复CSRF保护问题
- [ ] 添加Helmet安全中间件
- [ ] 重新运行安全扫描验证

**合并后可以跟进:**
- [ ] 监控生产环境登录性能
- [ ] 收集用户体验反馈
- [ ] 规划双因素认证功能

**预计修复时间**: 2小时
**修复后重新评审**: 预期评分 >85/100
```

### 步骤 8：修复并重新评审
```bash
# 开发者快速修复安全问题
@dev 根据@sec的建议实施CSRF保护和Helmet安全头，然后重新提交代码

# 修复后重新评审
/review staged
```

**修复后的评审结果：**
```markdown
📋 **重新评审报告**

**状态:** 🟢 APPROVED
**总体评分:** 89/100

## 🤖 自动化检查
✅ 所有检查通过

## 👥 代理评审
🟢 **@sec**: 92/100 - 安全问题已解决，建议批准

## ✅ DoD 合规性: 88/100
🟢 **所有要求达标**

**✅ 准备合并到主分支！**
```

### 步骤 9：每日站会报告 (/standup)
```
/standup
```

**预期输出：**
```markdown
📅 **每日站会 - 2025年1月17日**

## 🎯 Sprint 概览
**Sprint目标:** 建立CC-Scrum代理框架核心自动化
**Sprint:** #001 (第4天，共14天)
**燃尽:** 剩余5故事点 (总计13点)
**团队速度:** 领先计划 (平均2.3点/天)

## ✅ 昨日成就
- **登录功能完成**: 从需求到生产就绪 (8故事点)
- **安全审查**: 识别并修复CSRF保护问题
- **测试覆盖**: 达到91.75%，超过目标
- **质量门控**: 全面评审流程验证成功

## 🎯 今日重点
- **部署上线**: 登录功能部署到生产环境
- **监控设置**: 登录性能和安全指标监控
- **下个功能**: 开始用户注册功能分析
- **流程优化**: 基于首个功能的经验改进工作流

## 🚫 阻塞事项
当前无阻塞 🎉

## ⚠️ 风险关注
- **技术风险**: 生产部署需要数据库迁移，已准备回滚方案
- **进度风险**: 无，当前领先计划

## 📊 Sprint指标
**故事完成率**: 62% (8/13故事点) 🚀
**质量指标**:
- 缺陷数: 0
- 代码评审通过率: 100%
- 安全扫描: 通过
- 测试覆盖率: 91.75%

**团队健康指标**:
- 阻塞数量: 0 ✅
- 平均解决时间: N/A
- 团队满意度: 9/10 ✅

## 🔄 流程亮点
- **代理协作**: @po→@pmgr→@dev→@qa→@sec 无缝配合
- **自动化**: /meta-todo 任务分解准确率95%
- **质量**: /review 发现并解决了关键安全问题
- **效率**: 端到端交付时间比预期快30%
```

## 🎉 总结

通过这个完整的示例，我们展示了 CC-Scrum 如何将一个简单的业务需求转化为高质量的生产功能：

### 关键收益
1. **智能协作**: 6个专业代理协同工作，每个都专注于自己的领域
2. **质量保证**: 多层次验证确保代码质量、安全性和可维护性
3. **自动化流程**: 从任务分解到质量检查的全流程自动化
4. **持续学习**: 系统学习成功模式，不断改进估算和流程

### 效率提升
- **任务分解准确率**: 95% (vs 传统70%)
- **质量问题早发现**: 代码评审阶段发现安全问题
- **开发速度**: 比传统流程快30%
- **返工率**: 几乎为零

## 🚀 立即开始

现在你已经了解了完整的工作流程，可以开始使用 CC-Scrum：

```bash
# 开始你的第一个用户故事
@po "帮我将这个需求转换为用户故事：[你的需求]"

# 或者直接使用智能任务分解
/meta-todo "你的用户故事" --tier=2
```

让 AI 驱动的 Scrum 流程提升你的开发效率！