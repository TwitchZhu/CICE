# 其他事项

## 使用调试器运行

交互式调试器（interactive debugger）的可用性与使用方法因机器而异。有关系统上可用工具的更多信息，请联系系统管理员。使用交互式调试器运行时，一般按以下步骤操作：

1. 创建案例。
2. 修改 `env` 和 `Macros` 文件，加入适当的模块及编译器／链接器选项。
3. 构建模式。
4. 按需申请交互式硬件资源。
5. 打开 csh shell。
6. 加载 `env.${machine}`。
7. 加载 `cice.settings`。
8. 切换到运行目录。
9. 通过调试器手动启动可执行程序。

## 可重复求和

CICE 用 namelist 变量 `bfbflag` 设置可重复求和（reproducible sums）。使用默认的 EVP 动力学求解器或 EAP 求解器时，CICE 的预报结果不依赖全局求和的实现；无论 `bfbflag` 如何设置，结果都逐位一致。对所有动力学求解器，`bfbflag` 仅影响写入 CICE 日志的全局诊断结果及性能；使用 VP 求解器时，它还影响模式结果。为了获得最佳性能，建议使用 `off`，但不同分解方式下通常不会得到逐位一致的结果。若需要逐位一致，建议使用 `reprosum`，其速度应只比 `lsum8` 略慢。

实数的全局和通常不可重复，因为逐项求和的运算顺序随块分解方式或处理单元（PE）数量改变，数据在内存中的顺序不同，从而产生浮点舍入误差。整数数据的求和不受这种运算顺序影响，应保持逐位一致。

`bfbflag` 是字符型 namelist 变量。各取值在逐位一致性与计算成本之间有不同取舍：

| 取值 | 实现与特点 |
| --- | --- |
| `off` | 默认值，大体相当于 `lsum8`；VP 求解器中的部分计算在选择 `lsum8` 时会走不同代码路径。 |
| `lsum4` | 单精度（4 字节）局部求和，再进行标量 MPI `allreduce`。不同分解方式下几乎不可能逐位一致；对于以双精度（8 字节）变量实现的模式，精度很差，通常不应使用。 |
| `lsum8` | 双精度局部求和，再进行标量 MPI `allreduce`。速度快，但不同分解方式下几乎不可能逐位一致；双精度 CICE 的全局和差异应处于舍入误差量级。 |
| `lsum16` | 四倍精度（16 字节）局部求和，再进行标量 MPI `allreduce`。不同分解方式下很可能逐位一致；但部分编译器或 MPI 实现不支持或不能正确运行。Fortran 与 C 底层数据类型的四倍精度支持及一致性问题可能导致编译失败或结果错误。可通过 CPP 宏 `NO_R16` 关闭相关代码。否则建议不使用，或使用前在目标平台仔细验证。 |
| `reprosum` | 基于有序双整数求和的定点方法；每次全局求和需两次标量归约。极有可能逐位一致，但比 `lsum` 算法略贵。见原文引用的 Mirin 2012。 |
| `ddpdd` | 使用一次标量归约的并行 double-double 算法。很可能逐位一致，但速度和精度均不及 `reprosum`。见原文引用的 He 2001。 |

## 平均值

耦合量和历史输出量可能采用不同的平均方式，取决于该量代表整个网格单元、海冰覆盖部分，还是冰厚类别或融池面积等海冰子区域的平均值。时间平均也必须考虑这些区别。

SIMIP 项目（见原文引用的 Notz 2016）按变量相对于冰面积的性质，将输出量分为**广延量**（extensive）和**强度量**（intensive）。广延量与面积分数成正比；没有海冰的时空位置在其时间平均中贡献零。强度量不与面积分数成正比；在无冰的位置和时刻，其时间平均不应包括零。这可通过对各类别的面积加权强度量求和，再除以类别面积之和实现。冰厚、表面温度及生物地球化学示踪物是强度量。

