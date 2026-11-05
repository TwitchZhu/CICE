# Fortran 与 JAX 五步试验操作步骤

本目录原名 `gx3_5step`，现改为 `gx3_5step_simple`。它仍是关闭输运和冰脊的五步（五小时）诊断案例；已有日志、结果和 evidence 保留原始内容，其中的旧服务器路径不改写。新的官方配置五天案例位于 `../gx3_5day/`。

## 1. 上传文件

上传本地文件：

`E:\Code\CICE-JAX\cases\gx3_5step_simple\prepare_fortran_case.sh`

到服务器：

`cice-dirs/cases/gx3_5step_simple/prepare_fortran_case.sh`

将本地目录 `E:\Code\CICE-JAX\cases\gx3_5step_simple\fortran_pond_debug\` 中以下 **9 个文件**，上传到服务器 `cice-dirs/cases/gx3_5step_simple/fortran_pond_debug/`：

- `ice_in`
- `CICE_RunMod.F90`
- `ice_diagnostics.F90`
- `ice_step_mod.F90`
- `ice_step_snapshot.F90`
- `icepack_atmo.F90`
- `icepack_orbital.F90`
- `icepack_therm_mushy.F90`
- `icepack_therm_vertical.F90`

## 2. 创建 GNU、Intel case

在服务器 **Bash** 中进入现有 `cice-dirs/cases/` 目录，执行：

```bash
bash gx3_5step_simple/prepare_fortran_case.sh gx3_1step gx3_5step_simple_gnu
bash gx3_5step_simple/prepare_fortran_case.sh gx3_ifort gx3_5step_simple_intel
```

检查两个新 case 的 `cice.settings`：`ICE_CASEDIR`、`ICE_RUNDIR`、`ICE_OBJDIR`、`ICE_LOGDIR` 分别指向新 case；GNU、Intel 不共用运行或编译目录。保留各自原来的 `env.*`、`Macros.*`、MPI 进程数和浮点编译选项。

检查两个新 case 的 `ice_in`：输入文件路径 `../../../CICE/input/CICE_data/` 必须从各自 `ICE_RUNDIR` 可访问。若服务器目录布局不同，只修正输入路径。

## 3. 安装诊断源码

仍在服务器 `cice-dirs/cases/` 目录执行。下面 `../../CICE` 应对应两个 case 的 `ICE_SANDBOX`；若两个 case 使用不同源码树，对各自源码树分别执行。

```bash
pond_src=../../CICE
pond_files=gx3_5step_simple/fortran_pond_debug
for f in icepack_atmo icepack_orbital icepack_therm_mushy icepack_therm_vertical; do
    cp "$pond_files/$f.F90" "$pond_src/icepack/columnphysics/"
