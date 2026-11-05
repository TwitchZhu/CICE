# 主要变量和参数索引

此索引定义 CICE 模型代码中常用的许多符号，但并非穷尽。代码中所有量使用 MKS 单位制（温度可为摄氏或开尔文）；此处单位是模型内部定义，历史文件单位可能不同，以文件元数据为准。已弃用的参数列在末尾。namelist 变量只收录一部分，完整说明见[案例设置和 namelist](user_guide/ug_case_settings.md)。

## A

| 符号 | 含义 | 值／单位 |
| --- | --- | --- |
| `a11,a12` | 结构张量分量（structure tensor components） | |
| `a2D`、`a3Dz`、`a3Db`、`a3Dc`、`a3Df` | 历史场累积量，分别为二维、三维垂向、三维生物网格、三维厚度类别、三维浮冰尺寸分布（FSD） | |
| `a4Di`、`a4Db`、`a4Ds`、`a4Df` | 四维历史场累积量，分别为厚度类别×垂向海冰、生物网格、垂向积雪、FSD | |
| `a_rapid_mode` | 盐水通道直径 | |
| `add_mpi_barriers` | 打开 MPI 屏障以限制通信 | |
| `advection` | 平流算法类型 `remap/upwind` | `remap` |
| `afsd(n)` | 类别 n 的浮冰尺寸分布 | |
| `ahmax` | 高于此厚度时海冰反照率恒定 | 0.3 m |
| `aice_extmin` | 冰范围诊断的最小浓度 | 0.15 |
| `aice_init` | 时间步起点的冰浓度 | |
| `aice0` | 开阔水域面积比例 | |
| `aice(n)` | 网格内 n 类海冰总浓度 | |
| `albedo_type` | 反照率参数化类型 `ccsm3/constant` | |
| `albcnt` | 反照率平均计数器 | |
| `albice`、`albocn`、`albpnd`、`albsno` | 裸冰、海洋、融池、积雪反照率 | `albocn=0.06` |
| `albicei`、`albicev` | 厚冰近红外、可见光反照率 | |
| `albsnowi`、`albsnowv` | 冷雪近红外、可见光反照率 | |
| `algalN` | 藻类氮浓度 | mmol/m³ |
| `alv(n)dr(f)` | 可见光／近红外、直射／漫射反照率 | |
| `alv(n)dr(f)_ai` | 上述反照率的网格盒平均值 | |
| `amm` | 氨／铵浓度 | mmol/m³ |
| `ANGLE`、`ANGLET` | POP 网格与经纬网格转换的角度；后者转换至 T 单元 | 弧度 |
| `aparticn` | 参与函数 | |
| `apeff_ai` | 网格平均有效融池比例 | |
| `apnd_sl` | 海平面融池的平衡比例 | |
| `apondn` | 融池面积浓度 | |
| `arlx1i` | 动力学应力松弛常数 | |
| `araftn` | 筏化冰面积比例 | |
| `aredistrn` | 再分配函数：新脊面积比例 | |
| `ardgn` | 脊冰面积比例 | |
| `aspect_rapid_mode` | 盐水对流纵横比 | 1 |
| `astar` | 参与函数的 e 倍尺度 | 0.05 |
| `atmiter_conv` | 摩擦速度 `ustar` 的收敛准则 | 0.00 |
| `atm_data_dir`、`atm_data_format`、`atm_data_type` | 大气强迫数据目录、文件格式、类型 | |
| `atmbndy` | 大气边界层参数化 `similarity/constant/mixed` | |
| `avail_hist_fields` | 历史场数据类型 | |
| `awtidf`、`awtidr`、`awtvdf`、`awtvdr` | 近红外漫射、近红外直射、可见光漫射、可见光直射反照率的权重 | 0.36218、0.00182、0.63282、0.00318 |

## B

| 符号 | 含义 | 值／单位 |
| --- | --- | --- |
| `bfbflag` | 控制诊断的逐位可重现性及 VP 求解器输出的可重现性 | |
| `bgc_data_dir`、`bgc_data_type` | BGC 数据目录；硅酸盐、硝酸盐数据源 | |
| `bgc_flux_type`、`bgc_tracer_type` | 冰洋通量速度；BGC 示踪物类型 | |
| `bgrid` | 生物网格的无量纲垂向网格点 | |
| `bignum` | 大数 | $10^{30}$ |
| `block`、`block_id` | 块数据类型；全局块编号 | |
| `block_size_x(y)` | 块沿 x（y）方向的单元数 | |
| `blockGlobalID`、`blockLocalID`、`blockLocation`、`blocks_ice` | 全局块编号、局部块编号、块所在处理器、局部海冰块编号 | |
| `bphi`、`bTiz` | 生物网格上冰层的孔隙度、温度 | |
| `brlx` | 动力学动量松弛常数 | |

## C

