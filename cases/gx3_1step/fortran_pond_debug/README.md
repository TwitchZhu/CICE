# Fortran 融池定点诊断

## 当前轮次：multistep-pond-v1，GNU / Intel / JAX 各跑五步

本轮只准备诊断；未运行模型、编译、测试或比较程序。收齐三端本轮数据后再比较归因。
2026-10-31 按用户要求仅保留代码、配置和说明；本地旧输出、日志、快照、报告及归档已删除。
下文历史数值是此前已读结果的记录，相关原始文件现需重新下载或由用户生成。
第一步的近零水深 apnd 敏感性保留为已知问题，不用于解释第二步实际水量差异。
当前目标为第 2 步 `(68,2),cat2/3`、`(67,9),cat1`、`(52,8),cat1/2`；
三端均记录这三个格点的全部 5 个类别、全部 5 个时间步，坐标和类别均从 1 开始。

本地核对情况：原有七份上传源码与 `../CICE` 对应源码 SHA256 一致；随后只修改本目录
`CICE_RunMod.F90`、`ice_step_mod.F90` 的诊断，新增 `ice_diagnostics.F90` 上传副本。
`E:/Code/CICE` 原目录未写入；服务器需安装下面全部八份文件。未改原物理表达式或执行顺序。
JAX 已直接修改对应源码。三个 `DEBUG_REPLAY_ATMO_*` 开关继续为 False。
本地目录的源码一致不等于服务器实际编译源码一致，需回传构建证据。

已读取旧运行日志：GNU/JAX 为 5 步，Intel 为 1 步；三端记录的 `dt=3600`、`ndtd=1`、
`ndte=1`、`ktherm=2`、`advection=none`、`kridge=0`、`frzpnd=hlid` 一致。
旧 Intel 构建日志记录 `-O2 -fp-model precise -convert big_endian -assume byterecl`；
本地 GNU Macros 是非 debug `-O2`，不能据此证明旧二进制实际选项。不要在本轮调整浮点编译选项。

### 统一诊断位置与判读边界

- 初始化完成后的实际第 1 步入口、第 2 步入口：两端现有全字段无损快照扩展为连续两步，
  均位于 `ice_step` 开头、restoring 和诊断重置之前。第 1 步入口不是初始化过程内部的逐语句记录；
  若这里已经不同，要继续追溯初始化/步前 forcing，不能称作本步新产生。
- `(pond_stage)`：原有相同标签的 `debug_ice` 检查点，记录 `aicen/vicen/vsnon`、
  `alvl/apnd/hpnd/ipnd/Tsf`、`fswsfcn/fswintn`、完整 `qice1..7/sice1..7/qsno1`，
  以及派生 `pond_area=aicen*alvl*apnd` 和 `pond_volume=pond_area*hpnd`。
  重点顺序：`beginning time step` → `post prep_radiation` → `post step_therm1` →
  `post biogeochemistry` → `post step_therm2` → dynamics → radiation → coupling。
- `(atmo_fortran)/(atmo_jax)`：入口、每轮实际稳定度迭代和最终交换系数，沿用旧字段。
- `(picard_entry_*)`：`prep_picard` 前完整输入、后准备量；`(picard_*)` 为首/末轮诊断。
  仍保留最终采用的冷热分支求解，未记录所有中途尝试；不把缺失记录或占位零当作一致。
  没有调用 Picard 的类别不输出 Picard 行。
- `(surface_fortran)` 对应 JAX `(pond_therm1)` 中的 `surface_*` 字段：两阶段求解返回后。
- `(pond_fortran)` 对应 `(pond_therm1)` 的共同字段：`compute_ponds_lvl` 调用前/后。
  JAX 新补 `ipnd_before_ponds/vicen/vsnon/dhs/Tsf/fcondtopn/dt`；两端调用入口的残差命名为
  `pond_flux_residual/pond_energy_residual`，与较早的 `surface_*` 残差明确区分。
  JAX 额外 snow 字段尚无本轮 Fortran 对应记录，不当作三端证据。
- 空类别的未执行求解缓冲区在 Fortran 中为零、JAX 中可为 NaN，必须先看是否实际调用。
  本轮未增加融池函数内部每条分支的中间量；若三端调用输入相同而出口不同，下一轮再插入内部诊断。

源码导航：JAX `CICE_RunMod.py::ice_step` / `ice_diagnostics.py::debug_ice` /
`ice_step_mod.py::step_therm1` / `icepack_therm_vertical.py::icepack_step_therm1`；
Fortran 为相同模块的 `ice_step` / `debug_ice` / `step_therm1` / `icepack_step_therm1`。
后续结论必须注明本轮源码具体行号、初始化还是时间步、输入相同与否、最先不同的变量。
检查点之间仍有未采样区间，不能把“最早记录到”写成“已证实最早产生”。

### GNU 与 Intel：同一份源码包和 namelist，各自原环境运行

