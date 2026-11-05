# 实现

CICE 使用 Fortran 90 编写，可在 UNIX、Linux 及其他操作系统平台运行。目前的编码标准是 Fortran 2003；一维 EVP 求解器使用了 Fortran 2008 的 `CONTIGUOUS` 特性。代码基于二维水平正交网格，将其划分为二维水平块，通过 MPI 和 OpenMP 线程在块之间并行运行。代码还包含针对向量体系结构的一些优化。

`cicecore/` 中是支持模式动力学和顶层控制的源代码。单柱物理（column physics）代码位于 `icepack/`，它来自独立的 [Icepack 仓库](https://github.com/CICE-Consortium/Icepack)，在 GitHub 中作为子模块包含。`configuration/` 包含配置 CICE 案例的脚本。

## 目录结构

本发行版包含源代码和脚本；强迫数据可从 FTP 站点获取。CICE 目录结构如下：

| 文件或目录 | 内容 |
| --- | --- |
| `COPYRIGHT.pdf` | 版权声明 |
| `LICENSE.pdf` | 代码使用和分享许可 |
| `DistributionPolicy.pdf` | 代码使用和分享政策 |
| `README.md` | 基本信息与参考入口 |
| `icepack/` | Icepack 模块，包含自己的脚本、驱动程序和文档；CICE 仅使用 `icepack/columnphysics/` 中的单柱物理源代码 |
| `cicecore/` | CICE 源代码 |
| `cicecore/cicedyn/` | 动力核心相关例程 |
| `cicecore/drivers/` | 顶层驱动程序和耦合层 |
| `cicecore/shared/` | 与动力核心无关的 CICE 源代码 |
| `cicecore/version.txt` | CICE 模式版本号 |
| `configuration/scripts/` | 支持脚本，见[开发者指南的脚本章节](../developer_guide/dg_scripts.md) |
| `doc/` | 文档 |
| `cice.setup` | 创建案例的主要 CICE 脚本 |
| 点文件（dot files） | 以 `.` 开头，保存 Git 仓库或其他工具信息的文件 |

首次执行 `cice.setup` 时，会在 `-c` 后指定的位置创建案例（编译）目录。执行 `./cice.setup -h` 可查看该工具的帮助。

## 网格、边界条件与掩膜

最初的空间离散针对一般化正交 B 网格，见原文引用的 Murray 1996 或 Smith 1995。下图为 CICE B 网格示意图。中间有示踪物点 $t(i,j)$ 的单元称为 T 单元；冰雪面积、体积及能量定义在 t 点。与 $t(i,j)$ 对应的冰速 $\mathbf u(i,j)$ 定义在东北角（NE）。T 单元其余角分别是西北（NW）、西南（SW）和东南（SE）。T 单元北、西、南、东四边的长度依次为 `HTN`、`HTW`、`HTS`、`HTE`；经过单元中部沿 x、y 轴的长度分别为 `dxT`、`dyT`。

也会使用“U 单元”一词：它以相应 T 单元的东北角为中心，速度位于单元中心，速度分量沿网格线方向。在 B 网格实现中，内部冰应力张量在一个网格单元内取四个不同值，并用双线性近似表示单元内的应力张量和冰速（见原文引用 Hunke 2002）。这通常能避免与 B 网格有关的网格解耦问题。

![CICE B 网格示意图](../../source/user_guide/figures/CICE_Bgrid.png)

后来又加入在 C 网格和 CD 网格上求解的能力。C 网格的 $u$ 速度点位于 T 单元的东边（E），$v$ 速度点位于北边（N），而非角点。CD 网格的 $u$、$v$ 速度点同时位于 N 边和 E 边。为此，在已有 T、U 网格外，又增加定义在 T 单元北边和东边的 N、E 网格，如下图所示。

![CICE CD 网格示意图](../../source/user_guide/figures/CICE_Cgrid.png)

用户可以从文件读取网格，也可以在模式内部创建。`rectgrid` 代码创建规则矩形网格，使用 namelist 选项 `grid_type='rectangular'`。`popgrid`、`popgrid_nc` 读取非均匀网格的网格长度及其他参数，包括三极和区域网格。`mom_grid` 读取 MOM 镶嵌网格（mosaic/supergrid）格式定义的非均匀网格。

对 `popgrid` 格式，`grid_gx3.bin`、`kmt_gx3.bin` 包含约 3° 的 POP 网格及陆地掩膜；`grid_gx1.bin`、`kmt_gx1.bin` 包含约 1° 的网格及掩膜；`grid_tx1.bin`、`kmt_tx1.bin` 包含约 1° 的 POP 三极网格及掩膜。这些文件是无格式、直接访问、大端序（Big Endian）的二进制文件。

gx3 网格也提供 NetCDF 文件 `grid_gx3.nc`、`kmt_gx3.nc`，可作为定义其他网格的模板。网格文件至少须包含 `ULAT`、`ULON`、`HTN`、`HTE`、`ANGLE`。若文件中存在 `ANGLET`、`TLON`、`TLAT`，也会读取；否则由模式内部推导。

对 `grid_format='mom_nc'` 的 MOM 格式，需要符合 MOM 超网格约定的网格文件，可由 [FRE-NCTools](https://github.com/NOAA-GFDL/FRE-NCtools) 生成；另见[格式摘要](https://gist.github.com/adcroft/c1e207024fe1189b43dddc5f1fe7dd6c)。CICE 推导所需网格变量，使之与 MOM6 的网格实现一致。所有经纬度及网格长度从文件读取；A、B 网格单元面积也从文件加载，C 网格单元面积和单元旋转角由内部计算。所有计算与 MOM6 的方法保持一致。

`kmt`（掩膜）NetCDF 文件既用于 POP NetCDF 网格，也用于 MOM NetCDF 网格。文件中须有名为 `kmt` 或 `mask` 的变量，陆地取 0，海洋取 1。B 网格与 CD 网格使用相同的输入网格文件。

不同网格上的主要预报网格变量名如下：

| 变量 | T | U | N | E |
| --- | --- | --- | --- | --- |
| 经度 | `TLON` | `ULON` | `NLON` | `ELON` |
| 纬度 | `TLAT` | `ULAT` | `NLAT` | `ELAT` |
| x 方向长度 | `dxT` | `dxU` | `dxN` | `dxE` |
| y 方向长度 | `dyT` | `dyU` | `dyN` | `dyE` |
| 面积 | `tarea` | `uarea` | `narea` | `earea` |
| 掩膜（逻辑型） | `tmask` | `umask` | `nmask` | `emask` |
| 掩膜（实数型） | `hm` | `uvm` | `npm` | `epm` |

在 CESM 中，海冰模式交换耦合通量时可以使用与计算网格不同的网格；通过 namelist 变量 `gridcpl_file` 启用。

### 网格区域和块

全局网格区域一般为 `nx_global × ny_global`，块分配所用子区域为 `nx_block × ny_block`。子区域的物理部分索引为 `[ilo:ihi, jlo:jhi]`；区域外有 `nghost` 层“虚拟”或“晕区”单元（ghost/halo cells），用于边界条件。`global_scatter` 和 `global_gather` 例程分别把信息从全局区域分发到局部区域，以及从局部区域汇集回全局。若海冰模式未使用 MPI 进行网格分解，这些例程仅将全局索引调整为单个局部区域的索引。

建议使局部区域均匀划分全局区域。若无法做到，最东和／或最北的块会含有非物理点（padding）；它们被排除在计算区域外，对性能影响很小。`nghost` 是 `ice_blocks.F90` 中的硬编码参数。晕区代码理论上支持任意宽度，但 `nghost` 当前设为 1，更宽的晕区未经过正式测试。

![网格参数示意图](../../source/user_guide/figures/grid.png)

上图用一个具有 20 个单元的一维全局区域示例说明四个局部子区域的分解。每个子区域两侧各有一个晕区单元，物理部分标为 `ilo:ihi`。`nx_block` 是局部区域的总单元数，包括晕区单元；四个子区域采用相同编号方式。

用户在 `cice.settings` 中设置 `NTASKS`、`NTHRDS`，在 `ice_in` 中选择块大小 `block_size_x × block_size_y`，以及分解信息 `distribution_type`、`processor_shape`、`distribution_wgt`。这些信息决定块如何分配到处理器。模式在块上同时使用 MPI 和 OpenMP 并行。性能较好的参数组合见下文“性能”。`cice.setup` 会计算一些默认的分解与布局，但用户可手动修改 `ice_in` 覆盖默认值。

每个处理器上的块数可以不同。若 namelist 中 `max_blocks=-1`，模式会在内部计算；用户也可以指定，但过大会占用额外内存，过小则会因与分解不匹配而中止。运行时日志会打印分解信息；若块大小或最大块数与任务数、线程数不一致，模式会中止。最大块数过大时会输出警告，虽不致命但浪费内存。

若 `debug_blocks=true`，`ice_blocks.F90` 中 `create_blocks` 末尾的循环会打印所有块在全局网格上的位置；`ice_distribution.F90` 中 `create_local_block_ids` 末尾的类似循环会打印每个块的处理器及局部块号。据此可确定处理器和块上的网格分解。可能有数百至数千个块，因此只在必要时启用 `debug_blocks`。也可用 `cice.setup` 的 `debugblocks` 选项启用。用 TotalView 等调试器查看这些信息通常更方便。还可以在 `icefields_nml` 中启用输出字段 `f_blkmask`，将 `blkmask` 写入历史文件；它按 `blkmask = my_task + iblk/100` 标记分解后的块。

通信密集的配置可将 `add_mpi_barriers` 设为 `.true.`，通过额外的 MPI 屏障限制通信节奏，但可能使运行稍慢。当前只在少数位置加入屏障，其他位置也可能需要。一般应保持 `add_mpi_barriers=.false.`。

### 三极网格

三极网格（tripole grid）用于构造全球网格：南极及南部边界条件保持常规形式，同时避免在北冰洋设置物理边界或网格奇点。它在北方有两个位于陆地上的“极点”，而非一个北极，两极之间有一排网格点。这一排称为“折叠线”（fold），是物理网格的最上行。一个极点位于顶行左端，另一个位于该行中部。构造网格时将顶行折叠，使其左右两半重合。

有两种三极网格构造方式。最先引入 CICE 的称为 **U-fold**，其极点及两极之间的单元是 U 单元。另一种称为 **T-fold**，相应单元为 T 单元。OPA/NEMO 海洋模式也支持两者；其中把 U-fold 称为 f-fold，因为该模式使用 Arakawa C 网格，其 U 单元位于 T 行上。Namelist 变量 `ns_boundary_type` 选择三极类型：`tripole` 为 U-fold，`tripoleT` 为 T-fold。

在 U-fold 网格上，两极位于物理网格最上方 U 行，U 索引分别为 `nx_global/2` 和 `nx_global`；U 索引为 $i$ 与 `nx_global-i` 的点重合。设折叠线的全局 U 行索引为 $n$；其南侧 T 行的索引也为 $n$。逻辑网格中，折叠线以北还有虚拟的 T 行和 U 行。索引 $n+1$ 的虚拟 T 行中，索引 $i$ 的点与 T 行 $n$ 的 `nx_global-i+1` 点在物理上重合；虚拟 U 行 $n+1$ 与 U 行 $n-1$ 重合。下表中 A–H 代表给定 j 索引处从 1 到 `nx_global` 的网格点，示意折叠接缝附近的几行。

| 全局 j 索引 | 网格点 ID（i 索引） | 来源行 |
| --- | --- | --- |
| `ny_global+2` | H G F E D C B A | `ny_global-1` |
| `ny_global+1` | H G F E D C B A | `ny_global` |
| `ny_global` | A B C D E F G H | — |
| `ny_global-1` | A B C D E F G H | — |

在 T-fold 网格上，两极位于物理网格最上方 T 行，T 索引为 1 和 `nx_global/2+1`；T 索引为 $i$ 与 `nx_global-i+2` 的点重合。设折叠线的全局 T 行索引为 $n$。通常物理区域最北行是 U 行，但 T-fold 中 U 行 $n$ 位于折叠线“以外”；虽然它不是虚拟行，但与 U 行 $n-1$ 重合，并不具有独立的物理位置，因此须按虚拟行处理。U 行 $n$ 的 $i$ 点与 U 行 $n-1$ 的 `nx_global-i+1` 点重合。U 行 $n$ 以北仍有虚拟的 T、U 行 $n+1$：虚拟 T 行 $n+1$ 与 T 行 $n-1$ 重合，虚拟 U 行 $n+1$ 与 U 行 $n-2$ 重合。

| 全局 j 索引 | 网格点 ID（i 索引） | 来源行 |
| --- | --- | --- |
| `ny_global+2` | 空 H G F E D C B A | `ny_global-2` |
| `ny_global+1` | 空 H G F E D C B A | `ny_global-1` |
| `ny_global` | A BH CG DF E FD GC HB 空 | — |
| `ny_global-1` | A B C D E F G H 空 | — |
| `ny_global-2` | A B C D E F G H 空 | — |

因此，三极网格对某些行需要两类特殊处理，由晕区更新例程完成。第一，沿折叠线的重合点必须始终同值，通过成对平均实现。第二，虚拟行和 T-fold 上的“准虚拟”U 行的值，是物理重合行的镜像副本。两种操作都用三极缓冲区汇集受影响的行。分发例程也需特殊处理；全局求和时须排除每对重合点中的一个。代码支持中心、东、北和东北点的晕区，它们在三极接缝上的索引方式略有不同。

### 矩形网格

CICE 可定义内部生成的矩形测试网格。相关 namelist 设置包括 `grid_type='rectangular'`、`nx_global`、`ny_global`、`dx_rect`、`dy_rect`、`lonrefrect` 和 `latrefrect`。强迫和初始条件可由 `atm_data_type`、`ocn_data_type`、`ice_data_type`、`ice_data_conc`、`ice_data_dist` 设置。还可通过 `scale_dxdy` 启用变网格间距，用 `dxscale`、`dyscale` 设置缩放因子；取 1.0 时网格间距恒定。

矩形网格中，`lonrefrect`、`latrefrect` 定义左下角经纬度；`dx_rect`、`dy_rect` 定义基本间距；`dxscale`、`dyscale` 定义间距缩放。基本间距位于矩形区域中心，缩放因子沿 x、y 方向向外对称地逐次相乘。

CICE 通过 `cice.setup --grid` 提供 `gbox12`、`gbox80`、`gbox128`、`gbox180` 等预定义矩形网格；数字是各方向的单元数。`cice.setup --set` 还提供多种理想化盒式测试配置，包括 `box2001`、`boxadv`、`boxchan`、`boxchan1e`、`boxchan1n`、`boxnodyn`、`boxrestore`、`boxslotcyl`、`boxopen`、`boxclosed` 和 `boxforcee`。当前支持列表以 `cice.setup --help` 为准。

### 垂直网格

单个海冰柱或网格单元中的海冰物理过程位于 Icepack 子模块；Icepack 可独立于 CICE 运行。它包含物理过程使用的垂直网格，以及生物地球化学使用的“生物网格”（bio-grid），详见 Icepack 文档。单柱输出可用的历史变量包括冰温 `Tinz`、雪温 `Tsnz` 和海冰盐度剖面 `Sinz`；这些变量还以冰厚类别作为第四个维度。

### 边界条件

CICE 的许多基础设施（包括边界例程）沿用 POP。使用 MPI 时，边界例程负责处理器间通信；每个处理器有多个块时，也负责块间通信。

边界条件由 namelist 输入 `ns_boundary_type`、`ew_boundary_type` 定义，可取 `open`、`closed`、`cyclic`。`ns_boundary_type` 还可取 `tripole`、`tripoleT`。`closed` 在边界上施加两网格单元厚的陆地掩膜，仅支持矩形网格。一般而言，若边界为陆地，或边界上无冰，`boundary_type` 设置及边界条件不起作用。

在位移极点的全球网格中，掩膜（`kmt`）文件沿南北边界至少有一行陆地单元。东西方向的区域边界用周期条件环绕地球。此时适当的设置为 `ns_boundary_type='open'`、`ew_boundary_type='cyclic'`。

CICE 的区域网格可使用 `open`、`closed` 或 `cyclic` 边界条件。除描述网格长度的变量外，若边缘处有冰，非陆地的外侧晕区单元必须填入某种边界值。`closed` 或 `cyclic` 会自动处理外侧晕区。开放边界则可能采用多种方式，例如从外部文件读取值，或由内部解推导零梯度、常梯度、指定状态、零通量等边界值；但 CICE 当前不支持以数学方式直接指定这些边界条件。

`restore_ice` 可启用边界恢复（restoring）：把边界晕区设为从文件读取的值。可使用恢复时间尺度 `trestore`；在独立运行中，它也用于海表温度恢复。此实现仅为更复杂的边界处理提供接口。可用矩形网格选项测试该配置。使用恢复时，为获得精确重启，应在 namelist 中设置 `restart_ext=true`，使用扩展网格例程。

在三极网格上，折叠线两侧计算应力张量元素的运算顺序可能不同，导致舍入差异。虽然扩展网格例程可使同一次运行的重启精确，但与在其他时刻写重启文件的运行相比，解仍可能不同。因此，三极网格在动力学计算和重启过程中都显式更新应力张量的晕区。`tripoleT` 网格尚未实现此处理，仍待测试。

### 掩膜

陆地掩膜 `hm`（$M_h$）定义在 T 网格单元中心，0 为陆地，1 为海洋。U、N、E 网格的掩膜分别为：

$$
\begin{aligned}
M_u(i,j)&=\min\{M_h(l):l=(i,j),(i+1,j),(i,j+1),(i+1,j+1)\},\\
M_n(i,j)&=\min\{M_h(l):l=(i,j),(i,j+1)\},\\
M_e(i,j)&=\min\{M_h(l):l=(i,j),(i+1,j)\}.
\end{aligned}
$$

逻辑掩膜 `tmask`、`umask`、`nmask`、`emask` 分别对应实数掩膜 `hm`、`uvm`、`npm`、`epm`，适合在条件语句中使用。

除了陆地掩膜，`dyn_prep` 还建立两种掩膜，减少全球网格上的动力学计算量。每个时间步根据当前冰范围确定 `iceTmask` 和 `iceUmask`；有冰的位置为真，并为数值计算在冰盖周围额外包含一圈单元。动力学部分借此避免在无冰点上进行不必要的计算。热力学部分不使用这些掩膜，以便原本无冰的单元形成新冰。`iceTmask`、`iceUmask` 分别作用于 T、U 单元；使用 C 或 CD 网格时还定义 `iceEmask`、`iceNmask`。

通过 `maskhalo_bound`、`maskhalo_remap`、`maskhalo_dyn` 逻辑型 namelist 标志，可以分别在完整冰状态的边界更新、增量重映射输运、EVP/EAP 动力学中使用晕区掩膜，从而只通信包含所需信息的晕区单元，可能改善并行性能。

还为用户提供两个掩膜：`lmask_n`、`lmask_s` 可分别用于仅在北半球或南半球计算或写出数据。历史文件和诊断中以特殊常数 `spval`、`spval_dbl`（均为 $10^{30}$）标记陆地点。

## 网格间插值

CICE 的场通常定义在特定网格位置，如 T 单元中心、U 角点或 N/E 边缘；模式内部位置由 namelist 变量 `grid_ice` 指定。强迫／耦合场也关联一组网格位置，它们可以不同于 CICE 内部计算网格。`grid_atm`、`grid_ocn` 分别定义大气和海洋的强迫／耦合网格。`grid_ice`、`grid_atm`、`grid_ocn` 彼此独立，按 Arakawa 网格约定可取 `A`、`B`、`C` 或 `CD`。

| 网格系统 | 热力学网格 | u 动力学网格 | v 动力学网格 |
| --- | --- | --- | --- |
| A | T | T | T |
| B | T | U | U |
| C | T | E | N |
| CD | T | N+E | N+E |

所有系统中的模式热力学变量，以及强迫／耦合热力学场，都定义在 T 网格上；动力学 $u$、$v$ 场则随网格系统变化。CD 网格的 $u$、$v$ 场数量分别是其他网格的两倍。模式内部的 `grid_ice_thrm`、`grid_ice_dynu`、`grid_ice_dynv`、`grid_atm_thrm`、`grid_atm_dynu`、`grid_atm_dynv`、`grid_ocn_thrm`、`grid_ocn_dynu`、`grid_ocn_dynv` 是由上述三个 namelist 值推导的字符串，取 `T`、`U`、`N`、`E` 或 `NE`。

CICE 有多个内部方法，可将 `T`、`U`、`N`、`E`、`NE` 网格上的场插值（也称映射或平均）到 `T`、`U`、`N` 或 `E` 网格。若输入输出网格相同，结果只是复制场。通用接口为 `grid_average_X2Y`，有多种形式：

```fortran
subroutine grid_average_X2Y(type,work1,grid1,work2,grid2)
  character(len=*)    , intent(in)  :: type           ! 映射类型（S、A、F）
  real (kind=dbl_kind), intent(in)  :: work1(:,:,:)   ! 输入场
  character(len=*)    , intent(in)  :: grid1          ! work1 的网格（T、U、N、E）
  real (kind=dbl_kind), intent(out) :: work2(:,:,:)   ! 输出场
  character(len=*)    , intent(in)  :: grid2          ! work2 的网格（T、U、N、E）
```

输入输出场的数组形状为 `(nx_block, ny_block, max_blocks)`。`type` 可取：

- `S`：归一化、有掩膜、按面积加权的插值，$work2=\sum_i(M_{1i}A_{1i}work1_i)/\sum_i(M_{1i}A_{1i})$。
- `A`：归一化、无掩膜、按面积加权的插值，$work2=\sum_i(A_{1i}work1_i)/\sum_iA_{1i}$。
- `F`：归一化、无掩膜、守恒的通量插值，$work2=\sum_i(A_{1i}work1_i)/(nA_2)$。

其中 $A$ 为相应网格单元面积，$M$ 为掩膜。另一个接口形式为：

```fortran
subroutine grid_average_X2Y(type,work1,grid1,wght1,mask1,work2,grid2)
  character(len=*)    , intent(in)  :: type
  real (kind=dbl_kind), intent(in)  :: work1(:,:,:)
  real (kind=dbl_kind), intent(in)  :: wght1(:,:,:)   ! 输入权重
  real (kind=dbl_kind), intent(in)  :: mask1(:,:,:)   ! 输入掩膜
  character(len=*)    , intent(in)  :: grid1
  real (kind=dbl_kind), intent(out) :: work2(:,:,:)
  character(len=*)    , intent(in)  :: grid2
```

此形式在插值方程中用输入数组 `wght1`、`mask1` 代替网格单元面积和掩膜，使用户可显式指定权重与掩膜；仅支持 `S` 或 `A` 类型。最后一种形式为：

```fortran
subroutine grid_average_X2Y(type,work1a,grid1a,work1b,grid1b,work2,grid2)
  character(len=*)    , intent(in)  :: type
  real (kind=dbl_kind), intent(in)  :: work1a(:,:,:)
  character(len=*)    , intent(in)  :: grid1a         ! N 或 E
  real (kind=dbl_kind), intent(in)  :: work1b(:,:,:)
  character(len=*)    , intent(in)  :: grid1b         ! E 或 N
  real (kind=dbl_kind), intent(out) :: work2(:,:,:)
  character(len=*)    , intent(in)  :: grid2          ! T 或 U
```

这种形式支持从 `NE` 网格映射到 `T` 或 `U` 网格；`1a` 是 N 或 E 场，`1b` 是另一互补的 E 或 N 场。目前仅支持 `S` 类型。所有形式调用时，`work1`、`wght1`、`mask1` 输入数组的晕区值都应正确。以下示例使用有掩膜的面积加权平均，将 `uocn`、`vocn` 从其原生强迫／耦合网格映射到 U 网格：

```fortran
call grid_average_X2Y('S', uocn, grid_ocn_dynu, uocnU, 'U')
call grid_average_X2Y('S', vocn, grid_ocn_dynv, vocnU, 'U')
```

## 性能

`domain_nml` 的 namelist 选项允许灵活寻找高效的处理器和块配置。用户可控制块大小 `block_size_x`、`block_size_y`，分配类型 `distribution_type`，块工作量权重 `distribution_wght`，当分配类型为 `wghtfile` 时的 `distribution_wght_file`，以及当类型为 `cartesian` 时的 `processor_shape`。

用户在 `cice.settings` 中指定任务和线程总数，在 namelist 文件中指定块大小和分解方式。主要权衡是较大、近方形块的效率与模式内部负载均衡：无冰块的计算量很小。MPI 和 OpenMP 都按块并行。较小而数量更多的块，使每个处理器可同时分配有冰和无冰的块，改善负载均衡；但它们也增加晕区更新的 MPI 通信，降低效率。实际使用时，每个方向上的块边长最好不要少于约 8–10 个网格单元；近方形块的体积／表面积比通常更有利于降低通信成本。每个处理器有 3–8 个块，通常能提供足够灵活的分解以取得合理负载均衡。

与 MPI 一样，线程间块的负载均衡对性能很重要。多数 OpenMP 线程使用 `SCHEDULE(runtime)`，因此可用环境变量 `OMP_SCHEDULE` 设置运行时调度。`cice.settings` 中的 `ICE_OMPSCHE` 定义默认值；值得测试的取值包括 `STATIC,1` 和 `DYNAMIC,1`。CICE 的 OpenMP 实现仍在持续审查，用户应在自己的机器上验证结果和性能。改变块大小、分解方式、MPI 任务数和 OpenMP 线程数时，CICE 理应保持逐位一致。建议将 `OMP_STACKSIZE` 设为 32M 或更大。

`distribution_type` 支持标准笛卡尔块分配、通过“耙式”（rake）算法改善处理器间负载均衡的再分配，以及基于空间填充曲线（space-filling curve）的再分配。还提供 `roundrobin`、`sectrobin`、`sectcart`、`spiralcenter` 等其他分配类型，支持替代分解并使可用处理器数量更灵活。`wghtfile` 则根据输入文件中的权重生成分解。

![gx1 网格上 256 个块在 16 个处理器上的分配选项](../../source/user_guide/figures/distrb.png)

图中用颜色标示 gx1 网格上 256 个块如何分配到 16 个处理器：（a）`cartesian, slenderX1`；（b）`cartesian, slenderX2`；（c）`cartesian, square-ice`（此处 `square-pop` 等价）；（d）按块加权的 `rake`；（e）按纬度加权的 `rake`；（f）`spacecurve`。每块含 20×24 个网格单元，白色块完全由陆地单元构成。

![北极极区网格的分解示例](../../source/user_guide/figures/distrbB.png)

上图中（a）为 `spiralcenter` 分解，（b）为 `wghtfile` 分解，（c）为驱动（b）分解所用输入文件中的权重场。

`processor_shape` 与 `distribution_type='cartesian'` 一起使用，可将块按不同形状分组到处理器上，例如细长的处理器区域 `slenderX1`、`slenderX2`，或接近方形的 `square-pop`、`square-ice`。全球海冰模拟的大部分工作集中在网格顶部和底部，中间工作很少，因此细长布局通常较好。近方形区域可最大化面积与边界长度之比；若所有单元都有冰，也就最大化处理器内部计算相对消息传递的比例。若处理器数不是完全平方数（4、9、16 等），`processor_shape` 让用户选择排列方式。对海冰模式，x 方向的处理器数通常应多于 y 方向，例如 8 个处理器排成 4×2（`square-ice`）比 2×4（`square-pop`）更好。后者用于与默认采用此布局的 POP 直接通信兼容。

`distribution_wght` 指定每块工作量估计的权重方式。POP 默认的 `block` 选项让各块权重相同；POP 的每块总有工作量，且大量数组语法要求遍历整块，无论是否有陆地。CICE 提供该选项以兼容与 POP 的直接通信。`block` 会删除全陆地块；`blockfull` 与 `block` 相同，但不删除全陆地块；`blockall` 也不删除全陆地块，但给它们最低权重。`latitude` 根据纬度和块内海洋单元数加权。许多非笛卡尔分解会自动移除陆地块，无需 `distribution_wght`，并提供其他块分解方式。

`rake` 分配先按标准笛卡尔方式初始化，再依据每块工作量估计，将块沿 x、随后沿 y 方向“耙”到邻近处理器，改善处理器间的负载均衡。

空间填充曲线将多维空间（这里是二维）降为一维。曲线是一串块，按每个处理器的工作量切成若干段，再将每段放到一个处理器上，以优化负载均衡。使用此选项时，块大小必须使 x、y 方向的块数都可分解为 $2^n3^m5^p$，其中 $n,m,p$ 为整数。例如，16×16 个块、每块 20×24 个单元，正好填充 gx1 网格，此时 $n=4,m=p=0$。任一方向不满足此条件，`spacecurve` 分解就会失败。

笛卡尔分配将一组块交给同一处理器；`roundrobin` 则同时遍历块和处理器，轮流给每个处理器分配一个块直到分完。这样负载均衡较好，但邻居数量及通信数据量使通信特性较差。`sectrobin`、`sectcart` 也按类似方式遍历，但每次给处理器分配一组块以改善通信。`sectcart` 把区域分成东西、南北四个象限，依次在各象限遍历。

`wghtfile` 根据权重文件中的值分解。该文件应是 NetCDF 文件，包含名为 `wght` 的双精度实数场，给出每个网格单元的相对权重。前述北极极区图的（b）、（c）是示例。模式将单元权重按块求和，归一化为约 10 个等级，再按块权重从高到低分配到处理器。下图概括不同分配类型的优缺点。

![CICE 块分配方案评分卡](../../source/user_guide/figures/scorecard.png)

评分卡由 T. Craig 提供；更多信息见原文引用的 Craig 2014 及[演示文稿](http://www.cesm.ucar.edu/events/workshops/ws.2012/presentations/sewg/craig.pdf)。

Namelist 中的 `maskhalo` 选项通过避免在无冰区的不必要晕区通信改善性能。时间步推进中冰面积变化时，需要为晕区掩膜设置付出一定开销，但即使处理器数较少，通常也能缩短运行时间。T. Craig 发现，在 CESM 版 CICE 中结合更新后的分解和掩膜晕区，性能可提升超过 20%。

代码中许多 `(i,j)` 双层循环已合并为单个循环，且往往只遍历海洋单元或有冰单元，以减少无用操作并改善向量化性能。

下图展示 CICE v5 不同选项的计算开销，相对于一项 7 层配置的总时间（不包括初始化）。基准使用 BL99 热力学、EVP 动力学、gx1 网格上的 `ccsm3` 短波方案，从无冰初始条件运行一年；20×192 个块分布在 32 个处理器上（`slenderX2`），无线程，使用 `-O2` 优化。机器负载使完全相同配置的计时仍有约 ±3% 波动。示踪物的额外耗时包括输运该示踪物本身（平流、类别转换）和计算其专门过程两部分。年龄示踪物 FY、iage 几乎不需要额外专门计算，因此其耗时基本反映单纯增加一个示踪物的成本。地形融池方案略快，因为它每个单元只计算一次融池面积和体积，其他方案则按每个冰厚类别计算。

![CICE 选项的 TimeLoop 耗时变化](../../source/user_guide/figures/histograms.png)

图中浅灰色表示相同配置的约 ±3% 耗时差异，深灰色表示额外必需选项的耗时。所有融池方案和气溶胶示踪物都需要 Delta-Eddington 辐射方案；水平冰融池参数化还需要水平冰示踪物。

## 时间管理器与初始化

时间管理器是 CICE 模式的重要组成部分。

### 时间管理器

时间管理器的主要预报变量是整数 `myear`、`mmonth`、`mday`、`msec`，分别表示当前模式年、月、日及秒。模式时间步为 `dt`，单位为秒；选择方法见下文“选择合适的时间步”。内部变量 `istep`、`istep0`、`istep1` 记录时间步数。`istep` 是当前运行的计数器，每次运行开始时设为 0；`istep0` 是跨多次重启的长运行开始时的步数；`istep1` 是这类长运行的连续步数，跨模式重启保持连续。

一般应通过调用 `ice_calendar.F90` 中的 `advance_timestep` 推进时间管理器。它自动将模式时间推进 `dt`，更新各步数，并调用 `calendar` 更新其他日历数据。

Namelist 变量 `use_restart_time` 指定使用重启文件保存的时间和步数，还是使用 `year_init`、`month_init`、`day_init`、`sec_init` 指定的初始时间。初次运行通常设为假；在 `continue` 模式下该变量被忽略，始终用重启日期初始化。更多信息见下文“重启文件”。

支持的日历包括无闰年（noleap，每年 365 天）、360 天日历（每年 12 个 30 天月），以及向前延伸的公历（proleptic Gregorian）：每 4 年闰一次，但整百年不闰，整四百年又闰。向前延伸的公历在公历首次使用的 1582 年之前也沿用相同闰年规则，因此时间序列无不连续；见 [CF 约定](https://cfconventions.org/Data/cf-conventions/cf-conventions-1.12/cf-conventions.html#calendar)。在 namelist 中通过 `days_per_year`、`use_leap_years` 设置：

| `days_per_year` | `use_leap_years` | 日历 |
| --- | --- | --- |
| 365 | false | 无闰年 |
| 365 | true | 向前延伸的公历 |
| 360 | false | 360 天 |

历史和重启输出的频率在 namelist 中指定，并相对于 `histfreq_base`、`dumpfreq_base` 定义的参考日期计算。两者可取 `zero` 或 `init`。`zero` 以绝对参考日期 0000-01-01 为基准；这是 `histfreq_base` 默认值，因此不同初始日期的运行能产生相同输出时间安排。`init` 则以 `year_init`、`month_init`、`day_init` 定义的模式初始日期为基准；`sec_init` 不影响输出频率。`dumpfreq_base` 默认是 `init`，使测试中容易在开始后第 5 或第 10 个模式日生成重启文件。两个变量均为数组，可分别设置各输出流。

一般输出总在年、月、日或小时的开始时写出，不能任意调整相位。例如月输出总在每月 1 日，不能设置为每月 10 日；按 12–2 月或 1–3 月等不同季度划分，也不容易直接控制。更好的方法是先生成月数据，再在后处理中汇总为季度。历史与重启频率 `histfreq`、`dumpfreq` 的字符取值 `'1'` 表示每若干时间步输出；它是字符 `1`，不是整数 1。此频率依据连续的 `istep1` 计算，可能随时间步长、初始日期、`istep0` 等因素而变化。

模式年份受 `ice_calendar.F90` 中计算累计小时数所用的整数数学限制，上限为该文件中的 `myear_max`，目前为 200,000 年。

时间管理器在 2021 年初更新。独立模式已经修改；高层耦合接口修改后，也在耦合框架中做过一些测试。某些耦合模式升级到新时间管理器时，可能还需更新耦合接口。旧的预报变量 `time` 已不存在；`year_init` 只定义初始年份；`calendar` 子程序不再接受参数。可结合 `days_per_year`、`use_leap_years` 设置 `year_init`、`month_init`、`day_init`、`sec_init`、`dt`，初始化日期、时间步和日历。若要在耦合层覆盖默认值或 namelist 值，应在读取 namelist 后设置 `ice_calendar.F90` 中的 `myear`、`mmonth`、`mday`、`msec`、`dt`，随后调用 `calendar` 更新全部日历数据。最后使用 `advance_timestep` 推进时间管理器；它更新步数、按 `dt` 推进时间并刷新日历数据。旧的手动增加步数、把 `dt` 加到 `time` 的方法应弃用。

### 初始化与重启

海冰模式的参数和变量分多步初始化。许多常量和物理参数在 `ice_constants.F90` 中设置。可在运行时更改的 namelist 变量由 `input_data` 及其他初始化例程处理：代码先给出默认值，读取 `ice_in` 时再覆盖。其他物理常数、数值参数和变量先由各组件或模块的初始化例程设置。若从先前运行重启，核心变量由 `restartfile` 读取并重新初始化；特定配置所需的示踪物变量由对应示踪物或专门参数化的重启例程分别读取。最后设置反照率等依赖初始冰状态的量。部分参数详见[案例设置与 namelist](ug_case_settings.md)。

代码发行版附带的重启文件包含默认配置的核心变量，即七个垂直层、`kcatbound=0` 定义的冰厚分布。NetCDF 重启文件还包含部分示踪物的重启信息。

通常由 `runtype`、`ice_ic`、`use_restart_time` 三个 namelist 变量控制初始化。`runtype` 可取 `initial` 或 `continue`。`continue` 时，重启文件名保存在小型文本指针文件中，`use_restart_time` 强制为真，`ice_ic` 不起作用。`initial` 时，`ice_ic` 可取 `none`、`internal` 或文件名，分别表示无冰、由 namelist 驱动的初始条件和文件指定的冰状态。`ice_ic='internal'` 时，初始状态由 `ice_data_type`、`ice_data_dist`、`ice_data_conc` 定义。`initial` 模式下通常应设 `use_restart_time=false`，由 `year_init`、`month_init`、`day_init`、`sec_init` 指定初始时间。

重启文件与初始条件文件通常采用相同格式，也可以是同一个文件。它们保存某一时刻的模式状态，包括物理和动力学状态及可选示踪物状态。各示踪物组是否读取可由不同重启标志独立控制。因此，重启文件可用于初始化启用了新示踪物（例如生物地球化学）的新配置：读取已有物理状态，文件中没有的生物地球化学示踪物则重新初始化。

在 `continue` 模式中，CICE 会把最近一次重启文件名写入运行目录中的小型文本指针文件。重启时先读取指针文件，再读取它指向的重启文件。这样无需不断更新海冰 namelist 中的文件名，也便于自动重新提交运行。在运行中途手动编辑指针文件，可重设要读取的重启文件名。

| `runtype` | `ice_ic` | `use_restart_time` | 初始化方式 |
| --- | --- | --- | --- |
| `initial` | `none` | 不使用 | 无冰；起始日期由 namelist 指定 |
| `initial` | `internal` 或 `default` | 不使用 | 由 `ice_data_type`、`ice_data_dist`、`ice_data_conc` 设置 |
| `initial` | 文件名 | false | 从文件读冰状态；起始日期由 namelist 指定 |
| `initial` | 文件名 | true | 从文件读冰状态；起始日期由重启文件指定 |
| `continue` | 不使用 | 不使用 | 指针文件指定重启文件，重启文件指定起始日期 |

另一个 namelist 选项 `restart_ext` 指定重启文件是否包含晕区单元；它对三极和区域网格有用，但不能与 PIO 同用。`restart_coszen` 指定重启文件是否包含天顶角余弦，主要用于耦合模式。

对耦合和独立运行的 MPI 模式，MPI 都在 `init_communicate` 中初始化。海冰组件通过外部例程与通量耦合器或其他气候组件通信，交换的变量见 [Icepack 文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)。独立运行时，`ice_forcing.F90` 中的例程从文件读取并插值数据；这些例程主要用于指导用户编写自己的代码。编译时决定使用独立运行还是耦合模式，见后文说明。

### 选择合适的时间步

时间步长的选择取决于输运部分（水平和厚度空间）的稳定性，以及对物理强迫变化的分辨能力。CICE 允许动力学、平流和压力脊化部分使用比热力学时间步 $\Delta t$（`dt`）更短的 $\Delta t_{dyn}$（`dt_dyn`）。此时指定 `dt` 与整数 `ndtd`，并有 `dt_dyn=dt/ndtd`。

对重映射方案，水平输运时间步上限（CFL 条件）的保守估计是：

$$
\Delta t_{dyn}<\frac{\min(\Delta x,\Delta y)}{2\max(u,v)}.
$$

假设 $\max(u,v)=0.5$ m/s，几个 POP 网格的数值估计如下：

| 网格 | 北方极点奇点位置 | 维度 | 最小 $\sqrt{\Delta x\Delta y}$ | 最大 $\Delta t_{dyn}$ |
| --- | --- | --- | --- | --- |
| gx3 | 格陵兰 | $100\times116$ | $39\times10^3$ m | 10.8 h |
| gx1 | 格陵兰 | $320\times384$ | $18\times10^3$ m | 5.0 h |
| p4 | 加拿大 | $900\times600$ | $6.5\times10^3$ m | 1.8 h |

原文所引 Lipscomb 2007 指出，实践中的最大时间步通常取决于冰强度发生大变化的时间尺度，这又部分取决于风力。假设 $\Delta x=10$ km，采用 Rothrock 1975 的强度参数化时，旧压力脊方案 `krdg_partic=0` 的时间步限制约为 30 分钟，新方案 `krdg_partic=1` 约为 2 小时。实际限制还可能因大气风力而更严。

厚度空间输运也带来类似限制，由冰生长／融化速率和类别之间最小厚度范围决定：$\Delta t<\min(\Delta H)/(2\max(f))$，其中 $\Delta H$ 为类别边界间距，$f$ 为热力学生长速率。对本发行版默认的五类别冰厚分布，这一限制并不严格：假设 $\max(f)=40$ cm/day，则 $\Delta t<19.4$ h。

使用经典 EVP 或 EAP（`kdyn=1` 或 `2` 且 `revised_evp=false`）时，动力学每个动力学时间步子循环 `ndte`（$N$）次，使弹性波在下一时间步之前基本消失。子循环时间步为 `dte=dt_dyn/ndte`。另一个参数 $E_\circ$（`elasticDamp`）定义弹性波阻尼时间尺度 $T=\texttt{elasticDamp}\times\texttt{dt\_dyn}$，见[动力学](../science_guide/sg_dynamics.md)。子循环期间强迫项不更新。

EVP 动力学的子步 `dte` 很小，但弹性参数 $E$ 仍受稳定性条件限制（见原文引用 Hunke 1997）。线性稳定性分析表明，只要子循环步 $\Delta t_e$ 足够精细地解析阻尼时间尺度 $T$，数值方法就稳定；由于分析中作了多项简化，稳定与不稳定区域的边界仅是估计。目前 EVP、EAP 的默认参数为 `ndte=240`、$E_\circ=0.36$。高分辨率应用建议提高 `ndte`（原文引用 Koldunov 2019、Bouchat 2022）。

注意，动力学部分的稳定性只直接涉及 $T$ 和 $\Delta t_e$，不涉及 $\Delta t$。尽管稳定性可能不严格限制大时间步，过大的时间步（例如日强迫下 $\Delta t=1$ 天）仍无法得到准确的动力学结果；原因与影响见原文引用的 Hunke 1997、Hunke 1999。只要表面温度 $T_{sfc}$ 在模式内部计算，热力学部分对任何时间步均稳定；热力学时间步的数值限制主要来自输运方案，而非热力求解器。

修订版 EVP（`kdyn=1` 且 `revised_evp=true`）中，弛豫参数 `arlx1i` 实际设置问题中的阻尼时间尺度，`brlx` 表示有效子循环（原文引用 Bouillon 2013；见[修订版 EVP](../science_guide/sg_dynamics.md#修订版-evp-方法)）。

## 模式输入与输出

### I/O 概述

CICE 可通过多种方法读写无格式二进制数据或 NetCDF 数据。I/O 实现同时在构建时（选择特定源代码）和运行时（namelist）指定。`cicecore/cicedyn/infrastructure/io/` 下有 `io_binary`、`io_netcdf`、`io_pio2` 三个包，分别通过二进制、[NetCDF](https://www.unidata.ucar.edu/software/netcdf) 和 [PIO](https://github.com/NCAR/ParallelIO) 接口提供 I/O。`io_pio2` 同时支持 PIO1 和 PIO2，可以通过 NetCDF 或并行 NetCDF（PnetCDF）接口写数据。NetCDF 历史文件符合 CF 约定；`ncdump -h filename.nc` 可查看文件头中的数据说明。在 `cice.settings` 中将 `ICE_IOTYPE` 设为 `binary`、`netcdf`、`pio1` 或 `pio2`，以选择 I/O 源代码。

运行时还有更细的设置。`restart_format`、`history_format` 指定方法和格式，取值见下表。它们控制 CICE 新建文件的格式；只要与构建时的 `ICE_IOTYPE` 一致，已有文件可以按任意相容格式读取。`ICE_IOTYPE=binary` 时，格式名实际上被忽略。CICE NetCDF 输出的全局元数据属性 `io_flavor` 表示文件选择的格式；`ncdump -k filename.nc` 也可查看具体 NetCDF 格式。输入文件通常不强制要求与 namelist 中的详细格式匹配，因此无论 CICE namelist 如何设置，均可读取各类 NetCDF 格式。

| Namelist 格式选项 | 格式 | 写入接口 | 适用的 `ICE_IOTYPE` |
| --- | --- | --- | --- |
| `binary` | Fortran 二进制 | Fortran | `binary` |
| `cdf1` | NetCDF3 classic | NetCDF | `netcdf`, `pio1`, `pio2` |
| `cdf2` | NetCDF3 64-bit offset | NetCDF | `netcdf`, `pio1`, `pio2` |
| `cdf5` | NetCDF3 64-bit data | NetCDF | `netcdf`, `pio1`, `pio2` |
| `default` | 二进制或 `cdf1`，取决于 `ICE_IOTYPE` | 随配置而异 | `binary`, `netcdf`, `pio1`, `pio2` |
| `hdf5` | NetCDF4 HDF5 | NetCDF | `netcdf`, `pio1`, `pio2` |
| `pnetcdf1` | NetCDF3 classic | PnetCDF | `pio1`, `pio2` |
| `pnetcdf2` | NetCDF3 64-bit offset | PnetCDF | `pio1`, `pio2` |
| `pnetcdf5` | NetCDF3 64-bit data | PnetCDF | `pio1`, `pio2` |

还有影响重启和历史输出 PIO 性能的 namelist 选项。`history_`／`restart_` 前缀与 `iotasks`、`root`、`stride` 组合，分别控制 I/O 任务总数、根 I/O 任务和任务步长。`history_rearranger`、`restart_rearranger` 定义 PIO 数据重排策略。`history_`／`restart_` 前缀与 `deflate`、`chunksize` 组合，控制 NetCDF 和 PIO 输出中 `hdf5` 选项的压缩与分块。CICE 通过 NetCDF 库串行写 `hdf5`，通过 PIO 库并行写。详情见 [NetCDF](https://www.unidata.ucar.edu/software/netcdf) 和 [PIO](https://github.com/NCAR/ParallelIO) 文档。

使用 NetCDF 需在构建 CICE 时链接外部构建的 NetCDF 库；使用 PIO 还需外部构建的 PIO 库。两库的构建选项可能进一步依赖 MPI、HDF5、PnetCDF 等库。若 NetCDF 库未构建 `cdf2`、`cdf5` 或 `hdf5` 支持，可按需在机器 `Macros` 文件中显式加入 CPP 宏 `NO_CDF2`、`NO_CDF5`、`NO_HDF5`，关闭对应功能。

### 历史文件

如上所述，CICE 可通过二进制、NetCDF 或 PIO 接口以无格式二进制或 NetCDF 输出历史数据。`history_format` 及其他历史 namelist 选项控制文件格式和 I/O 性能。

数据按 `histfreq`、`histfreq_n` 指定的时段写出，以 `histfreq_base` 给出的日期为参考。输出到二进制或 NetCDF 文件，文件名前缀由 `history_file`、`history_suffix` 指定。这些设置在 `ice_in` 的 `setup_nml` 中。文件名大体形式为 `[history_file][history_suffix][_freq].[timeID].[nc,da]`，取决于具体选项。二进制文件另附一个包含等价信息的头文件。标准字段按 `ice_in` 的 `icefields_nml` 设置输出。若要添加或删除 namelist 尚未提供的变量，见[添加历史输出字段](../developer_guide/dg_other.md#添加历史输出字段)。

历史输出实现按格式和变量分为多个模块。跨模块共享的参数、变量及例程位于 `ice_history_shared.F90`；初始化和累加全部历史变量的主要例程位于 `ice_history.F90`，再调用 `io_binary`、`io_netcdf`、`io_pio2` 中的格式专用代码。特定组件或参数化的历史变量分别放在 `ice_history_bgc.F90`、`ice_history_drag.F90`、`ice_history_mechred.F90`、`ice_history_pond.F90` 中。

历史模块可同时使用 `histfreq` 的六种输出频率标识：`'1'`、`'h'`、`'d'`、`'m'`、`'y'`、`'n'`。每个流的 `histfreq` 必须唯一，例如两个流不能都使用 `'d'`。每个流的实际频率由 `histfreq_n` 指定，并相对于相应的 `histfreq_base` 日期计算。各流可以输出瞬时值，也可以在该间隔内做时间平均；`hist_avg` 分别控制每个流的时间平均。一个模式变量可通过其 `f_<var>` namelist 标志写入多个流，例如日 `'d'` 和月 `'m'`；`'x'` 关闭该变量。`f_aice='md'` 会把 `aice` 写入月和日流。网格变量的历史输出标志是逻辑型，开启后写入所有流。

若某一 `histfreq` 值没有任何变量标志使用，或对应 `histfreq_n` 元素为 0，该频率不会写文件。历史文件名由 `ice_history_shared.F90` 的 `construct_filename` 构造。如果两个流生成相同文件名，模式会中止；可用 `hist_suffix` 使其唯一。频率计算见上文“时间管理器”。部分地球系统模式还要求历史文件时间轴位于平均时段中心，`hist_time_axis` 可选择时间戳位于 `begin`、`middle` 或 `end`。

例如：

```fortran
histfreq   = '1', 'h', 'd', 'm', 'y'
histfreq_n =  1 ,  6 ,  0 ,  1 ,  1
histfreq_base = 'zero','zero','zero','zero','zero'
hist_avg      = .true.,.true.,.true.,.true.,.true.
f_hi = '1'
f_hs = 'h'
f_Tsfc = 'd'
f_aice = 'm'
f_meltb = 'mh'
f_iage = 'x'
```

此时 `hi` 每个时间步写一次，`hs` 每 6 小时一次，`aice` 每月一次，`meltb` 每月及每 6 小时各一次。`Tsfc` 不写出，因为日流的 `histfreq_n=0`；`iage` 因标志 `'x'` 不写出。所有流都在间隔内时间平均，但 `histfreq='1'`、`histfreq_n=1` 的流相当于每个模式时间步输出瞬时值。

从效率考虑，未使用的 `histfreq` 应设为 `'x'`。五种频率全部输出所需时间接近单频率的五倍。若只要月输出，最高效的设置是 `histfreq='m','x','x','x','x'`。代码根据 `histfreq` 计算所需流数 `nstreams`。

原文此处指出，历史输出的累加数据不一定随普通模式重启保存：如果模式在历史累加时段中途停止，重新启动时累加可能归零。因此应协调重启输出频率和历史输出频率，例如需要月历史文件时，将重启间隔设为整数个月。下文“历史重启文件”介绍了另行提供的历史累加状态重启能力。

NetCDF 中的历史变量名必须唯一。若同一变量输出到多个频率的流，在第一个流以外的文件中会在变量名后加频率。上例的 `meltb` 在月文件中仍叫 `meltb`，以兼容默认配置；在 6 小时文件中叫 `meltb_h`。

若 `ice_in` 中 `write_ic=true`，运行开始时会把同一组历史场的快照写入历史目录，文件名为 `iceh_ic.[timeID].nc(da)`。若干历史变量被硬编码为瞬时输出，不受 `hist_avg` 影响，但输出频率仍由各自 namelist 标志指定。

`grid_outfile=true` 可在开始运行时一次性把所有网格变量写入历史文件。只写尚未被分解过程剔除的块。若要生成不删除陆地块的一次性网格文件，可设 `distribution_wght='blockall'`、`grid_outfile=.true.`。

内部冰应力归一化主分量 `sig1`、`sig2` 在 `principal_stress` 中计算并写入历史文件。模拟本身不需要该计算；它们仅为用户方便而提供的诊断量。

若干历史变量有两种形式：一种是网格单元海冰部分的平均，另一种再乘以冰面积分数 $a_i$，表示整个网格单元面积上的平均。后者的变量名按约定加 `_ai` 后缀。

历史文件中的变量单位可能不同于模式内部单位。NetCDF 文件的变量单位写在元数据中。`define_hist_field` 子程序中的 `cona`、`conb` 参数负责将内部单位转换为历史文件单位，分别是硬编码的乘法项和加法项。

从 CICE v6 起，可输出海冰模式比较项目（Sea Ice Model Intercomparison Project，SIMIP）要求的历史变量，例如 `f_sithick`、`f_sidmassgrowthbottom`。所要求的[月变量](http://clipc-services.ceda.ac.uk/dreq/u/MIPtable::SImon.html)和[日变量](http://clipc-services.ceda.ac.uk/dreq/u/MIPtable::SIday.html)列表给出了 CICE 中的历史场名。所有 SIMIP 变量已按新的 [CMIP7 数据请求](https://wcrp-cmip.org/cmip7-data-request-v1-0/) 更新。

`f_CMIP` 标志已移除，改为 `set_nml.cmip` namelist 选项，可在 `cice.setup` 时通过 `-s cmip` 启用。该选项会打开 CMIP 数据请求变量，并关闭 CICE 中与 SIMIP 变量重复的输出；用户仍可在案例的 `ice_in` 中修改。部分 SIMIP 变量需除以冰面积或冰下区域面积；这些面积可能极小，使输出值看似不符合物理。解释 `sithick` 等变量时须特别谨慎；未来版本计划提供对这些区域加掩膜的选项。

调试时可以通过 namelist 标志 `history_precision` 将历史输出精度由 4 字节提高到 8 字节。地形融池（topo ponds）方案的 `dpnd` 融池历史场尚未实现，代码中保持关闭。

### 历史重启文件

CICE 支持历史累加状态的重启。若写重启文件时历史场仍在累加，会同时把各历史流已累加的数据分别写入重启目录，每个流一个文件。文件名以历史文件名为基础，加 `_r`、`histfreq` 字符串和模式时间。只有 `hist_avg=.true.` 且写出时累加计数大于零的流才写文件；只写该流正在累加的数据。设 `write_histrest=.false.` 可关闭此功能。

重启时，CICE 查找并读取适当的历史重启文件。若文件不存在或某些场无法读取，模式继续运行，相应历史累加器置零。日志会指出哪些文件和字段读取成功。在历史流设置保持不变的生产运行中，这应实现历史输出的逐位一致重启。若更改历史流输出，CICE 只读取已有的文件和字段；新字段的累加从零开始，其累加计数也可能不正确。

预设选项 `histall10d` 为所有历史变量指定 10 天和月平均历史流。相关测试脚本比较连续运行与重启运行生成的历史及历史重启输出，以验证逐位一致性。

### 诊断文件

与 `histfreq` 类似，`diagfreq` 控制向日志写入诊断的频率。诊断输出的文件单元在 `ice_fileunits.F90` 中设置。若 `diag_type='stdout'`，输出到标准输出；如果像 `cice.run` 一样重定向标准输出，则写入 `ice.log.[ID]`。否则写入 `diag_file` 指定的文件。

标准诊断包括最大面积平均厚度、速度、平均反照率、总冰面积、总冰雪体积。`print_points`、`print_global` 会计算并写入附加信息。`print_global` 输出全局求和，可检查质量和能量的全局守恒。`print_points` 输出由 namelist 中 `lonpnt`、`latpnt` 定义的两个网格点；默认一点在北极附近，另一点在威德尔海，可在 `ice_in` 中更改。

`debug_model` 在模式推进时对单个点输出详细调试诊断。点由 `debug_model_i`、`debug_model_j`、`debug_model_iblk`、`debug_model_task` 定义，分别是局部 i、j、块和 MPI 任务索引；它按局部索引指定，也可位于数组晕区。若 namelist 未指定局部点，则使用 `lonpnt(1)`、`latpnt(1)` 对应的点。模式中止时，通常用它对发生问题的网格点做细致调试。

逻辑型 namelist `memory_stats` 控制内存使用诊断；该功能调用 `ice_memusage_gptl.c` 中的 C 语言内在查询，按 `diagfreq` 频率写出内存诊断。

计时器在 `ice_timers.F90` 中声明和初始化，待计时代码段前后分别调用 `ice_timer_start`、`ice_timer_stop`，最后由 `ice_timer_print` 写结果到日志。可选的 `stats` 参数（真／假）输出更多统计量，可由 namelist `timer_stats` 设置。调用 `ice_timer_print_all` 可一次输出全部计时器，而不必逐个调用。添加计时器的方法见[开发者指南](../developer_guide/dg_other.md#添加计时器)。

计时器统计的时段不一定互斥。例如 `Column` 包含若干其他计时器的时间，`Bound` 从动力学、平流等多处调用。`Dynamics`、`Advection`、`Column` 三者互不重叠，覆盖大部分模式工作。并行运行时使用 `MPI_WTIME` 计时，单处理器运行时使用 Fortran 90 内在函数 `system_clock`。

| 索引 | 标签 | 计时范围 |
| --- | --- | --- |
| 1 | `Total` | 整次运行 |
| 2 | `Timeloop` | 总运行减去初始化和退出 |
| 3 | `Dynamics` | 动力学 |
| 4 | `Advection` | 水平输运 |
| 5 | `Column` | 全部垂直（单柱）过程 |
| 6 | `Thermo` | 垂直热力学，属于 `Column` |
| 7 | `Shortwave` | 短波辐射和反照率，属于 `Thermo` |
| 8 | `Ridging` | 力学再分配，属于 `Column` |
| 9 | `FloeSize` | 冰块尺寸，属于 `Column` |
| 10 | `Coupling` | 发送和接收耦合器消息 |
| 11 | `ReadWrite` | 文件读写 |
| 12 | `Diags` | 诊断日志 |
| 13 | `History` | 历史输出 |
| 14 | `Bound` | 边界条件与子区域通信 |
| 15 | `BundBound` | 晕区更新包复制 |
| 16 | `BGC` | 生物地球化学，属于 `Thermo` |
| 17 | `Forcing` | 强迫 |
| 18 | `1d-evp` | 一维 EVP，属于 `Dynamics` |
| 19 | `2d-evp` | 二维 EVP，属于 `Dynamics` |
| 20 | `UpdState` | 更新状态 |

### 重启文件

CICE 通过前述二进制、NetCDF、PIO 的不同实现，以无格式二进制或 NetCDF 格式读写重启数据。`restart_format` 及其他重启 namelist 选项控制格式与 I/O 性能。

CICE 创建的重启文件包含完整且精确重启所需的全部变量。文件名以 `restart_file` 指定的字符串开头；写出频率由 `dumpfreq`、`dumpfreq_n` 相对于 `dumpfreq_base` 定义。代码支持多个重启频率，机制与历史流类似。续跑时，`pointer_file` 指向待读取重启文件。代码假定辅助二进制示踪物重启文件使用同一指针和文件名前缀，但在文件名中另加各示踪物组对应的字符串。NetCDF 重启文件则包含全部变量。

其他 namelist 标志进一步控制重启行为。`dump_last=true` 使模式在运行结束时写一组重启文件，即使原定频率不在该时刻写出。`use_restart_time` 让用户在初始运行时选择是否使用重启文件中的模式日期；若为假，初始日期由 `year_init`、`month_init`、`day_init`、`sec_init` 决定。`lcdf64=true` 选择 64 位 NetCDF 输出，允许较大的文件。

扩展全局网格（包括物理区域及外侧虚拟／晕区单元）的汇集、分发及无格式读写例程，使开放边界的区域网格能够精确重启，也简化各类三极网格的重启。通过 `restart_ext=true` 启用。PIO 不支持扩展网格重启；此时会用额外晕区更新填充三极网格的虚拟单元。区域网格不应使用 PIO。

CICE 代码发行版提供 gx3、gx1 网格的重启文件（获取方法见[强迫数据](ug_running.md#强迫数据)）。这些文件使用默认配置，在 JRA55 强迫下运行多年生成。

原文：[ug_implementation.rst](../../source/user_guide/ug_implementation.rst)
