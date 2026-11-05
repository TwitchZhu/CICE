# gx3 官方配置五天对照案例

本案例取当前 CICE 6.6.3 源码树 `quick_suite.ts` 中这一项的配置：

```text
smoke gx3 8x2 diag1,run5day
```

GNU、Intel 使用官方 `cice.setup --case` 生成可手动编译、提交的独立案例；物理设置对应上述 smoke 项，但不调用整个 suite 的自动测试流程。JAX 使用相同物理配置，单进程运行完整网格。

这是 **5 天、120 步**，不是原来 `gx3_5step_simple` 的 5 小时简化试验。

**运行地点：服务器只运行 GNU、Intel Fortran；JAX 和结果比较都在本地运行。服务器不需要安装 JAX，也不需要上传整个 `CICE-JAX` 项目。**

**命令执行目录：所有服务器命令统一在 `cice-dirs/cases/` 下执行。命令块中的 `( ... )` 会临时进入所需目录，结束后终端仍停留在 `cice-dirs/cases/`，无需手动切换。第 6、7 节的本地命令统一在本地 `CICE-JAX` 根目录执行。**

## 1. 配置与文件

- 网格：gx3，100×116；5 个厚度类别、7 个冰层、1 个雪层。
- 时间：2005-01-01 00:00 至 2005-01-06 00:00，`dt=3600`，`npt_unit='d'`，`npt=5`。
- 热力：`ktherm=2`；短波 `dEdd`；level-ice ponds 开启。
- 动力：标准 EVP，`kdyn=1`，`ndte=240`，`revised_evp=.false.`。
- 输运/冰脊：`advection='remap'`，`ktransport=1`，`kridge=1`。
- Fortran：8 MPI×2 OpenMP，默认分块 5×29；JAX：单进程、100×116 完整网格，开启 x64。
- 输出沿用官方：`diagfreq=1`，第 5 天写 restart；history 为单精度月平均并写初始场。五天没有完整月平均输出，不能把它当作每日 history 试验。

本地 `CICE-JAX/cases/gx3_5day/` 中的文件：

```text
gx3_5day/
  ice_in                     JAX 实际读取的配置
  run.py                     JAX 入口
  prepare_fortran_cases.sh    调用官方 cice.setup，生成 GNU、Intel 案例
  compare_all.py              三端最终 restart 差异报告
  gnu/ice_in                 GNU 本地配置参考；结果收集到 gnu/
  intel/ice_in               Intel 本地配置参考；结果收集到 intel/
  reference/                 本次使用的 CICE 配置来源快照
```

`reference/` 保存当前相邻 `CICE` 源码树中的基础 `ice_in`、`set_nml.gx3`、`set_nml.diag1`、`set_nml.run5day`、`quick_suite.ts` 和版本文件。三份 namelist 按“基础 → gx3 → diag1 → run5day”覆盖生成，再设置运行布局与输入路径。GNU 和 Intel 的本地参考 namelist 完全相同；JAX 仅改变输入相对路径、进程数及分块布局。

本地参考 namelist 的路径相对于所在目录。**不要用它覆盖服务器生成的 `ice_in`**：服务器实际输入路径由机器配置指定。配置快照不等于完整源码版本证明；GNU、Intel 必须使用同一套源码，并保存下面的源码校验记录。

## 2. 上传准备文件，在服务器生成 Fortran 案例

先将本地 `cases/gx3_5day/` 中的 `prepare_fortran_cases.sh`、整个 `reference/` 目录和本 README 上传到服务器 `cice-dirs/cases/gx3_5day/`。不需要上传 `run.py`、JAX 源码或本地结果目录。

服务器目录布局如下：

```text
工作目录/
  CICE/
  cice-dirs/
    cases/
      gx3_5day/                 上传的准备文件
        prepare_fortran_cases.sh
        reference/
        README.md
      gx3_5day_gnu/             脚本生成
      gx3_5day_intel/           脚本生成
    runs/                      实际位置以机器配置为准
```

使用预定的 CICE 6.6.3 源码及 gx3 输入数据，两个编译器共享同一份源码和输入。此前 `fortran_pond_debug/` 增加的诊断快照、中间量记录和输出可以保留，不要求为了本次五天试验全部撤销；GNU、Intel 必须使用同一份源码，并保存源码校验记录。新案例的 `debug_model=.false.` 会关闭受该开关控制的快照和诊断日志，但部分内部诊断数组仍会填充，因此不能把关闭输出等同于完全移除了诊断代码。保留诊断扩展时，应说明这是“使用官方试验配置、带本地诊断扩展的 CICE”。这里没有验证它与未加诊断的源码逐位等价。

本案例不需要再次安装旧诊断包。尤其不要复制包内旧 `ice_in`：其中五步、关闭输运和冰脊等简化设置会改变本次试验。继续使用官方 `cice.setup` 生成的新五天配置。

确认 `CICE/configuration/scripts/machines/` 中有 `env.xingyi_gnu`、`Macros.xingyi_gnu`、`env.xingyi_intel`、`Macros.xingyi_intel`。本地 CICE 当前缺少 Intel 两个文件；服务器若也缺少，可从此前成功运行的 Intel 案例中复制这两个文件。已有归档副本在 `cases/gx3_5step_simple/intel/evidence/`。只复用机器/工具链文件，不复用旧 `ice_in` 或 `cice.settings`。机器配置中的输入目录、工作目录、队列、账户需适用于当前服务器。

在服务器 Bash 中进入已有的 **`cice-dirs/cases/`** 目录，执行：

```bash
bash gx3_5day/prepare_fortran_cases.sh ../../CICE xingyi .
```

脚本检查来源配置与快照相同，然后自动调用官方 `cice.setup`，使用 `-p 8x2 -g gx3 -s diag1,run5day --ignore-user-set`，分别生成 `gx3_5day_gnu/` 和 `gx3_5day_intel/`。无需进入 CICE 源码目录或另外执行 setup 命令。

