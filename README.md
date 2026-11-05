# CICE-JAX

本分支以官方 CICE6.6.3（`c734c12bfb19632cd700cb06b22c3ea62b4adeae`）为 Git 历史基线，保存 JAX 实现。Fortran 调试版保存在同一仓库的 `CICE-Fortran-debug` 分支，其 Icepack 基线为 `daa41638c6cef298583f35ee4dec5ab1bb077aea`。两个分支分别维护，官方后续更新按需迁移。

仓库保留源码、配置和对照工具；运行生成的历史场、重启文件、日志、性能记录及大型快照不纳入 Git。原始 CICE 与 Icepack 许可证和版权文件分别保留在根目录及 `icepack/`。

## 海冰水平动力学的支持范围

2026-11-01 已补齐以下 JAX 水平动量求解分支，并接入 `step_dyn_horiz`。**“已实现”指源码迁移与调用接线完成；本轮没有运行模型、测试或 Fortran 数值对照。**

- **B 网格二维 EVP**：`kdyn=1`、`grid_ice='B'`、`evp_algorithm='standard_2d'`，保留原有路径。
- **C/CD 网格 EVP**：`kdyn=1`、`grid_ice='C'` 或 `'CD'`、`evp_algorithm='standard_2d'`。包含 T/U 应变和应力、E/N 动量、无滑移边界、两种黏度平均方法、形变和海洋应力；补齐 remap 的边通量调整（EFA）。`C_override_D` 仍作为 CD 的兼容别名。
- **B 网格一维 EVP**：`kdyn=1`、`evp_algorithm='shared_mem_1d'`。`ice_dyn_evp1d.py` 迁移 `ice_dyn_core1d.F90` 的展平数组应变、应力、动量和诊断计算，使用固定形状掩码与邻点索引；不复刻 MPI gather/scatter、OpenMP 和 NUMA 存储管理。
- **B 网格 EAP**：`kdyn=2`。包含应力查表、结构张量演化、断裂重定向、脊化与应力诊断；结构张量通过已有 NetCDF 重启路径读写。
- **B 网格 VP**：`kdyn=3`。包含 Picard/Anderson 非线性迭代、重启 FGMRES、CGS/MGS 正交化，以及 `ident`、`diag`、`pgmres` 预条件；状态中保存残差、收敛标志及线性迭代次数。

入口代码位于 `cicecore/cicedyn/dynamics/ice_dyn_evp.py`、`ice_dyn_evp_cgrid.py`、`ice_dyn_evp1d.py`、`ice_dyn_eap.py`、`ice_dyn_vp.py`。初始化参数与演化数组由 `CICE_JAXState.py` 传递；时间步求解不依赖可变 NumPy 全局状态。初始化、文件 I/O 和日志仍在主机上执行。

迁移保留 Fortran 的配置约束：C/CD 仅配标准 EVP；一维 EVP 不支持 `tripole`/`tripoleT`。EAP、VP 未扩展到 C/CD。C/CD 的特殊 tripole 应力缝合在上游仍标为 TODO，本版保留已有 halo 处理，不宣称补齐该算法。

执行方式存在差别：JAX 用固定大小掩码代替压缩格点列表；一维 EVP 保留原版 `deltaminEVP * (dxT*dyT)` 的局部面积约定；VP 通过局部模板探测提取对角预条件，并重建小型 QR 分解处理 Anderson 历史，代替 Fortran 的显式对角公式和增量 QR 删除。迭代零残差和退化列设有保护。这些实现仍需逐分支数值、性能和梯度验证，不能据此声称逐位等价。

gx3 路径还包含热力学、水平输送和脊化等实现。

`kdyn<=0` 时，与 Fortran 一样跳过动量求解，水平输送仍按 `advection` 配置使用已有速度，脊化仍由 `kridge` 控制。

概率海床应力分支保留当前 Fortran 基准的实际行为：`ice_dyn_shared.F90` 中的 `do n = ncat,-1,1` 因步长为正而不执行，因此厚度截断保持为 `x_k(ncat_i)`，不会随末尾空类别降低。若要修正该循环，应同时修改两版并重新进行数值对照。

早期 gx3 一步对比首次在 `post step_dyn_horiz` 出现差异。该检查点包含 EVP、冰—海洋应力的网格平均以及水平输送；该日志不能单独证明是哪一项造成差异。当前 `cases/gx3_1step/ice_in` 实际运行五步，使用 `ndte=1`、`advection='none'`、`ktransport=0`、`kridge=0`；`cases/gx3_remap_2step/ice_in` 则使用 `ndte=240`、remap 和脊化。对照结果应按各次运行保存的配置区分。

热力学类别面积汇总、线性 ITD 积分、mushy 内部融雪量和 dEdd 高斯积分在源码中按 Fortran 的运算顺序组织。ITD 清理也保留原版的面积更新时机：入口汇总 `aice/aice0`，删除小类别时累加 `aice0`，仅在超额面积修正分支中将二者设为 1/0，不在清理内部额外汇总。这些对齐尚未重新运行数值对照，编译器和 JAX 后端的浮点运算仍可能造成差异。

