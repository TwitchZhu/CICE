# 运行 CICE

快速入门说明见[快速开始](../intro/quickstart.md)。

## 软件要求

独立运行 CICE 需要：

- bash 和 csh；
- `gmake`（GNU Make）；
- Fortran 和 C 编译器（已测试 Intel、PGI、GNU、Cray、NVHPC、AOCC 和 NAG）；
- NetCDF（可选，但测试使用 NetCDF 网格、输入及强迫文件的标准配置时必须安装）；
- MPI（可选，但多于一个处理器运行时必须安装）；
- PIO（可选，但使用 PIO I/O 接口时必须安装）。

下列软件版本都曾由 Consortium 测试，但不保证任意编译器版本都能与任意 CICE 版本配合。Consortium 会定期测试若干编译器，却不一定覆盖所有版本和组合。CICE 同时支持 PIO1 和 PIO2；使用 PIO1 时还应设置 `USE_PIO1` 宏。CICE 的目标之一是在不同硬件、编译器及软件环境中保持较好的可移植性（portability），因此实现上有时会采取保守方式。如移植到某系统遇到问题，请告知 Consortium。

**曾测试的编译器：**

```text
AOCC 3.0.0
Intel ifort 15.0.3.187, 16.0.1.150, 17.0.1.132, 17.0.2.174,
17.0.5.239, 18.0.1.163, 18.0.5, 19.0.2, 19.0.3.199,
19.1.0.166, 19.1.1.217, 19.1.2.254, 2021.4.0, 2021.6.0,
2021.8.0, 2021.9.0, 2021.10.0, 2022.2.1
PGI 16.10.0, 19.9-0, 20.1-0, 20.4-0
GNU 6.3.0, 7.2.0, 7.3.0, 7.7.0, 8.3.0, 9.3.0,
10.1.0, 11.2.0, 12.1.0, 12.2.0
Cray CCE 8.5.8, 8.6.4, 13.0.2, 14.0.3, 15.0.1
NAG 6.2
NVC 23.5-0
```

**曾测试的 MPI 实现：**

```text
MPICH 7.3.2, 7.5.3, 7.6.2, 7.6.3, 7.7.0, 7.7.6, 7.7.7,
7.7.19, 7.7.20, 8.1.14, 8.1.21, 8.1.25, 8.1.26
Intel MPI 18.0.1, 18.0.4, 2019 Update 6, 2019 Update 8
MPT 2.14, 2.17, 2.18, 2.19, 2.20, 2.21, 2.22, 2.25
mvapich2-2.3.3
OpenMPI 1.6.5, 4.0.2
```

NetCDF 实现较通用，理论上应可使用任何 NetCDF 3 或 4 版本。Consortium 曾测试：

```text
NetCDF 4.3.0, 4.3.2, 4.4.0, 4.4.1.1.3, 4.4.1.1.6, 4.4.1.1,
4.4.2, 4.5.0, 4.5.2, 4.6.1.3, 4.6.3, 4.6.3.2, 4.7.2,
4.7.4, 4.8.1, 4.8.1.1, 4.8.1.3, 4.9.0.1, 4.9.0.3, 4.9.2
```

还曾测试：

```text
PIO 1.10.1, 2.5.4, 2.5.9, 2.6.0, 2.6.1
PnetCDF 1.12.2, 1.12.3, 2.6.2
```

若此列表可增加新版本，请告知 Consortium。

## 脚本

CICE 脚本用于快速建立案例和测试。生成案例后，用户可手动修改 namelist 和其他文件，实现自定义配置；部分设置也可通过脚本完成。

### 概述（Overview）

配置、构建和运行 CICE 的脚本大多位于 `configuration/scripts/`；主目录中的 `cice.setup` 是生成案例的主脚本。用户可能需要将脚本移植到本地机器，详见下文“移植”。`cice.setup -h` 显示最新用法，`cice.setup --help` 显示扩展帮助。

