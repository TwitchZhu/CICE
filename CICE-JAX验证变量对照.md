# CICE-JAX 验证变量对照

**第一部分先列建议关注的物理量和文件变量名，后面再解释类别、层、代码名称和计算关系。** 本文按当前 `gx3_5step_simple` 的 **5 个冰厚类别、7 个冰层、1 个雪层** 说明。文末的详细对照按主题折叠，查某个量时再展开。

## 一、建议关注哪些变量：先看这份清单

下面分成三组：**核心状态、当前已启用过程的状态、解释差异的诊断量**。先看第一组，再补上第二组；第三组帮助判断差异来自哪个物理过程。

表中的 history / restart 都是**文件里的变量名**。写“由……计算”表示没有独立字段；写“待开启”表示当前配置未开启该 history 输出。两个文件列在同一行，表示描述同一个物理方面，**不一定可以直接相减**；必要的转换在最后一列说明。

### 1.1 核心状态：面积、体积、热状态、盐度和运动

| 建议关注的物理量 | history 变量名 | restart 变量名 | 需要关注到什么程度 |
| --- | --- | --- | --- |
| 海冰密集度 / 面积比例 | `aice`、`aicen` | `aicen` | 看总量 `aice`，也看全部 5 类 `aicen`；总量是五类别之和 |
| 海冰体积 / 等效冰厚 | `hi`、`vicen` | `vicen` | 看总量 `hi`，也看全部 5 类 `vicen`；`hi` 是冰体积除以网格面积 |
| 雪体积 / 等效雪厚 | `hs`、`vsnon` | `vsnon` | 看总量 `hs`，也看全部 5 类 `vsnon`；`hs` 是雪体积除以网格面积 |
| 冰内部热状态：焓与温度 | `Tinz`〔待开启〕 | `qice001`～`qice007`，温度转换还需 `sice001`～`sice007` | **5 类 × 7 冰层全部检查**；restart 保存焓，history 输出由焓和盐度计算的温度 |
| 冰内部盐度 | `Sinz`〔待开启〕；`sice` 是汇总诊断 | `sice001`～`sice007` | **5 类 × 7 冰层全部检查**；二维 `sice` 不能替代逐层 `Sinz` |
| 雪内部热状态：焓与温度 | `Tsnz`〔待开启〕 | `qsno001` | **5 类 × 1 雪层全部检查**；restart 保存焓，history 输出由焓计算的温度 |
| 冰 / 雪表面温度 | `Tsfc` | `Tsfcn` | restart 保留全部 5 类；history 是类别聚合值；表面温度不等于内部第 1 层温度 |
| 海冰水平速度 | `uvel`、`vvel` | `uvel`、`vvel` | 两个方向分量都看；不分冰厚类别，不分垂直层 |

**这一组是主要验收对象，但只看 `aice、hi、hs` 三个汇总结果不够。** 五类别和各垂直层的分布也会影响后续演化。

### 1.2 当前已启用过程：还需关注这些状态

这组用于检查当前启用的物理反馈，以及从 restart 继续计算所需的状态。它们不必采用与核心状态相同的误差判据。

| 建议关注的物理量 | history 变量名 | restart 变量名 | 对应关系 / 检查范围 |
| --- | --- | --- | --- |
| 冰龄 | `iage` | `iage` | restart 保留 5 类、单位秒；history 聚合后输出、单位年 |
| 一年冰份额 | `FYarea`〔待开启〕 | `FY` | restart 保留 5 类；`FYarea` 为聚合示踪物诊断，不直接等于网格一年冰面积比例 |
| 平整冰面积、体积份额 | `alvl`、`vlvl` | `alvl`、`vlvl` | restart 是各类别内的份额；history 是网格上的面积比例和等效体积厚度 |
| 融池面积份额 | `apondn`；汇总量 `apond`、`apond_ai` | `apnd`，并结合 `alvl`、`aicen` | 逐类检查；当前平整冰方案中，`apnd` 是融池占平整冰面积的份额 |
| 融池水深与池盖冰厚 | `hpondn`、`hpond`、`ipond` 及相应二维 `_ai` 字段 | `hpnd`、`ipnd` | 逐类原生深度看 restart；history 已加权，例如 `hpondn=apnd×hpnd` |
| 融池相关雪深差、融化热通量份额 | 无直接标准字段 | `dhs`、`ffrac` | 全部 5 类；用于检查融池后续计算所需状态 |
| EVP 内应力 | `trsig`、`sig1`、`sig2`、`sigP` 是诊断量 | `stressp_1`～`stressp_4`、`stressm_1`～`stressm_4`、`stress12_1`～`stress12_4` | restart 的 **12 个字段全部检查**；后缀是角点，不是冰层；history 诊断不能替代全部状态 |
| 动力有冰掩膜与冰洋应力 | 无原样掩膜；`strocnx`、`strocny` 是 U 点应力诊断 | `iceumask`、`strocnxT`、`strocnyT` | 动力掩膜不同于静态陆海掩膜；两文件应力的网格位置和处理不同，不能直接逐点相减 |

此外，检查重启连续性时还要核对 restart 的输入或记忆量：`swvdr、swvdf、swidr、swidf、scale_factor、sst、frzmlt、fsnow、frz_onset`。它们的含义和 history 对应放在后文“诊断与强迫”中。

### 1.3 诊断量：判断差异是否影响物理结果，并定位原因

这些量主要从 history 查看，通常没有可直接对照的 restart 字段。这里先列推荐名称，单位、加权和时间阶段在后面的详细表格解释。

| 建议关注的物理量 | history 变量名 | restart 中如何对应 |
| --- | --- | --- |
| 冰、雪热含量与冰盐质量 | `sihc`、`sisnhc`、`sisaltmass`〔均待开启〕 | 热含量可由分类体积和各层焓重建；盐质量还需按模型定义转换盐度和密度 |
| 反照率与辐射有效融池面积 | `albsni`、`alvdr`、`alvdf`、`alidr`、`alidf`；`apeffn`、`apeff_ai` | 没有原样字段；有效融池面积不等于原生 `apnd` |
| 表面热量与短波收支 | `fsurf_ai`、`fcondtop_ai`、`flat_ai`、`fsens_ai`、`flwdn`、`flwup_ai`、`fswdn`、`fswabs_ai`、`fswthru_ai` | 没有一一对应字段 |
| 冰底及冰洋热量、淡水、盐交换 | `fbot`、`fhocn_ai`、`fresh_ai`、`fsalt_ai` | 没有一一对应字段 |
| 生长与融化过程 | `congel`、`frazil`、`snoice`、`meltt`、`meltb`、`meltl`、`melts` | 没有一一对应字段 |
| 热力、动力引起的面积和体积变化 | `daidtt`、`daidtd`、`dvidtt`、`dvidtd` | 没有一一对应字段 |
| 海冰变形 | `divu`、`shear`、`vort`〔`vort` 待开启〕 | 没有原样字段；需要速度及对应离散算子才能重建 |

还建议从主要状态计算**区域或半球海冰面积、冰体积、雪体积、冰雪能量**，同时保留空间分布，避免正负偏差在总量中抵消。这些是派生指标，不是新的文件变量名。

上述清单依据本地 CICE / Icepack 文档、restart/history writer 和当前配置整理；源码出处保留在文末。是否实际出现在某次 history 文件中，仍由该次输出开关决定。这份清单确定“看什么”，不规定未经标定的数值容差。

## 二、先分清“类别”和“层”

一个海洋网格中可以同时有不同厚度的海冰，模型把它们分成 5 个**冰厚类别**。每个类别再有自己的雪层和冰层。

```text
一个水平网格
├─ 类别 1：最薄的一类冰 ─┐
├─ 类别 2             │
├─ 类别 3             ├─ 每个类别都有下面这套垂直结构
├─ 类别 4             │
└─ 类别 5：最厚的一类冰 ─┘

每个类别的垂直结构（从上向下）
    冰/雪表面温度          ← 边界温度，不是一个内部层
    雪层 1                ← 当前只有这一层雪
    冰层 1                ← 最上层冰
    冰层 2
    冰层 3
    冰层 4
    冰层 5
    冰层 6
    冰层 7                ← 最下层冰，接触海洋
```

因此，一个网格有 **5 × 7 个冰层温度值、5 × 7 个冰层盐度值、5 × 1 个雪层温度值**。空类别仍占数组位置，但不代表实际存在冰或雪。

每类的 7 个冰层把该类冰厚等分；不同类别的“第 1 层”不一定一样厚。**类别 1 不是冰层 1。**

## 三、history：先找变量名，再选类别和层

history 用于查看模拟结果。理解它时，先把变量分成下面 **4 种结构**。这里按阅读需要分组，文件中这些变量通常是平铺的，并没有对应的四个 NetCDF 文件夹。

下图是重点关注的字段，**不是文件全部变量清单**。标有“待开启”的字段，当前配置没有开启输出；其他诊断的开关见文末“当前输出设置”。