以下公式忽略一些细节，例如部分通量是在时间步开始时的冰面积上计算，而此面积随后因冰晶冰形成、侧向融化及输运而变化。用于平均和耦合的冰面积应结合模式时间步顺序仔细选取。海冰完全消失或新出现等边界情形会造成平均误差。可以考虑把所有量插值到时间步中点来处理，但当前尚未这样做。

### 冰面积

设 $\mathbf{X}=(x,y)$，$A$ 为网格单元面积（m²），$g$ 为冰厚分布，在离散形式中对应 $n=1,\ldots,ncat$ 的面积分数 $a_n$。冰面积 $A_i$（m²）是各厚度类别面积 $a_nA$ 的总和：

$$
A_i(t)=\int_{ice}g(\mathbf{X},t)\,d\mathbf{X}\sim\sum_{n=1}^{ncat}a_n(t)A.
$$

无量纲冰面积分数为：

$$
a_{ice}(t)=\frac{\int_{ice}g(\mathbf{X},t)\,d\mathbf{X}}{\int_{cell}d\mathbf{X}}\sim\sum_{n=1}^{ncat}a_n(t).
$$

对长度为 $N\Delta t$ 的时段，冰面积的时间平均为：

$$
\bar A_i=\frac{\int_t A_i(t)\,dt}{\int_tdt}
\sim\frac{\sum_{\Delta t}\sum_{n=1}^{ncat}a_nA\Delta t}{N\Delta t}
=\frac{A}{N}\sum_{\Delta t}\sum_{n=1}^{ncat}a_n.
$$

时间平均冰面积分数按定义是广延量：

$$
\bar a_{ice}=\frac{\int_t\int_{ice}g(\mathbf{X},t)\,d\mathbf{X}\,dt}{\int_t\int_{cell}d\mathbf{X}\,dt}
\sim\frac{1}{N}\sum_{\Delta t}\sum_{n=1}^{ncat}a_n.
$$

### 冰体积

冰体积 $V_i$（m³）的时间平均类似：

$$
\bar V_i=\frac{\int_t\int_{cell}\int_0^h g(\mathbf{X},t)\,dz\,d\mathbf{X}\,dt}{\int_tdt}
\sim\frac{A}{N}\sum_{\Delta t}\sum_{n=1}^{ncat}h_na_n.
$$

其中开阔水面的冰厚 $h$ 取零。每平方米网格面积对应的时间平均冰体积（单位为 m）为：

$$
\bar v_{ice}=\frac{\int_t\int_{cell}\int_0^h g(\mathbf{X},t)\,dz\,d\mathbf{X}\,dt}{\int_t\int_{cell}d\mathbf{X}\,dt}
\sim\frac{1}{N}\sum_{\Delta t}\sum_{n=1}^{ncat}h_na_n
=\frac{1}{N}\sum_{\Delta t}\sum_{n=1}^{ncat}v_n,
$$

其中 $v_n=h_na_n$。$v_{ice}$ 在历史输出中标记为 `hi`，可视为对整个网格单元平均的冰厚。每平方米冰面积对应的时间平均冰体积（即平均“实际”冰厚，单位为 m）为：

$$
\bar h_i=\frac{\int_t\int_{ice}\int_0^h g(\mathbf{X},t)\,dz\,d\mathbf{X}\,dt}{\int_t\int_{ice}d\mathbf{X}\,dt}
\sim\frac{\sum_{\Delta t}\sum_{n=1}^{ncat}v_n}{\sum_{\Delta t}\sum_{n=1}^{ncat}a_n}.
$$

雪体积的处理相同。冰雪体积是广延量，冰雪厚度是强度量。

这种时间平均方式对平均期间出现过的全部海冰求“实际”厚度平均。尤其对强度量而言，它与先在每个时间步求类别平均、再对时间求平均的两步法略有不同。后者需要额外除以并再乘以冰面积；当冰面积很小，或单元在有冰与无冰之间切换时，会产生误差。其他示踪物和强度量也有同样问题。两种方法都有效，但当守恒重要时，推荐使用这里给出的平均方式。

### 体积含量