将本目录八份 `.F90` 和 `ice_in` 上传到 **两个 case 各自的** `fortran_pond_debug/`。
不上传本地旧日志/NetCDF。沿用各自 `cice.settings`、`env.*`、`Macros.*`、MPI 分块和编译器。
两者物理 namelist 都用本目录 `ice_in`：5 步，从相同 2005-01-01 00:00 初值重启全流程，
不是从第 1 步 restart 续跑。上传的输入路径仍为已用服务器路径；若服务器布局变化，只改输入路径。
不要用 JAX namelist 覆盖 Fortran（含 JAX 专用参数）。

以下在 Bash 中、分别进入 GNU `gx3_1step` 和 Intel `gx3_ifort` case 执行。
相对源码路径来自原 case 设置；若实际 `ICE_SANDBOX` 不同，先改 `pond_src` 指向真实源码树。
两个 case 若共享源码树，安装同一套诊断即可，但各自必须重新编译，不能混用 `.o/.mod` 或可执行文件。

```bash
pond_src=../../../CICE
pond_round=multistep-pond-v1-$(date +%Y%m%d-%H%M%S)
pond_evidence=fortran_pond_debug/$pond_round
mkdir -p "$pond_evidence/source_before"
cp -p ice_in cice.settings Macros.* env.* "$pond_evidence/"
for f in icepack_atmo icepack_orbital icepack_therm_mushy icepack_therm_vertical; do
    cp -p "$pond_src/icepack/columnphysics/$f.F90" "$pond_evidence/source_before/"
    cp "fortran_pond_debug/$f.F90" "$pond_src/icepack/columnphysics/"
done
cp -p "$pond_src/cicecore/cicedyn/general/ice_step_mod.F90" "$pond_evidence/source_before/"
cp -p "$pond_src/cicecore/cicedyn/analysis/ice_diagnostics.F90" "$pond_evidence/source_before/"
cp -p "$pond_src/cicecore/cicedyn/analysis/ice_step_snapshot.F90" "$pond_evidence/source_before/"
cp -p "$pond_src/cicecore/drivers/standalone/cice/CICE_RunMod.F90" "$pond_evidence/source_before/"
cp fortran_pond_debug/ice_step_mod.F90 "$pond_src/cicecore/cicedyn/general/"
cp fortran_pond_debug/ice_diagnostics.F90 fortran_pond_debug/ice_step_snapshot.F90 "$pond_src/cicecore/cicedyn/analysis/"
cp fortran_pond_debug/CICE_RunMod.F90 "$pond_src/cicecore/drivers/standalone/cice/"
cp fortran_pond_debug/ice_in ice_in
cp ice_in "$pond_evidence/ice_in.used"
(cd "$pond_src" && find cicecore icepack/columnphysics -type f \( -name '*.F90' -o -name '*.h' \) -print0 | sort -z | xargs -0 sha256sum) > "$pond_evidence/source.sha256"
(cd "$pond_src/input/CICE_data" && find ic/gx3 grid/gx3 forcing/gx3 -type f -print0 | sort -z | xargs -0 sha256sum) > "$pond_evidence/input.sha256"
```

输入目录哈希覆盖本 case 的初值、网格和大气/海洋 forcing；若配置引用目录外的有效输入，也须补其哈希。
记录实际路径与哈希，路径相同不足以证明内容相同。哈希不同先核对文件内容/解码值，不能直接归为模型错误。

用与 `cice.build` 相同的环境入口记录工具链；两种 wrapper 展开命令只需保留该 MPI 支持的一种：

```bash
csh -f <<'CSH' > "$pond_evidence/environment.txt" 2>&1
source ./cice.settings
source ./env.${ICE_MACHCOMP}
module list
which mpif90
mpif90 --version
mpif90 -show
mpif90 --showme
nf-config --all
nc-config --all
CSH
```

完整 `cice.bldlog.*` 为实际编译选项的主要证据。
确认每个 case `ICE_CLEANBUILD=true`（原 GNU 已是 true），保留原优化/FMA/浮点选项，然后分别：

```bash
pond_run=../../runs/gx3_1step  # Intel case 改为 ../../runs/gx3_ifort；与 ICE_RUNDIR 核对
mkdir -p "$pond_run/restart_multistep_diag" "$pond_run/history_multistep_diag"
csh ./cice.build && csh ./cice.submit
```

本轮 **需要重新编译**。运行上述命令前，若新输出目录已有本轮失败/旧输出，先归档再创建空目录；
同样归档此前 `step_entry.*`，避免混入旧 rank。GNU/Intel 不能共用运行目录。
编译完成后保存新二进制 SHA256 和 `ldd` 输出。提交后等待本次作业成功结束，再收集文件，
不能把“提交成功”当成“运行完成”。

### JAX：原 CUDA 环境、项目根目录

同步修改的 JAX 源码、`cases/gx3_1step/run.py` 和 `ice_in`。保留现有 JAX/XLA/CUDA 设置，
不启用旧回填、不修改数学函数。三端均为 `dt=3600,npt=5,ndtd=1,ndte=1,ktherm=2`，
`advection=none,ktransport=0,kridge=0,bfbflag=off`；每步双精度瞬时 history 和 restart。