已有同名案例或运行目录时停止，不覆盖。来源检查忽略 Windows/Linux 换行差异；其他配置不一致时停止，需先核对源码版本，不要跳过检查后直接混用。

生成后核对两个 `cice.settings` 的 `ICE_NTASKS=8`、`ICE_NTHRDS=2`、`ICE_CLEANBUILD=true`，以及相互独立的 `ICE_RUNDIR` 和 `ICE_OBJDIR`。核对 `ice_in` 的五天时间、`ndte=240`、输运和冰脊开关及输入路径。官方配置没有唯一跨平台编译选项；本实验比较的是保存下来的 GNU/Intel 工具链，包括 MPI、NetCDF 和优化选项。

## 3. 服务器：GNU 编译、运行并保存证据

在服务器 `cice-dirs/cases/` 下，整段执行，保存证据、编译并提交 GNU：

```bash
(
set -euo pipefail
cd gx3_5day_gnu
cp ice_in cice.settings env.* Macros.* evidence/
(cd ../../../CICE && find cicecore icepack/columnphysics -type f \( -name '*.F90' -o -name '*.h' \) -print0 | sort -z | xargs -0 sha256sum) > evidence/source.sha256
(cd ../../../CICE/input/CICE_data && find ic/gx3 grid/gx3 forcing/gx3 -type f -print0 | sort -z | xargs -0 sha256sum) > evidence/input.sha256
csh -f <<'CSH' > evidence/environment.txt 2>&1
source ./cice.settings
source ./env.${ICE_MACHCOMP}
module list
which mpif90
mpif90 --version
mpif90 -show
nf-config --all
nc-config --all
CSH
csh ./cice.build && csh ./cice.submit
)
```

等待作业结束，确认本次日志有 `CICE COMPLETED SUCCESSFULLY`，最终步数为 120，最终 restart 为 `iced.2005-01-06-00000.nc`。不要继续使用未完成运行的结果。

## 4. 服务器：Intel 编译、运行

GNU 完成后，仍在服务器 `cice-dirs/cases/` 下，整段执行：

```bash
(
set -euo pipefail
cd gx3_5day_intel
cp ice_in cice.settings env.* Macros.* evidence/
(cd ../../../CICE && find cicecore icepack/columnphysics -type f \( -name '*.F90' -o -name '*.h' \) -print0 | sort -z | xargs -0 sha256sum) > evidence/source.sha256
(cd ../../../CICE/input/CICE_data && find ic/gx3 grid/gx3 forcing/gx3 -type f -print0 | sort -z | xargs -0 sha256sum) > evidence/input.sha256
csh -f <<'CSH' > evidence/environment.txt 2>&1
source ./cice.settings
source ./env.${ICE_MACHCOMP}
module list
which mpif90
mpif90 --version
mpif90 -show
nf-config --all
nc-config --all
CSH
csh ./cice.build && csh ./cice.submit
)
```

等待 Intel 作业结束，同样确认成功标志、120 步和最终 restart。运行间不修改共用的 CICE 源码或输入数据。

两端 `source.sha256` 与 `input.sha256` 应一致。编译器、依赖和编译参数允许不同，但必须在 `evidence/` 与构建日志中有记录。队列提交脚本应实际启动 8 MPI×2 线程；以生成的脚本和运行日志为准。

在服务器 `cice-dirs/cases/` 下核对两端校验记录（无输出表示一致）：

```bash
diff -u gx3_5day_gnu/evidence/source.sha256 gx3_5day_intel/evidence/source.sha256
diff -u gx3_5day_gnu/evidence/input.sha256 gx3_5day_intel/evidence/input.sha256
```

## 5. 服务器：下载前用官方脚本检查 GNU–Intel BFB

确认 GNU、Intel 都已成功完成 120 步后，在服务器 `cice-dirs/cases/` 下整段执行。命令从两个案例的 `cice.settings` 读取实际 restart 目录，调用 GNU 案例对应源码中的官方 `comparebfb.csh`，比较第 5 天的最终 restart：

```bash
(
set -o pipefail
csh -f <<'CSH' 2>&1 | tee gx3_5day_gnu/evidence/gnu_intel_bfb.log
source ./gx3_5day_gnu/cice.settings
set gnu_restart = "${ICE_RSTDIR}/iced.2005-01-06-00000.nc"
set compare_script = "${ICE_SCRIPTS}/tests/comparebfb.csh"
source ./gx3_5day_intel/cice.settings
set intel_restart = "${ICE_RSTDIR}/iced.2005-01-06-00000.nc"
if (! -f "$gnu_restart" || ! -f "$intel_restart") then
    echo "Missing final restart; check both runs before comparing."
    echo "GNU: $gnu_restart"
    echo "Intel: $intel_restart"
    exit 2
endif
if (! -f "$compare_script") then
    echo "Missing official comparison script: $compare_script"
    exit 9
endif
csh "$compare_script" "$gnu_restart" "$intel_restart"
set bfb_status = $status
echo "Official comparebfb exit code: $bfb_status"
exit $bfb_status
CSH
)
```

结果同时显示在终端，并保存为 `gx3_5day_gnu/evidence/gnu_intel_bfb.log`，之后随 GNU 的 `evidence/` 一起下载。重复执行会覆盖这份比较日志。

- `compare OK`，返回码 `0`：两个最终 restart 文件逐字节完全一致。
- `compare FAIL`，返回码 `1`：文件不完全一致。仍然下载两端结果，在本地用变量比较脚本分析差异；不能仅据此判定物理结果错误，也不能直接认定差异一定来自舍入误差。
- 返回码 `2`：缺少输入文件；返回码 `9`：脚本或调用错误。这两种情况需先解决，不能当作非 BFB 结果。

这一步只检查最终 restart 文件的 BFB，不比较日志，也不设置浮点容差。NetCDF 元数据或文件编码差异也可能导致文件比较失败，即使变量数值相同。

## 6. 本地：运行 JAX

切回本地，在已有 JAX 环境中，从本地 `CICE-JAX` 根目录执行：

```bash
python cases/gx3_5day/run.py
```

