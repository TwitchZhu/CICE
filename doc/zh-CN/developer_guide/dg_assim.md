# 资料同化

资料同化（data assimilation，DA）是将外部数据与数值模式预报相结合的科学过程。可通过调整模式初始条件（在模式内部或外部进行），也可在模式解随时间演变时进行调整。CICE 正在引入多种资料同化选项，下面介绍现有选项。

## 重启时的资料同化

Namelist 变量 `restart_mod` 指定重启资料同化模式。默认值 `none` 禁用该功能。当前可用的选项为 `adjust_aice` 和 `adjust_aice_test`。

使用这两个选项时，重启时会通过 `cicecore/cicedyn/infrastructure/ice_restart_driver.F90` 中的 `direct_adjust_aice` 子程序，将各类别平均的 `aice` 调整到指定值。该方法会调整所有类别中的 `aice`、`vice`、`vsno`、`qice` 和 `sice`，使其与指定的类别平均 `aice` 一致；还会调整温度和盐度等若干热力学变量（见原文引用的 Posey 2015）。

`adjust_aice` 从外部文件读取海冰密集度（sea-ice concentration）场。目前场名硬编码为 `sic`，文件名硬编码为 `sic.nc`。该场必须位于模式网格上。

`adjust_aice_test` 在模式内部修改从重启文件读取的 `aice` 场。当前实现将读入的 `aice` 值四舍五入到最近的 0.01。这个模式主要用于测试该功能。

原文：[dg_assim.rst](../../source/developer_guide/dg_assim.rst)
