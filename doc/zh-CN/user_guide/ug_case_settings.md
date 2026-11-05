# 案例设置、模型 namelist 与 CPP 宏

案例由 `cice.settings` 和 `ice_in` 两个重要文件定义。`cice.settings` 是用于设置、构建及运行案例的环境变量列表；`ice_in` 是 CICE 的 namelist 输入文件。下文描述两者的变量，并列出编译时开启或关闭功能的预处理宏（preprocessor macros）。

## C 预处理器（CPP）宏

CPP 宏在编译时激活不同源码，主要用于纳入或排除某些库和 Fortran 语言特性；用法见[运行指南](ug_running.md)。

| 宏 | 说明 |
| --- | --- |
| **通用宏（General Macros）** | |
| `CESM1_PIO` | 兼容约 2010 年随 CESM1 发布的 PIO 接口／版本。 |
| `ESMF_INTERFACE` | 在部分驱动代码中启用 ESMF；另有 `USE_ESMF_LIB`、`USE_ESMF_METADATA`。 |
| `FORTRANUNDERSCORE` | 支持 `ice_shr_reprosum86.c` 的 Fortran–C 接口，通常应始终启用。`ice_shr_reprosum.c` 中还有 `FORTRANDOUBULEUNDERSCORE`、`FORTRANCAPS` 等，在 CICE 中一般不用，但接口出问题时可能有用。 |
| `GPTL` | 如 PIO 需要，则启用 GPTL 初始化。 |
| `NO_CDF2` | 关闭 NetCDF CDF2（`nf90_64bit_offset`）支持。 |
| `NO_CDF5` | 关闭 NetCDF CDF5（`nf90_64bit_data`）支持。 |
| `NO_F2003` | 关闭部分 Fortran 2003 特性。 |
| `NO_HDF2` | 关闭 NetCDF HDF5（NetCDF4，包括分块和压缩）支持。 |
| `NO_I8` | 将 `integer*8` 转为 `integer*4`，可能不利于 `bfbflag` 的 `ddpdd` 等算法。 |
| `NO_R16` | 将 `real*16` 转为 `real*8`，可能不利于 `bfbflag` 的 `lsum16` 等算法。 |
| `NO_SNICARHC` | 不编译 `shortwave=dEdd_snicar_ad` 所需的硬编码五波段 SNICAR 表，可能缩短编译时间。 |
| `USE_NETCDF` | 启用 NetCDF 代码；发布配置通常需要。旧宏 `ncdf` 仍受支持。 |
| `USE_PIO1` | 将 CICE 的 PIO 实现改为兼容 PIO1；默认兼容 PIO2。 |
| **应用宏（Application Macros）** | |
| `CESMCOUPLED` | 启用 CESM 耦合应用的代码改动。 |
| `CICE_IN_NEMO` | 启用 NEMO 海洋模型耦合代码。 |
| `CICE_DMI` | 启用 DMI 耦合模型代码。 |
| `ICE_DA` | 启用 HadGEM 驱动中的代码改动。 |
| `RASM_MODS` | 启用 RASM 耦合应用的代码改动。 |
| **库宏（Library Macros）** | |
| `_OPENMP` | 使用 OpenMP 编译时自动定义。 |
| `_OPENACC` | 使用 OpenACC 编译时自动定义。 |

## CICE 设置（CICE Settings）

`cice.settings` 的环境变量定义案例配置、文件系统、运行和构建设置。若干变量由 `cice.setup` 设置；文件按案例生成，可按需修改。下表中“脚本”表示由 `cice.setup` 设置。

| 变量 | 格式／选项 | 说明 | 默认值 |
| --- | --- | --- | --- |
| `ICE_CASENAME` | 字符串 | 案例名 | 脚本 |
| `ICE_SANDBOX` | 字符串 | 工作区目录 | 脚本 |
| `ICE_MACHINE` | 字符串 | 机器名 | 脚本 |
| `ICE_ENVNAME` | 字符串 | 环境名 | 脚本 |
| `ICE_MACHCOMP` | 字符串 | 机器与环境组合名 | 脚本 |
| `ICE_SCRIPTS` | 字符串 | 脚本目录 | 脚本 |
| `ICE_CASEDIR` | 字符串 | 案例目录 | 脚本 |
| `ICE_RUNDIR` | 字符串 | 运行目录 | 脚本 |
| `ICE_OBJDIR` | 字符串 | 编译目录 | `${ICE_RUNDIR}/compile` |
| `ICE_RSTDIR` | 字符串 | 未使用 | `${ICE_RUNDIR}/restart` |
| `ICE_HSTDIR` | 字符串 | 未使用 | `${ICE_RUNDIR}/history` |
| `ICE_LOGDIR` | 字符串 | 日志目录 | `${ICE_CASEDIR}/logs` |
| `ICE_DRVOPT` | 字符串 | 未使用 | `standalone/cice` |
| `ICE_TARGET` | 字符串 | 构建目标 | 脚本 |
| `ICE_IOTYPE` | `binary/netcdf/pio1/pio2` | I/O 源码：分别使用 `io_binary`（不支持 NetCDF）、`io_netCDF`、或 `io_pio` 搭配 PIO1／PIO2（支持经 PIO 接口读写 NetCDF 和并行 NetCDF） | 脚本 |
| `ICE_CLEANBUILD` | `true/false` | 构建前自动清理 | `true` |
| `ICE_CPPDEFS` | 用户定义宏 | 构建时传入的 CPP 宏 | 空 |
| `ICE_QUIETMODE` | `true/false` | 减少屏幕上的构建输出 | `false` |
| `ICE_GRID` | 字符串 | 网格：`gbox12/80/128/180` 为对应尺寸的方盒网格；`gx1/gx3` 为格陵兰移极全球网格；`tx1` 为 1° 三极全球网格 | 脚本 |
| `ICE_NTASKS` | 整数 | MPI 任务数 | 脚本 |
| `ICE_NTHRDS` | 整数 | 每任务线程数 | 脚本 |
| `ICE_OMPSCHED` | 字符串 | OpenMP `SCHEDULE` 环境设置 | `static,1` |
| `ICE_TEST` | 字符串 | 测试模式设置 | 脚本 |
| `ICE_TESTNAME` | 字符串 | 测试名 | 脚本 |
| `ICE_TESTID` | 字符串 | 测试标识 | 脚本 |
| `ICE_BASELINE` | 字符串 | `--bdir` 对应的基线目录名 | 脚本 |
| `ICE_BASEGEN` | 字符串 | `--bgen` 对应的生成基线目录名 | 脚本 |
| `ICE_BASECOM` | 字符串 | `--bcmp` 对应的比较基线目录名 | 脚本 |
| `ICE_BFBCOMP` | 字符串 | `--bcmp` 的对比案例位置 | 脚本 |
| `ICE_BFBTYPE` | `log/logrest/qcchk/qcchkf/restart` | 逐位比较对象：日志、日志与重启、同气候 QC、不同气候 QC、重启文件 | `restart` |
| `ICE_SPVAL` | 字符串 | `cice.settings` 字符串的特殊值 | 脚本 |
| `ICE_RUNLENGTH` | 整数 | 默认批处理运行时长：`-1` 15 分钟，`0` 30 分钟，`1` 59 分钟，`2` 2 小时，`2<N<8` 为 N 小时，`≥8` 为 8 小时 | 脚本 |
| `ICE_ACCOUNT` | 字符串 | 批处理账户号 | 命令行、`.cice_proj` 或默认 |
| `ICE_QUEUE` | 字符串 | 批处理队列名 | 命令行或默认 |
| `ICE_THREADED` | `true/false` | 强制线程化编译；`ICE_NTHRDS>1` 时总会线程化 | `false` |
| `ICE_COMMDIR` | `mpi/serial` | 基础设施通信版本 | 由 `ICE_NTASKS` 决定 |
| `ICE_SNICARHC` | `true/false` | 在 Icepack 启用硬编码 SNICAR 表 | `false` |
| `ICE_BLDDEBUG` | `true/false` | 启用调试编译标志 | `false` |
| `ICE_COVERAGE` | `true/false` | 启用覆盖率编译标志 | `false` |