脚本有三种模式：`--case`（`-c`）建立独立案例；`--test` 建立带额外自动化的单项测试，如精确重启测试；`--suite` 建立预定义的测试套件，可快速完成整套测试的设置、构建和运行。所有模式都需要用 `--mach`（`-m`）指定机器，建议再用 `--env` 指定编译环境。案例和单项测试可用 `--set`（`-s`）启用模型选项。测试与套件需要 `--testid`；`--bdir`、`--bgen`、`--bcmp`、`--diff` 用于生成、保存和比较回归测试结果，`--tdir` 指定测试目录。详见[测试](ug_testing.md)。最新选项、支持的机器及测试类型以 `cice.setup --help` 为准。

建立案例：

```sh
cice.setup -c mycase -m machine -e intel
cd mycase
```

案例目录包含以下文件：

- `env.[machine]_[env]`：定义运行环境。
- `cice.settings`：定义构建和运行模型的诸多变量。
- `makdep.c`：自动生成 Make 依赖关系的工具。
- `Macros.[machine]_[env]`：Makefile 宏。
- `Makefile`：构建模型的 makefile。
- `cice.build`：调用 Makefile 编译模型的脚本。
- `ice_in`：namelist 输入文件。
- `setup_run_dirs.csh`：创建运行目录；用户未手动执行时由 `cice.run` 自动调用。
- `cice.run`：批处理运行脚本。
- `cice.submit`：提交 `cice.run` 的简易脚本。

案例建立后，脚本和 namelist 都已解析完成。可在案例目录手工编辑文件，以改变模型配置、构建选项或批处理设置。上述列表也反映依赖关系：若编辑了列于 `cice.build` 之前的文件，应重新运行 `cice.build`。`casescripts/` 保存创建案例所用脚本，通常无需关注。在案例目录交互执行 `cice.build`，随后交互执行 `cice.submit` 提交任务；也可直接交互运行或手动提交 `cice.run`／`cice.test`。

常用操作：修改 namelist 时编辑 `ice_in`；修改批处理设置时编辑 `cice.run` 或测试案例的 `cice.test` 文件开头。提交运行脚本时，案例目录中的 `ice_in`、`cice.settings` 和 `env.[machine]` 会复制到运行目录；按标准流程运行时不应编辑运行目录里的副本，因为它们会被覆盖。可在登录 shell 中载入 `cice.settings` 建立案例变量；实用别名见下文。调试编译标志由 `cice.settings` 中的 `ICE_BLDDEBUG=true` 启用，建立案例时也可选 `-s debug`。编译器选项在 Macros 文件中修改；用户自定义预处理宏在 `cice.settings` 的 `ICE_CPPDEFS` 中按 `-DCICE_MACRO` 语法添加。`ICE_CLEANBUILD=true`（默认）或 `-s buildclean` 会在每次编译前清理；设为 `false` 或用 `-s buildincremental` 则不清理。对构建是否正确有疑问时，建议保持清理构建。

```sh
./cice.build
./cice.submit
```

构建和运行日志会复制到案例目录的 `logs/`；其他模型输出位于 `cice.settings` 中 `ICE_RUNDIR` 指定的运行目录。更改案例设置应编辑案例目录。

### `cice.setup` 命令行选项

`cice.setup -h` 给出选项摘要。以下详述建立案例相关选项；测试选项见[测试](ug_testing.md)。

