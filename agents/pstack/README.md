# 本机 pstack

共享技能的可编辑源文件在 [skills](skills)。Home Manager 把同一份内容链接到各客户端的技能目录。现有技能保存后即可从链接读取。

- **模型与任务**　[models.md](models.md) 保存角色和本机 CLI 命令。[pstack-worker](worker) 在分配给它的目录启动对应 CLI，写入同一项目的并行任务分别使用 Worktrunk worktree。
- **代码与交付**　当前仓库的 AGENTS.md 决定项目约定。Git 提交使用 Worktrunk。请求开 GitHub PR 时走本机 pr 技能，请求 HeyDeer 评审或交付时走 heydeer-pr。每个 PR 的 owner 遵守指定的停止点。
- **记录与恢复**　长任务的 decisions.tsv 保存在本机 pstack 状态目录。恢复时用记录中的工作目录、提交和验证结果定位进度。
- **上游更新**　[check-upstream.sh](check-upstream.sh) 比较远端 HEAD 和 [已审版本](upstream-rev)。选取需要的改动后再记录新的已审版本。

[上游文档快照](docs) 用于版本对照。本机的执行说明见 [poteto-mode](skills/poteto-mode/SKILL.md) 和对应技能。