```bash
pond_evidence=cases/gx3_1step/comparison_logs/multistep-pond-v1-$(date +%Y%m%d-%H%M%S)
mkdir -p "$pond_evidence"
cp cases/gx3_1step/ice_in "$pond_evidence/ice_in.used"
find cicecore icepack -type f -name '*.py' -print0 | sort -z | xargs -0 sha256sum > "$pond_evidence/source.sha256"
sha256sum cases/gx3_1step/run.py >> "$pond_evidence/source.sha256"
(cd ../CICE/input/CICE_data && find ic/gx3 grid/gx3 forcing/gx3 -type f -print0 | sort -z | xargs -0 sha256sum) > "$pond_evidence/input.sha256"
python -m pip freeze > "$pond_evidence/packages.txt"
nvidia-smi > "$pond_evidence/nvidia-smi.txt"
python cases/gx3_1step/run.py
```

`run.py` 自动创建新输出目录，并在 `cice.multistep_diag.runlog` 记录版本、设备和相关环境变量；
同时保存完整 `comparison_logs/run.<时间戳>.log`。程序不覆盖原 `cice.runlog`、`restart_5step/`、
`history_5step/` 路径；这些路径中的本地旧结果已按要求清理。若再次运行本轮，先区分两次输出，避免混合。
初始化前的 x64 配置记录不代表初始化后的状态；以入口快照浮点 dtype 和初始化配置共同核对。

### 回传清单与收齐后的比较

GNU、Intel、JAX 每端单独放一目录，建议本地 `cases/gx3_1step/multistep_diag/{gnu,intel,jax}/`：

- 本次完整运行日志，统一复制命名为 `run.log`；GNU/Intel 加完整构建日志、作业标准输出。
- 运行时 `ice_in`、源码/输入 SHA256、编译环境/版本/库信息和上述 evidence 目录。
- `restart_multistep_diag/` 的 5 个 restart、整个 `history_multistep_diag/`（含初始化 history）。
- Fortran 第 1、2 步 **所有 rank** 的 `step_entry.0000000[12].rank*.txt/.bin`，放 `step_entry/`。
- JAX 本轮第 1、2 步 `step_entry_jax.*.json/.npz` 配对文件，放 `step_entry/`，
  以及本次 `comparison_logs` 中的各诊断分日志。用完整 run.log 关联同一轮快照时间戳。

三端应有五个时刻：03600、07200、10800、14400、18000 秒；第 1、2 步入口快照都必须完整。
`(pond_stage)` 每个共同检查点应有 3×5=15 行，5 步都在；缺行/重复行先查诊断覆盖与 MPI 归属。
详细 solver 日志只在实际求解时存在。新增诊断可能影响编译优化，收到结果后也要核对本轮 GNU/JAX
与已归档正常五步结果是否变化，不能将诊断运行自动视作完全相同轨迹。

**仅在三端收齐且来源核对后**，可由用户执行以下两两对比；也可直接回传数据后再决定比较。
这里显式指定本轮文件，防止脚本默认读旧五步/Intel 单步。

```bash
pond_data=cases/gx3_1step/multistep_diag
for step in 1 2 3 4 5; do
    pond_file=$(printf 'iced.2005-01-01-%05d.nc' "$((step * 3600))")
    python cases/gx3_1step/compare_restart.py --step "$step" --all-pond-mismatches --reference "$pond_data/gnu/restart_multistep_diag/$pond_file" --result "$pond_data/jax/restart_multistep_diag/$pond_file" --reference-log "$pond_data/gnu/run.log" --result-log "$pond_data/jax/run.log"
    python cases/gx3_1step/compare_restart.py --ifort --step "$step" --all-pond-mismatches --reference "$pond_data/gnu/restart_multistep_diag/$pond_file" --result "$pond_data/intel/restart_multistep_diag/$pond_file" --reference-log "$pond_data/gnu/run.log" --result-log "$pond_data/intel/run.log"
    python cases/gx3_1step/compare_restart.py --intel-jax --step "$step" --all-pond-mismatches --reference "$pond_data/intel/restart_multistep_diag/$pond_file" --result "$pond_data/jax/restart_multistep_diag/$pond_file" --reference-log "$pond_data/intel/run.log" --result-log "$pond_data/jax/run.log"
done
```

差异会返回非零，不要启用遇非零即停止的 shell 选项；保留所有报告。容差仍为 `rtol=1e-6,atol=1e-10`，
PASS 不代表逐位一致。`compare_step_entry.py` 支持用 `--jax` 指定某一步的本轮 JSON、
`--fortran` 指定 GNU 或 Intel 的 `step_entry/`，逐步比较；不要让它自动挑“最新”文件。
其 `MISSING/UNAVAILABLE/UNSUPPORTED` 是覆盖缺口；现有脚本不直接做 GNU–Intel 入口二进制对比。
先比较三端共同字段和阶段轨迹，再追踪最早不一致输入的生成处；两端或两编译器接近都不单独证明正确。
## 历史文件清理

旧实验的源码和配置已保留，原始输出和清理归档已按用户要求删除。
包括此前的 GNU/JAX 正常五步、Intel 单步结果及 exp/atan 回填诊断日志。
本轮三端诊断仍使用上面的同一套准备方案，不重新开启旧回填实验。