## Namelist 选项表

CICE 读取由多个 namelist 组组成的 `ice_in`。以下列出各组变量；默认值来自源码，除非 `ice_in` 覆盖，否则会使用这些值。源码默认值不一定是正式生产运行的推荐值。

### `setup_nml`

| 变量 | 说明与可选值 | 默认值 |
| --- | --- | --- |
| `bfbflag` | 逐位可重现求和：`off` 先局部归约再全局标量求和；`lsum4/8/16` 分别以 `real*4/8/16` 局部归约；`ddpdd` 为并行 double-double 算法；`reprosum` 为定点双整数求和 | `off` |
| `conserv_check` | 守恒检查（逻辑值） | `.false.` |
| `cpl_bgc` | 经驱动耦合生物地球化学（BGC） | `.false.` |
| `days_per_year` | 模型年天数 | 365 |
| `day_init` | 非重启运行的初始日 | 1 |
| `debug_forcing` | 输出额外强迫诊断 | `.false.` |
| `debug_model` | 输出扩展模型点诊断 | `.false.` |
| `debug_model_i`、`debug_model_j` | 调试点的局部 i、j 索引 | -1 |
| `debug_model_iblk`、`debug_model_task` | 调试点的块号、MPI 任务号 | -1 |
| `debug_model_step` | 开始写 `debug_model` 输出的初始时间步 | 0 |
| `diagfreq` | 诊断输出频率，单位为时间步 | 24 |
| `diag_type` | 诊断输出到 `stdout` 或 `file` | `stdout` |
| `diag_file` | 诊断输出文件 | `ice_diag.d` |
| `dt` | 热力学时间步，秒 | 3600. |
| `dumpfreq` | 重启写入频率类型：`d/d1` 每 N 天／仅在 N 天后一次；`h/h1` 小时；`m/m1` 月；`y/y1` 年；`1/11` 时间步。N 由 `dumpfreq_n` 指定 | `'y','x','x','x','x'` |
| `dumpfreq_base` | 频率基点：`init` 相对于 `year_init/month_init/day_init`，`zero` 相对于 `0000-01-01` | 五个 `init` |
| `dumpfreq_n` | 重启频率整数数组 | `1,1,1,1,1` |
| `dump_last` | 最后一个时间步写重启文件 | `.false.` |
| `histfreq` | 历史输出频率：`d/h/m/y/1` 为每 N 天／小时／月／年／时间步，`n` 为第 N 天，`x` 不写 | `'1','h','d','m','y','n'` |
| `histfreq_base` | 历史输出基点，`init` 或 `zero`，同 `dumpfreq_base` | 五个 `zero` |
| `histfreq_n` | 历史输出频率整数数组 | `1,1,1,1,1` |
| `history_chunksize` | 历史文件的 x、y 分块尺寸，仅 HDF5 | `0,0` |
| `history_deflate` | 历史文件压缩级别 0–9，仅 HDF5 | 0 |
| `history_dir`、`history_file` | 历史输出目录、文件前缀 | `./`、`iceh` |
| `history_format` | 历史文件格式：`binary`、`cdf1`（NetCDF3 classic）、`cdf2`（64 位 offset）、`cdf5`（64 位 data）、`default`、`hdf5`（NetCDF4）；`pio_pnetcdf`／`pio_netcdf` 已弃用；`pnetcdf1/2/5` 为相应的并行 NetCDF 格式 | `cdf1` |
| `history_iotasks`、`history_root`、`history_stride` | PIO 历史输出的 I/O 任务数、根任务和步长；`-99` 为内部默认 | -99 |
| `history_precision` | 历史文件精度，4 或 8 字节 | 4 |
| `history_rearranger` | PIO I/O 重排：`box`、`subset` 或内部 `default` | `default` |
| `hist_avg` | 写时间平均数据，逐流设置 | 五个 `.true.` |
| `hist_suffix` | 非 `x` 时附加在 `history_file` 后的字符 | `x,x,x,x,x` |
| `hist_time_axis` | 历史文件时间轴落在区间 `begin/middle/end` | `end` |
| `ice_ic` | 初始条件：`default` 等同 `internal`，根据 `ice_data_type/conc/dist` 设定；`none` 为无冰；也可给重启文件路径 | `default` |
| `incond_dir`、`incond_file` | 初始条件目录、输出文件前缀 | `./`、`iceh_ic` |
| `istep0` | 初始时间步编号 | 0 |
| `latpnt`、`lonpnt` | 两个诊断点的纬度、经度 | `90,-65`、`0,-45` |
| `lcdf64` | 使用 64 位 NetCDF 格式，已弃用；改用 `history_format`、`restart_format` | `.false.` |
| `memory_stats` | 内存使用诊断 | `.false.` |
| `month_init` | 非重启运行的初始月 | 1 |
| `ndtd` | 每个热力学时间步中的动力学、平流、脊化步骤数 | 1 |
| `npt`、`npt_unit` | 模拟时长与单位：`d/h/m/s/y/1` 对应天／小时／月／秒／年／时间步 | 99999、`1` |
| `numin`、`numax` | 内部 I/O 单元编号的最小、最大值 | 11、99 |
| `pointer_file` | 重启指针文件名 | `ice.restart_file` |
| `print_global` | 打印全局求和诊断 | `.true.` |
| `print_points` | 打印两个网格点的诊断 | `.false.` |
| `restart` | 仍存在但已弃用；现按其他输入内部设置 | — |
| `restart_chunksize`、`restart_deflate` | HDF5 重启文件的 x/y 分块尺寸及 0–9 压缩级别 | `0,0`、0 |
| `restart_dir`、`restart_file` | 重启目录、输出前缀 | `./`、`iced` |
| `restart_ext` | 在重启文件中读写 halo 单元 | `.false.` |
| `restart_format` | 重启文件格式，选项与 `history_format` 相同 | `cdf1` |
| `restart_iotasks`、`restart_root`、`restart_stride` | PIO 重启输出的 I/O 任务数、根任务、步长；`-99` 为内部默认 | -99 |
| `restart_mod` | 读取重启文件时调整 `aice`：`adjust_aice`、`adjust_aice_test`（测试舍入）或 `none` | `none` |
| `restart_rearranger` | PIO I/O 重排：`box/default/subset` | `default` |
| `runid` | 运行标签，目前仅 CESM | `unknown` |
| `runtype` | `continue` 使用 `pointer_file` 重启；`initial` 从 `ice_ic` 开始 | `initial` |
| `sec_init` | 非重启运行的初始秒 | 0 |
| `timer_stats` | 控制额外计时输出 | `.false.` |
| `use_leap_years` | 包含闰日 | `.false.` |
| `use_restart_time` | 仅在 `runtype=initial` 时用重启文件设置初始日期 | `.false.` |
| `version_name` | 模型版本名 | `unknown_version_name` |
| `write_histrest` | 需要时写历史重启 | `.true.` |
| `write_ic` | 写初始条件 | `.false.` |
| `year_init` | 非重启运行的初始年 | 0 |

