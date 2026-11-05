# 开发概述

CICE 模式由四部分组成：CICE 动力学及其配套基础设施、CICE 驱动程序、Icepack 单柱物理代码和脚本。本指南分别说明各部分的开发工作。

构建 CICE 时遵循以下原则：

- CICE 可以独立运行（stand-alone mode）或耦合运行（coupled mode）。顶层驱动程序、耦合层或模式封装层（model cap）均可驱动 CICE。
- Icepack 单柱物理模块应相互独立，由作用于单个网格单元的方法组成，不依赖底层基础设施。CICE 必须按 Icepack 指定的接口和方式调用它。

## Git 工作流与拉取请求

[开发者资源索引](https://github.com/CICE-Consortium/About-Us/wiki/Resource-Index#information-for-developers)提供以下内容的详细文档：参与模式开发、软件开发实践指南、Git 工作流指南（包括拉取请求的流程与要求）以及文档工作流指南。

## 编码标准

总体而言，CICE 代码应遵守以下约定：

- 遵循现有编码和命名约定。
- 编写易读的代码。使用有意义的变量名；循环和条件语句缩进 2 或 3 个空格；适当纵向对齐相似元素；在代码各处添加简洁注释。
- 在共享模块中声明共同参数，不要在多处硬编码同一个参数。
- 在可行范围内保持默认配置的输出逐位一致（bit-for-bit）；新功能通过 namelist 选项启用。
- 保持热量、水和盐的全局守恒。
- 尽量少用 C 预处理器（C preprocessor，CPP）指令；它们只应处理构建相关的差异，例如 NetCDF 等可选库，或部分编译器不支持的 Fortran 特性。运行时选项应使用 namelist。CPP 宏名应全部大写。
- 所有模块顶部应设置：

  ```fortran
  implicit none
  private
  ```

  任何公开的模块接口或数据都应显式声明。
- 所有子程序和函数都应定义与接口名称匹配的 `subname` 字符参数，例如：

  ```fortran
  character(len=*),parameter :: subname='(advance_timestep)'
  ```

- 应通过 `icepack_intfc` 模块访问 Icepack 的公开接口，例如：

  ```fortran
  use icepack_intfc, only: icepack_init_parameters
  ```

- Icepack 本身不直接写输出或中止运行，而是提供访问这些功能的方法。每次调用 Icepack 后，应调用 `icepack_warnings_flush`，将输出刷新到 CICE 日志，并检查 `icepack_warnings_aborted`，以便在发生 Icepack 错误时中止运行：

  ```fortran
  call icepack_physics()
  call icepack_warnings_flush(nu_diag)
  if (icepack_warnings_aborted()) call abort_ice(error_message=subname, file=__FILE__, line=__LINE__)
  ```

- 调用 NetCDF 或 PIO 后，分别使用 `ice_check_nc` 或 `ice_pio_check` 检查返回错误。
- 使用 `abort_ice` 子程序中止模式运行，不使用 `stop` 或 `MPI_ABORT`。调用 `abort_ice` 时传入可选参数 `file=__FILE__` 和 `line=__LINE__`，有助于调试。
- 除与中止调用有关的输出外，只从主任务向标准输出写信息。按现有标准使用单元 `nu_diag`；不使用单元 5 或 6，也不使用 `print` 语句。
- 引入新的 Fortran 特性或外部库时，要兼顾可用性以及在尽可能多的机器和编译器上构建的需要。遇到这类需求时，鼓励开发者尽早联系 Consortium，讨论需求和实现方案。

原文：[dg_about.rst](../../source/developer_guide/dg_about.rst)
