● Claude Code Agent 体系 —— 学习路线设计

  先看全貌，然后逐层深入。

---
  第一层：Agent 体系全貌

  Claude Code 的 agent 系统分 5 个原语，你已经在用其中大部分：

  ┌────────────────────────────────────────────┐
  │              你 (PM / Orchestrator)          │
  │   定义 CLAUDE.md, skills, hooks, 发指令      │
  └──────────┬─────────────────────────────────┘
             │
      ┌──────┴──────┐
      │  Agent 工具  │  ← 启动 subagent 的原语
      └──────┬──────┘
             │
      ┌──────┴──────────────────────────┐
      │     Subagent 类型 (角色)          │
      │  Explore │ Plan │ general-purpose │
      │  cavecrew-* │ claude-code-guide │
      └──────┬──────────────────────────┘
             │
      ┌──────┴──────────┐
      │  Worktree 隔离   │  ← 每个 agent 独立分支
      └──────┬──────────┘
             │
      ┌──────┴──────────────────────┐
      │  输出 / 回调                  │
      │  结果回主线程 → 下一 agent    │
      └─────────────────────────────┘

  5 个原语：
  1. Agent 工具 — Agent tool，启动子 agent
  2. Subagent 类型 — 预定义角色（Explore/Plan/cavecrew-builder 等）
  3. Skill 系统 — 可加载的专业能力模块
  4. Worktree 隔离 — isolation: "worktree" 给 agent 独立工作区
  5. Hook 系统 — 事件驱动的自动化（SessionStart/UserPromptSubmit 等）

  你现在的 caveman 模式就依赖了：Agent 工具（cavecrew-builder）+ Hook（UserPromptSubmit 注入 caveman 规则）+ Skill（caveman SKILL.md 定义行为）。

---
  这部分清楚吗？然后我展开第二层：Agent 角色定义（CLAUDE.md + Skill 怎么写才有效）。

✻ Crunched for 43s

※ recap: Goal: 学透 Claude Code 的内置 agent 协作体系，用配置/Prompt 编排多 agent 而非写代码。

  刚讲完第一层——5 个原语（Agent 工具、Subagent 类型、Skill、Worktree、Hook），等你确认后继续第二层：Agent 角色怎么定义。 (disable recaps in /config)

❯ ok