2026-10-31 静态核对覆盖当前 `gx3_1step`、`gx3_remap_2step`、`gx3_compare`、`gx3_test`、`gx3_diagnose`、`gx3_loop_smoke` 的主计算路径：二进制 gx3 网格与初始化、JRA55 强迫、mushy 热力学、层冰融池、三波段 dEdd、ITD、B 网格标准 EVP、remap/upwind、脊化、混合层及启用历史字段的数值计算和写出。EVP 的 T 点更新范围限定为 Fortran 的物理区及北/东侧一层 ghost；垂直热力学失败标志也按 `tmask | opmask` 屏蔽非计算格点。应力组合、形变求和、光学系数、网格平均和历史字段加权的运算顺序进一步对齐。

历史输出补齐了 `write_histrest=true` 且写模型重启时保存未完成平均区间的路径：仅在 `hist_avg=true` 且 `avgct>0` 时写出双精度原始累积量、计数器和起始时间，不执行常规输出的缩放或陆地掩码。常规输出后同步清零主机与 JAX 状态中的日照/积雪计数器。时间坐标在文件中固定为双精度，平均区间端点保留 Fortran 的单精度内存表示。

以上是源码静态核对，不代表全部可选分支或数值等价验证已经完成。未启用物理、其他网格/边界/强迫、完整 NetCDF 元数据及多流输出组合尚未穷尽；本轮未运行模型、测试、长积分或重启续跑对照。旧对比日志不能证明这些修改后的 `Tsfcn/apnd` 差异已消除。另保留执行方式的差别：JAX 在步末汇总失败标志，Fortran 在调用链中更早中止。

## 迁移后排查：剩余缺口与验证工作

2026-11-01 按时间步入口、初始化/状态交接、异常占位和 Fortran 对应过程进行静态排查。以下是确认的缺口，不表示所有未启用组合均已穷尽。

尚未迁移或仍受限的功能：

- **骨架层 BGC 的特定组合**：`skl_bgc=true` 且 `z_tracers=false` 时，`step_therm2` 的新冰／侧向融化 BGC tracer 索引路径仍明确报错。
- **指定状态的边界恢复**：`ice_restoring.set_restore_var` 的 `defined` 分支未迁移；恢复到初始状态的运行期 `ice_HaloRestore` 已实现。
- **旧式重启与其他 I/O 后端**：CICE v4 二进制重启读取、EAP 旧补充二进制文件的 `restart_ext=true` 路径未完成；目前主重启使用 NetCDF，未迁移完整 PIO/PIO2 后端。
- **完整历史输出元数据**：网格单元角点、bounds/vertices 尚未完整写出；多流输出和全部字段组合还需检查。常规历史输出、模型 dump 和平均区间累积量重启已有实现。
- **remap 可选单调性诊断**：`local_max_min`、`quasilocal_max_min`、`check_monotonicity` 未迁移；上游 `l_monotonicity_check` 固定为 `.false.`。这不等同于缺少重建限幅或守恒检查。
- **并行与耦合基础设施**：MPI 多块划分、分发和可重现归约、OpenMP/NUMA 管理，以及 MCT/NUOPC/MAPL 耦合驱动未迁移；当前是 standalone 单设备 JAX 路径。

上游自身未实现／禁用或明确保留的限制：

- `wave_height_type='coupled'` 在上游也未实现，仍拒绝此配置。
- VP 的 `fpfunc_andacc=2` 在上游直接中止；本版支持 `fpfunc_andacc=1`。EAP 插值查表在上游是编译期关闭分支，本版迁移其实际启用的整数查表路径。
- `mom_nc` 与 `tripoleT`、一维 EVP 与 tripole、C/CD 与 EAP/VP 的组合限制继续保留。
- `update_ocn_f=true` 与 CMIP `siflsaltbot`／`siflfwbot` 的组合、`NO_I8`／`NO_R16`、概率海床应力及 BGC 初始化的已知基准行为，见下文说明。

待验证工作：新增各求解器的编译和运行、C/CD 的 EFA 守恒与海岸边界、VP 收敛与迭代结果、EAP 结构张量及重启连续性、一维／二维 EVP 对照、长积分稳定性，以及 JAX 梯度。随机波浪路径和旧日志中的 `Tsfcn/apnd` 差异也尚未完成重新对照。

排查同时纠正了过时的“未迁移”注释：FSD 侧向增长／焊接／波浪破碎、风致积雪再分配、运行期初始状态边界恢复和 NetCDF dump 均已有实现，不再列为缺失物理。

## 融池诊断输出

融池诊断由 `setup_nml` 中的 `debug_model` 总开关控制，并遵循
`debug_model_step`（从该步开始输出）。JAX 增加以下子项，默认均关闭：