本地输入数据默认在相邻 `CICE/input/CICE_data/`，文件内容需与服务器 Fortran 使用的数据一致。可直接重复运行：复用已有 `history/`、`restart/` 目录，写出时覆盖同名结果文件，不因已有输出而停止，也不自动清空目录。每次创建独立的时间戳日志 `cice.runlog.YYYYMMDD-HHMMSS-ffffff`，其中最后六位为微秒，启动时会打印本次日志路径。日志记录 JAX/jaxlib、设备、x64、环境选项和本次 namelist；同时保留本次 JAX 源码版本。入口关闭旧诊断回填开关。

输出在 `cases/gx3_5day/` 的 `history/`、`restart/` 和 `cice.runlog.<时间戳>`。同样确认本次日志的成功标志、120 步和最终 restart。

时间循环中，history 字段计算、累积、平均和清零使用 JAX 设备数组；不再为 history 每步下载整套 `ice_state`、`ice_flux`、`ice_flux_bgc`、`ice_arrays_column`。累积更新使用 JIT，字段提取仍由 Python 调用 JAX 运算。正常日志回传归约结果，BGC/卤水日志只读取诊断点；history 写文件时回传相应字段，restart 写文件时才同步所需模块。forcing 文件读取仍在 CPU，JRA55 冰浓度相关气温修正、SST/BGC 恢复及下一步通量清零在设备上完成。首次调用仍有编译成本，不能用第一步耗时代表稳定步耗时。

运行入口默认在第 1–7 步输出详细物理分段计时，第 8 步起只同步测量整个 physics 阶段，直接查看本次 `cice.runlog.<时间戳>` 中的 `TIMING` 行。forcing、诊断、history 和 restart 的计时保留。

- `TIMING_SUMMARY` 按耗时降序列出物理计算、状态检查、诊断、history、restart 和 forcing。百分比以所统计顶层阶段的耗时总和为分母。
- `TIMING_WALL` 记录从步开始到汇总输出前的实际墙钟时间，加上本步消费的 forcing 耗时；包含阶段间日志和宿主工作，但不含之后的计时汇总打印及 profiler 导出。`detailed_physics` 标明是否启用物理子阶段同步。
- `TIMING_DETAIL` 列出子阶段。`physics.therm1`、`physics.therm2` 分别对应两段热力学，`physics.horizontal.momentum` 对应动量求解，`physics.horizontal.transport` 对应水平输运，`physics.ridge` 对应脊化，`physics.radiation` 对应辐射。
- 诊断分为 `diagnostics.compute_gpu`、`diagnostics.d2h` 和 `diagnostics.log_points`。可选 BGC/卤水点诊断的零散回传包含在 `log_points` 中。
- history 分为 `history.accumulate_gpu`、`history.reset_gpu` 和 `history.write`。写出时进一步列出 `history.write.prepare_gpu`、`history.write.d2h` 和 `history.write.io_metadata`，最后一项由写出总时间扣除准备及回传时间得到，包含 NetCDF 元数据处理、写入和关闭文件。
- restart 写出时记录 `restart.d2h_host_copy` 和 `restart.io`。`TIMING_TRANSFER` 汇总状态检查、诊断、history、restart 的显式回传耗时，包含主机端数组复制或精度转换，该数值已包含在各父阶段中。
- forcing 分为 `forcing.cpu_read` 和 `forcing.upload_prepare_gpu`，分别包括 CPU 文件读取与插值，以及上传输入和设备端准备。forcing 计入使用这些输入的时间步，第一步的 forcing 在初始化中完成。原有 `Time step ... seconds` 行的计时范围仍标注为物理计算到 restart，包含 forcing 的统计请看 `TIMING_SUMMARY`。
- `TIMING_HOTSPOT` 显示耗时最大的子阶段。名称以 `.other` 结尾时，表示父阶段扣除已计时子阶段后的剩余开销。

被计时的 GPU 阶段结束时等待结果完成，history 累积数组也单独同步。`seconds` 包含 CPU 调度、编译和等待时间，`sync_seconds` 是其中的同步等待部分。带点号的子阶段已包含在父阶段中，多次动力子循环和多个输出流按同名阶段累计。首次编译会计入首次调用所在阶段，评估稳定耗时请同时观察后续几步。分段同步会限制阶段间的异步重叠，这组计时用于定位瓶颈。

`DETAILED_PHYSICS_STEPS = tuple(range(1, 8))` 控制哪些步启用物理细分计时；设为 `None` 可恢复每步详细计时，设为 `()` 则关闭全部物理细分计时。第 8 步起省去 `physics.*` 的同步等待、`TIMING_BEGIN` 和物理进度刷新，但仍执行相同的分阶段 `vmap` 物理路径，不通过 `timing=None` 切换实现。错误检查和正常科学诊断继续执行，整个 physics 完成后仍同步，因此不会把未完成的计算漏出总计时。

`therm1`、`therm2` 和 `ridge` 都进一步记录 `.prepare`、`.columns`、`.writeback`，分别表示输入整理、批量柱计算、结果回填。柱计算还有以下细项。

- `physics.therm2.columns.itd` 为厚度类别重分配，`.new_ice` 为新冰生成，`.lateral_melt` 为侧融，`.cleanup` 为冰厚分布整理。启用相应配置时，还记录 `.fsd_weld` 和单类别模式下的 `.reduce_area`。
- `physics.ridge.columns.iteration` 为脊化主迭代，`.cleanup` 为随后调用的冰厚分布整理，可以与 therm2 的 cleanup 对照。
- `physics.therm1.columns` 测量完整的批量柱计算。内部大气边界层与垂直热力学求解仍合并在这一项中。

therm1 的切片、示踪物转换、展平已合并到 `_therm1_prepare`，ridge 的海洋掩膜和回写已合并到 `_ridge_writeback`，各自通过固定 JIT 边界执行。
比较 `physics.therm1.prepare`、`physics.ridge.writeback` 与整步耗时，首次调用仍包含编译。
原有示踪物布局、ridge 的 `tmask` 掩膜、错误标志及 `hin_max` 末项更新保留。大气调试回放在准备完成后处理。