### `grid_nml`

| 变量 | 说明与可选值 | 默认值 |
| --- | --- | --- |
| `bathymetry_file`、`bathymetry_format` | 水深文件名；格式 `default` 为 NetCDF 深度场，`pop` 为厘米单位 ASCII 厚度文件 | `unknown_bathymetry_file`、`default` |
| `close_boundaries` | 关闭边界；2025 年 11 月弃用，改用 `ew_boundary_type`、`ns_boundary_type` | `.false.` |
| `dxrect`、`dyrect` | 矩形网格 x、y 间距，厘米 | 0.0 |
| `dxscale`、`dyscale` | 用户定义的矩形网格 x、y 尺度因子 | 1.0 |
| `gridcpl_file` | 耦合网格信息输入文件 | `unknown_gridcpl_file` |
| `grid_atm`、`grid_ocn` | 大气／海洋强迫或耦合网格：`A` 所有场在 T 点；`B` 热力学场在 T、动力场在 U；`C` 热力学场在 T、动力 u/v 分别在 E/N；`CD` 热力学场在 T、动力场在 N 和 E | `A` |
| `grid_file` | 待读网格文件名 | `unknown_grid_file` |
| `grid_format` | `bin` 直接访问网格及 kmt 文件；`geosnc`、`pop_nc`、`pop_nc_ext`、`mom_nc` 为相应 NetCDF 格式；`meshnc` 是无 CICE 代码支持的耦合网格选项 | `bin` |
| `grid_ice` | 海冰网格：`B` 为中心 T、东北角 U；`C` 为中心 T、东边 U、北边 V | `B` |
| `grid_outfile` | 写一次性网格历史文件 | `.false.` |
| `grid_type` | `column` 单列纬经网格；`displaced_pole` 移极；`latlon` 从 `latlongrid` 读入；`rectangular` 由 `rectgrid` 定义；`regional` 区域；`tripole` 三极。部分类型从 `grid_format` 指定格式的文件读取 | `rectangular` |
| `kcatbound` | 厚度分类边界：`-1` 单类别；`0` 旧公式；`1` 整数边界新公式；`2` WMO 标准；`3` 渐近方案 | 1 |
| `kmt_file` | 陆地掩膜文件名 | `unknown_kmt_file` |
| `kmt_type` | 掩膜类型：`file` 从文件读；`boxislands` 复杂测试几何；`channel` 纬向通道；`channel_oneeast`／`channel_onenorth` 单格通道；`default` 在左上和右下布陆；`wall` 右边界；`none` 无陆地，仅用于理想化测试和开发 | `file` |
| `latrefrect`、`lonrefrect` | 矩形网格左下角纬度、经度，度 | 71.35、-156.5 |
| `nblyr`、`ncat`、`nfsd` | ZBGC 层数、冰厚类别数、浮冰尺寸类别数 | 0、0、1 |
| `nilyr`、`nslyr` | 海冰、积雪垂向层数 | 0、0 |
| `scale_dxdy` | 将 `dxscale/dyscale` 应用于矩形网格 | `false` |
| `use_bathymetry` | 为海底应力选项使用读入的水深文件 | `.false.` |