● 第二层：Agent 角色定义 —— CLAUDE.md + Skill 怎么写

  Agent 的行为由两层配置驱动：

  ┌──────────────────────┐
  │  CLAUDE.md (项目级)   │  ← Agent 的"身份和约束"
  │  定义：能做什么、怎么做  │
  ├──────────────────────┤
  │  Skill 文件 (功能级)   │  ← Agent 的"专业技能"
  │  定义：特定任务的流程    │
  └──────────────────────┘

  CLAUDE.md 的角色定义模式：

  当前项目的 CLAUDE.md 主要写构建命令和架构。但作为 agent 规范，可以扩展成这样：

  # role: backend-agent
  ## capabilities（能用的工具）
  - Read, Write, Edit, Bash, Grep
  ## restrictions（不能做的事）
  - 不能修改 lib/screens/ 下的 UI 文件
  - 不能 git push
  ## conventions（必须遵守的规范）
  - DAO 层只做 CRUD，不做业务逻辑
  - 所有 DB 操作必须有对应测试
  ## output-format（输出格式）
  - 改动完成后输出 changed-files: <路径列表>

  Skill 文件的角色定义模式：

  你用的 caveman skill 就是典型。看它的结构：

  # SKILL.md
  ## 触发条件 (TRIGGER)
  ## 行为规则 (RULES)
  ## 输出格式 (OUTPUT)
  ## 硬门禁 (HARD-GATE)

  关键设计原则：

  ┌──────────────────┬──────────────────────────────────────────────┬────────────────────┐
  │       原则       │                     说明                     │        反例        │
  ├──────────────────┼──────────────────────────────────────────────┼────────────────────┤
  │ 正反都写         │ 能做什么 + 不能做什么，双向约束              │ 只写"你要审查代码" │
  ├──────────────────┼──────────────────────────────────────────────┼────────────────────┤
  │ 具体到文件层     │ "不能碰 lib/db/" 比 "不能改数据库" 有效      │ "注意安全"         │
  ├──────────────────┼──────────────────────────────────────────────┼────────────────────┤
  │ HARD-GATE 用断言 │ "没有测试不允许提交" 比 "建议写测试" 有效    │ "最好加上测试"     │
  ├──────────────────┼──────────────────────────────────────────────┼────────────────────┤
  │ 输出格式模板化   │ 给 agent 固定的输出模板，方便下个 agent 解析 │ 自由格式输出       │
  └──────────────────┴──────────────────────────────────────────────┴────────────────────┘

  实际例子 —— 你已有的 agent 体系：

  CLAUDE.md (项目根)
    ├── 定义全局 agent 规则（构建命令、架构约定）
    └── 所有 agent 共享的上下文

  caveman SKILL.md
    ├── cavecrew-builder: 1-2 文件编辑，拒接 3+ 文件
    ├── cavecrew-reviewer: 一行一条 issue，不讲废话
    └── cavecrew-investigator: 唯读，拒绝给修复建议

  brainstorming SKILL.md (现在用的)
    ├── 流程：探索 → 提问 → 方案 → 设计 → 文档
    ├── HARD-GATE: 设计没批准前禁止写代码
    └── 输出：docs/superpowers/specs/*.md

---
  这一层清楚的话，进入第三层：权限和能力控制（settings.json hooks + permissions 机制）。

✻ Sautéed for 27s

❯ 使用skill时，是独立的agent吗？subagent什么时候才会生成

● 好问题。两者不同。

  Skill ≠ 独立 Agent。Skill 是"给当前 Agent 换脑子"。

  Skill 工具 → 加载 SKILL.md 到当前会话上下文
             → 当前 agent 切换行为模式
             → 没有新进程，没有隔离

  你调用 /superpowers:brainstorming 时，还是当前这个 agent 在回复你，只是它的规则切换成了 brainstorming 的流程。

  Agent 工具 → 真正 fork 出新 agent。

  Agent 工具 → 新建独立会话，独立上下文窗口
            → 可并行、可后台、可 worktree 隔离
            → 完成后结果回主线程

  Subagent 什么时候生成？

  ┌───────────────────┬─────────────────────────────────────────────┐
  │     触发方式      │                    例子                     │
  ├───────────────────┼─────────────────────────────────────────────┤
  │ 你显式要求        │ "用 Explore agent 搜索代码"                 │
  ├───────────────────┼─────────────────────────────────────────────┤
  │ 主 agent 主动分发 │ 我用 Agent 工具派发并行任务                 │
  ├───────────────────┼─────────────────────────────────────────────┤
  │ Skill 内部定义    │ 某些 skill 要求"去调 X agent"               │
  ├───────────────────┼─────────────────────────────────────────────┤
  │ 并行独立任务      │ 3 个文件同时改，主 agent spawn 3 个 builder │
  └───────────────────┴─────────────────────────────────────────────┘

  关键区别：

  当前你用 brainstorming skill:
    Skill → 加载到我的上下文 → 我按流程问你问题
    这不是 subagent，就是我在按 skill 规则行事

  如果我要生成 subagent:
    Agent(subagent_type="cavecrew-reviewer", prompt="审查这个 diff")
    → 新 agent 启动，独立干活，把结果返回给我

  实际场景对照：

  PM Agent (你)
    │
    ├── Skill: brainstorming     ← 不是 subagent，是 PM 切换了思维模式
    │
    └── Agent: cavecrew-builder  ← 是 subagent，独立进程改代码
         Agent: Explore           ← 是 subagent，独立进程搜代码

  总结：Skill 改变"我怎么想"，Agent 工具创建"另一个我"。

  清楚了的话，继续第三层：权限控制。

✻ Brewed for 17s

❯ ok

● 第三层：权限与能力控制

  Claude Code 对 agent 的权限控制分 3 级：

  ┌──────────────────────────────────────┐
  │  Level 1: Prompt 约束 (软限制)         │
  │  "你不能改 UI 文件" → 写在 CLAUDE.md    │
  │  依赖 agent 自觉遵守，可被绕过           │
  ├──────────────────────────────────────┤
  │  Level 2: settings.json 权限 (硬限制)   │
  │  permissions.allow/deny → 工具级拦截    │
  │  系统强制执行，agent 无法绕过            │
  ├──────────────────────────────────────┤
  │  Level 3: Hook 拦截 (动态限制)          │
  │  特定事件触发检查 → 可阻止/修改行为       │
  │  最灵活，但有性能成本                    │
  └──────────────────────────────────────┘

  Level 1 — 你现在就在用：

  # CLAUDE.md 或 Skill 中写
  ## restrictions
  - 不能修改 lib/screens/
  - 不能 git push
  - 只能 Read/Grep，不能 Edit

  caveman ultra 编译模式下，我只是在 prompt 中被要求"只能 Read/Grep"——但我工具列表里 Edit 还在。这是信任契约，不是技术限制。

  Level 2 — settings.json 真正限制：

  // .claude/settings.json
  {
    "permissions": {
      "allow": [
        "Bash(npm test)",
        "Read"
      ],
      "deny": [
        "Bash(git push:*)",
        "Bash(rm -rf:*)"
      ]
    }
  }

  工具硬拦截。如果设定 deny: ["Edit"]，这个 agent 调用 Edit 时直接拒绝，prompt 骗不过去。

  Level 3 — Hook 动态控制：

  你已经在用。看 caveman hook：

  // settings.json
  {
    "hooks": {
      "UserPromptSubmit": [
        {
          "matcher": "",
          "command": "~/.claude/plugins/cache/caveman/.../hooks/caveman-statusline.sh"
        }
      ],
      "SessionStart": [
        {
          "matcher": "",
          "command": "... caveman init hook ..."
        }
      ]
    }
  }

  Hook 在事件发生时执行脚本，可以做：阻止、修改 prompt、注入上下文、记录日志。

  多 agent 场景的权限分层设计：

  ┌────────────┬──────────────────┬───────────────────────────────────────────┬──────────────────┐
  │ Agent 角色 │ Level 1 (Prompt) │            Level 2 (settings)             │  Level 3 (Hook)  │
  ├────────────┼──────────────────┼───────────────────────────────────────────┼──────────────────┤
  │ PM         │ 全能力           │ 不允许 git push --force                   │ 无               │
  ├────────────┼──────────────────┼───────────────────────────────────────────┼──────────────────┤
  │ Builder    │ 不能碰测试文件   │ deny: Git 操作                            │ 修改后触发 lint  │
  ├────────────┼──────────────────┼───────────────────────────────────────────┼──────────────────┤
  │ Reviewer   │ 唯读             │ deny: Edit, Write, Bash(write)            │ 输出格式校验     │
  ├────────────┼──────────────────┼───────────────────────────────────────────┼──────────────────┤
  │ Deploy     │ 只能构建         │ allow: Bash(flutter build), Bash(git tag) │ 构建前跑测试检查 │
  └────────────┴──────────────────┴───────────────────────────────────────────┴──────────────────┘

  你当前项目的实际情况：

  你的 settings.json 应该有:
    - permissions: Bash/Read/Edit 允许
    - hooks: SessionStart → caveman 注入
              UserPromptSubmit → caveman statusline

  你的 CLAUDE.md 有:
    - 全局 agent 规范（构建命令、架构约定）
    - 但没有区分 agent 角色的权限定义

  要扩展的话，可以：
  1. 项目里放多个 agent spec 文件：agents/builder.md、agents/reviewer.md
  2. settings.json 按 agent 类型设 permissions
  3. Hook 在 agent 切换时自动加载对应 spec

---
  下一层：第四层 协作工作流模式（串行/并行/审查门禁），还是先消化这部分？

✻ Cooked for 23s

❯ 那为什么不在l2指定权限即可，要l1有什么意义

● Level 2 只能做 工具级拦截，粒度太粗。

  Level 2 能做的：
  "不允许 Bash"        ✅ 整个 Bash 工具禁用
  "不允许 git push"    ✅ 命令匹配拦截
  "不允许 Edit"        ✅ 整个编辑工具禁用

  Level 2 做不了的：
  "不能改 lib/screens/ 下的文件"    ❌ Edit 开了就全都能改
  "不要引入新依赖"                   ❌ 不是工具操作
  "遵循 Provider 而非 Riverpod"     ❌ 这是代码风格，不是工具问题
  "DAO 层只做 CRUD"                 ❌ 语义约束，不是操作约束

  如果只靠 L2，agent 调 Edit 改 UI 文件 → 权限系统放行（Edit 是允许的）→ 改错了。L1 提前告诉它"别碰 UI"，它就不会去尝试。

  说白了：
  - L2 = 门禁（能不能进这个房间）
  - L1 = 工作说明书（进房间后该干什么、不该干什么）
  - L1 + L2 = 双层防护。只靠门禁拦不住进房间后搞错东西

  还有一个隐性好处：省 token。 Agent 知道约束就不会乱试，试错了被 L2 拦截再重试浪费 round trip。

---
  继续第四层：协作工作流模式？

✻ Cogitated for 20s

❯ ok

● 第四层：协作工作流模式

  多 agent 协作的 4 种基本模式，复杂流程都是这些的组合：

---
  模式 1：串行流水线 (Pipeline)

  PM → Plan Agent → Builder Agent → Review Agent → PM 确认
        (方案)        (写代码)        (审查)

  每个阶段依赖前一阶段输出。适用：需求明确、步骤分明的任务。

  实际例子（你当前流程）:
  brainstorming skill → 设计方案 → writing-plans skill → 写实施计划
                                           ↓
                                     Builder 实现
                                           ↓
                                     Reviewer 审查

  模式 2：并行分发 (Fan-out / Fan-in)

                ┌→ Agent 1: 写 DAO
  PM 拆解任务 →  ┼→ Agent 2: 写 Provider
                └→ Agent 3: 写 UI
                (三个同时跑)
                ┌→ 结果回 PM
  PM 汇总 ← ────┼→ 合并到分支
                └→ 解决冲突

  前提：任务间无共享依赖。Claude Code 的 run_in_background: true 就是干这个的。

  什么时候并行:
  ✅ 三个独立文件各加一个函数
  ✅ 不同模块的文档各写一段
  ❌ 同一文件多处改动（会冲突）
  ❌ DAO + 依赖 DAO 的 Provider（Provider 要等 DAO 完成）

  模式 3：审查门禁 (Review Gate)

  Builder → 自测通过 → 提交 Review Agent →
    ├─ 通过 → 继续下一步
    └─ 失败 → 返回 Builder 修改 → 再 Review
    循环直到通过

  这是 DevOps 全流程里最关键的模式。code-review skill + verification-before-completion skill 就是这个门禁。

  模式 4：事件驱动 (Event-Driven)

  Hook: 代码提交 → 触发 Lint Agent
  Hook: PR 创建  → 触发 Review Agent
  Hook: 测试失败 → 触发 Debug Agent

  靠 settings.json 的 hooks 实现：

  ┌─────────────┬──────────────────────────┐
  │  Hook 事件  │        触发 Agent        │
  ├─────────────┼──────────────────────────┤
  │ PostToolUse │ 检查是否改了不该改的文件 │
  ├─────────────┼──────────────────────────┤
  │ Stop        │ 检查是否还有未提交的变更 │
  ├─────────────┼──────────────────────────┤
  │ PreToolUse  │ 拦截危险操作             │
  └─────────────┴──────────────────────────┘

---
  四种模式组合 → 完整 DevOps 流程：

  触发 (Hooks/你发指令)
    │
    ├─ Plan Agent ────→ 生成 spec
    │                    │
    ├─ Builder × N ────→ 并行开发 (Fan-out)  ← Worktree 隔离
    │                    │
    ├─ Review Gate ────→ 串行审查 (Pipeline) ← Gate 模式
    │   ├─ 通过 ─→ Test Agent → Deploy
    │   └─ 不通过 → 回 Builder
    │
    └─ Deploy ────────→ 构建/打 tag/生成 changelog

---
  你当前已经在用的模式：

  caveman 体系 = 模式 1 (Pipeline) + 模式 3 (Gate)
    Builder 改完 → cavecrew-reviewer 审查 → 你确认

  superpowers 体系 = 模式 1 (串行)
    brainstorming → writing-plans → executing-plans → finishing-branch

---
  最后一层：第五层 GitHub 高 star 学习案例 + 实操建议。继续？

✻ Cogitated for 26s

❯ ok

● 第五层：学习案例 + 实操路径

---
  GitHub 高 Star 案例

  直接相关（配置驱动型，不写代码）：

  ┌────────────────────────────────────────────────────────────────────┬───────┬──────────────────────────────────────────────────────────────────┐
  │                                Repo                                │ Stars │                              学什么                              │
  ├────────────────────────────────────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────┤
  │ anthropics/claude-code (https://github.com/anthropics/claude-code) │ ~50k+ │ Agent 系统本身。读它的 subagent 定义、hook 机制、permission 模型 │
  ├────────────────────────────────────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────┤
  │ anthropics/courses (https://github.com/anthropics/courses)         │ ~10k+ │ Anthropic 官方的 agent 设计模式，不是框架代码，就是设计理念      │
  └────────────────────────────────────────────────────────────────────┴───────┴──────────────────────────────────────────────────────────────────┘

  间接相关（理念参考，Python 写的但看设计不写代码）：

  ┌────────────────────────────────────────────────────────────────────┬───────┬───────────────────────────────────────────────────┐
  │                                Repo                                │ Stars │                      学什么                       │
  ├────────────────────────────────────────────────────────────────────┼───────┼───────────────────────────────────────────────────┤
  │ microsoft/autogen (https://github.com/microsoft/autogen)           │ ~40k  │ 多 agent 对话模式、角色分配、agent 间通信协议     │
  ├────────────────────────────────────────────────────────────────────┼───────┼───────────────────────────────────────────────────┤
  │ langchain-ai/langgraph (https://github.com/langchain-ai/langgraph) │ ~12k  │ Agent 工作流的状态机模型、条件分支、循环控制      │
  ├────────────────────────────────────────────────────────────────────┼───────┼───────────────────────────────────────────────────┤
  │ crewAIInc/crewAI (https://github.com/crewAIInc/crewAI)             │ ~25k  │ Agent 角色定义（Role/Goal/Backstory）、任务序列化 │
  └────────────────────────────────────────────────────────────────────┴───────┴───────────────────────────────────────────────────┘

  但最有价值的"案例"在你本地：

  ~/.claude/plugins/cache/superpowers-marketplace/superpowers/5.1.0/skills/
    ├── brainstorming/        ← 流程编排的典范
    ├── writing-plans/        ← 结构化输出
    ├── subagent-driven-development/  ← agent 分发模式
    ├── executing-plans/      ← 带审查门禁的执行
    ├── code-review/          ← 审查 agent 定义
    └── caveman/              ← 极致压缩的输出规范

  ~/.claude/CLAUDE.md         ← 全局 agent 身份定义
  项目目录/CLAUDE.md           ← 项目 agent 身份定义

  研究这些 skill 文件，看它们怎么写触发条件、写硬门禁、写输出格式——这就是 agent 角色定义的最佳案例。

---
  实操路线图

  按你当前状态，建议分 3 步走：

  Step 1：看懂已有的（现在就能做）
  - 精读 ~/.claude/plugins/cache/ 下 3-5 个 skill 的 SKILL.md
  - 理解 HARD-GATE、TRIGGER、输出模板的写法
  - 看 settings.json 里 hooks 怎么配的

  Step 2：给 AIAccounting 定义专属 agent 族
  项目目录/agents/
    ├── builder.md        ← 写代码规范（架构、Provider 模式、测试要求）
    ├── reviewer.md       ← 审查规则（检查项、输出格式）
    └── deployer.md       ← 构建规范（JDK 路径、Android SDK 路径、构建命令）

  settings.json:
    - 配置 PreToolUse hook: 检查 agent 是否碰了不该碰的文件
    - 配置 Stop hook: 未跑测试不允许提交

  Step 3：编排完整 DevOps 流程
  你发指令："实现 XX 功能"

  自动化流程:
    brainstorm (skill) → spec 文件
    → 你审批
    → Plan Agent → 实施计划
    → 你审批
    → Builder Agent × N (worktree 隔离，并行开发)
    → Review Agent (审查每个 diff)
    → Test Agent (跑 flutter test --concurrency=1)
    → Deploy Agent (flutter build apk --debug)
    → 生成 changelog

---
  关键认知

  多 agent 协作的核心不是代码，而是 3 样东西：

  1. Agent Spec 写得好不好 — CLAUDE.md + Skill 文件的约束够不够精确
  2. 接口设计清不清晰 — agent 之间传递什么、输出什么格式、下个 agent 能否直接消费
  3. 门禁机制够不够硬 — 不是"建议"而是强制检查，失败的必须回退

  你用的 Claude Code + superpowers 体系已经把这三样都实现了。你现在要做的是：研读源码级 skill 文件，理解它们怎么做到的，然后按你项目的需求定制。