| 符号 | 含义 | 值／单位 |
| --- | --- | --- |
| `c<n>` | `real(n)` 类型 | |
| `rotate_wind` | 为真时将风／风应力分量旋转至计算网格 | 真 |
| `calc_dragio`、`calc_strair`、`calc_Tsfc` | 为真时分别计算冰洋阻力系数、风应力、表面温度 | 假、真、真 |
| `capping`、`capping_method` | 黏度上限方法的参数与 namelist 方法 | 1.0、`hibler` |
| `Cdn_atm`、`Cdn_ocn` | 大气、海洋阻力系数 | |
| `Cf` | 脊化功与势能变化之比 | 17 |
| `cgrid` | 冰网格垂向点，与 `bgrid` 比较 | |
| `char_len`、`char_len_long` | 普通、较长字符变量长度 | 80、256 |
| `check_step`、`check_umax` | 开始写调试数据的时间步；是否检查冰速超过 `umax_stab` | |
| `cldf` | 云量比例 | |
| `cm_to_m` | 厘米到米换算系数 | 0.01 |
| `coldice`、`coldsnow` | 常数反照率参数化中的冰、雪值 | 0.70、0.81 |
| `cona`、`conb` | 历史文件单位转换的乘法项、加法项 | 1.0、0.0 |
| `conduct` | 热导率参数化 | |
| `congel` | 底部海冰生长 | m |
| `conserv_check` | 为真时检查守恒 | |
| `cosw`、`coszen` | 水中转向角余弦；太阳天顶角余弦 | `cosw=1` |
| `Cp` | 势能比例常数 | kg/m²/s² |
| `cpl_frazil` | 冰晶冰耦合类型 | |
| `cp_air`、`cp_ice`、`cp_ocn`、`cp_wv` | 空气、淡水冰、海水、水汽比热 | 1005、2106、4218、1810 J/kg/K |
| `cp063`、`cp455` | 上方、下方漫射 Fresnel 反射率 | 0.063、0.455 |
| `Cs` | 对脊化有贡献的剪切能比例 | 0.25 |
| `Cstar` | Hibler 冰强度公式常数 | 20 |
| `cxm`、`cxp`、`cym`、`cyp` | HTN 与 HTE 值的组合 | |

## D

| 符号 | 含义 | 值／单位 |
| --- | --- | --- |
| `d_afsd_[proc]` | 各过程引起的 FSD 变化 | |
| `daice_da` | 数据同化的浓度增量率 | |
| `daidtd`、`daidtt` | 动力学／输运及热力学导致的冰面积变化率 | 1/s |
| `dalb_mlt`、`dalb_mlti`、`dalb_mltv` | 见 `icepack_shortwave.F90` | -0.075、-0.100、-0.150 |
| `darcy_V` | 盐水高度示踪物所用 Darcy 速度 | |
| `dardg1(n)dt`、`dardg2(n)dt` | n 类脊化冰损失的面积比例率；新冰脊增加率 | 1/s |
| `daymo`、`daycal` | 每月天数；月底对应的日编号 | |
| `days_per_year`、`day_init` | 每年天数；初始月中的日 | 365、— |
| `dbl_kind` | 双精度定义 | `selected_real_kind(13)` |
| `debug_blocks`、`debug_forcing` | 块／分解、强迫输入的额外诊断 | `.false.` |
| `debug_model` | 扩展模型点调试开关 | |
| `debug_model_i`、`debug_model_j`、`debug_model_iblk`、`debug_model_task`、`debug_model_step` | 调试点局部 i、j、块号、MPI 任务号与开始输出的时间步 | |
| `Delta`、`deltaminEVP`、`deltaminVP` | 应变率函数；EVP、VP 中的最小值，见动力学章节 | 1/s |
| `default_season` | 初始强迫值所用季节 | `winter` |
| `denom1` | 应力方程中的常数组合 | |
| `depressT` | 盐水冻结温度与盐度之比 | 0.054 度/ppt |
| `dhbr_bt`、`dhbr_top` | 冰柱底部、顶部盐水高度变化 | |
| `dhsn` | 海冰上积雪与融池冰上积雪的深度差 | |
| `diag_file`、`diag_type`、`diagfreq` | 诊断输出文件、输出位置、输出时间步间隔 | `diag_type=stdout` |
| `distrb`、`distrb_info` | 分布数据类型；块分布信息 | |
| `distribution_type`、`distribution_weight` | 处理器上的块分配方法；每块工作量权重方法 | |
| `divu`、`divu_adv` | 应变率第一不变量，即速度散度；平流相关散度 | 1/s |
| `DminTarea` | `deltamin × tarea` | m²/s |
| `dms`、`dmsp` | 二甲基硫、二甲基巯基丙酸盐浓度 | mmol/m³ |
| `dpscale` | 可渗透冰冲洗时间尺度 | $10^{-3}$ |
| `drhosdwind` | 风致积雪压实因子 | 27.3 kg·s/m⁴ |
| `dragio` | 水对冰的阻力系数 | 0.00536 |
| `dSdt_slow_mode` | 排水强度参数 | |
| `dsnow` | 积雪厚度变化 | m |
| `dt`、`dt_dyn` | 热力学时间步；动力学／脊化／输运时间步 | `dt=3600 s` |
| `dT_mlt` | 单位雪粒半径变化对应的温差 | 1 度 |
| `dte`、`dte2T`、`dtei` | EVP 子循环时间步、`dte/2` 阻尼尺度、`1/dte` | s、—、1/s |
| `dump_file`、`dumpfreq`、`dumpfreq_base`、`dumpfreq_n`、`dump_last` | 重启输出文件、频率类型、基准日期、频率值、是否在最后时间步输出 | |
| `dwavefreq` | 波频率区间宽度 | 1/s |
| `dxE`、`dxN`、`dxT`、`dxU` | E/N/T/U 单元中心处 x 向宽度 | m |
| `dyE`、`dyN`、`dyT`、`dyU` | E/N/T/U 单元中心处 y 向高度 | m |
| `dxhy`、`dyhx` | HTE、HTN 值的组合 | |
| `dvidtd`、`dvidtt`、`dvirdg(n)dt` | 动力学／输运、热力学、n 类脊化导致的冰体积变化率 | m/s |
| `dyn_area_min`、`dyn_mass_min` | 计算冰速所需的最小浓度、质量 | `1e-11`、`1e-10 kg/m²` |