盐和焓等示踪物的总含量对守恒耦合是必要的。设体积示踪物 $b$ 的单位基于 m³，其含量的时间平均为：

$$
\bar B_i=\frac{\int_t\int_{cell}\int_0^h b(\mathbf{X},z,t)g(\mathbf{X},t)\,dz\,d\mathbf{X}\,dt}{\int_tdt}
\sim\frac{A}{N}\sum_{\Delta t}\sum_{n=1}^{ncat}b_nv_n.
$$

每平方米网格面积的时间平均含量为：

$$
\bar b_{ice}\sim\frac{1}{N}\sum_{\Delta t}\sum_{n=1}^{ncat}b_nv_n.
$$

海冰内示踪物的平均值为：

$$
\bar b_i=\frac{\int_t\int_{cell}\int_0^h b(\mathbf{X},z,t)g(\mathbf{X},t)\,dz\,d\mathbf{X}\,dt}{\int_t\int_{cell}\int_0^h dz\,d\mathbf{X}\,dt}
\sim\frac{\sum_{\Delta t}\sum_{n=1}^{ncat}b_nv_n}{\sum_{\Delta t}\sum_{n=1}^{ncat}v_n}.
$$

因此，体积含量变量是广延量，示踪物本身是强度量。

### 表面量

温度等表面量是强度量，其处理与体积示踪物类似，但积分区域是所需表面积而非体积。例如：

$$
T_{ice}(t)=\frac{\int_{ice}T(\mathbf{X},t)g(\mathbf{X},t)\,d\mathbf{X}}{\int_{ice}g(\mathbf{X},t)\,d\mathbf{X}},
\qquad
\bar T_{ice}=\frac{\sum_{\Delta t}\sum_{n=1}^{ncat}T_na_n}{\sum_{\Delta t}\sum_{n=1}^{ncat}a_n}.
$$

由于 $\sum_{n=0}^{ncat}a_n=1$，若开阔水面上该量为零，合并各类别后的量可视为网格单元面积平均值：

$$
T_{cell}=\frac{\sum_{n=0}^{ncat}T_na_n}{\sum_{n=0}^{ncat}a_n}
=\sum_{n=1}^{ncat}T_na_n,
\qquad
T_{ice}=\frac{\sum_{n=1}^{ncat}T_na_n}{\sum_{n=1}^{ncat}a_n}
=\frac{T_{cell}}{a_{ice}}.
$$

这种简化适用于依附于冰面积的示踪物；对体积依附示踪物也有类似形式。按定义，开阔水面上的这些示踪物为零。对 CICE 历史场求时间平均时，先保存各类别合并值作为分子（通常在 Icepack 中），然后在时间上累加，最后在 CICE 中除以累积的冰面积分数或体积。

### 示踪物层级

对于依附于其他示踪物的量（如融池），对同一网格单元不同区域求平均时，分母不同。以不依附于平整冰面积的融池为例，分别对整个网格单元、海冰面积和融池面积平均的融池深度为：

$$
h_{p,cell}\sim\sum_{n=1}^{ncat}h_{pn}a_{pn}a_n,
\quad
h_{p,ice}\sim\frac{\sum_{n=1}^{ncat}h_{pn}a_{pn}a_n}{\sum_{n=1}^{ncat}a_n},
\quad
h_{p,pond}\sim\frac{\sum_{n=1}^{ncat}h_{pn}a_{pn}a_n}{\sum_{n=1}^{ncat}a_{pn}a_n}.
$$

原文还给出了上述三个量各自的面积积分形式；这些离散式与积分式对应。对于平整冰融池，需要再乘平整冰面积因子 $a_{lvl}$。分别对网格单元、全部海冰、平整冰和融池面积平均时：

$$
h_{p,cell}\sim\sum_{n=1}^{ncat}h_{pn}a_{pn}a_{lvln}a_n,
$$