radiation 的太阳高度计算、输入整理、批量求解和掩膜回写放入 `_step_radiation_compiled`，coupling 的混合层更新、类别加权和通量缩放放入 `_coupling_prep_compiled`。
时间步长、日序、日内秒数和输入场为动态参数，布局和方案开关为静态配置。比较 `physics.radiation`、`physics.coupling`、整步耗时及首次调用的编译成本。
现有掩膜、类别累加次序和物理公式保留，但扩大 JIT 范围可能改变浮点融合，数值一致性需要重新比较。

物理步的质量诊断初值、热力/BGC 诊断清零、初始状态快照和风场插值合并到 `_physics_prepare_compiled`。
辐射准备的切片、短波缩放和回写合并到 `_prep_radiation_compiled`，ridge 输入切片与展平合并到 `_ridge_prepare`。
边界恢复、调试输出及同步计时仍在这些编译边界外；ridge 迭代与 cleanup 沿用原有计算路径。
准备阶段优化比较 `physics.prepare`、`physics.prepare_radiation`、`physics.ridge.prepare` 和整步耗时。
参考运行 `cice.runlog.20261104-142519-941928` 第 8–119 步的平均值分别约为 0.089、0.083、0.036 和 1.700 秒。
运行至至少第 12 步可检查采样结束后的速度和第 5–10 步 GPU 采样；完成 120 步后再运行 `compare_all.py`，以 GNU、Intel 为数值参照。
首次调用包含新增编译成本，提速及数值变化需以新日志和比较报告确认。

水平应力的冰面积归一化、U 网格边界填充和 U→T 插值合并到 `_horizontal_stress_compiled`。
热力、动力及可选雪过程后的类别边界填充、状态汇总和变化率计算合并到 `_update_state_compiled`。
网格边界规则、类别累加顺序和冰龄变化率分支沿用原有逻辑；时间步长和冰龄偏移量作为动态输入。
应力和状态更新优化用于减少 CPU 逐项派发造成的 GPU 空闲，重点检查时间线中的 `_horizontal_stress_compiled` 和 `update_state`，以及原有同步阶段计时。
参考运行 `cice.runlog.20261104-154410-202631` 第 8–119 步，`physics.horizontal.stress`、`physics.update_thermo`、`physics.update_dynamics` 平均约为 0.071、0.044、0.044 秒，整步为 1.442 秒。
比较 GPU 活动时间占比和整步耗时，并在完整运行后用 `compare_all.py` 检查对 Fortran 的误差；更大的 JIT 范围可能改变浮点融合，不能仅凭提速判断数值验证通过。

启用详细计时时，therm2 和 ridge 在各子阶段分别进行 `vmap`，然后在宿主端等待结果完成。每个子阶段仍调用原有的单柱物理函数，计时边界会影响追踪、编译和执行重叠，因此绝对耗时可能与此前日志不同。`TIMING_BEGIN` 在子阶段开始时立即写出，随后对应的 `TIMING` 行记录完成耗时。用同一版本连续运行后的几步判断主要瓶颈。

`run.py` 设置 `CLEANUP_CATEGORY_UNROLL = 5`，用于 therm2、ridge 共用的 cleanup 内核。
残余类别移除、超额面积修正和异常雪层移除的三个 `lax.fori_loop` 按原顺序编译展开，每组仍执行全部类别；gx3 的 5 个类别完全展开。重分箱算法、物理阈值、通量收支公式和错误标志保留。
这允许编译器优化短循环中的索引和数组回写，目标是减少内核启动和间隙；不是每步在 Python 中执行五次循环，也不减少迭代次数。展开可能增加编译时间和寄存器压力，是否有益需看采样和墙钟耗时。
将该值改为 `1` 并重新运行可恢复原有循环形式，同时保留低同步模式。此设置在初始化前传入模块，并显式进入 cleanup 的 JIT 缓存键。
参考运行 `cice.runlog.20261104-164834-846752`：第 5–7 步 therm2 cleanup 平均约 0.058 秒、ridge cleanup 约 0.067 秒；第 11–119 步整步汇总约 1.167 秒，`TIMING_WALL` 约 1.170 秒。
本轮比较相同步数的 cleanup 耗时、GPU 内核数量和活动时间，以及低同步模式的整步耗时。完成 120 步后继续用 `compare_all.py` 检查对 GNU、Intel 的误差，编译展开后的浮点结果需要实际验证。

`REBIN_STATIC_TRACERS = True` 使 cleanup 重分箱后的示踪物恢复按固定布局编译展开。
示踪物类型和父示踪物索引在追踪时确定，按原示踪物顺序恢复，后续示踪物仍读取已经恢复的父示踪物。面积、冰体积、雪体积的归一化次序及缺冰/缺雪默认值保留。
展开位于 JIT 内，不会在每个时间步由 Python 逐个派发；目标是消除动态示踪物循环中的索引和分支，降低 GPU 内核数量。普通 ITD 部分搬移继续使用原路径，本轮只启用 cleanup 的重分箱路径。
将 `REBIN_STATIC_TRACERS` 改为 `False` 并重新运行，可单独回退此项，保留五类别循环展开和低同步模式。开关显式进入 cleanup 的 JIT 缓存键；编译成本、显存及浮点结果需随性能一起检查。
参考运行 `cice.runlog.20261104-172934-880409`：第 5–7 步 therm2/ridge cleanup 平均约 0.050/0.055 秒，单次计算内核事件约 1691/1695；第 11–119 步整步汇总约 1.047 秒，墙钟约 1.049 秒。低同步采样步 physics 的 GPU 活动占比约 61%–64%，该比例不是 SM 占用率。