## E

| 符号 | 含义 | 值／单位 |
| --- | --- | --- |
| `e11,e12,e22` | 应变率张量分量 | |
| `earea` | E 单元面积 | m² |
| `ecci` | 屈服曲线短轴／长轴比的平方 | 1/4 |
| `eice(n)`、`esno(n)` | n 类冰／雪单位面积融化能 | J/m² |
| `emask` | E 单元的陆地／边界掩膜 | |
| `emissivity` | 雪和冰的发射率 | 0.985 |
| `eps13`、`eps16` | 小常数 | $10^{-13}$、$10^{-16}$ |
| `etax2` | 剪切黏度 $2\eta$ | kg/s |
| `evap` | 蒸发水通量 | kg/m²/s |
| `ew_boundary_type` | 东西边界条件类型 | |
| `elasticDamp` | 计算参数 E 的系数，介于 0 与 1 之间 | 0.36 |
| `e_yieldcurve`、`e_plasticpot` | 屈服曲线、塑性势的短轴／长轴比 | 2 |

## F

| 符号 | 含义 | 值／单位 |
| --- | --- | --- |
| `faero_atm`、`faero_ocn` | 气溶胶沉降率、流向海洋的通量 | kg/m²/s |
| `fbot_xfer_type` | 冰下热交换系数类型 | |
| `fcondtop(n)(_f)` | 传导热通量 | W/m² |
| `fcor_blk` | Coriolis 参数 | 1/s |
| `ferrmax` | 热力学允许的最大能量通量误差 | $10^{-3}$ W/m² |
| `ffracn` | 用于融化融池冰的表面通量比例 | |
| `fhocn`、`fhocn_ai` | 海洋净热通量及其网格盒平均值 | W/m² |
| `field_loc_center/Eface/NEcorner/Nface/Wface` | 场位于单元中心、东面、东北角、北面、西面 | 1、4、2、3、5 |
| `field_loc_noupdate/unknown` | 忽略场位置／位置未知 | -1、0 |
| `field_type_angle/scalar/vector` | 角度场、标量场、矢量场类型 | 3、1、2 |
| `field_type_noupdate/unknown` | 忽略场类型／类型未知 | -1、0 |
| `first_ice` | 初次结冰标志 | |
| `flat` | 潜热通量 | W/m² |
| `floediam`、`floeshape` | 侧向融化的有效浮冰直径、形状常数 | 300 m、0.66 |
| `floe_rad_l`、`floe_rad_c`、`floe_binwidth` | FSD 尺寸箱的半径下界、中心、宽度 | m |
| `flux_bio`、`flux_bio_ai` | 向海洋传递的所有生物地球化学通量及其网格平均 | |
| `flw`、`flwout` | 入射、出射长波辐射 | W/m² |
| `fmU` | Coriolis 参数乘 U 单元质量 | kg/s |
| `formdrag` | 计算形状阻力 | |
| `fpond` | 流向融池的淡水通量 | kg/m²/s |
| `fr_resp` | BGC 呼吸比例 | 0.05 |
| `frain` | 降雨率 | kg/m²/s |
| `frazil` | 冰晶冰生长 | m |
| `fresh`、`fresh_ai` | 流向海洋的淡水通量及其网格平均 | kg/m²/s |
| `frz_onset` | 当年开始冻结的日期 | |
| `frzmlt`、`frzmlt_init` | 冻结／融化势及其时间步初值 | W/m² |
| `frzmlt_max` | 冻结／融化势绝对值上限 | 1000 W/m² |
| `frzpnd` | 融池 Stefan 再冻结 | `hlid` |
| `fsalt` | 流向海洋的净盐通量 | kg/m²/s |
| `fsalt_ai` | 上述盐通量的网格盒平均 | kg/m²/s |
| `fsens`、`fsnow` | 显热通量；降雪率 | W/m²；kg/m²/s |
| `fsnowrdg` | 脊化后保留的雪比例 | 0.5 |
| `fsurf(n)(_f)` | 不含 `fcondtop` 的净表面热通量 | W/m² |
| `fsloss` | 积雪流失到冰间水道的速率 | kg/m²/s |
| `fsw`、`fswabs`、`fswint`、`fswpenl` | 入射短波、总吸收短波、冰内部吸收短波、穿透冰层的短波 | W/m² |
| `fswfac` | 根据更新的数据调整冰变量的缩放因子 | |
| `fswthru`、`fswthru_ai` | 到达海洋的短波及其网格盒平均 | W/m² |
| `fswthru_vdr/vdf/idr/idf` | 到达海洋的可见光直射／漫射、近红外直射／漫射短波 | W/m² |
| `fyear`、`fyear_final`、`fyear_init` | 当前、末尾、初始强迫数据年份 | |

