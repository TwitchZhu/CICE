# 快速开始

从 CICE Consortium 的仓库克隆模式及其子模块：

```bash
git clone --recurse-submodules https://github.com/CICE-Consortium/CICE
```

使用 Git 和 GitHub 开发 CICE（及 Icepack）的说明见 [CICE Git 工作流指南](https://github.com/CICE-Consortium/About-Us/wiki/Git-Workflow-Guide)。通常还需要下载部分输入数据，参阅 [CICE Wiki](https://github.com/cice-consortium/CICE/wiki) 或[强迫数据](../user_guide/ug_running.md#强迫数据)。软件要求见[软件要求](../user_guide/ug_running.md#软件要求)。移植信息见[移植](../user_guide/ug_running.md#移植)，在个人计算机上移植的专门说明见[移植到笔记本或个人计算机](../user_guide/ug_running.md#移植到笔记本或个人计算机)。

在 CICE 主目录下执行：

```bash
./cice.setup -c ~/mycase1 -g gx3 -m testmachine -s diag1,thread -p 8x1
cd ~/mycase1
./cice.build
./cice.submit
```

`testmachine` 是 CICE 脚本附带的通用机器名。应将其替换为本地机器名；已有若干机器的适配配置。如果需要自行移植，请参阅上文的[移植](../user_guide/ug_running.md#移植)一节。[脚本](../user_guide/ug_running.md#脚本)一节进一步介绍 `cice.setup` 和 `cice.submit` 的用法。

使用 CICE 代码时请予以引用。详情见[如何引用 CICE 代码](citing.md)。

原文：[quickstart.rst](../../source/intro/quickstart.rst)