本轮设置 `THERM2_BATCH_JIT = True`，将 therm2 的类别重分配、新冰生成、侧融、可选 FSD 过程、cleanup 及中间状态整理纳入 `_therm2_columns_compiled`，一次调用推进整批柱。
第 1 步即使用该路径，之后复用编译结果。所有状态、错误标志及分阶段面积诊断仍返回；布局、方案和 cleanup 调优开关显式进入静态配置，步长及物理数组保持动态。
启用时保留 `physics.therm2.columns` 的完整同步计时，不再输出其内部 `.itd/.new_ice/.lateral_melt/.cleanup` 子阶段计时；该变化不影响 ridge 的细分计时。时间线增加 `_therm2_columns_compiled` 标记。
将 `THERM2_BATCH_JIT = False` 并重新运行可恢复分阶段路径，保持其他开关不变，作为同配置 A/B。参考运行 `cice.runlog.20261104-201714-426147` 第 11–119 步汇总约 1.086 秒，墙钟约 1.089 秒。

WSL `tianji310_cuda` 直接运行的 `cice.runlog.20261104-211121-437862` 已完成 120 步，总用时 822.82 秒。第 11–119 步墙钟平均 0.962 秒，较上述参考运行减少约 11.6%；第 5–7 步 therm2 柱计算平均从 0.207 秒降至 0.038 秒。首次 physics 调用含编译为 474.18 秒，最终 history 写出约 108.21 秒、restart 写出及传输约 26.56 秒，均不计入稳定步均值。由于此前运行可能经过调试器，这些跨运行结果尚不能替代同一启动方式下的受控 A/B。

本次 profile 第 8–10 步 physics 区间的 GPU 设备事件时间并集占比约 70%–75%，不是 SM 占用率或 `nvidia-smi` 利用率。采样文件位于该运行的 `profiles/` 子目录，包括 `gpu_monitor.csv`。`comparison_logs/20261104-212633-565809/` 中 GNU–JAX、Intel–JAX 各 54 项变量的对比指标与上一轮报告一致；这表示已报告指标未退化，不代表 JAX 与 Fortran 逐位一致，也不替代长期验证。

`RIDGE_BATCH_JIT = True` 将 ridge 的脊化迭代、cleanup 和中间状态整理合并到 `_ridge_columns_compiled`，对全部物理柱执行一次批量 JIT 调用。类别布局、方案和 cleanup 调优开关进入静态缓存键；步长、动力子步数和物理数组保持动态输入。原有迭代上限、收敛判断、错误标志及海洋掩膜回写保留。
启用时记录整个 `physics.ridge.columns`，不再单独记录 `.iteration/.cleanup`；设为 `False` 可恢复分阶段路径，用于同启动方式的 A/B。

`RIDGE_BATCH_STOP = True` 在批量 JIT 路径中启用整批收敛保护。通过命名 `vmap` 轴上的 `lax.pmax`，在 GPU 上判断是否仍有柱需要迭代。整批收敛后，剩余 `fori_loop` 轮次直接返回已有状态。逐柱收敛掩膜、20 次迭代上限及错误检查继续生效，固定循环结构支持反向模式自动微分。将该开关设为 `False` 可单独关闭整批保护进行对照。

2026-11-05 的前两次运行在第 3 步 `prep_radiation` 调用中遇到 `libcuda.so` 段错误。本机环境为 WSL、驱动 610.88、JAX/jaxlib 0.6.2。使用实际初始化状态、更新设备缓冲区并单独重复调用辐射准备，第二次调用即复现故障，测试中尚未执行 ridge。局部关闭该函数的 command buffer 后，相同测试完成了 10 次调用，但第三次完整运行又在 therm2 回写中崩溃。

该轮验证使用 `DISABLE_CUDA_COMMAND_BUFFER = True`，在 JAX 后端初始化前添加 `--xla_gpu_enable_command_buffer=`，完成了全局关闭 command buffer 的兼容对照。入口日志记录开关及完整 `XLA_FLAGS`，跨此设置比较历史运行耗时需要注明执行配置差异。

当前入口恢复 `DISABLE_CUDA_COMMAND_BUFFER = False`。辐射准备只向编译函数传入必要字段，therm2 回写、短波主计算、耦合、B-grid EVP 和水平应力插值只返回实际更新的数组，在宿主端合并状态字典。零长度数组的空更新由外层保留原数组。辐射准备、therm2、耦合和完整水平动力与输运路径通过了默认 command buffer 下的重复调用检查。短波主计算仍可单独复现图重放崩溃，因此仅 `_step_radiation_compiled` 使用局部 `compiler_options={"xla_gpu_enable_command_buffer": ""}`，入口日志也记录此设置。全局开关保留用于兼容回退。

验证运行 `cice.runlog.20261104-213210-242681` 同样由 WSL `tianji310_cuda` 直接启动，完成 120 步，总用时 812.70 秒。相对上一轮，第 11–119 步墙钟均值由 0.9623 降至 0.9024 秒（约 6.2%），中位数由 0.9286 降至 0.8785 秒；physics 均值由 0.8202 降至 0.7722 秒。第 5–7 步 ridge 柱计算均值由 0.2964 降至 0.2679 秒，但首次 ridge 调用含编译从 74.59 增至 86.61 秒。这是一组单次运行对照，仍需重复测量判断稳定收益。

本轮第 8–10 步 physics 的 GPU 设备活动占比为 67.6%–73.1%，未显示明显提升；采样没有负时长事件。`profiles/` 中各运行的 `profile_summary.json` 保存设备活动时间并集摘要，`gpu_monitor.csv` 保存实际 `nvidia-smi` 采样。当前保留本轮优化，下一候选为检查 ridge 在 `vmap` 下逐柱收敛后仍执行的固定迭代，验证整批收敛保护能否避免冗余计算。

`comparison_logs/20261104-214602-533754/` 的 GNU–JAX、Intel–JAX 各 54 项变量指标，以及 restart/history 对比报告，均与上一轮一致；当前 history 对比仅覆盖初始文件。最终 history 写出约 102.55 秒，restart 写出及传输约 22.73 秒。清理旧日志和采样释放约 1.16 GiB，目前保留三轮日志、profile 和比较报告。

### Ridge 收敛保护与 command buffer 验证