```text
history 文件
│
├─ A. 每个网格一个值：没有类别轴，也没有垂直层轴
│   ├─ aice           总海冰密集度（海冰覆盖网格的比例）
│   ├─ hi             总冰体积 / 网格面积，称为等效冰厚
│   ├─ hs             总雪体积 / 网格面积，称为等效雪厚
│   ├─ uvel、vvel     海冰水平速度的两个分量
│   ├─ Tsfc           各类别聚合后的表面温度
│   ├─ sice           各类别、各冰层聚合后的盐度
│   ├─ iage           聚合后的冰龄
│   ├─ FYarea         一年冰诊断〔待开启〕
│   ├─ alvl、vlvl     平整冰面积比例、等效体积厚度
│   ├─ ardg、vrdg     脊化冰面积比例、等效体积厚度
│   ├─ apond、hpond、ipond   融池面积、等效池深、等效池盖厚度
│   └─ 通量、反照率、变化率等二维诊断（在下面单列）
│
├─ B. 每个网格分 5 个类别：有类别轴，没有垂直层轴
│   ├─ aicen          类别 1、2、3、4、5 各自的冰面积比例
│   ├─ vicen          类别 1、2、3、4、5 各自的冰体积 / 网格面积
│   ├─ vsnon          类别 1、2、3、4、5 各自的雪体积 / 网格面积
│   ├─ apondn         类别 1、2、3、4、5 各自的融池面积份额
│   ├─ hpondn         类别 1、2、3、4、5 各自的面积加权池深
│   └─ apeffn         类别 1、2、3、4、5 各自的辐射有效融池面积份额
│
├─ C. 每个网格分 5 个类别，每类再分 7 个冰层
│   ├─ Tinz           冰内部温度，°C〔待开启〕
│   │   └─ 每个类别内：
│   │       ├─ 冰层 1 温度
│   │       ├─ 冰层 2 温度
│   │       ├─ 冰层 3 温度
│   │       ├─ 冰层 4 温度
│   │       ├─ 冰层 5 温度
│   │       ├─ 冰层 6 温度
│   │       └─ 冰层 7 温度
│   └─ Sinz           冰内部总体盐度，ppt〔待开启〕
│       └─ 每个类别内：
│           ├─ 冰层 1 盐度
│           ├─ 冰层 2 盐度
│           ├─ 冰层 3 盐度
│           ├─ 冰层 4 盐度
│           ├─ 冰层 5 盐度
│           ├─ 冰层 6 盐度
│           └─ 冰层 7 盐度
│
└─ D. 每个网格分 5 个类别，每类再分 1 个雪层
    └─ Tsnz           雪内部温度，°C〔待开启〕
        └─ 每个类别内：雪层 1 温度
```

**`Tinz` 是一个变量，里面装着 5 类 × 7 层；不是 35 个不同名字的变量。** `Sinz` 同理。`Tsfc` 是表面温度，不能替代内部温度 `Tinz` 或 `Tsnz`。

上面四种结构写成文件维度，就是：

```text
A：变量[时间, 南北位置, 东西位置]
   例：hi(time, nj, ni)

B：变量[时间, 类别, 南北位置, 东西位置]
   例：aicen(time, nc=5, nj, ni)

C：变量[时间, 类别, 冰层, 南北位置, 东西位置]
   例：Tinz(time, nc=5, nkice=7, nj, ni)

D：变量[时间, 类别, 雪层, 南北位置, 东西位置]
   例：Tsnz(time, nc=5, nksnow=1, nj, ni)
```

A 类中的其他诊断可以按物理用途继续查：

- **动力学**：`divu`（散度）、`shear`（剪切）、`vort`（涡度）、`trsig`（内应力迹诊断）。
- **热量与辐射**：`fsurf_ai`（表面热通量）、`fcondtop_ai`（顶面导热）、`fswdn`（入射短波）、`fswabs`（吸收短波）、`fbot`（冰底热通量）、`albsni`（雪冰反照率）。
- **冰洋交换**：`fhocn`（热通量）、`fresh`（淡水通量）、`fsalt`（盐通量）。
- **生长与融化**：`congel`（底部生长）、`frazil`（新冰形成）、`snoice`（雪冰形成）、`meltt/meltb/meltl/melts`（冰顶/冰底/侧向/雪融化）。
- **面积和体积变化**：`daidtt/daidtd`（热力/动力面积变化率）、`dvidtt/dvidtd`（热力/动力体积变化率）。
- **热含量与盐质量**：`sihc`（冰热含量）、`sisnhc`（雪热含量）、`sisaltmass`（冰盐质量），当前均待开启。

这些诊断的单位、加权方式和运行时名称，在文末分组对照中查。网格经纬度、面积、掩膜和坐标也存在于 history 中，它们用于定位，不属于上面的海冰状态分组。

## 四、restart：层号直接写进变量名

restart 用于恢复模型运行，保存的是继续计算需要的状态。它与 history 最明显的结构差别是：**冰焓、冰盐度的每一层分别存成一个变量。**

下面列出当前已有比较日志中的 **54 个状态字段**：28 个带类别轴，26 个只有水平空间轴。时间记在文件属性中，这些字段没有 time 轴。restart 结构依据已有日志和 writer 核对，并非本次直接读取 NetCDF 得到。

```text
restart 文件
│
├─ A. 带类别轴的字段：每个字段内部都有类别 1、2、3、4、5
│   │
│   ├─ 面积和体积（3 个字段）
│   │   └─ aicen、vicen、vsnon
│   │
│   ├─ 表面温度（1 个字段）
│   │   └─ Tsfcn
│   │
│   ├─ 冰内部焓（7 个字段，J/m³，描述冰的热状态）
│   │   ├─ qice001    冰层 1 的焓
│   │   ├─ qice002    冰层 2 的焓
│   │   ├─ qice003    冰层 3 的焓
│   │   ├─ qice004    冰层 4 的焓
│   │   ├─ qice005    冰层 5 的焓
│   │   ├─ qice006    冰层 6 的焓
│   │   └─ qice007    冰层 7 的焓
│   │
│   ├─ 冰内部总体盐度（7 个字段，ppt）
│   │   ├─ sice001    冰层 1 的盐度
│   │   ├─ sice002    冰层 2 的盐度
│   │   ├─ sice003    冰层 3 的盐度
│   │   ├─ sice004    冰层 4 的盐度
│   │   ├─ sice005    冰层 5 的盐度
│   │   ├─ sice006    冰层 6 的盐度
│   │   └─ sice007    冰层 7 的盐度
│   │
│   ├─ 雪内部焓（1 个字段，J/m³）
│   │   └─ qsno001    雪层 1 的焓
│   │
│   ├─ 冰龄、一年冰和平整冰（4 个字段）
│   │   └─ iage、FY、alvl、vlvl
│   │
│   └─ 融池（5 个字段）
│       ├─ apnd       融池面积占平整冰面积的份额
│       ├─ hpnd       池内水深
│       ├─ ipnd       池盖冰厚
│       ├─ dhs        雪深差
│       └─ ffrac      用于融化池盖的热通量份额
│
└─ B. 不带类别轴、也不带垂直层轴的字段
    ├─ 水平速度（2 个）：uvel、vvel
    ├─ EVP 内应力（12 个；后缀 1–4 是角点，不是冰层）
    │   ├─ stressp_1、stressp_2、stressp_3、stressp_4
    │   ├─ stressm_1、stressm_2、stressm_3、stressm_4
    │   └─ stress12_1、stress12_2、stress12_3、stress12_4
    ├─ 动力掩膜（1 个）：iceumask
    ├─ 冰洋应力（2 个）：strocnxT、strocnyT
    ├─ 短波分量和缩放因子（5 个）：swvdr、swvdf、swidr、swidf、scale_factor
    └─ 其他输入或记忆量（4 个）：sst、frzmlt、fsnow、frz_onset
```

restart 的两种数组结构：

```text
A：变量[类别, 南北位置, 东西位置]
   例：qice005(ncat=5, nj, ni)  ← 层号已写在名字中，不再有冰层轴

B：变量[南北位置, 东西位置]
   例：uvel(nj, ni)
```

所以，**`qice001` 是“所有 5 个类别的第 1 冰层焓”，不是“第 1 类冰的全部层”。**

## 五、用一个例子串起文档、代码和两个文件

假设要找 **第 3 类冰、第 5 冰层** 的热状态。下面的数组索引用 Python 的 0 起始规则；`:` 表示保留整个水平空间。

```text
要找的物理位置：第 3 类 → 第 5 冰层
│
├─ 科学文档 Fundvars
│   └─ q_ink，取 n=3、k=5：该层的体积焓，J/m³
│
├─ JAX 运行时（仅对当前 tracer 配置）
│   └─ ice_state.trcrn[:, :, 5, 2]
│       第三轴的槽位 5 保存第 5 层冰焓；第四轴索引 2 表示第 3 类
│
├─ restart
│   ├─ qice005[2, :, :]        该层焓，J/m³
│   └─ sice005[2, :, :]        该层盐度，ppt
│
└─ history（需要先开启剖面输出）
    ├─ Tinz[t, 2, 4, :, :]     该层温度，°C
    └─ Sinz[t, 2, 4, :, :]     该层盐度，ppt
```

这里的对应关系是：**restart 的焓和盐度一起决定 history 的温度**。`qice005` 与 `Tinz` 不能直接相减，因为它们分别是焓和温度。对于有效有冰类别，`sice005` 与 `Sinz` 对应同一层的总体盐度。

再记住三组最常用的面积、体积对应：

- 文档 `a_in` → 运行时 `ice_state.aicen` → restart `aicen` → history `aicen`；五类别相加得到 history `aice`。
- 文档 `v_in` → 运行时 `ice_state.vicen` → restart `vicen` → history `vicen`；五类别相加得到 history `hi`。
- 文档 `v_sn` → 运行时 `ice_state.vsnon` → restart `vsnon` → history `vsnon`；五类别相加得到 history `hs`。

**`hi` 是等效冰厚。** 例如一个网格一半有冰、冰区实际厚度为 2 m，那么 `aice=0.5`、`hi=1 m`。有冰区平均厚度才是 `hi/aice=2 m`。