$$
h_{p,ice}\sim\frac{\sum_{n=1}^{ncat}h_{pn}a_{pn}a_{lvln}a_n}{\sum_{n=1}^{ncat}a_n},
\qquad
h_{p,lvl}\sim\frac{\sum_{n=1}^{ncat}h_{pn}a_{pn}a_{lvln}a_n}{\sum_{n=1}^{ncat}a_{lvln}a_n},
$$

$$
h_{p,pond}\sim\frac{\sum_{n=1}^{ncat}h_{pn}a_{pn}a_{lvln}a_n}{\sum_{n=1}^{ncat}a_{pn}a_{lvln}a_n}.
$$

时间平均可依照前述方法计算。

压力脊冰的面积与体积处理略有不同，因为它们根据平整冰面积和体积进行诊断。平整冰面积是依附于冰面积的示踪物，平整冰体积是依附于冰体积的示踪物。其值表示占总冰量的比例；压力脊（变形）冰诊断为剩余部分：面积示踪物 $T_{ardg}=1-T_{alvl}$，体积示踪物 $T_{vrdg}=1-T_{vlvl}$。因此，平整冰和压力脊冰分别占冰面积的平均比例为：

$$
a_{lvl,ice}\sim\frac{\sum_{n=1}^{ncat}a_{lvln}a_n}{\sum_{n=1}^{ncat}a_n},
\qquad
a_{rdg,ice}\sim\frac{\sum_{n=1}^{ncat}(1-a_{lvln})a_n}{\sum_{n=1}^{ncat}a_n}.
$$

对所有类别中的平整冰面积求平均时，平整冰平均厚度为：

$$
h_{lvl}\sim\frac{\sum_{n=1}^{ncat}T_{vlvln}v_n}{\sum_{n=1}^{ncat}T_{alvln}a_n}.
$$

对所有类别中的压力脊冰面积求平均时，变形冰平均厚度为：

$$
h_{rdg}\sim\frac{\sum_{n=1}^{ncat}(1-T_{vlvln})v_n}{\sum_{n=1}^{ncat}(1-T_{alvln})a_n}.
$$

### 添加计时器

要对一段或多段代码计时，先定义计时器，再在代码段前后调用启动与停止命令。所有计时器的结果会同时打印。首先在 `ice_timers.F90` 顶部声明 `timer_[tmr]`（建议在 `mpi/` 和 `serial/` 两个目录中都添加），然后在 `init_ice_timers` 子程序中增加对 `get_ice_timer` 的调用。在待计时代码所在模块中，代码段开头调用 `ice_timer_start(timer_[tmr])`，末尾调用 `ice_timer_stop`。可能还需要在修改的子程序中加入 `use ice_timers`。注意不要把启动命令放在循环外而停止命令放在循环内，或反过来。如需对单独的块计时，可在调用时传入块 ID。

### 添加历史输出字段

若要把变量加入历史输出，在 `ice_history_shared.F90` 中查找 `example`，然后：

1. 为新字段添加输出频率标志。
2. 将该标志加入 namelist，并同步修改 `ice_in`。
3. 添加索引号。

接着在 `ice_history.F90` 中：

1. 广播该标志。
2. 增加对 `define_hist_field` 的调用。
3. 增加对 `accum_hist_field` 的调用。