上一轮验证运行 `cice.runlog.20261105-104033-153286` 在关闭 command buffer、启用 ridge 整批收敛保护的配置下完成了 120 步，总用时 874.65 秒，其中包含第 4 次 ridge 调用的额外对照编译和测量。对照使用同一份输入状态，预热两条路径后交替测量 8 组，全部结果完成 GPU 同步后计时。柱计算中位耗时从关闭保护的 0.29730 秒降至开启保护的 0.04462 秒，减少约 85.0%，两条路径输出数组逐项相等。测量记录位于该运行 profile 目录中的 `ridge_ab.json`。

第 11–119 步墙钟均值为 0.97596 秒、中位数为 0.96603 秒，上一轮分别为 0.90237、0.87850 秒。本次整步均值增加约 8.2%，执行配置同时改变了 command buffer 设置，因此整体性能变化需要进一步受控测量。第 5–7 步 therm1 平均约 0.314 秒、水平动力与输运约 0.272 秒、ridge 约 0.099 秒。下一步优先定位 command buffer 的兼容触发条件，评估按函数缩小兼容处理范围，并检查 therm1 与水平动力的设备等待和调度开销。

第 11–119 步对应 97 个 `nvidia-smi` 样本，GPU 利用率平均约 52.0%，范围 5%–88%，平均功率约 107.7 W。这些样本按读取日志时的时间步近似归属。第 8–10 步 profiler 的 physics 设备活动占比约 49%–57%，采样无负时长事件。两种统计分别记录设备监控读数和时间线事件覆盖率。

`comparison_logs/20261105-105442-591348/` 中 GNU–JAX、Intel–JAX 各 54 项指标，以及 restart/history 报告，与上一轮完全一致。最终 history 写出约 111.95 秒，restart 写出及传输约 22.77 秒。崩溃复现和兼容测试证据归档在本轮 profile 的 `cuda_replay_diagnostic/` 中。已清理 9 项旧产物，释放约 120.4 MiB，目前保留三轮完整运行的日志、profile 和比较报告。

验证运行 `cice.runlog.20261105-114116-871948` 恢复默认 command buffer，仅短波主计算局部关闭，完成 120 步，总用时 802.60 秒。第 11–119 步墙钟均值从上一轮的 0.97596 降至 0.68488 秒，减少约 29.8%，中位数从 0.96603 降至 0.67005 秒。physics 均值从 0.83802 降至 0.55847 秒，减少约 33.4%。这是精简 JIT 返回值和恢复 command buffer 的组合改动单次运行对照，各项独立收益与稳定性还需受控重复测量。首次 physics 调用含编译约 481.86 秒，最终 history 写出约 113.86 秒，restart 阶段约 25.68 秒。

最新运行第 11–119 步对应 69 个 GPU 监控样本，利用率均值 67.5%，范围 32%–93%，平均功率 115.9 W，监控显存均值约 7757 MiB。相同区间上一轮利用率均值 52.0%。第 8–10 步 profiler 的 physics 设备活动占比为 69.3%、73.5%、67.7%，采样无负时长事件，每步仍有约 200 次 D2H 事件。第 5–7 步详细计时中，therm1 平均 0.252 秒、水平动力与输运 0.135 秒、短波计算 0.109 秒。下一轮优先分析 therm1 的迭代控制同步和短波计算的调用边界，继续定位 GPU 空闲间隙。

`comparison_logs/20261105-115351-525323/` 的 GNU–JAX、Intel–JAX 各 54 项指标，以及 restart/history 报告，与上一轮一致。所有 restart 变量均完成比较，未掩膜位置的 NaN/Inf 数量和缺测掩膜差异均为零。GNU–JAX 的 `iceumask` 仍有原先的一个格点值差异，Intel–JAX 该变量精确相等。history 对比覆盖初始文件的 5 个核心变量，三组均精确相等。长期数值验证仍需后续一年试验。

本轮默认 command buffer 的重复调用探针及一次 EVP 崩溃记录保存在最新 profile 的 `cuda_replay_diagnostic/` 中。随后精简 EVP 与应力插值返回值，完整水平动力与输运通过 5 次独立调用，并通过上述完整 120 步运行。已删除临时初始化状态快照、冗余失败产物和最旧一轮产物，共清理约 239.0 MiB，保留最近三轮完整运行的日志、采样和比较报告。

### Therm1 三对角求解器优化

`tdma_solve_sparse` 的前消元和回代使用静态标量列表保存递推结果，最后一次 `stack` 生成层数组，减少中间层数组的反复 scatter 和 slice。每项递推按右端项数组的数据类型转换，沿用已有求解顺序。Python 循环在追踪时展开，执行发生在编译后的 GPU 程序中。

最新运行 `cice.runlog.20261105-141630-458390` 完成 120 步，总用时 670.02 秒。第 11–119 步墙钟均值从 0.68488 降至 0.59941 秒，减少约 12.5%，中位数从 0.67005 降至 0.58453 秒。physics 均值从 0.55847 降至 0.45416 秒，减少约 18.7%。第 5–7 步 therm1 柱计算均值从 0.22433 降至 0.09963 秒，减少约 55.6%。首步 therm1 含编译约 136.63 秒，上一轮约 240.00 秒。这是相同案例配置的单次整段运行对照，仍需后续运行估计波动。最终 history 写出约 117.99 秒，restart 阶段约 27.21 秒。

本轮第 11–119 步的 60 个 GPU 样本利用率均值为 57.9%，范围 5%–82%，平均功率 110.1 W，监控显存均值约 7766 MiB。上一轮利用率均值为 67.5%。第 8–10 步 physics 的 profiler 设备活动占比为 64.7%、68.5%、64.1%。同一组采样步 GPU 活动时间均值从约 0.458 秒降至 0.321 秒，physics 墙钟从约 0.653 秒降至 0.489 秒，空闲时间从约 0.195 秒降至 0.167 秒。设备计算时间缩短更多，因此活动占比下降。本轮获得整步提速，持续提高利用率仍需进一步压缩等待间隙。