## 六、验证时先看哪些，再查哪些

1. **先看整体结果**：history 的 `aice、hi、hs、uvel、vvel`，了解冰的范围、数量和运动。
2. **再看内部是否一致**：五类别的 `aicen、vicen、vsnon`，逐类表面温度，以及全部 7 层冰焓/盐度和 1 层雪焓。history 的 `Tinz、Sinz、Tsnz` 用于查看内部温盐剖面。
3. **接着看当前启用的过程**：冰龄、一年冰、平整冰、融池和 EVP 应力；这些状态会影响后续演化。
4. **用通量和收支解释差异**：查看热量、淡水、盐、生长融化和面积/体积变化率。

当前 `Tinz、Sinz、Tsnz` 尚未开启，所以已有 history 不能展示完整内部剖面。本文没有修改输出开关。总量相近也不能替代逐类逐层检查；数值上允许多大差异，需要另外标定，本文件不规定任意固定容差。

## 详细对照：按需要展开

以下保留各变量的含义、单位、运行时名称、文件名称和源码依据。编号 2–13 是详细条目的内部编号，条目中的章节引用也指这里。

<details>
<summary>2．读后面表格时，只需知道这几个名字</summary>

## 2 读表前的小说明

前面的结构树已经说明变量有哪些类别和层，这里只解释后面表格中会遇到的代码名称。

### 2.1 为什么很多变量的代码名称都是 trcrn？

模型把表面温度、各层焓、各层盐度、冰龄等量，集中存进一个叫 **`trcrn` 的大数组**。这些量在文档中称为“示踪物”。

**“槽位”就是某个量在这个数组里的存放位置。** 它不是额外的冰层，也不是冰厚类别。

例如当前 JAX 配置中：

- 槽位 `0`：存表面温度，写到 restart 时叫 `Tsfcn`。
- 槽位 `1`：存第 1 冰层焓，写到 restart 时叫 `qice001`。
- 槽位 `2`：存第 2 冰层焓，写到 restart 时叫 `qice002`。
- 槽位 `9`：存第 1 冰层盐度，写到 restart 时叫 `sice001`。

每个槽位都保留 5 个类别和所有水平网格的数据。后面表格里的 `nt_qice`、`nt_sice` 等，是代码给这些位置起的名字；例如 `nt_qice` 指向第 1 冰层焓的位置，后面的冰层依次排列。改变层数或物理开关后，数字槽位可能变化。[C2][S1]

如果只查 restart 和 history 的对应关系，可以直接看这两列，暂时跳过“槽位”列。

### 2.2 为什么第 3 类、第 5 层，在代码里写成 2 和 4？

因为日常描述从 **1** 开始数，Python/JAX 数组从 **0** 开始数：

- 类别 1、2、3、4、5 → Python 下标 0、1、2、3、4。
- 冰层 1、2、3、4、5、6、7 → Python 下标 0、1、2、3、4、5、6。

因此 `Tinz[t,2,4,:,:]` 就是：**时刻 t，第 3 类，第 5 冰层，所有水平网格的温度**。这里 `:` 表示取该方向的全部位置。

后面的表格同时列出 Fortran 和 JAX 槽位。Fortran 这里从 1 编号，所以同一个量的槽位通常比 JAX 大 1。例如第 1 冰层焓：Fortran 槽位 2，JAX 槽位 1。

### 2.3 看到文档符号时，怎样读？

在 Fundvars 的符号中，`n` 表示**冰厚类别**，`k` 表示**垂直层**；`i` 表示冰（ice），`s` 表示雪（snow）。例如 `q_ink` 就读成“第 n 类、第 k 冰层的焓”。具体含义和单位直接查后面的对应表。

代码中还有一个少了末尾 `n` 的 **`trcr`**：它保存各类别按模型规定的权重汇总后的示踪物。它与保留五类别的 `trcrn` 不同，也不能简单地用五类别算术平均代替。[F2][I2]

后面能量公式中的 `R[vicen,n]`，只是“restart 中第 n 类的 vicen”的文字简写；`Q[n,k]`、`S[n,k]` 分别指第 n 类第 k 冰层的焓和盐度。这些不是文件里的新变量名，也不是可直接执行的 Python 索引。

</details>

<details>
<summary>3．面积与厚度：aice / aicen、hi / vicen、hs / vsnon</summary>

## 3 冰面积、冰体积与雪体积

本节符号直接对应 CICE Fundamental Variables 和 Tracers。[F1][F2]

| 文档符号/名称 | 运行时变量 | restart | history | 含义、单位与关系 |
| --- | --- | --- | --- | --- |
| `a_in`，fractional ice area | `ice_state.aicen(:,:,n)` | `aicen`，保留 n | `aicen`，保留 n | 第 n 类冰占**整个网格面积**的比例，1；不是它占全部海冰的比例 |
| `v_in = a_in h_in` | `ice_state.vicen(:,:,n)` | `vicen`，保留 n | `vicen`，保留 n | 第 n 类冰体积/网格面积，m³/m² = m |
| `v_sn = a_in h_sn` | `ice_state.vsnon(:,:,n)` | `vsnon`，保留 n | `vsnon`，保留 n | 第 n 类上的雪体积/网格面积，m；不是当地实际雪厚 |
| `h_in`，类别实际冰厚 | 由 `vicen/aicen` 得到；局部过程常用 `hin` 等 | 无独立字段；从 `vicen/aicen` 重建 | 标准 `vicen` 不是它；可由分类场重建；CMIP `siitdthick` 是相关输出 | 第 n 类有冰面积上的实际厚度，m；`aicen` 足够大时才做除法 |
| `h_sn`，类别实际雪厚 | 由 `vsnon/aicen` 得到；局部过程常用 `hsn` 等 | 无独立字段；重建 | 可由分类场重建；CMIP `siitdsnthick` 是相关输出 | 第 n 类有冰面积上的雪厚，m；不是雪覆盖部分的条件平均雪厚 |
| `Σ_n a_in`，总海冰密集度 | `ice_state.aice` | 无独立 `aice`；求和 `aicen` | `aice`；瞬时专用 `aisnap` | 网格被海冰覆盖的比例，1 |
| 开水面积比例 | `ice_state.aice0` | 无独立字段；汇总后由 `max(1-Σaicen,0)` 重建 | 无同名常规核心字段；由 `aice` 重建 | 网格中开水的面积比例，1；需在状态汇总完成的同一检查点使用 |
| `Σ_n v_in`，总等效冰厚 | `ice_state.vice` | 求和 `vicen` | **`hi`**；瞬时专用 `hisnap` | 整个网格上的冰体积/网格面积，m |
| `Σ_n v_sn`，总等效雪厚 | `ice_state.vsno` | 求和 `vsnon` | **`hs`** | 整个网格上的雪体积/网格面积，m |
| 有冰区平均冰厚 | `vice/aice`，派生 | 由分类总量重建 | `hi/aice` 仅对同一瞬时样本适用；CMIP `sithick` 是相关输出 | 冰覆盖部分的平均厚度，m；不是原生 `hi` |
| 有冰区平均雪厚 | `vsno/aice`，派生 | 由分类总量重建 | `hs/aice` 仅对同一瞬时样本适用；CMIP `sisnthick` 是相关输出 | 冰覆盖部分的平均雪厚，m |

`aice`、`vice`、`vsno` 聚合量必须与对应分类状态比较；总量一致而类别分配不一致，仍可能导致不同的后续融化、导热和脊化。CMIP 厚度字段涉及有冰时加权，不能把时间平均的 `hi/aice` 与瞬时比值或逐步比值平均混为一谈。[H1]

</details>

<details>
<summary>4．逐层热状态：qice、sice、qsno、Tinz、Sinz、Tsnz、表面温度</summary>

## 4 分层热力学与盐度

### 4.1 垂直层的位置

每个冰厚类别都有自己的冰柱和雪柱。当前每个冰柱分为 7 个等厚冰层，每层厚度为该类别实际冰厚 `h_in/7`；雪柱分为 1 层，厚度为 `h_sn`。层号从上向下；雪在冰上方。各类别的层号相同，不表示其实际深度相同。[I1]

| 介质/层 k | Python 层索引 | 从该介质顶面向下的范围 | 层中心 |
| --- | --- | --- | --- |
| 冰层 1，最上层冰 | 0 | `0–h_in/7` | `h_in/14` |
| 冰层 2 | 1 | `h_in/7–2h_in/7` | `3h_in/14` |
| 冰层 3 | 2 | `2h_in/7–3h_in/7` | `5h_in/14` |
| 冰层 4 | 3 | `3h_in/7–4h_in/7` | `7h_in/14` |
| 冰层 5 | 4 | `4h_in/7–5h_in/7` | `9h_in/14` |
| 冰层 6 | 5 | `5h_in/7–6h_in/7` | `11h_in/14` |
| 冰层 7，贴近冰底 | 6 | `6h_in/7–h_in` | `13h_in/14` |
| 雪层 1，当前唯一雪层 | 0 | `0–h_sn`，从雪面向下 | `h_sn/2` |

层中心表达式用于说明几何位置；history 的 `VGRDi/VGRDs` 本身只写层号。表面温度是边界温度，不是最上层内部温度；`Tsfcn` 不能替代 `Tinz` 第 1 层或 `Tsnz` 第 1 层。

### 4.2 冰体积焓和冰内温度，七层全部展开