## G

`gravit`：重力加速度，9.80616 m/s²；`grid_atm`、`grid_ice`、`grid_ocn`：大气强迫／耦合、海冰模型和海洋强迫／耦合的网格结构（A/B/C 等）；对应的 `grid_atm_dynu/dynv/thrm`、`grid_ice_dynu/dynv/thrm`、`grid_ocn_dynu/dynv/thrm` 分别指定动力 u、动力 v、热力学场使用的 T/U/N/E 网格。`grid_file`、`grid_format`、`gridcpl_file`：网格信息输入文件、格式、耦合网格文件；`grid_outfile`：写一次性网格历史文件；`grid_type`：输入网格类型，如 `rectangular/displaced_pole/tripole`。`grow_net`：每网格单元的 BGC 比生长率，s⁻¹；`Gstar`：分段线性脊化参与函数参数，0.15。

## H

`halo_info`：影子单元更新信息；`hfrazilmin`：新成冰晶冰的最小厚度，0.05 m；`hi_min`：最薄海冰类别的最小厚度，0.01 m；`hi_ssl`：海冰表面散射层厚度，0.05 m；`hicen`：n 类冰厚，m；`highfreq`：高频大气耦合，默认假；`hin_old`：生长／融化前冰厚，m；`hin_max`：类别厚度上限，m。

`hist_avg`：输出平均数据而非瞬时数据，默认五个真；`histfreq`、`histfreq_base`、`histfreq_n`：历史输出频率单位、基准日期和整数频率；`history_chunksize`、`history_deflate`：HDF5 历史输出的 x/y 分块尺寸（0,0）及压缩级别（0）；`history_dir`、`history_file`、`history_format`：历史文件目录、前缀、格式；`history_iotasks`、`history_precision`、`history_rearranger`、`history_root`、`history_stride`：历史输出的 I/O 任务数、精度（4 或 8 字节，默认 4）、重排方法、根任务和任务步长；`hist_time_axis`：时间轴在区间开头／中间／末尾，默认末尾；`hist_suffix`：文件名后缀，`x` 表示不加，默认五个 `x`。

`hm`：T 单元厚度的陆地／边界掩膜；`hmix`：海洋混合层深度，20 m；`hour`：当年小时数；`hp0`：短波由融池转为裸冰的融池深度，0.2 m；`hp1`：地形融池临界冰盖厚度，0.01 m；`hpmin`：最小融池深度，0.005 m；`hpondn`：融池深度，m；`hs_min`：计算表面温度所需的最小厚度，$10^{-4}$ m；`hs0`、`hs1`：积雪转为冰、转为融池冰的深度阈值，后者 0.03 m；`hs_ssl`：雪表面散射层厚度，0.04 m；`Hstar`：确定脊冰平均厚度的参数，25 m；`HTE/HTN/HTS/HTW`：T 单元东／北／南／西边长，m。

## I

`i(j)_glob`：每个网格单元的全局位置；`i0vis`：穿透的可见光太阳辐射比例，0.70；`iblkp`、`ip,jp`：调试输出所在块及局部处理器坐标；`i(j)block`：块的笛卡尔 i、j 位置；`ice_data_conc/dist/type`：海冰初始化浓度／分布／掩膜，主要用于盒模型测试；`ice_hist_field`：历史变量类型；`ice_ic`：初始条件选项；`ice_stdout`、`ice_stderr`：标准输出、错误输出单元编号；`ice_ref_salinity`：冰洋交换的参考盐度；`icells`：具指定属性的网格单元数（用于矢量化）；`iceruf`：冰表面大气界面粗糙度，$5\times10^{-4}$ m；`iceruf_ocn`：冰下海洋界面粗糙度，0.03 m。