### `domain_nml`

| 变量 | 说明与可选值 | 默认值 |
| --- | --- | --- |
| `add_mpi_barriers` | 添加 MPI 屏障，限制通信 | `.false.` |
| `block_size_x`、`block_size_y` | x、y 方向块尺寸 | -1 |
| `debug_blocks` | 增加块分解调试输出 | `.false.` |
| `distribution_type` | 块分配方法：`cartesian` 二维笛卡尔；`rake` 邻近块再分配；`roundrobin` 每进程依次一块；`sectcart` 分到各象限；`sectrobin` 每进程多块；`spacecurve` 空间填充曲线；`spiralcenter` 从中心螺旋向外轮转；`wghtfile` 按文件权重 | `cartesian` |
| `distribution_wght` | 权重方法：`block` 去除陆地块；`blockall` 不去除陆地块且给最小权重；`blockfull` 不去除且给完整权重；`latitude` 按纬度／海洋设置每块工作量 | `latitude` |
| `distribution_wght_file` | `distribution_type=wghtfile` 时的权重文件 | `unknown` |
| `ew_boundary_type`、`ns_boundary_type` | 东西／南北边界：`closed` 对矩形网格边界强制两格陆地；`cyclic` 周期；`open` Dirichlet；南北还可选 `tripole`（U 折返）、`tripoleT`（T 折返） | `cyclic` |
| `maskhalo_dyn`、`maskhalo_remap`、`maskhalo_bound` | 屏蔽动力学、输运、边界更新未使用的 halo 单元 | `.false.` |
| `max_blocks` | 每 MPI 任务最大块数，供内存分配；`-1` 自动计算 | -1 |
| `nprocs` | MPI 任务数；`-1` 自动计算 | -1 |
| `nx_global`、`ny_global` | 全局网格 x、y 尺寸 | -1 |
| `processor_shape` | `distribution_type=cartesian` 的进程形状：`slenderX1` y 向一进程，高而窄；`slenderX2` y 向两进程；`square-ice` x 进程多于 y；`square-pop` y 多于 x，后两者近似方形 | `slenderX2` |

### `tracer_nml`

| 变量 | 说明 | 默认值 |
| --- | --- | --- |
| `n_aero`、`n_zaero` | 气溶胶示踪物数；Z 气溶胶可选 0–6 | 0 |
| `n_algae` | 藻类示踪物数，0–3 | 0 |
| `n_dic`、`n_doc`、`n_don` | 溶解无机碳、溶解有机碳、溶解有机氮示踪物数，分别可选 0–1、0–3、0–1 | 0 |
| `n_fed`、`n_fep` | 溶解态、颗粒态铁示踪物数，0–2 | 0 |
| `n_iso` | 同位素示踪物数 | 0 |
| `tr_aero`、`tr_fsd`、`tr_FY`、`tr_iage`、`tr_iso`、`tr_lvl` | 分别启用气溶胶、浮冰尺寸分布、首年冰面积、冰龄、同位素、平整冰面积与体积示踪 | `.false.` |
| `tr_pond_cesm` | CESM 融池选项，已弃用 | — |
| `tr_pond_lvl`、`tr_pond_sealvl`、`tr_pond_topo` | 平整冰、海平面、地形融池示踪 | `.false.` |
| `tr_snow` | 高级积雪物理 | `.false.` |
| `restart_aero`、`restart_age`、`restart_fsd`、`restart_FY`、`restart_iso`、`restart_lvl`、`restart_pond_lvl`、`restart_pond_sealvl`、`restart_pond_topo`、`restart_snow` | 从重启文件恢复相应示踪物或浮冰尺寸分布、积雪值 | `.false.` |

### `thermo_nml`

| 变量 | 说明与可选值 | 默认值 |
| --- | --- | --- |
| `a_rapid_mode` | 盐水通道直径，米 | `0.5e-3` |
| `aspect_rapid_mode` | 盐水对流纵横比 | 1.0 |
| `conduct` | 热导率方案：`bubbly`（Pringle 2007）或 `MU71`（Maykut 1971） | `bubbly` |
| `dSdt_slow_mode` | 缓慢排水强度，m/s/K | `-1.5e-7` |
| `floediam` | 侧向融化的有效浮冰直径，米 | 300.0 |
| `hfrazilmin`、`hi_min` | 新成冰晶冰最小厚度、海冰最小厚度，米 | 0.05、0.01 |
| `kitd` | 冰厚分布（ITD）近似：`0` δ 函数，`1` 线性重映射 | 1 |
| `ksno` | 积雪热导率 | 0.3 |
| `ktherm` | 热力学：`-1` 关闭，`1` Bitz–Lipscomb 模型，`2` 糊状层模型 | 1 |
| `itd_area_min`、`itd_mass_min` | 小于此面积／质量时删除海冰 | `1.e-11`、`1.e-10` |
| `phi_c_slow_mode`、`phi_i_mushy` | 临界液相体积分数、底边界固相体积分数 | 0.05、0.85 |
| `Rac_rapid_mode` | 临界 Rayleigh 数 | 10.0 |
| `Tliquidus_max` | 糊状层液相线最高温度，°C | 0.0 |
| `tscale_pnd_drain` | 糊状层宏观排水时间尺度，天 | 10 |

### `dynamics_nml`