Fundvars 的 `q_ink` 是第 n 类、第 k 冰层的**体积焓**，单位 J/m³。它是融化该体积冰并升至 0 °C 所需能量的负值，通常为负。代码将其保存为体积依赖的 tracer，数值本身没有预乘类别体积。[F1]

下表 JAX 槽位指 `ice_state.trcrn[:,:,槽位,n-1]`；Fortran 槽位指 `trcrn(:,:,槽位,n,iblk)`。数字仅适用于本配置。

| 冰层 | 文档符号 | Fortran tracer 槽位 | JAX tracer 槽位 | restart 字段 | history 温度字段与关系 |
| --- | --- | --- | --- | --- | --- |
| 1 | `q_in1` | `nt_qice+0 = 2` | `nt_qice+0 = 1` | `qice001` | `Tinz[t,n-1,0,:,:] = T(qice001,sice001)` |
| 2 | `q_in2` | `nt_qice+1 = 3` | `nt_qice+1 = 2` | `qice002` | `Tinz[t,n-1,1,:,:] = T(qice002,sice002)` |
| 3 | `q_in3` | `nt_qice+2 = 4` | `nt_qice+2 = 3` | `qice003` | `Tinz[t,n-1,2,:,:] = T(qice003,sice003)` |
| 4 | `q_in4` | `nt_qice+3 = 5` | `nt_qice+3 = 4` | `qice004` | `Tinz[t,n-1,3,:,:] = T(qice004,sice004)` |
| 5 | `q_in5` | `nt_qice+4 = 6` | `nt_qice+4 = 5` | `qice005` | `Tinz[t,n-1,4,:,:] = T(qice005,sice005)` |
| 6 | `q_in6` | `nt_qice+5 = 7` | `nt_qice+5 = 6` | `qice006` | `Tinz[t,n-1,5,:,:] = T(qice006,sice006)` |
| 7 | `q_in7` | `nt_qice+6 = 8` | `nt_qice+6 = 7` | `qice007` | `Tinz[t,n-1,6,:,:] = T(qice007,sice007)` |

`T(q,S)` 是当前热力学方案的 `icepack_ice_temperature(q,S)`，单位 °C。它不是简单的单位换算；mushy 方案中盐度也参与转换。**标准 history 注册器没有逐层原样输出 `qice001…qice007` 的对应字段。** 验证原生焓用 restart；验证温度剖面用启用后的 `Tinz`。[R1][H1]

### 4.3 冰层总体盐度，七层全部展开

下表用 `S_bulk(n,k)` 表示层总体盐度，这是为区分含盐总量而采用的说明记号；Fundvars 的 `S_i` 描述的是与层体积相乘后的含盐量，并不等于下表 tracer 数值。`sice` 是 bulk salinity，不是液态卤水盐度或液相体积分数。

| 冰层 | 物理量 | Fortran tracer 槽位 | JAX tracer 槽位 | restart 字段 | history 剖面 |
| --- | --- | --- | --- | --- | --- |
| 1 | `S_bulk(n,1)`，ppt | `nt_sice+0 = 10` | `nt_sice+0 = 9` | `sice001` | `Sinz[t,n-1,0,:,:]` |
| 2 | `S_bulk(n,2)`，ppt | `nt_sice+1 = 11` | `nt_sice+1 = 10` | `sice002` | `Sinz[t,n-1,1,:,:]` |
| 3 | `S_bulk(n,3)`，ppt | `nt_sice+2 = 12` | `nt_sice+2 = 11` | `sice003` | `Sinz[t,n-1,2,:,:]` |
| 4 | `S_bulk(n,4)`，ppt | `nt_sice+3 = 13` | `nt_sice+3 = 12` | `sice004` | `Sinz[t,n-1,3,:,:]` |
| 5 | `S_bulk(n,5)`，ppt | `nt_sice+4 = 14` | `nt_sice+4 = 13` | `sice005` | `Sinz[t,n-1,4,:,:]` |
| 6 | `S_bulk(n,6)`，ppt | `nt_sice+5 = 15` | `nt_sice+5 = 14` | `sice006` | `Sinz[t,n-1,5,:,:]` |
| 7 | `S_bulk(n,7)`，ppt | `nt_sice+6 = 16` | `nt_sice+6 = 15` | `sice007` | `Sinz[t,n-1,6,:,:]` |

有冰类别中 `Sinz` 从盐度 tracer 复制；当前实现只在 `vicen > puny` 时复制，其他位置置零后再经过输出掩膜处理。不能对空类别要求 `Sinz` 与 restart 盐度无条件逐点相等。

history 中二维 `sice` 是类别聚合的层盐度再做垂向平均，只有一个数/网格，**不包含七层剖面信息**。即使二维 `sice` 一致，七层之间的盐分分配仍可能不同。[H1]

### 4.4 雪焓、雪温和表面温度

| 文档符号/物理量 | Fortran 位置 | JAX 位置 | restart | history | 含义 |
| --- | --- | --- | --- | --- | --- |
| `q_sn1`，唯一雪层体积焓 | `trcrn(:,:,nt_qsno,n,iblk)`，槽 9 | `trcrn[:,:,8,n-1]` | `qsno001[n-1,:,:]` | 无原生逐层焓字段 | 雪体积焓，J/m³，通常为负 |
| 第 1 雪层内部温度 | `icepack_snow_temperature(q_sn1)` | 同名转换函数 | 不单独保存，来自 `qsno001` | `Tsnz[t,n-1,0,:,:]` | 雪层内部温度，°C |
| `T_sfn`，冰/雪表面温度 | `trcrn(:,:,nt_Tsfc,n,iblk)`，槽 1 | `trcrn[:,:,0,n-1]` | **`Tsfcn[n-1,:,:]`** | **`Tsfc` 是二维聚合场**，没有一一对应的逐类 `Tsfcn` 标准输出 | 表面边界温度，°C；有雪时是雪面温度 |

无冰时表面温度有 `Tf` 默认处理。二维 `Tsfc` 不能替代五个类别的 `Tsfcn`；温度的 °C 接近零不表示热含量接近零，也不适合仅用相对误差判定。

### 4.5 五类乘七层的具体覆盖范围

以下每行都是必须覆盖的一个类别，列 1–7 是全部冰层。单元格 `(c,k)` 同时对应 `Tinz/Sinz` 的 Python 类别与层索引。

| 类别 | 冰层1 | 冰层2 | 冰层3 | 冰层4 | 冰层5 | 冰层6 | 冰层7 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `(0,0)` | `(0,1)` | `(0,2)` | `(0,3)` | `(0,4)` | `(0,5)` | `(0,6)` |
| 2 | `(1,0)` | `(1,1)` | `(1,2)` | `(1,3)` | `(1,4)` | `(1,5)` | `(1,6)` |
| 3 | `(2,0)` | `(2,1)` | `(2,2)` | `(2,3)` | `(2,4)` | `(2,5)` | `(2,6)` |
| 4 | `(3,0)` | `(3,1)` | `(3,2)` | `(3,3)` | `(3,4)` | `(3,5)` | `(3,6)` |
| 5 | `(4,0)` | `(4,1)` | `(4,2)` | `(4,3)` | `(4,4)` | `(4,5)` | `(4,6)` |

例如第 3 类第 5 冰层：restart 焓为 `qice005[2,:,:]`，盐度为 `sice005[2,:,:]`；history 温度为 `Tinz[t,2,4,:,:]`，盐度为 `Sinz[t,2,4,:,:]`。两文件的最后两轴都是 `(j,i)`。

雪层也覆盖全部类别：`qsno001[0,:,:]`、`[1,:,:]`、`[2,:,:]`、`[3,:,:]`、`[4,:,:]`，对应 `Tsnz[t,0,0,:,:]` 至 `Tsnz[t,4,0,:,:]`。

### 4.6 Fundvars 的分层能量到底在哪里

Fundvars 的 `e_ink`、`e_snk` 是**单位网格面积上的层能量**，单位 J/m²；当前版本不把它们作为独立主状态保存，而是保存体积与焓。[F1]

| 层能量符号 | 从 restart 重建，固定类别 n | history |
| --- | --- | --- |
| `e_in1` | `R[vicen,n] × R[qice001,n] / 7` | 无独立逐层字段 |
| `e_in2` | `R[vicen,n] × R[qice002,n] / 7` | 无独立逐层字段 |
| `e_in3` | `R[vicen,n] × R[qice003,n] / 7` | 无独立逐层字段 |
| `e_in4` | `R[vicen,n] × R[qice004,n] / 7` | 无独立逐层字段 |
| `e_in5` | `R[vicen,n] × R[qice005,n] / 7` | 无独立逐层字段 |
| `e_in6` | `R[vicen,n] × R[qice006,n] / 7` | 无独立逐层字段 |
| `e_in7` | `R[vicen,n] × R[qice007,n] / 7` | 无独立逐层字段 |
| `e_sn1` | `R[vsnon,n] × R[qsno001,n] / 1` | 无独立逐层字段 |
| 全类别全冰层能量 | `Σ_n Σ_k e_ink` | **`sihc`**，J/m²，需启用 |
| 全类别全雪层能量 | `Σ_n e_sn1` | **`sisnhc`**，J/m²，需启用 |

不要将体积焓直接相加当成总能量；不要漏掉 `vicen/7`，也不要因为焓通常为负而擅自改变符号。由有效体积加权后的能量误差，能补充判断很小类别中的大 tracer 相对误差究竟有多大物理影响。