- `debug_model_ponds`：输出各检查阶段的融池状态。
- `debug_model_ponds_inputs`：输出垂直热力学中融池函数的输入和输出、各阶段融雪量；目前用于 `tr_pond_lvl`。当 `ktherm=2` 时还记录温度求解器出口的 `surface_*` 字段：表面净热通量及其各分量、顶部导热通量、温度、层厚和导热系数。`surface_flux_residual` 是未截断的净热通量减导热通量（W/m²），`surface_energy_residual` 是该差值乘时间步长（J/m²）；这些诊断不写入重启状态。
- `debug_model_ponds_i`、`debug_model_ponds_j`：成对填写全局网格坐标，从 1 开始，最多 16 个点；未用项为 `-1`。输出每个点的所有冰厚类别。

两个子开关可以独立启用；`debug_model=.false.` 或尚未到 `debug_model_step` 时，
不生成融池中间诊断量，也不输出融池诊断。输出由 `ice_diagnostics` 写入常规诊断流。
`cases/gx3_1step/run.py` 会将相关行另存为 `comparison_logs/pond_stages.时间戳.log`
和 `pond_inputs.时间戳.log`，无需额外命令行参数。

这些新增 namelist 项仅用于 JAX，不要复制到原版 Fortran 的 `ice_in`。

## 不支持的 Fortran 编译开关

本移植不支持 CICE 的预处理宏 `NO_I8` 和 `NO_R16`。

- `NO_I8`：Fortran 在编译器没有 8 字节整数时，把 `int8_kind` 退回 `selected_int_kind(6)`。JAX 和 NumPy 始终提供 `int64`，因此 `int8_kind` 固定为 `numpy.int64`。
- `NO_R16`：Fortran 在没有可靠的四倍精度实数时，把 `r16_kind` 退回双精度。JAX 没有 33 位有效数字的实数，这里也不做这条退路，因此不定义 `r16_kind`。

## 已知的 CICE BGC 初始化行为

在非 BGC 重启的初始化中，CICE 的 `cicecore/shared/ice_init_column.F90` 将全局 `trcrn` 的 BGC 部分复制到局部数组 `trcrn_bgc`，调用 `icepack_init_bgc` 修改该局部数组，然后直接释放它，没有把结果写回全局 `trcrn`。相关位置是 `ice_init_column.F90` 的 `init_bgc`（约第 878–919 行）和 `icepack/columnphysics/icepack_zbgc.F90` 的 `icepack_init_bgc`（约第 327–432 行）。BGC 重启路径另由 `read_restart_bgc` 直接读入全局状态，不属于这一情况。

CICE-JAX 目前在 `cicecore/shared/ice_init_column.py` 的 `_init_bgc_column` 中保留上述 Fortran 行为，以便先做逐变量对照。它意味着非重启路径计算出的冰内 BGC 初值不会进入全局冰状态；如要修正，应在确认基准结果后单独讨论并验证。关闭 BGC 的配置不触发这条路径。

## 波浪破碎的随机相位

`wave_spec_type=random` 时，原版 CICE 在波浪破碎计算中逐次抽取随机相位。CICE-JAX 将按用户选择使用**显式种子生成的 JAX PRNG key**，每次需要随机相位时拆分 key，并把更新后的 key 与冰状态一起传递。这样同一种子与同一模型配置可重现，也不会把随机数生成放在 NumPy 模块全局状态里。随机相位是外部随机输入；对初始冰状态或物理参数求梯度时，固定这组随机输入。

初始化状态交接接受 `wave_seed` 参数：仅当 `tr_fsd`、`wave_spec` 和 `wave_spec_type=random` 同时启用时，必须显式传入该种子；生成的 key 存入状态 pytree。每个波浪时间步拆出各格点的 key，并将下一步使用的 key 写回状态。逐格随机相位由 `wave_frac` 消耗。代码尚未运行验证。

JAX 与 Fortran 的随机数生成器不会自然产生相同的逐次相位，因此开启此分支后不能期待两版按同一种子逐变量完全一致；应另外提供相同的相位输入，才能做严格数值对照。当前 JAX 类别更新把自适应波浪子步上限设为 256，达到上限或原版的 100 步警告阈值时记录 `wave_failed`；这个上限也需要运行后核对。

## 不支持的 CMIP 历史输出组合

当 `update_ocn_f=true` 时，暂不支持启用 CMIP 历史字段 `siflsaltbot` 或 `siflfwbot`。原版 CICE 的 `ice_history.F90` 在这两个字段的计算中使用 `dfresh`，但该配置下没有给 `dfresh` 赋值，因此不存在可靠的 Fortran 数值可供忠实迁移。CICE-JAX 在初始化历史字段时对这个组合明确报错；不启用这两个字段时，`update_ocn_f=true` 仍可用于其他路径。`update_ocn_f=false` 时，这两个历史字段按原版的霰冰淡水修正计算。此限制由用户选择暂时保留。