`iceEmask/iceNmask/iceTmask/iceUmask`：E/N/T/U 单元的动力学冰范围掩膜；`idate`、`idate0`：当前时间步末日期（yyyymmdd）、初始日期；`ierr`：通用错误标志；`igrid`：垂向生物网格界面点；`i(j)hi`、`i(j)lo`：局部物理域末尾、起始索引；`incond_dir`、`incond_file`：初始条件快照输出目录和文件前缀；`int_kind`：整数类型定义；`integral_order`：重映射积分求积多项式阶数，3；`istep`、`istep0`、`istep1`：局部时间步计数、上次运行步数（默认 0）、当前总步数；`Iswabs`：冰层吸收短波，W/m²；`itd_area_min`、`itd_mass_min`：删除残余冰的面积／质量阈值。

## J

原索引在 J 下无条目。

## K

`kalg`：藻类吸收系数；`kappav`：海冰中波长低于 700 nm 的可见光消光系数，1.4 m⁻¹；`kcatbound`：厚度类别边界公式；`kdyn`：动力学类型，1 EVP、2 EAP、3 VP、0 或 -1 关闭，默认 1；`kg_to_g`：千克到克的换算系数，1000；`kice`：淡水冰热导率，2.03 W/m/K；`kitd`：冰厚分布（ITD）转换，0 δ 函数、1 线性重映射，默认 1；`kmt_file`、`kmt_type`：陆地掩膜文件及类型，默认 `file`；`krdg_partic`、`krdg_redist`：脊化参与与再分配函数，默认 1；`krgdn`：单位脊化冰厚对应的平均脊厚；`ksno`：积雪热导率，0.30 W/m/K；`kstrength`：冰强度公式，1 Rothrock、0 Hibler，默认 1；`ktherm`：热力学公式，-1 关闭、1 Bitz、2 糊状层。

## L

`l_brine`：盐水囊作用标志；`l_edge_flux_adj`：指定重映射通量标志；`l_mpond_fresh`：融池排水前保留地形融池水；`latpnt`、`lonpnt`：诊断点所需纬度（°N）和经度（°E）；`latt(u)_bounds`、`lont(u)_bounds`：T/U 网格角点纬度、经度；`lcdf64`：使用 64 位格式；`Lfresh`：淡水冰融化潜热，等于 `Lsub-Lvap`，J/kg；`lhcoef`：潜热传递系数；`lmask_n(s)`：北／南半球掩膜；`local_id`：当前分布中的局部块地址；`log_kind`：逻辑变量类型；`Lsub`：淡水升华潜热，$2.835\times10^6$ J/kg；`ltripole_grid`：三极网格标志；`Lvap`：淡水汽化潜热，$2.501\times10^6$ J/kg。

## M

`m_to_cm`：米到厘米换算，100；`m1`、`m2`：侧向融化速率常数，分别 $1.6\times10^{-6}$ m/s/度$^{m2}$、1.36；`m2_to_km2`：平方米到平方千米换算，$10^{-6}$；`maskhalo_bound/dyn/remap`：边界状态、动力学、输运 halo 掩膜开关；`master_task`：控制处理器任务号；`max_blocks`：每处理器最大块数；`max_ntrcr`：最大可用示踪物数，5；`maxraft`：可筏化冰的最大厚度，1 m；`mday`、`mmonth`、`myear`：模型当月日、月份、年份；`meltb`、`meltl`、`meltt`：底部、侧向、顶部融冰量，m；`melts`：融雪量，m；`meltsliq`、`meltsliqn`：总融雪质量及 n 类的融雪质量，kg/m²；`min_salin`：盐水囊阈值，0.1 ppt；`mlt_onset`：当年表面开始融化日期；`monthp`、`month_init`：上月编号、初始月份；`mps_to_cmpdy`：m/s 转 cm/day 的系数，$8.64\times10^6$；`msec`：当日已过模型秒数；`mtask`：调试输出所在局部处理器号；`mu_rdg`：脊冰 e 倍尺度；`myear_max`：允许的最大模型年；`my_task`：当前处理器任务号。

## N

`n_aero`：气溶胶组分数；`narea`：N 单元面积，m²；`natmiter`：大气边界层迭代次数，默认 5；`nblocks`、`nblocks_tot`、`nblocks_x(y)`：当前处理器块数、分解总块数、x/y 方向块总数；`nbtrcr`：生物示踪物数；`ncat`、`ncat_hist`：海冰厚度类别数（默认 5）、写入历史的类别数；`ndte`：动力学子循环次数，120；`ndtd`：每个热力学步内动力学／平流步数，1；`new_day/hour/month/year`：新的一天／小时／月／年开始标志；`nfreq`：波频率箱数，25；`nfsd`：浮冰尺寸类别数，12；`nghost`：每个子域外围影子单元行数，1；`ngroups`：重映射通量三角形组数，5；`nhlat`：人工掩膜边缘北界纬度，30°S；`nilyr`：每类海冰层数，7；`nit`：硝酸盐浓度，mmol/m³；`nlt_bgc_[chem]`：海洋 BGC 源汇；`nmask`：N 单元 T 北边缘的陆地／边界掩膜；`nml_filename`：namelist 文件名；`nprocs`：处理器总数；`npt`、`npt_unit`：运行长度值及其单位；`ns_boundary_type`：南北边界条件；`nslyr`：每类雪层数；`nspint`：太阳光谱区间数；`nstreams`：历史输出流数；`nt_<trcr>`：示踪物索引；`ntrace`：被输运场数；`ntrcr`：示踪物数。

