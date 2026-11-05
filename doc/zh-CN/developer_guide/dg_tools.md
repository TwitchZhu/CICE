# 工具

## CICE4 重启文件转换

`configuration/tools/cice4_restart_conversion` 中的 Fortran 程序可帮助把 CICE4 的重启文件转换为 CICE5 的重启文件。该工具的源代码中包含构建、使用和运行说明。由于若干预报变量（prognostic variables）从 CICE4 到 CICE5 发生变化，重启文件保存的场也有根本变化。详情见 `configuration/tools/cice4_restart_conversion/convert_restarts.f90`。

## JRA55 强迫数据集

本节说明如何为 CICE 生成 JRA55 强迫数据。原始 JRA55 或 JRA55do 文件必须插值和处理为 CICE 专用输入文件。`configuration/tools/jra55_datasets` 中提供了相应工具。原始数据来自 NCAR/UCAR Research Data Archive，转换工具由 Python 编写。

### 软件要求

需要 Python 3 及以下 Python 包。括号中的版本是最近运行脚本时使用并测试的版本，并不表示其他版本一定不能运行。

| 软件 | 测试版本 |
| --- | --- |
| Python 3 | 3.7.9 |
| NumPy | 1.18.5 |
| netCDF4 | 1.5.5 |
| ESMPy | 8.0.0 |
| xesmf | 0.3.0 |

还需要 NCO 将输出聚合为按年存储的文件；测试时使用的 NetCDF 和 NCO 版本分别为 4.7.4 和 4.9.5。

### 原始 JRA55 强迫数据

原始 JRA55 数据从 [UCAR/NCAR Research Data Archive](https://rda.ucar.edu/) 获取。首先免费注册并登录。数据集“JRA-55 Reanalysis Daily 3-Hourly and 6-Hourly Data”的编号是 `ds628.0`，位于 [ds628.0 页面](https://rda.ucar.edu/datasets/ds628.0)。

“Data access”标签页列出产品类别。所需 JRA55 数据分布在两个产品中：风速、空气温度和比湿在“JRA-55 3-Hourly Model Resolution 2-Dimensional Instantaneous Diagnostic Fields”中；降水与向下辐射通量在“JRA-55 3-Hourly Model Resolution 2-Dimensional Average Diagnostic Fields”中。注意区分瞬时数据和平均数据。JRA55 数据集较多，可能需要向下滚动才能找到。虽然也有较粗的 1.25° 网格数据，但这些工具最适合 JRA55 原生 TL319 网格。

CICE 所需的场如下：

| 场 | 时间表示 | CICE 变量 |
| --- | --- | --- |
| 比湿 | 3 小时瞬时值 | `Qa` |
| 温度 | 3 小时瞬时值 | `Tair` |
| 风的 u 分量 | 3 小时瞬时值 | `uatm` |
| 风的 v 分量 | 3 小时瞬时值 | `vatm` |
| 向下长波辐射通量 | 3 小时平均值 | `flw` |
| 向下太阳辐射通量 | 3 小时平均值 | `fsw` |
| 总降水 | 3 小时平均值 | `fsnow` |

自定义下载数据时，选择“Get a Subset”，在“Temporal Selection”中选择时间，然后选择所需参数。继续下一步后，将输出格式设为“Converted to NetCDF”。提交数据请求后，会收到包含专用 URL 的邮件通知，该 URL 提供多种远程下载方式。数据保留 5 天。原始数据由多个文件组成，每个文件包含一个场的三个月数据。

### 数据转换

脚本 `configuration/tools/jra55_datasets/interp_jra55_ncdf_bilinear.py` 将原始数据转换为 CICE 输入文件。它使用双线性重网格化（bilinear regridding）算法，将 JRA55 网格上的数据插值到 CICE 网格。脚本使用 Python 包 `xesmf` 生成双线性重网格化权重，并将权重写入该脚本中变量 `blin_grid_name` 指定的文件。可以编辑脚本修改文件名。同一网格上的其他数据可以复用权重文件。`xesmf` 还提供守恒插值和最近邻等方法，但当前版本的脚本未测试这些选项；详情见 [xESMF 文档](https://xesmf.readthedocs.io/en/latest/)（原文访问时间：2020 年 11 月 5 日）。

查看脚本最新的命令行用法：

```bash
python3 interp_jra55_ncdf_bilinear.py -h
```

命令形式为：

```text
usage: interp_jra55_ncdf_bilinear.py [-h] JRADTG gridout ncout

将 JRA55 数据插值到 CICE 网格

位置参数：
  JRADTG   JRA55 输入文件的日期时间组
  gridout  CICE 网格文件（NetCDF）
  ncout    输出 NetCDF 文件名

可选参数：
  -h, --help  显示帮助并退出
```

示例：

```bash
./interp_jra55_ncdf_bilinear.py 1996010100_1996033121 grid_gx3.nc JRA55_gx3_03hr_forcing_1996-q1.nc
./interp_jra55_ncdf_bilinear.py 1996040100_1996063021 grid_gx3.nc JRA55_gx3_03hr_forcing_1996-q2.nc
./interp_jra55_ncdf_bilinear.py 1996070100_1996093021 grid_gx3.nc JRA55_gx3_03hr_forcing_1996-q3.nc
./interp_jra55_ncdf_bilinear.py 1996100100_1996123121 grid_gx3.nc JRA55_gx3_03hr_forcing_1996-q4.nc
```

此例将 1996 年四个季度的 JRA55 数据插值到 gx3 网格。随后可用 NCO 聚合为一个年度文件：

```bash
ncrcat JRA55_gx3_03hr_forcing_1996-??.nc JRA55_${grid}_03hr_forcing_1996.nc
```

注意事项：

- 脚本需要 NetCDF 格式的 CICE 网格文件，上例为 `grid_gx3.nc`。NetCDF 网格变量名在 `interp_jra55_ncdf_bilinear.py` 中硬编码；如果使用不同变量名的网格文件，需要修改脚本。
- 原始 JRA55 输入文件、CICE 网格文件和转换脚本应放在同一目录；输出也会写入该目录。
- `configuration/tools/jra55_datasets/make_forcing.csh` 于 2021 年 3 月在 NCAR Cheyenne 机器上用于生成 CICE 强迫数据。它假定原始 JRA55 已下载，然后设置 Python 环境、把数据链接到同一目录、运行 `interp_jra55_ncdf_bilinear.py`，最后用 NCO 聚合季度数据。
- 新强迫文件可通过 `ice_in` namelist 中的 `atm_data_type`、`atm_data_format`、`atm_data_dir`、`fyear_init` 和 `ycycle` 指定。详情见[独立运行的强迫数据](dg_forcing.md)。
- JRA55 的总降水场单位为 mm/day。它最初作为雪读入，但 `ice_forcing.F90` 中的 `prepare_forcing` 会根据空气温度将其拆分为降雨或降雪强迫。

原文：[dg_tools.rst](../../source/developer_guide/dg_tools.rst)