done
cp "$pond_files/ice_step_mod.F90" "$pond_src/cicecore/cicedyn/general/"
cp "$pond_files/ice_diagnostics.F90" "$pond_files/ice_step_snapshot.F90" "$pond_src/cicecore/cicedyn/analysis/"
cp "$pond_files/CICE_RunMod.F90" "$pond_src/cicecore/drivers/standalone/cice/"
```

## 4. 分别编译并提交

先进入 `gx3_5step_simple_gnu/`，执行下面整组命令；完成后回到 `cice-dirs/cases/`，进入 `gx3_5step_simple_intel/` 再执行同一组。

确认 `cice.settings` 中 `ICE_CLEANBUILD=true`，运行目录没有其他轮次输出。

```bash
pond_src=../../../CICE
mkdir -p evidence
cp ice_in cice.settings Macros.* env.* evidence/
(cd "$pond_src" && find cicecore icepack/columnphysics -type f \( -name '*.F90' -o -name '*.h' \) -print0 | sort -z | xargs -0 sha256sum) > evidence/source.sha256
(cd "$pond_src/input/CICE_data" && find ic/gx3 grid/gx3 forcing/gx3 -type f -print0 | sort -z | xargs -0 sha256sum) > evidence/input.sha256
csh -f <<'CSH' > evidence/environment.txt 2>&1
source ./cice.settings
source ./env.${ICE_MACHCOMP}
module list
which mpif90
mpif90 --version
mpif90 -show
mpif90 --showme
nf-config --all
nc-config --all
CSH
csh ./cice.build
```

编译成功后执行：

```bash
csh -f <<'CSH' > evidence/executable.txt 2>&1
source ./cice.settings
sha256sum ${ICE_RUNDIR}/cice
ldd ${ICE_RUNDIR}/cice
CSH
csh ./cice.submit
```

等待两个作业结束，确认各自本次运行日志包含 `CICE COMPLETED SUCCESSFULLY`。

## 5. 下载结果到本地

GNU 下载到：

`E:\Code\CICE-JAX\cases\gx3_5step_simple\gnu\`

Intel 下载到：

`E:\Code\CICE-JAX\cases\gx3_5step_simple\intel\`

两端分别按下面的对应关系下载：

- 服务器新 case 的 `logs/cice.runlog.<本次时间戳>` → 本地对应目录的 `logs/`；若已重命名放在对应目录根部 `cice.runlog`，比较脚本也能读取。
- 服务器新 case 的 `logs/cice.bldlog.<本次时间戳>` → 本地对应目录的 `logs/`。
- 服务器新 case 的本次作业输出 `slurm<作业号>.out` → 本地对应目录的 `logs/`。
- 服务器新 case 的整个 `evidence/` → 本地对应目录的 `evidence/`。
- 服务器 `ICE_RUNDIR/restart/` → 本地对应目录的 `restart/`。
- 服务器 `ICE_RUNDIR/history/` → 本地对应目录的 `history/`，包括初始化 history。
- 服务器 `ICE_RUNDIR/step_entry.00000001.rank*.txt`、配套 `.bin` → 本地对应目录的 `step_entry/` 或目录根部。
- 服务器 `ICE_RUNDIR/step_entry.00000002.rank*.txt`、配套 `.bin` → 与第 1 步放在同一目录，下载全部 rank。

默认运行目录分别为 `cice-dirs/runs/gx3_5step_simple_gnu/`、`cice-dirs/runs/gx3_5step_simple_intel/`；以各自 `cice.settings` 中的 `ICE_RUNDIR` 为准。

检查两端 `restart/` 都有以下五个文件：

```text
iced.2005-01-01-03600.nc
iced.2005-01-01-07200.nc
iced.2005-01-01-10800.nc
iced.2005-01-01-14400.nc
iced.2005-01-01-18000.nc
```

## 6. 运行 JAX 五步模型

以下命令在原 JAX CUDA 环境的 **Bash** 中执行，当前目录为 `CICE-JAX` 项目根目录。
同步当前源码和 `cases/gx3_5step_simple/` 后，执行一次：

```bash
python cases/gx3_5step_simple/run.py
```

等运行结束，确认 `cases/gx3_5step_simple/cice.runlog` 中有 `CICE COMPLETED SUCCESSFULLY`，
并确认 `restart/` 内有第 5 节列出的五个文件。保持三个回填开关为 False。

JAX 自动输出到本 case 的 `restart/`、`history/`、`cice.runlog`，第 1、2 步入口快照在
`comparison_logs/`，每一步都有同名配套的 `.json` 和 `.npz`。
若 JAX 在另一台机器运行，将这些输出下载到本地
`E:\Code\CICE-JAX\cases\gx3_5step_simple\` 的对应位置。

## 7. 收齐三端结果后比较

先把 GNU、Intel 结果放到第 5 节指定位置，确认 JAX 五步运行已完成。
在能访问三端文件的 JAX 环境中，从项目根目录执行一条命令；也可以直接在 PyCharm 中运行此脚本，无需设置工作目录：

```bash
python cases/gx3_5step_simple/compare_all.py
```

脚本会检查三端五步文件，依次生成 15 份 restart 两两比较报告，并从 JAX 运行日志
读取第 1、2 步快照文件名，生成 4 份 JAX–Fortran 入口比较报告。
它能读取 GNU、Intel 各自根目录或 `logs/` 中的运行日志，以及各自根目录或 `step_entry/`
中的 rank 文件。数值差异会记录在报告中，不会中断后续比较。
终端会逐项显示进度、`PASS` 或 `DIFF`、报告路径，并在结束时汇总 19 项完成情况；
缺文件或脚本报错会显示 `ERROR` 和失败步骤。
报告统一写入 `cases/gx3_5step_simple/comparison_logs/`；模型不会重新运行。
