# 故障排查

首先查看 [CICE Wiki 中的常见问题](https://github.com/CICE-Consortium/CICE/wiki)。

## 目录结构

2022 年 11 月，`cicedynB` 目录更名为 `cicedyn`。

## 初始设置

如果遇到问题，可以先手动编辑案例目录中的 `env`、`Macros` 和 `cice.run` 文件，直到配置能正常工作，再把 `env` 与 `Macros` 文件复制回 `configuration/scripts/machines/`。

直接修改运行目录中的文件（例如 namelist）后，如果再次执行案例目录中的脚本，这些修改会被覆盖。若需改动 `cice.run.setup.csh`，必须手动修改该脚本。

检查 `block_size_x`、`block_size_y` 和 `max_blocks` 是否与 `ice_in` 中的 `processor_shape` 及其他区域选项兼容。若用耙式（rake）或空间填充曲线（space-filling curve）算法分配块（由 `ice_in` 中的 `distribution_type` 指定），`max_blocks` 不够大时程序会中止；诊断输出会给出正确值。此外，`spacecurve` 只适用于某些块大小：它们产生的 x、y 方向块数只能由 2、3 或 5 的倍数组成。

若从重启文件开始，确认 `kcatbound` 与创建该文件时相同；本代码发行版附带的文件使用 `kcatbound=0`。其他配置参数，例如 `NICELYR`，也须在前后两次运行间保持一致。

独立运行时，检查 `Macros.*` 中**未**设置 `-Dcoupled`。耦合运行时，检查 `Macros.*` 中**已**设置 `-Dcoupled`，以及 CESM、popcice、hadgem 等对应耦合模式的专用预处理选项。将 `ICE_CLEANBUILD` 设为真，以便重建前清理构建结果。

## 重启

手动重启测试需要在 `ice_in` namelist 中写入重启文件路径。确认 `kcatbound` 与创建重启文件时相同；`nilyr` 等其他配置参数也必须在两次运行中一致。

CICE v5 及后续版本的配置使得从旧模拟重启较困难。重启文件与新运行必须使用相同的冰厚类别数、类别边界，以及每个类别的垂直层数。物理方案的明显变化（例如盐度剖面变化）也可能导致重启失败。因此，新配置可能需要以 `runtype='initial'` 开始。CICE v4.1 附带的二进制重启文件采用 BL99 热力学、4 个垂直层和 5 个冰厚类别（`kcatbound=0`），不能直接用于默认的 CICE v5 及后续版本的 7 层配置。此外，CICE 目前的默认重启文件格式已从二进制改为 NetCDF。

使用 `runtype='continue'` 重启，要求新运行所用的所有示踪物都有重启数据。如果某些示踪物的重启数据缺失，使用 `runtype='initial'`，将 `ice_ic` 设为核心重启文件名，并对有数据的各示踪物把对应 namelist 重启标志设为真。缺失数据的示踪物会按默认值初始化。

在三极网格上，使用二进制或普通（非 PIO）NetCDF 重启文件时，应设置 `restart_ext=true`。

只要新运行使用相同的冰层数（默认 4），就有可能把 v4.1 重启文件转换为新文件结构及格式；如果物理参数化也相同，代码应能从转换后的文件继续运行。但如果物理过程不同，例如以 mushy 热力学替代 BL99，仍可能失败。转换 v4.1 重启文件的方法见 [CICE v5 文档](https://github.com/CICE-Consortium/CICE-svn-trunk/blob/main/cicedoc/cicedoc.pdf)第 5.2 节。

如果不使用 PIO 时串行写入重启文件耗时很长，请参阅下一节。

## 执行缓慢

在某些体系结构上，非常小的下溢数值（underflow，例如 $10^{-300}$）不会自动归零。通常可通过编译器标志处理；如果没有相应标志，可尝试取消 `ice_dyn_evp.F90` 或 `ice_dyn_eap.F90` 的 `stress` 子程序末尾代码块的注释。这会增加一些计算开销，但通常比持续处理下溢更快。

## 调试提示

以下工具可帮助调试代码。由于模块依赖可能冲突，并非所有工具都可在代码的任意位置使用。

| 工具或设置 | 作用 |
| --- | --- |
| `debug_ice`（`ice_diagnostics.F90`） | `print_state` 的封装，可在时间步循环的许多位置方便调用。 |
| `print_state`（`ice_diagnostics.F90`） | 打印指定网格单元的冰状态和强迫场。 |
| `debug_forcing=true`（`ice_in`） | 打印与输入强迫有关的多项诊断量。 |
| `debug_blocks=true`（`ice_in`） | 在块分解和分配期间打印诊断信息。 |
| `debug_model=true`（`ice_in`） | 对 `print_points` 关联的第一个点打印扩展诊断信息。 |
| `debug_model_i`（整数，`ice_in`） | 定义 `debug_model` 诊断点的局部 i 索引。 |
| `debug_model_j`（整数，`ice_in`） | 定义诊断点的局部 j 索引。 |
| `debug_model_iblk`（整数，`ice_in`） | 定义诊断点的局部 `iblk` 值。 |
| `debug_model_task`（整数，`ice_in`） | 定义诊断点所在的局部任务值。 |
| `debug_model_step`（`ice_in`） | 开始打印 `debug_model` 诊断的时间步。 |
| `print_global`（`ice_in`） | 若为真，计算并打印多个用于能量与质量平衡分析的全局和；可能显著降低效率。 |
| `print_points`（`ice_in`） | 若为真，打印 namelist 中 `lonpnt`、`latpnt` 指定的两个网格单元的多项诊断量，并给出可用于调用 `print_state` 的局部网格索引、块号和处理器号（`ip`、`jp`、`iblkp`、`mtask`）。由于需要从处理器汇集数据，可能比较慢。 |
| `conserv_check=true`（`ice_in`） | 诊断各算法中的守恒性。 |
| `global_minval`、`global_maxval`、`global_sum`（`ice_global_reductions.F90`） | 计算并打印单个实数数组的最小值、最大值或全局和。 |

## 已知问题

- 在一个时间步中，网格单元若从无冰变成有冰或反向变化，传给 CESM 耦合器的通量可能因冰面积缩放而取值不正确。CESM 通量耦合器的设计要求面积缩放，以便一致地处理冰和陆地模式；但陆地面积不会像冰面积那样在网格单元内突然变成零。
- 使用旧 CCSM 辐射方案（`shortwave='default'` 或 `'ccsm3'`）且 `snowpatch<1` 时，总短波辐射中相当大的一部分（超过 10%）被表面吸收，本应透入冰内部。这是因为计算中使用了汇总后的有效反照率，而非裸冰反照率。
- 融化开始日期 `melt_onset` 和冻结开始日期 `frz_onset` 不包含在核心重启文件中。若在 1 月 1 日之后重启，它们在当年可能不正确。这些变量的实现也以北极为背景，应用于南极时可能不正确。
- 在某些体系结构上，单处理器 `system_clock` 计时可能不稳定。
- 若从时间平均时段中途重启，包含时间平均数据（`ice_in` 中 `hist_avg=true`）的历史文件会不正确。
- 独立运行时，在 `ycycle` 末尾重启不能实现精确续算。
- 在 `histfreq` 中重复使用同一频率会造成意外结果，并导致代码中止。
- 使用填充（padding）时，历史输出中的经纬度场可能不正确。

## 反照率的解释

关于反照率（albedo）解释的更多信息见 [Icepack 用户指南](https://cice-consortium-icepack.readthedocs.io/en/main/user_guide/index.html)。

## VP 动力学结果

VP 动力学求解器（`kdyn=3`）需要全局求和。默认的高效求和实现对不同分解方式或处理单元数量不能保证逐位一致。将 namelist 设为 `bfbflag=reprosum`，或在创建案例时使用 `-s reprosum`，可以恢复 VP 求解器结果的逐位一致性。

## 不断增加的子过程参数化

随着海冰过程有了多种替代参数化，一些子过程出现在代码的多个位置，而且描述方式不同。例如，海冰孔隙率、渗透率，以及相关的冲刷与淹没过程，分别由 mushy 热力学、不同融池方案及盐水层高度示踪物计算，各自使用自己的方程。类似地，BL99 和 mushy 热力学对露出水面高度（freeboard）及雪冰形成的计算不同；地形融池和水平冰融池方案都允许融池上方生长新冰，但其 Stefan 冻结公式略有区别。代码中与融池水有关的质量计算也不一致。以后可能比较这些过程参数化，并统一其子过程描述。

原文：[ug_troubleshooting.rst](../../source/user_guide/ug_troubleshooting.rst)