Fundvars 的层含盐量可按其定义重建为 `(vicen/7) × S_bulk(n,k)`。若要报告物理盐质量，还需一致的密度和 ppt 单位换算；标准 `sisaltmass` 为 kg/m²，走当前热力学密度/盐度诊断路径，不能把它与体积乘盐度的数值直接等同。[H1]

</details>

<details>
<summary>5．海冰速度与变形：uvel、vvel、散度、剪切和涡度</summary>

## 5 海冰速度与变形

| 文档符号/名称 | 运行时 | restart | history | 单位与含义 |
| --- | --- | --- | --- | --- |
| Fundamental Variables 的向量 `u` 的 x 分量 | `ice_state.uvel` | `uvel` | `uvel` | m/s，B 网格 U 点沿模型网格 x 方向速度 |
| 向量 `u` 的 y 分量 | `ice_state.vvel` | `vvel` | `vvel` | m/s，B 网格 U 点沿模型网格 y 方向速度 |
| 冰速大小 | `sqrt(uvel²+vvel²)`，派生 | 由两速度分量重建 | `icespd` | m/s；不能代替两个分量 |
| 冰漂方向 | 由两速度分量转换 | 无独立字段 | `icedir` | 度；当前实现为来向，涉及 `atan2` 和 180° 偏移 |
| 速度散度 | `ice_state.divu` | 无 | `divu` | 内部 s⁻¹；history 为 %/day，即乘 `86400×100` |
| 剪切变形率 | `ice_state.shear` | 无 | `shear` | 内部 s⁻¹；history 为 %/day |
| 涡度诊断 | `ice_state.vort` | 无 | `vort` | 内部 s⁻¹；history 为 %/day |
| 冰强度 `P`，动力学文档 | `ice_state.strength` | 无独立字段 | `strength` | N/m，垂向积分的海冰强度，不是 N/m² 的边界应力 |

`uvel/vvel` 不应直接解释为地理东向、北向速度；比较到外部产品前须处理网格旋转。当前 B 网格两分量都位于 U 点，不能与 T 点标量不经处理地逐点配对。`divu/shear/vort` 在历史输出中按瞬时诊断处理。[F3][H1]

</details>

<details>
<summary>6．冰龄、一年冰、平整冰与融池</summary>

## 6 冰龄、平整冰与融池

这组变量的数学名称主要来自 Icepack Tracers 和对应物理章节，**并非全部出现在 CICE Fundvars 中**。无 Fundvars 独立符号时，本文明确使用其他章节名称，不另造一个“官方符号”。[I2]

### 6.1 冰龄、一年冰和平整冰

| 文档符号/名称 | Fortran / JAX tracer 槽位 | restart | history | 含义与转换 |
| --- | --- | --- | --- | --- |
| `τ_age`，ice age | `nt_iage = 17 / 16` | `iage`，逐类，s | `iage`，二维，years | 冰体积加权年龄；history 将聚合年龄除以 `86400×days_per_year`，本配置一年 365 天 |
| `a_FY`，first-year ice tracer | `nt_FY = 18 / 17` | `FY`，逐类，1 | **`FYarea`**，二维 | 一年冰面积依赖示踪物；restart 数值是类别冰面积中的份额，网格一年冰面积比例可重建为 `Σ aicen×FY` |
| `a_lvl`，level ice area fraction | `nt_alvl = 19 / 18` | `alvl`，逐类，1 | `alvl`，二维，1 | restart 是类别内平整冰面积份额；history 是网格平整冰面积比例 `Σ aicen×alvl` |
| `v_lvl`，level ice volume fraction | `nt_vlvl = 20 / 19` | `vlvl`，逐类，**1** | `vlvl`，二维，**m** | restart 是类别内平整冰体积份额；history 是 `Σ vicen×vlvl`，即平整冰体积/网格面积 |
| ridged ice area | 从 `aicen`、`alvl` 派生 | 无独立 `ardg` | `ardg`；分类 `ardgn` | 网格脊化冰面积比例：`Σ aicen×(1-alvl)`；分类场保留各项 |
| ridged ice volume | 从 `vicen`、`vlvl` 派生 | 无独立 `vrdg` | `vrdg`；分类 `vrdgn` | 脊化冰体积/网格面积：`Σ vicen×(1-vlvl)`，m |

`FYarea` 的名称与注释容易被理解成网格总面积；当前 writer 实际取聚合 tracer `trcr(nt_FY)`。应按该实现读数，并将物理网格总量 `Σaicen×FY` 单独计算，不能仅凭名称把两者视为同一量。[H1][H3]

上述所有 restart 示踪物都覆盖类别 1、2、3、4、5；数字槽位位于 `trcrn` 的第三轴，类别在第四轴。海冰年龄不等于“所有冰物质的冻结时间”；其增长和混合遵循 Icepack 的 ice-age 定义。[I2]

### 6.2 平整冰融池的原生状态

本配置 `tr_pond_lvl=true`。`apnd` 的基底是平整冰面积；其他融池方案的基底可能是整个海冰面积，因此下表中乘 `alvl` 的公式仅用于平整冰融池。

| 文档名称/符号 | 运行时位置 | restart | history 对应 | 含义、单位与限制 |
| --- | --- | --- | --- | --- |
| `a_pnd`，pond area fraction | `trcrn` 的 `nt_apnd`，F=21，JAX=20 | `apnd`，逐类 | **`apondn`**，逐类 | 平整冰面积中被融池覆盖的比例，1；这里 `apondn` 直接输出 tracer，未乘 `alvl` |
| `h_pnd`，pond depth | `trcrn` 的 `nt_hpnd`，F=22，JAX=21 | `hpnd`，逐类 | **`hpondn` 不是原样池深** | 原生池深，m；当前 `hpondn = apnd×hpnd` |
| pond ice lid thickness | `trcrn` 的 `nt_ipnd`，F=23，JAX=22 | `ipnd`，逐类 | 无直接原样逐类 `ipondn` 标准字段；二维 `ipond/ipond_ai` 经过面积加权 | 融池表面再冻结冰盖厚度，m，不是雪层或第 1 冰层 |
| 雪深差 | `ice_arrays_column.dhsn` | **`dhs`**，逐类 | 无直接标准字段 | 海冰表面雪与池盖上雪的深度差，m |
| 融池冰盖融化热通量份额 | `ice_arrays_column.ffracn` | **`ffrac`**，逐类 | 无直接标准字段 | 用于融化池盖的表面热通量份额，1 |
| radiation-effective pond area | `ice_arrays_column.apeffn` | 无直接字段 | `apeffn`，逐类 | 辐射计算使用的有效融池面积比例；与原生池面积不同，包含池盖/积雪等遮蔽处理的影响 |

注意 CICE 的 tracer 表中可见 `nt_vpnd` 文字，但本地实际代码的池深索引为 **`nt_hpnd`**；文件名以 restart writer 为准。[F2][R2][H2]

### 6.3 融池汇总诊断和物理总量

在同一状态时刻定义：

- 第 n 类融池面积/网格面积：`Apond_n = aicen_n × alvl_n × apnd_n`。
- 第 n 类融池水体积/网格面积：`Vpond_n = Apond_n × hpnd_n`，单位 m。
- 第 n 类池盖体积/网格面积：`Vlid_n = Apond_n × ipnd_n`，单位 m。
- 网格总融池面积、池水体积和池盖体积分别对 n=1…5 求和。

这些是建议从 restart 计算的派生诊断，不是新增的标准 NetCDF 字段。它们能帮助判断 `apnd` 在近乎干涸的融池中发生大比例差异时，池水体积和辐射反馈是否也出现显著差异。

| history 字段 | 当前代码累积的量 | 单位 | 是否能直接与 restart 同名量比较 |
| --- | --- | --- | --- |
| `apondn` | 分类 `apnd_n` | 1 | 可在同一时刻/掩膜下比较 `apnd_n` |
| `hpondn` | 分类 `apnd_n×hpnd_n` | m | 不能直接比较 `hpnd_n` |
| `apond` | 平整冰方案中 `trcr(nt_alvl)×trcr(nt_apnd)` | 1 | 海冰面积中的池面积份额，不是原生分类 `apnd` |
| `apond_ai` | `aice_init×apond` | 1 | 网格面积权重采用步初 `aice_init`，并非无条件等于步末 restart 重建值 |
| `hpond` | `apond×trcr(nt_hpnd)` | m | 在整个海冰面积上平均的等效池深，不是池内真实水深 |
| `hpond_ai` | `aice_init×hpond` | m | 网格平均池水体积厚度型诊断，注意时间点 |
| `ipond` | `apond×trcr(nt_ipnd)` | m | 海冰面积平均池盖厚度型诊断 |
| `ipond_ai` | `aice_init×ipond` | m | 网格面积加权池盖厚度型诊断 |
| `apeffn` | `ice_arrays_column.apeffn` | 1 | 不是 `apondn` 的别名 |
| `apeff_ai` | `ice_flux.apeff_ai` | 1 | 网格平均辐射有效融池面积 |
| `apeff` | 有冰处 `apeff_ai/aice` | 1 | 海冰面积归一的辐射有效融池面积 |

融池 history 的精确归一方式应以代码表达式为准，而不是只看字段 long_name。即使 `hist_avg=false`，`aice_init` 与步末 `aice` 的区别也仍存在。[H2]

</details>

<details>
<summary>7．动力记忆状态：12 个 EVP 应力、动力掩膜与冰洋应力</summary>

## 7 EVP 应力、掩膜与冰洋应力

### 7.1 四个离散角点全部列出

