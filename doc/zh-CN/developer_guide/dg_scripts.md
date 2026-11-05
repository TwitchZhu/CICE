# 脚本

脚本是 CICE 软件包的第三部分，用于建立案例、构建及运行独立模式。

## 文件清单

`configuration/scripts/` 下的目录结构及文件作用如下：

| 文件或目录 | 作用 |
| --- | --- |
| `Makefile` | 主要 Makefile |
| `cice.batch.csh` | 为特定机器创建批处理脚本 |
| `cice.build` | 编译代码 |
| `cice.decomp.csh` | 根据网格及任务／线程数量计算分解方式 |
| `cice.launch.csh` | 生成运行可执行程序的脚本逻辑 |
| `cice.run.setup.csh` | 设置运行脚本 |
| `cice.settings` | 定义环境、模式配置和运行设置 |
| `cice.test.setup.csh` | 创建模式测试配置 |
| `ciceplots.csh` | 生成 CICE 时间序列和二维图的一般脚本 |
| `ciceplots2d.py` | 生成二维 CICE 图的 Python 脚本 |
| `ice_in` | Namelist 输入数据 |
| `machines/` | 设置环境和 Macros 的机器专用文件 |
| `makdep.c` | 确定模块依赖关系 |
| `options/` | 可通过 `cice.setup` 命令行选择的其他 namelist 配置 |
| `parse_namelist.sh` | 用命令行配置替换 namelist 值 |
| `parse_namelist_from_settings.sh` | 用 `cice.settings` 的值替换 namelist 值 |
| `parse_settings.sh` | 用命令行配置替换 settings 值 |
| `setup_run_dirs.csh` | 创建案例运行目录 |
| `set_version_number.csh` | 根据 `cice.setup` 命令行更新模式版本号 |
| `timeseries.py` | 根据 CICE 日志生成时间序列图的 Python 脚本 |
| `tests/` | 配置和运行基本测试的脚本 |

## 实现策略

CICE 脚本的实现方式使 `cice.setup` 调用完成后，案例中的配置均已解析确定。这通过把特定文件复制到案例目录，以及在执行 `cice.setup` 时运行脚本来设置各文件实现。

