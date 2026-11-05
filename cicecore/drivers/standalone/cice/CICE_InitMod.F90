!=======================================================================
!
!  This module contains the CICE initialization routine that sets model
!  parameters and initializes the grid and CICE state variables.
!
!  authors Elizabeth C. Hunke, LANL
!          William H. Lipscomb, LANL
!          Philip W. Jones, LANL
!
! 2006: Converted to free form source (F90) by Elizabeth Hunke
! 2008: E. Hunke moved ESMF code to its own driver

      module CICE_InitMod

      use ice_kinds_mod
      use ice_exit, only: abort_ice
      use ice_fileunits, only: init_fileunits, nu_diag
      use ice_memusage, only: ice_memusage_init, ice_memusage_print
      use icepack_intfc, only: icepack_aggregate
      use icepack_intfc, only: icepack_init_itd, icepack_init_itd_hist
      use icepack_intfc, only: icepack_init_fsd_bounds, icepack_init_wave
      use icepack_intfc, only: icepack_init_snow, icepack_init_radiation
      use icepack_intfc, only: icepack_configure
      use icepack_intfc, only: icepack_warnings_flush, icepack_warnings_aborted
      use icepack_intfc, only: icepack_query_parameters, icepack_query_tracer_flags, &
          icepack_query_tracer_indices, icepack_query_tracer_sizes

      implicit none
      private
      public :: CICE_Initialize, cice_init

!=======================================================================

      contains

!=======================================================================

!  Initialize the basic state, grid and all necessary parameters for
!  running the CICE model.  Return the initial state in routine
!  export state.
!  Note: This initialization driver is designed for standalone and
!        CESM-coupled applications.  For other
!        applications (e.g., standalone CAM), this driver would be
!        replaced by a different driver that calls subroutine cice_init,
!        where most of the work is done.

      subroutine CICE_Initialize

      character(len=*), parameter :: subname='(CICE_Initialize)'
   !--------------------------------------------------------------------
   ! model initialization
   !--------------------------------------------------------------------

      call cice_init

      end subroutine CICE_Initialize

