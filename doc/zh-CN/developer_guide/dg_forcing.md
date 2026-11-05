# 独立运行的强迫数据

项目强烈建议在耦合系统中运行 CICE（见[耦合](../science_guide/sg_coupling.md)），以提高科学研究的质量。独立运行模式（standalone mode）最适合技术测试及初步科学测试。CICE 历史上实现过多种输入强迫数据集：一些已经过时，一些被更新的数据选项取代，还有一些由外部用户实现，Consortium 无法测试。强迫代码通常并非由 Consortium 持续维护；Consortium 只测试其中一部分。

强迫实现位于 `cicecore/cicedyn/general/ice_forcing.F90`。由于历史原因，也由于不鼓励用独立运行来评估复杂科学问题，该实现的许多方面比较基础。多数实现大体采用以下方式：

- 输入文件按年份组织。文件名规则有一定灵活性。例如，JRA55 和 JRA55do 的文件名可采用 `[JRA55,JRA55do][_$grid]_03hr_forcing_$year.nc` 或 `[JRA55,JRA55do]_03hr_forcing[_$grid]_$year.nc`；可选的 `_$grid` 可以出现在两个位置之一。这是为了自动支持 `CICE_data` 目录中 gx1、gx3 和 tx1 网格的现有命名方式。详情见 `ice_forcing.F90` 的 `JRA55_files`。
- Namelist 输入 `fyear` 和 `ycycle` 指定强迫年份数据集。模式动态计算强迫年份，并假定它在 `ycycle` 定义的数据集长度内循环。
- `atm_data_dir` 指定大气输入文件的完整或部分路径，`atm_data_type` 指定大气强迫模式（见[ `forcing_nml` 参数表](../user_guide/ug_case_settings.md)）。许多强迫选项在模式内部生成。对于从文件读取的大气强迫，目录结构和文件名取决于网格及 `atm_data_type`；可查看 `CICE_data` 的目录和文件名，以及 `ice_forcing.F90` 的实现。gx1、gx3 和 tx1 测试网格主要使用 `JRA55`、`JRA55do`。此时 `atm_data_dir` 应设置为 `${CICE_data_root}/forcing/${grid}/[JRA55,JRA55do]`，文件名应为 `[JRA55,JRA55do]_${grid}_03hr_forcing${atm_data_version}_yyyy.nc`，其中 `yyyy` 是强迫年份。这些文件应位于 `atm_data_dir/8XDAILY` 下。`atm_data_version` 是 `forcing_nml` 中的字符串，用于区分强迫数据版本；它可以是任意字符串，包括空字符串，通常形如 `_yyyymmdd`，表示数据生成日期。
- `ocn_data_dir` 指定海洋输入文件目录，`ocn_data_type` 指定海洋强迫模式。
- 文件名须遵守源代码（例如 `JRA55_files` 子程序）规定的命名约定。强迫年份通常位于文件扩展名 `.nc` 之前；`file_year` 等子程序根据模式年份和对应的强迫年份更新文件名。
- 强迫子程序通常**不读取输入数据的时间轴**。强迫频率在模式中硬编码，文件记录号根据强迫频率和模式时间计算。闰年输入数据与无闰年模式日历混用时，处理并不完善；CICE 不读取输入数据的时间轴，也不据此检查。
- 数据直接按模式网格读取，没有空间插值。
- 模式的每个时间步通常会在两个输入时刻之间做线性时间插值。

强迫模块通常需要定义以下变量。

**大气变量：**

| 变量 | 含义 | 单位 |
| --- | --- | --- |
| `zlvl` | 大气层高度（atmosphere level height） | m |
| `uatm`、`vatm` | 模式网格 i、j 方向风速分量 | m/s |
| `strax`、`stray` | 模式网格 i、j 方向风应力 | N/m² |
| `potT` | 空气位温（potential temperature） | K |
| `Tair` | 空气温度 | K |
| `Qa` | 比湿（specific humidity） | kg/kg |
| `rhoa` | 空气密度 | kg/m³ |
| `flw` | 入射长波辐射 | W/m² |
| `fsw` | 入射短波辐射 | W/m² |
| `swvdr`、`swvdf` | 可见光波段向下短波辐射，分别为直射和漫射 | W/m² |
| `swidr`、`swidf` | 近红外波段向下短波辐射，分别为直射和漫射 | W/m² |
| `frain` | 降雨率 | kg/(m²·s) |
| `fsnow` | 降雪率 | kg/(m²·s) |

**海洋变量：**

| 变量 | 含义 | 单位 |
| --- | --- | --- |
| `uocn`、`vocn` | 海流 x、y 方向分量 | m/s |
| `ss_tltx`、`ss_tlty` | 海面 x、y 方向坡度 | m/m |
| `hwater` | 计算底部应力所需的水深（岸冰） | 原文未列 |
| `sss` | 海表盐度（sea surface salinity） | ppt |
| `sst` | 海表温度（sea surface temperature） | °C |
| `frzmlt` | 结冰／融化潜势 | W/m² |
| `frzmlt_init` | 当前时间步使用的 `frzmlt` | W/m² |
| `Tf` | 冰点温度 | °C |
| `qdp` | 深海热通量，向上为负 | W/m² |
| `hmix` | 混合层深度 | m |
| `daice_da` | 资料同化的密集度增量率，仅用于 HadGEM 驱动程序 | s⁻¹ |