时间线仍记录每步约 200–207 次 D2H 事件，其中第 5–7 步 therm1 各有 70、75、72 次。下一轮优先检查批量收敛控制的同步，以及状态准备和回写的调用开销，并针对同一输入做受控 A/B。`profile_summary.json`、`phase_summary.json`、`performance_comparison.json` 和 `gpu_monitor.csv` 保存在本轮 profile 目录。

独立 GPU 求解器对照使用固定随机种子 4521、每组 11600 个严格对角占优系统，覆盖 1、2、7、8、9、16 层。每个尺寸预热后交替计时 20 组，结果保存在 `tdma_microbenchmark.json`。双精度输出在该测试中逐项相等，最大方程残差约 `1.1e-15`，梯度通过转置线性系统的独立参考检查。纯单精度及两种混合精度通过按机器精度设置的归一化残差检查。双精度系数配单精度右端项时，两种实现最大差异约 `1.19e-7`。这些检查针对独立构造的线性系统，完整模式的科学验收以 Fortran 对照和长期试验为依据。

`comparison_logs/20261105-142705-067939/` 中 GNU–JAX、Intel–JAX 各 54 项指标与上一轮逐项相等，restart/history 报告内容相同。所有 restart 变量均完成比较，缺测掩膜差异及未掩膜位置的 NaN/Inf 数量均为零。GNU–JAX 的 `iceumask` 有既有的一个格点值差异，Intel–JAX 该变量精确相等。history 只覆盖初始化文件。短波计算继续使用局部关闭 command buffer 的兼容设置。

本轮清理临时求解器副本和最旧一轮产物约 112.4 MiB，保留最近三轮完整日志、profile 和比较报告。

### 本地性能优化的结束条件

每轮自动运行与比较后，清理本案例根目录的旧时间戳 `cice.runlog.*`、`profiles/` 和 `comparison_logs/`，通常保留当前轮及最近两轮所需的对照证据。仍用于受控对比或定位数值问题的结果另行保留。Fortran 参考目录、输入文件和当前 history/restart 不属于这类清理对象。较早运行的统计摘要保留在本文中，原始采样可能已清理。

本阶段针对 RTX 3060 Ti 上的 gx3 短期试验。保留优化需通过主要变量的 Fortran 对照和约定的 QC；不以辅助数组逐位一致作为统一要求，也不将编译器间差异直接当作验收阈值。
性能比较使用相同配置、相同计时模式和第 11–119 步，排除编译、采样及最终集中输出；候选开关做单变量 A/B，并用重复运行估计波动，同时记录首次编译、显存和输出成本。
在主要耗时阶段与 GPU 空闲来源已完成检查后，连续三轮有针对性的受控 A/B 都无法取得超过运行波动且至少约 3% 的稳定整步提速，则结束本地优化并保留最佳已验证配置。3% 是本项目的性能停止线，不是 CICE 官方标准或数值误差阈值。
若性能受 gx3 工作量、FP64 吞吐、内存带宽或必需的 I/O 限制，应以 profiler 和受控测量记录依据，不能仅凭低利用率推断。100% 的 `nvidia-smi` 读数不是完成条件。
收尾时固定代码、配置、对照报告和性能基线；服务器上的 gx3/gx1 一年试验负责长期数值验证，并按服务器硬件另行评估性能。

### GPU 时间线采样

本次性能排查在 `run.py` 中设置 `PROFILE_GPU = True`、`PROFILE_STEPS = (5, 10)`。
直接运行该入口，会在第 5 步开始时启动 JAX profiler，第 10 步结束后导出时间线，模型随后继续运行。第 5–7 步保留物理细分同步，第 8–10 步使用低同步模式；两组处于不同模拟时刻，仅用于初步判断同步开销。同一组步数的严格 A/B 可将 `DETAILED_PHYSICS_STEPS` 设为 `None` 再运行对照。
将 `PROFILE_GPU` 设为 `False` 可关闭采样。

输出保存在案例目录的 `profiles/cice.runlog.<本次时间戳>/` 下，包含 JAX profiler 原始数据和 `perfetto_trace.json.gz`。
日志出现 `PROFILE saved directory=...` 表示导出完成，此后可以结束本次性能排查运行。
后续分析需要保留整个采样目录以及同名时间戳的运行日志。

时间线标记包括 `physics_step`、`_physics_prepare_compiled`、`prep_radiation`、`step_therm1`、`_therm1_prepare`、`icepack_step_therm1_batch`、`_therm1_writeback`、`_ridge_prepare`、`_ridge_writeback`、
`physics.therm2.columns.itd`、`physics.horizontal.momentum`、`_horizontal_stress_compiled`、`update_state`、`step_radiation` 和 `coupling_prep`。
采样覆盖第 5–10 步的计算和输出，以及第 6–10 步的 forcing 准备。第 5 步的 forcing 在启动采样前已经完成。
`physics_step` 时间线范围包含整个 physics 的最终同步；低同步模式的子函数标记只表示宿主调用范围，不能用它们直接计算子阶段的完整 GPU 活动比例。profiler 本身会增加开销，评价稳定速度时使用第 11 步以后的时间步，并排除最终集中输出步。

### Picard 收敛次数统计

`run.py` 当前设置 `PROFILE_PICARD = False`，关闭上一轮收敛次数统计。
需要再次采样时改为 `True`，在 `PROFILE_STEPS` 范围内输出 `PICARD_STATS`。
统计按冰厚类别 `category=1..5` 分开，`attempt=first` 是首次求解，`attempt=retry` 是切换冷表面/融化表面条件后的第二次求解。
只统计有效海洋格点中实际进入热力学求解的冰类别，未触发的重试不计入。

- `columns` 是该类别、该次求解的柱数，`mean_iterations`、`p50`、`p95` 和 `max` 是到收敛或达到上限时的迭代次数。
- `reached_100` 包括恰好在第 100 次收敛和仍未收敛的柱，`unconverged` 仅指 Picard 热量收敛条件未满足，不包含后续盐度或表面条件一致性检查。
- `histogram` 的每项为 `迭代次数:柱数`。这些计数代表所选物理分支的实际需求，不是 GPU 内核执行次数。`vmap` 下未选中的分支仍可能执行计算。