`cice.setup` 控制案例设置，用 csh 编写；支持脚本主要是相对简单的 csh 或 sh 脚本。更多信息见[运行指南中的脚本](../user_guide/ug_running.md#脚本)。`cice.settings` 指定案例的一组环境默认值；`ice_in` 定义 CICE 驱动程序的 namelist 输入。

## 预设案例选项

通过 `cice.setup --set` 可以选用预设的 CICE 设置和 namelist 值。这些选项在 `configuration/scripts/options/` 中定义，文件名前缀为 `set_env` 或 `set_nml`。运行 `cice.setup` 时，它读取相应选项文件，并根据其中的值更新案例目录中的 `cice.settings` 和／或 `ice_in`。

文件名后缀决定 `-s` 选项名。例如：

```bash
cice.setup -s diag1,debug,bgcISPOL
```

这会查找后缀为 `diag1`、`debug` 和 `bgcISPOL` 的选项文件，然后应用相应设置。`parse_namelist.sh`、`parse_settings.sh` 和 `parse_namelist_from_settings.sh` 三个脚本负责修改 `ice_in` 与 `cice.settings`。

若要添加新选项，在 `configuration/scripts/options/` 中按适当名称和语法增加文件。`set_nml` 文件遵循 namelist 语法，`set_env` 文件遵循 csh 的 `setenv` 语法；可参考已有文件。选项名（例如 `diag1`、`debug`、`bgcISPOL`）不应包含特殊字符，以免影响脚本使用。

## 构建脚本

CICE 使用 GNU Make 构建模式。所有机器共用一个 `Makefile`。每台机器提供一个 `Macros` 文件以定义部分 Makefile 变量，并提供一个 `env` 文件以指定各编译器的模块／软件环境。`cice.build` 调用 Make 进行构建。该脚本还专门捕获循环依赖错误，以便在发生时明确提示。

`cice.build` 还有其他功能，包括传递 Makefile 目标，详见[用户指南中的 cice.build](../user_guide/ug_running.md#进一步了解-cicebuild)。脚本还提供一个供测试套件复用可执行文件的内部功能，可显著降低重复构建成本。它通过 `cice.build --exe` 调用，不应由用户交互式使用。

## 机器

机器专用信息位于 `configuration/scripts/machines/`，其中为每台受支持机器提供 `Macros` 文件和 `env` 文件。移植到新机器时还需要修改 `configuration/scripts/cice.batch.csh`。具体说明见[移植](../user_guide/ug_running.md#移植)。

## 测试选项

与 `cice.setup --set` 对应的值在 `configuration/scripts/options/` 中定义。它们是文本文件；创建案例时，`cice.setup` 使用这些值修改案例的 `cice.settings` 和 `ice_in`。名为 `set_env.$option` 的文件对应 `cice.settings` 中的值；`set_nml.$option` 对应 `ice_in` 中的值。文件每行包含一组简单的关键字和值；以 `#` 开头的行是注释。以 `test_` 开头的文件专门用于测试。

该目录还包含 `set_files.$option` 文件。它在单个设置文件之外增加一层组合机制，使设置可以由一组其他设置定义。文件内容是要应用的 `--set` 选项列表。文件名中的 `$option` 对应 `cice.setup` 的 `--set` 参数。可用逗号分隔多个选项；若设置冲突，以最后定义的值为准。

## 测试脚本

`configuration/scripts/tests/` 包含设置各种测试的脚本，例如 `test_smoke.script`、`test_restart.script`，以及指定每个测试所需选项文件的 `test_smoke.files`、`test_restart.files`。`baseline.script` 负责一般性的回归与对比测试。目录中还包含预设测试套件（例如 `base_suite.ts`），以及把测试套件结果提交到 CICE-Consortium 测试结果 Wiki 的 `report_results.csh`。

增加一个测试（例如 `newtest`）可能需要下列文件：

- `configuration/scripts/tests/test_newtest.script` 定义如何运行测试；这段脚本会并入案例测试脚本。
- `configuration/scripts/tests/test_newtest.files` 列出运行测试所需的 `configuration/scripts/options/` 选项文件。调用测试时，这些文件会复制到测试目录，供 `test_newtest.script` 使用。
- 可能还需要在 `configuration/scripts/options/` 中添加文件，既可以是通用的 `set_nml`、`set_env` 文件，也可以是测试专用文件（通常以 `test_nml` 开头）。

创建新测试，特别是编写 `test_newtest.script`，通常需要反复调整才能正常工作。

## QC 流程验证

代码验证（code validation，也称质量控制，quality control，QC）测试用于验证**非逐位一致**的模式变更。相关脚本位于 `configuration/scripts/tests/QC/`，测试流程见[用户指南的验证章节](../user_guide/ug_testing.md#代码验证测试非逐位一致性验证)。本节介绍用于检验 QC 测试流程本身的一组脚本；当 QC 测试或其脚本（如 `cice.t-test.py`）发生修改时，应运行这一流程。本节**验证的是 QC 脚本**，不是介绍如何运行 QC 验证测试本身。

两个自动验证脚本分别是：

- `gen_qc_cases.csh`：创建验证所需的四个测试案例，构建可执行文件并提交队列。
- `compare_qc_cases.csh`：对四个案例中的三个组合运行 QC 脚本，并报告是否得到预期结果。

`gen_qc_cases.csh` 接受与 `cice.setup` 类似的参数：`--mach`/`-m`（必填，机器）、`--env`/`-e`（编译器）、`--pes`/`-p`（任务数 × 线程数）、`--acct`（批处理账户）、`--grid`/`-g`（网格）、`--queue`（队列）及 `--testid`（用户定义的测试 ID）。

脚本创建四个案例，测试 ID 分别为 `qc_base`、`qc_bfb`、`qc_test` 和 `qc_fail`。`qc_base` 使用默认 QC namelist；`qc_bfb` 与 `qc_base` 完全相同；`qc_test` 与 `qc_base` 不逐位一致，但不改变气候；`qc_fail` 既不逐位一致，也改变气候。

运行 `compare_qc_cases.csh` 需要 Python 2.7 或更新版本，以及 Python 的 NetCDF 和 NumPy 包。可使用 `pip` 安装：

```bash
pip install --user netCDF4
pip install --user numpy
```

若某台机器提示 `pip: Command not found`，请检查是否须先加载 Python 模块（`module avail python`）。

执行 QC 流程验证：

```bash
# 在 CICE 根目录下
cp configuration/scripts/tests/QC/gen_qc_cases.csh .
cp configuration/scripts/tests/QC/compare_qc_cases.csh .

# 创建所需测试案例
./gen_qc_cases.csh -m <machine> --acct <acct>

# 等待四个作业全部完成，再进行比较
./compare_qc_cases.csh
```

`compare_qc_cases.csh` 对 `qc_base` 与 `qc_bfb`、`qc_nonbfb`、`qc_fail` 三组组合运行 QC 脚本。原文中的 `qc_test` 与此处的 `qc_nonbfb` 命名不一致，使用时请核对实际脚本。预期输出为：前两组通过（`PASSED`），气候变化组失败（`FAILED`），最后报告 `QC Test has validated`。

原文：[dg_scripts.rst](../../source/developer_guide/dg_scripts.rst)
