# Icepack

CICE 调用 Icepack 单柱物理（column physics）源代码。Icepack 模式另有独立文档，见 [CICE-Consortium/Icepack](https://github.com/CICE-Consortium/Icepack)。

具体来说，CICE 使用 `icepack_intfc.F90` 中定义的方法，通过初始化（init）、查询（query）和写入（write）方法设置、获取并记录 Icepack 的值。它遵循 Icepack 的警告处理方式：每次调用 Icepack 方法后，检查 `icepack_warnings_aborted` 并调用 `icepack_warnings_flush`。CICE 不直接通过 Fortran `use` 语句使用 Icepack 数据，而只通过接口访问这些数据。

原文：[dg_icepack.rst](../../source/developer_guide/dg_icepack.rst)