- `--help`、`-h`：显示帮助后退出。
- `--version`：显示 CICE 版本后退出。
- `--setvers VERSION`：更新工作区内部的 CICE 版本，可选择将改动提交仓库；`--version` 会显示新值。版本通常如 `5.1.2`，也可使用其他字母数字串。
- `--case`、`-c CASE`：案例名称，可为相对路径或绝对路径；不可与 `--test`、`--suite` 同时使用；三种模式必须选其一。
- `--mach`、`-m MACHINE`：机器名，应与 `configuration/scripts/machines/` 中的 Macros 和 env 文件一致；所有模式必需，与 `--env` 一起确定编译环境。
- `--env`、`-e ENVIRONMENT1,ENVIRONMENT2,...`：机器的编译环境，须对应 Macros 和 env 文件。每台机器可支持不同编译器、版本、MPI 库等。测试或套件可用无空格的逗号分隔列表，同时测试多个环境；案例只能指定一个。默认 `intel`。
- `--pes`、`-p MxN[xBXxBY[xMB]]`：仅用于案例，指定任务数 `M` 与线程数 `N`，还可指定 x、y 方向块尺寸 `BX`、`BY` 及最大块数 `MB`。支持 `MxN`、`MxNxBXxBY`、`MxNxBXxBYxMB` 三种格式；未给出的块参数按网格和并行度自动计算。默认 `4x1`。
- `--acct ACCOUNT`：可选的批处理账户，见“机器账户设置”。
- `--queue QUEUE`：可选的批处理队列，见“机器队列设置”。
- `--grid`、`-g GRID`：网格名；当前驱动支持 `gx1`、`gx3`、`tx1`，默认 `gx3`。
- `--set`、`-s SET1,SET2,...`：用无空格的逗号分隔列表选用案例预设，可改 namelist 或整体案例设置；套件的预设在套件文件中定义。可用预设位于 `configuration/scripts/options/`，也可用 `cice.setup --help` 查看。案例和单项测试会纳入 `~/.cice_set` 中的设置；`--ignore-user-set` 可覆盖这一行为。
- `--ignore-user-set`：忽略用户设置文件；测试套件始终忽略它。原文在此处同时写作 `~/.cice.set` 与 `~/.cice_set`，请以实际脚本使用的文件名为准。

建立案例必须指定 `--case` 和 `--mach`，也建议显式指定 `--env`；`--pes`、`--grid` 常有用。通常无需 `--acct` 和 `--queue`，可用 `~/cice_proj` 文件代替，见“机器账户设置”。

### 预设选项（Preset Options）

预设文件位于 `configuration/scripts/options/`，通过 `--set` 为案例或测试指定。完整清单可运行 `cice.setup --help` 查看。默认 namelist 和设置分别由 `configuration/scripts/ice_in` 与 `configuration/scripts/cice.settings` 提供；建立案例时，`set_env.setting` 和 `set_nml.setting` 修改默认值，最终写入案例目录的 `cice.settings` 和 `ice_in`。若多个预设冲突，以最后一个为准；某些预设彼此不兼容。