动力学文档的 `σ_11`、`σ_22`、`σ_12` 是垂向积分的内应力，单位 N/m。B 网格 EVP 保存其组合；下列运行时数组属于 `ice_flux`，每项都是二维空间场，不带类别轴或垂向层轴。[F3][R1]

| 角点 c | 运行时与 restart 字段 | 文档应力组合 | history 原样输出 |
| --- | --- | --- | --- |
| 1 | `stressp_1` | `(σ_11+σ_22)_1` | 无 |
| 2 | `stressp_2` | `(σ_11+σ_22)_2` | 无 |
| 3 | `stressp_3` | `(σ_11+σ_22)_3` | 无 |
| 4 | `stressp_4` | `(σ_11+σ_22)_4` | 无 |
| 1 | `stressm_1` | `(σ_11-σ_22)_1` | 无 |
| 2 | `stressm_2` | `(σ_11-σ_22)_2` | 无 |
| 3 | `stressm_3` | `(σ_11-σ_22)_3` | 无 |
| 4 | `stressm_4` | `(σ_11-σ_22)_4` | 无 |
| 1 | `stress12_1` | `(σ_12)_1` | 无 |
| 2 | `stress12_2` | `(σ_12)_2` | 无 |
| 3 | `stress12_3` | `(σ_12)_3` | 无 |
| 4 | `stress12_4` | `(σ_12)_4` | 无 |

每个角点可重建 `σ_11=(stressp+stressm)/2`、`σ_22=(stressp-stressm)/2`。history 的 `trsig` 在当前 EVP 路径是四个 `stressp` 的平均；它不能替代 12 个原生状态。

history 的 `sig1/sig2` 是无量纲归一化主应力诊断，`sigP` 是压力诊断（N/m），均不是 `stressp/stressm` 的直接改名。在 B 网格上，`sig1/sig2/sigP` 的元数据指向 U 网格东北角诊断，`trsig` 在 T 网格。[H1]

### 7.2 掩膜与边界应力

| 物理量 | 运行时 | restart | history | 说明 |
| --- | --- | --- | --- | --- |
| 动力计算的有冰掩膜 | `ice_dyn_shared.iceUmask` | **`iceumask`**，以 0/1 写出 | 无完全对应的常规字段 | 当前运行时为布尔值；不是静态陆海掩膜 `umask` |
| T 点冰洋应力 x 分量 | `ice_flux.strocnxT_iavg` | **`strocnxT`** | 无同名原样核心输出 | N/m²，T 点按有冰面积归一的冰洋应力 |
| T 点冰洋应力 y 分量 | `ice_flux.strocnyT_iavg` | **`strocnyT`** | 无同名原样核心输出 | 同上 |
| U 点海洋对冰应力 x | `ice_flux.strocnxU` | 不以此名保存 | **`strocnx`** | N/m²，与 `strocnxT` 的位置/处理不同，不能直接逐点比较 |
| U 点海洋对冰应力 y | `ice_flux.strocnyU` | 不以此名保存 | **`strocny`** | N/m² |
| U 点大气对冰应力 x | `ice_flux.strairxU` | 无 | **`strairx`** | N/m² |
| U 点大气对冰应力 y | `ice_flux.strairyU` | 无 | **`strairy`** | N/m² |

静态网格/陆海掩膜应在统一网格后精确一致。动态 `iceumask` 则受面积/质量阈值影响；若不同，应定位阈值附近的状态和动力后果，不应与静态掩膜合并处理。

</details>

<details>
<summary>8．诊断与强迫：辐射、热量、淡水、盐、生长和融化</summary>

## 8 辐射、通量、过程收支与输入参照

这些量多数不是 Fundvars 中的基本状态，来源是边界强迫、热力学、短波与动力章节。表中明确给出物理名称；没有 Fundvars 专属符号时不人为补一个。

### 8.1 restart 中另外保存的输入或记忆量

| 文档物理名称 | 运行时 | restart | history | 单位/注意事项 |
| --- | --- | --- | --- | --- |
| 可见光直射入射短波 | `ice_flux.swvdr` | `swvdr` | 没有对应的原样四分量核心字段；总入射短波见 `fswdn` | W/m² |
| 可见光漫射入射短波 | `ice_flux.swvdf` | `swvdf` | 同上 | W/m² |
| 近红外直射入射短波 | `ice_flux.swidr` | `swidr` | 同上 | W/m² |
| 近红外漫射入射短波 | `ice_flux.swidf` | `swidf` | 同上 | W/m² |
| 短波缩放因子 | `ice_flux.scale_factor` | `scale_factor` | **`scale_factor`**，开关却是 **`f_fswfac`** | 1；辐射时间安排中使用的记忆量 |
| 海表温度 | `ice_flux.sst` | `sst`，取决于 standalone/混合层路径 | `sst` | °C |
| 海洋冻结/融化热势 | restart 取 `ice_flux.frzmlt`；history 取 `ice_flux.frzmlt_init` | `frzmlt`，同上 | `frzmlt` | W/m²；正值有利于形成新冰，负值融冰；两个文件虽同名，保存阶段可能不同 |
| 降雪质量通量 | `ice_flux.fsnow` | `fsnow`，当前融池重启路径写出 | **`snow` / `snow_ai`** | 内部/restart kg/m²/s；history cm/day，除以淡水密度并换算；`snow_ai` 还乘 `aice_init` |
| 开始结冰的年内日序 | `ice_flux.frz_onset` | `frz_onset`，当前 FY 重启路径写出 | `frz_onset` | day of year；不是时间步计数 |

这些记录对重启连续性和强迫一致性有用，不应全都被当成“模型预测的主要状态”。`fswdn` 与四分量求和的比较还需对齐辐射更新时刻。

### 8.2 推荐保留的辐射与热通量

本表所列 `ice_flux.*` 为二维运行时场，除特别注明外，当前核心 restart 不保存对应量。

| 文档物理名称 | 运行时 | history 字段 | 单位/转换 |
| --- | --- | --- | --- |
| 净表面热通量 | `ice_flux.fsurf`；writer 乘 `ice_state.aice` | `fsurf_ai` | W/m²，面积加权诊断；不存在必须同名的 `fsurf_ai` 主状态 |
| 顶面导热通量 | `ice_flux.fcondtop`；writer 乘 `ice_state.aice` | `fcondtop_ai` | W/m²，面积加权诊断 |
| 潜热通量 | `ice_flux.flat`；`_ai` 输出由 writer 乘 `aice` | `flat` / `flat_ai` | W/m²；`flat` 的符号约定为向下正 |
| 感热通量 | `ice_flux.fsens`；`_ai` 输出由 writer 乘 `aice` | `fsens` / `fsens_ai` | W/m²；`fsens` 向下正 |
| 向下长波 | `ice_flux.flw` | **`flwdn`** | W/m²，向下正 |
| 向上长波项 | `ice_flux.flwout`；`_ai` 输出由 writer 乘 `aice` | **`flwup` / `flwup_ai`** | W/m²；本实现 `flwup` 仍采用向下为正的通量符号，不能因名称有 up 就翻转符号 |
| 入射短波 | `ice_flux.fsw` | **`fswdn`** | W/m²，向下正 |
| 冰雪海洋吸收短波 | `ice_flux.fswabs`；`_ai` 输出由 writer 乘 `aice` | `fswabs` / `fswabs_ai` | W/m²；`fswabs_ai` 是面积加权输出 |
| 冰内吸收短波 | `ice_flux.fswint_ai` | `fswint_ai` | W/m²，不含表面吸收 |
| 透过冰进入海洋的短波 | `ice_flux.fswthru` / `fswthru_ai` | `fswthru` / `fswthru_ai` | W/m²；正值使海洋获得热量 |
| 冰底热通量 | `ice_flux.fbot` | `fbot` | W/m²；正值使海洋获得热量 |
| 输出给海洋的热通量 | `ice_flux.fhocn` / `fhocn_ai` | `fhocn` / `fhocn_ai` | W/m²；不能把它与 `fbot` 自动当成同一个量 |
| 冰向海洋的淡水通量 | `ice_flux.fresh` / `fresh_ai` | `fresh` / `fresh_ai` | 内部 kg/m²/s；history cm/day；正值使海洋获得淡水 |
| 冰向海洋的盐通量 | `ice_flux.fsalt` / `fsalt_ai` | `fsalt` / `fsalt_ai` | kg/m²/s；正值使海洋获得盐 |

`_ai` 通常提示冰面积加权，但不能据后缀推断所有字段均能通过“当前总面积 × 无后缀场”恢复。不同通量是在不同阶段计算和累积的；检查收支时应使用对应过程的定义与时间点。[H1]

分类表面通量也值得保留，均无当前核心 restart 对应：

| 运行时源量与 writer 运算 | history 字段 | 维度 | 含义 |
| --- | --- | --- | --- |
| `ice_flux.fsurfn × ice_state.aicen_init` | `fsurfn_ai` | 五类别 | 各类别净表面热通量，W/m² |
| `ice_flux.fcondtopn × ice_state.aicen_init` | `fcondtopn_ai` | 五类别 | 各类别顶面导热通量，W/m² |
| `max(fsurfn-fcondtopn,0) × aicen_init` | `fmelttn_ai` | 五类别 | 各类别用于表面融化的净热通量，W/m² |
| `ice_flux.flatn × ice_state.aicen_init` | `flatn_ai` | 五类别 | 各类别潜热通量，W/m² |
| `ice_flux.fsensn × ice_state.aicen_init` | `fsensn_ai` | 五类别 | 各类别感热通量，W/m² |

### 8.3 反照率与有效融池反馈