`nu_diag`、`nu_dump`、`nu_dump_eap`、`nu_dump_[tracer]`、`nu_forcing`、`nu_grid`、`nu_hdr`、`nu_history`、`nu_kmt`、`nu_nml`、`nu_restart`、`nu_restart_eap`、`nu_restart_[tracer]`、`nu_rst_pointer`：分别为诊断输出、重启转储、EAP 重启转储、示踪物转储、强迫数据、网格、二进制历史文件头、历史文件、陆地掩膜、namelist 输入、重启输入、EAP 重启输入、示踪物重启输入、最新重启文件指针的 I/O 单元编号。`num_avail_hist_fields_[shape]`：各数组形状的可用历史场数；`nvar`：写入历史的水平网格场数；`nvarz`：写入历史的类别×垂向场数；`nx(y)_block`：块在 x/y 方向的网格点总数；`nx(y)_global`：全局域 x/y 方向物理网格点数。

## O

`ocean_bio`：海洋 BGC 组分浓度；`oceanmixed_file`：海洋强迫数据文件；`oceanmixed_ice`：为真时启用内部海洋混合层；`ocn_data_dir`、`ocn_data_format`、`ocn_data_type`：海洋强迫数据目录、文件格式及海表温度／盐度数据来源；`omega`：地球角速度，$7.292\times10^{-5}$ rad/s；`opening`：辐散和剪切造成的海冰开裂率，1/s。

## P

常数：`p001=1/1000`、`p01=1/100`、`p025=1/40`、`p027=1/36`、`p05=1/20`、`p055=1/18`、`p1=1/10`、`p111=1/9`、`p15=15/100`、`p166=1/6`、`p2=1/5`、`p222=2/9`、`p25=1/4`、`p333=1/3`、`p4=2/5`、`p5=1/2`、`p52083=25/48`、`p5625m=-9/16`、`p6=3/5`、`p666=2/3`、`p75=3/4`。

`phi_c_slow_mode`：临界液相比例；`phi_i_mushy`：底边界固相比例；`phi_sk`：骨架层孔隙度；`phi_snow`：盐水高度示踪物中的雪孔隙度；`pi`、`pi2`、`pih`、`piq`：$\pi$、$2\pi$、$\pi/2$、$\pi/4$；`pi(j,b,m)loc`：诊断点的 x/y、块、任务位置；`plat`、`plon`：诊断点网格纬度、经度；`pndaspect`：融池变化深度／面积纵横比，0.8；`pointer_file`：重启输入文件；`potT`：大气位温，K；`PP_net`：每格总初级生产力，mg C/m²/s；`precip_units`：液态降水数据单位；`print_global`、`print_points`：打印全局或指定点数据的开关；`processor_shape`：处理器长宽比描述；`Pstar`：冰强度参数，$2.75\times10^4$ N/m²；`puny`：小正数，$10^{-11}$。

## Q

`Qa`：10 m 高度比湿，kg/kg；`qdp`：深海热通量，W/m²；`qqqice`、`qqqocn`：冰面与海面饱和比湿计算用常数，分别 $1.16378\times10^7$ 和 $6.275724\times10^6$ kg/m³；`Qref`：2 m 大气参考比湿，kg/kg。

## R

`R_C2N`：藻类碳／硝酸盐因子，7 mol/mol；`R_gC2molC`：碳的 mg/mmol 换算因子，12.01；`R_chl2N`：藻类叶绿素／硝酸盐因子，3 mg/mmol；`R_ice`、`R_pnd`、`R_snw`：Delta-Eddington 的冰、融池、雪反照率参数；`R_S2N`：藻类硅酸盐／硝酸盐因子，0.03 mol/mol；`r16_kind`：四倍精度定义 `selected_real_kind(26)`；`Rac_rapid_mode`：临界 Rayleigh 数，10；`rad_to_deg`：弧度转角度因子，$180/\pi$；`radius`：地球半径，$6.37\times10^6$ m；`rdg_conv`、`rdg_shear`：脊化的辐合率和剪切率，1/s；`real_kind`：单精度实数定义 `selected_real_kind(6)`；`refindx`：海冰折射率，1.310；`rep_prs`：替代压力，N/m；`revp`：`real(revised_evp)`。

`restart`：为真时从文件初始化冰状态；`restart_age`、`restart_bgc`、`restart_[tracer]`：读取冰龄、BGC 和相应示踪物重启文件；`restart_chunksize`、`restart_deflate`：HDF5 重启文件的 x/y 分块尺寸（0,0）与压缩级别（0）；`restart_dir`、`restart_file`、`restart_format`：重启文件目录、前缀、格式；`restart_iotasks`、`restart_rearranger`、`restart_root`、`restart_stride`：重启 I/O 任务数、重排方法、根任务及步长；`restart_mod`：重启修正模式；`restart_ext`、`restart_coszen`：在重启文件读写 halo 单元、太阳天顶角余弦。