若存在 `~/.cice_set`，其中一行逗号分隔的选项会并入 `--set`；命令行优先。`--ignore-user-set` 可忽略该文件。常见预设包括：`debug`（调试编译）；`buildclean`、`buildincremental`（清理或增量构建）；`short`、`medium`、`long`（批处理时限）；`gx3`、`gx1`、`tx1`（网格）；`diag1`（逐时间步诊断）；`run10day`、`run1year`（运行时长）；`dslenderX1`、`droundrobin`、`dspacecurve`（区域分解）；`bgcISPOL`、`bgcNICE`（生物地球化学选项）；`boxadv`、`boxnodyn`、`boxrestore`（简单盒模型配置）；`alt*`（测试用动力学和物理过程组合）。预设可能变化，新增预设只需在选项目录添加相应文件，详见[开发者测试选项](../developer_guide/dg_scripts.md#测试选项)。

最简单的案例只指定名称、机器和环境；也可以增加预设：

```sh
cice.setup --case mycase1 --mach spirit --env intel
cice.setup --case mycase2 --mach spirit --env intel --set debug,diag1,run1year
```

建立后仍可修改 `cice.settings` 和 `ice_in`。

### 进一步了解 `cice.build`

`cice.build` 复制到案例目录，应从该目录交互运行。CICE 使用 make 构建；案例目录含通用 Makefile 与机器专用 Macros 文件。`cice.build` 封装 make 调用并提供其他功能。构建首先编译小型 C 程序生成 `makdep`，再运行它生成依赖文件，并由 Makefile 自动包含，因此用户无需手写依赖；最后 make 编译 CICE 源码并生成 `cice` 可执行文件。

推荐不带参数运行 `cice.build`。`cice.build [-h|--help]` 显示用法；若传入 make 参数或目标，脚本会关闭大部分附加功能，将参数直接交给 make。例如 `cice.build --version` 向 make 传递 `--version`；`cice.build targets` 显示 Makefile 的有效目标。`cice.build cice` 或 `cice.build all` 大体相当于无参数构建，但会关闭上述附加功能。完整构建都会编译 `makdep`、生成源码依赖并编译源码。`clean`／`realclean` 清理构建；`db_files`／`db_flags` 输出 Makefile 配置信息；`makdep`／`depends` 只构建依赖工具或依赖文件；也可指定某个 CICE 目标文件。`cice.settings` 的 `ICE_CLEANBUILD` 默认是真，表示每次运行前自动清理旧构建；开发时需要节省时间可改为增量构建。

### C 预处理器宏（C Preprocessor, CPP macros）

预处理宏控制编译时是否包含 NetCDF、MPI 或特定 Fortran 特性。Makefile 的 `CPPDEFS` 变量用 `-D[CPP]` 格式向 C、Fortran 编译器传宏，如 `-DUSE_NETCDF`；其值包括 `cice.settings` 中的 `ICE_CPPDEFS` 和 `Macros.[machine]_[environment]` 中预置的设置。通常应设 `-DFORTRANUNDERSCORE`，以支持 `ice_shr_reprosum.c` 的 Fortran/C 接口；使用 NetCDF 时还应定义 `-DUSE_NETCDF`。可用宏列表见[参数索引](../cice_index.md)。

## 移植（Porting）

移植需要处理四方面：`env.[machine]_[environment]` 中的编译器、环境变量及软件环境；`Macros.[machine]_[environment]` 中的构建宏；`cice.batch.csh` 中的批处理提交设置；`cice.launch.csh` 中的模型启动命令。将新机器的 env 与 Macros 文件加到 `configuration/scripts/machines/`，并修改 `configuration/scripts/cice.batch.csh` 和 `configuration/scripts/cice.launch.csh`。`cice.setup --mach` 指机器，`--env` 指环境；两者共同决定编译器、版本、依赖库和批处理设置。同一机器可以有多个不同名称的环境。

操作步骤为：进入 `configuration/scripts/machines/`，复制现有 env 与 Macros 文件并改名，编辑内容；返回 `configuration/scripts/`，分别在 `cice.batch.csh` 和 `cice.launch.csh` 添加机器对应的批处理和作业启动段；将强迫数据下载解包到 env 文件的 `ICE_MACHINE_INPUTDATA` 所指位置。此过程通常需要迭代：先建立案例，在案例目录调整 env 与 Macros 直到可以构建和运行；再将两文件复制回机器目录，更新批处理与启动脚本，复测后提交到仓库。

### 机器变量（Machine variables）

`env.[machine]` 中的变量为指定机器、编译器与批处理系统生成可运行案例；有些变量可选。

| 变量 | 格式 | 含义 |
| --- | --- | --- |
| `ICE_MACHINE_MACHNAME` | 字符串 | 机器名 |
| `ICE_MACHINE_MACHINFO` | 字符串 | 机器信息 |
| `ICE_MACHINE_ENVNAME` | 字符串 | 环境／编译器名称 |
| `ICE_MACHINE_ENVINFO` | 字符串 | 环境／编译器信息 |
| `ICE_MACHINE_MAKE` | 字符串 | make 命令 |
| `ICE_MACHINE_WKDIR` | 字符串 | 工作目录根路径 |
| `ICE_MACHINE_INPUTDATA` | 字符串 | 输入数据根目录 |
| `ICE_MACHINE_BASELINE` | 字符串 | 回归测试基线根目录 |
| `ICE_MACHINE_SUBMIT` | 字符串 | 批处理提交命令 |
| `ICE_MACHINE_TPNODE` | 整数 | 每节点 MPI 任务数上限 |
| `ICE_MACHINE_MAXPES` | 整数 | 每作业总处理器数上限（可选） |
| `ICE_MACHINE_MAXTHREADS` | 整数 | 每 MPI 任务线程数上限（可选） |
| `ICE_MACHINE_MAXRUNLENGTH` | 整数 | 批处理墙钟时限，小时（可选） |
| `ICE_MACHINE_ACCT` | 字符串 | 默认批处理账户 |
| `ICE_MACHINE_QUEUE` | 字符串 | 默认批处理队列 |
| `ICE_MACHINE_BLDTHRDS` | 整数 | 构建所用线程数 |
| `ICE_MACHINE_QSTAT` | 字符串 | 批处理作业状态命令（可选） |
| `ICE_MACHINE_QUIETMODE` | 真／假 | 减少构建输出的标志（可选） |

### 交叉编译（Cross-compiling）

模型有时须在一台平台构建、另一台平台运行，例如运行环境只能通过批处理队列访问。但构建时 `makdep` 既要编译也要执行。Makefile 的 `CFLAGS_HOST` 可为构建主机上的 `makdep` 编译提供专用编译标志；需要时在 `Macros.[machine]_[environment]` 添加，例如 `CFLAGS_HOST = -xHost`。

### 机器账户设置（Machine Account Settings）

默认账户来自 `env.[machine]` 的 `ICE_MACHINE_ACCT`。用户可在主目录创建 `.cice_proj`，将首选账户写在第一行；也可在 `cice.setup` 使用 `--acct`。优先级依次为命令行、`.cice_proj`、env 文件。

### 机器队列设置（Machine Queue Settings）

支持的机器在 `env.[machine]` 用 `ICE_MACHINE_QUEUE` 指定默认队列。也可直接修改 `cice.run`／`cice.test`，更方便的是在 `cice.setup` 使用 `--queue`。

## 移植到笔记本或个人计算机

仓库提供 `configuration/scripts/machines/environment.yml`，用于建立运行 CICE 及其绘图、质量控制脚本所需的 [conda](https://docs.conda.io/en/latest/) 环境。Consortium 对 macOS 和 GNU/Linux 提供尽力而为的支持；Windows 未经测试，但可能通过 [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) 使用。按本节安装 Miniconda 并创建 `cice` 环境后，通常无需执行上文完整的移植流程。

### 安装 Miniconda

建议用 [Miniconda](https://docs.conda.io/en/latest/miniconda.html) 根据 `environment.yml` 创建独立 conda 环境，此操作只需一次。若尚未安装 Miniconda 或 Anaconda，可依照[官方安装说明](https://conda.io/projects/conda/en/latest/user-guide/install/index.html)，或执行以下命令。

```bash
# macOS：下载安装程序，按提示安装并重启 shell
curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o ~/miniconda.sh
bash ~/miniconda.sh

# GNU/Linux：下载安装程序，按提示安装并重启 shell
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh
```

某些 Linux 发行版（包括 Ubuntu 系列）的系统 csh 与 conda 不兼容，需要安装向后兼容 csh 的 tcsh，并将其设为 csh：

```bash
sudo apt-get install tcsh
sudo update-alternatives --set csh /bin/tcsh
```

### 初始化 shell 以使用 conda

建议初始化默认 shell，此操作只需一次。Miniconda 安装程序通常会询问是否执行；若当时未同意，可按下面方法操作。安装程序回答“yes”只会初始化 Bash。macOS 10.14 及更早版本和 GNU/Linux 的默认 shell 通常是 Bash，macOS 10.15 及以后通常是 Zsh。这些命令修改 shell 启动文件，使 `conda` 可用，并禁止启动时自动激活安装 Miniconda 时创建、但 CICE 不用的 `base` 环境。

```bash
# Bash
source $HOME/miniconda3/bin/activate
conda init bash
conda config --set auto_activate_base false

# Zsh
source $HOME/miniconda3/bin/activate
conda init zsh
conda config --set auto_activate_base false

# tcsh
source $HOME/miniconda3/etc/profile.d/conda.csh
conda init tcsh
conda config --set auto_activate_base false

# fish
source $HOME/miniconda3/etc/fish/conf.d/conda.fish
conda init fish
conda config --set auto_activate_base false

# xonsh
source-bash $HOME/miniconda3/bin/activate
conda init xonsh
conda config --set auto_activate_base false
```

执行相应命令后关闭并重新打开 shell。

### 手动初始化 shell

若不愿修改 shell 启动文件，则在使用任何 conda 命令、编译或运行 CICE 前，在当前会话执行相应命令，以使 `conda` 在该会话中可用：

```bash
# Bash、Zsh
source $HOME/miniconda3/bin/activate
# tcsh
source $HOME/miniconda3/etc/profile.d/conda.csh
# fish
source $HOME/miniconda3/etc/fish/conf.d/conda.fish
# xonsh
source-bash $HOME/miniconda3/bin/activate
```

### 建立 CICE 目录和 conda 环境

conda 配置要求 `$HOME/cice-dirs` 下存在相应目录和文件。此步骤只需一次：

```bash
cd $HOME
mkdir -p cice-dirs/runs cice-dirs/baseline cice-dirs/input
# 从 https://github.com/CICE-Consortium/CICE/wiki/CICE-Input-Data 下载所需强迫数据
# 并解包到 $HOME/cice-dirs/input
```

如需将这些目录放在其他位置，可在主目录建立符号链接：

```bash
cd ${somewhere}
mkdir -p cice-dirs/runs cice-dirs/baseline cice-dirs/input
# 下载并解包强迫数据到 cice-dirs/input
cd $HOME
ln -s ${somewhere}/cice-dirs cice-dirs
```

也可从 conda 配置出发，为本机建立完整移植配置，见前文“移植”。克隆 CICE 源码后，在仓库中创建 `cice` 环境：

```bash
conda env create -f configuration/scripts/machines/environment.yml
```

这一操作仅需一次，得到静态环境。以后若需更新到较新软件版本：

```bash
conda env create -f configuration/scripts/machines/environment.yml --force
```

### 使用 conda 配置

按前文“概述”操作，机器名使用 `conda`，环境名在 macOS 上用 `macos`、GNU/Linux 上用 `linux`：

```bash
# macOS
./cice.setup -m conda -e macos -c ~/cice-dirs/cases/case1
cd ~/cice-dirs/cases/case1
./cice.build
./cice.run

# GNU/Linux
./cice.setup -m conda -e linux -c ~/cice-dirs/cases/case1
cd ~/cice-dirs/cases/case1
./cice.build
./cice.run
```

几点说明：

- 此配置总是交互运行模型，`./cice.run` 与 `./cice.submit` 等价。
- 不应更新 `cice` conda 环境中的软件包或另装软件包。
- CPU 数量不足时，默认 MPI 配置 `-p 4x1` 可能报 OpenMPI“可用槽位不足以满足 4 个槽位”的错误。可用 `-p 1x1` 以单进程运行：`./cice.setup -m conda -e linux -p 1x1 ...`。若确需超额使用 MPI 进程，可在特定案例的 `cice.run` 中把 `mpirun -np <num> ./cice >&! $ICE_RUNLOG_FILE` 改成 `mpirun -np <num> --oversubscribe ./cice >&! $ICE_RUNLOG_FILE`；若想影响今后所有案例，可在 `configuration/scripts/cice.launch.csh` 中为相应的 `mpirun` 行加 `--oversubscribe`。
- 不建议在个人计算机运行 `quick_suite` 或 `travis_suite` 以外的测试套件。
- 案例目录的 `cice.build` 和 `cice.run` 在编译或运行时自动通过 `env.conda_{linux.macos}` 激活 `cice` 环境。
- 使用 Python 时间序列绘图或质量控制脚本时须手动激活环境。

```bash
cd ~/cice-dirs/cases/case1
conda env create -f configuration/scripts/machines/environment.yml --force
conda activate cice
python timeseries.py ~/cice-dirs/cases/case1/logs
conda deactivate
```

环境还包含构建 HTML 文档所需的 Sphinx：

```bash
cd doc
conda activate cice
make html
# 在浏览器打开 build/html/index.html
conda deactivate
```

## 强迫数据（Forcing data）

输入数据目录按机器由 `env.[machine]` 中的 `ICE_MACHINE_INPUTDATA` 定义，通常由多位用户共用；可建立群组可读写的公共目录，以便数据集更新。CICE 输入数据保存在匿名 FTP 服务器上，下载说明见 [CICE Input Data](https://github.com/CICE-Consortium/CICE/wiki/CICE-Input-Data)。该站点提供多种网格的测试强迫数据；这些数据仅供代码测试，不应用于正式模拟或当作观测数据，也不应发表基于这些数据的结果。

## 运行目录（Run Directories）

`cice.setup` 创建案例目录，但模型实际在 `cice.settings` 的 `ICE_OBJDIR` 和 `ICE_RUNDIR` 目录下构建、运行。提交运行脚本时，当前 `ice_in`、`cice.settings`、`env.[machine]` 会从案例目录复制到运行目录，故一般不应编辑运行目录副本。完成后，构建和运行日志从运行目录复制回案例目录的 `logs/`。

## 本地修改（Local modifications）

可在案例目录手动修改脚本和设置，也可在主工作区修改源码。修改源码后应重新构建再提交运行。建议始终在案例目录编辑脚本和输入设置；构建、提交和运行时通常会用案例目录中的版本覆盖运行目录里的文件。

## 使用 shell 别名（Shell Aliases）

以下别名利用 CICE 脚本，仅供参考，并非 CICE 自带或运行所必需。运行时 `ice_in`、`cice.settings`、`env.[machine]` 会复制到运行目录，因此可以使用其中的变量。用户可自行将别名放入 shell 启动文件：

```bash
#!/bin/tcsh
# 从案例或运行目录载入 CICE 环境文件
alias cice_env 'source env.*; source cice.settings'
# 在案例目录和运行目录之间切换
alias cdrun  'set rundir=`\grep "setenv ICE_RUNDIR" cice.settings | awk "{print "\$"NF}"` && cd $rundir'
alias cdcase 'set casedir=`\grep "setenv ICE_CASEDIR" cice.settings | awk "{print "\$"NF}"` && cd $casedir'

#!/bin/bash
# 从案例／测试目录进入运行目录，或反向返回
alias cdrun='cd $(cice_var ICE_RUNDIR)'
alias cdcase='cd $(cice_var ICE_CASEDIR)'
# 监视最新运行日志
alias cice_tail='tail -f $(ls -1t cice.runlog.* |head -1)'
# 打开最近的运行或构建日志
alias cice_lastrun='$EDITOR $(ls -1t logs/cice.runlog.* |head -1)'
alias cice_lastbuild='$EDITOR $(ls -1t logs/cice.bldlog.* |head -1)'
alias cice_rundir='cice_var ICE_RUNDIR'
# 打开 tcsh 并载入环境，可用于调试器
alias cice_shell='tcsh -c "cice_env; tcsh"'

# 输出 cice.settings 中的 CICE 变量值
cice_var() {
  \grep "setenv $1" cice.settings | awk "{print "\$"3}"
}
```

## 绘图工具（Plotting Tools）

CICE 提供简单绘图脚本：`timeseries.py` 从日志绘制南北半球多个变量的时间序列；`ciceplots2d.py` 从历史文件绘制全球和极区投影的二维图；`ciceplots.csh` 准备 Python 脚本输入并调用它们。两个 Python 工具均生成 PNG。依赖 Python 3、numpy、matplotlib、re、datetime、netcdf4，以及 basemap、basemap-data、basemap-data-hires。最容易用项目提供的 conda 环境安装：

```bash
conda env create -f configuration/scripts/machines/environment.yml --force
conda activate cice
```

编辑并运行 `ciceplots.csh`，其中也展示如何单独调用 Python 脚本。使用 `cice.setup` 建立案例或测试时，这三个脚本会自动复制到案例目录；也可从 `configuration/scripts/` 使用。

`timeseries.py` 的调用示例：

```bash
./timeseries.py /p/work1/turner/CICE_RUNS/conrad_intel_smoke_col_1x1_diag1_run1year.t00 --grid --case CICE6.0.1
```

时间分辨率取决于日志输出频率。默认绘制总海冰面积（km²）、总海冰范围（km²）、总海冰体积（m³）、总积雪体积（m³）及海冰速度均方根（m/s）；可用可选命令行参数指定图表。

`ciceplots2d.py` 调用示例：

```bash
./ciceplots2d.py aice /p/work1/turner/CICE_RUNS/conrad_intel_smoke_col_1x1_diag1_run1year.t00/history/iceh.2005-09.nc CICE6.0.1 "Sept 2005 Mean" 2005Sep
```

此例从 `iceh.2005-09.nc` 的 `aice` 绘制全球、北半球和南半球三张图。标题包含 `CICE6.0.1` 与 `Sept 2005 Mean`；PNG 文件名包含 `2005Sep`、变量名和区域名。二维图使用 matplotlib 散点功能绘制，因而相对简陋。

[英文原文](../../source/user_guide/ug_running.rst)