| 运行时 `ice_flux` 源量 | history 字段 | history 单位 | 物理含义 |
| --- | --- | --- | --- |
| `alvdr` | `alvdr` | % | 可见光直射反照率 |
| `alvdf` | `alvdf` | % | 可见光漫射反照率 |
| `alidr` | `alidr` | % | 近红外直射反照率 |
| `alidf` | `alidf` | % | 近红外漫射反照率 |
| `awtvdr×alvdr_ai + awtidr×alidr_ai + awtvdf×alvdf_ai + awtidf×alidf_ai`，由 writer 计算 | `albsni` | % | 雪冰宽波段反照率；`awt*` 是相应光谱权重参数，不是独立的 `ice_flux.albsni` 状态 |
| `albice` | `albice` | % | 裸冰反照率诊断 |
| `albsno` | `albsno` | % | 雪反照率诊断 |
| `albpnd` | `albpnd` | % | 融池反照率诊断 |

这些量没有当前核心 restart 原样字段。运行时反照率通常用 0–1，history 乘 100；部分字段还包含有日照筛选和冰面积归一/加权。比较 history 对 history 时保持同一输出设置；从 restart 重建时不能只做乘 100。[H1]

### 8.4 面积、体积和融化过程诊断

下表运行时都在 `ice_flux`，history 与运行时同名，当前核心 restart 不直接保存。

| 变量名称 | 文档中的物理过程 | 内部量 → history 单位 |
| --- | --- | --- |
| `daidtt` | 热力学引起的冰面积变化率 | s⁻¹ → %/day，乘 `86400×100` |
| `daidtd` | 动力学引起的冰面积变化率 | s⁻¹ → %/day |
| `dvidtt` | 热力学引起的冰体积变化率 | m/s → cm/day，乘 `86400×100` |
| `dvidtd` | 动力学引起的冰体积变化率 | m/s → cm/day |
| `congel` | 底部凝结生长 | 当步厚度增量 m → cm/day，乘 `86400×100/dt` |
| `frazil` | 新冰/霰冰形成 | 当步厚度增量 m → cm/day |
| `snoice` | 雪冰形成 | 当步厚度增量 m → cm/day |
| `meltt` | 冰顶融化 | 当步融化量 m → cm/day |
| `meltb` | 冰底融化 | 当步融化量 m → cm/day |
| `meltl` | 侧向融化 | 当步融化量 m → cm/day |
| `melts` | 雪融化 | 当步融化量 m → cm/day |

这些过程量可解释最终冰体积为何改变，但不能不核对面积权重、源汇和时间点，就把所有名称含 melt/growth 的字段简单相加当成完整守恒方程。

当前案例 `advection='none'`、`kridge=0`，不能用它证明输送和脊化路径正确。验证这些路径时应启用相应配置，保留分类状态和 `dvidtd/daidtd`，必要时增加 `ardgn/vrdgn` 及脊化过程诊断。[C1]

### 8.5 强迫与网格参照

| 检查对象 | 运行时/来源 | 文件对应 | 用途 |
| --- | --- | --- | --- |
| 大气温度 | `ice_flux.Tair`，内部 K | history `Tair`，°C，减冻结点参考常数 | 确认两版接受同一热强迫 |
| 大气速度 | `ice_flux.uatm/vatm` | history `uatm/vatm`，m/s | 确认风强迫一致 |
| 海洋速度 | `ice_flux.uocn/vocn` | history `uocn/vocn`，m/s | 确认海洋动力强迫一致 |
| 海表盐度 | `ice_flux.sss` | history `sss`，ppt | 确认冻结点和盐度边界一致 |
| 网格中心经纬度 | `ice_grid.TLON/TLAT` | history `TLON/TLAT`，degree | 物理位置对齐 |
| U 点经纬度 | `ice_grid.ULON/ULAT` | history `ULON/ULAT`，degree | 速度/应力位置对齐 |
| 网格面积 | `ice_grid.tarea` | history `tarea`，m² | 区域面积、体积、能量积分 |
| 静态掩膜 | 网格陆海定义 | history `tmask`；可选 `umask` | 排除陆地、核对拓扑；不等于动态 `iceumask` |
| 类别边界 | `ice_arrays_column.hin_max` | history `NCAT`，m | 核对类别定义 |

</details>

<details>
<summary>9．如何计算区域冰面积、体积、能量和融池总量</summary>

## 9 从主要状态构造科学验收指标

下面是对原生变量的派生量，不是要求修改模型增加的新状态。区域积分应使用有效海洋网格的 `tarea`；北/南半球可以分别计算，不能用一个全球总量掩盖两半球相反的偏差。

| 指标 | 同一时刻的定义 | 单位 |
| --- | --- | --- |
| 海冰面积 | `Σ_cells tarea × Σ_n aicen_n` | m² |
| 海冰体积 | `Σ_cells tarea × Σ_n vicen_n` | m³ |
| 雪体积 | `Σ_cells tarea × Σ_n vsnon_n` | m³ |
| 冰内能量 | `Σ_cells tarea × Σ_n Σ_k vicen_n Q[n,k]/7` | J |
| 雪内能量 | `Σ_cells tarea × Σ_n vsnon_n qsno001_n` | J |
| 每层盐度加权库存 | `Σ_cells tarea × Σ_n vicen_n S[n,k]/7` | m³·ppt；不是直接的 kg 盐质量 |
| 网格总融池面积比例 | `Σ_n aicen_n alvl_n apnd_n` | 1 |
| 网格池水等效体积厚度 | `Σ_n aicen_n alvl_n apnd_n hpnd_n` | m |
| 网格池盖等效体积厚度 | `Σ_n aicen_n alvl_n apnd_n ipnd_n` | m |

总量以外还需要保留：每类每层误差、空间误差图、误差极值位置、面积/体积加权误差、季节变化与时间增长。海冰 extent 若采用密集度阈值，应另外明确定义阈值；它不同于上述 sea-ice area。

这些指标之间不能相互替代。例如：总能量相同不能证明热量的垂向分布相同；总面积相同不能证明冰厚分布相同；池水体积很小不能单独证明其辐射有效面积差异无关紧要。

</details>

<details>
<summary>10．当前输出设置：哪些已开启，哪些待开启</summary>

## 10 当前案例能输出什么，还缺什么

### 10.1 当前设置

依据 `cases/gx3_5step_simple/ice_in`：[C1]

- `history_precision=8`，当前设置要求双精度历史输出。不要沿用旧初始化测试文档中“history 总是单精度”的前提。
- `histfreq='1',…`、`hist_avg(1)=false`、`hist_time_axis='end'`，主流按步瞬时输出。
- `f_aice/f_hi/f_hs/f_uvel/f_vvel/f_Tsfc/f_sice='1'`。
- `f_aicen/f_vicen/f_vsnon='1'`，分类几何状态开启。
- `f_Tinz/f_Sinz/f_Tsnz='x'`，**分层冰温、冰盐度、雪温未开启**。
- `f_sihc/f_sisnhc/f_sisaltmass='x'`，标准汇总热含量和盐质量诊断未开启。
- `f_iage='1'`，`f_FY='x'`，因此支持 `FYarea` 不等于当前会输出它。
- `f_alvl/f_vlvl/f_ardg/f_vrdg='1'`，分类 `ardgn/vrdgn` 关闭。
- `f_apondn/f_hpondn/f_apeffn='1'`，主要二维融池诊断也开启。
- `f_icespd/f_icedir/f_vort='x'`，可由速度重建冰速；涡度需另行输出或按同一离散算子计算。
- `f_VGRDi/f_VGRDs=false`；启用分层输出时宜同时输出层坐标。

这一节记录配置意图；具体历史文件是否由这份配置生成，仍应结合该次运行证据、变量列表、dtype 和时间属性核对，不能只看当前磁盘上的 namelist。

### 10.2 建议补齐的 history 输出

这是为后续验证提出的配置建议，**本文未修改 namelist**。

| 优先级 | 输出开关 | 用途 |
| --- | --- | --- |
| 首先补齐 | `f_Tinz='1'`、`f_Sinz='1'`、`f_Tsnz='1'` | 七层冰温/盐度、一层雪温，保留五类别 |
| 首先补齐 | `f_VGRDi=true`、`f_VGRDs=true` | 明确垂向层编号 |
| 建议补齐 | `f_sihc='1'`、`f_sisnhc='1'` | 标准网格冰雪热含量诊断，与 restart 重建交叉检查 |
| 根据盐收支需求 | `f_sisaltmass='1'` | 使用模型当前定义的盐质量诊断，并核对密度/盐度换算 |
| 已开启 FY 时建议补齐 | `f_FY='1'` | 输出 `FYarea`，与分类 FY 状态配合 |
| 动力验证时可补齐 | `f_icespd='1'`、`f_vort='1'` | 冰速和涡度的标准诊断 |
| 脊化验证时可补齐 | `f_ardgn='1'`、`f_vrdgn='1'` | 分类脊化面积、体积 |

即使全部开启，标准 history 仍不能完整替代 restart：逐类表面温度、原生逐层焓、原生池深/池盖、12 个 EVP 应力状态等仍应从 restart 检查。

### 10.3 对齐与单位检查