上述示例适用于标准二维水平场。若数组维度不同，请选用形状相似的历史变量作范例。有些历史变量，特别是示踪物，会按用途（生物地球化学、融池等）归入其他文件。若要为现有变量增加输出频率，见[历史文件](../user_guide/ug_implementation.md#历史文件)。

### 添加示踪物

代码修改必须能够通过 namelist 标志关闭。大多数情况下，包含新功能但关闭该功能的代码，其结果应与未修改代码逐位一致。偶尔必须作出非逐位一致的更改，例如不可避免地改变运算顺序。此时应分阶段修改，隔离非逐位一致部分，以便分别测试本应保持逐位一致的部分。

向 CICE 添加示踪物，也需要大幅修改 Icepack 驱动程序，包括初始化、namelist 标志和重启功能。Icepack 驱动程序的修改应反映 CICE 的需求，但不必完全相同。建议在 `ice_[tracer].F90` 之外所有涉及新示踪物的调用处使用逻辑型 namelist 变量 `tr_[tracer]`，以便其他用户关闭该示踪物。

代码中的可选示踪物包括冰龄、一年冰面积、融池面积和体积、盐水层高度、气溶胶、水同位素，以及平整冰面积和体积（可据此推导压力脊冰的量）。盐度、焓、年龄、气溶胶、同位素、平整冰体积、盐水层高度和多数融池量是体积加权示踪物；一年冰面积、融池面积和平整冰面积是面积加权示踪物。骨架层中的生物地球化学示踪物按面积加权，垂直生物地球化学示踪物按体积加权。

在没有源汇的情况下，气溶胶等体积加权示踪物的总质量（kg）在水平和厚度空间输运中守恒（单个网格单元的质量可以变化），而其浓度（kg/m）沿流动保持不变；尤其在表面或底部融化时浓度不变。示踪物数组中体积加权质量示踪物的正确单位是 kg/m。

代码中有多处必须对守恒的“示踪物体积”而非示踪物本身进行计算。例如，守恒量是 $h_{pnd}a_{pnd}a_{lvl}a_i$，而不是 $h_{pnd}$。守恒量因此按示踪物依赖关系（权重）计算。相关数组包括 `trcr_depend`（表示对面积、冰体积或雪体积的依赖）、`trcr_base`（依赖掩膜）、`n_trcr_strata`（底层示踪物层数）及 `nt_strata`（底层层的索引）。更多信息见 [Icepack 开发者文档](https://cice-consortium-icepack.readthedocs.io/en/main/developer_guide/index.html)。

添加示踪物时，以一个已有示踪物为范例，依次执行：

1. 在 `icepack_tracers.F90` 和 `icepack_[tracer].F90` 中声明示踪物、添加标志与索引，并按 [Icepack 添加示踪物指南](https://cice-consortium-icepack.readthedocs.io/en/main/developer_guide/dg_adding_tracers.html)创建物理例程。
2. 在 `ice_arrays_column.F90` 中声明数组。
3. 在 `ice_init_column.F90` 中初始化数组。
4. 在 `ice_init.F90` 中完成下列工作（部分工作也可以在 `icepack_[tracer].F90` 中完成）：按需声明 `tr_[tracer]`、`nt_[tracer]`；加入逻辑型 namelist 变量 `tr_[tracer]`、`restart_[tracer]`；初始化并广播 namelist 变量；检查冲突并在必要时中止；将 namelist 变量写入诊断输出；在 Icepack 中初始化示踪物标志等（调用 `icepack_init_tracer_flags` 等）；根据 namelist 输入增加已启用示踪物数量 `ntrcr`；定义示踪物依赖关系。
5. 在 `CICE_InitMod.F90` 中初始化示踪物，包括读取重启文件。
6. 在 `CICE_RunMod.F90`、`ice_step_mod.F90` 及必要的其他位置，调用写入示踪物重启数据的例程，并调用 Icepack 或其他例程更新示踪物值（通常从 `ice_step_mod.F90` 调用）。
7. 在 `ice_restart.F90` 中定义二进制、NetCDF 和 PIO 的重启变量。
8. 在 `ice_restart_column.F90` 中编写读写示踪物重启数据的例程。
9. 在 `ice_fileunits.F90` 中增加新的 dump 和重启文件单元。
10. 在 `ice_history_[tracer].F90` 中增加历史输出变量（见上文“添加历史输出字段”）。
11. 在 `ice_in` 的 `tracer_nml` 和 `icefields_nml` 中加入 namelist 变量。推荐默认关闭新功能，并在 `configuration/scripts/options/` 中为推荐配置建立选项文件。
12. 如果必须严格守恒，按 [Icepack 科学文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)中地形融池（topo ponds）的说明添加诊断。
13. 更新文档，包括 `cice_index.rst` 和 `ug_case_settings.rst`。

原文：[dg_other.rst](../../source/developer_guide/dg_other.rst)
