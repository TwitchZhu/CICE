# 基础设施

## 数值种类

`cicecore/shared/ice_kinds_mod.F90` 定义 CICE 使用的数值种类（kind）数据类型。CICE 的各处代码使用这些 kind 定义变量类型。为保持接口一致，CICE 的 kind 沿用 Icepack 定义的 kind。

## 常量

`cicecore/shared/ice_constants.F90` 定义若干模式常量。其中一些是硬编码参数，另一些有内部默认值，也可通过 namelist 设置。

## 动态数组分配

CICE v5 及更早版本主要使用静态数组，需要通过多个 CPP 宏定义网格大小、块大小、示踪物数量等。从 CICE v6 起，数组改为动态分配，这些参数成为 namelist 设置。下列 CPP 宏在 CICE v6 及后续版本中不再使用：

```text
-DNXGLOB=100 -DNYGLOB=116 -DBLCKX=25 -DBLCKY=29 -DMXBLCKS=4 -DNICELYR=7 -DNSNWLYR=1 -DNICECAT=5 -DTRAGE=1 -DTRFY=1 -DTRLVL=1 -DTRPND=1 -DTRBRI=0 -DNTRAERO=1 -DTRZS=0 -DNBGCLYR=7 -DTRALG=0 -DTRBGCZ=0 -DTRDOC=0 -DTRDOC=0 -DTRDIC=0 -DTRDON=0 -DTRFED=0 -DTRFEP=0 -DTRZAERO=0 -DTRBGCS=0 -DNUMIN=11 -DNUMAX=99
```

它们已迁移到[ namelist 设置](../user_guide/ug_case_settings.md)中的变量：

```text
nx_global, ny_global, block_size_x, block_size_y, max_blocks, nilyr, nslyr, ncat, nblyr, n_aero, n_zaero, n_algae, n_doc, n_dic, n_don, n_fed, n_fep, numin, numax
```

## 时间管理器

时间管理器（time manager）的数据是 `cicecore/shared/ice_calendar.F90` 中的模块数据。许多时间管理器数据是公开的，并在模式时间步推进过程中使用。实际的时间步推进发生在驱动程序代码中的 `CICE_RunMod.F90`。时间管理器于 2021 年初更新；更多信息见[实现指南中的时间管理器](../user_guide/ug_implementation.md#时间管理器)。

## 通信

CICE 提供 MPI 和串行两个底层通信包，作为模式与底层库之间的中间层。构建时只会编译其中之一，不会同时编译两者。

`cicedyn/infrastructure/comm/mpi/` 基于 MPI，通过较通用的接口提供晕区更新（halo update）、全局求和、汇集／分发（gather/scatter）、广播等操作，从而把代码中的 MPI 调用隔离开。

`cicedyn/infrastructure/comm/serial/` 提供相同的接口，但在没有 MPI 的共享内存模式下运行。CICE 脚本中 MPI 任务数为 1 时，默认使用串行库。这样模式可以在单核上运行，或仅使用 OpenMP 并行运行，而不需要 MPI 库。

## 输入输出

CICE 有三个底层输入输出（I/O）包：`io_netcdf`、`io_binary` 和 `io_pio`。它们在模式与底层 I/O 写入方式之间提供中间层。构建时只能选择其中一个。CICE 脚本默认使用 `io_netcdf`；其他选择可在构建前，通过案例目录中 `cice.settings` 的 `ICE_IOTYPE` 设置。

`cicedyn/infrastructure/io/io_netcdf/` 是独立运行 CICE 的默认包，使用标准 NetCDF 调用读写 NetCDF 格式的历史文件和重启文件。为支持并行，它由根任务读写文件，并在根任务与其他任务之间汇集和分发场。

`cicedyn/infrastructure/io/io_binary/` 使用汇集／分发方式支持二进制格式文件，由根任务读写。

`cicedyn/infrastructure/io/io_pio/` 通过 PIO 接口读写。PIO 是[并行 I/O 库](https://github.com/NCAR/ParallelIO)，支持通过 NetCDF 和 PnetCDF 等接口读写二进制与 NetCDF 文件。即使使用串行 NetCDF，PIO 在内存中一般也比标准汇集／分发方法具有更好的并行性；可通过可选的 PnetCDF 链接获得并行读写能力。

更多信息见[模式输入输出](../user_guide/ug_implementation.md#模式输入输出)。

原文：[dg_infra.rst](../../source/developer_guide/dg_infra.rst)
