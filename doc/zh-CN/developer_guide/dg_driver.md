# 驱动程序与耦合

驱动程序与耦合层位于 `cicecore/drivers/`。独立运行驱动程序位于 `cicecore/drivers/standalone/cice/`，其他高层耦合层位于其他目录。根据模式的运行和耦合方式，一次构建只使用其中一个驱动程序。独立运行目录中包含：

- `CICE.F90`：顶层主程序，调用 `CICE_Initialize`、`CICE_Run` 和 `CICE_Finalize`。
- `CICE_InitMod.F90`：包含 `CICE_Initialize` 及下一层源代码。
- `CICE_RunMod.F90`：包含 `CICE_Run` 及下一层源代码。
- `CICE_FinalMod.F90`：包含 `CICE_Finalize` 及下一层源代码。

这些文件确定了独立运行 CICE 模式的顶层调用顺序。

## 添加新的驱动程序

`drivers` 目录有两层子目录。第一层表示耦合基础设施或策略；第二层表示驱动程序针对的应用或耦合器。目前的结构包括：

```text
drivers/direct/hadgem3
drivers/mct/cesm1
drivers/nuopc/cmeps
drivers/standalone/cice
```

使用 CICE 脚本独立运行时，采用 `drivers/standalone/cice`。如果需要与新的基础设施或应用耦合，可添加新驱动程序。项目鼓励社区将驱动程序放在 `drivers` 目录中以便复用；驱动程序代码也可以放在应用内。应尽量遵循现有命名策略，将驱动程序加入能表示耦合基础设施的相应子目录。以后也可以按需新增 `oasis` 或 `esmf` 等子目录。

社区需要共同决定何时在不同应用之间共享驱动程序、何时更新驱动程序、何时创建新驱动程序。相关权衡包括与早期应用版本的向后兼容性、代码复用和独立性。一般不应删除驱动程序目录，也不应重复使用旧目录名，以免与本质不同的早期版本混淆。随着基础设施和应用增多、版本演进，驱动程序数量可能继续增加。

当前的第一层子目录为 `mct`、`nuopc`、`standalone` 和 `direct`。`standalone` 包含作为独立程序运行模式的驱动程序；`direct` 包含让其他模式以子程序方式直接调用海冰模式目录的耦合接口；`mct` 和 `nuopc` 分别包含通过相应接口耦合的应用／耦合器子目录。

`cicecore/drivers/` 下的各驱动程序通常以类似独立运行驱动程序的方式实现，包含各自版本的 `CICE_InitMod.F90`、`CICE_RunMod.F90`、`CICE_FinalMod.F90`，以及与耦合层相适应的文件。以后若新增 CICE 功能需要修改调用顺序，可能所有驱动程序都须更新。这类变更影响较大，需要社区共同维护。

## 调用顺序

初始化调用顺序大致如下。代码中的英文注释已译为中文，实际顺序应以最新的 `CICE_InitMod.F90` 为准。

```fortran
call init_communicate     ! 消息传递的初始设置
call init_fileunits       ! 文件单元编号
call icepack_configure()  ! 初始化 Icepack
call input_data           ! Namelist 变量
call init_zbgc            ! 垂直生物地球化学 namelist
call count_tracers        ! 统计示踪物数量
call init_domain_blocks   ! 设置块分解
call init_grid1           ! 区域分配
call alloc_*              ! 分配数组
call init_ice_timers      ! 初始化所有计时器
call init_grid2           ! 网格变量
call init_zbgc            ! 初始化垂直生物地球化学
call init_calendar        ! 初始化部分日历设置
call init_hist (dt)       ! 初始化历史输出文件
call init_dyn (dt_dyn)    ! 定义动力学参数和变量
if (kdyn == 2) then
   call init_eap          ! 定义 EAP 动力学参数和变量
else if (kdyn == 3) then
   call init_vp           ! 定义 VP 动力学参数和变量
endif
call init_coupler_flux    ! 初始化与耦合器交换的通量
call init_thermo_vertical ! 初始化垂直热力学
call icepack_init_itd(ncat, hin_max)  ! 冰厚分布
if (tr_fsd) call icepack_init_fsd_bounds  ! 冰块尺寸分布
call init_forcing_ocn(dt) ! 根据数据初始化海表盐度和温度
call init_state           ! 初始化海冰状态
call init_transport       ! 初始化水平输运
call ice_HaloRestore_init ! 恢复式边界条件
call init_restart         ! 初始化重启变量
call init_diags           ! 初始化诊断输出点
call init_history_therm   ! 初始化热力学历史变量
call init_history_dyn     ! 初始化动力学历史变量
call calc_timesteps       ! 非 npt_unit="1" 时更新步数计数器
call init_shortwave       ! 初始化辐射传输
call advance_timestep     ! 推进时间步
call init_forcing_atmo    ! 初始化大气强迫（独立运行）
if (tr_fsd .and. wave_spec) call get_wave_spec ! 海冰中的波浪谱
call get_forcing*         ! 读取强迫数据（独立运行）
if (tr_snow) call icepack_init_snow ! 高级积雪物理
```

时间循环中的运行顺序大致如下。实际顺序应以最新的 `CICE_RunMod.F90` 为准。

```fortran
call init_mass_diags   ! 每个时间步的诊断
call init_history_therm
call init_history_bgc

do iblk = 1, nblocks
   if (calc_Tsfc) call prep_radiation (dt, iblk)
   call step_therm1     (dt, iblk) ! 垂直热力学
   call biogeochemistry (dt, iblk) ! 生物地球化学
   call step_therm2     (dt, iblk) ! 冰厚分布热力学
enddo ! iblk

call update_state (dt, daidtt, dvidtt, dagedtt, offset)

if (tr_fsd .and. wave_spec) call step_dyn_wave(dt)
do k = 1, ndtd
   call step_dyn_horiz (dt_dyn)
   do iblk = 1, nblocks
      call step_dyn_ridge (dt_dyn, ndtd, iblk)
   enddo
   call update_state (dt_dyn, daidtd, dvidtd, dagedtd, offset)
enddo

if (tr_snow) then         ! 高级积雪物理
   do iblk = 1, nblocks
      call step_snow (dt, iblk)
   enddo
   call update_state (dt) ! 整理状态
endif

do iblk = 1, nblocks
   call step_radiation (dt, iblk)
   call coupling_prep (iblk)
enddo ! iblk

! 写出数据
! 更新强迫数据
```

原文：[dg_driver.rst](../../source/developer_guide/dg_driver.rst)