所有变量都有合理但固定的默认值，`default` 模式使用这些值。

每个时间步，时间循环调用 `get_forcing_atmo` 和 `get_forcing_ocn` 推进强迫。相关子程序计算强迫年份 `fyear`、调用相应的数据方法，然后调用 `prepare_forcing`，将输入数据场转换为模式强迫场。

## JRA55 和 JRA55do 大气强迫

Consortium 当前在 gx3、gx1 和 tx1 独立网格上进行测试时，默认使用 JRA55 强迫数据集（见原文引用的 Tsujino 2018）。Consortium 为这些网格发布了 2005—2009 年共五年的强迫数据。每年一个文件；数据集使用包含闰日的公历时间轴。

![JRA55 CICE 强迫文件生成示意图](../../source/developer_guide/figures/jra55data.png)

`JRA55_data` 子程序负责读取并插值强迫。它从输入文件读取空气温度 `airtmp`、东西向和南北向风速 `wndewd`、`wndnwd`、比湿 `spchmd`、入射短波与长波辐射 `glbrad`、`dswsfc`，以及降水 `ttlpcp`。JRA55 再分析每 6 小时使用更新后的初始条件运行一次，每 3 小时输出一次。四个状态场（空气温度、风、比湿）是瞬时数据，三个通量场（辐射、降水）是 3 小时平均值。

在 Consortium 提供的 JRA55 强迫文件中，3 小时平均场的时间被移到该 3 小时时段的**开始时刻**。**这与原始 JRA55 文件的处理方式不同，也与模式通常为累积／平均场定义时间的方式不同。**上图对此作了示意。

状态场在相邻输入时刻之间进行线性时间插值；通量场读取后，在每个 3 小时模式时段内保持常量。实现中强迫频率硬编码为 3 小时，记录号根据当前模式年份中的时间计算。插值系数在 `JRA55_data` 中计算。

`get_forcing_atmo` 调用的 `prepare_forcing` 将强迫数据转换为模式输入。具体来说，JRA55 输入数据包含：

| 变量 | 含义 | 单位 |
| --- | --- | --- |
| `uatm` | T 网格单元中心、模式网格 i 方向风速分量 | m/s |
| `vatm` | T 网格单元中心、模式网格 j 方向风速分量 | m/s |
| `Tair` | 空气温度 | K |
| `Qa` | 比湿 | kg/kg |
| `flw` | 入射长波辐射 | W/m² |
| `fsw` | 入射短波辐射 | W/m² |
| `fsnow` | 降雪率 | kg/(m²·s) |

模式的其余强迫输入由这些场及默认值推导得到。

输入文件采用公历时间轴，因此模式可以使用通常的 365 天无闰年（noleap）日历运行。不过在这种情况下，输入数据中的 2 月 29 日会用于 3 月 1 日，此后数据均偏移一天；在闰年，CICE 使用无闰日日历时会跳过 12 月 31 日的数据。

Consortium 也以相同格式和方案提供 JRA55do 强迫。JRA55do 更侧重于海洋和海冰模式的强迫，但提供与 JRA55 很相近的气候。切换到 JRA55do 时，将 namelist 中 `atm_data_type` 设为 `JRA55do`，并在输入数据目录中放置 Consortium 提供的 JRA55do 数据集。

## NCAR 大气强迫

早期在 gx3 网格上的独立运行使用 NCAR 大气强迫；Consortium 目前仍对此数据集进行少量测试。模式读取 `fsw`、`cldf`、`fsnow` 的月平均数据，以及 `Tair`、`uatm`、`vatm`、`rhoa`、`Qa` 的 6 小时数据。建议用户改用 [JRA55](#jra55-和-jra55do-大气强迫) 数据集。NCAR 大气强迫以后可能被弃用。

## 默认大气强迫

默认大气强迫选项在模式内部设置强迫，不读取文件。强迫场的值在 `init_coupler_flux` 子程序初始化时定义，此后保持不变。可以通过 namelist 变量 `default_season` 指定不同条件。

## Box2001 大气强迫

Box2001 强迫数据集在模式内部生成，不读取文件。它用于测试原文引用的 Hunke 2001 所定义的理想化盒式案例。

## 其他大气强迫

`atm_data_type` 还定义了一些其他大气强迫模式，但 Consortium 不定期测试这些模式。

## 默认海洋强迫

独立运行 CICE 的标准海洋设置是 `default`。此时所有网格点的海表盐度设为 34 ppt，海表温度设为冰点温度，并保持不变；若启用混合层参数化，则海表温度会随时间演变。其他海洋耦合场设为零。不读取文件。

## 其他海洋强迫

`ocn_data_type` 还定义了一些其他海洋强迫模式，但 Consortium 不定期测试这些模式。

原文：[dg_forcing.rst](../../source/developer_guide/dg_forcing.rst)