| 变量 | 说明与可选值 | 默认值 |
| --- | --- | --- |
| `advection` | 平流方案：`remap` 线性重映射；`upwind` 供体单元方案 | `remap` |
| `algo_nonlin` | 隐式求解器的非线性算法：`anderson` 或 `picard` | `picard` |
| `alphab` | Lemieux 等（2016）中的 $\alpha_b$ 因子 | 20.0 |
| `arlx`、`brlx` | 修订版 EVP 参数 | 300.0 |
| `capping_method` | 上限方法：`max`（Hibler 1979）或 `sum`（Kreyscher 2000） | `max` |
| `Cf` | 脊化功与势能变化之比 | 17.0 |
| `coriolis` | Coriolis 参数：`constant` 为 $1.46\times10^{-4}\,s^{-1}$；`latitude` 随纬度变化；`zero` 为零 | `latitude` |
| `Cstar`、`Pstar` | Hibler 强度公式常数；`Pstar` 单位 N/m² | 20、`2.75e4` |
| `deltaminEVP`、`deltaminVP` | 黏度计算的最小 $\Delta$ | `1e-11`、`2e-9` |
| `dim_fgmres`、`dim_pgmres` | FGMRES 的最大 Arnoldi 迭代次数、PGMRES 预条件器相应次数 | 50、5 |
| `dyn_area_min`、`dyn_mass_min` | 激活动力学的最小冰面积浓度、冰质量（kg/m²） | `1.e-11`、`1.e-10` |
| `e_plasticpot`、`e_yieldcurve` | 椭圆塑性势、屈服曲线纵横比 | 2.0 |
| `elasticDamp` | 弹性阻尼参数 | 0.36 |
| `evp_algorithm` | `standard_2d` 为标准二维 EVP 内存并行求解器；`shared_mem_1d` 为一维共享内存求解器 | `standard_2d` |
| `kdyn` | 动力学：`-1/0` 关闭；`1` EVP；`2` EAP；`3` VP | 1 |
| `kstrength` | 冰强度公式：`0` Hibler（1979）；`1` Rothrock（1975） | 1 |
| `krdg_partic`、`krdg_redist` | 脊化参与函数、再分配函数：`0` 旧、`1` 新 | 1 |
| `kridge`、`ktransport` | 脊化、输运：`-1` 关闭，`1` 开启 | 1 |
| `Ktens` | 抗拉强度因子，见 König 等（2010） | 0.0 |
| `k1`、`k2` | 固着冰参数化的第一、第二自由参数；`k2` 单位 N/m³ | 7.5、15.0 |
| `maxits_fgmres`、`maxits_pgmres` | FGMRES、PGMRES 最大重启次数 | 1 |
| `maxits_nonlin` | VP 求解器最大非线性迭代次数 | 10 |
| `monitor_fgmres`、`monitor_pgmres`、`monitor_nonlin` | 每次相应迭代输出速度范数 | `.false.` |
| `mu_rdg` | `krdg_partic=1` 时脊冰 e 倍衰减尺度，m^0.5 | 3.0 |
| `ndte` | EVP 子循环次数 | 120 |
| `ortho_type` | FGMRES 正交化：`cgs` 经典 Gram–Schmidt；`mgs` 修正 Gram–Schmidt | `mgs` |
| `precond` | FGMRES 预条件器：`diag` Jacobi、`ident` 无、`pgmres` GMRES | `pgmres` |
| `reltol_fgmres`、`reltol_nonlin`、`reltol_pgmres` | 各求解器的相对容差 | `1e-1`、`1e-8`、`1e-6` |
| `revised_evp` | 使用修订版 EVP 公式 | `.false.` |
| `seabed_stress` | 固着冰的海底应力参数化 | `.false.` |
| `seabed_stress_method` | `LKD` 线性龙骨吃水法（Lemieux 2016）；`probabilistic` 接触概率法（Dupont 2022） | `LKD` |
| `ssh_stress` | 海面高度应力：`coupled` 从耦合的海面高度梯度计算；`geostropic` 从海流速度计算 | `geostrophic` |
| `threshold_hw` | 搁浅的最大水深，见 Amundrud（2004） | 30. |
| `use_mean_vrel` | VP 中使用前两次迭代相对速度的平均值 | `.true.` |
| `visc_method` | U 网格黏度：`avg_strength` 平均强度；`avg_zeta` 平均 $\zeta$ | `avg_zeta` |
| `yield_curve` | 屈服曲线；`ellipse` 为椭圆 | `ellipse` |

### `shortwave_nml`

| 变量 | 说明与可选值 | 默认值 |
| --- | --- | --- |
| `ahmax` | 超过此冰厚时反照率不再变化，米 | 0.3 |
| `albedo_type` | `ccsm3` 为 NCAR CCSM3 反照率实现；`constant` 使用四个常数 | `ccsm3` |
| `albicei`、`albicev` | 厚冰近红外、可见光反照率 | 0.36、0.78 |
| `albsnowi`、`albsnowv` | 冷雪近红外、可见光反照率 | 0.70、0.98 |
| `dT_mlt` | 单位雪粒半径变化对应的温差 | 1.5 |
| `kalg` | 藻类吸收系数 | 0.6 |
| `rsnw_mlt` | 融化雪粒最大半径 | 1500. |
| `R_ice`、`R_pnd`、`R_snw` | Delta-Eddington 短波中海冰、融池冰、积雪反照率的调节参数 | 0.0、0.0、1.5 |
| `shortwave` | 短波方法：`ccsm3`；`dEdd` 三波段 Delta-Eddington；`dEdd_snicar_ad` 为含五波段积雪的方法 | `ccsm3` |
| `snw_ssp_table` | `dEdd_snicar_ad` 查表：`snicar` 或测试用精简 `test` | `test` |
| `sw_dtemp`、`sw_frac` | 开始再分配的融化温差、再分配比例 | 0.02、0.9 |
| `sw_redist` | 将内部短波重新分配到表面 | `.false.` |

### `ponds_nml`

