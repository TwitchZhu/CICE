# 关于 CICE

CICE 是一种计算效率较高的模式，用于模拟极地海冰的生长、融化和运动。它被设计为大气—海洋—陆地—海冰耦合全球气候模式（coupled global climate model）的一个组件。今天的 CICE 模式是在洛斯阿拉莫斯国家实验室（Los Alamos National Laboratory）科学家二十多年工作的基础上发展而来；与社区成员的合作又大幅完善了当前版本。

CICE 包含几个相互作用的组件：海冰动力学模式（ice dynamics model）依据海冰材料强度模型预测冰盖速度场；输运模式（transport model）描述面积密集度、冰体积及其他状态变量的平流；称为 **Icepack** 的垂直物理包（vertical physics package）包含力学、热力学和生物地球化学模式，用于计算厚度变化以及冰—盐水生态系统（ice-brine ecosystem）的内部演化。当 CICE 与其他地球系统模式组件耦合时，CICE 外部的例程负责准备并执行与外部通量耦合器（flux coupler）的数据交换。

Icepack 以 Git 子模块的形式包含在 CICE 中，其文档位于 [Icepack 文档网站](https://cice-consortium-icepack.readthedocs.io/en/main/index.html)。CICE 和 Icepack 的开发与测试可以同时进行，但两个代码仓库彼此独立。本文档介绍 CICE 模式中除 Icepack 之外的部分。CICE 代码可从 [CICE-Consortium/CICE](https://github.com/CICE-Consortium/CICE) 获取。

标准的独立运行（standalone）CICE 测试配置使用 3 度网格及 1997 年的大气数据，数据获取方式见 [CICE 输入数据](https://github.com/CICE-Consortium/CICE/wiki/CICE-Input-Data)。此外还提供 1 度配置及其数据，以及一些理想化配置。这些数据文件**仅用于代码测试**，不能用于生产运行，也不能视为观测数据。请勿发表基于这些数据集得到的结果。

CICE 可以串行或并行运行，软件包包含多种配置的测试。处理器间的消息传递使用 MPI，也可以使用 OpenMP 线程。

每个 CICE 版本的主要变化见随 [版本发布](https://github.com/CICE-Consortium/CICE/releases) 提供的发布说明。最近一个编号版本以来的功能改进和错误修复见 [CICE 近期变化](https://github.com/CICE-Consortium/CICE/wiki/CICE-Recent-changes)。**使用 CICE 代码时请予以引用。**详情见[如何引用 CICE 代码](citing.md)。

原文采用以下排版约定：代码中的变量名使用`等宽字体`，子程序名使用*斜体*，文件名和目录名使用**粗体**。文档末尾的[综合索引](../cice_index.md)包含许多符号及其数值的术语表。

原文：[about.rst](../../source/intro/about.rst)