`restore_bgc`：将硝酸盐／硅酸盐恢复到数据值；`restore_ice`：沿侧边界恢复海冰状态；`restore_ocn`：恢复海表温度；`revised_evp`：使用修订版 EVP 参数和方法；`rfracmin`、`rfracmax`：进入融池的融水最小、最大比例，索引中为 0.15 和 1.0；`rhoa`、`rhofresh`、`rhoi`、`rhos`、`rhow`：空气、淡水、冰、雪、海水密度，后四者分别为 1000、917、330、1026 kg/m³；`rhos_cmp`：风压实导致的雪密度；`rhos_cnt`：雪中冰与液态水含量的密度；`rhosi`：盐水高度示踪物使用的海冰平均密度，940 kg/m³；`rhosmax`、`rhosmin`、`rhosnew`：雪最大、最小、新雪密度，450、100、100 kg/m³；`rnilyr`：`real(nlyr)`；`rside`：侧向融化的冰比例；`rsnw`、`rsnw_fall`、`rsnw_mlt`、`rsnw_nonmelt`、`rsnw_sig`、`rsnw_tmax`：雪粒半径及新雪、融雪、未融雪、标准差和最大半径，分别 $10^{-6}$、100、1000、500、250、1500×$10^{-6}$ m；`runid`：运行标识；`runtype`：初始化类型。

## S

`s11,s12,s22`：应力张量分量；`saltflux_option`：耦合盐通量形式；`saltmax`：冰底最大盐度，3.2 ppt；`scale_factor`：短波辐射分量缩放因子；`seabed_stress`：是否计算海底应力，默认假；`seabed_stress_method`：`LKD` 或 `probabilistic`，默认 LKD；`secday`：一天的秒数，86400；`sec_init`：初始秒；`shcoef`：显热传递系数；`shear`：应变率第二分量，1/s；`shlat`：人工掩膜边缘南界纬度，30°N；`shortwave`：短波参数化选项 `ccsm3/dEdd/dEdd_snicar_ad`；`sig1(2)`：诊断主应力分量；`sigP`：内部冰压，N/m；`sil`：硅酸盐浓度，mmol/m³；`sinw`：水中转向角正弦，0；`Sinz`：冰盐度剖面，ppt；`sk_l`：骨架层厚度，0.03 m；`snoice`：雪冰形成量，m；`snowpatch`：非均匀积雪覆盖参数化长度尺度，0.02 m；`skl_bgc`：BGC 开关。

`smassice`、`smassliq`：积雪中冰和液态水质量，kg/m²；`snowage_drdt0`：有效雪粒半径初始变化率；`snowage_rhos`、`snowage_kappa`、`snowage_tau`、`snowage_T`、`snowage_Tgrd`：雪老化的密度、拟合参数、温度及温度梯度参数；`snw_aging_table`、`snw_filename`：雪老化查找表及文件名；`snw_tau_fname`、`snw_kappa_fname`、`snw_drdt0_fname`、`snw_rhos_fname`、`snw_Tgrd_fname`、`snw_T_fname`：文件中相应场名；`snwgrain`：启用雪变质；`snwlvlfac`：脊化再分配时雪深比例增量，0.3；`snwredist`：积雪再分配类型；`spval`、`spval_dbl`：单／双精度特殊值，$10^{30}$。

`ss_tltx(y)`：x/y 方向海面坡度，m/m；`sss`：海表盐度，ppt；`sst`：海表温度，°C；`Sswabs`：积雪层吸收短波，W/m²；`stefan-boltzmann`：Stefan–Boltzmann 常数，$5.67\times10^{-8}$ W/m²/K⁴；`stop_now`：为 1 时终止程序；`strairx(y)U/T`：大气对海冰的 x/y 向应力，分别位于 U/T 单元，N/m²；`strax(y)`：数据中的风应力分量，N/m²；`strength`：冰强度，N/m；`stress12`、`stressm`、`stressp`：冰内应力 $\sigma_{12}$、$\sigma_{11}-\sigma_{22}$、$\sigma_{11}+\sigma_{22}$，N/m；`strintx(y)U`：冰内应力散度，N/m²；`strocnx(y)U/T`：U/T 单元冰洋 x/y 向应力，N/m²；`strtltx(y)U`：海面坡度所致表面应力，N/m²；`swv(n)dr(f)`：可见／近红外及直射／漫射入射短波，W/m²。

## T