!=======================================================================
!
!  Initialize CICE model.

      subroutine cice_init

      use ice_arrays_column, only: hin_max, c_hi_range, alloc_arrays_column
      use ice_arrays_column, only: floe_rad_l, floe_rad_c, &
          floe_binwidth, c_fsd_range
      use ice_state, only: alloc_state
      use ice_flux_bgc, only: alloc_flux_bgc
      use ice_calendar, only: dt, write_ic, &
          init_calendar, advance_timestep, calc_timesteps
      use ice_communicate, only: init_communicate, my_task, master_task
      use ice_diagnostics, only: init_diags
      use ice_domain, only: init_domain_blocks
      use ice_domain_size, only: ncat, nfsd
      use ice_dyn_eap, only: init_eap
      use ice_dyn_evp, only: init_evp
      use ice_dyn_vp, only: init_vp
      use ice_dyn_shared, only: kdyn
      use ice_flux, only: init_coupler_flux, init_history_therm, &
          init_history_dyn, init_flux_atm, init_flux_ocn, alloc_flux
      use ice_forcing, only: init_forcing_ocn, init_forcing_atmo, &
          get_forcing_atmo, get_forcing_ocn, get_wave_spec, init_snowtable
      use ice_forcing_bgc, only: get_forcing_bgc, get_atm_bgc, &
          faero_default, alloc_forcing_bgc, fiso_default
      use ice_grid, only: init_grid1, init_grid2, alloc_grid, dealloc_grid
      use ice_history, only: init_hist, accum_hist
      use ice_history_write, only: ice_read_hist
      use ice_restart_shared, only: restart, runtype
      use ice_init, only: input_data, init_state
      use ice_init_column, only: init_thermo_vertical, init_shortwave, init_zbgc, input_zbgc, count_tracers
      use ice_kinds_mod
      use ice_restoring, only: ice_HaloRestore_init
      use ice_timers, only: timer_total, init_ice_timers, ice_timer_start
      use ice_transport_driver, only: init_transport

      logical(kind=log_kind) :: tr_aero, tr_zaero, skl_bgc, z_tracers, &
         tr_iso, tr_fsd, wave_spec, tr_snow
      character(len=char_len) :: snw_aging_table
      character(len=*), parameter :: subname = '(cice_init)'

      ! ================================通信、文件和 Icepack =================================
      call init_communicate     ! initial setup for message passing # 启动 MPI
      call init_fileunits       ! unit numbers 占用标准输入输出，再为网格、地形、强迫、重启、历史场和各类示踪物重启预留文件号。

      ! tcx debug, this will create a different logfile for each pe
      ! if (my_task /= master_task) nu_diag = 100+my_task

      call icepack_configure()  ! initialize icepack 关掉 Icepack 的“遇警告即中止”，并重算物理常数。柱物理包必须在读 namelist 之前可用，后面所有参数查询都走它。
      call icepack_warnings_flush(nu_diag)
      if (icepack_warnings_aborted()) call abort_ice(trim(subname), &
          file=__FILE__,line= __LINE__)

      ! ================================读配置，并数出示踪物 =================================
      call input_data           ! namelist variables 读 ice_in 里的 namelist，主进程读完后广播给所有进程，再写入 Icepack 并做一致性检查。
      call input_zbgc           ! vertical biogeochemistry namelist 读垂直生物地球化学namelist：盐度、卤水、营养盐、藻类、铁、气溶胶是否按层求解。
      call count_tracers        ! count tracers  按开关给每个示踪物分配下标，得到总个数 ntrcr。固定部分是表面温度、各冰层焓和盐度、
                                ! 各雪层焓；可选部分是冰龄、一年冰、平整冰面积/体积、融池、雪微物理、浮冰尺寸谱、同位素、气溶胶和 BGC。
                                ! 后面所有状态数组的第三、第四维都按这个数分配，所以它必须在 allocate 之前。

      ! Call this as early as possible, must be after memory_stats is read
      if (my_task == master_task) then
         call ice_memusage_init(nu_diag)
         call ice_memusage_print(nu_diag,subname//':start')
      endif

      ! ================================区域分解、分配内存、填网格 =================================
      call init_domain_blocks   ! set up block decomposition 读 domain_nml：全球格点数、块大小、进程拓扑、东西/南北边界（周期、开放或 tripole），以及是否丢掉纯陆块。
      call init_grid1           ! domain distribution 读全球纬度和海陆分布，用它们做块分配。Tripole 网格还会在这里核对边界类型是否匹配。
      call alloc_grid           ! allocate grid arrays 经纬度、格距、掩膜、角度
      call alloc_arrays_column  ! allocate column arrays 柱物理工作数组
      call alloc_state          ! allocate state arrays : aicen、vicen、vsnon、trcrn 和速度
      call alloc_flux_bgc       ! allocate flux_bgc arrays 海气、海冰–海洋通量
      call alloc_flux           ! allocate flux arrays  海气、海冰–海洋通量
      call init_ice_timers      ! initialize all timers  启动总计时器
      call ice_timer_start(timer_total)   ! start timing entire run
      call init_grid2           ! grid variables  把全局网格拆到各块上，算出 T/U（以及 C 网格的 N/E）点的经纬度、面积、格距、转向角和掩膜。
                                ! 矩形网格走 rectgrid；位移极点、tripole、区域网格按 grid_format 读 POP、MOM 或 GEOS 文件。
      ! ================================日历、输出和动力学 =================================
      call init_zbgc            ! vertical biogeochemistry initialization 按 BGC 开关设置垂直生物网格和示踪物初值结构。
      call init_calendar        ! initialize some calendar stuff  把模型日期设成 namelist 里的起始年月日和秒，算出动力学子步长 dt_dyn = dt/ndtd
                                ! 并选定历法：无闰年、360 天，或 365 天的 proleptic Gregorian。此时 istep = 0。
      call init_hist (dt)       ! initialize output history file  按 histfreq 登记历史场，包括热力、动力、融池、雪、拖曳、浮冰尺寸和 BGC。

      if (kdyn == 1) then       ! 动力学按 kdyn 三选一：
         call init_evp          ! EVP，分配应力、质量、海表倾斜等数组
      else if (kdyn == 2) then  ! EAP
         call init_eap          ! define eap dynamics parameters, variables
      else if (kdyn == 3) then  ! VP，并设置线性求解器
         call init_vp           ! define vp dynamics parameters, variables
      endif

      call init_coupler_flux    ! initialize fluxes exchanged with coupler 把和耦合器交换的风应力、长短波、海洋流速、海表温度盐度等
                                ! 先填成安全初值（例如大气参考高度 10 m）。独立运行时这些量随后会被数据强迫覆盖。

      ! ================================柱物理骨架和初始冰态 =================================
      call init_thermo_vertical ! initialize vertical thermodynamics 生成一条垂直盐度剖面，并换成融点 Tmltz。这条剖面主要给 BL99 热力方案用；
                                ! init_state 也用它给冰层赋初值。

      call icepack_init_itd(hin_max=hin_max)  ! ice thickness distribution 按 kcatbound 划出 ncat 个厚度档的上下界 hin_max。
                                              ! 常见三种：Lipscomb (2001) 的公式、便于取整的二次公式，以及 WMO 标准档（5/6/7 档时把最薄的几档合并）。
                                              ! 主进程再生成历史输出用的档位标签。
      if (my_task == master_task) then
         call icepack_init_itd_hist(hin_max=hin_max, c_hi_range=c_hi_range) ! output
      endif

      call icepack_query_tracer_flags(tr_fsd_out=tr_fsd)
      call icepack_warnings_flush(nu_diag)
      if (icepack_warnings_aborted()) call abort_ice(trim(subname), &
          file=__FILE__,line= __LINE__)


      if (tr_fsd) call icepack_init_fsd_bounds ( & ! 若打开浮冰尺寸示踪物 tr_fsd，icepack_init_fsd_bounds 划出各尺寸档的半径、中心和宽度。
         floe_rad_l_out = floe_rad_l,    &  ! fsd size lower bound in m (radius)
         floe_rad_c_out = floe_rad_c,    &  ! fsd size bin centre in m (radius)
         floe_binwidth_out = floe_binwidth, &  ! fsd size bin width in m (radius)
         c_fsd_range_out = c_fsd_range,   &  ! string for history output
         write_diags=(my_task == master_task))  ! write diag on master only
      call icepack_warnings_flush(nu_diag)
      if (icepack_warnings_aborted()) call abort_ice(error_message=subname, &
         file=__FILE__, line=__LINE__)

      call init_forcing_ocn(dt) ! initialize sss and sst from data
                                ! init_forcing_ocn 必须在 init_state 之前。它读入或设好海表盐度、海表温度和冰点。
                                ! set_state_var 要用这些量决定哪里有冰、冰有多厚。
      call init_state           ! initialize the ice state
                                ! 1. 给每个示踪物标明它挂在什么上：0 是面积，1 是冰体积，2 是雪体积。融池深度还挂在融池面积（以及平整冰面积）上，传输时要按这个依赖关系重映射。
                                ! 2. set_state_var 按 ice_ic 填分类冰态。internal 用 namelist 里的浓度和分布（均匀、抛物线、随纬度变化，或 box 试验）；
                                ! none 是开阔水；否则把 ice_ic 当成重启文件名，真正读文件留到后面的 init_restart。速度先置零。
                                ! 3. 做 halo 更新。C 网格还要把速度平均到北、东侧。然后 icepack_aggregate 把各厚度档合成网格平均值
                                ! aice、vice、vsno、trcr，开阔水是 aice0 = 1 - aice。陆地格点不参与聚合。
      call init_transport       ! initialize horizontal transport 按上面的依赖关系，告诉平流/重映射模块：冰厚、雪厚以及每个示踪物依赖谁。
                                ! 依赖顺序不对会直接中止。
      call ice_HaloRestore_init ! restored boundary conditions 只在 restore_ice 打开时工作，给开边界准备恢复场。
                                ! 开边界还要求 restart_ext 为真。

      call icepack_query_parameters(skl_bgc_out=skl_bgc, z_tracers_out=z_tracers, &
          wave_spec_out=wave_spec, snw_aging_table_out=snw_aging_table)
      call icepack_warnings_flush(nu_diag)
      if (icepack_warnings_aborted()) call abort_ice(trim(subname), &
          file=__FILE__,line= __LINE__)

      if (skl_bgc .or. z_tracers) call alloc_forcing_bgc ! allocate biogeochemistry arrays

      ! ================================重启和示踪物 =================================
      call init_restart         ! initialize restart variables 决定核心冰态从哪来：
                                ! runtype = 'continue'：按指针文件读核心重启，并用文件里的时间覆盖日历；EAP 再读自己的重启。
                                ! restart 为真（ice_ic 是文件名）：把该文件当初始场，时间是否采用由 use_restart_time 决定。
                                ! 否则保持 init_state 刚生成的内部初值。
                                ! 然后按示踪物逐个处理。continue 时默认读对应重启；否则看 restart_age、restart_FY 等开关。
                                ! 没重启就用解析初值，例如冰龄、一年冰、平整冰、三类融池、雪层质量/密度/粒径、浮冰尺寸、同位素、气溶胶。
                                ! 卤水和 BGC 走 init_hbrine、init_bgc。浮冰尺寸和 BGC 不能同时用，代码会直接报错退出。
                                ! 最后再聚合一次。陆地格点上的 trcrn 被清零。这一步会覆盖 init_state 里的临时聚合结果，因为示踪物可能
                                ! 刚从重启或解析初值里补齐。
      ! ================================短波、时钟，以及第一步强迫 =================================
      call init_diags           ! initialize diagnostic output points 按经纬度找到诊断点所在的块和格点。
      call init_history_therm   ! initialize thermo history variables 把热力历史累加器置零。
      call init_history_dyn     ! initialize dynamic history variables 把动力历史累加器置零。
      call calc_timesteps       ! update timestep counter if not using npt_unit="1" 把 npt 从年、月、日、时、秒统一换算成时间步数，并检查总时长能否被 dt 整除。
      call icepack_init_radiation ! initialize icepack shortwave tables 装入 delta-Eddington 或 SNICAR 的短波查算表。
                                ! 短波场本身分两种情况初始化：
                                ! 1. continue 或从重启起步：立刻调用 init_shortwave。它用上一步保存的向下短波，真正积分前会再按当前强迫缩放。
                                ! 2. 冷启动：这时还没有当前短波，所以先跳过。

      call icepack_query_tracer_flags(tr_aero_out=tr_aero, tr_zaero_out=tr_zaero)
      call icepack_query_tracer_flags(tr_iso_out=tr_iso, tr_snow_out=tr_snow)
      call icepack_warnings_flush(nu_diag)
      if (icepack_warnings_aborted()) call abort_ice(trim(subname), &
          file=__FILE__,line= __LINE__)

      ! Initialize shortwave components using swdn from previous timestep
      ! if restarting. These components will be scaled to current forcing
      ! in prep_radiation.
      if (trim(runtype) == 'continue' .or. restart) &
         call init_shortwave    ! initialize radiative transfer

      if (write_ic) call accum_hist(dt) ! write initial conditions 若 write_ic 为真，accum_hist 把当前冰态记成初始条件。
      call ice_read_hist  ! read history restarts 读历史累加器的重启，这样平均值不会从零重新累。

! tcraig, use advance_timestep here
!      istep  = istep  + 1    ! update time step counters
!      istep1 = istep1 + 1
!      time = time + dt       ! determine the time and date
!      call calendar(time)    ! at the end of the first timestep
      call advance_timestep()   ! advance_timestep 把时钟向前拨一个 dt：istep 变成 1，日期变成第一个时间步的结束时刻。
                                ! CICE 的约定是，积分过程中的模型时间表示该步结束时的时间。CICE_Run 里每个 ice_step 之后还会再拨一次；
                                ! 初始化先拨这一次，是为了让第一步物理和第一步强迫使用同一个结束时刻。

   !--------------------------------------------------------------------
   ! coupler communication or forcing data initialization
   !--------------------------------------------------------------------
   ! 拨钟之后读第一步强迫
      call init_forcing_atmo    ! initialize atmospheric forcing (standalone) 按 atm_data_type 定数据年份和文件名（NCAR、JRA55、HadGEM、月平均、一维、box 试验或均匀风）

      if (tr_fsd .and. wave_spec) call get_wave_spec ! wave spectrum in ice 需要波谱时读 get_wave_spec
      call get_forcing_atmo     ! atmospheric forcing from data 读入风、温、湿、降水、长短波、海温和海流
      call get_forcing_ocn(dt)  ! ocean forcing from data 读入风、温、湿、降水、长短波、海温和海流

      ! snow aging lookup table initialization 高级雪物理则 icepack_init_snow，并在老化表不是 test 时读 init_snowtable
      if (tr_snow) then         ! advanced snow physics
         call icepack_init_snow()  ! 高级雪物理
         call icepack_warnings_flush(nu_diag)
         if (icepack_warnings_aborted()) call abort_ice(error_message=subname, &
            file=__FILE__, line=__LINE__)
         if (snw_aging_table(1:4) /= 'test') then
            call init_snowtable() ! 老化表不是 test 时读 init_snowtable
         endif
      endif

      ! isotopes 同位素、气溶胶、BGC 填默认值或数据
      if (tr_iso)     call fiso_default                 ! default values

      ! aerosols
      ! if (tr_aero)  call faero_data                   ! data file
      ! if (tr_zaero) call fzaero_data                  ! data file (gx1)
      if (tr_aero .or. tr_zaero)  call faero_default    ! default values 同位素、气溶胶、BGC 填默认值或数据
      if (skl_bgc .or. z_tracers) call get_forcing_bgc  ! biogeochemistry 同位素、气溶胶、BGC 填默认值或数据
      if (z_tracers) call get_atm_bgc                   ! biogeochemistry 同位素、气溶胶、BGC 填默认值或数据

      if (runtype == 'initial' .and. .not. restart) &   ! 冷启动到这里才调用 init_shortwave，因为当前向下短波已经在手。
         call init_shortwave    ! initialize radiative transfer using current swdn

      call init_flux_atm        ! initialize atmosphere fluxes sent to coupler 把交给大气的应力、感热、潜热、反照率相关通量清零。
      call init_flux_ocn        ! initialize ocean fluxes sent to coupler 把交给海洋的淡水、盐、热和透射短波清零。
                                ! 这些量要等第一步热力、动力算完才有意义；时间循环里每步结束都会再清一次。

      call dealloc_grid         ! deallocate temporary grid arrays 释放建网格时用过的全局临时数组。

      if (my_task == master_task) then
         call ice_memusage_print(nu_diag,subname//':end')  ! 主进程打印结束时的内存占用。
      endif

      end subroutine cice_init

!=======================================================================

      subroutine init_restart

      use ice_arrays_column, only: dhsn
      use ice_blocks, only: nx_block, ny_block
      use ice_calendar, only: calendar
      use ice_constants, only: c0
      use ice_domain, only: nblocks
      use ice_domain_size, only: ncat, n_iso, n_aero, nfsd, nslyr
      use ice_dyn_eap, only: read_restart_eap
      use ice_dyn_shared, only: kdyn
      use ice_grid, only: tmask
      use ice_init, only: ice_ic
      use ice_init_column, only: init_age, init_FY, init_lvl, init_snowtracers, &
          init_meltponds_lvl, init_meltponds_sealvl, init_meltponds_topo, &
          init_isotope, init_aerosol, init_hbrine, init_bgc, init_fsd
      use ice_restart_column, only: restart_age, read_restart_age, &
          restart_FY, read_restart_FY, restart_lvl, read_restart_lvl, &
          restart_pond_lvl, read_restart_pond_lvl, &
          restart_pond_sealvl, read_restart_pond_sealvl, &
          restart_pond_topo, read_restart_pond_topo, &
          restart_snow, read_restart_snow, &
          restart_fsd, read_restart_fsd, &
          restart_iso, read_restart_iso, &
          restart_aero, read_restart_aero, &
          restart_hbrine, read_restart_hbrine, &
          restart_bgc
      use ice_flux, only: Tf
      use ice_restart_driver, only: restartfile
      use ice_restart_shared, only: runtype, restart
      use ice_state ! almost everything

      integer(kind=int_kind) :: &
         i, j        , & ! horizontal indices
         iblk            ! block index
      logical(kind=log_kind) :: &
          tr_iage, tr_FY, tr_lvl, tr_pond_lvl, tr_pond_sealvl, &
          tr_pond_topo, tr_snow, tr_fsd, tr_iso, tr_aero, tr_brine, &
          skl_bgc, z_tracers
      integer(kind=int_kind) :: &
          ntrcr
      integer(kind=int_kind) :: &
          nt_alvl, nt_vlvl, nt_apnd, nt_hpnd, nt_ipnd, &
          nt_smice, nt_smliq, nt_rhos, nt_rsnw, &
          nt_iage, nt_FY, nt_aero, nt_fsd, nt_isosno, nt_isoice

      character(len=*), parameter :: subname = '(init_restart)'

      call icepack_query_tracer_sizes(ntrcr_out=ntrcr)
      call icepack_warnings_flush(nu_diag)
      if (icepack_warnings_aborted()) call abort_ice(error_message=subname, &
          file=__FILE__, line=__LINE__)

      call icepack_query_parameters(skl_bgc_out=skl_bgc, &
           z_tracers_out=z_tracers)
      call icepack_query_tracer_flags(tr_iage_out=tr_iage, tr_FY_out=tr_FY, &
           tr_lvl_out=tr_lvl, tr_pond_lvl_out=tr_pond_lvl, &
           tr_pond_sealvl_out = tr_pond_sealvl, &
           tr_pond_topo_out=tr_pond_topo, tr_aero_out=tr_aero, tr_brine_out=tr_brine, &
           tr_snow_out=tr_snow, tr_fsd_out=tr_fsd, tr_iso_out=tr_iso)
      call icepack_query_tracer_indices(nt_alvl_out=nt_alvl, nt_vlvl_out=nt_vlvl, &
           nt_apnd_out=nt_apnd, nt_hpnd_out=nt_hpnd, nt_ipnd_out=nt_ipnd, &
           nt_iage_out=nt_iage, nt_FY_out=nt_FY, nt_aero_out=nt_aero, nt_fsd_out=nt_fsd, &
           nt_smice_out=nt_smice, nt_smliq_out=nt_smliq, &
           nt_rhos_out=nt_rhos, nt_rsnw_out=nt_rsnw, &
           nt_isosno_out=nt_isosno, nt_isoice_out=nt_isoice)
      call icepack_warnings_flush(nu_diag)
      if (icepack_warnings_aborted()) call abort_ice(error_message=subname, &
         file=__FILE__, line=__LINE__)

      if (trim(runtype) == 'continue') then
         ! start from core restart file
         call restartfile()           ! given by pointer in ice_in
         call calendar()              ! update time parameters
         if (kdyn == 2) call read_restart_eap ! EAP
      else if (restart) then          ! ice_ic = core restart file
         call restartfile (ice_ic)    !  or 'default' or 'none'
         !!! uncomment to create netcdf
         ! call restartfile_v4 (ice_ic)  ! CICE v4.1 binary restart file
         !!! uncomment if EAP restart data exists
         ! if (kdyn == 2) call read_restart_eap
      endif

      ! tracers
      ! ice age tracer
      if (tr_iage) then
         if (trim(runtype) == 'continue') restart_age = .true.
         if (restart_age) then
            call read_restart_age
         else
            do iblk = 1, nblocks
               call init_age(trcrn(:,:,nt_iage,:,iblk))
            enddo ! iblk
         endif
      endif
      ! first-year area tracer
      if (tr_FY) then
         if (trim(runtype) == 'continue') restart_FY = .true.
         if (restart_FY) then
            call read_restart_FY
         else
            do iblk = 1, nblocks
               call init_FY(trcrn(:,:,nt_FY,:,iblk))
            enddo ! iblk
         endif
      endif
      ! level ice tracer
      if (tr_lvl) then
         if (trim(runtype) == 'continue') restart_lvl = .true.
         if (restart_lvl) then
            call read_restart_lvl
         else
            do iblk = 1, nblocks
               call init_lvl(iblk,trcrn(:,:,nt_alvl,:,iblk), &
                             trcrn(:,:,nt_vlvl,:,iblk))
            enddo ! iblk
         endif
      endif
      ! level-ice melt ponds
      if (tr_pond_lvl) then
         if (trim(runtype) == 'continue') restart_pond_lvl = .true.
         if (restart_pond_lvl) then
            call read_restart_pond_lvl
         else
            do iblk = 1, nblocks
               call init_meltponds_lvl(trcrn(:,:,nt_apnd,:,iblk), &
                                       trcrn(:,:,nt_hpnd,:,iblk), &
                                       trcrn(:,:,nt_ipnd,:,iblk), &
                                       dhsn(:,:,:,iblk))
            enddo ! iblk
         endif
      endif
      ! sealvl melt ponds
      if (tr_pond_sealvl) then
         if (trim(runtype) == 'continue') restart_pond_sealvl = .true.
         if (restart_pond_sealvl) then
            call read_restart_pond_sealvl
         else
            do iblk = 1, nblocks
               call init_meltponds_sealvl(trcrn(:,:,nt_apnd,:,iblk), &
                                          trcrn(:,:,nt_hpnd,:,iblk), &
                                          trcrn(:,:,nt_ipnd,:,iblk), &
                                          dhsn(:,:,:,iblk))
            enddo ! iblk
         endif
      endif
      ! topographic melt ponds
      if (tr_pond_topo) then
         if (trim(runtype) == 'continue') restart_pond_topo = .true.
         if (restart_pond_topo) then
            call read_restart_pond_topo
         else
            do iblk = 1, nblocks
               call init_meltponds_topo(trcrn(:,:,nt_apnd,:,iblk), &
                                        trcrn(:,:,nt_hpnd,:,iblk), &
                                        trcrn(:,:,nt_ipnd,:,iblk))
            enddo ! iblk
         endif ! .not. restart_pond
      endif

      ! snow redistribution/metamorphism
      if (tr_snow) then
         if (trim(runtype) == 'continue') restart_snow = .true.
         if (restart_snow) then
            call read_restart_snow
         else
            do iblk = 1, nblocks
               call init_snowtracers(trcrn(:,:,nt_smice:nt_smice+nslyr-1,:,iblk), &
                                     trcrn(:,:,nt_smliq:nt_smliq+nslyr-1,:,iblk), &
                                     trcrn(:,:,nt_rhos :nt_rhos +nslyr-1,:,iblk), &
                                     trcrn(:,:,nt_rsnw :nt_rsnw +nslyr-1,:,iblk))
            enddo ! iblk
         endif
      endif

      ! floe size distribution
      if (tr_fsd) then
         if (trim(runtype) == 'continue') restart_fsd = .true.
         if (restart_fsd) then
            call read_restart_fsd
         else
            call init_fsd(trcrn(:,:,nt_fsd:nt_fsd+nfsd-1,:,:))
         endif
      endif

      ! isotopes
      if (tr_iso) then
         if (trim(runtype) == 'continue') restart_iso = .true.
         if (restart_iso) then
            call read_restart_iso
         else
            do iblk = 1, nblocks
               call init_isotope(trcrn(:,:,nt_isosno:nt_isosno+n_iso-1,:,iblk), &
                                 trcrn(:,:,nt_isoice:nt_isoice+n_iso-1,:,iblk))
            enddo ! iblk
         endif
      endif

      if (tr_aero) then ! ice aerosol
         if (trim(runtype) == 'continue') restart_aero = .true.
         if (restart_aero) then
            call read_restart_aero
         else
            do iblk = 1, nblocks
               call init_aerosol(trcrn(:,:,nt_aero:nt_aero+4*n_aero-1,:,iblk))
            enddo ! iblk
         endif ! .not. restart_aero
      endif

      if (trim(runtype) == 'continue') then
         if (tr_brine) restart_hbrine = .true.
         if (skl_bgc .or. z_tracers) restart_bgc = .true.
      endif

      if (tr_brine .or. skl_bgc) then ! brine height tracer
         call init_hbrine
         if (tr_brine .and. restart_hbrine) call read_restart_hbrine
      endif

      if (skl_bgc .or. z_tracers) then ! biogeochemistry
         if (tr_fsd) then
            write (nu_diag,*) 'FSD implementation incomplete for use with BGC'
            call icepack_warnings_flush(nu_diag)
            if (icepack_warnings_aborted()) call abort_ice(error_message=subname, &
               file=__FILE__, line=__LINE__)
         endif
         call init_bgc
      endif

      !-----------------------------------------------------------------
      ! aggregate tracers
      !-----------------------------------------------------------------

      !$OMP PARALLEL DO PRIVATE(iblk)
      do iblk = 1, nblocks
      do j = 1, ny_block
      do i = 1, nx_block
         if (tmask(i,j,iblk)) then
            call icepack_aggregate(aicen = aicen(i,j,:,iblk),     &
                                   trcrn = trcrn(i,j,:,:,iblk),   &
                                   vicen = vicen(i,j,:,iblk),     &
                                   vsnon = vsnon(i,j,:,iblk),     &
                                   aice  = aice (i,j,  iblk),     &
                                   trcr  = trcr (i,j,:,iblk),     &
                                   vice  = vice (i,j,  iblk),     &
                                   vsno  = vsno (i,j,  iblk),     &
                                   aice0 = aice0(i,j,  iblk),     &
                                   trcr_depend   = trcr_depend,   &
                                   trcr_base     = trcr_base,     &
                                   n_trcr_strata = n_trcr_strata, &
                                   nt_strata     = nt_strata,     &
                                   Tf            = Tf(i,j,iblk))
         else
            ! tcraig, reset all tracer values on land to zero
            trcrn(i,j,:,:,iblk) = c0
         endif
      enddo
      enddo
      enddo
      !$OMP END PARALLEL DO

      call icepack_warnings_flush(nu_diag)
      if (icepack_warnings_aborted()) call abort_ice(error_message=subname, &
         file=__FILE__, line=__LINE__)

      end subroutine init_restart

!=======================================================================

      end module CICE_InitMod

!=======================================================================