1. **时间**：restart 的 `istep1/myear/mmonth/mday/msec` 是全局属性；history 使用 time 及相关属性。先匹配同一步、同一状态阶段。
2. **瞬时与平均**：均值不能直接与终点 restart 比较；`平均(vice/aice)` 也通常不等于 `平均(vice)/平均(aice)`。
3. **轴**：先对齐维度名，去掉鬼点，统一全局位置，再比较数值。
4. **温度与能量**：`qice` 是 J/m³，`Tinz` 是 °C，`sihc` 是 J/m²，三者不是同量纲。
5. **盐度与盐总量**：`sice00k` 是 ppt，Fundvars 的体积加权盐量和 kg 盐质量不能直接用同一个数字比较。
6. **比例与百分数**：`aice` 是 0–1；许多反照率/CMIP 浓度输出是 %。
7. **有效范围**：分别处理海洋/陆地、空类别、无雪和无融池，不把 `_FillValue` 当数值。
8. **输出精度**：以该次文件实际 dtype 为准；写盘舍入不是内部计算误差标准。

</details>

<details>
<summary>11．以后启用其他物理方案时，需要增加哪些变量</summary>

## 11 未启用物理方案的扩展边界

本配置的主要状态表已包含当前 7 冰层、1 雪层的全部基础热力学示踪物。下列模块当前未开启，因此不把其所有层、组分加入本次核心验收清单；以后开启时必须按该配置展开，不能只沿用本文 24 个槽位。

| 模块 | 开关/索引族 | 应额外关注的物理量 | 查阅入口 |
| --- | --- | --- | --- |
| 高级雪 | `tr_snow`；`nt_smice/nt_smliq/nt_rhos/nt_rsnw` | 每个雪层的冰质量、液态水、密度、粒径 | `ice_restart_column` 的 snow 写出；`ice_history_snow` |
| 浮冰尺寸分布 | `tr_fsd`；`nt_fsd` | 每个浮冰尺寸类别与冰厚类别的联合分布；相关波浪输入 | `ice_restart_column` 的 fsd 写出；`ice_history_fsd` |
| 水同位素 | `tr_iso` | 冰和雪中的各同位素 tracer | `ice_restart_column` 的 iso 写出；`ice_history_bgc` |
| 气溶胶 | `tr_aero`，以及相关 BGC 选项 | 各组分在冰雪层中的含量与通量 | `ice_restart_column` 的 aero/bgc 写出；`ice_history_bgc` |
| 卤水/BGC | `tr_brine`、`tr_bgc_*`、`solve_zbgc` 等 | 卤水高度份额、营养盐、藻类等各层/组分 | 专用 bio 网格与示踪物定义；不能用 7 个热力冰层替代 bio 网格 |
| 其他动力网格/求解器 | `grid_ice='C'/'CD'`、EAP、VP 等 | E/N 点速度、对应应力或结构状态 | 当前 JAX 支持范围与相应 restart 分支；不套用 B 网格角点表 |

这些是扩展范围说明，不是声称当前案例已覆盖或当前 JAX 已支持全部组合。

</details>

<details>
<summary>12．容易混淆的名字、单位与加权方式</summary>

## 12 已核对的名称陷阱

| 容易误认为 | 实际关系 |
| --- | --- |
| Fundvars 的 `h_in` 就是 history `hi` | `h_in=vicen_n/aicen_n`；`hi=Σvicen_n` |
| history `hs` 就是冰面实际雪厚 | `hs=Σvsnon_n`；实际有冰区均厚还需要除冰面积 |
| `qice001` 是第一类别 | 它是第一冰层，字段内部仍有全部五类别 |
| `qice001` 与 `Tinz[...,0,...]` 可直接相减 | 前者是焓，后者是焓与盐度转换出的温度 |
| Fundvars `e_ink` 会以 `eice` 保存 | 当前保存体积与 `qice00k`，能量需相乘重建 |
| `sice` 包含全部垂直盐度信息 | 二维 `sice` 已聚合；剖面是 `Sinz`，原始层状态是 `sice001…007` |
| restart `Tsfcn` 与 history `Tsfc` 一一对应 | 前者五类别，后者二维聚合 |
| restart 和 history 的 `vlvl` 同名同义 | 前者是份额 1，后者是网格平整冰体积厚度 m |
| history `hpondn` 是原生 `hpnd` | 当前代码输出 `apnd×hpnd` |
| `apondn` 是池面积占整个网格的比例 | 平整冰方案下还需乘 `alvl` 和 `aicen` |
| `strocnxT` 就是 history `strocnx` | 一个是 T 点归一场，一个是 U 点诊断 |
| `stressp_1` 的 1 是冰层 | 是离散角点编号 |
| `iage` 的两个文件单位一致 | restart 秒；history 年 |
| `f_fswfac` 输出 `fswfac` | 实际字段名为 `scale_factor` |
| restart `frzmlt` 与 history `frzmlt` 保存同阶段值 | restart 取 `frzmlt`，history 取 `frzmlt_init` |
| 每个 history 字段都有同名运行时数组 | 如 `fsurf_ai=fsurf×aice`、`hpondn=apnd×hpnd`，由 writer 派生 |
| 所有 history 都是单精度 | 当前案例设置 `history_precision=8` |
| `nt_vpnd` 是当前池深代码索引 | 当前源码索引为 `nt_hpnd`，应以实现为准 |

</details>

<details>
<summary>13．依据：配置、日志、CICE / Icepack 文档和源码链接</summary>

## 13 来源与维护依据

以下使用仓库相对路径，便于与代码一起维护。源码行号会随修改改变，因此同时给出模块/过程名作为定位依据。

- **[C1] 当前配置**：[gx3_5step_simple ice_in](cases/gx3_5step_simple/ice_in)。重点为 `grid_nml`、`tracer_nml`、`thermo_nml`、`dynamics_nml` 和各 `icefields_*_nml`。
- **[C2] 当前初始化日志**：[cice.runlog](cases/gx3_5step_simple/cice.runlog)。`icepack_write_tracer_indices` 给出 1 起始槽位；`icepack_init_itd_hist` 给出类别边界。
- **[C3] 已有 restart 比较清单**：[第一步比较日志](cases/gx3_5step_simple/comparison_logs/compare_restart.20261101-163333-220441.log)。用于交叉核对字段名称和形状，不用该日志的 PASS/FAIL 作为本文的验收结论。
- **[F1] 基本变量**：[CICE Fundamental Variables](../CICE/doc/source/science_guide/sg_fundvars.rst)，中文对应[基本变量](../CICE/doc/zh-CN/science_guide/sg_fundvars.md)。这是 `a_in/v_in/v_sn/q_ink/e_ink/e_snk/S_i/T_sfn` 的物理定义来源。
- **[F2] 示踪物守恒与依赖**：[CICE Tracers](../CICE/doc/source/science_guide/sg_tracers.rst)。
- **[F3] 动力学**：[CICE Dynamics](../CICE/doc/source/science_guide/sg_dynamics.rst)。
- **[I1] 层结构、焓和热力学**：[Icepack Thermodynamics](../CICE/icepack/doc/source/science_guide/sg_thermo.rst)。
- **[I2] 冰龄、融池示踪物与依赖**：[Icepack Tracers](../CICE/icepack/doc/source/science_guide/sg_tracers.rst)。
- **[R1] 核心重启映射**：[Fortran ice_restart_driver](../CICE/cicecore/cicedyn/infrastructure/ice_restart_driver.F90)；[JAX 对应实现](cicecore/cicedyn/infrastructure/ice_restart_driver.py)，重点为 `dumpfile`。
- **[R2] 扩展示踪物重启映射**：[Fortran ice_restart_column](../CICE/cicecore/shared/ice_restart_column.F90)；[JAX 对应实现](cicecore/shared/ice_restart_column.py)，重点为 `write_restart_age/FY/lvl/pond_lvl`。
- **[R3] restart 维度与输出类型**：[JAX NetCDF restart writer](cicecore/cicedyn/infrastructure/io/io_netcdf/ice_restart.py)。
- **[H1] 主 history 定义、转换和累积**：[Fortran ice_history](../CICE/cicecore/cicedyn/analysis/ice_history.F90)；[JAX 对应实现](cicecore/cicedyn/analysis/ice_history.py)。重点为 `define_hist_field`、`accum_hist`、分层温度转换及瞬时字段覆盖。
- **[H2] 融池 history**：[Fortran ice_history_pond](../CICE/cicecore/cicedyn/analysis/ice_history_pond.F90)；[JAX 对应实现](cicecore/cicedyn/analysis/ice_history_pond.py)。
- **[H3] 平整冰与脊化 history**：[Fortran ice_history_mechred](../CICE/cicecore/cicedyn/analysis/ice_history_mechred.F90)；[JAX 对应实现](cicecore/cicedyn/analysis/ice_history_mechred.py)。
- **[H4] history 维度、单位与坐标**：[Fortran NetCDF history writer](../CICE/cicecore/cicedyn/infrastructure/io/io_netcdf/ice_history_write.F90)；[JAX 对应实现](cicecore/cicedyn/infrastructure/io/io_netcdf/ice_history_write.py)；[JAX history rank 定义](cicecore/cicedyn/analysis/ice_history_shared.py)。
- **[S1] 运行时状态与槽位**：[ice_state](cicecore/cicedyn/general/ice_state.py)、[ice_flux](cicecore/cicedyn/general/ice_flux.py)、[icepack_tracers](icepack/columnphysics/icepack_tracers.py)。当前 `ntrcr=24`，有效非 BGC tracer 使用槽 0–22，额外保留槽不能误认成一个待验证的物理层。

维护时先检查 namelist 的层数、类别数、物理开关和输出流，再检查 tracer 索引与 writer。数值验收容差、微扰基准和长期 QC 应另行定义；变量字典本身不把任何固定容差标成 CICE 官方要求。

</details>