每步在 GPU 上生成直方图，仅在 `PROFILE_STEPS` 指定范围内回传并记录汇总，gx3 每个采样步约 4 KiB。
`physics.therm1.picard_stats_gpu` 和 `physics.therm1.picard_stats_d2h` 分别记录汇总和回传耗时，均包含在 therm1 总耗时中。
计数开关在整次运行中保持固定，避免进入采样区间时重新编译 therm1。首次编译和计数本身会影响耗时。
将 `PROFILE_PICARD = False` 可完全关闭计数，与 `PROFILE_GPU` 独立。

### Picard 批量收敛控制

`run.py` 当前设置 `PICARD_BATCH_STOP = True`，采用 `4+12x8` 分块迭代。每个冰厚类别、每种表面求解分支在 GPU 上归约是否还有需要该分支且未收敛的柱。
掩膜包括有效海洋格点、有冰类别、雪层条件、冷/融化表面条件及是否需要重试。
先检查该分支是否有有效柱，没有则跳过 Picard 迭代。有有效柱时先执行 4 次，之后整批已收敛就跳过剩余 96 次。
仍有未收敛柱时，进入 12 个块，每块最多执行 8 次，在块开始时检查是否还需要计算。
每一次迭代仍检查逐柱收敛，已收敛柱立即冻结状态。块内可以继续执行被掩膜的计算，但不会继续更新已收敛柱。

总上限仍为 100 次，所有 `lax.fori_loop` 的循环边界都是静态常数，保留原收敛阈值和反向自动微分的控制流结构。
批量条件通过命名 `vmap` 轴上的 `lax.pmax` 归约，避免条件本身再次按格点展开为逐元素选择。
此前逐次判断版本的 profiler 显示，XLA 会为条件分支回传 4 字节标量，therm1 每步约 4,000 次，并非没有 CPU 等待。
分块版本每个分支最多进行 14 次批量判断（进入分支 1 次、前 4 次后 1 次、后续块 12 次），前 4 次内全部收敛时仅需 2 次，没有有效柱时仅需 1 次。
这减少条件判断的执行次数，但实际 D2H 数量及同步开销仍需用新的 profiler 确认。
该路径的实际加速、数值一致性及梯度仍需运行验证。

需要单独评估 Picard 柱计算时启用相应步的详细物理计时，并比较 `physics.therm1.columns`；低同步模式只报告整个 physics 的同步耗时。
默认不再输出 `PICARD_STATS`。首次编译可能较慢，无需为性能排查等待第 120 步文件输出。
如需隔离批量控制的效果，另一次运行将 `PICARD_BATCH_STOP = False`，两次均保持 `PROFILE_PICARD = False` 以及相同的 `PROFILE_GPU` 设置。
关闭批量控制会恢复原 Picard 循环路径，therm2 的准备和回写优化仍保留。

## 7. 下载 Fortran 结果，在本地比较

将服务器 GNU 和 Intel 各自本次结果下载到本地 `CICE-JAX` 项目中的 `cases/gx3_5day/gnu/` 和 `cases/gx3_5day/intel/`：

- `ICE_RUNDIR/restart/` → `restart/`；`ICE_RUNDIR/history/` → `history/`。
- 本次运行日志保留时间戳文件名 → 对应目录根部或 `logs/`；兼容旧的无时间戳 `cice.runlog`。
- 本次构建/调度日志 → `logs/`；服务器案例的 `evidence/` → `evidence/`。

三端结果都在本地收齐后，在本地 JAX 环境中，从 `CICE-JAX` 项目根目录执行：

```bash
python cases/gx3_5day/compare_all.py
```

依赖当前环境中的 `netCDF4` 和 `numpy`。每端按文件名排序选择最新的时间戳日志；没有时间戳日志时才读取根目录旧 `cice.runlog`。保留原来的时间戳命名，不给日志追加其他后缀。脚本打印选用的日志路径，先检查最新运行完成和 restart 时间属性，随后比较 GNU–Intel、GNU–JAX、Intel–JAX 的最终 restart 全部变量，报告写入带时间戳的 `comparison_logs/`。最新日志未完成时会停止，不回退到以前成功的日志。

最终 restart 的三组结果同时汇总到 `restart.log`，先展示核心状态变量，再展示次要变量，每组附中文结论。日志中的 `relative_l2_pct` 使用百分比，CSV 中的 `relative_l2_to_left` 使用原始比值。

报告包含缺失变量、维度、数据类型、缺测掩膜差异、非有限值数量、有限值不相等数量、最大绝对差、RMSE、相对 L2 误差（分母为左端变量 L2 范数）。缺测和非有限位置不进入浮点指标，但单独计数，不能忽略。整数及掩膜检查精确相等；浮点变量**不设置人为 PASS/FAIL 阈值**。`EXACT` 仅表示可比较位置数值完全相同且无掩膜差异/非有限值，不代表科学验证通过；`DIFFERENCES` 表示存在需分析的差异。脚本正常结束只说明报告生成完成。

脚本还按同名文件比较三端 `history/*.nc`，只检查核心变量 `aice/aicen`、`hi/vicen`、`hs/vsnon`、`uvel`、`vvel`，三组结果汇总到同一输出目录的 `history.log`。各变量按实际名称分别比较，文件中未输出的名称会注明；缺失文件、时间坐标或单位不一致也会记录。日志列出最大绝对差、RMSE、相对 L2 误差、缺测掩膜差异及非有限值数量。`iceh_ic` 文件用于核对初始化，逐步日志用于观察差异出现的时间。先看 GNU–Intel 差异，再评估两组 JAX 差异；GNU–Intel 的误差规模是经验参照，不能单独当作科学验收标准。

只比较已有 history 时，运行 `python cases/gx3_5day/compare_all.py --history-only`，只生成 `history.log`。此模式允许在最终运行完成前核对已写出的初始 history。

一年 gx3/gx1 阶段另外在服务器建立；此目录仅定义当前五天验证。