| 变量 | 说明与可选值 | 默认值 |
| --- | --- | --- |
| `apnd_sl` | 海平面融池的平衡面积比例 | 0.27 |
| `dpscale` | 可渗透冰排水时间尺度 | 1.0 |
| `frzpnd` | 融池再冻结公式：`cesm` 或 `hlid`（考虑融池冰厚的 Stefan 再冻结） | `cesm` |
| `hp1` | 地形融池临界冰盖厚度，米 | 0.01 |
| `hs0`、`hs1` | 分别为转为裸冰、融池冰的雪深阈值，米 | 未指定、0.03 |
| `pndaspect` | 融池变化纵横比（深度：面积） | 0.8 |
| `rfracmax`、`rfracmin` | 加入融池的融水最大、最小比例 | 0.85、0.15 |

### `snow_nml`

| 变量 | 说明与可选值 | 默认值 |
| --- | --- | --- |
| `drhosdwind` | 风致积雪压实因子，kg·s/m⁴ | 27.3 |
| `rhosmax`、`rhosmin`、`rhosnew` | 最大、最小和新雪密度，kg/m³ | 450、100、100 |
| `rsnw_fall`、`rsnw_tmax` | 新雪粒半径、最大雪粒半径，单位 $10^{-6}$ m | 100、1500 |
| `snwgrain` | 积雪变质开关 | `.false.` |
| `snwlvlfac` | 积雪的比例增加量 | 0.3 |
| `snwredist` | 积雪再分配方案：`bulk`、`ITD`、`ITDrdg`、`none`（关闭） | `none` |
| `snw_aging_table` | 干变质查找表：文件中的一维与三维场、`snicar` 三维场或内部生成测试表 `test` | `test` |
| `snw_drdt0_fname`、`snw_kappa_fname`、`snw_rhos_fname`、`snw_T_fname`、`snw_tau_fname`、`snw_Tgrd_fname` | 积雪老化文件中对应场名 | `unknown` |
| `snw_filename` | 积雪老化表数据文件名 | `unknown` |
| `use_smliq_pnd` | 使用积雪液态水填充融池 | `.false.` |
| `windmin` | 触发积雪压实的最小风速，m/s | 10. |

### `forcing_nml`

| 变量 | 说明与可选值 | 默认值 |
| --- | --- | --- |
| `atmbndy` | 大气边界层总体输送系数：`constant` 常数；`mixed` 风应力用稳定度、显热和潜热用常数；`similarity` 用稳定度 | `similarity` |
| `atmiter_conv` | $u_*$ 的收敛准则 | 0.0 |
| `atm_data_dir` | 大气强迫数据目录或其部分路径 | 空 |
| `atm_data_format` | `bin` 直接访问二进制；`nc` NetCDF | `bin` |
| `atm_data_type` | `box2001` 为 Hunke（2001）盒模型强迫；`default` 为代码常量；`hycom` 为 HYCOM NetCDF；`JRA55/JRA55do` 为相应再分析数据；`monthly` 月数据；`ncar` 总体强迫；`oned` 单列数据 | `default` |
| `atm_data_version` | 大气强迫文件建立日期 | `_undef` |
| `bgc_data_dir` | 海洋生物地球化学强迫目录 | `unknown_bgc_data_dir` |
| `bgc_data_type` | `clim` 气候态；`default` 代码常量；`hycom` HYCOM NetCDF；`ncar` POP 海洋数据 | `default` |
| `calc_strair` | 真：计算风应力和风速；假：从文件读取 | `.true.` |
| `calc_Tsfc` | 计算表面温度 | `.true.` |
| `congel_freeze` | 底部冻结冰：`one-step` 立即冻结，`two-step` 延迟冻结 | `two-step` |
| `cpl_frazil` | 冰晶冰水盐通量：`external` 在 Icepack 外处理；`fresh_ice_correction` 按糊状层物理修正淡水冰通量；`internal` 传递完整通量 | `fresh_ice_correction` |
| `default_season` | 初始强迫值使用 `summer` 或 `winter` | `winter` |
| `emissivity` | 雪和冰的发射率 | 0.985 |
| `fbot_xfer_type` | 海洋热交换系数：`Cdn_ocn` 可变，`constant` 恒定 | `constant` |
| `fe_data_type` | 铁强迫：`clim` 海洋气候态，`default` 默认值 | `default` |
| `formdrag` | 计算形状阻力 | `.false.` |
| `fyear_init` | 大气强迫数据起始年 | 1900 |
| `highfreq` | 高频大气耦合 | `.false.` |
| `ice_data_conc` | 初始冰浓度：`box2001` 西到东从 0 增至 1；`c1` 为 1；`p5/p8/p9` 为 0.5/0.8/0.9；`parabolic` 按冰厚呈抛物分布且类别浓度和为 1；`default` 等于 `parabolic` | `default` |
| `ice_data_dist` | 冰分布：`box2001` 西到东渐变；`gauss` 区域中心峰值的高斯分布；`uniform` 均匀；`default` 等于 `uniform` | `default` |
| `ice_data_type` | 初始冰形状：`block` 中心约占 25%；`boxslotcyl` 开槽圆柱；`box2001` 盒模型；`channel` i 向全域、j 向中央 50%；`eastblock` 东缘约 25%；`latsst` 依赖纬度与海温；`uniform` 全网格；`default` 等于 `latsst` | `default` |
| `ice_ref_salinity` | 耦合通量所用海冰参考盐度，ppt | 4.0 |
| `iceruf` | 大气界面的冰表面粗糙度，米 | 0.0005 |
| `l_mpond_fresh` | 地形融池水保留到融池排水 | `.false.` |
| `natmiter` | 大气边界层迭代次数 | 5 |
| `nfreq` | 海面波谱强迫的频率数 | 25 |
| `oceanmixed_file` | 海洋强迫数据文件 | `unknown_oceanmixed_file` |
| `oceanmixed_ice` | 启用海洋混合层计算 | `.false.` |
| `ocn_data_dir` | 海洋强迫数据目录 | `unknown_ocn_data_dir` |
| `ocn_data_format` | `bin` 直接访问二进制；`nc` NetCDF | `bin` |
| `ocn_data_type` | `clim` 海洋气候态；`default` 代码常量；`hycom` HYCOM NetCDF；`ncar` POP 数据 | `default` |
| `precip_units` | 液态降水单位：`mks`、`mm_per_month`、`mm_per_sec`（与 MKS 相同）、`m_per_sec` | `mks` |
| `restart_coszen` | 在重启文件读写太阳天顶角余弦 | `.false.` |
| `restore_ocn`、`restore_ice` | 将海表温度恢复到数据、沿侧边界恢复冰状态 | `.false.` |
| `rotate_wind` | 将东西／南北风旋转至计算网格 | `.true.` |
| `saltflux_option` | 盐通量：`constant` 用 `ice_ref_salinity`；`prognostic` 用预报盐度 | `constant` |
| `semi-implicit_Tsfc` | 基于 $d(hf)/dT_s$ 的表面温度半隐式耦合 | `.false.` |
| `tfrz_option` | 海洋冻结温度：`constant` 用 `Tocnfrz`；`linear_salt` 随盐度线性变化（`ktherm=1`）；`minus1p8` 固定 -1.8°C；`mushy` 与糊状层热力学一致（`ktherm=2`） | `mushy` |
| `trestore` | 海表温度恢复时间尺度，天 | 90 |
| `ustar_min` | 最小海洋摩擦速度，m/s | 0.0005 |
| `update_ocn_f` | 是否将冰晶冰水盐通量计入海洋通量 | `.false.` |
| `vapor_flux_correction` | 与假定温度相关的水汽凝华／升华修正 | `.false.` |
| `wave_spec_file` | 波谱强迫数据文件 | 空 |
| `wave_spec_type` | `constant` 使用文件中的固定波谱测试；`none` 无波冰相互作用；`profile` 使用固定虚拟谱；`random` 用随机数生成文件中的波谱 | `none` |
| `ycycle` | 强迫数据循环的年数 | 1 |

