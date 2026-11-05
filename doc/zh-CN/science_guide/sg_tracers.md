# 示踪物

对于每个冰厚类别 $n$，冰面积分数 $a_{in}$、冰体积 $v_{in}$ 和雪体积 $v_{sn}$ 的基本守恒方程为：

$$
\frac{\partial a_{in}}{\partial t}+\nabla\cdot(a_{in}\mathbf u)=0,
\qquad
\frac{\partial v_{in}}{\partial t}+\nabla\cdot(v_{in}\mathbf u)=0,
\qquad
\frac{\partial v_{sn}}{\partial t}+\nabla\cdot(v_{sn}\mathbf u)=0.
$$

冰雪体积也可以用示踪物形式，以冰厚 $h_{in}$ 和雪厚 $h_{sn}$ 等价表示：

$$
\frac{\partial(h_{in}a_{in})}{\partial t}+\nabla\cdot(h_{in}a_{in}\mathbf u)=0,
\qquad
\frac{\partial(h_{sn}a_{in})}{\partial t}+\nabla\cdot(h_{sn}a_{in}\mathbf u)=0.
$$

虽然 CICE 把冰雪体积而非厚度作为状态变量保存，但体积输运使用示踪物形式（见[水平输运](sg_horiztrans.md)）。还可使用许多其他示踪物（tracer），其值保存在 `trcrn` 数组中。它们的输运方程通常是以下三种形式之一：

$$
\frac{\partial(a_{in}T_n)}{\partial t}+\nabla\cdot(a_{in}T_n\mathbf u)=0,
$$

$$
\frac{\partial(v_{in}T_n)}{\partial t}+\nabla\cdot(v_{in}T_n\mathbf u)=0,
$$

$$
\frac{\partial(v_{sn}T_n)}{\partial t}+\nabla\cdot(v_{sn}T_n\mathbf u)=0.
$$

第一式描述表面温度的输运；后两式描述冰雪焓、盐及冰龄和雪龄等体积加权被动示踪物（passive tracer）的输运。每个示踪物场有一个整数索引 `trcr_depend`。若相应守恒方程依次为上述第一、第二或第三式，它分别取 `0`、`1` 或 `2`。示踪物总数 $N_{tr}\ge1$。

下表列出可用示踪物、启用它们的 namelist 标志，以及在示踪物数组中的索引。若三种显式融池方案中的任一种启用，`tr_pond` 即为真。生物地球化学示踪物可以定义在依附于冰面积分数的骨架层（skeletal layer）中；也可以覆盖雪和冰的整个深度，此时使用生物网格（bio grid），并依附于盐水分数（brine fraction）；若不使用盐水分数，则依附于冰体积。

| 标志 | 示踪物数量 | 依附量 | CICE 网格索引 | 生物网格索引 |
| --- | --- | --- | --- | --- |
| `default` | 1 | `aice` | `nt_Tsfc=1` | |
| `default` | 1 | `vice` | `nt_qice` | |
| `default` | 1 | `vsno` | `nt_qsno` | |
| `default` | 1 | `vice` | `nt_sice` | |
| `tr_iage` | 1 | `vice` | `nt_iage` | |
| `tr_FY` | 1 | `aice` | `nt_FY` | |
| `tr_lvl` | 2 | `aice` | `nt_alvl` | |
| | | `vice` | `nt_vlvl` | |
| `tr_pond_lvl` | 3 | `alvl` | `nt_apnd` | |
| | | `apnd` | `nt_vpnd` | |
| | | `apnd` | `nt_ipnd` | |
| `tr_pond_sealvl` | 3 | `aice` | `nt_apnd` | |
| | | `apnd` | `nt_vpnd` | |
| | | `apnd` | `nt_ipnd` | |
| `tr_pond_topo` | 3 | `aice` | `nt_apnd` | |
| | | `apnd` | `nt_vpnd` | |
| | | `apnd` | `nt_ipnd` | |
| `tr_aero` | `n_aero` | `vice, vsno` | `nt_aero` | |
| `tr_iso` | `n_iso` | `vice, vsno` | `nt_iso` | |
| `tr_brine` | | `vice` | `nt_fbri` | |
| `tr_fsd` | `nfsd` | `aice` | `nt_fsd` | |
| `tr_snow` | `nslyr` | `vsno` | `nt_rsnw` | |
| | `nslyr` | `vsno` | `nt_rhos` | |
| | `nslyr` | `vsno` | `nt_smice` | |
| | `nslyr` | `vsno` | `nt_smliq` | |
| `tr_bgc_N` | `n_algae` | `fbri` 或 `(a,v)ice` | `nt_bgc_N` | `nlt_bgc_N` |
| `tr_bgc_Nit` | | `fbri` 或 `(a,v)ice` | `nt_bgc_Nit` | `nlt_bgc_Nit` |
| `tr_bgc_C` | `n_doc` | `fbri` 或 `(a,v)ice` | `nt_bgc_DOC` | `nlt_bgc_DOC` |
| | `n_dic` | `fbri` 或 `(a,v)ice` | `nt_bgc_DIC` | `nlt_bgc_DIC` |
| `tr_bgc_chl` | `n_algae` | `fbri` 或 `(a,v)ice` | `nt_bgc_chl` | `nlt_bgc_chl` |
| `tr_bgc_Am` | | `fbri` 或 `(a,v)ice` | `nt_bgc_Am` | `nlt_bgc_Am` |
| `tr_bgc_Sil` | | `fbri` 或 `(a,v)ice` | `nt_bgc_Sil` | `nlt_bgc_Sil` |
| `tr_bgc_DMS` | | `fbri` 或 `(a,v)ice` | `nt_bgc_DMSPp` | `nlt_bgc_DMSPd` |
| | | `fbri` 或 `(a,v)ice` | `nt_bgc_DMSPd` | `nlt_bgc_DMSPd` |
| | | `fbri` 或 `(a,v)ice` | `nt_bgc_DMS` | `nlt_bgc_DMS` |
| `tr_bgc_PON` | | `fbri` 或 `(a,v)ice` | `nt_bgc_PON` | `nlt_bgc_PON` |
| `tr_bgc_DON` | | `fbri` 或 `(a,v)ice` | `nt_bgc_DON` | `nlt_bgc_DON` |
| `tr_bgc_Fe` | `n_fed` | `fbri` 或 `(a,v)ice` | `nt_bgc_Fed` | `nlt_bgc_Fed` |
| | `n_fep` | `fbri` 或 `(a,v)ice` | `nt_bgc_Fep` | `nlt_bgc_Fep` |
| `tr_bgc_hum` | | `fbri` 或 `(a,v)ice` | `nt_bgc_hum` | `nlt_bgc_hum` |
| `tr_zaero` | `n_zaero` | `fbri` 或 `(a,v)ice` | `nt_zaero` | `nlt_zaero` |
| | 1 | `fbri` | `nt_zbgc_frac` | |

原文中另有被注释掉的 `solve_zsal` 和 `tr_pond_cesm` 表项，它们不属于当前生效的表格。

只要正确设置 `trcr_depend`，用户可以添加任意数量并按守恒方式输运的示踪物。操作说明见[添加示踪物](../developer_guide/dg_other.md#添加示踪物)。有关依附于其他示踪物的示踪物、冰块尺寸分布、高级积雪物理、冰龄、气溶胶、水同位素、盐水层高度和海冰生态系统的更多信息，见 [Icepack 文档](https://cice-consortium-icepack.readthedocs.io/en/main/science_guide/index.html)。

原文：[sg_tracers.rst](../../source/science_guide/sg_tracers.rst)