`Tair`：10 m 气温，K；`tarea`、`tarean`、`tareas`：T 单元、北半球 T 单元、南半球 T 单元面积，m²；`tarear`：面积倒数，m⁻²；`tcstr`：历史变量的 T 网格标识字符串；`Tf`：冻结温度，°C；`Tffresh`：淡水冰冻结温度，273.15 K；`tfrz_option`：海洋冻结温度形式；`thinS`：盐水示踪物使用的最小冰厚；`timer_stats`：额外计时统计开关，默认假；`timesecs`：累计时间，秒；`time_beg`、`time_bounds`、`time_end`：历史平均起点、起止边界、终点；`time_forc`：上次强迫更新时刻，秒；`Timelt`：冰顶面融化温度，0°C；`Tinz`：冰内部温度，°C；`TLAT`、`TLON`：单元中心纬度、经度，弧度；`Tliquidus_max`：糊状层最高液相线温度，0°C；`tmask`：T 单元厚度的陆地／边界掩膜；`tmass`：冰雪总质量，kg/m²；`Tmin`：允许的最低内部温度，-100°C；`Tmltz`：冰融化温度剖面；`Tocnfrz`：常数冻结点参数化的温度，-1.8°C。

`tr_aero`、`tr_bgc_[tracer]`、`tr_brine`、`tr_FY`、`tr_iage`、`tr_lvl`：分别启用气溶胶、BGC、盐水高度、首年冰、冰龄、平整冰面积与体积示踪物；`tr_pond_lvl`、`tr_pond_sealvl`、`tr_pond_topo`：分别启用平整冰、海平面、地形融池方案；`trcr`：海冰示踪物；`trcr_depend`：示踪物对基本状态变量的依赖；`Tref`：2 m 大气参考温度，K；`trestore`：恢复时间尺度，天；`tripole`：块位于三极边界的标志；`tripoleT`：三极边界 T 折返（真）或 U 折返（假）；`tscale_pnd_drain`：糊状层宏观排水时间尺度，天；`Tsf_errmax`：允许的最大表面温度误差，$5\times10^{-4}$ 度；`Tsfc(n)`：n 类冰／雪顶面温度，°C；`Tsnz`：雪内部温度，°C；`Tsmelt`：雪顶面融化温度，0°C；`TTTice`、`TTTocn`：冰面与海面饱和比湿计算常数，5897.8、5107.4 K。

## U

`uarea`、`uarear`：U 单元面积及其倒数，m² 与 m⁻²；`uatm`、`uocn`：x 向风速与海流速度，m/s；`ULAT`、`ULON`：U 单元中心纬度、经度，弧度；`umask`、`uvm`：U 单元速度陆地／边界掩膜；`umax_stab`：诊断冰速阈值，1 m/s；`umin`：湍流通量所需最小风速，1 m/s；`update_ocn_f`：是否将冰晶冰通量纳入海洋通量场；`use_leap_years`：是否包含闰日；`use_restart_time`：是否使用重启文件日期；`use_smliq_pnd`：融池是否使用雪中液态水；`ustar_min`：冰下最小摩擦速度；`ucstr`：历史变量 U 网格标识字符串；`uvel`、`uvel_init`：海冰速度 x 分量及时间步初值，m/s。

## V

`vatm`、`vocn`：y 向风速、海流速度，m/s；`vice(n)`：n 类冰的单位面积体积，m；`vicen_init`：时间步初始冰体积，m；`viscosity_dyn`：盐水动力黏度，$1.79\times10^{-3}$ kg/m/s；`visc_method`：黏度计算方法 `avg_strength/avg_zeta`，默认后者；`vonkar`：von Kármán 常数，0.4；`vort`：涡度，1/s；`vraftn`、`vrdgn`：筏化冰、脊冰体积，m；`vredistrn`：再分配函数中新脊体积比例；`vsno(n)`：n 类雪的单位面积体积，m；`vvel`、`vvel_init`：海冰速度 y 分量及时间步初值，m/s。

## W

`warmice`、`warmsno`：常数反照率参数化中的暖冰、暖雪值，0.68、0.77；`wave_sig_ht`：有效波高，m；`wave_spectrum`：波谱，m²/s；`wavefreq`：波频率，1/s；`wind`：风速，m/s；`windmin`：压实积雪所需最小风速，10 m/s；`write_history`、`write_histrest`、`write_histrest_now`、`write_ic`、`write_restart`：当前写历史文件、按需写历史重启、立即写历史重启、写初始条件、立即写重启的标志。

## X、Y、Z

原索引 X 无条目。`ycycle`：强迫数据循环年数；`yday`：模型日历计算的当年第几天；`yield_curve`：屈服曲线类型，默认椭圆；`yieldstress11(12,22)`：屈服应力张量分量；`year_init`：初始年。`zetax2`：体积黏度 $2\zeta$，kg/s；`zlvl`：动量用大气层高度，m；`zlvs`：标量用大气层高度，m；`zref`：稳定度参考高度，10 m；`zTrf`：`Tref/Qref/Uref` 参考高度，2 m；`zvir`：水汽气体常数与空气气体常数之比减一，0.606。

## 已弃用选项和参数

`heat_capacity`：为真时使用盐度相关热力学，旧默认真；`kseaice`：零层热力学中的冰热导率，2.0 W/m/K；旧 `ktherm` 的 0 值表示零层方案（1 为 Bitz，2 为糊状层）；`tr_pond_cesm`：旧 CESM 融池方案。

[英文原文](../source/cice_index.rst)