### `zbgc_nml`

该组控制垂向生物地球化学（vertical biogeochemistry, ZBGC）。下列成组变量按列出的顺序对应默认值。

| 变量 | 说明 | 默认值 |
| --- | --- | --- |
| `algaltype_diatoms`、`algaltype_phaeo`、`algaltype_sp` | 硅藻、定鞭藻、小型浮游生物在固定与移动状态间的迁移类型 | 各 0.0 |
| `algal_vel` | 藻类速度，见 Lavoie（2005） | `1.0e-7` |
| `alpha2max_low_diatoms/phaeo/sp` | 三类藻的低光限制，单位 $(W/m^2)^{-1}$ | 0.3、0.17、0.2 |
| `ammoniumtype` | 铵的固定／移动迁移类型 | 0.0 |
| `beta2max_diatoms/phaeo/sp` | 三类藻的光抑制，单位 $(W/m^2)^{-1}$ | 0.001、0.04、0.001 |
| `bgc_flux_type` | 冰洋通量速度：`constant` 常数；`Jin2006` 按 Jin 等（2006） | `Jin2006` |
| `chlabs_diatoms/phaeo/sp` | 三类藻的叶绿素吸收，单位 $m^{-1}/(mg/m^3)$ | 0.03、0.05、0.01 |
| `dEdd_algae` | Delta-Eddington 藻类选项 | `.false.` |
| `dmspdtype`、`dmspptype` | DMSPd、DMSPp 的固定／移动迁移类型 | 0.0、0.5 |
| `doctype_l`、`doctype_s` | 脂质、糖类 DOC 的固定／移动迁移类型 | 0.0 |
| `dontype_protein` | 蛋白质 DON 的固定／移动迁移类型 | 0.0 |
| `dustFe_sol` | 尘埃铁可溶比例 | 0.005 |
| `fedtype_1`、`feptype_1` | 溶解、颗粒脂质铁的固定／移动迁移类型 | 0.0、0.5 |
| `frazil_scav` | 海洋清除作用引起的初始生物示踪物增加量 | 0.8 |
| `fr_dFe` | 以藻类铁为单位的再矿化氮比例 | 1.0 |
| `fr_graze_diatoms/phaeo/sp` | 三类藻被摄食的比例 | 各 0.19 |
| `fr_graze_e`、`fr_graze_s` | 同化后排泄比例、摄食散失比例 | 各 0.5 |
| `fr_mort2min` | 死亡物质转为铵的比例 | 0.9 |
| `fr_resp`、`fr_resp_s` | 藻类生长的呼吸损失比例、其中成为 DMSPd 的比例 | 0.05、0.9 |
| `fsal` | 盐度限制，ppt | 1.0 |
| `F_abs_chl_diatoms/phaeo/sp` | Delta-Eddington 中三类藻的叶绿素吸收辐射缩放 | 2.0、5.0、4.0 |
| `f_doc_l`、`f_doc_s` | 死亡物质进入脂质、糖类 DOC 的比例 | 各 0.5 |
| `f_don_Am_protein`、`f_don_protein` | 再矿化 DON 转为铵的比例、散失摄食转为蛋白质的比例 | 1.0、0.6 |
| `f_exude_l`、`f_exude_s` | 渗出物进入脂质、糖类 DOC 的比例 | 各 1.0 |
| `grid_o`、`grid_o_t` | 底部、顶部通量的生物垂向尺度 | 各 0.006 |
| `grow_Tdep_diatoms/phaeo/sp` | 三类藻生长对温度的依赖，每 °C | 各 0.063 |
| `humtype` | 腐殖质的固定／移动迁移类型 | 0.0 |
| `initbio_frac` | 生物示踪物中的海洋示踪物浓度比例 | 1.0 |
| `K_Am_diatoms/phaeo/sp` | 铵半饱和浓度，mmol/m³ | 各 0.3 |
| `k_bac_l`、`k_bac_s` | 脂质、糖类 DOC 的细菌降解率，每天 | 各 0.03 |
| `k_exude_diatoms/phaeo/sp` | 三类藻渗出率，每天 | 各 0.0 |
| `K_Fe_diatoms/phaeo/sp` | 铁半饱和浓度，nM | 1.0、0.1、0.2 |
| `k_nitrif` | 硝化速率，每天 | 0.046 |
| `K_Nit_diatoms/phaeo/sp` | 硝酸盐半饱和浓度，mmol/m³ | 各 1.0 |
| `K_Sil_diatoms/phaeo/sp` | 硅酸盐半饱和浓度，mmol/m³ | 4.0、0.0、0.0 |
| `kn_bac_protein` | DON 细菌降解率，每天 | 0.2 |
| `l_sk` | 特征扩散尺度，米 | 2.0 |
| `max_dfe_doc1` | 冰中溶解铁与糖类的最大比，nm Fe/μM C | 0.2 |
| `max_loss` | 将吸收限制为剩余量的指定比例 | 0.9 |
| `modal_aero` | 模态气溶胶 | `.false.` |
| `mort_pre_diatoms/phaeo/sp` | 三类藻的基准死亡率 | 各 0.007 |
| `mort_Tdep_diatoms/phaeo/sp` | 三类藻死亡率的温度依赖，每 °C | 各 0.03 |
| `mu_max_diatoms/phaeo/sp` | 三类藻最大生长率，每天 | 1.44、0.63、0.41 |
| `nitratetype` | 硝酸盐固定／移动迁移类型 | -1.0 |
| `op_dep_min` | 光学深度超过此最小值时光衰减 | 0.1 |
| `phi_snow` | 盐水高度示踪物中的积雪孔隙度 | -1.0 |
| `ratio_chl2N_diatoms/phaeo/sp` | 藻类叶绿素／氮比，mg/mmol | 2.1、0.84、1.1 |
| `ratio_C2N_diatoms/phaeo/proteins/sp` | 碳／氮摩尔比 | 7.0、7.0、5.0、7.0 |
| `ratio_Fe2C_diatoms/phaeo/sp` | 藻类铁／碳比，μmol/mol | 0.0033、0.1、0.0033 |
| `ratio_Fe2N_diatoms/phaeo/sp` | 藻类铁／氮比，μmol/mol | 0.023、0.7、0.023 |
| `ratio_Fe2DOC_l`、`ratio_Fe2DOC_s`、`ratio_Fe2DON` | DOC 脂质、DOC 糖类及 DON 的铁／碳比，nmol/μmol | 0.033、1.0、0.023 |
| `ratio_Si2N_diatoms/phaeo/sp` | 藻类硅／氮摩尔比 | 1.8、0.0、0.0 |
| `ratio_S2N_diatoms/phaeo/sp` | 藻类硫／氮摩尔比 | 各 0.03 |
| `restart_bgc` | 从文件恢复 BGC 示踪物 | `.false.` |
| `restart_hbrine` | 恢复盐水高度 | `.false.` |
| `restore_bgc` | 将 BGC 恢复到数据值 | `.false.` |
| `R_dFe2dust` | 溶解铁／尘埃质量比，g/g；见 Tagliabue 等（2009） | 0.035 |
| `scale_bgc` | BGC 缩放开关 | `.false.` |
| `silicatetype` | 硅酸盐固定／移动迁移类型 | -1.0 |
| `skl_bgc` | 骨架生物地球化学，已弃用 | `.false.` |
| `solve_zbgc` | 求解 ZBGC | `.false.` |
| `tau_max`、`tau_min` | 移动到固定状态的慢速、快速交换时间 | 604800、3600 秒 |
| `tr_bgc_Am`、`tr_bgc_C`、`tr_bgc_chl`、`tr_bgc_DMS`、`tr_bgc_DON`、`tr_bgc_Fe`、`tr_bgc_hum`、`tr_bgc_Nit`、`tr_bgc_PON`、`tr_bgc_Sil` | 启用铵、藻类碳、叶绿素、DMS、DON、铁、腐殖质、硝酸盐、PON、硅酸盐示踪物 | `.false.` |
| `tr_brine`、`tr_zaero` | 启用盐水高度、垂向气溶胶示踪物 | `.false.` |
| `t_iron_conv` | 颗粒铁脱附为溶解铁的时间，天 | 3065. |
| `t_sk_conv`、`t_sk_ox` | Stefels 转换、DMS 氧化时间，天 | 5.0、12.0 |
| `T_max` | 最高温度，°C | 0.0 |
| `y_sk_DMS` | 高产率条件下的转换比例 | 0.7 |
| `zaerotype_bc1/bc2/dust1/dust2/dust3/dust4` | 各垂向气溶胶（黑碳和尘埃）组分固定／移动迁移类型 | 各 -1.0 |
| `z_tracers` | 垂向示踪物开关 | `.false.` |

### `icefields_nml` 等历史输出组

多个 icefields namelist 组控制模型历史输出。可用输出场完整列表见对应源码：`icefields_nml` 对应 `cicecore/cicedyn/analysis/ice_history_shared.F90`；`icefields_bgc_nml` 对应 `ice_history_bgc.F90`；`icefields_drag_nml` 对应 `ice_history_drag.F90`；`icefields_fsd_nml` 对应 `ice_history_fsd.F90`；`icefields_mechred_nml` 对应 `ice_history_mechred.F90`；`icefields_pond_nml` 对应 `ice_history_pond.F90`；`icefields_snow_nml` 对应 `ice_history_snow.F90`，这些文件均在同一 `analysis/` 目录。

`f_<var>` 控制变量 `<var>` 写入历史文件的频率：`d/h/m/y` 分别为每 `histfreq_n` 天／小时／月／年；`1` 为每时间步；`n` 为第 `histfreq_n` 天的瞬时值；`x` 不输出；`md` 可同时写月和日文件。`f_<var>_ai` 用相同频率代码控制网格单元平均场，支持 `d/h/m/y/1/x/md`。

[英文原文](../../source/user_guide/ug_case_settings.rst)
