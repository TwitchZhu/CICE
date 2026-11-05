# 动力学

CICE 的 `cicecore/` 目录包含 Icepack 之外的源代码，其子目录如下：

- `cicecore/cicedyn/analysis`：较高层次的历史输出（history）和诊断例程。
- `cicecore/cicedyn/dynamics`：所有动力学 EVP、EAP 及输运例程。
- `cicecore/cicedyn/general`：与强迫、通量计算、初始化和模式时间步推进有关的例程。
- `cicecore/cicedyn/infrastructure`：多数底层基础设施，包括通信（边界晕区更新、汇集、分发、全局求和等），以及二进制文件和 NetCDF 文件的输入输出。
- `cicecore/drivers/`：支持独立运行驱动程序及其他高层耦合层的子目录。
- `cicecore/shared/`：与网格分解、时间管理器、常量、数值种类（kind）及重启功能有关的基本方法。

## 动力学求解器

动力学求解器位于 `cicecore/cicedyn/dynamics/`。可选方案包括弹性黏塑性（elastic-viscous-plastic，EVP）、弹性各向异性塑性（elastic-anisotropic-plastic，EAP）及黏塑性（viscous-plastic，VP）。Namelist 变量 `kdyn` 指定求解器：`kdyn=1` 为 EVP，`kdyn=2` 为 EAP，`kdyn=3` 为 VP。

EVP 还提供两种替代实现。将 `revised_evp` 设为真会启用修订版 EVP（Revised EVP）。将 `evp_algorithm` 从默认的 `evp_standard_2d` 改为 `shared_mem_1d`，会启用一维 EVP 求解器。`evp_algorithm` 设为 `standard_2d` 和 `shared_mem_1d` 时，两个解通常不会逐位一致，因为如果没有严格的编译器标志，就会出现浮点舍入差异。`shared_mem_1d` 主要为 OpenMP 构建；若使用 MPI 区域分割，该求解器只在主处理器上运行。`shared_mem_1d` 不支持三极网格（tripole grid）。

## 输运

输运（平流，advection）方法位于 `cicecore/cicedyn/dynamics/`。支持迎风（upwind）和重映射（remap）两种方法，由 namelist 变量 `advection` 指定。也可以使用 namelist 变量 `ktransport` 禁用输运。

原文：[dg_dynamics.rst](../../source/developer_guide/dg_dynamics.rst)
