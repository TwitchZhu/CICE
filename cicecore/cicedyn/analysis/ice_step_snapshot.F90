! Diagnostic snapshot only: no model state is assigned here.
! Public-field inventory: cases/gx3_1step/step_entry_manifest.json.
module ice_step_snapshot
  use iso_fortran_env, only: int64, real64
  use ice_blocks, only: block, get_block, nx_block, ny_block
  use ice_domain, only: nblocks, blocks_ice
  use ice_domain_size, only: max_blocks
  use ice_communicate, only: my_task, master_task, get_num_procs
  use ice_broadcast, only: broadcast_scalar
  use ice_fileunits, only: nu_diag
  implicit none
  private
  public :: write_step_entry
  integer :: meta_unit, data_unit
  integer(int64) :: byte_offset
  interface entry_real
    module procedure entry_real_0
    module procedure entry_real_1
    module procedure entry_real_2
    module procedure entry_real_3
    module procedure entry_real_4
    module procedure entry_real_5
  end interface
  interface entry_int
    module procedure entry_int_0
    module procedure entry_int_1
    module procedure entry_int_2
    module procedure entry_int_4
  end interface
  interface entry_logical
    module procedure entry_logical_0
    module procedure entry_logical_1
    module procedure entry_logical_3
    module procedure entry_logical_4
  end interface
  interface entry_char
    module procedure entry_char_0
    module procedure entry_char_1
  end interface
contains
  subroutine write_step_entry(step)
    use ice_state, only: e0001 => aice
    use ice_state, only: e0002 => aiU
    use ice_state, only: e0003 => vice
    use ice_state, only: e0004 => vsno
    use ice_state, only: e0005 => trcr
    use ice_state, only: e0006 => aice0
    use ice_state, only: e0007 => aicen
    use ice_state, only: e0008 => vicen
    use ice_state, only: e0009 => vsnon
    use ice_state, only: e0010 => trcrn
    use ice_state, only: e0011 => trcr_depend
    use ice_state, only: e0012 => n_trcr_strata
    use ice_state, only: e0013 => nt_strata
    use ice_state, only: e0014 => trcr_base
    use ice_state, only: e0015 => uvel
    use ice_state, only: e0016 => vvel
    use ice_state, only: e0017 => uvelE
    use ice_state, only: e0018 => vvelE
    use ice_state, only: e0019 => uvelN
    use ice_state, only: e0020 => vvelN
    use ice_state, only: e0021 => divu
    use ice_state, only: e0022 => shear
    use ice_state, only: e0023 => vort
    use ice_state, only: e0024 => strength
    use ice_state, only: e0025 => aice_init
    use ice_state, only: e0026 => aicen_init
    use ice_state, only: e0027 => vicen_init
    use ice_state, only: e0028 => vsnon_init
    use ice_state, only: e0029 => Tsfcn_init
    use ice_flux, only: e0030 => default_season
    use ice_flux, only: e0031 => strax
    use ice_flux, only: e0032 => stray
    use ice_flux, only: e0033 => uocn
    use ice_flux, only: e0034 => vocn
    use ice_flux, only: e0035 => ss_tltx
    use ice_flux, only: e0036 => ss_tlty
    use ice_flux, only: e0037 => hwater
    use ice_flux, only: e0038 => strairxT
    use ice_flux, only: e0039 => strairyT
    use ice_flux, only: e0040 => strocnxT_iavg
    use ice_flux, only: e0041 => strocnyT_iavg
    use ice_flux, only: e0042 => sig1
    use ice_flux, only: e0043 => sig2
    use ice_flux, only: e0044 => sigP
    use ice_flux, only: e0045 => taubxU
    use ice_flux, only: e0046 => taubyU
    use ice_flux, only: e0047 => strairxU
    use ice_flux, only: e0048 => strairyU
    use ice_flux, only: e0049 => strocnxU
    use ice_flux, only: e0050 => strocnyU
    use ice_flux, only: e0051 => strtltxU
    use ice_flux, only: e0052 => strtltyU
    use ice_flux, only: e0053 => strintxU
    use ice_flux, only: e0054 => strintyU
    use ice_flux, only: e0055 => taubxN
    use ice_flux, only: e0056 => taubyN
    use ice_flux, only: e0057 => strairxN
    use ice_flux, only: e0058 => strairyN
    use ice_flux, only: e0059 => strocnxN
    use ice_flux, only: e0060 => strocnyN
    use ice_flux, only: e0061 => strtltxN
    use ice_flux, only: e0062 => strtltyN
    use ice_flux, only: e0063 => strintxN
    use ice_flux, only: e0064 => strintyN
    use ice_flux, only: e0065 => taubxE
    use ice_flux, only: e0066 => taubyE
    use ice_flux, only: e0067 => strairxE
    use ice_flux, only: e0068 => strairyE
    use ice_flux, only: e0069 => strocnxE
    use ice_flux, only: e0070 => strocnyE
    use ice_flux, only: e0071 => strtltxE
    use ice_flux, only: e0072 => strtltyE
    use ice_flux, only: e0073 => strintxE
    use ice_flux, only: e0074 => strintyE
    use ice_flux, only: e0075 => daidtd
    use ice_flux, only: e0076 => dvidtd
    use ice_flux, only: e0077 => dvsdtd
    use ice_flux, only: e0078 => dagedtd
    use ice_flux, only: e0079 => dardg1dt
    use ice_flux, only: e0080 => dardg2dt
    use ice_flux, only: e0081 => dvirdgdt
    use ice_flux, only: e0082 => opening
    use ice_flux, only: e0083 => dardg1ndt
    use ice_flux, only: e0084 => dardg2ndt
    use ice_flux, only: e0085 => dvirdgndt
    use ice_flux, only: e0086 => aparticn
    use ice_flux, only: e0087 => krdgn
    use ice_flux, only: e0088 => ardgn
    use ice_flux, only: e0089 => vrdgn
    use ice_flux, only: e0090 => araftn
    use ice_flux, only: e0091 => vraftn
    use ice_flux, only: e0092 => aredistn
    use ice_flux, only: e0093 => vredistn
    use ice_flux, only: e0094 => stressp_1
    use ice_flux, only: e0095 => stressp_2
    use ice_flux, only: e0096 => stressp_3
    use ice_flux, only: e0097 => stressp_4
    use ice_flux, only: e0098 => stressm_1
    use ice_flux, only: e0099 => stressm_2
    use ice_flux, only: e0100 => stressm_3
    use ice_flux, only: e0101 => stressm_4
    use ice_flux, only: e0102 => stress12_1
    use ice_flux, only: e0103 => stress12_2
    use ice_flux, only: e0104 => stress12_3
    use ice_flux, only: e0105 => stress12_4
    use ice_flux, only: e0106 => stresspT
    use ice_flux, only: e0107 => stressmT
    use ice_flux, only: e0108 => stress12T
    use ice_flux, only: e0109 => stresspU
    use ice_flux, only: e0110 => stressmU
    use ice_flux, only: e0111 => stress12U
    use ice_flux, only: e0112 => fmU
    use ice_flux, only: e0113 => TbU
    use ice_flux, only: e0114 => fmE
    use ice_flux, only: e0115 => TbE
    use ice_flux, only: e0116 => fmN
    use ice_flux, only: e0117 => TbN
    use ice_flux, only: e0118 => zlvl
    use ice_flux, only: e0119 => zlvs
    use ice_flux, only: e0120 => uatm
    use ice_flux, only: e0121 => vatm
    use ice_flux, only: e0122 => wind
    use ice_flux, only: e0123 => potT
    use ice_flux, only: e0124 => Tair
    use ice_flux, only: e0125 => Qa
    use ice_flux, only: e0126 => rhoa
    use ice_flux, only: e0127 => swvdr
    use ice_flux, only: e0128 => swvdf
    use ice_flux, only: e0129 => swidr
    use ice_flux, only: e0130 => swidf
    use ice_flux, only: e0131 => flw
    use ice_flux, only: e0132 => fsurfn_f
    use ice_flux, only: e0133 => fcondtopn_f
    use ice_flux, only: e0134 => fsensn_f
    use ice_flux, only: e0135 => flatn_f
    use ice_flux, only: e0136 => evapn_f
    use ice_flux, only: e0137 => dflatndTsfc_f
    use ice_flux, only: e0138 => dfsurfndTsfc_f
    use ice_flux, only: e0139 => swuvrdr
    use ice_flux, only: e0140 => swuvrdf
    use ice_flux, only: e0141 => swpardr
    use ice_flux, only: e0142 => swpardf
    use ice_flux, only: e0143 => frain
    use ice_flux, only: e0144 => fsnow
    use ice_flux, only: e0145 => sss
    use ice_flux, only: e0146 => sst
    use ice_flux, only: e0147 => frzmlt
    use ice_flux, only: e0148 => frzmlt_init
    use ice_flux, only: e0149 => Tf
    use ice_flux, only: e0150 => qdp
    use ice_flux, only: e0151 => hmix
    use ice_flux, only: e0152 => daice_da
    use ice_flux, only: e0153 => fsens
    use ice_flux, only: e0154 => flat
    use ice_flux, only: e0155 => fswabs
    use ice_flux, only: e0156 => fswint_ai
    use ice_flux, only: e0157 => flwout
    use ice_flux, only: e0158 => Tref
    use ice_flux, only: e0159 => Qref
    use ice_flux, only: e0160 => Uref
    use ice_flux, only: e0161 => evap
    use ice_flux, only: e0162 => evaps
    use ice_flux, only: e0163 => evapi
    use ice_flux, only: e0164 => alvdr
    use ice_flux, only: e0165 => alidr
    use ice_flux, only: e0166 => alvdf
    use ice_flux, only: e0167 => alidf
    use ice_flux, only: e0168 => alvdr_ai
    use ice_flux, only: e0169 => alidr_ai
    use ice_flux, only: e0170 => alvdf_ai
    use ice_flux, only: e0171 => alidf_ai
    use ice_flux, only: e0172 => albice
    use ice_flux, only: e0173 => albsno
    use ice_flux, only: e0174 => albpnd
    use ice_flux, only: e0175 => apeff_ai
    use ice_flux, only: e0176 => snowfrac
    use ice_flux, only: e0177 => alvdr_init
    use ice_flux, only: e0178 => alidr_init
    use ice_flux, only: e0179 => alvdf_init
    use ice_flux, only: e0180 => alidf_init
    use ice_flux, only: e0181 => albcnt
    use ice_flux, only: e0182 => fpond
    use ice_flux, only: e0183 => fresh
    use ice_flux, only: e0184 => fsalt
    use ice_flux, only: e0185 => fhocn
    use ice_flux, only: e0186 => fsloss
    use ice_flux, only: e0187 => fswthru
    use ice_flux, only: e0188 => fswthru_vdr
    use ice_flux, only: e0189 => fswthru_vdf
    use ice_flux, only: e0190 => fswthru_idr
    use ice_flux, only: e0191 => fswthru_idf
    use ice_flux, only: e0192 => fswthru_uvrdr
    use ice_flux, only: e0193 => fswthru_uvrdf
    use ice_flux, only: e0194 => fswthru_pardr
    use ice_flux, only: e0195 => fswthru_pardf
    use ice_flux, only: e0196 => scale_factor
    use ice_flux, only: e0197 => update_ocn_f
    use ice_flux, only: e0198 => l_mpond_fresh
    use ice_flux, only: e0199 => cpl_frazil
    use ice_flux, only: e0200 => meltsn
    use ice_flux, only: e0201 => melttn
    use ice_flux, only: e0202 => meltbn
    use ice_flux, only: e0203 => congeln
    use ice_flux, only: e0204 => snoicen
    use ice_flux, only: e0205 => keffn_top
    use ice_flux, only: e0206 => strairx_ocn
    use ice_flux, only: e0207 => strairy_ocn
    use ice_flux, only: e0208 => fsens_ocn
    use ice_flux, only: e0209 => flat_ocn
    use ice_flux, only: e0210 => flwout_ocn
    use ice_flux, only: e0211 => evap_ocn
    use ice_flux, only: e0212 => alvdr_ocn
    use ice_flux, only: e0213 => alidr_ocn
    use ice_flux, only: e0214 => alvdf_ocn
    use ice_flux, only: e0215 => alidf_ocn
    use ice_flux, only: e0216 => Tref_ocn
    use ice_flux, only: e0217 => Qref_ocn
    use ice_flux, only: e0218 => fsurf
    use ice_flux, only: e0219 => fcondtop
    use ice_flux, only: e0220 => fcondbot
    use ice_flux, only: e0221 => fbot
    use ice_flux, only: e0222 => Tbot
    use ice_flux, only: e0223 => Tsnice
    use ice_flux, only: e0224 => congel
    use ice_flux, only: e0225 => frazil
    use ice_flux, only: e0226 => snoice
    use ice_flux, only: e0227 => meltt
    use ice_flux, only: e0228 => melts
    use ice_flux, only: e0229 => meltb
    use ice_flux, only: e0230 => meltl
    use ice_flux, only: e0231 => dsnow
    use ice_flux, only: e0232 => daidtt
    use ice_flux, only: e0233 => dvidtt
    use ice_flux, only: e0234 => dvsdtt
    use ice_flux, only: e0235 => dagedtt
    use ice_flux, only: e0236 => mlt_onset
    use ice_flux, only: e0237 => frz_onset
    use ice_flux, only: e0238 => frazil_diag
    use ice_flux, only: e0239 => dpnd_flush
    use ice_flux, only: e0240 => dpnd_expon
    use ice_flux, only: e0241 => dpnd_freebd
    use ice_flux, only: e0242 => dpnd_initial
    use ice_flux, only: e0243 => dpnd_dlid
    use ice_flux, only: e0244 => dpnd_melt
    use ice_flux, only: e0245 => dpnd_ridge
    use ice_flux, only: e0246 => dpnd_flushn
    use ice_flux, only: e0247 => dpnd_exponn
    use ice_flux, only: e0248 => dpnd_freebdn
    use ice_flux, only: e0249 => dpnd_initialn
    use ice_flux, only: e0250 => dpnd_dlidn
    use ice_flux, only: e0251 => fsurfn
    use ice_flux, only: e0252 => fcondtopn
    use ice_flux, only: e0253 => fcondbotn
    use ice_flux, only: e0254 => fsensn
    use ice_flux, only: e0255 => flatn
    use ice_flux, only: e0256 => snwcnt
    use ice_flux, only: e0257 => fresh_ai
    use ice_flux, only: e0258 => fsalt_ai
    use ice_flux, only: e0259 => fhocn_ai
    use ice_flux, only: e0260 => fswthru_ai
    use ice_flux, only: e0261 => fresh_da
    use ice_flux, only: e0262 => fsalt_da
    use ice_flux, only: e0263 => fswthrun_ai
    use ice_flux, only: e0264 => send_i2x_per_cat
    use ice_flux, only: e0265 => uatmT
    use ice_flux, only: e0266 => vatmT
    use ice_flux, only: e0267 => wlat
    use ice_flux, only: e0268 => fsw
    use ice_flux, only: e0269 => fswup
    use ice_flux, only: e0270 => coszen
    use ice_flux, only: e0271 => rdg_conv
    use ice_flux, only: e0272 => rdg_shear
    use ice_flux, only: e0273 => rsiden
    use ice_flux, only: e0274 => salinz
    use ice_flux, only: e0275 => Tmltz
    use ice_flux_bgc, only: e0276 => fiso_atm
    use ice_flux_bgc, only: e0277 => faero_atm
    use ice_flux_bgc, only: e0278 => flux_bio_atm
    use ice_flux_bgc, only: e0279 => fiso_ocn
    use ice_flux_bgc, only: e0280 => faero_ocn
    use ice_flux_bgc, only: e0281 => flux_bio
    use ice_flux_bgc, only: e0282 => flux_bio_ai
    use ice_flux_bgc, only: e0283 => cpl_bgc
    use ice_flux_bgc, only: e0284 => hin_old
    use ice_flux_bgc, only: e0285 => dsnown
    use ice_flux_bgc, only: e0286 => nit
    use ice_flux_bgc, only: e0287 => amm
    use ice_flux_bgc, only: e0288 => sil
    use ice_flux_bgc, only: e0289 => dmsp
    use ice_flux_bgc, only: e0290 => dms
    use ice_flux_bgc, only: e0291 => hum
    use ice_flux_bgc, only: e0292 => fnit
    use ice_flux_bgc, only: e0293 => famm
    use ice_flux_bgc, only: e0294 => fsil
    use ice_flux_bgc, only: e0295 => fdmsp
    use ice_flux_bgc, only: e0296 => fdms
    use ice_flux_bgc, only: e0297 => fhum
    use ice_flux_bgc, only: e0298 => fdust
    use ice_flux_bgc, only: e0299 => algalN
    use ice_flux_bgc, only: e0300 => falgalN
    use ice_flux_bgc, only: e0301 => doc
    use ice_flux_bgc, only: e0302 => fdoc
    use ice_flux_bgc, only: e0303 => don
    use ice_flux_bgc, only: e0304 => fdon
    use ice_flux_bgc, only: e0305 => dic
    use ice_flux_bgc, only: e0306 => fdic
    use ice_flux_bgc, only: e0307 => fed
    use ice_flux_bgc, only: e0308 => fep
    use ice_flux_bgc, only: e0309 => ffed
    use ice_flux_bgc, only: e0310 => ffep
    use ice_flux_bgc, only: e0311 => zaeros
    use ice_flux_bgc, only: e0312 => fiso_evap
    use ice_flux_bgc, only: e0313 => Qa_iso
    use ice_flux_bgc, only: e0314 => Qref_iso
    use ice_flux_bgc, only: e0315 => HDO_ocn
    use ice_flux_bgc, only: e0316 => H2_16O_ocn
    use ice_flux_bgc, only: e0317 => H2_18O_ocn
    use ice_arrays_column, only: e0318 => Cdn_atm
    use ice_arrays_column, only: e0319 => Cdn_ocn
    use ice_arrays_column, only: e0320 => hfreebd
    use ice_arrays_column, only: e0321 => hdraft
    use ice_arrays_column, only: e0322 => hridge
    use ice_arrays_column, only: e0323 => distrdg
    use ice_arrays_column, only: e0324 => hkeel
    use ice_arrays_column, only: e0325 => dkeel
    use ice_arrays_column, only: e0326 => lfloe
    use ice_arrays_column, only: e0327 => dfloe
    use ice_arrays_column, only: e0328 => Cdn_atm_skin
    use ice_arrays_column, only: e0329 => Cdn_atm_floe
    use ice_arrays_column, only: e0330 => Cdn_atm_pond
    use ice_arrays_column, only: e0331 => Cdn_atm_rdg
    use ice_arrays_column, only: e0332 => Cdn_ocn_skin
    use ice_arrays_column, only: e0333 => Cdn_ocn_floe
    use ice_arrays_column, only: e0334 => Cdn_ocn_keel
    use ice_arrays_column, only: e0335 => Cdn_atm_ratio
    use ice_arrays_column, only: e0336 => hin_max
    use ice_arrays_column, only: e0337 => c_hi_range
    use ice_arrays_column, only: e0338 => meltsliq
    use ice_arrays_column, only: e0339 => meltsliqn
    use ice_arrays_column, only: e0340 => dhsn
    use ice_arrays_column, only: e0341 => ffracn
    use ice_arrays_column, only: e0342 => alvdrn
    use ice_arrays_column, only: e0343 => alidrn
    use ice_arrays_column, only: e0344 => alvdfn
    use ice_arrays_column, only: e0345 => alidfn
    use ice_arrays_column, only: e0346 => albicen
    use ice_arrays_column, only: e0347 => albsnon
    use ice_arrays_column, only: e0348 => albpndn
    use ice_arrays_column, only: e0349 => apeffn
    use ice_arrays_column, only: e0350 => snowfracn
    use ice_arrays_column, only: e0351 => Iswabsn
    use ice_arrays_column, only: e0352 => Sswabsn
    use ice_arrays_column, only: e0353 => fswsfcn
    use ice_arrays_column, only: e0354 => fswthrun
    use ice_arrays_column, only: e0355 => fswthrun_vdr
    use ice_arrays_column, only: e0356 => fswthrun_vdf
    use ice_arrays_column, only: e0357 => fswthrun_idr
    use ice_arrays_column, only: e0358 => fswthrun_idf
    use ice_arrays_column, only: e0359 => fswthrun_uvrdr
    use ice_arrays_column, only: e0360 => fswthrun_uvrdf
    use ice_arrays_column, only: e0361 => fswthrun_pardr
    use ice_arrays_column, only: e0362 => fswthrun_pardf
    use ice_arrays_column, only: e0363 => fswintn
    use ice_arrays_column, only: e0364 => fswpenln
    use ice_arrays_column, only: e0365 => bgrid
    use ice_arrays_column, only: e0366 => igrid
    use ice_arrays_column, only: e0367 => cgrid
    use ice_arrays_column, only: e0368 => icgrid
    use ice_arrays_column, only: e0369 => swgrid
    use ice_arrays_column, only: e0370 => first_ice_real
    use ice_arrays_column, only: e0371 => first_ice
    use ice_arrays_column, only: e0372 => ocean_bio
    use ice_arrays_column, only: e0373 => fbio_snoice
    use ice_arrays_column, only: e0374 => fbio_atmice
    use ice_arrays_column, only: e0375 => ocean_bio_all
    use ice_arrays_column, only: e0376 => algal_peak
    use ice_arrays_column, only: e0377 => Zoo
    use ice_arrays_column, only: e0378 => dhbr_top
    use ice_arrays_column, only: e0379 => dhbr_bot
    use ice_arrays_column, only: e0380 => grow_net
    use ice_arrays_column, only: e0381 => PP_net
    use ice_arrays_column, only: e0382 => hbri
    use ice_arrays_column, only: e0383 => bphi
    use ice_arrays_column, only: e0384 => bTiz
    use ice_arrays_column, only: e0385 => darcy_V
    use ice_arrays_column, only: e0386 => chl_net
    use ice_arrays_column, only: e0387 => NO_net
    use ice_arrays_column, only: e0388 => sice_rho
    use ice_arrays_column, only: e0389 => zfswin
    use ice_arrays_column, only: e0390 => iDi
    use ice_arrays_column, only: e0391 => iki
    use ice_arrays_column, only: e0392 => upNO
    use ice_arrays_column, only: e0393 => upNH
    use ice_arrays_column, only: e0394 => trcrn_sw
    use ice_arrays_column, only: e0395 => ice_bio_net
    use ice_arrays_column, only: e0396 => snow_bio_net
    use ice_arrays_column, only: e0397 => oceanmixed_ice
    use ice_arrays_column, only: e0398 => restore_bgc
    use ice_arrays_column, only: e0399 => fe_data_type
    use ice_arrays_column, only: e0400 => bgc_data_dir
    use ice_arrays_column, only: e0401 => R_chl2N
    use ice_arrays_column, only: e0402 => R_C2N
    use ice_arrays_column, only: e0403 => floe_rad_l
    use ice_arrays_column, only: e0404 => floe_rad_c
    use ice_arrays_column, only: e0405 => floe_binwidth
    use ice_arrays_column, only: e0406 => wave_sig_ht
    use ice_arrays_column, only: e0407 => wavefreq
    use ice_arrays_column, only: e0408 => dwavefreq
    use ice_arrays_column, only: e0409 => wave_spectrum
    use ice_arrays_column, only: e0410 => d_afsd_newi
    use ice_arrays_column, only: e0411 => d_afsd_latg
    use ice_arrays_column, only: e0412 => d_afsd_latm
    use ice_arrays_column, only: e0413 => d_afsd_wave
    use ice_arrays_column, only: e0414 => d_afsd_weld
    use ice_arrays_column, only: e0415 => c_fsd_range
    use ice_restoring, only: e0416 => restore_ice
    use ice_restoring, only: e0417 => aicen_rest
    use ice_restoring, only: e0418 => vicen_rest
    use ice_restoring, only: e0419 => vsnon_rest
    use ice_restoring, only: e0420 => trcrn_rest
    use ice_dyn_shared, only: e0421 => kdyn
    use ice_dyn_shared, only: e0422 => kridge
    use ice_dyn_shared, only: e0423 => ndte
    use ice_dyn_shared, only: e0424 => coriolis
    use ice_dyn_shared, only: e0425 => ssh_stress
    use ice_dyn_shared, only: e0426 => revised_evp
    use ice_dyn_shared, only: e0427 => evp_algorithm
    use ice_dyn_shared, only: e0428 => dyn_area_min
    use ice_dyn_shared, only: e0429 => dyn_mass_min
    use ice_dyn_shared, only: e0430 => elasticDamp
    use ice_dyn_shared, only: e0431 => yield_curve
    use ice_dyn_shared, only: e0432 => visc_method
    use ice_dyn_shared, only: e0433 => seabed_stress_method
    use ice_dyn_shared, only: e0434 => u0
    use ice_dyn_shared, only: e0435 => cosw
    use ice_dyn_shared, only: e0436 => sinw
    use ice_dyn_shared, only: e0437 => revp
    use ice_dyn_shared, only: e0438 => e_yieldcurve
    use ice_dyn_shared, only: e0439 => e_plasticpot
    use ice_dyn_shared, only: e0440 => epp2i
    use ice_dyn_shared, only: e0441 => e_factor
    use ice_dyn_shared, only: e0442 => ecci
    use ice_dyn_shared, only: e0443 => deltaminEVP
    use ice_dyn_shared, only: e0444 => deltaminVP
    use ice_dyn_shared, only: e0445 => capping
    use ice_dyn_shared, only: e0446 => dtei
    use ice_dyn_shared, only: e0447 => denom1
    use ice_dyn_shared, only: e0448 => arlx
    use ice_dyn_shared, only: e0449 => arlx1i
    use ice_dyn_shared, only: e0450 => brlx
    use ice_dyn_shared, only: e0451 => fcor_blk
    use ice_dyn_shared, only: e0452 => fcorE_blk
    use ice_dyn_shared, only: e0453 => fcorN_blk
    use ice_dyn_shared, only: e0454 => fld2
    use ice_dyn_shared, only: e0455 => fld3
    use ice_dyn_shared, only: e0456 => fld4
    use ice_dyn_shared, only: e0457 => uvel_init
    use ice_dyn_shared, only: e0458 => vvel_init
    use ice_dyn_shared, only: e0459 => uvelN_init
    use ice_dyn_shared, only: e0460 => vvelN_init
    use ice_dyn_shared, only: e0461 => uvelE_init
    use ice_dyn_shared, only: e0462 => vvelE_init
    use ice_dyn_shared, only: e0463 => iceTmask
    use ice_dyn_shared, only: e0464 => iceUmask
    use ice_dyn_shared, only: e0465 => iceNmask
    use ice_dyn_shared, only: e0466 => iceEmask
    use ice_dyn_shared, only: e0467 => DminTarea
    use ice_dyn_shared, only: e0468 => cyp
    use ice_dyn_shared, only: e0469 => cxp
    use ice_dyn_shared, only: e0470 => cym
    use ice_dyn_shared, only: e0471 => cxm
    use ice_dyn_shared, only: e0472 => dxhy
    use ice_dyn_shared, only: e0473 => dyhx
    use ice_dyn_shared, only: e0474 => Ktens
    use ice_dyn_shared, only: e0475 => seabed_stress
    use ice_dyn_shared, only: e0476 => k1
    use ice_dyn_shared, only: e0477 => k2
    use ice_dyn_shared, only: e0478 => alphab
    use ice_dyn_shared, only: e0479 => threshold_hw
    use ice_dyn_evp, only: e0480 => ratiodxN
    use ice_dyn_evp, only: e0481 => ratiodyE
    use ice_dyn_evp, only: e0482 => ratiodxNr
    use ice_dyn_evp, only: e0483 => ratiodyEr
    use ice_dyn_eap, only: e0484 => e11
    use ice_dyn_eap, only: e0485 => e12
    use ice_dyn_eap, only: e0486 => e22
    use ice_dyn_eap, only: e0487 => yieldstress11
    use ice_dyn_eap, only: e0488 => yieldstress12
    use ice_dyn_eap, only: e0489 => yieldstress22
    use ice_dyn_eap, only: e0490 => s11
    use ice_dyn_eap, only: e0491 => s12
    use ice_dyn_eap, only: e0492 => s22
    use ice_dyn_eap, only: e0493 => a11
    use ice_dyn_eap, only: e0494 => a12
    use ice_dyn_vp, only: e0495 => maxits_nonlin
    use ice_dyn_vp, only: e0496 => dim_fgmres
    use ice_dyn_vp, only: e0497 => dim_pgmres
    use ice_dyn_vp, only: e0498 => maxits_fgmres
    use ice_dyn_vp, only: e0499 => maxits_pgmres
    use ice_dyn_vp, only: e0500 => fpfunc_andacc
    use ice_dyn_vp, only: e0501 => dim_andacc
    use ice_dyn_vp, only: e0502 => start_andacc
    use ice_dyn_vp, only: e0503 => monitor_nonlin
    use ice_dyn_vp, only: e0504 => monitor_fgmres
    use ice_dyn_vp, only: e0505 => monitor_pgmres
    use ice_dyn_vp, only: e0506 => use_mean_vrel
    use ice_dyn_vp, only: e0507 => reltol_nonlin
    use ice_dyn_vp, only: e0508 => reltol_fgmres
    use ice_dyn_vp, only: e0509 => reltol_pgmres
    use ice_dyn_vp, only: e0510 => damping_andacc
    use ice_dyn_vp, only: e0511 => reltol_andacc
    use ice_dyn_vp, only: e0512 => precond
    use ice_dyn_vp, only: e0513 => algo_nonlin
    use ice_dyn_vp, only: e0514 => ortho_type
    use ice_transport_driver, only: e0515 => advection
    use ice_transport_driver, only: e0516 => tracer_type
    use ice_transport_driver, only: e0517 => depend
    use ice_transport_driver, only: e0518 => has_dependents
    use ice_transport_driver, only: e0519 => conserv_check
    use ice_grid, only: e0520 => grid_format
    use ice_grid, only: e0521 => gridcpl_file
    use ice_grid, only: e0522 => grid_file
    use ice_grid, only: e0523 => kmt_file
    use ice_grid, only: e0524 => kmt_type
    use ice_grid, only: e0525 => bathymetry_file
    use ice_grid, only: e0526 => bathymetry_format
    use ice_grid, only: e0527 => grid_spacing
    use ice_grid, only: e0528 => grid_ice
    use ice_grid, only: e0529 => grid_ice_thrm
    use ice_grid, only: e0530 => grid_ice_dynu
    use ice_grid, only: e0531 => grid_ice_dynv
    use ice_grid, only: e0532 => grid_atm
    use ice_grid, only: e0533 => grid_atm_thrm
    use ice_grid, only: e0534 => grid_atm_dynu
    use ice_grid, only: e0535 => grid_atm_dynv
    use ice_grid, only: e0536 => grid_ocn
    use ice_grid, only: e0537 => grid_ocn_thrm
    use ice_grid, only: e0538 => grid_ocn_dynu
    use ice_grid, only: e0539 => grid_ocn_dynv
    use ice_grid, only: e0540 => grid_type
    use ice_grid, only: e0541 => dxT
    use ice_grid, only: e0542 => dyT
    use ice_grid, only: e0543 => dxU
    use ice_grid, only: e0544 => dyU
    use ice_grid, only: e0545 => dxN
    use ice_grid, only: e0546 => dyN
    use ice_grid, only: e0547 => dxE
    use ice_grid, only: e0548 => dyE
    use ice_grid, only: e0549 => HTE
    use ice_grid, only: e0550 => HTN
    use ice_grid, only: e0551 => tarea
    use ice_grid, only: e0552 => uarea
    use ice_grid, only: e0553 => narea
    use ice_grid, only: e0554 => earea
    use ice_grid, only: e0555 => tarear
    use ice_grid, only: e0556 => uarear
    use ice_grid, only: e0557 => narear
    use ice_grid, only: e0558 => earear
    use ice_grid, only: e0559 => tarean
    use ice_grid, only: e0560 => tareas
    use ice_grid, only: e0561 => ULON
    use ice_grid, only: e0562 => ULAT
    use ice_grid, only: e0563 => TLON
    use ice_grid, only: e0564 => TLAT
    use ice_grid, only: e0565 => NLON
    use ice_grid, only: e0566 => NLAT
    use ice_grid, only: e0567 => ELON
    use ice_grid, only: e0568 => ELAT
    use ice_grid, only: e0569 => ANGLE
    use ice_grid, only: e0570 => ANGLET
    use ice_grid, only: e0571 => bathymetry
    use ice_grid, only: e0572 => ocn_gridcell_frac
    use ice_grid, only: e0573 => G_HTE
    use ice_grid, only: e0574 => G_HTN
    use ice_grid, only: e0575 => dxrect
    use ice_grid, only: e0576 => dyrect
    use ice_grid, only: e0577 => dxscale
    use ice_grid, only: e0578 => dyscale
    use ice_grid, only: e0579 => lonrefrect
    use ice_grid, only: e0580 => latrefrect
    use ice_grid, only: e0581 => lont_bounds
    use ice_grid, only: e0582 => latt_bounds
    use ice_grid, only: e0583 => lonu_bounds
    use ice_grid, only: e0584 => latu_bounds
    use ice_grid, only: e0585 => lonn_bounds
    use ice_grid, only: e0586 => latn_bounds
    use ice_grid, only: e0587 => lone_bounds
    use ice_grid, only: e0588 => late_bounds
    use ice_grid, only: e0589 => hm
    use ice_grid, only: e0590 => bm
    use ice_grid, only: e0591 => uvm
    use ice_grid, only: e0592 => npm
    use ice_grid, only: e0593 => epm
    use ice_grid, only: e0594 => kmt
    use ice_grid, only: e0595 => grid_outfile
    use ice_grid, only: e0596 => use_bathymetry
    use ice_grid, only: e0597 => save_ghte_ghtn
    use ice_grid, only: e0598 => scale_dxdy
    use ice_grid, only: e0599 => tmask
    use ice_grid, only: e0600 => umask
    use ice_grid, only: e0601 => umaskCD
    use ice_grid, only: e0602 => nmask
    use ice_grid, only: e0603 => emask
    use ice_grid, only: e0604 => opmask
    use ice_grid, only: e0605 => lmask_n
    use ice_grid, only: e0606 => lmask_s
    use ice_grid, only: e0607 => rndex_global
    use icepack_parameters, only: e0608 => argcheck
    use icepack_parameters, only: e0609 => c0
    use icepack_parameters, only: e0610 => c1
    use icepack_parameters, only: e0611 => c1p5
    use icepack_parameters, only: e0612 => c2
    use icepack_parameters, only: e0613 => c3
    use icepack_parameters, only: e0614 => c4
    use icepack_parameters, only: e0615 => c5
    use icepack_parameters, only: e0616 => c6
    use icepack_parameters, only: e0617 => c8
    use icepack_parameters, only: e0618 => c10
    use icepack_parameters, only: e0619 => c15
    use icepack_parameters, only: e0620 => c16
    use icepack_parameters, only: e0621 => c20
    use icepack_parameters, only: e0622 => c25
    use icepack_parameters, only: e0623 => c100
    use icepack_parameters, only: e0624 => c180
    use icepack_parameters, only: e0625 => c1000
    use icepack_parameters, only: e0626 => p001
    use icepack_parameters, only: e0627 => p01
    use icepack_parameters, only: e0628 => p1
    use icepack_parameters, only: e0629 => p2
    use icepack_parameters, only: e0630 => p4
    use icepack_parameters, only: e0631 => p5
    use icepack_parameters, only: e0632 => p6
    use icepack_parameters, only: e0633 => p05
    use icepack_parameters, only: e0634 => p15
    use icepack_parameters, only: e0635 => p25
    use icepack_parameters, only: e0636 => p75
    use icepack_parameters, only: e0637 => p333
    use icepack_parameters, only: e0638 => p666
    use icepack_parameters, only: e0639 => spval_const
    use icepack_parameters, only: e0640 => secday
    use icepack_parameters, only: e0641 => puny
    use icepack_parameters, only: e0642 => bignum
    use icepack_parameters, only: e0643 => pi
    use icepack_parameters, only: e0644 => pih
    use icepack_parameters, only: e0645 => piq
    use icepack_parameters, only: e0646 => pi2
    use icepack_parameters, only: e0647 => rad_to_deg
    use icepack_parameters, only: e0648 => Lfresh
    use icepack_parameters, only: e0649 => cprho
    use icepack_parameters, only: e0650 => Cp
    use icepack_parameters, only: e0651 => rhos
    use icepack_parameters, only: e0652 => rhoi
    use icepack_parameters, only: e0653 => rhosi
    use icepack_parameters, only: e0654 => rhow
    use icepack_parameters, only: e0655 => rhofresh
    use icepack_parameters, only: e0656 => hfrazilmin
    use icepack_parameters, only: e0657 => cp_ice
    use icepack_parameters, only: e0658 => cp_ocn
    use icepack_parameters, only: e0659 => depressT
    use icepack_parameters, only: e0660 => viscosity_dyn
    use icepack_parameters, only: e0661 => tscale_pnd_drain
    use icepack_parameters, only: e0662 => Tocnfrz
    use icepack_parameters, only: e0663 => Tffresh
    use icepack_parameters, only: e0664 => Lsub
    use icepack_parameters, only: e0665 => Lvap
    use icepack_parameters, only: e0666 => Timelt
    use icepack_parameters, only: e0667 => Tsmelt
    use icepack_parameters, only: e0668 => ice_ref_salinity
    use icepack_parameters, only: e0669 => kice
    use icepack_parameters, only: e0670 => ksno
    use icepack_parameters, only: e0671 => hs_min
    use icepack_parameters, only: e0672 => snowpatch
    use icepack_parameters, only: e0673 => saltmax
    use icepack_parameters, only: e0674 => phi_init
    use icepack_parameters, only: e0675 => min_salin
    use icepack_parameters, only: e0676 => Tliquidus_max
    use icepack_parameters, only: e0677 => dSin0_frazil
    use icepack_parameters, only: e0678 => ustar_min
    use icepack_parameters, only: e0679 => hi_min
    use icepack_parameters, only: e0680 => a_rapid_mode
    use icepack_parameters, only: e0681 => Rac_rapid_mode
    use icepack_parameters, only: e0682 => aspect_rapid_mode
    use icepack_parameters, only: e0683 => dSdt_slow_mode
    use icepack_parameters, only: e0684 => phi_c_slow_mode
    use icepack_parameters, only: e0685 => phi_i_mushy
    use icepack_parameters, only: e0686 => ktherm
    use icepack_parameters, only: e0687 => conduct
    use icepack_parameters, only: e0688 => fbot_xfer_type
    use icepack_parameters, only: e0689 => cpl_frazil
    use icepack_parameters, only: e0690 => calc_Tsfc
    use icepack_parameters, only: e0691 => semi_implicit_Tsfc
    use icepack_parameters, only: e0692 => vapor_flux_correction
    use icepack_parameters, only: e0693 => update_ocn_f
    use icepack_parameters, only: e0694 => modal_aero
    use icepack_parameters, only: e0695 => conserv_check
    use icepack_parameters, only: e0696 => congel_freeze
    use icepack_parameters, only: e0697 => tfrz_option
    use icepack_parameters, only: e0698 => saltflux_option
    use icepack_parameters, only: e0699 => emissivity
    use icepack_parameters, only: e0700 => albocn
    use icepack_parameters, only: e0701 => vonkar
    use icepack_parameters, only: e0702 => stefan_boltzmann
    use icepack_parameters, only: e0703 => kappav
    use icepack_parameters, only: e0704 => hi_ssl
    use icepack_parameters, only: e0705 => hs_ssl
    use icepack_parameters, only: e0706 => hs_ssl_min
    use icepack_parameters, only: e0707 => albicev
    use icepack_parameters, only: e0708 => albicei
    use icepack_parameters, only: e0709 => albsnowv
    use icepack_parameters, only: e0710 => albsnowi
    use icepack_parameters, only: e0711 => ahmax
    use icepack_parameters, only: e0712 => R_ice
    use icepack_parameters, only: e0713 => R_pnd
    use icepack_parameters, only: e0714 => R_snw
    use icepack_parameters, only: e0715 => dT_mlt
    use icepack_parameters, only: e0716 => rsnw_mlt
    use icepack_parameters, only: e0717 => kalg
    use icepack_parameters, only: e0718 => R_gC2molC
    use icepack_parameters, only: e0719 => awtvdr
    use icepack_parameters, only: e0720 => awtidr
    use icepack_parameters, only: e0721 => awtvdf
    use icepack_parameters, only: e0722 => awtidf
    use icepack_parameters, only: e0723 => shortwave
    use icepack_parameters, only: e0724 => albedo_type
    use icepack_parameters, only: e0725 => sw_redist
    use icepack_parameters, only: e0726 => sw_frac
    use icepack_parameters, only: e0727 => sw_dtemp
    use icepack_parameters, only: e0728 => snw_ssp_table
    use icepack_parameters, only: e0729 => hpmin
    use icepack_parameters, only: e0730 => hp0
    use icepack_parameters, only: e0731 => kstrength
    use icepack_parameters, only: e0732 => krdg_partic
    use icepack_parameters, only: e0733 => krdg_redist
    use icepack_parameters, only: e0734 => itd_area_min
    use icepack_parameters, only: e0735 => itd_mass_min
    use icepack_parameters, only: e0736 => Cf
    use icepack_parameters, only: e0737 => Pstar
    use icepack_parameters, only: e0738 => Cstar
    use icepack_parameters, only: e0739 => dragio
    use icepack_parameters, only: e0740 => thickness_ocn_layer1
    use icepack_parameters, only: e0741 => iceruf_ocn
    use icepack_parameters, only: e0742 => gravit
    use icepack_parameters, only: e0743 => mu_rdg
    use icepack_parameters, only: e0744 => calc_dragio
    use icepack_parameters, only: e0745 => cp_air
    use icepack_parameters, only: e0746 => cp_wv
    use icepack_parameters, only: e0747 => zvir
    use icepack_parameters, only: e0748 => zref
    use icepack_parameters, only: e0749 => iceruf
    use icepack_parameters, only: e0750 => qqqice
    use icepack_parameters, only: e0751 => TTTice
    use icepack_parameters, only: e0752 => qqqocn
    use icepack_parameters, only: e0753 => TTTocn
    use icepack_parameters, only: e0754 => senscoef
    use icepack_parameters, only: e0755 => latncoef
    use icepack_parameters, only: e0756 => atmbndy
    use icepack_parameters, only: e0757 => calc_strair
    use icepack_parameters, only: e0758 => formdrag
    use icepack_parameters, only: e0759 => highfreq
    use icepack_parameters, only: e0760 => natmiter
    use icepack_parameters, only: e0761 => atmiter_conv
    use icepack_parameters, only: e0762 => kitd
    use icepack_parameters, only: e0763 => kcatbound
    use icepack_parameters, only: e0764 => nfreq
    use icepack_parameters, only: e0765 => floeshape
    use icepack_parameters, only: e0766 => floediam
    use icepack_parameters, only: e0767 => wave_spec
    use icepack_parameters, only: e0768 => wave_spec_type
    use icepack_parameters, only: e0769 => wave_height_type
    use icepack_parameters, only: e0770 => hs0
    use icepack_parameters, only: e0771 => hs1
    use icepack_parameters, only: e0772 => dpscale
    use icepack_parameters, only: e0773 => rfracmin
    use icepack_parameters, only: e0774 => rfracmax
    use icepack_parameters, only: e0775 => pndaspect
    use icepack_parameters, only: e0776 => frzpnd
    use icepack_parameters, only: e0777 => apnd_sl
    use icepack_parameters, only: e0778 => pndhyps
    use icepack_parameters, only: e0779 => pndfrbd
    use icepack_parameters, only: e0780 => pndhead
    use icepack_parameters, only: e0781 => pndmacr
    use icepack_parameters, only: e0782 => hp1
    use icepack_parameters, only: e0783 => snwredist
    use icepack_parameters, only: e0784 => snw_aging_table
    use icepack_parameters, only: e0785 => use_smliq_pnd
    use icepack_parameters, only: e0786 => snwgrain
    use icepack_parameters, only: e0787 => rsnw_fall
    use icepack_parameters, only: e0788 => rsnw_tmax
    use icepack_parameters, only: e0789 => rhosnew
    use icepack_parameters, only: e0790 => rhosmin
    use icepack_parameters, only: e0791 => rhosmax
    use icepack_parameters, only: e0792 => windmin
    use icepack_parameters, only: e0793 => drhosdwind
    use icepack_parameters, only: e0794 => snwlvlfac
    use icepack_parameters, only: e0795 => snw_growth_wet
    use icepack_parameters, only: e0796 => drsnw_min
    use icepack_parameters, only: e0797 => snwliq_max
    use icepack_parameters, only: e0798 => isnw_T
    use icepack_parameters, only: e0799 => isnw_Tgrd
    use icepack_parameters, only: e0800 => isnw_rhos
    use icepack_parameters, only: e0801 => snowage_rhos
    use icepack_parameters, only: e0802 => snowage_Tgrd
    use icepack_parameters, only: e0803 => snowage_T
    use icepack_parameters, only: e0804 => snowage_tau
    use icepack_parameters, only: e0805 => snowage_kappa
    use icepack_parameters, only: e0806 => snowage_drdt0
    use icepack_parameters, only: e0807 => bgc_flux_type
    use icepack_parameters, only: e0808 => z_tracers
    use icepack_parameters, only: e0809 => scale_bgc
    use icepack_parameters, only: e0810 => solve_zbgc
    use icepack_parameters, only: e0811 => dEdd_algae
    use icepack_parameters, only: e0812 => skl_bgc
    use icepack_parameters, only: e0813 => use_macromolecules
    use icepack_parameters, only: e0814 => use_atm_dust_iron
    use icepack_parameters, only: e0815 => restartbgc
    use icepack_parameters, only: e0816 => phi_snow
    use icepack_parameters, only: e0817 => grid_o
    use icepack_parameters, only: e0818 => initbio_frac
    use icepack_parameters, only: e0819 => l_sk
    use icepack_parameters, only: e0820 => algal_vel
    use icepack_parameters, only: e0821 => R_dFe2dust
    use icepack_parameters, only: e0822 => dustFe_sol
    use icepack_parameters, only: e0823 => frazil_scav
    use icepack_parameters, only: e0824 => sk_l
    use icepack_parameters, only: e0825 => min_bgc
    use icepack_parameters, only: e0826 => T_max
    use icepack_parameters, only: e0827 => fsal
    use icepack_parameters, only: e0828 => op_dep_min
    use icepack_parameters, only: e0829 => fr_graze_s
    use icepack_parameters, only: e0830 => fr_graze_e
    use icepack_parameters, only: e0831 => fr_mort2min
    use icepack_parameters, only: e0832 => fr_dFe
    use icepack_parameters, only: e0833 => k_nitrif
    use icepack_parameters, only: e0834 => t_iron_conv
    use icepack_parameters, only: e0835 => max_loss
    use icepack_parameters, only: e0836 => max_dfe_doc1
    use icepack_parameters, only: e0837 => fr_resp
    use icepack_parameters, only: e0838 => fr_resp_s
    use icepack_parameters, only: e0839 => y_sk_DMS
    use icepack_parameters, only: e0840 => t_sk_conv
    use icepack_parameters, only: e0841 => t_sk_ox
    use icepack_parameters, only: e0842 => grid_o_t
    use icepack_parameters, only: e0843 => ratio_Si2N_diatoms
    use icepack_parameters, only: e0844 => ratio_Si2N_sp
    use icepack_parameters, only: e0845 => ratio_Si2N_phaeo
    use icepack_parameters, only: e0846 => ratio_S2N_diatoms
    use icepack_parameters, only: e0847 => ratio_S2N_sp
    use icepack_parameters, only: e0848 => ratio_S2N_phaeo
    use icepack_parameters, only: e0849 => ratio_Fe2C_diatoms
    use icepack_parameters, only: e0850 => ratio_Fe2C_sp
    use icepack_parameters, only: e0851 => ratio_Fe2C_phaeo
    use icepack_parameters, only: e0852 => ratio_Fe2N_diatoms
    use icepack_parameters, only: e0853 => ratio_Fe2N_sp
    use icepack_parameters, only: e0854 => ratio_Fe2N_phaeo
    use icepack_parameters, only: e0855 => ratio_Fe2DON
    use icepack_parameters, only: e0856 => ratio_Fe2DOC_s
    use icepack_parameters, only: e0857 => ratio_Fe2DOC_l
    use icepack_parameters, only: e0858 => tau_min
    use icepack_parameters, only: e0859 => tau_max
    use icepack_parameters, only: e0860 => chlabs_diatoms
    use icepack_parameters, only: e0861 => chlabs_sp
    use icepack_parameters, only: e0862 => chlabs_phaeo
    use icepack_parameters, only: e0863 => alpha2max_low_diatoms
    use icepack_parameters, only: e0864 => alpha2max_low_sp
    use icepack_parameters, only: e0865 => alpha2max_low_phaeo
    use icepack_parameters, only: e0866 => beta2max_diatoms
    use icepack_parameters, only: e0867 => beta2max_sp
    use icepack_parameters, only: e0868 => beta2max_phaeo
    use icepack_parameters, only: e0869 => mu_max_diatoms
    use icepack_parameters, only: e0870 => mu_max_sp
    use icepack_parameters, only: e0871 => mu_max_phaeo
    use icepack_parameters, only: e0872 => grow_Tdep_diatoms
    use icepack_parameters, only: e0873 => grow_Tdep_sp
    use icepack_parameters, only: e0874 => grow_Tdep_phaeo
    use icepack_parameters, only: e0875 => fr_graze_diatoms
    use icepack_parameters, only: e0876 => fr_graze_sp
    use icepack_parameters, only: e0877 => fr_graze_phaeo
    use icepack_parameters, only: e0878 => mort_pre_diatoms
    use icepack_parameters, only: e0879 => mort_pre_sp
    use icepack_parameters, only: e0880 => mort_pre_phaeo
    use icepack_parameters, only: e0881 => mort_Tdep_diatoms
    use icepack_parameters, only: e0882 => mort_Tdep_sp
    use icepack_parameters, only: e0883 => mort_Tdep_phaeo
    use icepack_parameters, only: e0884 => k_exude_diatoms
    use icepack_parameters, only: e0885 => k_exude_sp
    use icepack_parameters, only: e0886 => k_exude_phaeo
    use icepack_parameters, only: e0887 => K_Nit_diatoms
    use icepack_parameters, only: e0888 => K_Nit_sp
    use icepack_parameters, only: e0889 => K_Nit_phaeo
    use icepack_parameters, only: e0890 => K_Am_diatoms
    use icepack_parameters, only: e0891 => K_Am_sp
    use icepack_parameters, only: e0892 => K_Am_phaeo
    use icepack_parameters, only: e0893 => K_Sil_diatoms
    use icepack_parameters, only: e0894 => K_Sil_sp
    use icepack_parameters, only: e0895 => K_Sil_phaeo
    use icepack_parameters, only: e0896 => K_Fe_diatoms
    use icepack_parameters, only: e0897 => K_Fe_sp
    use icepack_parameters, only: e0898 => K_Fe_phaeo
    use icepack_parameters, only: e0899 => f_don_protein
    use icepack_parameters, only: e0900 => kn_bac_protein
    use icepack_parameters, only: e0901 => f_don_Am_protein
    use icepack_parameters, only: e0902 => f_doc_s
    use icepack_parameters, only: e0903 => f_doc_l
    use icepack_parameters, only: e0904 => f_exude_s
    use icepack_parameters, only: e0905 => f_exude_l
    use icepack_parameters, only: e0906 => k_bac_s
    use icepack_parameters, only: e0907 => k_bac_l
    use icepack_parameters, only: e0908 => algaltype_diatoms
    use icepack_parameters, only: e0909 => algaltype_sp
    use icepack_parameters, only: e0910 => algaltype_phaeo
    use icepack_parameters, only: e0911 => nitratetype
    use icepack_parameters, only: e0912 => ammoniumtype
    use icepack_parameters, only: e0913 => silicatetype
    use icepack_parameters, only: e0914 => dmspptype
    use icepack_parameters, only: e0915 => dmspdtype
    use icepack_parameters, only: e0916 => humtype
    use icepack_parameters, only: e0917 => doctype_s
    use icepack_parameters, only: e0918 => doctype_l
    use icepack_parameters, only: e0919 => dictype_1
    use icepack_parameters, only: e0920 => dontype_protein
    use icepack_parameters, only: e0921 => fedtype_1
    use icepack_parameters, only: e0922 => feptype_1
    use icepack_parameters, only: e0923 => zaerotype_bc1
    use icepack_parameters, only: e0924 => zaerotype_bc2
    use icepack_parameters, only: e0925 => zaerotype_dust1
    use icepack_parameters, only: e0926 => zaerotype_dust2
    use icepack_parameters, only: e0927 => zaerotype_dust3
    use icepack_parameters, only: e0928 => zaerotype_dust4
    use icepack_parameters, only: e0929 => ratio_C2N_diatoms
    use icepack_parameters, only: e0930 => ratio_C2N_sp
    use icepack_parameters, only: e0931 => ratio_C2N_phaeo
    use icepack_parameters, only: e0932 => ratio_chl2N_diatoms
    use icepack_parameters, only: e0933 => ratio_chl2N_sp
    use icepack_parameters, only: e0934 => ratio_chl2N_phaeo
    use icepack_parameters, only: e0935 => ratio_C2N_proteins
    use icepack_parameters, only: e0936 => F_abs_chl_diatoms
    use icepack_parameters, only: e0937 => F_abs_chl_sp
    use icepack_parameters, only: e0938 => F_abs_chl_phaeo
    use icepack_therm_shared, only: e0939 => ferrmax
    use icepack_therm_shared, only: e0940 => Tmin
    use icepack_therm_shared, only: e0941 => l_brine
    use icepack_therm_shared, only: e0942 => dfsurfdTs_cpl
    use icepack_therm_shared, only: e0943 => dflatdTs_cpl
    use icepack_therm_shared, only: e0944 => fsurf_cpl0
    use icepack_therm_shared, only: e0945 => flat_cpl0
    use icepack_therm_shared, only: e0946 => fsurf_cpl
    use icepack_therm_shared, only: e0947 => flat_cpl
    use icepack_tracers, only: e0948 => max_iso
    use icepack_tracers, only: e0949 => nmodal1
    use icepack_tracers, only: e0950 => nmodal2
    use icepack_tracers, only: e0951 => max_algae
    use icepack_tracers, only: e0952 => max_dic
    use icepack_tracers, only: e0953 => max_doc
    use icepack_tracers, only: e0954 => max_don
    use icepack_tracers, only: e0955 => max_fe
    use icepack_tracers, only: e0956 => max_aero
    use icepack_tracers, only: e0957 => max_nbtrcr
    use icepack_tracers, only: e0958 => ntrcr
    use icepack_tracers, only: e0959 => ntrcr_o
    use icepack_tracers, only: e0960 => ncat
    use icepack_tracers, only: e0961 => nilyr
    use icepack_tracers, only: e0962 => nslyr
    use icepack_tracers, only: e0963 => nblyr
    use icepack_tracers, only: e0964 => nfsd
    use icepack_tracers, only: e0965 => n_iso
    use icepack_tracers, only: e0966 => n_aero
    use icepack_tracers, only: e0967 => n_zaero
    use icepack_tracers, only: e0968 => n_algae
    use icepack_tracers, only: e0969 => n_doc
    use icepack_tracers, only: e0970 => n_dic
    use icepack_tracers, only: e0971 => n_don
    use icepack_tracers, only: e0972 => n_fed
    use icepack_tracers, only: e0973 => n_fep
    use icepack_tracers, only: e0974 => nt_Tsfc
    use icepack_tracers, only: e0975 => nt_qice
    use icepack_tracers, only: e0976 => nt_qsno
    use icepack_tracers, only: e0977 => nt_sice
    use icepack_tracers, only: e0978 => nt_fbri
    use icepack_tracers, only: e0979 => nt_iage
    use icepack_tracers, only: e0980 => nt_FY
    use icepack_tracers, only: e0981 => nt_alvl
    use icepack_tracers, only: e0982 => nt_vlvl
    use icepack_tracers, only: e0983 => nt_apnd
    use icepack_tracers, only: e0984 => nt_hpnd
    use icepack_tracers, only: e0985 => nt_ipnd
    use icepack_tracers, only: e0986 => nt_fsd
    use icepack_tracers, only: e0987 => nt_smice
    use icepack_tracers, only: e0988 => nt_smliq
    use icepack_tracers, only: e0989 => nt_rhos
    use icepack_tracers, only: e0990 => nt_rsnw
    use icepack_tracers, only: e0991 => nt_isosno
    use icepack_tracers, only: e0992 => nt_isoice
    use icepack_tracers, only: e0993 => nt_aero
    use icepack_tracers, only: e0994 => nt_bgc_Nit
    use icepack_tracers, only: e0995 => nt_bgc_Am
    use icepack_tracers, only: e0996 => nt_bgc_Sil
    use icepack_tracers, only: e0997 => nt_bgc_DMSPp
    use icepack_tracers, only: e0998 => nt_bgc_DMSPd
    use icepack_tracers, only: e0999 => nt_bgc_DMS
    use icepack_tracers, only: e1000 => nt_bgc_PON
    use icepack_tracers, only: e1001 => nt_bgc_hum
    use icepack_tracers, only: e1002 => nt_zbgc_frac
    use icepack_tracers, only: e1003 => tr_iage
    use icepack_tracers, only: e1004 => tr_FY
    use icepack_tracers, only: e1005 => tr_lvl
    use icepack_tracers, only: e1006 => tr_pond
    use icepack_tracers, only: e1007 => tr_pond_lvl
    use icepack_tracers, only: e1008 => tr_pond_topo
    use icepack_tracers, only: e1009 => tr_pond_sealvl
    use icepack_tracers, only: e1010 => tr_snow
    use icepack_tracers, only: e1011 => tr_iso
    use icepack_tracers, only: e1012 => tr_aero
    use icepack_tracers, only: e1013 => tr_brine
    use icepack_tracers, only: e1014 => tr_fsd
    use icepack_tracers, only: e1015 => tr_zaero
    use icepack_tracers, only: e1016 => tr_bgc_Nit
    use icepack_tracers, only: e1017 => tr_bgc_N
    use icepack_tracers, only: e1018 => tr_bgc_DON
    use icepack_tracers, only: e1019 => tr_bgc_C
    use icepack_tracers, only: e1020 => tr_bgc_chl
    use icepack_tracers, only: e1021 => tr_bgc_Am
    use icepack_tracers, only: e1022 => tr_bgc_Sil
    use icepack_tracers, only: e1023 => tr_bgc_DMS
    use icepack_tracers, only: e1024 => tr_bgc_Fe
    use icepack_tracers, only: e1025 => tr_bgc_PON
    use icepack_tracers, only: e1026 => tr_bgc_hum
    use icepack_tracers, only: e1027 => nbtrcr
    use icepack_tracers, only: e1028 => nbtrcr_sw
    use icepack_tracers, only: e1029 => nlt_chl_sw
    use icepack_tracers, only: e1030 => nlt_zaero_sw
    use icepack_tracers, only: e1031 => nlt_bgc_N
    use icepack_tracers, only: e1032 => nlt_bgc_C
    use icepack_tracers, only: e1033 => nlt_bgc_chl
    use icepack_tracers, only: e1034 => nlt_bgc_DOC
    use icepack_tracers, only: e1035 => nlt_bgc_DON
    use icepack_tracers, only: e1036 => nlt_bgc_DIC
    use icepack_tracers, only: e1037 => nlt_bgc_Fed
    use icepack_tracers, only: e1038 => nlt_bgc_Fep
    use icepack_tracers, only: e1039 => nlt_zaero
    use icepack_tracers, only: e1040 => nlt_bgc_Nit
    use icepack_tracers, only: e1041 => nlt_bgc_Am
    use icepack_tracers, only: e1042 => nlt_bgc_Sil
    use icepack_tracers, only: e1043 => nlt_bgc_DMSPp
    use icepack_tracers, only: e1044 => nlt_bgc_DMSPd
    use icepack_tracers, only: e1045 => nlt_bgc_DMS
    use icepack_tracers, only: e1046 => nlt_bgc_PON
    use icepack_tracers, only: e1047 => nlt_bgc_hum
    use icepack_tracers, only: e1048 => nt_bgc_N
    use icepack_tracers, only: e1049 => nt_bgc_C
    use icepack_tracers, only: e1050 => nt_bgc_chl
    use icepack_tracers, only: e1051 => nt_bgc_DOC
    use icepack_tracers, only: e1052 => nt_bgc_DON
    use icepack_tracers, only: e1053 => nt_bgc_DIC
    use icepack_tracers, only: e1054 => nt_bgc_Fed
    use icepack_tracers, only: e1055 => nt_bgc_Fep
    use icepack_tracers, only: e1056 => nt_zaero
    use icepack_tracers, only: e1057 => bio_index_o
    use icepack_tracers, only: e1058 => bio_index
    use icepack_fsd, only: e1059 => floe_rad_h
    use icepack_fsd, only: e1060 => floe_rad_c
    use icepack_fsd, only: e1061 => floe_rad_l
    use icepack_fsd, only: e1062 => floe_binwidth
    use icepack_fsd, only: e1063 => floe_area_l
    use icepack_fsd, only: e1064 => floe_area_h
    use icepack_fsd, only: e1065 => floe_area_c
    use icepack_fsd, only: e1066 => floe_area_binwidth
    use icepack_fsd, only: e1067 => c_fsd_range
    use icepack_fsd, only: e1068 => iweld
    use icepack_shortwave_data, only: e1069 => nspint_3bd
    use icepack_shortwave_data, only: e1070 => nspint_5bd
    use icepack_shortwave_data, only: e1071 => rsnw_datatype
    use icepack_shortwave_data, only: e1072 => ki_ssl_mn_3bd
    use icepack_shortwave_data, only: e1073 => wi_ssl_mn_3bd
    use icepack_shortwave_data, only: e1074 => gi_ssl_mn_3bd
    use icepack_shortwave_data, only: e1075 => ki_dl_mn_3bd
    use icepack_shortwave_data, only: e1076 => wi_dl_mn_3bd
    use icepack_shortwave_data, only: e1077 => gi_dl_mn_3bd
    use icepack_shortwave_data, only: e1078 => ki_int_mn_3bd
    use icepack_shortwave_data, only: e1079 => wi_int_mn_3bd
    use icepack_shortwave_data, only: e1080 => gi_int_mn_3bd
    use icepack_shortwave_data, only: e1081 => ki_p_ssl_mn
    use icepack_shortwave_data, only: e1082 => wi_p_ssl_mn
    use icepack_shortwave_data, only: e1083 => gi_p_ssl_mn
    use icepack_shortwave_data, only: e1084 => ki_p_int_mn
    use icepack_shortwave_data, only: e1085 => wi_p_int_mn
    use icepack_shortwave_data, only: e1086 => gi_p_int_mn
    use icepack_shortwave_data, only: e1087 => kw
    use icepack_shortwave_data, only: e1088 => ww
    use icepack_shortwave_data, only: e1089 => gw
    use icepack_shortwave_data, only: e1090 => gaer_bc_3bd
    use icepack_shortwave_data, only: e1091 => kaer_bc_3bd
    use icepack_shortwave_data, only: e1092 => waer_bc_3bd
    use icepack_shortwave_data, only: e1093 => gaer_3bd
    use icepack_shortwave_data, only: e1094 => kaer_3bd
    use icepack_shortwave_data, only: e1095 => waer_3bd
    use icepack_shortwave_data, only: e1096 => bcenh_3bd
    use icepack_shortwave_data, only: e1097 => nmbrad_snw
    use icepack_shortwave_data, only: e1098 => rsnw_tab
    use icepack_shortwave_data, only: e1099 => Qs_tab
    use icepack_shortwave_data, only: e1100 => ws_tab
    use icepack_shortwave_data, only: e1101 => gs_tab
    use icepack_shortwave_data, only: e1102 => ki_ssl_mn_5bd
    use icepack_shortwave_data, only: e1103 => wi_ssl_mn_5bd
    use icepack_shortwave_data, only: e1104 => gi_ssl_mn_5bd
    use icepack_shortwave_data, only: e1105 => ki_dl_mn_5bd
    use icepack_shortwave_data, only: e1106 => wi_dl_mn_5bd
    use icepack_shortwave_data, only: e1107 => gi_dl_mn_5bd
    use icepack_shortwave_data, only: e1108 => ki_int_mn_5bd
    use icepack_shortwave_data, only: e1109 => wi_int_mn_5bd
    use icepack_shortwave_data, only: e1110 => gi_int_mn_5bd
    use icepack_shortwave_data, only: e1111 => gaer_bc_5bd
    use icepack_shortwave_data, only: e1112 => kaer_bc_5bd
    use icepack_shortwave_data, only: e1113 => waer_bc_5bd
    use icepack_shortwave_data, only: e1114 => gaer_5bd
    use icepack_shortwave_data, only: e1115 => kaer_5bd
    use icepack_shortwave_data, only: e1116 => waer_5bd
    use icepack_shortwave_data, only: e1117 => bcenh_5bd
    use icepack_shortwave_data, only: e1118 => nmbrad_snicar
    use icepack_shortwave_data, only: e1119 => rsnw_snicar_min
    use icepack_shortwave_data, only: e1120 => rsnw_snicar_max
    use icepack_shortwave_data, only: e1121 => rsnw_snicar_tab
    use icepack_shortwave_data, only: e1122 => ssp_snwextdr
    use icepack_shortwave_data, only: e1123 => ssp_snwextdf
    use icepack_shortwave_data, only: e1124 => ssp_snwalbdr
    use icepack_shortwave_data, only: e1125 => ssp_snwalbdf
    use icepack_shortwave_data, only: e1126 => ssp_sasymmdr
    use icepack_shortwave_data, only: e1127 => ssp_sasymmdf
    use ice_calendar, only: e1128 => ice_calendar_proleptic_gregorian
    use ice_calendar, only: e1129 => ice_calendar_gregorian
    use ice_calendar, only: e1130 => ice_calendar_noleap
    use ice_calendar, only: e1131 => ice_calendar_360day
    use ice_calendar, only: e1132 => months_per_year
    use ice_calendar, only: e1133 => hours_per_day
    use ice_calendar, only: e1134 => minutes_per_hour
    use ice_calendar, only: e1135 => seconds_per_minute
    use ice_calendar, only: e1136 => seconds_per_day
    use ice_calendar, only: e1137 => seconds_per_hour
    use ice_calendar, only: e1138 => days_per_year
    use ice_calendar, only: e1139 => daymo
    use ice_calendar, only: e1140 => daycal
    use ice_calendar, only: e1141 => istep
    use ice_calendar, only: e1142 => istep0
    use ice_calendar, only: e1143 => istep1
    use ice_calendar, only: e1144 => myear
    use ice_calendar, only: e1145 => mmonth
    use ice_calendar, only: e1146 => mday
    use ice_calendar, only: e1147 => msec
    use ice_calendar, only: e1148 => year_init
    use ice_calendar, only: e1149 => month_init
    use ice_calendar, only: e1150 => day_init
    use ice_calendar, only: e1151 => sec_init
    use ice_calendar, only: e1152 => hh_init
    use ice_calendar, only: e1153 => mm_init
    use ice_calendar, only: e1154 => ss_init
    use ice_calendar, only: e1155 => idate
    use ice_calendar, only: e1156 => idate0
    use ice_calendar, only: e1157 => dayyr
    use ice_calendar, only: e1158 => npt
    use ice_calendar, only: e1159 => npt0
    use ice_calendar, only: e1160 => ndtd
    use ice_calendar, only: e1161 => stop_now
    use ice_calendar, only: e1162 => write_restart
    use ice_calendar, only: e1163 => diagfreq
    use ice_calendar, only: e1164 => nstreams
    use ice_calendar, only: e1165 => dumpfreq_n
    use ice_calendar, only: e1166 => histfreq_n
    use ice_calendar, only: e1167 => new_year
    use ice_calendar, only: e1168 => new_month
    use ice_calendar, only: e1169 => new_day
    use ice_calendar, only: e1170 => new_hour
    use ice_calendar, only: e1171 => dt
    use ice_calendar, only: e1172 => dt_dyn
    use ice_calendar, only: e1173 => timesecs
    use ice_calendar, only: e1174 => yday
    use ice_calendar, only: e1175 => nextsw_cday
    use ice_calendar, only: e1176 => use_leap_years
    use ice_calendar, only: e1177 => write_ic
    use ice_calendar, only: e1178 => write_histrest
    use ice_calendar, only: e1179 => dump_last
    use ice_calendar, only: e1180 => force_restart_now
    use ice_calendar, only: e1181 => write_history
    use ice_calendar, only: e1182 => npt_unit
    use ice_calendar, only: e1183 => npt0_unit
    use ice_calendar, only: e1184 => histfreq
    use ice_calendar, only: e1185 => dumpfreq
    use ice_calendar, only: e1186 => dumpfreq_base
    use ice_calendar, only: e1187 => histfreq_base
    use ice_calendar, only: e1188 => calendar_type
    use ice_domain_size, only: e1189 => max_blocks
    use ice_domain_size, only: e1190 => block_size_x
    use ice_domain_size, only: e1191 => block_size_y
    use ice_domain_size, only: e1192 => nx_global
    use ice_domain_size, only: e1193 => ny_global
    use ice_domain_size, only: e1194 => ncat
    use ice_domain_size, only: e1195 => nfsd
    use ice_domain_size, only: e1196 => nilyr
    use ice_domain_size, only: e1197 => nslyr
    use ice_domain_size, only: e1198 => nblyr
    use ice_domain_size, only: e1199 => n_iso
    use ice_domain_size, only: e1200 => n_aero
    use ice_domain_size, only: e1201 => n_zaero
    use ice_domain_size, only: e1202 => n_algae
    use ice_domain_size, only: e1203 => n_doc
    use ice_domain_size, only: e1204 => n_dic
    use ice_domain_size, only: e1205 => n_don
    use ice_domain_size, only: e1206 => n_fed
    use ice_domain_size, only: e1207 => n_fep
    use ice_domain_size, only: e1208 => nfreq
    use ice_domain_size, only: e1209 => max_nstrm
    use ice_domain, only: e1210 => nblocks
    use ice_domain, only: e1211 => close_boundaries
    use ice_domain, only: e1212 => blocks_ice
    use ice_domain, only: e1213 => ew_boundary_type
    use ice_domain, only: e1214 => ns_boundary_type
    use ice_domain, only: e1215 => maskhalo_dyn
    use ice_domain, only: e1216 => maskhalo_remap
    use ice_domain, only: e1217 => maskhalo_bound
    use ice_domain, only: e1218 => halo_dynbundle
    use ice_domain, only: e1219 => landblockelim
    use ice_init, only: e1220 => ice_ic
    use ice_forcing, only: e1221 => ycycle
    use ice_forcing, only: e1222 => fyear_init
    use ice_forcing, only: e1223 => fyear
    use ice_forcing, only: e1224 => fyear_final
    use ice_forcing, only: e1225 => topmelt_file
    use ice_forcing, only: e1226 => botmelt_file
    use ice_forcing, only: e1227 => c1intp
    use ice_forcing, only: e1228 => c2intp
    use ice_forcing, only: e1229 => cldf
    use ice_forcing, only: e1230 => fsw_data
    use ice_forcing, only: e1231 => cldf_data
    use ice_forcing, only: e1232 => fsnow_data
    use ice_forcing, only: e1233 => Tair_data
    use ice_forcing, only: e1234 => uatm_data
    use ice_forcing, only: e1235 => vatm_data
    use ice_forcing, only: e1236 => wind_data
    use ice_forcing, only: e1237 => strax_data
    use ice_forcing, only: e1238 => stray_data
    use ice_forcing, only: e1239 => Qa_data
    use ice_forcing, only: e1240 => rhoa_data
    use ice_forcing, only: e1241 => flw_data
    use ice_forcing, only: e1242 => sst_data
    use ice_forcing, only: e1243 => sss_data
    use ice_forcing, only: e1244 => uocn_data
    use ice_forcing, only: e1245 => vocn_data
    use ice_forcing, only: e1246 => sublim_data
    use ice_forcing, only: e1247 => frain_data
    use ice_forcing, only: e1248 => topmelt_data
    use ice_forcing, only: e1249 => botmelt_data
    use ice_forcing, only: e1250 => atm_data_format
    use ice_forcing, only: e1251 => ocn_data_format
    use ice_forcing, only: e1252 => atm_data_type
    use ice_forcing, only: e1253 => atm_data_version
    use ice_forcing, only: e1254 => bgc_data_type
    use ice_forcing, only: e1255 => ocn_data_type
    use ice_forcing, only: e1256 => ice_data_type
    use ice_forcing, only: e1257 => ice_data_conc
    use ice_forcing, only: e1258 => ice_data_dist
    use ice_forcing, only: e1259 => precip_units
    use ice_forcing, only: e1260 => rotate_wind
    use ice_forcing, only: e1261 => atm_data_dir
    use ice_forcing, only: e1262 => ocn_data_dir
    use ice_forcing, only: e1263 => wave_spec_dir
    use ice_forcing, only: e1264 => wave_spec_file
    use ice_forcing, only: e1265 => oceanmixed_file
    use ice_forcing, only: e1266 => frcvdr
    use ice_forcing, only: e1267 => frcvdf
    use ice_forcing, only: e1268 => frcidr
    use ice_forcing, only: e1269 => frcidf
    use ice_forcing, only: e1270 => ocn_frc_m
    use ice_forcing, only: e1271 => restore_ocn
    use ice_forcing, only: e1272 => trestore
    use ice_forcing, only: e1273 => trest
    use ice_forcing, only: e1274 => debug_forcing
    use ice_forcing, only: e1275 => jday_atm
    use ice_forcing, only: e1276 => Njday_atm
    use ice_forcing, only: e1277 => snw_filename
    use ice_forcing, only: e1278 => snw_rhos_fname
    use ice_forcing, only: e1279 => snw_Tgrd_fname
    use ice_forcing, only: e1280 => snw_T_fname
    use ice_forcing, only: e1281 => snw_tau_fname
    use ice_forcing, only: e1282 => snw_kappa_fname
    use ice_forcing, only: e1283 => snw_drdt0_fname
    use ice_forcing_bgc, only: e1284 => nitdat
    use ice_forcing_bgc, only: e1285 => sildat
    use ice_forcing_bgc, only: e1286 => nit_data
    use ice_forcing_bgc, only: e1287 => sil_data
    use ice_constants, only: e1288 => omega
    use ice_constants, only: e1289 => radius
    use ice_constants, only: e1290 => spval_dbl
    use ice_constants, only: e1291 => spval
    use ice_constants, only: e1292 => shlat
    use ice_constants, only: e1293 => nhlat
    use ice_constants, only: e1294 => c0
    use ice_constants, only: e1295 => c1
    use ice_constants, only: e1296 => c1p5
    use ice_constants, only: e1297 => c2
    use ice_constants, only: e1298 => c3
    use ice_constants, only: e1299 => c4
    use ice_constants, only: e1300 => c5
    use ice_constants, only: e1301 => c6
    use ice_constants, only: e1302 => c8
    use ice_constants, only: e1303 => c9
    use ice_constants, only: e1304 => c10
    use ice_constants, only: e1305 => c12
    use ice_constants, only: e1306 => c15
    use ice_constants, only: e1307 => c16
    use ice_constants, only: e1308 => c20
    use ice_constants, only: e1309 => c25
    use ice_constants, only: e1310 => c30
    use ice_constants, only: e1311 => c100
    use ice_constants, only: e1312 => c180
    use ice_constants, only: e1313 => c360
    use ice_constants, only: e1314 => c365
    use ice_constants, only: e1315 => c400
    use ice_constants, only: e1316 => c1000
    use ice_constants, only: e1317 => c3600
    use ice_constants, only: e1318 => p001
    use ice_constants, only: e1319 => p01
    use ice_constants, only: e1320 => p025
    use ice_constants, only: e1321 => p05
    use ice_constants, only: e1322 => p1
    use ice_constants, only: e1323 => p15
    use ice_constants, only: e1324 => p2
    use ice_constants, only: e1325 => p25
    use ice_constants, only: e1326 => p3
    use ice_constants, only: e1327 => p4
    use ice_constants, only: e1328 => p5
    use ice_constants, only: e1329 => p6
    use ice_constants, only: e1330 => p75
    use ice_constants, only: e1331 => p111
    use ice_constants, only: e1332 => p166
    use ice_constants, only: e1333 => p222
    use ice_constants, only: e1334 => p333
    use ice_constants, only: e1335 => p666
    use ice_constants, only: e1336 => p055
    use ice_constants, only: e1337 => p027
    use ice_constants, only: e1338 => eps04
    use ice_constants, only: e1339 => eps13
    use ice_constants, only: e1340 => eps16
    use ice_constants, only: e1341 => field_loc_unknown
    use ice_constants, only: e1342 => field_loc_noupdate
    use ice_constants, only: e1343 => field_loc_center
    use ice_constants, only: e1344 => field_loc_NEcorner
    use ice_constants, only: e1345 => field_loc_Nface
    use ice_constants, only: e1346 => field_loc_Eface
    use ice_constants, only: e1347 => field_type_unknown
    use ice_constants, only: e1348 => field_type_noupdate
    use ice_constants, only: e1349 => field_type_scalar
    use ice_constants, only: e1350 => field_type_vector
    use ice_constants, only: e1351 => field_type_angle
    use ice_constants, only: e1352 => cm_to_m
    use ice_constants, only: e1353 => m_to_cm
    use ice_constants, only: e1354 => m2_to_km2
    use ice_constants, only: e1355 => kg_to_g
    use ice_constants, only: e1356 => mps_to_cmpdy
    use icepack_orbital, only: icepack_snapshot_orbit
    integer, intent(in) :: step
    integer :: ib, status
    integer, allocatable :: ig(:,:), jg(:,:), bounds(:,:)
    real(real64) :: orbit_values(4)
    type(block) :: this_block
    character(len=160) :: stem
    character(len=8) :: snapshot_date
    character(len=10) :: snapshot_time
    character(len=32) :: run_id
    run_id = ''
    if (my_task == master_task) then
      call date_and_time(date=snapshot_date,time=snapshot_time)
      run_id = snapshot_date//'-'//snapshot_time
    endif
    call broadcast_scalar(run_id,master_task)
    write(stem,'(A,I8.8,A,I6.6)') 'step_entry.',step,'.rank',my_task
    open(newunit=meta_unit,file=trim(stem)//'.txt',status='replace',action='write',iostat=status)
    if (status /= 0) then
      write(nu_diag,*) '(step_entry) cannot open snapshot metadata: ',trim(stem)
      return
    endif
    open(newunit=data_unit,file=trim(stem)//'.bin',status='replace', &
         access='stream',form='unformatted',action='write',iostat=status)
    if (status /= 0) then
      write(nu_diag,*) '(step_entry) cannot open snapshot data: ',trim(stem)
      close(meta_unit)
      return
    endif
    write(meta_unit,'(A)') 'CICE_STEP_ENTRY_V1'
    write(data_unit) int(z'0102030405060708',int64)
    byte_offset = 8_int64
    call entry_char('layout.run_id',run_id)
    call entry_int('layout.step',int(step,int64))
    call entry_int('layout.rank',int(my_task,int64))
    call entry_int('layout.nprocs',int(get_num_procs(),int64))
    allocate(ig(nx_block,nblocks),jg(ny_block,nblocks),bounds(4,nblocks))
    do ib=1,nblocks
      this_block = get_block(blocks_ice(ib),ib)
      ig(:,ib) = this_block%i_glob
      jg(:,ib) = this_block%j_glob
      bounds(:,ib) = [this_block%ilo,this_block%ihi,this_block%jlo,this_block%jhi]
    enddo
    call entry_int('layout.iglob',int(ig,int64),lbound(ig))
    call entry_int('layout.jglob',int(jg,int64),lbound(jg))
    call entry_int('layout.bounds',int(bounds,int64),lbound(bounds))
    call icepack_snapshot_orbit(orbit_values)
    call entry_real('icepack_orbital.eccen',orbit_values(1))
    call entry_real('icepack_orbital.obliqr',orbit_values(2))
    call entry_real('icepack_orbital.lambm0',orbit_values(3))
    call entry_real('icepack_orbital.mvelpp',orbit_values(4))
    if (allocated(e0001)) then
      call entry_real('ice_state.aice', &
         real(e0001,real64),lbound(e0001))
    else
      write(meta_unit,'(A)') 'ice_state.aice U'
    endif
    if (allocated(e0002)) then
      call entry_real('ice_state.aiu', &
         real(e0002,real64),lbound(e0002))
    else
      write(meta_unit,'(A)') 'ice_state.aiu U'
    endif
    if (allocated(e0003)) then
      call entry_real('ice_state.vice', &
         real(e0003,real64),lbound(e0003))
    else
      write(meta_unit,'(A)') 'ice_state.vice U'
    endif
    if (allocated(e0004)) then
      call entry_real('ice_state.vsno', &
         real(e0004,real64),lbound(e0004))
    else
      write(meta_unit,'(A)') 'ice_state.vsno U'
    endif
    if (allocated(e0005)) then
      call entry_real('ice_state.trcr', &
         real(e0005,real64),lbound(e0005))
    else
      write(meta_unit,'(A)') 'ice_state.trcr U'
    endif
    if (allocated(e0006)) then
      call entry_real('ice_state.aice0', &
         real(e0006,real64),lbound(e0006))
    else
      write(meta_unit,'(A)') 'ice_state.aice0 U'
    endif
    if (allocated(e0007)) then
      call entry_real('ice_state.aicen', &
         real(e0007,real64),lbound(e0007))
    else
      write(meta_unit,'(A)') 'ice_state.aicen U'
    endif
    if (allocated(e0008)) then
      call entry_real('ice_state.vicen', &
         real(e0008,real64),lbound(e0008))
    else
      write(meta_unit,'(A)') 'ice_state.vicen U'
    endif
    if (allocated(e0009)) then
      call entry_real('ice_state.vsnon', &
         real(e0009,real64),lbound(e0009))
    else
      write(meta_unit,'(A)') 'ice_state.vsnon U'
    endif
    if (allocated(e0010)) then
      call entry_real('ice_state.trcrn', &
         real(e0010,real64),lbound(e0010))
    else
      write(meta_unit,'(A)') 'ice_state.trcrn U'
    endif
    if (allocated(e0011)) then
      call entry_int('ice_state.trcr_depend', &
         int(e0011,int64),lbound(e0011))
    else
      write(meta_unit,'(A)') 'ice_state.trcr_depend U'
    endif
    if (allocated(e0012)) then
      call entry_int('ice_state.n_trcr_strata', &
         int(e0012,int64),lbound(e0012))
    else
      write(meta_unit,'(A)') 'ice_state.n_trcr_strata U'
    endif
    if (allocated(e0013)) then
      call entry_int('ice_state.nt_strata', &
         int(e0013,int64),lbound(e0013))
    else
      write(meta_unit,'(A)') 'ice_state.nt_strata U'
    endif
    if (allocated(e0014)) then
      call entry_real('ice_state.trcr_base', &
         real(e0014,real64),lbound(e0014))
    else
      write(meta_unit,'(A)') 'ice_state.trcr_base U'
    endif
    if (allocated(e0015)) then
      call entry_real('ice_state.uvel', &
         real(e0015,real64),lbound(e0015))
    else
      write(meta_unit,'(A)') 'ice_state.uvel U'
    endif
    if (allocated(e0016)) then
      call entry_real('ice_state.vvel', &
         real(e0016,real64),lbound(e0016))
    else
      write(meta_unit,'(A)') 'ice_state.vvel U'
    endif
    if (allocated(e0017)) then
      call entry_real('ice_state.uvele', &
         real(e0017,real64),lbound(e0017))
    else
      write(meta_unit,'(A)') 'ice_state.uvele U'
    endif
    if (allocated(e0018)) then
      call entry_real('ice_state.vvele', &
         real(e0018,real64),lbound(e0018))
    else
      write(meta_unit,'(A)') 'ice_state.vvele U'
    endif
    if (allocated(e0019)) then
      call entry_real('ice_state.uveln', &
         real(e0019,real64),lbound(e0019))
    else
      write(meta_unit,'(A)') 'ice_state.uveln U'
    endif
    if (allocated(e0020)) then
      call entry_real('ice_state.vveln', &
         real(e0020,real64),lbound(e0020))
    else
      write(meta_unit,'(A)') 'ice_state.vveln U'
    endif
    if (allocated(e0021)) then
      call entry_real('ice_state.divu', &
         real(e0021,real64),lbound(e0021))
    else
      write(meta_unit,'(A)') 'ice_state.divu U'
    endif
    if (allocated(e0022)) then
      call entry_real('ice_state.shear', &
         real(e0022,real64),lbound(e0022))
    else
      write(meta_unit,'(A)') 'ice_state.shear U'
    endif
    if (allocated(e0023)) then
      call entry_real('ice_state.vort', &
         real(e0023,real64),lbound(e0023))
    else
      write(meta_unit,'(A)') 'ice_state.vort U'
    endif
    if (allocated(e0024)) then
      call entry_real('ice_state.strength', &
         real(e0024,real64),lbound(e0024))
    else
      write(meta_unit,'(A)') 'ice_state.strength U'
    endif
    if (allocated(e0025)) then
      call entry_real('ice_state.aice_init', &
         real(e0025,real64),lbound(e0025))
    else
      write(meta_unit,'(A)') 'ice_state.aice_init U'
    endif
    if (allocated(e0026)) then
      call entry_real('ice_state.aicen_init', &
         real(e0026,real64),lbound(e0026))
    else
      write(meta_unit,'(A)') 'ice_state.aicen_init U'
    endif
    if (allocated(e0027)) then
      call entry_real('ice_state.vicen_init', &
         real(e0027,real64),lbound(e0027))
    else
      write(meta_unit,'(A)') 'ice_state.vicen_init U'
    endif
    if (allocated(e0028)) then
      call entry_real('ice_state.vsnon_init', &
         real(e0028,real64),lbound(e0028))
    else
      write(meta_unit,'(A)') 'ice_state.vsnon_init U'
    endif
    if (allocated(e0029)) then
      call entry_real('ice_state.tsfcn_init', &
         real(e0029,real64),lbound(e0029))
    else
      write(meta_unit,'(A)') 'ice_state.tsfcn_init U'
    endif
    call entry_char('ice_flux.default_season', &
         e0030)
    if (allocated(e0031)) then
      call entry_real('ice_flux.strax', &
         real(e0031,real64),lbound(e0031))
    else
      write(meta_unit,'(A)') 'ice_flux.strax U'
    endif
    if (allocated(e0032)) then
      call entry_real('ice_flux.stray', &
         real(e0032,real64),lbound(e0032))
    else
      write(meta_unit,'(A)') 'ice_flux.stray U'
    endif
    if (allocated(e0033)) then
      call entry_real('ice_flux.uocn', &
         real(e0033,real64),lbound(e0033))
    else
      write(meta_unit,'(A)') 'ice_flux.uocn U'
    endif
    if (allocated(e0034)) then
      call entry_real('ice_flux.vocn', &
         real(e0034,real64),lbound(e0034))
    else
      write(meta_unit,'(A)') 'ice_flux.vocn U'
    endif
    if (allocated(e0035)) then
      call entry_real('ice_flux.ss_tltx', &
         real(e0035,real64),lbound(e0035))
    else
      write(meta_unit,'(A)') 'ice_flux.ss_tltx U'
    endif
    if (allocated(e0036)) then
      call entry_real('ice_flux.ss_tlty', &
         real(e0036,real64),lbound(e0036))
    else
      write(meta_unit,'(A)') 'ice_flux.ss_tlty U'
    endif
    if (allocated(e0037)) then
      call entry_real('ice_flux.hwater', &
         real(e0037,real64),lbound(e0037))
    else
      write(meta_unit,'(A)') 'ice_flux.hwater U'
    endif
    if (allocated(e0038)) then
      call entry_real('ice_flux.strairxt', &
         real(e0038,real64),lbound(e0038))
    else
      write(meta_unit,'(A)') 'ice_flux.strairxt U'
    endif
    if (allocated(e0039)) then
      call entry_real('ice_flux.strairyt', &
         real(e0039,real64),lbound(e0039))
    else
      write(meta_unit,'(A)') 'ice_flux.strairyt U'
    endif
    if (allocated(e0040)) then
      call entry_real('ice_flux.strocnxt_iavg', &
         real(e0040,real64),lbound(e0040))
    else
      write(meta_unit,'(A)') 'ice_flux.strocnxt_iavg U'
    endif
    if (allocated(e0041)) then
      call entry_real('ice_flux.strocnyt_iavg', &
         real(e0041,real64),lbound(e0041))
    else
      write(meta_unit,'(A)') 'ice_flux.strocnyt_iavg U'
    endif
    if (allocated(e0042)) then
      call entry_real('ice_flux.sig1', &
         real(e0042,real64),lbound(e0042))
    else
      write(meta_unit,'(A)') 'ice_flux.sig1 U'
    endif
    if (allocated(e0043)) then
      call entry_real('ice_flux.sig2', &
         real(e0043,real64),lbound(e0043))
    else
      write(meta_unit,'(A)') 'ice_flux.sig2 U'
    endif
    if (allocated(e0044)) then
      call entry_real('ice_flux.sigp', &
         real(e0044,real64),lbound(e0044))
    else
      write(meta_unit,'(A)') 'ice_flux.sigp U'
    endif
    if (allocated(e0045)) then
      call entry_real('ice_flux.taubxu', &
         real(e0045,real64),lbound(e0045))
    else
      write(meta_unit,'(A)') 'ice_flux.taubxu U'
    endif
    if (allocated(e0046)) then
      call entry_real('ice_flux.taubyu', &
         real(e0046,real64),lbound(e0046))
    else
      write(meta_unit,'(A)') 'ice_flux.taubyu U'
    endif
    if (allocated(e0047)) then
      call entry_real('ice_flux.strairxu', &
         real(e0047,real64),lbound(e0047))
    else
      write(meta_unit,'(A)') 'ice_flux.strairxu U'
    endif
    if (allocated(e0048)) then
      call entry_real('ice_flux.strairyu', &
         real(e0048,real64),lbound(e0048))
    else
      write(meta_unit,'(A)') 'ice_flux.strairyu U'
    endif
    if (allocated(e0049)) then
      call entry_real('ice_flux.strocnxu', &
         real(e0049,real64),lbound(e0049))
    else
      write(meta_unit,'(A)') 'ice_flux.strocnxu U'
    endif
    if (allocated(e0050)) then
      call entry_real('ice_flux.strocnyu', &
         real(e0050,real64),lbound(e0050))
    else
      write(meta_unit,'(A)') 'ice_flux.strocnyu U'
    endif
    if (allocated(e0051)) then
      call entry_real('ice_flux.strtltxu', &
         real(e0051,real64),lbound(e0051))
    else
      write(meta_unit,'(A)') 'ice_flux.strtltxu U'
    endif
    if (allocated(e0052)) then
      call entry_real('ice_flux.strtltyu', &
         real(e0052,real64),lbound(e0052))
    else
      write(meta_unit,'(A)') 'ice_flux.strtltyu U'
    endif
    if (allocated(e0053)) then
      call entry_real('ice_flux.strintxu', &
         real(e0053,real64),lbound(e0053))
    else
      write(meta_unit,'(A)') 'ice_flux.strintxu U'
    endif
    if (allocated(e0054)) then
      call entry_real('ice_flux.strintyu', &
         real(e0054,real64),lbound(e0054))
    else
      write(meta_unit,'(A)') 'ice_flux.strintyu U'
    endif
    if (allocated(e0055)) then
      call entry_real('ice_flux.taubxn', &
         real(e0055,real64),lbound(e0055))
    else
      write(meta_unit,'(A)') 'ice_flux.taubxn U'
    endif
    if (allocated(e0056)) then
      call entry_real('ice_flux.taubyn', &
         real(e0056,real64),lbound(e0056))
    else
      write(meta_unit,'(A)') 'ice_flux.taubyn U'
    endif
    if (allocated(e0057)) then
      call entry_real('ice_flux.strairxn', &
         real(e0057,real64),lbound(e0057))
    else
      write(meta_unit,'(A)') 'ice_flux.strairxn U'
    endif
    if (allocated(e0058)) then
      call entry_real('ice_flux.strairyn', &
         real(e0058,real64),lbound(e0058))
    else
      write(meta_unit,'(A)') 'ice_flux.strairyn U'
    endif
    if (allocated(e0059)) then
      call entry_real('ice_flux.strocnxn', &
         real(e0059,real64),lbound(e0059))
    else
      write(meta_unit,'(A)') 'ice_flux.strocnxn U'
    endif
    if (allocated(e0060)) then
      call entry_real('ice_flux.strocnyn', &
         real(e0060,real64),lbound(e0060))
    else
      write(meta_unit,'(A)') 'ice_flux.strocnyn U'
    endif
    if (allocated(e0061)) then
      call entry_real('ice_flux.strtltxn', &
         real(e0061,real64),lbound(e0061))
    else
      write(meta_unit,'(A)') 'ice_flux.strtltxn U'
    endif
    if (allocated(e0062)) then
      call entry_real('ice_flux.strtltyn', &
         real(e0062,real64),lbound(e0062))
    else
      write(meta_unit,'(A)') 'ice_flux.strtltyn U'
    endif
    if (allocated(e0063)) then
      call entry_real('ice_flux.strintxn', &
         real(e0063,real64),lbound(e0063))
    else
      write(meta_unit,'(A)') 'ice_flux.strintxn U'
    endif
    if (allocated(e0064)) then
      call entry_real('ice_flux.strintyn', &
         real(e0064,real64),lbound(e0064))
    else
      write(meta_unit,'(A)') 'ice_flux.strintyn U'
    endif
    if (allocated(e0065)) then
      call entry_real('ice_flux.taubxe', &
         real(e0065,real64),lbound(e0065))
    else
      write(meta_unit,'(A)') 'ice_flux.taubxe U'
    endif
    if (allocated(e0066)) then
      call entry_real('ice_flux.taubye', &
         real(e0066,real64),lbound(e0066))
    else
      write(meta_unit,'(A)') 'ice_flux.taubye U'
    endif
    if (allocated(e0067)) then
      call entry_real('ice_flux.strairxe', &
         real(e0067,real64),lbound(e0067))
    else
      write(meta_unit,'(A)') 'ice_flux.strairxe U'
    endif
    if (allocated(e0068)) then
      call entry_real('ice_flux.strairye', &
         real(e0068,real64),lbound(e0068))
    else
      write(meta_unit,'(A)') 'ice_flux.strairye U'
    endif
    if (allocated(e0069)) then
      call entry_real('ice_flux.strocnxe', &
         real(e0069,real64),lbound(e0069))
    else
      write(meta_unit,'(A)') 'ice_flux.strocnxe U'
    endif
    if (allocated(e0070)) then
      call entry_real('ice_flux.strocnye', &
         real(e0070,real64),lbound(e0070))
    else
      write(meta_unit,'(A)') 'ice_flux.strocnye U'
    endif
    if (allocated(e0071)) then
      call entry_real('ice_flux.strtltxe', &
         real(e0071,real64),lbound(e0071))
    else
      write(meta_unit,'(A)') 'ice_flux.strtltxe U'
    endif
    if (allocated(e0072)) then
      call entry_real('ice_flux.strtltye', &
         real(e0072,real64),lbound(e0072))
    else
      write(meta_unit,'(A)') 'ice_flux.strtltye U'
    endif
    if (allocated(e0073)) then
      call entry_real('ice_flux.strintxe', &
         real(e0073,real64),lbound(e0073))
    else
      write(meta_unit,'(A)') 'ice_flux.strintxe U'
    endif
    if (allocated(e0074)) then
      call entry_real('ice_flux.strintye', &
         real(e0074,real64),lbound(e0074))
    else
      write(meta_unit,'(A)') 'ice_flux.strintye U'
    endif
    if (allocated(e0075)) then
      call entry_real('ice_flux.daidtd', &
         real(e0075,real64),lbound(e0075))
    else
      write(meta_unit,'(A)') 'ice_flux.daidtd U'
    endif
    if (allocated(e0076)) then
      call entry_real('ice_flux.dvidtd', &
         real(e0076,real64),lbound(e0076))
    else
      write(meta_unit,'(A)') 'ice_flux.dvidtd U'
    endif
    if (allocated(e0077)) then
      call entry_real('ice_flux.dvsdtd', &
         real(e0077,real64),lbound(e0077))
    else
      write(meta_unit,'(A)') 'ice_flux.dvsdtd U'
    endif
    if (allocated(e0078)) then
      call entry_real('ice_flux.dagedtd', &
         real(e0078,real64),lbound(e0078))
    else
      write(meta_unit,'(A)') 'ice_flux.dagedtd U'
    endif
    if (allocated(e0079)) then
      call entry_real('ice_flux.dardg1dt', &
         real(e0079,real64),lbound(e0079))
    else
      write(meta_unit,'(A)') 'ice_flux.dardg1dt U'
    endif
    if (allocated(e0080)) then
      call entry_real('ice_flux.dardg2dt', &
         real(e0080,real64),lbound(e0080))
    else
      write(meta_unit,'(A)') 'ice_flux.dardg2dt U'
    endif
    if (allocated(e0081)) then
      call entry_real('ice_flux.dvirdgdt', &
         real(e0081,real64),lbound(e0081))
    else
      write(meta_unit,'(A)') 'ice_flux.dvirdgdt U'
    endif
    if (allocated(e0082)) then
      call entry_real('ice_flux.opening', &
         real(e0082,real64),lbound(e0082))
    else
      write(meta_unit,'(A)') 'ice_flux.opening U'
    endif
    if (allocated(e0083)) then
      call entry_real('ice_flux.dardg1ndt', &
         real(e0083,real64),lbound(e0083))
    else
      write(meta_unit,'(A)') 'ice_flux.dardg1ndt U'
    endif
    if (allocated(e0084)) then
      call entry_real('ice_flux.dardg2ndt', &
         real(e0084,real64),lbound(e0084))
    else
      write(meta_unit,'(A)') 'ice_flux.dardg2ndt U'
    endif
    if (allocated(e0085)) then
      call entry_real('ice_flux.dvirdgndt', &
         real(e0085,real64),lbound(e0085))
    else
      write(meta_unit,'(A)') 'ice_flux.dvirdgndt U'
    endif
    if (allocated(e0086)) then
      call entry_real('ice_flux.aparticn', &
         real(e0086,real64),lbound(e0086))
    else
      write(meta_unit,'(A)') 'ice_flux.aparticn U'
    endif
    if (allocated(e0087)) then
      call entry_real('ice_flux.krdgn', &
         real(e0087,real64),lbound(e0087))
    else
      write(meta_unit,'(A)') 'ice_flux.krdgn U'
    endif
    if (allocated(e0088)) then
      call entry_real('ice_flux.ardgn', &
         real(e0088,real64),lbound(e0088))
    else
      write(meta_unit,'(A)') 'ice_flux.ardgn U'
    endif
    if (allocated(e0089)) then
      call entry_real('ice_flux.vrdgn', &
         real(e0089,real64),lbound(e0089))
    else
      write(meta_unit,'(A)') 'ice_flux.vrdgn U'
    endif
    if (allocated(e0090)) then
      call entry_real('ice_flux.araftn', &
         real(e0090,real64),lbound(e0090))
    else
      write(meta_unit,'(A)') 'ice_flux.araftn U'
    endif
    if (allocated(e0091)) then
      call entry_real('ice_flux.vraftn', &
         real(e0091,real64),lbound(e0091))
    else
      write(meta_unit,'(A)') 'ice_flux.vraftn U'
    endif
    if (allocated(e0092)) then
      call entry_real('ice_flux.aredistn', &
         real(e0092,real64),lbound(e0092))
    else
      write(meta_unit,'(A)') 'ice_flux.aredistn U'
    endif
    if (allocated(e0093)) then
      call entry_real('ice_flux.vredistn', &
         real(e0093,real64),lbound(e0093))
    else
      write(meta_unit,'(A)') 'ice_flux.vredistn U'
    endif
    if (allocated(e0094)) then
      call entry_real('ice_flux.stressp_1', &
         real(e0094,real64),lbound(e0094))
    else
      write(meta_unit,'(A)') 'ice_flux.stressp_1 U'
    endif
    if (allocated(e0095)) then
      call entry_real('ice_flux.stressp_2', &
         real(e0095,real64),lbound(e0095))
    else
      write(meta_unit,'(A)') 'ice_flux.stressp_2 U'
    endif
    if (allocated(e0096)) then
      call entry_real('ice_flux.stressp_3', &
         real(e0096,real64),lbound(e0096))
    else
      write(meta_unit,'(A)') 'ice_flux.stressp_3 U'
    endif
    if (allocated(e0097)) then
      call entry_real('ice_flux.stressp_4', &
         real(e0097,real64),lbound(e0097))
    else
      write(meta_unit,'(A)') 'ice_flux.stressp_4 U'
    endif
    if (allocated(e0098)) then
      call entry_real('ice_flux.stressm_1', &
         real(e0098,real64),lbound(e0098))
    else
      write(meta_unit,'(A)') 'ice_flux.stressm_1 U'
    endif
    if (allocated(e0099)) then
      call entry_real('ice_flux.stressm_2', &
         real(e0099,real64),lbound(e0099))
    else
      write(meta_unit,'(A)') 'ice_flux.stressm_2 U'
    endif
    if (allocated(e0100)) then
      call entry_real('ice_flux.stressm_3', &
         real(e0100,real64),lbound(e0100))
    else
      write(meta_unit,'(A)') 'ice_flux.stressm_3 U'
    endif
    if (allocated(e0101)) then
      call entry_real('ice_flux.stressm_4', &
         real(e0101,real64),lbound(e0101))
    else
      write(meta_unit,'(A)') 'ice_flux.stressm_4 U'
    endif
    if (allocated(e0102)) then
      call entry_real('ice_flux.stress12_1', &
         real(e0102,real64),lbound(e0102))
    else
      write(meta_unit,'(A)') 'ice_flux.stress12_1 U'
    endif
    if (allocated(e0103)) then
      call entry_real('ice_flux.stress12_2', &
         real(e0103,real64),lbound(e0103))
    else
      write(meta_unit,'(A)') 'ice_flux.stress12_2 U'
    endif
    if (allocated(e0104)) then
      call entry_real('ice_flux.stress12_3', &
         real(e0104,real64),lbound(e0104))
    else
      write(meta_unit,'(A)') 'ice_flux.stress12_3 U'
    endif
    if (allocated(e0105)) then
      call entry_real('ice_flux.stress12_4', &
         real(e0105,real64),lbound(e0105))
    else
      write(meta_unit,'(A)') 'ice_flux.stress12_4 U'
    endif
    if (allocated(e0106)) then
      call entry_real('ice_flux.stresspt', &
         real(e0106,real64),lbound(e0106))
    else
      write(meta_unit,'(A)') 'ice_flux.stresspt U'
    endif
    if (allocated(e0107)) then
      call entry_real('ice_flux.stressmt', &
         real(e0107,real64),lbound(e0107))
    else
      write(meta_unit,'(A)') 'ice_flux.stressmt U'
    endif
    if (allocated(e0108)) then
      call entry_real('ice_flux.stress12t', &
         real(e0108,real64),lbound(e0108))
    else
      write(meta_unit,'(A)') 'ice_flux.stress12t U'
    endif
    if (allocated(e0109)) then
      call entry_real('ice_flux.stresspu', &
         real(e0109,real64),lbound(e0109))
    else
      write(meta_unit,'(A)') 'ice_flux.stresspu U'
    endif
    if (allocated(e0110)) then
      call entry_real('ice_flux.stressmu', &
         real(e0110,real64),lbound(e0110))
    else
      write(meta_unit,'(A)') 'ice_flux.stressmu U'
    endif
    if (allocated(e0111)) then
      call entry_real('ice_flux.stress12u', &
         real(e0111,real64),lbound(e0111))
    else
      write(meta_unit,'(A)') 'ice_flux.stress12u U'
    endif
    if (allocated(e0112)) then
      call entry_real('ice_flux.fmu', &
         real(e0112,real64),lbound(e0112))
    else
      write(meta_unit,'(A)') 'ice_flux.fmu U'
    endif
    if (allocated(e0113)) then
      call entry_real('ice_flux.tbu', &
         real(e0113,real64),lbound(e0113))
    else
      write(meta_unit,'(A)') 'ice_flux.tbu U'
    endif
    if (allocated(e0114)) then
      call entry_real('ice_flux.fme', &
         real(e0114,real64),lbound(e0114))
    else
      write(meta_unit,'(A)') 'ice_flux.fme U'
    endif
    if (allocated(e0115)) then
      call entry_real('ice_flux.tbe', &
         real(e0115,real64),lbound(e0115))
    else
      write(meta_unit,'(A)') 'ice_flux.tbe U'
    endif
    if (allocated(e0116)) then
      call entry_real('ice_flux.fmn', &
         real(e0116,real64),lbound(e0116))
    else
      write(meta_unit,'(A)') 'ice_flux.fmn U'
    endif
    if (allocated(e0117)) then
      call entry_real('ice_flux.tbn', &
         real(e0117,real64),lbound(e0117))
    else
      write(meta_unit,'(A)') 'ice_flux.tbn U'
    endif
    if (allocated(e0118)) then
      call entry_real('ice_flux.zlvl', &
         real(e0118,real64),lbound(e0118))
    else
      write(meta_unit,'(A)') 'ice_flux.zlvl U'
    endif
    if (allocated(e0119)) then
      call entry_real('ice_flux.zlvs', &
         real(e0119,real64),lbound(e0119))
    else
      write(meta_unit,'(A)') 'ice_flux.zlvs U'
    endif
    if (allocated(e0120)) then
      call entry_real('ice_flux.uatm', &
         real(e0120,real64),lbound(e0120))
    else
      write(meta_unit,'(A)') 'ice_flux.uatm U'
    endif
    if (allocated(e0121)) then
      call entry_real('ice_flux.vatm', &
         real(e0121,real64),lbound(e0121))
    else
      write(meta_unit,'(A)') 'ice_flux.vatm U'
    endif
    if (allocated(e0122)) then
      call entry_real('ice_flux.wind', &
         real(e0122,real64),lbound(e0122))
    else
      write(meta_unit,'(A)') 'ice_flux.wind U'
    endif
    if (allocated(e0123)) then
      call entry_real('ice_flux.pott', &
         real(e0123,real64),lbound(e0123))
    else
      write(meta_unit,'(A)') 'ice_flux.pott U'
    endif
    if (allocated(e0124)) then
      call entry_real('ice_flux.tair', &
         real(e0124,real64),lbound(e0124))
    else
      write(meta_unit,'(A)') 'ice_flux.tair U'
    endif
    if (allocated(e0125)) then
      call entry_real('ice_flux.qa', &
         real(e0125,real64),lbound(e0125))
    else
      write(meta_unit,'(A)') 'ice_flux.qa U'
    endif
    if (allocated(e0126)) then
      call entry_real('ice_flux.rhoa', &
         real(e0126,real64),lbound(e0126))
    else
      write(meta_unit,'(A)') 'ice_flux.rhoa U'
    endif
    if (allocated(e0127)) then
      call entry_real('ice_flux.swvdr', &
         real(e0127,real64),lbound(e0127))
    else
      write(meta_unit,'(A)') 'ice_flux.swvdr U'
    endif
    if (allocated(e0128)) then
      call entry_real('ice_flux.swvdf', &
         real(e0128,real64),lbound(e0128))
    else
      write(meta_unit,'(A)') 'ice_flux.swvdf U'
    endif
    if (allocated(e0129)) then
      call entry_real('ice_flux.swidr', &
         real(e0129,real64),lbound(e0129))
    else
      write(meta_unit,'(A)') 'ice_flux.swidr U'
    endif
    if (allocated(e0130)) then
      call entry_real('ice_flux.swidf', &
         real(e0130,real64),lbound(e0130))
    else
      write(meta_unit,'(A)') 'ice_flux.swidf U'
    endif
    if (allocated(e0131)) then
      call entry_real('ice_flux.flw', &
         real(e0131,real64),lbound(e0131))
    else
      write(meta_unit,'(A)') 'ice_flux.flw U'
    endif
    if (allocated(e0132)) then
      call entry_real('ice_flux.fsurfn_f', &
         real(e0132,real64),lbound(e0132))
    else
      write(meta_unit,'(A)') 'ice_flux.fsurfn_f U'
    endif
    if (allocated(e0133)) then
      call entry_real('ice_flux.fcondtopn_f', &
         real(e0133,real64),lbound(e0133))
    else
      write(meta_unit,'(A)') 'ice_flux.fcondtopn_f U'
    endif
    if (allocated(e0134)) then
      call entry_real('ice_flux.fsensn_f', &
         real(e0134,real64),lbound(e0134))
    else
      write(meta_unit,'(A)') 'ice_flux.fsensn_f U'
    endif
    if (allocated(e0135)) then
      call entry_real('ice_flux.flatn_f', &
         real(e0135,real64),lbound(e0135))
    else
      write(meta_unit,'(A)') 'ice_flux.flatn_f U'
    endif
    if (allocated(e0136)) then
      call entry_real('ice_flux.evapn_f', &
         real(e0136,real64),lbound(e0136))
    else
      write(meta_unit,'(A)') 'ice_flux.evapn_f U'
    endif
    if (allocated(e0137)) then
      call entry_real('ice_flux.dflatndtsfc_f', &
         real(e0137,real64),lbound(e0137))
    else
      write(meta_unit,'(A)') 'ice_flux.dflatndtsfc_f U'
    endif
    if (allocated(e0138)) then
      call entry_real('ice_flux.dfsurfndtsfc_f', &
         real(e0138,real64),lbound(e0138))
    else
      write(meta_unit,'(A)') 'ice_flux.dfsurfndtsfc_f U'
    endif
    if (allocated(e0139)) then
      call entry_real('ice_flux.swuvrdr', &
         real(e0139,real64),lbound(e0139))
    else
      write(meta_unit,'(A)') 'ice_flux.swuvrdr U'
    endif
    if (allocated(e0140)) then
      call entry_real('ice_flux.swuvrdf', &
         real(e0140,real64),lbound(e0140))
    else
      write(meta_unit,'(A)') 'ice_flux.swuvrdf U'
    endif
    if (allocated(e0141)) then
      call entry_real('ice_flux.swpardr', &
         real(e0141,real64),lbound(e0141))
    else
      write(meta_unit,'(A)') 'ice_flux.swpardr U'
    endif
    if (allocated(e0142)) then
      call entry_real('ice_flux.swpardf', &
         real(e0142,real64),lbound(e0142))
    else
      write(meta_unit,'(A)') 'ice_flux.swpardf U'
    endif
    if (allocated(e0143)) then
      call entry_real('ice_flux.frain', &
         real(e0143,real64),lbound(e0143))
    else
      write(meta_unit,'(A)') 'ice_flux.frain U'
    endif
    if (allocated(e0144)) then
      call entry_real('ice_flux.fsnow', &
         real(e0144,real64),lbound(e0144))
    else
      write(meta_unit,'(A)') 'ice_flux.fsnow U'
    endif
    if (allocated(e0145)) then
      call entry_real('ice_flux.sss', &
         real(e0145,real64),lbound(e0145))
    else
      write(meta_unit,'(A)') 'ice_flux.sss U'
    endif
    if (allocated(e0146)) then
      call entry_real('ice_flux.sst', &
         real(e0146,real64),lbound(e0146))
    else
      write(meta_unit,'(A)') 'ice_flux.sst U'
    endif
    if (allocated(e0147)) then
      call entry_real('ice_flux.frzmlt', &
         real(e0147,real64),lbound(e0147))
    else
      write(meta_unit,'(A)') 'ice_flux.frzmlt U'
    endif
    if (allocated(e0148)) then
      call entry_real('ice_flux.frzmlt_init', &
         real(e0148,real64),lbound(e0148))
    else
      write(meta_unit,'(A)') 'ice_flux.frzmlt_init U'
    endif
    if (allocated(e0149)) then
      call entry_real('ice_flux.tf', &
         real(e0149,real64),lbound(e0149))
    else
      write(meta_unit,'(A)') 'ice_flux.tf U'
    endif
    if (allocated(e0150)) then
      call entry_real('ice_flux.qdp', &
         real(e0150,real64),lbound(e0150))
    else
      write(meta_unit,'(A)') 'ice_flux.qdp U'
    endif
    if (allocated(e0151)) then
      call entry_real('ice_flux.hmix', &
         real(e0151,real64),lbound(e0151))
    else
      write(meta_unit,'(A)') 'ice_flux.hmix U'
    endif
    if (allocated(e0152)) then
      call entry_real('ice_flux.daice_da', &
         real(e0152,real64),lbound(e0152))
    else
      write(meta_unit,'(A)') 'ice_flux.daice_da U'
    endif
    if (allocated(e0153)) then
      call entry_real('ice_flux.fsens', &
         real(e0153,real64),lbound(e0153))
    else
      write(meta_unit,'(A)') 'ice_flux.fsens U'
    endif
    if (allocated(e0154)) then
      call entry_real('ice_flux.flat', &
         real(e0154,real64),lbound(e0154))
    else
      write(meta_unit,'(A)') 'ice_flux.flat U'
    endif
    if (allocated(e0155)) then
      call entry_real('ice_flux.fswabs', &
         real(e0155,real64),lbound(e0155))
    else
      write(meta_unit,'(A)') 'ice_flux.fswabs U'
    endif
    if (allocated(e0156)) then
      call entry_real('ice_flux.fswint_ai', &
         real(e0156,real64),lbound(e0156))
    else
      write(meta_unit,'(A)') 'ice_flux.fswint_ai U'
    endif
    if (allocated(e0157)) then
      call entry_real('ice_flux.flwout', &
         real(e0157,real64),lbound(e0157))
    else
      write(meta_unit,'(A)') 'ice_flux.flwout U'
    endif
    if (allocated(e0158)) then
      call entry_real('ice_flux.tref', &
         real(e0158,real64),lbound(e0158))
    else
      write(meta_unit,'(A)') 'ice_flux.tref U'
    endif
    if (allocated(e0159)) then
      call entry_real('ice_flux.qref', &
         real(e0159,real64),lbound(e0159))
    else
      write(meta_unit,'(A)') 'ice_flux.qref U'
    endif
    if (allocated(e0160)) then
      call entry_real('ice_flux.uref', &
         real(e0160,real64),lbound(e0160))
    else
      write(meta_unit,'(A)') 'ice_flux.uref U'
    endif
    if (allocated(e0161)) then
      call entry_real('ice_flux.evap', &
         real(e0161,real64),lbound(e0161))
    else
      write(meta_unit,'(A)') 'ice_flux.evap U'
    endif
    if (allocated(e0162)) then
      call entry_real('ice_flux.evaps', &
         real(e0162,real64),lbound(e0162))
    else
      write(meta_unit,'(A)') 'ice_flux.evaps U'
    endif
    if (allocated(e0163)) then
      call entry_real('ice_flux.evapi', &
         real(e0163,real64),lbound(e0163))
    else
      write(meta_unit,'(A)') 'ice_flux.evapi U'
    endif
    if (allocated(e0164)) then
      call entry_real('ice_flux.alvdr', &
         real(e0164,real64),lbound(e0164))
    else
      write(meta_unit,'(A)') 'ice_flux.alvdr U'
    endif
    if (allocated(e0165)) then
      call entry_real('ice_flux.alidr', &
         real(e0165,real64),lbound(e0165))
    else
      write(meta_unit,'(A)') 'ice_flux.alidr U'
    endif
    if (allocated(e0166)) then
      call entry_real('ice_flux.alvdf', &
         real(e0166,real64),lbound(e0166))
    else
      write(meta_unit,'(A)') 'ice_flux.alvdf U'
    endif
    if (allocated(e0167)) then
      call entry_real('ice_flux.alidf', &
         real(e0167,real64),lbound(e0167))
    else
      write(meta_unit,'(A)') 'ice_flux.alidf U'
    endif
    if (allocated(e0168)) then
      call entry_real('ice_flux.alvdr_ai', &
         real(e0168,real64),lbound(e0168))
    else
      write(meta_unit,'(A)') 'ice_flux.alvdr_ai U'
    endif
    if (allocated(e0169)) then
      call entry_real('ice_flux.alidr_ai', &
         real(e0169,real64),lbound(e0169))
    else
      write(meta_unit,'(A)') 'ice_flux.alidr_ai U'
    endif
    if (allocated(e0170)) then
      call entry_real('ice_flux.alvdf_ai', &
         real(e0170,real64),lbound(e0170))
    else
      write(meta_unit,'(A)') 'ice_flux.alvdf_ai U'
    endif
    if (allocated(e0171)) then
      call entry_real('ice_flux.alidf_ai', &
         real(e0171,real64),lbound(e0171))
    else
      write(meta_unit,'(A)') 'ice_flux.alidf_ai U'
    endif
    if (allocated(e0172)) then
      call entry_real('ice_flux.albice', &
         real(e0172,real64),lbound(e0172))
    else
      write(meta_unit,'(A)') 'ice_flux.albice U'
    endif
    if (allocated(e0173)) then
      call entry_real('ice_flux.albsno', &
         real(e0173,real64),lbound(e0173))
    else
      write(meta_unit,'(A)') 'ice_flux.albsno U'
    endif
    if (allocated(e0174)) then
      call entry_real('ice_flux.albpnd', &
         real(e0174,real64),lbound(e0174))
    else
      write(meta_unit,'(A)') 'ice_flux.albpnd U'
    endif
    if (allocated(e0175)) then
      call entry_real('ice_flux.apeff_ai', &
         real(e0175,real64),lbound(e0175))
    else
      write(meta_unit,'(A)') 'ice_flux.apeff_ai U'
    endif
    if (allocated(e0176)) then
      call entry_real('ice_flux.snowfrac', &
         real(e0176,real64),lbound(e0176))
    else
      write(meta_unit,'(A)') 'ice_flux.snowfrac U'
    endif
    if (allocated(e0177)) then
      call entry_real('ice_flux.alvdr_init', &
         real(e0177,real64),lbound(e0177))
    else
      write(meta_unit,'(A)') 'ice_flux.alvdr_init U'
    endif
    if (allocated(e0178)) then
      call entry_real('ice_flux.alidr_init', &
         real(e0178,real64),lbound(e0178))
    else
      write(meta_unit,'(A)') 'ice_flux.alidr_init U'
    endif
    if (allocated(e0179)) then
      call entry_real('ice_flux.alvdf_init', &
         real(e0179,real64),lbound(e0179))
    else
      write(meta_unit,'(A)') 'ice_flux.alvdf_init U'
    endif
    if (allocated(e0180)) then
      call entry_real('ice_flux.alidf_init', &
         real(e0180,real64),lbound(e0180))
    else
      write(meta_unit,'(A)') 'ice_flux.alidf_init U'
    endif
    if (allocated(e0181)) then
      call entry_real('ice_flux.albcnt', &
         real(e0181,real64),lbound(e0181))
    else
      write(meta_unit,'(A)') 'ice_flux.albcnt U'
    endif
    if (allocated(e0182)) then
      call entry_real('ice_flux.fpond', &
         real(e0182,real64),lbound(e0182))
    else
      write(meta_unit,'(A)') 'ice_flux.fpond U'
    endif
    if (allocated(e0183)) then
      call entry_real('ice_flux.fresh', &
         real(e0183,real64),lbound(e0183))
    else
      write(meta_unit,'(A)') 'ice_flux.fresh U'
    endif
    if (allocated(e0184)) then
      call entry_real('ice_flux.fsalt', &
         real(e0184,real64),lbound(e0184))
    else
      write(meta_unit,'(A)') 'ice_flux.fsalt U'
    endif
    if (allocated(e0185)) then
      call entry_real('ice_flux.fhocn', &
         real(e0185,real64),lbound(e0185))
    else
      write(meta_unit,'(A)') 'ice_flux.fhocn U'
    endif
    if (allocated(e0186)) then
      call entry_real('ice_flux.fsloss', &
         real(e0186,real64),lbound(e0186))
    else
      write(meta_unit,'(A)') 'ice_flux.fsloss U'
    endif
    if (allocated(e0187)) then
      call entry_real('ice_flux.fswthru', &
         real(e0187,real64),lbound(e0187))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru U'
    endif
    if (allocated(e0188)) then
      call entry_real('ice_flux.fswthru_vdr', &
         real(e0188,real64),lbound(e0188))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru_vdr U'
    endif
    if (allocated(e0189)) then
      call entry_real('ice_flux.fswthru_vdf', &
         real(e0189,real64),lbound(e0189))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru_vdf U'
    endif
    if (allocated(e0190)) then
      call entry_real('ice_flux.fswthru_idr', &
         real(e0190,real64),lbound(e0190))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru_idr U'
    endif
    if (allocated(e0191)) then
      call entry_real('ice_flux.fswthru_idf', &
         real(e0191,real64),lbound(e0191))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru_idf U'
    endif
    if (allocated(e0192)) then
      call entry_real('ice_flux.fswthru_uvrdr', &
         real(e0192,real64),lbound(e0192))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru_uvrdr U'
    endif
    if (allocated(e0193)) then
      call entry_real('ice_flux.fswthru_uvrdf', &
         real(e0193,real64),lbound(e0193))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru_uvrdf U'
    endif
    if (allocated(e0194)) then
      call entry_real('ice_flux.fswthru_pardr', &
         real(e0194,real64),lbound(e0194))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru_pardr U'
    endif
    if (allocated(e0195)) then
      call entry_real('ice_flux.fswthru_pardf', &
         real(e0195,real64),lbound(e0195))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru_pardf U'
    endif
    if (allocated(e0196)) then
      call entry_real('ice_flux.scale_factor', &
         real(e0196,real64),lbound(e0196))
    else
      write(meta_unit,'(A)') 'ice_flux.scale_factor U'
    endif
    call entry_logical('ice_flux.update_ocn_f', &
         e0197)
    call entry_logical('ice_flux.l_mpond_fresh', &
         e0198)
    call entry_char('ice_flux.cpl_frazil', &
         e0199)
    if (allocated(e0200)) then
      call entry_real('ice_flux.meltsn', &
         real(e0200,real64),lbound(e0200))
    else
      write(meta_unit,'(A)') 'ice_flux.meltsn U'
    endif
    if (allocated(e0201)) then
      call entry_real('ice_flux.melttn', &
         real(e0201,real64),lbound(e0201))
    else
      write(meta_unit,'(A)') 'ice_flux.melttn U'
    endif
    if (allocated(e0202)) then
      call entry_real('ice_flux.meltbn', &
         real(e0202,real64),lbound(e0202))
    else
      write(meta_unit,'(A)') 'ice_flux.meltbn U'
    endif
    if (allocated(e0203)) then
      call entry_real('ice_flux.congeln', &
         real(e0203,real64),lbound(e0203))
    else
      write(meta_unit,'(A)') 'ice_flux.congeln U'
    endif
    if (allocated(e0204)) then
      call entry_real('ice_flux.snoicen', &
         real(e0204,real64),lbound(e0204))
    else
      write(meta_unit,'(A)') 'ice_flux.snoicen U'
    endif
    if (allocated(e0205)) then
      call entry_real('ice_flux.keffn_top', &
         real(e0205,real64),lbound(e0205))
    else
      write(meta_unit,'(A)') 'ice_flux.keffn_top U'
    endif
    if (allocated(e0206)) then
      call entry_real('ice_flux.strairx_ocn', &
         real(e0206,real64),lbound(e0206))
    else
      write(meta_unit,'(A)') 'ice_flux.strairx_ocn U'
    endif
    if (allocated(e0207)) then
      call entry_real('ice_flux.strairy_ocn', &
         real(e0207,real64),lbound(e0207))
    else
      write(meta_unit,'(A)') 'ice_flux.strairy_ocn U'
    endif
    if (allocated(e0208)) then
      call entry_real('ice_flux.fsens_ocn', &
         real(e0208,real64),lbound(e0208))
    else
      write(meta_unit,'(A)') 'ice_flux.fsens_ocn U'
    endif
    if (allocated(e0209)) then
      call entry_real('ice_flux.flat_ocn', &
         real(e0209,real64),lbound(e0209))
    else
      write(meta_unit,'(A)') 'ice_flux.flat_ocn U'
    endif
    if (allocated(e0210)) then
      call entry_real('ice_flux.flwout_ocn', &
         real(e0210,real64),lbound(e0210))
    else
      write(meta_unit,'(A)') 'ice_flux.flwout_ocn U'
    endif
    if (allocated(e0211)) then
      call entry_real('ice_flux.evap_ocn', &
         real(e0211,real64),lbound(e0211))
    else
      write(meta_unit,'(A)') 'ice_flux.evap_ocn U'
    endif
    if (allocated(e0212)) then
      call entry_real('ice_flux.alvdr_ocn', &
         real(e0212,real64),lbound(e0212))
    else
      write(meta_unit,'(A)') 'ice_flux.alvdr_ocn U'
    endif
    if (allocated(e0213)) then
      call entry_real('ice_flux.alidr_ocn', &
         real(e0213,real64),lbound(e0213))
    else
      write(meta_unit,'(A)') 'ice_flux.alidr_ocn U'
    endif
    if (allocated(e0214)) then
      call entry_real('ice_flux.alvdf_ocn', &
         real(e0214,real64),lbound(e0214))
    else
      write(meta_unit,'(A)') 'ice_flux.alvdf_ocn U'
    endif
    if (allocated(e0215)) then
      call entry_real('ice_flux.alidf_ocn', &
         real(e0215,real64),lbound(e0215))
    else
      write(meta_unit,'(A)') 'ice_flux.alidf_ocn U'
    endif
    if (allocated(e0216)) then
      call entry_real('ice_flux.tref_ocn', &
         real(e0216,real64),lbound(e0216))
    else
      write(meta_unit,'(A)') 'ice_flux.tref_ocn U'
    endif
    if (allocated(e0217)) then
      call entry_real('ice_flux.qref_ocn', &
         real(e0217,real64),lbound(e0217))
    else
      write(meta_unit,'(A)') 'ice_flux.qref_ocn U'
    endif
    if (allocated(e0218)) then
      call entry_real('ice_flux.fsurf', &
         real(e0218,real64),lbound(e0218))
    else
      write(meta_unit,'(A)') 'ice_flux.fsurf U'
    endif
    if (allocated(e0219)) then
      call entry_real('ice_flux.fcondtop', &
         real(e0219,real64),lbound(e0219))
    else
      write(meta_unit,'(A)') 'ice_flux.fcondtop U'
    endif
    if (allocated(e0220)) then
      call entry_real('ice_flux.fcondbot', &
         real(e0220,real64),lbound(e0220))
    else
      write(meta_unit,'(A)') 'ice_flux.fcondbot U'
    endif
    if (allocated(e0221)) then
      call entry_real('ice_flux.fbot', &
         real(e0221,real64),lbound(e0221))
    else
      write(meta_unit,'(A)') 'ice_flux.fbot U'
    endif
    if (allocated(e0222)) then
      call entry_real('ice_flux.tbot', &
         real(e0222,real64),lbound(e0222))
    else
      write(meta_unit,'(A)') 'ice_flux.tbot U'
    endif
    if (allocated(e0223)) then
      call entry_real('ice_flux.tsnice', &
         real(e0223,real64),lbound(e0223))
    else
      write(meta_unit,'(A)') 'ice_flux.tsnice U'
    endif
    if (allocated(e0224)) then
      call entry_real('ice_flux.congel', &
         real(e0224,real64),lbound(e0224))
    else
      write(meta_unit,'(A)') 'ice_flux.congel U'
    endif
    if (allocated(e0225)) then
      call entry_real('ice_flux.frazil', &
         real(e0225,real64),lbound(e0225))
    else
      write(meta_unit,'(A)') 'ice_flux.frazil U'
    endif
    if (allocated(e0226)) then
      call entry_real('ice_flux.snoice', &
         real(e0226,real64),lbound(e0226))
    else
      write(meta_unit,'(A)') 'ice_flux.snoice U'
    endif
    if (allocated(e0227)) then
      call entry_real('ice_flux.meltt', &
         real(e0227,real64),lbound(e0227))
    else
      write(meta_unit,'(A)') 'ice_flux.meltt U'
    endif
    if (allocated(e0228)) then
      call entry_real('ice_flux.melts', &
         real(e0228,real64),lbound(e0228))
    else
      write(meta_unit,'(A)') 'ice_flux.melts U'
    endif
    if (allocated(e0229)) then
      call entry_real('ice_flux.meltb', &
         real(e0229,real64),lbound(e0229))
    else
      write(meta_unit,'(A)') 'ice_flux.meltb U'
    endif
    if (allocated(e0230)) then
      call entry_real('ice_flux.meltl', &
         real(e0230,real64),lbound(e0230))
    else
      write(meta_unit,'(A)') 'ice_flux.meltl U'
    endif
    if (allocated(e0231)) then
      call entry_real('ice_flux.dsnow', &
         real(e0231,real64),lbound(e0231))
    else
      write(meta_unit,'(A)') 'ice_flux.dsnow U'
    endif
    if (allocated(e0232)) then
      call entry_real('ice_flux.daidtt', &
         real(e0232,real64),lbound(e0232))
    else
      write(meta_unit,'(A)') 'ice_flux.daidtt U'
    endif
    if (allocated(e0233)) then
      call entry_real('ice_flux.dvidtt', &
         real(e0233,real64),lbound(e0233))
    else
      write(meta_unit,'(A)') 'ice_flux.dvidtt U'
    endif
    if (allocated(e0234)) then
      call entry_real('ice_flux.dvsdtt', &
         real(e0234,real64),lbound(e0234))
    else
      write(meta_unit,'(A)') 'ice_flux.dvsdtt U'
    endif
    if (allocated(e0235)) then
      call entry_real('ice_flux.dagedtt', &
         real(e0235,real64),lbound(e0235))
    else
      write(meta_unit,'(A)') 'ice_flux.dagedtt U'
    endif
    if (allocated(e0236)) then
      call entry_real('ice_flux.mlt_onset', &
         real(e0236,real64),lbound(e0236))
    else
      write(meta_unit,'(A)') 'ice_flux.mlt_onset U'
    endif
    if (allocated(e0237)) then
      call entry_real('ice_flux.frz_onset', &
         real(e0237,real64),lbound(e0237))
    else
      write(meta_unit,'(A)') 'ice_flux.frz_onset U'
    endif
    if (allocated(e0238)) then
      call entry_real('ice_flux.frazil_diag', &
         real(e0238,real64),lbound(e0238))
    else
      write(meta_unit,'(A)') 'ice_flux.frazil_diag U'
    endif
    if (allocated(e0239)) then
      call entry_real('ice_flux.dpnd_flush', &
         real(e0239,real64),lbound(e0239))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_flush U'
    endif
    if (allocated(e0240)) then
      call entry_real('ice_flux.dpnd_expon', &
         real(e0240,real64),lbound(e0240))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_expon U'
    endif
    if (allocated(e0241)) then
      call entry_real('ice_flux.dpnd_freebd', &
         real(e0241,real64),lbound(e0241))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_freebd U'
    endif
    if (allocated(e0242)) then
      call entry_real('ice_flux.dpnd_initial', &
         real(e0242,real64),lbound(e0242))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_initial U'
    endif
    if (allocated(e0243)) then
      call entry_real('ice_flux.dpnd_dlid', &
         real(e0243,real64),lbound(e0243))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_dlid U'
    endif
    if (allocated(e0244)) then
      call entry_real('ice_flux.dpnd_melt', &
         real(e0244,real64),lbound(e0244))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_melt U'
    endif
    if (allocated(e0245)) then
      call entry_real('ice_flux.dpnd_ridge', &
         real(e0245,real64),lbound(e0245))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_ridge U'
    endif
    if (allocated(e0246)) then
      call entry_real('ice_flux.dpnd_flushn', &
         real(e0246,real64),lbound(e0246))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_flushn U'
    endif
    if (allocated(e0247)) then
      call entry_real('ice_flux.dpnd_exponn', &
         real(e0247,real64),lbound(e0247))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_exponn U'
    endif
    if (allocated(e0248)) then
      call entry_real('ice_flux.dpnd_freebdn', &
         real(e0248,real64),lbound(e0248))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_freebdn U'
    endif
    if (allocated(e0249)) then
      call entry_real('ice_flux.dpnd_initialn', &
         real(e0249,real64),lbound(e0249))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_initialn U'
    endif
    if (allocated(e0250)) then
      call entry_real('ice_flux.dpnd_dlidn', &
         real(e0250,real64),lbound(e0250))
    else
      write(meta_unit,'(A)') 'ice_flux.dpnd_dlidn U'
    endif
    if (allocated(e0251)) then
      call entry_real('ice_flux.fsurfn', &
         real(e0251,real64),lbound(e0251))
    else
      write(meta_unit,'(A)') 'ice_flux.fsurfn U'
    endif
    if (allocated(e0252)) then
      call entry_real('ice_flux.fcondtopn', &
         real(e0252,real64),lbound(e0252))
    else
      write(meta_unit,'(A)') 'ice_flux.fcondtopn U'
    endif
    if (allocated(e0253)) then
      call entry_real('ice_flux.fcondbotn', &
         real(e0253,real64),lbound(e0253))
    else
      write(meta_unit,'(A)') 'ice_flux.fcondbotn U'
    endif
    if (allocated(e0254)) then
      call entry_real('ice_flux.fsensn', &
         real(e0254,real64),lbound(e0254))
    else
      write(meta_unit,'(A)') 'ice_flux.fsensn U'
    endif
    if (allocated(e0255)) then
      call entry_real('ice_flux.flatn', &
         real(e0255,real64),lbound(e0255))
    else
      write(meta_unit,'(A)') 'ice_flux.flatn U'
    endif
    if (allocated(e0256)) then
      call entry_real('ice_flux.snwcnt', &
         real(e0256,real64),lbound(e0256))
    else
      write(meta_unit,'(A)') 'ice_flux.snwcnt U'
    endif
    if (allocated(e0257)) then
      call entry_real('ice_flux.fresh_ai', &
         real(e0257,real64),lbound(e0257))
    else
      write(meta_unit,'(A)') 'ice_flux.fresh_ai U'
    endif
    if (allocated(e0258)) then
      call entry_real('ice_flux.fsalt_ai', &
         real(e0258,real64),lbound(e0258))
    else
      write(meta_unit,'(A)') 'ice_flux.fsalt_ai U'
    endif
    if (allocated(e0259)) then
      call entry_real('ice_flux.fhocn_ai', &
         real(e0259,real64),lbound(e0259))
    else
      write(meta_unit,'(A)') 'ice_flux.fhocn_ai U'
    endif
    if (allocated(e0260)) then
      call entry_real('ice_flux.fswthru_ai', &
         real(e0260,real64),lbound(e0260))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthru_ai U'
    endif
    if (allocated(e0261)) then
      call entry_real('ice_flux.fresh_da', &
         real(e0261,real64),lbound(e0261))
    else
      write(meta_unit,'(A)') 'ice_flux.fresh_da U'
    endif
    if (allocated(e0262)) then
      call entry_real('ice_flux.fsalt_da', &
         real(e0262,real64),lbound(e0262))
    else
      write(meta_unit,'(A)') 'ice_flux.fsalt_da U'
    endif
    if (allocated(e0263)) then
      call entry_real('ice_flux.fswthrun_ai', &
         real(e0263,real64),lbound(e0263))
    else
      write(meta_unit,'(A)') 'ice_flux.fswthrun_ai U'
    endif
    call entry_logical('ice_flux.send_i2x_per_cat', &
         e0264)
    if (allocated(e0265)) then
      call entry_real('ice_flux.uatmt', &
         real(e0265,real64),lbound(e0265))
    else
      write(meta_unit,'(A)') 'ice_flux.uatmt U'
    endif
    if (allocated(e0266)) then
      call entry_real('ice_flux.vatmt', &
         real(e0266,real64),lbound(e0266))
    else
      write(meta_unit,'(A)') 'ice_flux.vatmt U'
    endif
    if (allocated(e0267)) then
      call entry_real('ice_flux.wlat', &
         real(e0267,real64),lbound(e0267))
    else
      write(meta_unit,'(A)') 'ice_flux.wlat U'
    endif
    if (allocated(e0268)) then
      call entry_real('ice_flux.fsw', &
         real(e0268,real64),lbound(e0268))
    else
      write(meta_unit,'(A)') 'ice_flux.fsw U'
    endif
    if (allocated(e0269)) then
      call entry_real('ice_flux.fswup', &
         real(e0269,real64),lbound(e0269))
    else
      write(meta_unit,'(A)') 'ice_flux.fswup U'
    endif
    if (allocated(e0270)) then
      call entry_real('ice_flux.coszen', &
         real(e0270,real64),lbound(e0270))
    else
      write(meta_unit,'(A)') 'ice_flux.coszen U'
    endif
    if (allocated(e0271)) then
      call entry_real('ice_flux.rdg_conv', &
         real(e0271,real64),lbound(e0271))
    else
      write(meta_unit,'(A)') 'ice_flux.rdg_conv U'
    endif
    if (allocated(e0272)) then
      call entry_real('ice_flux.rdg_shear', &
         real(e0272,real64),lbound(e0272))
    else
      write(meta_unit,'(A)') 'ice_flux.rdg_shear U'
    endif
    if (allocated(e0273)) then
      call entry_real('ice_flux.rsiden', &
         real(e0273,real64),lbound(e0273))
    else
      write(meta_unit,'(A)') 'ice_flux.rsiden U'
    endif
    if (allocated(e0274)) then
      call entry_real('ice_flux.salinz', &
         real(e0274,real64),lbound(e0274))
    else
      write(meta_unit,'(A)') 'ice_flux.salinz U'
    endif
    if (allocated(e0275)) then
      call entry_real('ice_flux.tmltz', &
         real(e0275,real64),lbound(e0275))
    else
      write(meta_unit,'(A)') 'ice_flux.tmltz U'
    endif
    if (allocated(e0276)) then
      call entry_real('ice_flux_bgc.fiso_atm', &
         real(e0276,real64),lbound(e0276))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fiso_atm U'
    endif
    if (allocated(e0277)) then
      call entry_real('ice_flux_bgc.faero_atm', &
         real(e0277,real64),lbound(e0277))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.faero_atm U'
    endif
    if (allocated(e0278)) then
      call entry_real('ice_flux_bgc.flux_bio_atm', &
         real(e0278,real64),lbound(e0278))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.flux_bio_atm U'
    endif
    if (allocated(e0279)) then
      call entry_real('ice_flux_bgc.fiso_ocn', &
         real(e0279,real64),lbound(e0279))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fiso_ocn U'
    endif
    if (allocated(e0280)) then
      call entry_real('ice_flux_bgc.faero_ocn', &
         real(e0280,real64),lbound(e0280))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.faero_ocn U'
    endif
    if (allocated(e0281)) then
      call entry_real('ice_flux_bgc.flux_bio', &
         real(e0281,real64),lbound(e0281))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.flux_bio U'
    endif
    if (allocated(e0282)) then
      call entry_real('ice_flux_bgc.flux_bio_ai', &
         real(e0282,real64),lbound(e0282))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.flux_bio_ai U'
    endif
    call entry_logical('ice_flux_bgc.cpl_bgc', &
         e0283)
    if (allocated(e0284)) then
      call entry_real('ice_flux_bgc.hin_old', &
         real(e0284,real64),lbound(e0284))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.hin_old U'
    endif
    if (allocated(e0285)) then
      call entry_real('ice_flux_bgc.dsnown', &
         real(e0285,real64),lbound(e0285))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.dsnown U'
    endif
    if (allocated(e0286)) then
      call entry_real('ice_flux_bgc.nit', &
         real(e0286,real64),lbound(e0286))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.nit U'
    endif
    if (allocated(e0287)) then
      call entry_real('ice_flux_bgc.amm', &
         real(e0287,real64),lbound(e0287))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.amm U'
    endif
    if (allocated(e0288)) then
      call entry_real('ice_flux_bgc.sil', &
         real(e0288,real64),lbound(e0288))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.sil U'
    endif
    if (allocated(e0289)) then
      call entry_real('ice_flux_bgc.dmsp', &
         real(e0289,real64),lbound(e0289))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.dmsp U'
    endif
    if (allocated(e0290)) then
      call entry_real('ice_flux_bgc.dms', &
         real(e0290,real64),lbound(e0290))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.dms U'
    endif
    if (allocated(e0291)) then
      call entry_real('ice_flux_bgc.hum', &
         real(e0291,real64),lbound(e0291))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.hum U'
    endif
    if (allocated(e0292)) then
      call entry_real('ice_flux_bgc.fnit', &
         real(e0292,real64),lbound(e0292))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fnit U'
    endif
    if (allocated(e0293)) then
      call entry_real('ice_flux_bgc.famm', &
         real(e0293,real64),lbound(e0293))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.famm U'
    endif
    if (allocated(e0294)) then
      call entry_real('ice_flux_bgc.fsil', &
         real(e0294,real64),lbound(e0294))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fsil U'
    endif
    if (allocated(e0295)) then
      call entry_real('ice_flux_bgc.fdmsp', &
         real(e0295,real64),lbound(e0295))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fdmsp U'
    endif
    if (allocated(e0296)) then
      call entry_real('ice_flux_bgc.fdms', &
         real(e0296,real64),lbound(e0296))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fdms U'
    endif
    if (allocated(e0297)) then
      call entry_real('ice_flux_bgc.fhum', &
         real(e0297,real64),lbound(e0297))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fhum U'
    endif
    if (allocated(e0298)) then
      call entry_real('ice_flux_bgc.fdust', &
         real(e0298,real64),lbound(e0298))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fdust U'
    endif
    if (allocated(e0299)) then
      call entry_real('ice_flux_bgc.algaln', &
         real(e0299,real64),lbound(e0299))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.algaln U'
    endif
    if (allocated(e0300)) then
      call entry_real('ice_flux_bgc.falgaln', &
         real(e0300,real64),lbound(e0300))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.falgaln U'
    endif
    if (allocated(e0301)) then
      call entry_real('ice_flux_bgc.doc', &
         real(e0301,real64),lbound(e0301))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.doc U'
    endif
    if (allocated(e0302)) then
      call entry_real('ice_flux_bgc.fdoc', &
         real(e0302,real64),lbound(e0302))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fdoc U'
    endif
    if (allocated(e0303)) then
      call entry_real('ice_flux_bgc.don', &
         real(e0303,real64),lbound(e0303))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.don U'
    endif
    if (allocated(e0304)) then
      call entry_real('ice_flux_bgc.fdon', &
         real(e0304,real64),lbound(e0304))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fdon U'
    endif
    if (allocated(e0305)) then
      call entry_real('ice_flux_bgc.dic', &
         real(e0305,real64),lbound(e0305))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.dic U'
    endif
    if (allocated(e0306)) then
      call entry_real('ice_flux_bgc.fdic', &
         real(e0306,real64),lbound(e0306))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fdic U'
    endif
    if (allocated(e0307)) then
      call entry_real('ice_flux_bgc.fed', &
         real(e0307,real64),lbound(e0307))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fed U'
    endif
    if (allocated(e0308)) then
      call entry_real('ice_flux_bgc.fep', &
         real(e0308,real64),lbound(e0308))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fep U'
    endif
    if (allocated(e0309)) then
      call entry_real('ice_flux_bgc.ffed', &
         real(e0309,real64),lbound(e0309))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.ffed U'
    endif
    if (allocated(e0310)) then
      call entry_real('ice_flux_bgc.ffep', &
         real(e0310,real64),lbound(e0310))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.ffep U'
    endif
    if (allocated(e0311)) then
      call entry_real('ice_flux_bgc.zaeros', &
         real(e0311,real64),lbound(e0311))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.zaeros U'
    endif
    if (allocated(e0312)) then
      call entry_real('ice_flux_bgc.fiso_evap', &
         real(e0312,real64),lbound(e0312))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.fiso_evap U'
    endif
    if (allocated(e0313)) then
      call entry_real('ice_flux_bgc.qa_iso', &
         real(e0313,real64),lbound(e0313))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.qa_iso U'
    endif
    if (allocated(e0314)) then
      call entry_real('ice_flux_bgc.qref_iso', &
         real(e0314,real64),lbound(e0314))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.qref_iso U'
    endif
    if (allocated(e0315)) then
      call entry_real('ice_flux_bgc.hdo_ocn', &
         real(e0315,real64),lbound(e0315))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.hdo_ocn U'
    endif
    if (allocated(e0316)) then
      call entry_real('ice_flux_bgc.h2_16o_ocn', &
         real(e0316,real64),lbound(e0316))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.h2_16o_ocn U'
    endif
    if (allocated(e0317)) then
      call entry_real('ice_flux_bgc.h2_18o_ocn', &
         real(e0317,real64),lbound(e0317))
    else
      write(meta_unit,'(A)') 'ice_flux_bgc.h2_18o_ocn U'
    endif
    if (allocated(e0318)) then
      call entry_real('ice_arrays_column.cdn_atm', &
         real(e0318,real64),lbound(e0318))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_atm U'
    endif
    if (allocated(e0319)) then
      call entry_real('ice_arrays_column.cdn_ocn', &
         real(e0319,real64),lbound(e0319))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_ocn U'
    endif
    if (allocated(e0320)) then
      call entry_real('ice_arrays_column.hfreebd', &
         real(e0320,real64),lbound(e0320))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.hfreebd U'
    endif
    if (allocated(e0321)) then
      call entry_real('ice_arrays_column.hdraft', &
         real(e0321,real64),lbound(e0321))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.hdraft U'
    endif
    if (allocated(e0322)) then
      call entry_real('ice_arrays_column.hridge', &
         real(e0322,real64),lbound(e0322))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.hridge U'
    endif
    if (allocated(e0323)) then
      call entry_real('ice_arrays_column.distrdg', &
         real(e0323,real64),lbound(e0323))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.distrdg U'
    endif
    if (allocated(e0324)) then
      call entry_real('ice_arrays_column.hkeel', &
         real(e0324,real64),lbound(e0324))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.hkeel U'
    endif
    if (allocated(e0325)) then
      call entry_real('ice_arrays_column.dkeel', &
         real(e0325,real64),lbound(e0325))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.dkeel U'
    endif
    if (allocated(e0326)) then
      call entry_real('ice_arrays_column.lfloe', &
         real(e0326,real64),lbound(e0326))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.lfloe U'
    endif
    if (allocated(e0327)) then
      call entry_real('ice_arrays_column.dfloe', &
         real(e0327,real64),lbound(e0327))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.dfloe U'
    endif
    if (allocated(e0328)) then
      call entry_real('ice_arrays_column.cdn_atm_skin', &
         real(e0328,real64),lbound(e0328))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_atm_skin U'
    endif
    if (allocated(e0329)) then
      call entry_real('ice_arrays_column.cdn_atm_floe', &
         real(e0329,real64),lbound(e0329))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_atm_floe U'
    endif
    if (allocated(e0330)) then
      call entry_real('ice_arrays_column.cdn_atm_pond', &
         real(e0330,real64),lbound(e0330))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_atm_pond U'
    endif
    if (allocated(e0331)) then
      call entry_real('ice_arrays_column.cdn_atm_rdg', &
         real(e0331,real64),lbound(e0331))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_atm_rdg U'
    endif
    if (allocated(e0332)) then
      call entry_real('ice_arrays_column.cdn_ocn_skin', &
         real(e0332,real64),lbound(e0332))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_ocn_skin U'
    endif
    if (allocated(e0333)) then
      call entry_real('ice_arrays_column.cdn_ocn_floe', &
         real(e0333,real64),lbound(e0333))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_ocn_floe U'
    endif
    if (allocated(e0334)) then
      call entry_real('ice_arrays_column.cdn_ocn_keel', &
         real(e0334,real64),lbound(e0334))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_ocn_keel U'
    endif
    if (allocated(e0335)) then
      call entry_real('ice_arrays_column.cdn_atm_ratio', &
         real(e0335,real64),lbound(e0335))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cdn_atm_ratio U'
    endif
    if (allocated(e0336)) then
      call entry_real('ice_arrays_column.hin_max', &
         real(e0336,real64),lbound(e0336))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.hin_max U'
    endif
    if (allocated(e0337)) then
      call entry_char('ice_arrays_column.c_hi_range', &
         e0337,lbound(e0337))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.c_hi_range U'
    endif
    if (allocated(e0338)) then
      call entry_real('ice_arrays_column.meltsliq', &
         real(e0338,real64),lbound(e0338))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.meltsliq U'
    endif
    if (allocated(e0339)) then
      call entry_real('ice_arrays_column.meltsliqn', &
         real(e0339,real64),lbound(e0339))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.meltsliqn U'
    endif
    if (allocated(e0340)) then
      call entry_real('ice_arrays_column.dhsn', &
         real(e0340,real64),lbound(e0340))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.dhsn U'
    endif
    if (allocated(e0341)) then
      call entry_real('ice_arrays_column.ffracn', &
         real(e0341,real64),lbound(e0341))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.ffracn U'
    endif
    if (allocated(e0342)) then
      call entry_real('ice_arrays_column.alvdrn', &
         real(e0342,real64),lbound(e0342))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.alvdrn U'
    endif
    if (allocated(e0343)) then
      call entry_real('ice_arrays_column.alidrn', &
         real(e0343,real64),lbound(e0343))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.alidrn U'
    endif
    if (allocated(e0344)) then
      call entry_real('ice_arrays_column.alvdfn', &
         real(e0344,real64),lbound(e0344))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.alvdfn U'
    endif
    if (allocated(e0345)) then
      call entry_real('ice_arrays_column.alidfn', &
         real(e0345,real64),lbound(e0345))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.alidfn U'
    endif
    if (allocated(e0346)) then
      call entry_real('ice_arrays_column.albicen', &
         real(e0346,real64),lbound(e0346))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.albicen U'
    endif
    if (allocated(e0347)) then
      call entry_real('ice_arrays_column.albsnon', &
         real(e0347,real64),lbound(e0347))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.albsnon U'
    endif
    if (allocated(e0348)) then
      call entry_real('ice_arrays_column.albpndn', &
         real(e0348,real64),lbound(e0348))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.albpndn U'
    endif
    if (allocated(e0349)) then
      call entry_real('ice_arrays_column.apeffn', &
         real(e0349,real64),lbound(e0349))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.apeffn U'
    endif
    if (allocated(e0350)) then
      call entry_real('ice_arrays_column.snowfracn', &
         real(e0350,real64),lbound(e0350))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.snowfracn U'
    endif
    if (allocated(e0351)) then
      call entry_real('ice_arrays_column.iswabsn', &
         real(e0351,real64),lbound(e0351))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.iswabsn U'
    endif
    if (allocated(e0352)) then
      call entry_real('ice_arrays_column.sswabsn', &
         real(e0352,real64),lbound(e0352))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.sswabsn U'
    endif
    if (allocated(e0353)) then
      call entry_real('ice_arrays_column.fswsfcn', &
         real(e0353,real64),lbound(e0353))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswsfcn U'
    endif
    if (allocated(e0354)) then
      call entry_real('ice_arrays_column.fswthrun', &
         real(e0354,real64),lbound(e0354))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswthrun U'
    endif
    if (allocated(e0355)) then
      call entry_real('ice_arrays_column.fswthrun_vdr', &
         real(e0355,real64),lbound(e0355))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswthrun_vdr U'
    endif
    if (allocated(e0356)) then
      call entry_real('ice_arrays_column.fswthrun_vdf', &
         real(e0356,real64),lbound(e0356))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswthrun_vdf U'
    endif
    if (allocated(e0357)) then
      call entry_real('ice_arrays_column.fswthrun_idr', &
         real(e0357,real64),lbound(e0357))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswthrun_idr U'
    endif
    if (allocated(e0358)) then
      call entry_real('ice_arrays_column.fswthrun_idf', &
         real(e0358,real64),lbound(e0358))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswthrun_idf U'
    endif
    if (allocated(e0359)) then
      call entry_real('ice_arrays_column.fswthrun_uvrdr', &
         real(e0359,real64),lbound(e0359))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswthrun_uvrdr U'
    endif
    if (allocated(e0360)) then
      call entry_real('ice_arrays_column.fswthrun_uvrdf', &
         real(e0360,real64),lbound(e0360))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswthrun_uvrdf U'
    endif
    if (allocated(e0361)) then
      call entry_real('ice_arrays_column.fswthrun_pardr', &
         real(e0361,real64),lbound(e0361))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswthrun_pardr U'
    endif
    if (allocated(e0362)) then
      call entry_real('ice_arrays_column.fswthrun_pardf', &
         real(e0362,real64),lbound(e0362))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswthrun_pardf U'
    endif
    if (allocated(e0363)) then
      call entry_real('ice_arrays_column.fswintn', &
         real(e0363,real64),lbound(e0363))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswintn U'
    endif
    if (allocated(e0364)) then
      call entry_real('ice_arrays_column.fswpenln', &
         real(e0364,real64),lbound(e0364))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fswpenln U'
    endif
    if (allocated(e0365)) then
      call entry_real('ice_arrays_column.bgrid', &
         real(e0365,real64),lbound(e0365))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.bgrid U'
    endif
    if (allocated(e0366)) then
      call entry_real('ice_arrays_column.igrid', &
         real(e0366,real64),lbound(e0366))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.igrid U'
    endif
    if (allocated(e0367)) then
      call entry_real('ice_arrays_column.cgrid', &
         real(e0367,real64),lbound(e0367))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.cgrid U'
    endif
    if (allocated(e0368)) then
      call entry_real('ice_arrays_column.icgrid', &
         real(e0368,real64),lbound(e0368))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.icgrid U'
    endif
    if (allocated(e0369)) then
      call entry_real('ice_arrays_column.swgrid', &
         real(e0369,real64),lbound(e0369))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.swgrid U'
    endif
    if (allocated(e0370)) then
      call entry_real('ice_arrays_column.first_ice_real', &
         real(e0370,real64),lbound(e0370))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.first_ice_real U'
    endif
    if (allocated(e0371)) then
      call entry_logical('ice_arrays_column.first_ice', &
         e0371,lbound(e0371))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.first_ice U'
    endif
    if (allocated(e0372)) then
      call entry_real('ice_arrays_column.ocean_bio', &
         real(e0372,real64),lbound(e0372))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.ocean_bio U'
    endif
    if (allocated(e0373)) then
      call entry_real('ice_arrays_column.fbio_snoice', &
         real(e0373,real64),lbound(e0373))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fbio_snoice U'
    endif
    if (allocated(e0374)) then
      call entry_real('ice_arrays_column.fbio_atmice', &
         real(e0374,real64),lbound(e0374))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.fbio_atmice U'
    endif
    if (allocated(e0375)) then
      call entry_real('ice_arrays_column.ocean_bio_all', &
         real(e0375,real64),lbound(e0375))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.ocean_bio_all U'
    endif
    if (allocated(e0376)) then
      call entry_int('ice_arrays_column.algal_peak', &
         int(e0376,int64),lbound(e0376))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.algal_peak U'
    endif
    if (allocated(e0377)) then
      call entry_real('ice_arrays_column.zoo', &
         real(e0377,real64),lbound(e0377))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.zoo U'
    endif
    if (allocated(e0378)) then
      call entry_real('ice_arrays_column.dhbr_top', &
         real(e0378,real64),lbound(e0378))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.dhbr_top U'
    endif
    if (allocated(e0379)) then
      call entry_real('ice_arrays_column.dhbr_bot', &
         real(e0379,real64),lbound(e0379))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.dhbr_bot U'
    endif
    if (allocated(e0380)) then
      call entry_real('ice_arrays_column.grow_net', &
         real(e0380,real64),lbound(e0380))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.grow_net U'
    endif
    if (allocated(e0381)) then
      call entry_real('ice_arrays_column.pp_net', &
         real(e0381,real64),lbound(e0381))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.pp_net U'
    endif
    if (allocated(e0382)) then
      call entry_real('ice_arrays_column.hbri', &
         real(e0382,real64),lbound(e0382))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.hbri U'
    endif
    if (allocated(e0383)) then
      call entry_real('ice_arrays_column.bphi', &
         real(e0383,real64),lbound(e0383))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.bphi U'
    endif
    if (allocated(e0384)) then
      call entry_real('ice_arrays_column.btiz', &
         real(e0384,real64),lbound(e0384))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.btiz U'
    endif
    if (allocated(e0385)) then
      call entry_real('ice_arrays_column.darcy_v', &
         real(e0385,real64),lbound(e0385))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.darcy_v U'
    endif
    if (allocated(e0386)) then
      call entry_real('ice_arrays_column.chl_net', &
         real(e0386,real64),lbound(e0386))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.chl_net U'
    endif
    if (allocated(e0387)) then
      call entry_real('ice_arrays_column.no_net', &
         real(e0387,real64),lbound(e0387))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.no_net U'
    endif
    if (allocated(e0388)) then
      call entry_real('ice_arrays_column.sice_rho', &
         real(e0388,real64),lbound(e0388))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.sice_rho U'
    endif
    if (allocated(e0389)) then
      call entry_real('ice_arrays_column.zfswin', &
         real(e0389,real64),lbound(e0389))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.zfswin U'
    endif
    if (allocated(e0390)) then
      call entry_real('ice_arrays_column.idi', &
         real(e0390,real64),lbound(e0390))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.idi U'
    endif
    if (allocated(e0391)) then
      call entry_real('ice_arrays_column.iki', &
         real(e0391,real64),lbound(e0391))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.iki U'
    endif
    if (allocated(e0392)) then
      call entry_real('ice_arrays_column.upno', &
         real(e0392,real64),lbound(e0392))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.upno U'
    endif
    if (allocated(e0393)) then
      call entry_real('ice_arrays_column.upnh', &
         real(e0393,real64),lbound(e0393))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.upnh U'
    endif
    if (allocated(e0394)) then
      call entry_real('ice_arrays_column.trcrn_sw', &
         real(e0394,real64),lbound(e0394))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.trcrn_sw U'
    endif
    if (allocated(e0395)) then
      call entry_real('ice_arrays_column.ice_bio_net', &
         real(e0395,real64),lbound(e0395))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.ice_bio_net U'
    endif
    if (allocated(e0396)) then
      call entry_real('ice_arrays_column.snow_bio_net', &
         real(e0396,real64),lbound(e0396))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.snow_bio_net U'
    endif
    call entry_logical('ice_arrays_column.oceanmixed_ice', &
         e0397)
    call entry_logical('ice_arrays_column.restore_bgc', &
         e0398)
    call entry_char('ice_arrays_column.fe_data_type', &
         e0399)
    call entry_char('ice_arrays_column.bgc_data_dir', &
         e0400)
    if (allocated(e0401)) then
      call entry_real('ice_arrays_column.r_chl2n', &
         real(e0401,real64),lbound(e0401))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.r_chl2n U'
    endif
    if (allocated(e0402)) then
      call entry_real('ice_arrays_column.r_c2n', &
         real(e0402,real64),lbound(e0402))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.r_c2n U'
    endif
    if (allocated(e0403)) then
      call entry_real('ice_arrays_column.floe_rad_l', &
         real(e0403,real64),lbound(e0403))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.floe_rad_l U'
    endif
    if (allocated(e0404)) then
      call entry_real('ice_arrays_column.floe_rad_c', &
         real(e0404,real64),lbound(e0404))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.floe_rad_c U'
    endif
    if (allocated(e0405)) then
      call entry_real('ice_arrays_column.floe_binwidth', &
         real(e0405,real64),lbound(e0405))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.floe_binwidth U'
    endif
    if (allocated(e0406)) then
      call entry_real('ice_arrays_column.wave_sig_ht', &
         real(e0406,real64),lbound(e0406))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.wave_sig_ht U'
    endif
    if (allocated(e0407)) then
      call entry_real('ice_arrays_column.wavefreq', &
         real(e0407,real64),lbound(e0407))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.wavefreq U'
    endif
    if (allocated(e0408)) then
      call entry_real('ice_arrays_column.dwavefreq', &
         real(e0408,real64),lbound(e0408))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.dwavefreq U'
    endif
    if (allocated(e0409)) then
      call entry_real('ice_arrays_column.wave_spectrum', &
         real(e0409,real64),lbound(e0409))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.wave_spectrum U'
    endif
    if (allocated(e0410)) then
      call entry_real('ice_arrays_column.d_afsd_newi', &
         real(e0410,real64),lbound(e0410))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.d_afsd_newi U'
    endif
    if (allocated(e0411)) then
      call entry_real('ice_arrays_column.d_afsd_latg', &
         real(e0411,real64),lbound(e0411))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.d_afsd_latg U'
    endif
    if (allocated(e0412)) then
      call entry_real('ice_arrays_column.d_afsd_latm', &
         real(e0412,real64),lbound(e0412))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.d_afsd_latm U'
    endif
    if (allocated(e0413)) then
      call entry_real('ice_arrays_column.d_afsd_wave', &
         real(e0413,real64),lbound(e0413))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.d_afsd_wave U'
    endif
    if (allocated(e0414)) then
      call entry_real('ice_arrays_column.d_afsd_weld', &
         real(e0414,real64),lbound(e0414))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.d_afsd_weld U'
    endif
    if (allocated(e0415)) then
      call entry_char('ice_arrays_column.c_fsd_range', &
         e0415,lbound(e0415))
    else
      write(meta_unit,'(A)') 'ice_arrays_column.c_fsd_range U'
    endif
    call entry_logical('ice_restoring.restore_ice', &
         e0416)
    if (allocated(e0417)) then
      call entry_real('ice_restoring.aicen_rest', &
         real(e0417,real64),lbound(e0417))
    else
      write(meta_unit,'(A)') 'ice_restoring.aicen_rest U'
    endif
    if (allocated(e0418)) then
      call entry_real('ice_restoring.vicen_rest', &
         real(e0418,real64),lbound(e0418))
    else
      write(meta_unit,'(A)') 'ice_restoring.vicen_rest U'
    endif
    if (allocated(e0419)) then
      call entry_real('ice_restoring.vsnon_rest', &
         real(e0419,real64),lbound(e0419))
    else
      write(meta_unit,'(A)') 'ice_restoring.vsnon_rest U'
    endif
    if (allocated(e0420)) then
      call entry_real('ice_restoring.trcrn_rest', &
         real(e0420,real64),lbound(e0420))
    else
      write(meta_unit,'(A)') 'ice_restoring.trcrn_rest U'
    endif
    call entry_int('ice_dyn_shared.kdyn', &
         int(e0421,int64))
    call entry_int('ice_dyn_shared.kridge', &
         int(e0422,int64))
    call entry_int('ice_dyn_shared.ndte', &
         int(e0423,int64))
    call entry_char('ice_dyn_shared.coriolis', &
         e0424)
    call entry_char('ice_dyn_shared.ssh_stress', &
         e0425)
    call entry_logical('ice_dyn_shared.revised_evp', &
         e0426)
    call entry_char('ice_dyn_shared.evp_algorithm', &
         e0427)
    call entry_real('ice_dyn_shared.dyn_area_min', &
         real(e0428,real64))
    call entry_real('ice_dyn_shared.dyn_mass_min', &
         real(e0429,real64))
    call entry_real('ice_dyn_shared.elasticdamp', &
         real(e0430,real64))
    call entry_char('ice_dyn_shared.yield_curve', &
         e0431)
    call entry_char('ice_dyn_shared.visc_method', &
         e0432)
    call entry_char('ice_dyn_shared.seabed_stress_method', &
         e0433)
    call entry_real('ice_dyn_shared.u0', &
         real(e0434,real64))
    call entry_real('ice_dyn_shared.cosw', &
         real(e0435,real64))
    call entry_real('ice_dyn_shared.sinw', &
         real(e0436,real64))
    call entry_real('ice_dyn_shared.revp', &
         real(e0437,real64))
    call entry_real('ice_dyn_shared.e_yieldcurve', &
         real(e0438,real64))
    call entry_real('ice_dyn_shared.e_plasticpot', &
         real(e0439,real64))
    call entry_real('ice_dyn_shared.epp2i', &
         real(e0440,real64))
    call entry_real('ice_dyn_shared.e_factor', &
         real(e0441,real64))
    call entry_real('ice_dyn_shared.ecci', &
         real(e0442,real64))
    call entry_real('ice_dyn_shared.deltaminevp', &
         real(e0443,real64))
    call entry_real('ice_dyn_shared.deltaminvp', &
         real(e0444,real64))
    call entry_real('ice_dyn_shared.capping', &
         real(e0445,real64))
    call entry_real('ice_dyn_shared.dtei', &
         real(e0446,real64))
    call entry_real('ice_dyn_shared.denom1', &
         real(e0447,real64))
    call entry_real('ice_dyn_shared.arlx', &
         real(e0448,real64))
    call entry_real('ice_dyn_shared.arlx1i', &
         real(e0449,real64))
    call entry_real('ice_dyn_shared.brlx', &
         real(e0450,real64))
    if (allocated(e0451)) then
      call entry_real('ice_dyn_shared.fcor_blk', &
         real(e0451,real64),lbound(e0451))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.fcor_blk U'
    endif
    if (allocated(e0452)) then
      call entry_real('ice_dyn_shared.fcore_blk', &
         real(e0452,real64),lbound(e0452))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.fcore_blk U'
    endif
    if (allocated(e0453)) then
      call entry_real('ice_dyn_shared.fcorn_blk', &
         real(e0453,real64),lbound(e0453))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.fcorn_blk U'
    endif
    if (allocated(e0454)) then
      call entry_real('ice_dyn_shared.fld2', &
         real(e0454,real64),lbound(e0454))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.fld2 U'
    endif
    if (allocated(e0455)) then
      call entry_real('ice_dyn_shared.fld3', &
         real(e0455,real64),lbound(e0455))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.fld3 U'
    endif
    if (allocated(e0456)) then
      call entry_real('ice_dyn_shared.fld4', &
         real(e0456,real64),lbound(e0456))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.fld4 U'
    endif
    if (allocated(e0457)) then
      call entry_real('ice_dyn_shared.uvel_init', &
         real(e0457,real64),lbound(e0457))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.uvel_init U'
    endif
    if (allocated(e0458)) then
      call entry_real('ice_dyn_shared.vvel_init', &
         real(e0458,real64),lbound(e0458))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.vvel_init U'
    endif
    if (allocated(e0459)) then
      call entry_real('ice_dyn_shared.uveln_init', &
         real(e0459,real64),lbound(e0459))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.uveln_init U'
    endif
    if (allocated(e0460)) then
      call entry_real('ice_dyn_shared.vveln_init', &
         real(e0460,real64),lbound(e0460))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.vveln_init U'
    endif
    if (allocated(e0461)) then
      call entry_real('ice_dyn_shared.uvele_init', &
         real(e0461,real64),lbound(e0461))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.uvele_init U'
    endif
    if (allocated(e0462)) then
      call entry_real('ice_dyn_shared.vvele_init', &
         real(e0462,real64),lbound(e0462))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.vvele_init U'
    endif
    if (allocated(e0463)) then
      call entry_logical('ice_dyn_shared.icetmask', &
         e0463,lbound(e0463))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.icetmask U'
    endif
    if (allocated(e0464)) then
      call entry_logical('ice_dyn_shared.iceumask', &
         e0464,lbound(e0464))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.iceumask U'
    endif
    if (allocated(e0465)) then
      call entry_logical('ice_dyn_shared.icenmask', &
         e0465,lbound(e0465))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.icenmask U'
    endif
    if (allocated(e0466)) then
      call entry_logical('ice_dyn_shared.iceemask', &
         e0466,lbound(e0466))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.iceemask U'
    endif
    if (allocated(e0467)) then
      call entry_real('ice_dyn_shared.dmintarea', &
         real(e0467,real64),lbound(e0467))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.dmintarea U'
    endif
    if (allocated(e0468)) then
      call entry_real('ice_dyn_shared.cyp', &
         real(e0468,real64),lbound(e0468))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.cyp U'
    endif
    if (allocated(e0469)) then
      call entry_real('ice_dyn_shared.cxp', &
         real(e0469,real64),lbound(e0469))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.cxp U'
    endif
    if (allocated(e0470)) then
      call entry_real('ice_dyn_shared.cym', &
         real(e0470,real64),lbound(e0470))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.cym U'
    endif
    if (allocated(e0471)) then
      call entry_real('ice_dyn_shared.cxm', &
         real(e0471,real64),lbound(e0471))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.cxm U'
    endif
    if (allocated(e0472)) then
      call entry_real('ice_dyn_shared.dxhy', &
         real(e0472,real64),lbound(e0472))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.dxhy U'
    endif
    if (allocated(e0473)) then
      call entry_real('ice_dyn_shared.dyhx', &
         real(e0473,real64),lbound(e0473))
    else
      write(meta_unit,'(A)') 'ice_dyn_shared.dyhx U'
    endif
    call entry_real('ice_dyn_shared.ktens', &
         real(e0474,real64))
    call entry_logical('ice_dyn_shared.seabed_stress', &
         e0475)
    call entry_real('ice_dyn_shared.k1', &
         real(e0476,real64))
    call entry_real('ice_dyn_shared.k2', &
         real(e0477,real64))
    call entry_real('ice_dyn_shared.alphab', &
         real(e0478,real64))
    call entry_real('ice_dyn_shared.threshold_hw', &
         real(e0479,real64))
    if (allocated(e0480)) then
      call entry_real('ice_dyn_evp.ratiodxn', &
         real(e0480,real64),lbound(e0480))
    else
      write(meta_unit,'(A)') 'ice_dyn_evp.ratiodxn U'
    endif
    if (allocated(e0481)) then
      call entry_real('ice_dyn_evp.ratiodye', &
         real(e0481,real64),lbound(e0481))
    else
      write(meta_unit,'(A)') 'ice_dyn_evp.ratiodye U'
    endif
    if (allocated(e0482)) then
      call entry_real('ice_dyn_evp.ratiodxnr', &
         real(e0482,real64),lbound(e0482))
    else
      write(meta_unit,'(A)') 'ice_dyn_evp.ratiodxnr U'
    endif
    if (allocated(e0483)) then
      call entry_real('ice_dyn_evp.ratiodyer', &
         real(e0483,real64),lbound(e0483))
    else
      write(meta_unit,'(A)') 'ice_dyn_evp.ratiodyer U'
    endif
    if (allocated(e0484)) then
      call entry_real('ice_dyn_eap.e11', &
         real(e0484,real64),lbound(e0484))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.e11 U'
    endif
    if (allocated(e0485)) then
      call entry_real('ice_dyn_eap.e12', &
         real(e0485,real64),lbound(e0485))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.e12 U'
    endif
    if (allocated(e0486)) then
      call entry_real('ice_dyn_eap.e22', &
         real(e0486,real64),lbound(e0486))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.e22 U'
    endif
    if (allocated(e0487)) then
      call entry_real('ice_dyn_eap.yieldstress11', &
         real(e0487,real64),lbound(e0487))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.yieldstress11 U'
    endif
    if (allocated(e0488)) then
      call entry_real('ice_dyn_eap.yieldstress12', &
         real(e0488,real64),lbound(e0488))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.yieldstress12 U'
    endif
    if (allocated(e0489)) then
      call entry_real('ice_dyn_eap.yieldstress22', &
         real(e0489,real64),lbound(e0489))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.yieldstress22 U'
    endif
    if (allocated(e0490)) then
      call entry_real('ice_dyn_eap.s11', &
         real(e0490,real64),lbound(e0490))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.s11 U'
    endif
    if (allocated(e0491)) then
      call entry_real('ice_dyn_eap.s12', &
         real(e0491,real64),lbound(e0491))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.s12 U'
    endif
    if (allocated(e0492)) then
      call entry_real('ice_dyn_eap.s22', &
         real(e0492,real64),lbound(e0492))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.s22 U'
    endif
    if (allocated(e0493)) then
      call entry_real('ice_dyn_eap.a11', &
         real(e0493,real64),lbound(e0493))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.a11 U'
    endif
    if (allocated(e0494)) then
      call entry_real('ice_dyn_eap.a12', &
         real(e0494,real64),lbound(e0494))
    else
      write(meta_unit,'(A)') 'ice_dyn_eap.a12 U'
    endif
    call entry_int('ice_dyn_vp.maxits_nonlin', &
         int(e0495,int64))
    call entry_int('ice_dyn_vp.dim_fgmres', &
         int(e0496,int64))
    call entry_int('ice_dyn_vp.dim_pgmres', &
         int(e0497,int64))
    call entry_int('ice_dyn_vp.maxits_fgmres', &
         int(e0498,int64))
    call entry_int('ice_dyn_vp.maxits_pgmres', &
         int(e0499,int64))
    call entry_int('ice_dyn_vp.fpfunc_andacc', &
         int(e0500,int64))
    call entry_int('ice_dyn_vp.dim_andacc', &
         int(e0501,int64))
    call entry_int('ice_dyn_vp.start_andacc', &
         int(e0502,int64))
    call entry_logical('ice_dyn_vp.monitor_nonlin', &
         e0503)
    call entry_logical('ice_dyn_vp.monitor_fgmres', &
         e0504)
    call entry_logical('ice_dyn_vp.monitor_pgmres', &
         e0505)
    call entry_logical('ice_dyn_vp.use_mean_vrel', &
         e0506)
    call entry_real('ice_dyn_vp.reltol_nonlin', &
         real(e0507,real64))
    call entry_real('ice_dyn_vp.reltol_fgmres', &
         real(e0508,real64))
    call entry_real('ice_dyn_vp.reltol_pgmres', &
         real(e0509,real64))
    call entry_real('ice_dyn_vp.damping_andacc', &
         real(e0510,real64))
    call entry_real('ice_dyn_vp.reltol_andacc', &
         real(e0511,real64))
    call entry_char('ice_dyn_vp.precond', &
         e0512)
    call entry_char('ice_dyn_vp.algo_nonlin', &
         e0513)
    call entry_char('ice_dyn_vp.ortho_type', &
         e0514)
    call entry_char('ice_transport_driver.advection', &
         e0515)
    if (allocated(e0516)) then
      call entry_int('ice_transport_driver.tracer_type', &
         int(e0516,int64),lbound(e0516))
    else
      write(meta_unit,'(A)') 'ice_transport_driver.tracer_type U'
    endif
    if (allocated(e0517)) then
      call entry_int('ice_transport_driver.depend', &
         int(e0517,int64),lbound(e0517))
    else
      write(meta_unit,'(A)') 'ice_transport_driver.depend U'
    endif
    if (allocated(e0518)) then
      call entry_logical('ice_transport_driver.has_dependents', &
         e0518,lbound(e0518))
    else
      write(meta_unit,'(A)') 'ice_transport_driver.has_dependents U'
    endif
    call entry_logical('ice_transport_driver.conserv_check', &
         e0519)
    call entry_char('ice_grid.grid_format', &
         e0520)
    call entry_char('ice_grid.gridcpl_file', &
         e0521)
    call entry_char('ice_grid.grid_file', &
         e0522)
    call entry_char('ice_grid.kmt_file', &
         e0523)
    call entry_char('ice_grid.kmt_type', &
         e0524)
    call entry_char('ice_grid.bathymetry_file', &
         e0525)
    call entry_char('ice_grid.bathymetry_format', &
         e0526)
    call entry_char('ice_grid.grid_spacing', &
         e0527)
    call entry_char('ice_grid.grid_ice', &
         e0528)
    call entry_char('ice_grid.grid_ice_thrm', &
         e0529)
    call entry_char('ice_grid.grid_ice_dynu', &
         e0530)
    call entry_char('ice_grid.grid_ice_dynv', &
         e0531)
    call entry_char('ice_grid.grid_atm', &
         e0532)
    call entry_char('ice_grid.grid_atm_thrm', &
         e0533)
    call entry_char('ice_grid.grid_atm_dynu', &
         e0534)
    call entry_char('ice_grid.grid_atm_dynv', &
         e0535)
    call entry_char('ice_grid.grid_ocn', &
         e0536)
    call entry_char('ice_grid.grid_ocn_thrm', &
         e0537)
    call entry_char('ice_grid.grid_ocn_dynu', &
         e0538)
    call entry_char('ice_grid.grid_ocn_dynv', &
         e0539)
    call entry_char('ice_grid.grid_type', &
         e0540)
    if (allocated(e0541)) then
      call entry_real('ice_grid.dxt', &
         real(e0541,real64),lbound(e0541))
    else
      write(meta_unit,'(A)') 'ice_grid.dxt U'
    endif
    if (allocated(e0542)) then
      call entry_real('ice_grid.dyt', &
         real(e0542,real64),lbound(e0542))
    else
      write(meta_unit,'(A)') 'ice_grid.dyt U'
    endif
    if (allocated(e0543)) then
      call entry_real('ice_grid.dxu', &
         real(e0543,real64),lbound(e0543))
    else
      write(meta_unit,'(A)') 'ice_grid.dxu U'
    endif
    if (allocated(e0544)) then
      call entry_real('ice_grid.dyu', &
         real(e0544,real64),lbound(e0544))
    else
      write(meta_unit,'(A)') 'ice_grid.dyu U'
    endif
    if (allocated(e0545)) then
      call entry_real('ice_grid.dxn', &
         real(e0545,real64),lbound(e0545))
    else
      write(meta_unit,'(A)') 'ice_grid.dxn U'
    endif
    if (allocated(e0546)) then
      call entry_real('ice_grid.dyn', &
         real(e0546,real64),lbound(e0546))
    else
      write(meta_unit,'(A)') 'ice_grid.dyn U'
    endif
    if (allocated(e0547)) then
      call entry_real('ice_grid.dxe', &
         real(e0547,real64),lbound(e0547))
    else
      write(meta_unit,'(A)') 'ice_grid.dxe U'
    endif
    if (allocated(e0548)) then
      call entry_real('ice_grid.dye', &
         real(e0548,real64),lbound(e0548))
    else
      write(meta_unit,'(A)') 'ice_grid.dye U'
    endif
    if (allocated(e0549)) then
      call entry_real('ice_grid.hte', &
         real(e0549,real64),lbound(e0549))
    else
      write(meta_unit,'(A)') 'ice_grid.hte U'
    endif
    if (allocated(e0550)) then
      call entry_real('ice_grid.htn', &
         real(e0550,real64),lbound(e0550))
    else
      write(meta_unit,'(A)') 'ice_grid.htn U'
    endif
    if (allocated(e0551)) then
      call entry_real('ice_grid.tarea', &
         real(e0551,real64),lbound(e0551))
    else
      write(meta_unit,'(A)') 'ice_grid.tarea U'
    endif
    if (allocated(e0552)) then
      call entry_real('ice_grid.uarea', &
         real(e0552,real64),lbound(e0552))
    else
      write(meta_unit,'(A)') 'ice_grid.uarea U'
    endif
    if (allocated(e0553)) then
      call entry_real('ice_grid.narea', &
         real(e0553,real64),lbound(e0553))
    else
      write(meta_unit,'(A)') 'ice_grid.narea U'
    endif
    if (allocated(e0554)) then
      call entry_real('ice_grid.earea', &
         real(e0554,real64),lbound(e0554))
    else
      write(meta_unit,'(A)') 'ice_grid.earea U'
    endif
    if (allocated(e0555)) then
      call entry_real('ice_grid.tarear', &
         real(e0555,real64),lbound(e0555))
    else
      write(meta_unit,'(A)') 'ice_grid.tarear U'
    endif
    if (allocated(e0556)) then
      call entry_real('ice_grid.uarear', &
         real(e0556,real64),lbound(e0556))
    else
      write(meta_unit,'(A)') 'ice_grid.uarear U'
    endif
    if (allocated(e0557)) then
      call entry_real('ice_grid.narear', &
         real(e0557,real64),lbound(e0557))
    else
      write(meta_unit,'(A)') 'ice_grid.narear U'
    endif
    if (allocated(e0558)) then
      call entry_real('ice_grid.earear', &
         real(e0558,real64),lbound(e0558))
    else
      write(meta_unit,'(A)') 'ice_grid.earear U'
    endif
    if (allocated(e0559)) then
      call entry_real('ice_grid.tarean', &
         real(e0559,real64),lbound(e0559))
    else
      write(meta_unit,'(A)') 'ice_grid.tarean U'
    endif
    if (allocated(e0560)) then
      call entry_real('ice_grid.tareas', &
         real(e0560,real64),lbound(e0560))
    else
      write(meta_unit,'(A)') 'ice_grid.tareas U'
    endif
    if (allocated(e0561)) then
      call entry_real('ice_grid.ulon', &
         real(e0561,real64),lbound(e0561))
    else
      write(meta_unit,'(A)') 'ice_grid.ulon U'
    endif
    if (allocated(e0562)) then
      call entry_real('ice_grid.ulat', &
         real(e0562,real64),lbound(e0562))
    else
      write(meta_unit,'(A)') 'ice_grid.ulat U'
    endif
    if (allocated(e0563)) then
      call entry_real('ice_grid.tlon', &
         real(e0563,real64),lbound(e0563))
    else
      write(meta_unit,'(A)') 'ice_grid.tlon U'
    endif
    if (allocated(e0564)) then
      call entry_real('ice_grid.tlat', &
         real(e0564,real64),lbound(e0564))
    else
      write(meta_unit,'(A)') 'ice_grid.tlat U'
    endif
    if (allocated(e0565)) then
      call entry_real('ice_grid.nlon', &
         real(e0565,real64),lbound(e0565))
    else
      write(meta_unit,'(A)') 'ice_grid.nlon U'
    endif
    if (allocated(e0566)) then
      call entry_real('ice_grid.nlat', &
         real(e0566,real64),lbound(e0566))
    else
      write(meta_unit,'(A)') 'ice_grid.nlat U'
    endif
    if (allocated(e0567)) then
      call entry_real('ice_grid.elon', &
         real(e0567,real64),lbound(e0567))
    else
      write(meta_unit,'(A)') 'ice_grid.elon U'
    endif
    if (allocated(e0568)) then
      call entry_real('ice_grid.elat', &
         real(e0568,real64),lbound(e0568))
    else
      write(meta_unit,'(A)') 'ice_grid.elat U'
    endif
    if (allocated(e0569)) then
      call entry_real('ice_grid.angle', &
         real(e0569,real64),lbound(e0569))
    else
      write(meta_unit,'(A)') 'ice_grid.angle U'
    endif
    if (allocated(e0570)) then
      call entry_real('ice_grid.anglet', &
         real(e0570,real64),lbound(e0570))
    else
      write(meta_unit,'(A)') 'ice_grid.anglet U'
    endif
    if (allocated(e0571)) then
      call entry_real('ice_grid.bathymetry', &
         real(e0571,real64),lbound(e0571))
    else
      write(meta_unit,'(A)') 'ice_grid.bathymetry U'
    endif
    if (allocated(e0572)) then
      call entry_real('ice_grid.ocn_gridcell_frac', &
         real(e0572,real64),lbound(e0572))
    else
      write(meta_unit,'(A)') 'ice_grid.ocn_gridcell_frac U'
    endif
    if (allocated(e0573)) then
      call entry_real('ice_grid.g_hte', &
         real(e0573,real64),lbound(e0573))
    else
      write(meta_unit,'(A)') 'ice_grid.g_hte U'
    endif
    if (allocated(e0574)) then
      call entry_real('ice_grid.g_htn', &
         real(e0574,real64),lbound(e0574))
    else
      write(meta_unit,'(A)') 'ice_grid.g_htn U'
    endif
    call entry_real('ice_grid.dxrect', &
         real(e0575,real64))
    call entry_real('ice_grid.dyrect', &
         real(e0576,real64))
    call entry_real('ice_grid.dxscale', &
         real(e0577,real64))
    call entry_real('ice_grid.dyscale', &
         real(e0578,real64))
    call entry_real('ice_grid.lonrefrect', &
         real(e0579,real64))
    call entry_real('ice_grid.latrefrect', &
         real(e0580,real64))
    if (allocated(e0581)) then
      call entry_real('ice_grid.lont_bounds', &
         real(e0581,real64),lbound(e0581))
    else
      write(meta_unit,'(A)') 'ice_grid.lont_bounds U'
    endif
    if (allocated(e0582)) then
      call entry_real('ice_grid.latt_bounds', &
         real(e0582,real64),lbound(e0582))
    else
      write(meta_unit,'(A)') 'ice_grid.latt_bounds U'
    endif
    if (allocated(e0583)) then
      call entry_real('ice_grid.lonu_bounds', &
         real(e0583,real64),lbound(e0583))
    else
      write(meta_unit,'(A)') 'ice_grid.lonu_bounds U'
    endif
    if (allocated(e0584)) then
      call entry_real('ice_grid.latu_bounds', &
         real(e0584,real64),lbound(e0584))
    else
      write(meta_unit,'(A)') 'ice_grid.latu_bounds U'
    endif
    if (allocated(e0585)) then
      call entry_real('ice_grid.lonn_bounds', &
         real(e0585,real64),lbound(e0585))
    else
      write(meta_unit,'(A)') 'ice_grid.lonn_bounds U'
    endif
    if (allocated(e0586)) then
      call entry_real('ice_grid.latn_bounds', &
         real(e0586,real64),lbound(e0586))
    else
      write(meta_unit,'(A)') 'ice_grid.latn_bounds U'
    endif
    if (allocated(e0587)) then
      call entry_real('ice_grid.lone_bounds', &
         real(e0587,real64),lbound(e0587))
    else
      write(meta_unit,'(A)') 'ice_grid.lone_bounds U'
    endif
    if (allocated(e0588)) then
      call entry_real('ice_grid.late_bounds', &
         real(e0588,real64),lbound(e0588))
    else
      write(meta_unit,'(A)') 'ice_grid.late_bounds U'
    endif
    if (allocated(e0589)) then
      call entry_real('ice_grid.hm', &
         real(e0589,real64),lbound(e0589))
    else
      write(meta_unit,'(A)') 'ice_grid.hm U'
    endif
    if (allocated(e0590)) then
      call entry_real('ice_grid.bm', &
         real(e0590,real64),lbound(e0590))
    else
      write(meta_unit,'(A)') 'ice_grid.bm U'
    endif
    if (allocated(e0591)) then
      call entry_real('ice_grid.uvm', &
         real(e0591,real64),lbound(e0591))
    else
      write(meta_unit,'(A)') 'ice_grid.uvm U'
    endif
    if (allocated(e0592)) then
      call entry_real('ice_grid.npm', &
         real(e0592,real64),lbound(e0592))
    else
      write(meta_unit,'(A)') 'ice_grid.npm U'
    endif
    if (allocated(e0593)) then
      call entry_real('ice_grid.epm', &
         real(e0593,real64),lbound(e0593))
    else
      write(meta_unit,'(A)') 'ice_grid.epm U'
    endif
    if (allocated(e0594)) then
      call entry_real('ice_grid.kmt', &
         real(e0594,real64),lbound(e0594))
    else
      write(meta_unit,'(A)') 'ice_grid.kmt U'
    endif
    call entry_logical('ice_grid.grid_outfile', &
         e0595)
    call entry_logical('ice_grid.use_bathymetry', &
         e0596)
    call entry_logical('ice_grid.save_ghte_ghtn', &
         e0597)
    call entry_logical('ice_grid.scale_dxdy', &
         e0598)
    if (allocated(e0599)) then
      call entry_logical('ice_grid.tmask', &
         e0599,lbound(e0599))
    else
      write(meta_unit,'(A)') 'ice_grid.tmask U'
    endif
    if (allocated(e0600)) then
      call entry_logical('ice_grid.umask', &
         e0600,lbound(e0600))
    else
      write(meta_unit,'(A)') 'ice_grid.umask U'
    endif
    if (allocated(e0601)) then
      call entry_logical('ice_grid.umaskcd', &
         e0601,lbound(e0601))
    else
      write(meta_unit,'(A)') 'ice_grid.umaskcd U'
    endif
    if (allocated(e0602)) then
      call entry_logical('ice_grid.nmask', &
         e0602,lbound(e0602))
    else
      write(meta_unit,'(A)') 'ice_grid.nmask U'
    endif
    if (allocated(e0603)) then
      call entry_logical('ice_grid.emask', &
         e0603,lbound(e0603))
    else
      write(meta_unit,'(A)') 'ice_grid.emask U'
    endif
    if (allocated(e0604)) then
      call entry_logical('ice_grid.opmask', &
         e0604,lbound(e0604))
    else
      write(meta_unit,'(A)') 'ice_grid.opmask U'
    endif
    if (allocated(e0605)) then
      call entry_logical('ice_grid.lmask_n', &
         e0605,lbound(e0605))
    else
      write(meta_unit,'(A)') 'ice_grid.lmask_n U'
    endif
    if (allocated(e0606)) then
      call entry_logical('ice_grid.lmask_s', &
         e0606,lbound(e0606))
    else
      write(meta_unit,'(A)') 'ice_grid.lmask_s U'
    endif
    if (allocated(e0607)) then
      call entry_real('ice_grid.rndex_global', &
         real(e0607,real64),lbound(e0607))
    else
      write(meta_unit,'(A)') 'ice_grid.rndex_global U'
    endif
    call entry_char('icepack_parameters.argcheck', &
         e0608)
    call entry_real('icepack_parameters.c0', &
         real(e0609,real64))
    call entry_real('icepack_parameters.c1', &
         real(e0610,real64))
    call entry_real('icepack_parameters.c1p5', &
         real(e0611,real64))
    call entry_real('icepack_parameters.c2', &
         real(e0612,real64))
    call entry_real('icepack_parameters.c3', &
         real(e0613,real64))
    call entry_real('icepack_parameters.c4', &
         real(e0614,real64))
    call entry_real('icepack_parameters.c5', &
         real(e0615,real64))
    call entry_real('icepack_parameters.c6', &
         real(e0616,real64))
    call entry_real('icepack_parameters.c8', &
         real(e0617,real64))
    call entry_real('icepack_parameters.c10', &
         real(e0618,real64))
    call entry_real('icepack_parameters.c15', &
         real(e0619,real64))
    call entry_real('icepack_parameters.c16', &
         real(e0620,real64))
    call entry_real('icepack_parameters.c20', &
         real(e0621,real64))
    call entry_real('icepack_parameters.c25', &
         real(e0622,real64))
    call entry_real('icepack_parameters.c100', &
         real(e0623,real64))
    call entry_real('icepack_parameters.c180', &
         real(e0624,real64))
    call entry_real('icepack_parameters.c1000', &
         real(e0625,real64))
    call entry_real('icepack_parameters.p001', &
         real(e0626,real64))
    call entry_real('icepack_parameters.p01', &
         real(e0627,real64))
    call entry_real('icepack_parameters.p1', &
         real(e0628,real64))
    call entry_real('icepack_parameters.p2', &
         real(e0629,real64))
    call entry_real('icepack_parameters.p4', &
         real(e0630,real64))
    call entry_real('icepack_parameters.p5', &
         real(e0631,real64))
    call entry_real('icepack_parameters.p6', &
         real(e0632,real64))
    call entry_real('icepack_parameters.p05', &
         real(e0633,real64))
    call entry_real('icepack_parameters.p15', &
         real(e0634,real64))
    call entry_real('icepack_parameters.p25', &
         real(e0635,real64))
    call entry_real('icepack_parameters.p75', &
         real(e0636,real64))
    call entry_real('icepack_parameters.p333', &
         real(e0637,real64))
    call entry_real('icepack_parameters.p666', &
         real(e0638,real64))
    call entry_real('icepack_parameters.spval_const', &
         real(e0639,real64))
    call entry_real('icepack_parameters.secday', &
         real(e0640,real64))
    call entry_real('icepack_parameters.puny', &
         real(e0641,real64))
    call entry_real('icepack_parameters.bignum', &
         real(e0642,real64))
    call entry_real('icepack_parameters.pi', &
         real(e0643,real64))
    call entry_real('icepack_parameters.pih', &
         real(e0644,real64))
    call entry_real('icepack_parameters.piq', &
         real(e0645,real64))
    call entry_real('icepack_parameters.pi2', &
         real(e0646,real64))
    call entry_real('icepack_parameters.rad_to_deg', &
         real(e0647,real64))
    call entry_real('icepack_parameters.lfresh', &
         real(e0648,real64))
    call entry_real('icepack_parameters.cprho', &
         real(e0649,real64))
    call entry_real('icepack_parameters.cp', &
         real(e0650,real64))
    call entry_real('icepack_parameters.rhos', &
         real(e0651,real64))
    call entry_real('icepack_parameters.rhoi', &
         real(e0652,real64))
    call entry_real('icepack_parameters.rhosi', &
         real(e0653,real64))
    call entry_real('icepack_parameters.rhow', &
         real(e0654,real64))
    call entry_real('icepack_parameters.rhofresh', &
         real(e0655,real64))
    call entry_real('icepack_parameters.hfrazilmin', &
         real(e0656,real64))
    call entry_real('icepack_parameters.cp_ice', &
         real(e0657,real64))
    call entry_real('icepack_parameters.cp_ocn', &
         real(e0658,real64))
    call entry_real('icepack_parameters.depresst', &
         real(e0659,real64))
    call entry_real('icepack_parameters.viscosity_dyn', &
         real(e0660,real64))
    call entry_real('icepack_parameters.tscale_pnd_drain', &
         real(e0661,real64))
    call entry_real('icepack_parameters.tocnfrz', &
         real(e0662,real64))
    call entry_real('icepack_parameters.tffresh', &
         real(e0663,real64))
    call entry_real('icepack_parameters.lsub', &
         real(e0664,real64))
    call entry_real('icepack_parameters.lvap', &
         real(e0665,real64))
    call entry_real('icepack_parameters.timelt', &
         real(e0666,real64))
    call entry_real('icepack_parameters.tsmelt', &
         real(e0667,real64))
    call entry_real('icepack_parameters.ice_ref_salinity', &
         real(e0668,real64))
    call entry_real('icepack_parameters.kice', &
         real(e0669,real64))
    call entry_real('icepack_parameters.ksno', &
         real(e0670,real64))
    call entry_real('icepack_parameters.hs_min', &
         real(e0671,real64))
    call entry_real('icepack_parameters.snowpatch', &
         real(e0672,real64))
    call entry_real('icepack_parameters.saltmax', &
         real(e0673,real64))
    call entry_real('icepack_parameters.phi_init', &
         real(e0674,real64))
    call entry_real('icepack_parameters.min_salin', &
         real(e0675,real64))
    call entry_real('icepack_parameters.tliquidus_max', &
         real(e0676,real64))
    call entry_real('icepack_parameters.dsin0_frazil', &
         real(e0677,real64))
    call entry_real('icepack_parameters.ustar_min', &
         real(e0678,real64))
    call entry_real('icepack_parameters.hi_min', &
         real(e0679,real64))
    call entry_real('icepack_parameters.a_rapid_mode', &
         real(e0680,real64))
    call entry_real('icepack_parameters.rac_rapid_mode', &
         real(e0681,real64))
    call entry_real('icepack_parameters.aspect_rapid_mode', &
         real(e0682,real64))
    call entry_real('icepack_parameters.dsdt_slow_mode', &
         real(e0683,real64))
    call entry_real('icepack_parameters.phi_c_slow_mode', &
         real(e0684,real64))
    call entry_real('icepack_parameters.phi_i_mushy', &
         real(e0685,real64))
    call entry_int('icepack_parameters.ktherm', &
         int(e0686,int64))
    call entry_char('icepack_parameters.conduct', &
         e0687)
    call entry_char('icepack_parameters.fbot_xfer_type', &
         e0688)
    call entry_char('icepack_parameters.cpl_frazil', &
         e0689)
    call entry_logical('icepack_parameters.calc_tsfc', &
         e0690)
    call entry_logical('icepack_parameters.semi_implicit_tsfc', &
         e0691)
    call entry_logical('icepack_parameters.vapor_flux_correction', &
         e0692)
    call entry_logical('icepack_parameters.update_ocn_f', &
         e0693)
    call entry_logical('icepack_parameters.modal_aero', &
         e0694)
    call entry_logical('icepack_parameters.conserv_check', &
         e0695)
    call entry_char('icepack_parameters.congel_freeze', &
         e0696)
    call entry_char('icepack_parameters.tfrz_option', &
         e0697)
    call entry_char('icepack_parameters.saltflux_option', &
         e0698)
    call entry_real('icepack_parameters.emissivity', &
         real(e0699,real64))
    call entry_real('icepack_parameters.albocn', &
         real(e0700,real64))
    call entry_real('icepack_parameters.vonkar', &
         real(e0701,real64))
    call entry_real('icepack_parameters.stefan_boltzmann', &
         real(e0702,real64))
    call entry_real('icepack_parameters.kappav', &
         real(e0703,real64))
    call entry_real('icepack_parameters.hi_ssl', &
         real(e0704,real64))
    call entry_real('icepack_parameters.hs_ssl', &
         real(e0705,real64))
    call entry_real('icepack_parameters.hs_ssl_min', &
         real(e0706,real64))
    call entry_real('icepack_parameters.albicev', &
         real(e0707,real64))
    call entry_real('icepack_parameters.albicei', &
         real(e0708,real64))
    call entry_real('icepack_parameters.albsnowv', &
         real(e0709,real64))
    call entry_real('icepack_parameters.albsnowi', &
         real(e0710,real64))
    call entry_real('icepack_parameters.ahmax', &
         real(e0711,real64))
    call entry_real('icepack_parameters.r_ice', &
         real(e0712,real64))
    call entry_real('icepack_parameters.r_pnd', &
         real(e0713,real64))
    call entry_real('icepack_parameters.r_snw', &
         real(e0714,real64))
    call entry_real('icepack_parameters.dt_mlt', &
         real(e0715,real64))
    call entry_real('icepack_parameters.rsnw_mlt', &
         real(e0716,real64))
    call entry_real('icepack_parameters.kalg', &
         real(e0717,real64))
    call entry_real('icepack_parameters.r_gc2molc', &
         real(e0718,real64))
    call entry_real('icepack_parameters.awtvdr', &
         real(e0719,real64))
    call entry_real('icepack_parameters.awtidr', &
         real(e0720,real64))
    call entry_real('icepack_parameters.awtvdf', &
         real(e0721,real64))
    call entry_real('icepack_parameters.awtidf', &
         real(e0722,real64))
    call entry_char('icepack_parameters.shortwave', &
         e0723)
    call entry_char('icepack_parameters.albedo_type', &
         e0724)
    call entry_logical('icepack_parameters.sw_redist', &
         e0725)
    call entry_real('icepack_parameters.sw_frac', &
         real(e0726,real64))
    call entry_real('icepack_parameters.sw_dtemp', &
         real(e0727,real64))
    call entry_char('icepack_parameters.snw_ssp_table', &
         e0728)
    call entry_real('icepack_parameters.hpmin', &
         real(e0729,real64))
    call entry_real('icepack_parameters.hp0', &
         real(e0730,real64))
    call entry_int('icepack_parameters.kstrength', &
         int(e0731,int64))
    call entry_int('icepack_parameters.krdg_partic', &
         int(e0732,int64))
    call entry_int('icepack_parameters.krdg_redist', &
         int(e0733,int64))
    call entry_real('icepack_parameters.itd_area_min', &
         real(e0734,real64))
    call entry_real('icepack_parameters.itd_mass_min', &
         real(e0735,real64))
    call entry_real('icepack_parameters.cf', &
         real(e0736,real64))
    call entry_real('icepack_parameters.pstar', &
         real(e0737,real64))
    call entry_real('icepack_parameters.cstar', &
         real(e0738,real64))
    call entry_real('icepack_parameters.dragio', &
         real(e0739,real64))
    call entry_real('icepack_parameters.thickness_ocn_layer1', &
         real(e0740,real64))
    call entry_real('icepack_parameters.iceruf_ocn', &
         real(e0741,real64))
    call entry_real('icepack_parameters.gravit', &
         real(e0742,real64))
    call entry_real('icepack_parameters.mu_rdg', &
         real(e0743,real64))
    call entry_logical('icepack_parameters.calc_dragio', &
         e0744)
    call entry_real('icepack_parameters.cp_air', &
         real(e0745,real64))
    call entry_real('icepack_parameters.cp_wv', &
         real(e0746,real64))
    call entry_real('icepack_parameters.zvir', &
         real(e0747,real64))
    call entry_real('icepack_parameters.zref', &
         real(e0748,real64))
    call entry_real('icepack_parameters.iceruf', &
         real(e0749,real64))
    call entry_real('icepack_parameters.qqqice', &
         real(e0750,real64))
    call entry_real('icepack_parameters.tttice', &
         real(e0751,real64))
    call entry_real('icepack_parameters.qqqocn', &
         real(e0752,real64))
    call entry_real('icepack_parameters.tttocn', &
         real(e0753,real64))
    call entry_real('icepack_parameters.senscoef', &
         real(e0754,real64))
    call entry_real('icepack_parameters.latncoef', &
         real(e0755,real64))
    call entry_char('icepack_parameters.atmbndy', &
         e0756)
    call entry_logical('icepack_parameters.calc_strair', &
         e0757)
    call entry_logical('icepack_parameters.formdrag', &
         e0758)
    call entry_logical('icepack_parameters.highfreq', &
         e0759)
    call entry_int('icepack_parameters.natmiter', &
         int(e0760,int64))
    call entry_real('icepack_parameters.atmiter_conv', &
         real(e0761,real64))
    call entry_int('icepack_parameters.kitd', &
         int(e0762,int64))
    call entry_int('icepack_parameters.kcatbound', &
         int(e0763,int64))
    call entry_int('icepack_parameters.nfreq', &
         int(e0764,int64))
    call entry_real('icepack_parameters.floeshape', &
         real(e0765,real64))
    call entry_real('icepack_parameters.floediam', &
         real(e0766,real64))
    call entry_logical('icepack_parameters.wave_spec', &
         e0767)
    call entry_char('icepack_parameters.wave_spec_type', &
         e0768)
    call entry_char('icepack_parameters.wave_height_type', &
         e0769)
    call entry_real('icepack_parameters.hs0', &
         real(e0770,real64))
    call entry_real('icepack_parameters.hs1', &
         real(e0771,real64))
    call entry_real('icepack_parameters.dpscale', &
         real(e0772,real64))
    call entry_real('icepack_parameters.rfracmin', &
         real(e0773,real64))
    call entry_real('icepack_parameters.rfracmax', &
         real(e0774,real64))
    call entry_real('icepack_parameters.pndaspect', &
         real(e0775,real64))
    call entry_char('icepack_parameters.frzpnd', &
         e0776)
    call entry_real('icepack_parameters.apnd_sl', &
         real(e0777,real64))
    call entry_char('icepack_parameters.pndhyps', &
         e0778)
    call entry_char('icepack_parameters.pndfrbd', &
         e0779)
    call entry_char('icepack_parameters.pndhead', &
         e0780)
    call entry_char('icepack_parameters.pndmacr', &
         e0781)
    call entry_real('icepack_parameters.hp1', &
         real(e0782,real64))
    call entry_char('icepack_parameters.snwredist', &
         e0783)
    call entry_char('icepack_parameters.snw_aging_table', &
         e0784)
    call entry_logical('icepack_parameters.use_smliq_pnd', &
         e0785)
    call entry_logical('icepack_parameters.snwgrain', &
         e0786)
    call entry_real('icepack_parameters.rsnw_fall', &
         real(e0787,real64))
    call entry_real('icepack_parameters.rsnw_tmax', &
         real(e0788,real64))
    call entry_real('icepack_parameters.rhosnew', &
         real(e0789,real64))
    call entry_real('icepack_parameters.rhosmin', &
         real(e0790,real64))
    call entry_real('icepack_parameters.rhosmax', &
         real(e0791,real64))
    call entry_real('icepack_parameters.windmin', &
         real(e0792,real64))
    call entry_real('icepack_parameters.drhosdwind', &
         real(e0793,real64))
    call entry_real('icepack_parameters.snwlvlfac', &
         real(e0794,real64))
    call entry_real('icepack_parameters.snw_growth_wet', &
         real(e0795,real64))
    call entry_real('icepack_parameters.drsnw_min', &
         real(e0796,real64))
    call entry_real('icepack_parameters.snwliq_max', &
         real(e0797,real64))
    call entry_int('icepack_parameters.isnw_t', &
         int(e0798,int64))
    call entry_int('icepack_parameters.isnw_tgrd', &
         int(e0799,int64))
    call entry_int('icepack_parameters.isnw_rhos', &
         int(e0800,int64))
    if (allocated(e0801)) then
      call entry_real('icepack_parameters.snowage_rhos', &
         real(e0801,real64),lbound(e0801))
    else
      write(meta_unit,'(A)') 'icepack_parameters.snowage_rhos U'
    endif
    if (allocated(e0802)) then
      call entry_real('icepack_parameters.snowage_tgrd', &
         real(e0802,real64),lbound(e0802))
    else
      write(meta_unit,'(A)') 'icepack_parameters.snowage_tgrd U'
    endif
    if (allocated(e0803)) then
      call entry_real('icepack_parameters.snowage_t', &
         real(e0803,real64),lbound(e0803))
    else
      write(meta_unit,'(A)') 'icepack_parameters.snowage_t U'
    endif
    if (allocated(e0804)) then
      call entry_real('icepack_parameters.snowage_tau', &
         real(e0804,real64),lbound(e0804))
    else
      write(meta_unit,'(A)') 'icepack_parameters.snowage_tau U'
    endif
    if (allocated(e0805)) then
      call entry_real('icepack_parameters.snowage_kappa', &
         real(e0805,real64),lbound(e0805))
    else
      write(meta_unit,'(A)') 'icepack_parameters.snowage_kappa U'
    endif
    if (allocated(e0806)) then
      call entry_real('icepack_parameters.snowage_drdt0', &
         real(e0806,real64),lbound(e0806))
    else
      write(meta_unit,'(A)') 'icepack_parameters.snowage_drdt0 U'
    endif
    call entry_char('icepack_parameters.bgc_flux_type', &
         e0807)
    call entry_logical('icepack_parameters.z_tracers', &
         e0808)
    call entry_logical('icepack_parameters.scale_bgc', &
         e0809)
    call entry_logical('icepack_parameters.solve_zbgc', &
         e0810)
    call entry_logical('icepack_parameters.dedd_algae', &
         e0811)
    call entry_logical('icepack_parameters.skl_bgc', &
         e0812)
    call entry_logical('icepack_parameters.use_macromolecules', &
         e0813)
    call entry_logical('icepack_parameters.use_atm_dust_iron', &
         e0814)
    call entry_logical('icepack_parameters.restartbgc', &
         e0815)
    call entry_real('icepack_parameters.phi_snow', &
         real(e0816,real64))
    call entry_real('icepack_parameters.grid_o', &
         real(e0817,real64))
    call entry_real('icepack_parameters.initbio_frac', &
         real(e0818,real64))
    call entry_real('icepack_parameters.l_sk', &
         real(e0819,real64))
    call entry_real('icepack_parameters.algal_vel', &
         real(e0820,real64))
    call entry_real('icepack_parameters.r_dfe2dust', &
         real(e0821,real64))
    call entry_real('icepack_parameters.dustfe_sol', &
         real(e0822,real64))
    call entry_real('icepack_parameters.frazil_scav', &
         real(e0823,real64))
    call entry_real('icepack_parameters.sk_l', &
         real(e0824,real64))
    call entry_real('icepack_parameters.min_bgc', &
         real(e0825,real64))
    call entry_real('icepack_parameters.t_max', &
         real(e0826,real64))
    call entry_real('icepack_parameters.fsal', &
         real(e0827,real64))
    call entry_real('icepack_parameters.op_dep_min', &
         real(e0828,real64))
    call entry_real('icepack_parameters.fr_graze_s', &
         real(e0829,real64))
    call entry_real('icepack_parameters.fr_graze_e', &
         real(e0830,real64))
    call entry_real('icepack_parameters.fr_mort2min', &
         real(e0831,real64))
    call entry_real('icepack_parameters.fr_dfe', &
         real(e0832,real64))
    call entry_real('icepack_parameters.k_nitrif', &
         real(e0833,real64))
    call entry_real('icepack_parameters.t_iron_conv', &
         real(e0834,real64))
    call entry_real('icepack_parameters.max_loss', &
         real(e0835,real64))
    call entry_real('icepack_parameters.max_dfe_doc1', &
         real(e0836,real64))
    call entry_real('icepack_parameters.fr_resp', &
         real(e0837,real64))
    call entry_real('icepack_parameters.fr_resp_s', &
         real(e0838,real64))
    call entry_real('icepack_parameters.y_sk_dms', &
         real(e0839,real64))
    call entry_real('icepack_parameters.t_sk_conv', &
         real(e0840,real64))
    call entry_real('icepack_parameters.t_sk_ox', &
         real(e0841,real64))
    call entry_real('icepack_parameters.grid_o_t', &
         real(e0842,real64))
    call entry_real('icepack_parameters.ratio_si2n_diatoms', &
         real(e0843,real64))
    call entry_real('icepack_parameters.ratio_si2n_sp', &
         real(e0844,real64))
    call entry_real('icepack_parameters.ratio_si2n_phaeo', &
         real(e0845,real64))
    call entry_real('icepack_parameters.ratio_s2n_diatoms', &
         real(e0846,real64))
    call entry_real('icepack_parameters.ratio_s2n_sp', &
         real(e0847,real64))
    call entry_real('icepack_parameters.ratio_s2n_phaeo', &
         real(e0848,real64))
    call entry_real('icepack_parameters.ratio_fe2c_diatoms', &
         real(e0849,real64))
    call entry_real('icepack_parameters.ratio_fe2c_sp', &
         real(e0850,real64))
    call entry_real('icepack_parameters.ratio_fe2c_phaeo', &
         real(e0851,real64))
    call entry_real('icepack_parameters.ratio_fe2n_diatoms', &
         real(e0852,real64))
    call entry_real('icepack_parameters.ratio_fe2n_sp', &
         real(e0853,real64))
    call entry_real('icepack_parameters.ratio_fe2n_phaeo', &
         real(e0854,real64))
    call entry_real('icepack_parameters.ratio_fe2don', &
         real(e0855,real64))
    call entry_real('icepack_parameters.ratio_fe2doc_s', &
         real(e0856,real64))
    call entry_real('icepack_parameters.ratio_fe2doc_l', &
         real(e0857,real64))
    call entry_real('icepack_parameters.tau_min', &
         real(e0858,real64))
    call entry_real('icepack_parameters.tau_max', &
         real(e0859,real64))
    call entry_real('icepack_parameters.chlabs_diatoms', &
         real(e0860,real64))
    call entry_real('icepack_parameters.chlabs_sp', &
         real(e0861,real64))
    call entry_real('icepack_parameters.chlabs_phaeo', &
         real(e0862,real64))
    call entry_real('icepack_parameters.alpha2max_low_diatoms', &
         real(e0863,real64))
    call entry_real('icepack_parameters.alpha2max_low_sp', &
         real(e0864,real64))
    call entry_real('icepack_parameters.alpha2max_low_phaeo', &
         real(e0865,real64))
    call entry_real('icepack_parameters.beta2max_diatoms', &
         real(e0866,real64))
    call entry_real('icepack_parameters.beta2max_sp', &
         real(e0867,real64))
    call entry_real('icepack_parameters.beta2max_phaeo', &
         real(e0868,real64))
    call entry_real('icepack_parameters.mu_max_diatoms', &
         real(e0869,real64))
    call entry_real('icepack_parameters.mu_max_sp', &
         real(e0870,real64))
    call entry_real('icepack_parameters.mu_max_phaeo', &
         real(e0871,real64))
    call entry_real('icepack_parameters.grow_tdep_diatoms', &
         real(e0872,real64))
    call entry_real('icepack_parameters.grow_tdep_sp', &
         real(e0873,real64))
    call entry_real('icepack_parameters.grow_tdep_phaeo', &
         real(e0874,real64))
    call entry_real('icepack_parameters.fr_graze_diatoms', &
         real(e0875,real64))
    call entry_real('icepack_parameters.fr_graze_sp', &
         real(e0876,real64))
    call entry_real('icepack_parameters.fr_graze_phaeo', &
         real(e0877,real64))
    call entry_real('icepack_parameters.mort_pre_diatoms', &
         real(e0878,real64))
    call entry_real('icepack_parameters.mort_pre_sp', &
         real(e0879,real64))
    call entry_real('icepack_parameters.mort_pre_phaeo', &
         real(e0880,real64))
    call entry_real('icepack_parameters.mort_tdep_diatoms', &
         real(e0881,real64))
    call entry_real('icepack_parameters.mort_tdep_sp', &
         real(e0882,real64))
    call entry_real('icepack_parameters.mort_tdep_phaeo', &
         real(e0883,real64))
    call entry_real('icepack_parameters.k_exude_diatoms', &
         real(e0884,real64))
    call entry_real('icepack_parameters.k_exude_sp', &
         real(e0885,real64))
    call entry_real('icepack_parameters.k_exude_phaeo', &
         real(e0886,real64))
    call entry_real('icepack_parameters.k_nit_diatoms', &
         real(e0887,real64))
    call entry_real('icepack_parameters.k_nit_sp', &
         real(e0888,real64))
    call entry_real('icepack_parameters.k_nit_phaeo', &
         real(e0889,real64))
    call entry_real('icepack_parameters.k_am_diatoms', &
         real(e0890,real64))
    call entry_real('icepack_parameters.k_am_sp', &
         real(e0891,real64))
    call entry_real('icepack_parameters.k_am_phaeo', &
         real(e0892,real64))
    call entry_real('icepack_parameters.k_sil_diatoms', &
         real(e0893,real64))
    call entry_real('icepack_parameters.k_sil_sp', &
         real(e0894,real64))
    call entry_real('icepack_parameters.k_sil_phaeo', &
         real(e0895,real64))
    call entry_real('icepack_parameters.k_fe_diatoms', &
         real(e0896,real64))
    call entry_real('icepack_parameters.k_fe_sp', &
         real(e0897,real64))
    call entry_real('icepack_parameters.k_fe_phaeo', &
         real(e0898,real64))
    call entry_real('icepack_parameters.f_don_protein', &
         real(e0899,real64))
    call entry_real('icepack_parameters.kn_bac_protein', &
         real(e0900,real64))
    call entry_real('icepack_parameters.f_don_am_protein', &
         real(e0901,real64))
    call entry_real('icepack_parameters.f_doc_s', &
         real(e0902,real64))
    call entry_real('icepack_parameters.f_doc_l', &
         real(e0903,real64))
    call entry_real('icepack_parameters.f_exude_s', &
         real(e0904,real64))
    call entry_real('icepack_parameters.f_exude_l', &
         real(e0905,real64))
    call entry_real('icepack_parameters.k_bac_s', &
         real(e0906,real64))
    call entry_real('icepack_parameters.k_bac_l', &
         real(e0907,real64))
    call entry_real('icepack_parameters.algaltype_diatoms', &
         real(e0908,real64))
    call entry_real('icepack_parameters.algaltype_sp', &
         real(e0909,real64))
    call entry_real('icepack_parameters.algaltype_phaeo', &
         real(e0910,real64))
    call entry_real('icepack_parameters.nitratetype', &
         real(e0911,real64))
    call entry_real('icepack_parameters.ammoniumtype', &
         real(e0912,real64))
    call entry_real('icepack_parameters.silicatetype', &
         real(e0913,real64))
    call entry_real('icepack_parameters.dmspptype', &
         real(e0914,real64))
    call entry_real('icepack_parameters.dmspdtype', &
         real(e0915,real64))
    call entry_real('icepack_parameters.humtype', &
         real(e0916,real64))
    call entry_real('icepack_parameters.doctype_s', &
         real(e0917,real64))
    call entry_real('icepack_parameters.doctype_l', &
         real(e0918,real64))
    call entry_real('icepack_parameters.dictype_1', &
         real(e0919,real64))
    call entry_real('icepack_parameters.dontype_protein', &
         real(e0920,real64))
    call entry_real('icepack_parameters.fedtype_1', &
         real(e0921,real64))
    call entry_real('icepack_parameters.feptype_1', &
         real(e0922,real64))
    call entry_real('icepack_parameters.zaerotype_bc1', &
         real(e0923,real64))
    call entry_real('icepack_parameters.zaerotype_bc2', &
         real(e0924,real64))
    call entry_real('icepack_parameters.zaerotype_dust1', &
         real(e0925,real64))
    call entry_real('icepack_parameters.zaerotype_dust2', &
         real(e0926,real64))
    call entry_real('icepack_parameters.zaerotype_dust3', &
         real(e0927,real64))
    call entry_real('icepack_parameters.zaerotype_dust4', &
         real(e0928,real64))
    call entry_real('icepack_parameters.ratio_c2n_diatoms', &
         real(e0929,real64))
    call entry_real('icepack_parameters.ratio_c2n_sp', &
         real(e0930,real64))
    call entry_real('icepack_parameters.ratio_c2n_phaeo', &
         real(e0931,real64))
    call entry_real('icepack_parameters.ratio_chl2n_diatoms', &
         real(e0932,real64))
    call entry_real('icepack_parameters.ratio_chl2n_sp', &
         real(e0933,real64))
    call entry_real('icepack_parameters.ratio_chl2n_phaeo', &
         real(e0934,real64))
    call entry_real('icepack_parameters.ratio_c2n_proteins', &
         real(e0935,real64))
    call entry_real('icepack_parameters.f_abs_chl_diatoms', &
         real(e0936,real64))
    call entry_real('icepack_parameters.f_abs_chl_sp', &
         real(e0937,real64))
    call entry_real('icepack_parameters.f_abs_chl_phaeo', &
         real(e0938,real64))
    call entry_real('icepack_therm_shared.ferrmax', &
         real(e0939,real64))
    call entry_real('icepack_therm_shared.tmin', &
         real(e0940,real64))
    call entry_logical('icepack_therm_shared.l_brine', &
         e0941)
    call entry_real('icepack_therm_shared.dfsurfdts_cpl', &
         real(e0942,real64))
    call entry_real('icepack_therm_shared.dflatdts_cpl', &
         real(e0943,real64))
    call entry_real('icepack_therm_shared.fsurf_cpl0', &
         real(e0944,real64))
    call entry_real('icepack_therm_shared.flat_cpl0', &
         real(e0945,real64))
    call entry_real('icepack_therm_shared.fsurf_cpl', &
         real(e0946,real64))
    call entry_real('icepack_therm_shared.flat_cpl', &
         real(e0947,real64))
    call entry_int('icepack_tracers.max_iso', &
         int(e0948,int64))
    call entry_int('icepack_tracers.nmodal1', &
         int(e0949,int64))
    call entry_int('icepack_tracers.nmodal2', &
         int(e0950,int64))
    call entry_int('icepack_tracers.max_algae', &
         int(e0951,int64))
    call entry_int('icepack_tracers.max_dic', &
         int(e0952,int64))
    call entry_int('icepack_tracers.max_doc', &
         int(e0953,int64))
    call entry_int('icepack_tracers.max_don', &
         int(e0954,int64))
    call entry_int('icepack_tracers.max_fe', &
         int(e0955,int64))
    call entry_int('icepack_tracers.max_aero', &
         int(e0956,int64))
    call entry_int('icepack_tracers.max_nbtrcr', &
         int(e0957,int64))
    call entry_int('icepack_tracers.ntrcr', &
         int(e0958,int64))
    call entry_int('icepack_tracers.ntrcr_o', &
         int(e0959,int64))
    call entry_int('icepack_tracers.ncat', &
         int(e0960,int64))
    call entry_int('icepack_tracers.nilyr', &
         int(e0961,int64))
    call entry_int('icepack_tracers.nslyr', &
         int(e0962,int64))
    call entry_int('icepack_tracers.nblyr', &
         int(e0963,int64))
    call entry_int('icepack_tracers.nfsd', &
         int(e0964,int64))
    call entry_int('icepack_tracers.n_iso', &
         int(e0965,int64))
    call entry_int('icepack_tracers.n_aero', &
         int(e0966,int64))
    call entry_int('icepack_tracers.n_zaero', &
         int(e0967,int64))
    call entry_int('icepack_tracers.n_algae', &
         int(e0968,int64))
    call entry_int('icepack_tracers.n_doc', &
         int(e0969,int64))
    call entry_int('icepack_tracers.n_dic', &
         int(e0970,int64))
    call entry_int('icepack_tracers.n_don', &
         int(e0971,int64))
    call entry_int('icepack_tracers.n_fed', &
         int(e0972,int64))
    call entry_int('icepack_tracers.n_fep', &
         int(e0973,int64))
    call entry_int('icepack_tracers.nt_tsfc', &
         int(e0974,int64))
    call entry_int('icepack_tracers.nt_qice', &
         int(e0975,int64))
    call entry_int('icepack_tracers.nt_qsno', &
         int(e0976,int64))
    call entry_int('icepack_tracers.nt_sice', &
         int(e0977,int64))
    call entry_int('icepack_tracers.nt_fbri', &
         int(e0978,int64))
    call entry_int('icepack_tracers.nt_iage', &
         int(e0979,int64))
    call entry_int('icepack_tracers.nt_fy', &
         int(e0980,int64))
    call entry_int('icepack_tracers.nt_alvl', &
         int(e0981,int64))
    call entry_int('icepack_tracers.nt_vlvl', &
         int(e0982,int64))
    call entry_int('icepack_tracers.nt_apnd', &
         int(e0983,int64))
    call entry_int('icepack_tracers.nt_hpnd', &
         int(e0984,int64))
    call entry_int('icepack_tracers.nt_ipnd', &
         int(e0985,int64))
    call entry_int('icepack_tracers.nt_fsd', &
         int(e0986,int64))
    call entry_int('icepack_tracers.nt_smice', &
         int(e0987,int64))
    call entry_int('icepack_tracers.nt_smliq', &
         int(e0988,int64))
    call entry_int('icepack_tracers.nt_rhos', &
         int(e0989,int64))
    call entry_int('icepack_tracers.nt_rsnw', &
         int(e0990,int64))
    call entry_int('icepack_tracers.nt_isosno', &
         int(e0991,int64))
    call entry_int('icepack_tracers.nt_isoice', &
         int(e0992,int64))
    call entry_int('icepack_tracers.nt_aero', &
         int(e0993,int64))
    call entry_int('icepack_tracers.nt_bgc_nit', &
         int(e0994,int64))
    call entry_int('icepack_tracers.nt_bgc_am', &
         int(e0995,int64))
    call entry_int('icepack_tracers.nt_bgc_sil', &
         int(e0996,int64))
    call entry_int('icepack_tracers.nt_bgc_dmspp', &
         int(e0997,int64))
    call entry_int('icepack_tracers.nt_bgc_dmspd', &
         int(e0998,int64))
    call entry_int('icepack_tracers.nt_bgc_dms', &
         int(e0999,int64))
    call entry_int('icepack_tracers.nt_bgc_pon', &
         int(e1000,int64))
    call entry_int('icepack_tracers.nt_bgc_hum', &
         int(e1001,int64))
    call entry_int('icepack_tracers.nt_zbgc_frac', &
         int(e1002,int64))
    call entry_logical('icepack_tracers.tr_iage', &
         e1003)
    call entry_logical('icepack_tracers.tr_fy', &
         e1004)
    call entry_logical('icepack_tracers.tr_lvl', &
         e1005)
    call entry_logical('icepack_tracers.tr_pond', &
         e1006)
    call entry_logical('icepack_tracers.tr_pond_lvl', &
         e1007)
    call entry_logical('icepack_tracers.tr_pond_topo', &
         e1008)
    call entry_logical('icepack_tracers.tr_pond_sealvl', &
         e1009)
    call entry_logical('icepack_tracers.tr_snow', &
         e1010)
    call entry_logical('icepack_tracers.tr_iso', &
         e1011)
    call entry_logical('icepack_tracers.tr_aero', &
         e1012)
    call entry_logical('icepack_tracers.tr_brine', &
         e1013)
    call entry_logical('icepack_tracers.tr_fsd', &
         e1014)
    call entry_logical('icepack_tracers.tr_zaero', &
         e1015)
    call entry_logical('icepack_tracers.tr_bgc_nit', &
         e1016)
    call entry_logical('icepack_tracers.tr_bgc_n', &
         e1017)
    call entry_logical('icepack_tracers.tr_bgc_don', &
         e1018)
    call entry_logical('icepack_tracers.tr_bgc_c', &
         e1019)
    call entry_logical('icepack_tracers.tr_bgc_chl', &
         e1020)
    call entry_logical('icepack_tracers.tr_bgc_am', &
         e1021)
    call entry_logical('icepack_tracers.tr_bgc_sil', &
         e1022)
    call entry_logical('icepack_tracers.tr_bgc_dms', &
         e1023)
    call entry_logical('icepack_tracers.tr_bgc_fe', &
         e1024)
    call entry_logical('icepack_tracers.tr_bgc_pon', &
         e1025)
    call entry_logical('icepack_tracers.tr_bgc_hum', &
         e1026)
    call entry_int('icepack_tracers.nbtrcr', &
         int(e1027,int64))
    call entry_int('icepack_tracers.nbtrcr_sw', &
         int(e1028,int64))
    call entry_int('icepack_tracers.nlt_chl_sw', &
         int(e1029,int64))
    call entry_int('icepack_tracers.nlt_zaero_sw', &
         int(e1030,int64),lbound(e1030))
    call entry_int('icepack_tracers.nlt_bgc_n', &
         int(e1031,int64),lbound(e1031))
    call entry_int('icepack_tracers.nlt_bgc_c', &
         int(e1032,int64),lbound(e1032))
    call entry_int('icepack_tracers.nlt_bgc_chl', &
         int(e1033,int64),lbound(e1033))
    call entry_int('icepack_tracers.nlt_bgc_doc', &
         int(e1034,int64),lbound(e1034))
    call entry_int('icepack_tracers.nlt_bgc_don', &
         int(e1035,int64),lbound(e1035))
    call entry_int('icepack_tracers.nlt_bgc_dic', &
         int(e1036,int64),lbound(e1036))
    call entry_int('icepack_tracers.nlt_bgc_fed', &
         int(e1037,int64),lbound(e1037))
    call entry_int('icepack_tracers.nlt_bgc_fep', &
         int(e1038,int64),lbound(e1038))
    call entry_int('icepack_tracers.nlt_zaero', &
         int(e1039,int64),lbound(e1039))
    call entry_int('icepack_tracers.nlt_bgc_nit', &
         int(e1040,int64))
    call entry_int('icepack_tracers.nlt_bgc_am', &
         int(e1041,int64))
    call entry_int('icepack_tracers.nlt_bgc_sil', &
         int(e1042,int64))
    call entry_int('icepack_tracers.nlt_bgc_dmspp', &
         int(e1043,int64))
    call entry_int('icepack_tracers.nlt_bgc_dmspd', &
         int(e1044,int64))
    call entry_int('icepack_tracers.nlt_bgc_dms', &
         int(e1045,int64))
    call entry_int('icepack_tracers.nlt_bgc_pon', &
         int(e1046,int64))
    call entry_int('icepack_tracers.nlt_bgc_hum', &
         int(e1047,int64))
    call entry_int('icepack_tracers.nt_bgc_n', &
         int(e1048,int64),lbound(e1048))
    call entry_int('icepack_tracers.nt_bgc_c', &
         int(e1049,int64),lbound(e1049))
    call entry_int('icepack_tracers.nt_bgc_chl', &
         int(e1050,int64),lbound(e1050))
    call entry_int('icepack_tracers.nt_bgc_doc', &
         int(e1051,int64),lbound(e1051))
    call entry_int('icepack_tracers.nt_bgc_don', &
         int(e1052,int64),lbound(e1052))
    call entry_int('icepack_tracers.nt_bgc_dic', &
         int(e1053,int64),lbound(e1053))
    call entry_int('icepack_tracers.nt_bgc_fed', &
         int(e1054,int64),lbound(e1054))
    call entry_int('icepack_tracers.nt_bgc_fep', &
         int(e1055,int64),lbound(e1055))
    call entry_int('icepack_tracers.nt_zaero', &
         int(e1056,int64),lbound(e1056))
    call entry_int('icepack_tracers.bio_index_o', &
         int(e1057,int64),lbound(e1057))
    call entry_int('icepack_tracers.bio_index', &
         int(e1058,int64),lbound(e1058))
    if (allocated(e1059)) then
      call entry_real('icepack_fsd.floe_rad_h', &
         real(e1059,real64),lbound(e1059))
    else
      write(meta_unit,'(A)') 'icepack_fsd.floe_rad_h U'
    endif
    if (allocated(e1060)) then
      call entry_real('icepack_fsd.floe_rad_c', &
         real(e1060,real64),lbound(e1060))
    else
      write(meta_unit,'(A)') 'icepack_fsd.floe_rad_c U'
    endif
    if (allocated(e1061)) then
      call entry_real('icepack_fsd.floe_rad_l', &
         real(e1061,real64),lbound(e1061))
    else
      write(meta_unit,'(A)') 'icepack_fsd.floe_rad_l U'
    endif
    if (allocated(e1062)) then
      call entry_real('icepack_fsd.floe_binwidth', &
         real(e1062,real64),lbound(e1062))
    else
      write(meta_unit,'(A)') 'icepack_fsd.floe_binwidth U'
    endif
    if (allocated(e1063)) then
      call entry_real('icepack_fsd.floe_area_l', &
         real(e1063,real64),lbound(e1063))
    else
      write(meta_unit,'(A)') 'icepack_fsd.floe_area_l U'
    endif
    if (allocated(e1064)) then
      call entry_real('icepack_fsd.floe_area_h', &
         real(e1064,real64),lbound(e1064))
    else
      write(meta_unit,'(A)') 'icepack_fsd.floe_area_h U'
    endif
    if (allocated(e1065)) then
      call entry_real('icepack_fsd.floe_area_c', &
         real(e1065,real64),lbound(e1065))
    else
      write(meta_unit,'(A)') 'icepack_fsd.floe_area_c U'
    endif
    if (allocated(e1066)) then
      call entry_real('icepack_fsd.floe_area_binwidth', &
         real(e1066,real64),lbound(e1066))
    else
      write(meta_unit,'(A)') 'icepack_fsd.floe_area_binwidth U'
    endif
    if (allocated(e1067)) then
      call entry_char('icepack_fsd.c_fsd_range', &
         e1067,lbound(e1067))
    else
      write(meta_unit,'(A)') 'icepack_fsd.c_fsd_range U'
    endif
    if (allocated(e1068)) then
      call entry_int('icepack_fsd.iweld', &
         int(e1068,int64),lbound(e1068))
    else
      write(meta_unit,'(A)') 'icepack_fsd.iweld U'
    endif
    call entry_int('icepack_shortwave_data.nspint_3bd', &
         int(e1069,int64))
    call entry_int('icepack_shortwave_data.nspint_5bd', &
         int(e1070,int64))
    call entry_char('icepack_shortwave_data.rsnw_datatype', &
         e1071)
    call entry_real('icepack_shortwave_data.ki_ssl_mn_3bd', &
         real(e1072,real64),lbound(e1072))
    call entry_real('icepack_shortwave_data.wi_ssl_mn_3bd', &
         real(e1073,real64),lbound(e1073))
    call entry_real('icepack_shortwave_data.gi_ssl_mn_3bd', &
         real(e1074,real64),lbound(e1074))
    call entry_real('icepack_shortwave_data.ki_dl_mn_3bd', &
         real(e1075,real64),lbound(e1075))
    call entry_real('icepack_shortwave_data.wi_dl_mn_3bd', &
         real(e1076,real64),lbound(e1076))
    call entry_real('icepack_shortwave_data.gi_dl_mn_3bd', &
         real(e1077,real64),lbound(e1077))
    call entry_real('icepack_shortwave_data.ki_int_mn_3bd', &
         real(e1078,real64),lbound(e1078))
    call entry_real('icepack_shortwave_data.wi_int_mn_3bd', &
         real(e1079,real64),lbound(e1079))
    call entry_real('icepack_shortwave_data.gi_int_mn_3bd', &
         real(e1080,real64),lbound(e1080))
    call entry_real('icepack_shortwave_data.ki_p_ssl_mn', &
         real(e1081,real64),lbound(e1081))
    call entry_real('icepack_shortwave_data.wi_p_ssl_mn', &
         real(e1082,real64),lbound(e1082))
    call entry_real('icepack_shortwave_data.gi_p_ssl_mn', &
         real(e1083,real64),lbound(e1083))
    call entry_real('icepack_shortwave_data.ki_p_int_mn', &
         real(e1084,real64),lbound(e1084))
    call entry_real('icepack_shortwave_data.wi_p_int_mn', &
         real(e1085,real64),lbound(e1085))
    call entry_real('icepack_shortwave_data.gi_p_int_mn', &
         real(e1086,real64),lbound(e1086))
    call entry_real('icepack_shortwave_data.kw', &
         real(e1087,real64),lbound(e1087))
    call entry_real('icepack_shortwave_data.ww', &
         real(e1088,real64),lbound(e1088))
    call entry_real('icepack_shortwave_data.gw', &
         real(e1089,real64),lbound(e1089))
    if (allocated(e1090)) then
      call entry_real('icepack_shortwave_data.gaer_bc_3bd', &
         real(e1090,real64),lbound(e1090))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.gaer_bc_3bd U'
    endif
    if (allocated(e1091)) then
      call entry_real('icepack_shortwave_data.kaer_bc_3bd', &
         real(e1091,real64),lbound(e1091))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.kaer_bc_3bd U'
    endif
    if (allocated(e1092)) then
      call entry_real('icepack_shortwave_data.waer_bc_3bd', &
         real(e1092,real64),lbound(e1092))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.waer_bc_3bd U'
    endif
    if (allocated(e1093)) then
      call entry_real('icepack_shortwave_data.gaer_3bd', &
         real(e1093,real64),lbound(e1093))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.gaer_3bd U'
    endif
    if (allocated(e1094)) then
      call entry_real('icepack_shortwave_data.kaer_3bd', &
         real(e1094,real64),lbound(e1094))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.kaer_3bd U'
    endif
    if (allocated(e1095)) then
      call entry_real('icepack_shortwave_data.waer_3bd', &
         real(e1095,real64),lbound(e1095))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.waer_3bd U'
    endif
    if (allocated(e1096)) then
      call entry_real('icepack_shortwave_data.bcenh_3bd', &
         real(e1096,real64),lbound(e1096))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.bcenh_3bd U'
    endif
    call entry_int('icepack_shortwave_data.nmbrad_snw', &
         int(e1097,int64))
    if (allocated(e1098)) then
      call entry_real('icepack_shortwave_data.rsnw_tab', &
         real(e1098,real64),lbound(e1098))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.rsnw_tab U'
    endif
    if (allocated(e1099)) then
      call entry_real('icepack_shortwave_data.qs_tab', &
         real(e1099,real64),lbound(e1099))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.qs_tab U'
    endif
    if (allocated(e1100)) then
      call entry_real('icepack_shortwave_data.ws_tab', &
         real(e1100,real64),lbound(e1100))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.ws_tab U'
    endif
    if (allocated(e1101)) then
      call entry_real('icepack_shortwave_data.gs_tab', &
         real(e1101,real64),lbound(e1101))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.gs_tab U'
    endif
    call entry_real('icepack_shortwave_data.ki_ssl_mn_5bd', &
         real(e1102,real64),lbound(e1102))
    call entry_real('icepack_shortwave_data.wi_ssl_mn_5bd', &
         real(e1103,real64),lbound(e1103))
    call entry_real('icepack_shortwave_data.gi_ssl_mn_5bd', &
         real(e1104,real64),lbound(e1104))
    call entry_real('icepack_shortwave_data.ki_dl_mn_5bd', &
         real(e1105,real64),lbound(e1105))
    call entry_real('icepack_shortwave_data.wi_dl_mn_5bd', &
         real(e1106,real64),lbound(e1106))
    call entry_real('icepack_shortwave_data.gi_dl_mn_5bd', &
         real(e1107,real64),lbound(e1107))
    call entry_real('icepack_shortwave_data.ki_int_mn_5bd', &
         real(e1108,real64),lbound(e1108))
    call entry_real('icepack_shortwave_data.wi_int_mn_5bd', &
         real(e1109,real64),lbound(e1109))
    call entry_real('icepack_shortwave_data.gi_int_mn_5bd', &
         real(e1110,real64),lbound(e1110))
    if (allocated(e1111)) then
      call entry_real('icepack_shortwave_data.gaer_bc_5bd', &
         real(e1111,real64),lbound(e1111))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.gaer_bc_5bd U'
    endif
    if (allocated(e1112)) then
      call entry_real('icepack_shortwave_data.kaer_bc_5bd', &
         real(e1112,real64),lbound(e1112))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.kaer_bc_5bd U'
    endif
    if (allocated(e1113)) then
      call entry_real('icepack_shortwave_data.waer_bc_5bd', &
         real(e1113,real64),lbound(e1113))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.waer_bc_5bd U'
    endif
    if (allocated(e1114)) then
      call entry_real('icepack_shortwave_data.gaer_5bd', &
         real(e1114,real64),lbound(e1114))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.gaer_5bd U'
    endif
    if (allocated(e1115)) then
      call entry_real('icepack_shortwave_data.kaer_5bd', &
         real(e1115,real64),lbound(e1115))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.kaer_5bd U'
    endif
    if (allocated(e1116)) then
      call entry_real('icepack_shortwave_data.waer_5bd', &
         real(e1116,real64),lbound(e1116))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.waer_5bd U'
    endif
    if (allocated(e1117)) then
      call entry_real('icepack_shortwave_data.bcenh_5bd', &
         real(e1117,real64),lbound(e1117))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.bcenh_5bd U'
    endif
    call entry_int('icepack_shortwave_data.nmbrad_snicar', &
         int(e1118,int64))
    call entry_real('icepack_shortwave_data.rsnw_snicar_min', &
         real(e1119,real64))
    call entry_real('icepack_shortwave_data.rsnw_snicar_max', &
         real(e1120,real64))
    if (trim(e0723) /= 'dEdd_snicar_ad') then
      write(meta_unit,'(A)') 'icepack_shortwave_data.rsnw_snicar_tab X inactive_shortwave_pointer'
    elseif (associated(e1121)) then
      call entry_real('icepack_shortwave_data.rsnw_snicar_tab', &
         real(e1121,real64),lbound(e1121))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.rsnw_snicar_tab U'
    endif
    if (trim(e0723) /= 'dEdd_snicar_ad') then
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_snwextdr X inactive_shortwave_pointer'
    elseif (associated(e1122)) then
      call entry_real('icepack_shortwave_data.ssp_snwextdr', &
         real(e1122,real64),lbound(e1122))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_snwextdr U'
    endif
    if (trim(e0723) /= 'dEdd_snicar_ad') then
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_snwextdf X inactive_shortwave_pointer'
    elseif (associated(e1123)) then
      call entry_real('icepack_shortwave_data.ssp_snwextdf', &
         real(e1123,real64),lbound(e1123))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_snwextdf U'
    endif
    if (trim(e0723) /= 'dEdd_snicar_ad') then
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_snwalbdr X inactive_shortwave_pointer'
    elseif (associated(e1124)) then
      call entry_real('icepack_shortwave_data.ssp_snwalbdr', &
         real(e1124,real64),lbound(e1124))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_snwalbdr U'
    endif
    if (trim(e0723) /= 'dEdd_snicar_ad') then
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_snwalbdf X inactive_shortwave_pointer'
    elseif (associated(e1125)) then
      call entry_real('icepack_shortwave_data.ssp_snwalbdf', &
         real(e1125,real64),lbound(e1125))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_snwalbdf U'
    endif
    if (trim(e0723) /= 'dEdd_snicar_ad') then
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_sasymmdr X inactive_shortwave_pointer'
    elseif (associated(e1126)) then
      call entry_real('icepack_shortwave_data.ssp_sasymmdr', &
         real(e1126,real64),lbound(e1126))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_sasymmdr U'
    endif
    if (trim(e0723) /= 'dEdd_snicar_ad') then
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_sasymmdf X inactive_shortwave_pointer'
    elseif (associated(e1127)) then
      call entry_real('icepack_shortwave_data.ssp_sasymmdf', &
         real(e1127,real64),lbound(e1127))
    else
      write(meta_unit,'(A)') 'icepack_shortwave_data.ssp_sasymmdf U'
    endif
    call entry_char('ice_calendar.ice_calendar_proleptic_gregorian', &
         e1128)
    call entry_char('ice_calendar.ice_calendar_gregorian', &
         e1129)
    call entry_char('ice_calendar.ice_calendar_noleap', &
         e1130)
    call entry_char('ice_calendar.ice_calendar_360day', &
         e1131)
    call entry_int('ice_calendar.months_per_year', &
         int(e1132,int64))
    call entry_int('ice_calendar.hours_per_day', &
         int(e1133,int64))
    call entry_int('ice_calendar.minutes_per_hour', &
         int(e1134,int64))
    call entry_int('ice_calendar.seconds_per_minute', &
         int(e1135,int64))
    call entry_int('ice_calendar.seconds_per_day', &
         int(e1136,int64))
    call entry_int('ice_calendar.seconds_per_hour', &
         int(e1137,int64))
    call entry_int('ice_calendar.days_per_year', &
         int(e1138,int64))
    call entry_int('ice_calendar.daymo', &
         int(e1139,int64),lbound(e1139))
    call entry_int('ice_calendar.daycal', &
         int(e1140,int64),lbound(e1140))
    call entry_int('ice_calendar.istep', &
         int(e1141,int64))
    call entry_int('ice_calendar.istep0', &
         int(e1142,int64))
    call entry_int('ice_calendar.istep1', &
         int(e1143,int64))
    call entry_int('ice_calendar.myear', &
         int(e1144,int64))
    call entry_int('ice_calendar.mmonth', &
         int(e1145,int64))
    call entry_int('ice_calendar.mday', &
         int(e1146,int64))
    call entry_int('ice_calendar.msec', &
         int(e1147,int64))
    call entry_int('ice_calendar.year_init', &
         int(e1148,int64))
    call entry_int('ice_calendar.month_init', &
         int(e1149,int64))
    call entry_int('ice_calendar.day_init', &
         int(e1150,int64))
    call entry_int('ice_calendar.sec_init', &
         int(e1151,int64))
    call entry_int('ice_calendar.hh_init', &
         int(e1152,int64))
    call entry_int('ice_calendar.mm_init', &
         int(e1153,int64))
    call entry_int('ice_calendar.ss_init', &
         int(e1154,int64))
    call entry_int('ice_calendar.idate', &
         int(e1155,int64))
    call entry_int('ice_calendar.idate0', &
         int(e1156,int64))
    call entry_int('ice_calendar.dayyr', &
         int(e1157,int64))
    call entry_int('ice_calendar.npt', &
         int(e1158,int64))
    call entry_int('ice_calendar.npt0', &
         int(e1159,int64))
    call entry_int('ice_calendar.ndtd', &
         int(e1160,int64))
    call entry_int('ice_calendar.stop_now', &
         int(e1161,int64))
    call entry_int('ice_calendar.write_restart', &
         int(e1162,int64))
    call entry_int('ice_calendar.diagfreq', &
         int(e1163,int64))
    call entry_int('ice_calendar.nstreams', &
         int(e1164,int64))
    call entry_int('ice_calendar.dumpfreq_n', &
         int(e1165,int64),lbound(e1165))
    call entry_int('ice_calendar.histfreq_n', &
         int(e1166,int64),lbound(e1166))
    call entry_logical('ice_calendar.new_year', &
         e1167)
    call entry_logical('ice_calendar.new_month', &
         e1168)
    call entry_logical('ice_calendar.new_day', &
         e1169)
    call entry_logical('ice_calendar.new_hour', &
         e1170)
    call entry_real('ice_calendar.dt', &
         real(e1171,real64))
    call entry_real('ice_calendar.dt_dyn', &
         real(e1172,real64))
    call entry_real('ice_calendar.timesecs', &
         real(e1173,real64))
    call entry_real('ice_calendar.yday', &
         real(e1174,real64))
    call entry_real('ice_calendar.nextsw_cday', &
         real(e1175,real64))
    call entry_logical('ice_calendar.use_leap_years', &
         e1176)
    call entry_logical('ice_calendar.write_ic', &
         e1177)
    call entry_logical('ice_calendar.write_histrest', &
         e1178)
    call entry_logical('ice_calendar.dump_last', &
         e1179)
    call entry_logical('ice_calendar.force_restart_now', &
         e1180)
    call entry_logical('ice_calendar.write_history', &
         e1181,lbound(e1181))
    call entry_char('ice_calendar.npt_unit', &
         e1182)
    call entry_char('ice_calendar.npt0_unit', &
         e1183)
    call entry_char('ice_calendar.histfreq', &
         e1184,lbound(e1184))
    call entry_char('ice_calendar.dumpfreq', &
         e1185,lbound(e1185))
    call entry_char('ice_calendar.dumpfreq_base', &
         e1186,lbound(e1186))
    call entry_char('ice_calendar.histfreq_base', &
         e1187,lbound(e1187))
    call entry_char('ice_calendar.calendar_type', &
         e1188)
    call entry_int('ice_domain_size.max_blocks', &
         int(e1189,int64))
    call entry_int('ice_domain_size.block_size_x', &
         int(e1190,int64))
    call entry_int('ice_domain_size.block_size_y', &
         int(e1191,int64))
    call entry_int('ice_domain_size.nx_global', &
         int(e1192,int64))
    call entry_int('ice_domain_size.ny_global', &
         int(e1193,int64))
    call entry_int('ice_domain_size.ncat', &
         int(e1194,int64))
    call entry_int('ice_domain_size.nfsd', &
         int(e1195,int64))
    call entry_int('ice_domain_size.nilyr', &
         int(e1196,int64))
    call entry_int('ice_domain_size.nslyr', &
         int(e1197,int64))
    call entry_int('ice_domain_size.nblyr', &
         int(e1198,int64))
    call entry_int('ice_domain_size.n_iso', &
         int(e1199,int64))
    call entry_int('ice_domain_size.n_aero', &
         int(e1200,int64))
    call entry_int('ice_domain_size.n_zaero', &
         int(e1201,int64))
    call entry_int('ice_domain_size.n_algae', &
         int(e1202,int64))
    call entry_int('ice_domain_size.n_doc', &
         int(e1203,int64))
    call entry_int('ice_domain_size.n_dic', &
         int(e1204,int64))
    call entry_int('ice_domain_size.n_don', &
         int(e1205,int64))
    call entry_int('ice_domain_size.n_fed', &
         int(e1206,int64))
    call entry_int('ice_domain_size.n_fep', &
         int(e1207,int64))
    call entry_int('ice_domain_size.nfreq', &
         int(e1208,int64))
    call entry_int('ice_domain_size.max_nstrm', &
         int(e1209,int64))
    call entry_int('ice_domain.nblocks', &
         int(e1210,int64))
    call entry_logical('ice_domain.close_boundaries', &
         e1211)
    if (associated(e1212)) then
      call entry_int('ice_domain.blocks_ice', &
         int(e1212,int64),lbound(e1212))
    else
      write(meta_unit,'(A)') 'ice_domain.blocks_ice U'
    endif
    call entry_char('ice_domain.ew_boundary_type', &
         e1213)
    call entry_char('ice_domain.ns_boundary_type', &
         e1214)
    call entry_logical('ice_domain.maskhalo_dyn', &
         e1215)
    call entry_logical('ice_domain.maskhalo_remap', &
         e1216)
    call entry_logical('ice_domain.maskhalo_bound', &
         e1217)
    call entry_logical('ice_domain.halo_dynbundle', &
         e1218)
    call entry_logical('ice_domain.landblockelim', &
         e1219)
    call entry_char('ice_init.ice_ic', &
         e1220)
    call entry_int('ice_forcing.ycycle', &
         int(e1221,int64))
    call entry_int('ice_forcing.fyear_init', &
         int(e1222,int64))
    call entry_int('ice_forcing.fyear', &
         int(e1223,int64))
    call entry_int('ice_forcing.fyear_final', &
         int(e1224,int64))
    if (allocated(e1225)) then
      call entry_char('ice_forcing.topmelt_file', &
         e1225,lbound(e1225))
    else
      write(meta_unit,'(A)') 'ice_forcing.topmelt_file U'
    endif
    if (allocated(e1226)) then
      call entry_char('ice_forcing.botmelt_file', &
         e1226,lbound(e1226))
    else
      write(meta_unit,'(A)') 'ice_forcing.botmelt_file U'
    endif
    call entry_real('ice_forcing.c1intp', &
         real(e1227,real64))
    call entry_real('ice_forcing.c2intp', &
         real(e1228,real64))
    if (allocated(e1229)) then
      call entry_real('ice_forcing.cldf', &
         real(e1229,real64),lbound(e1229))
    else
      write(meta_unit,'(A)') 'ice_forcing.cldf U'
    endif
    if (allocated(e1230)) then
      call entry_real('ice_forcing.fsw_data', &
         real(e1230,real64),lbound(e1230))
    else
      write(meta_unit,'(A)') 'ice_forcing.fsw_data U'
    endif
    if (allocated(e1231)) then
      call entry_real('ice_forcing.cldf_data', &
         real(e1231,real64),lbound(e1231))
    else
      write(meta_unit,'(A)') 'ice_forcing.cldf_data U'
    endif
    if (allocated(e1232)) then
      call entry_real('ice_forcing.fsnow_data', &
         real(e1232,real64),lbound(e1232))
    else
      write(meta_unit,'(A)') 'ice_forcing.fsnow_data U'
    endif
    if (allocated(e1233)) then
      call entry_real('ice_forcing.tair_data', &
         real(e1233,real64),lbound(e1233))
    else
      write(meta_unit,'(A)') 'ice_forcing.tair_data U'
    endif
    if (allocated(e1234)) then
      call entry_real('ice_forcing.uatm_data', &
         real(e1234,real64),lbound(e1234))
    else
      write(meta_unit,'(A)') 'ice_forcing.uatm_data U'
    endif
    if (allocated(e1235)) then
      call entry_real('ice_forcing.vatm_data', &
         real(e1235,real64),lbound(e1235))
    else
      write(meta_unit,'(A)') 'ice_forcing.vatm_data U'
    endif
    if (allocated(e1236)) then
      call entry_real('ice_forcing.wind_data', &
         real(e1236,real64),lbound(e1236))
    else
      write(meta_unit,'(A)') 'ice_forcing.wind_data U'
    endif
    if (allocated(e1237)) then
      call entry_real('ice_forcing.strax_data', &
         real(e1237,real64),lbound(e1237))
    else
      write(meta_unit,'(A)') 'ice_forcing.strax_data U'
    endif
    if (allocated(e1238)) then
      call entry_real('ice_forcing.stray_data', &
         real(e1238,real64),lbound(e1238))
    else
      write(meta_unit,'(A)') 'ice_forcing.stray_data U'
    endif
    if (allocated(e1239)) then
      call entry_real('ice_forcing.qa_data', &
         real(e1239,real64),lbound(e1239))
    else
      write(meta_unit,'(A)') 'ice_forcing.qa_data U'
    endif
    if (allocated(e1240)) then
      call entry_real('ice_forcing.rhoa_data', &
         real(e1240,real64),lbound(e1240))
    else
      write(meta_unit,'(A)') 'ice_forcing.rhoa_data U'
    endif
    if (allocated(e1241)) then
      call entry_real('ice_forcing.flw_data', &
         real(e1241,real64),lbound(e1241))
    else
      write(meta_unit,'(A)') 'ice_forcing.flw_data U'
    endif
    if (allocated(e1242)) then
      call entry_real('ice_forcing.sst_data', &
         real(e1242,real64),lbound(e1242))
    else
      write(meta_unit,'(A)') 'ice_forcing.sst_data U'
    endif
    if (allocated(e1243)) then
      call entry_real('ice_forcing.sss_data', &
         real(e1243,real64),lbound(e1243))
    else
      write(meta_unit,'(A)') 'ice_forcing.sss_data U'
    endif
    if (allocated(e1244)) then
      call entry_real('ice_forcing.uocn_data', &
         real(e1244,real64),lbound(e1244))
    else
      write(meta_unit,'(A)') 'ice_forcing.uocn_data U'
    endif
    if (allocated(e1245)) then
      call entry_real('ice_forcing.vocn_data', &
         real(e1245,real64),lbound(e1245))
    else
      write(meta_unit,'(A)') 'ice_forcing.vocn_data U'
    endif
    if (allocated(e1246)) then
      call entry_real('ice_forcing.sublim_data', &
         real(e1246,real64),lbound(e1246))
    else
      write(meta_unit,'(A)') 'ice_forcing.sublim_data U'
    endif
    if (allocated(e1247)) then
      call entry_real('ice_forcing.frain_data', &
         real(e1247,real64),lbound(e1247))
    else
      write(meta_unit,'(A)') 'ice_forcing.frain_data U'
    endif
    if (allocated(e1248)) then
      call entry_real('ice_forcing.topmelt_data', &
         real(e1248,real64),lbound(e1248))
    else
      write(meta_unit,'(A)') 'ice_forcing.topmelt_data U'
    endif
    if (allocated(e1249)) then
      call entry_real('ice_forcing.botmelt_data', &
         real(e1249,real64),lbound(e1249))
    else
      write(meta_unit,'(A)') 'ice_forcing.botmelt_data U'
    endif
    call entry_char('ice_forcing.atm_data_format', &
         e1250)
    call entry_char('ice_forcing.ocn_data_format', &
         e1251)
    call entry_char('ice_forcing.atm_data_type', &
         e1252)
    call entry_char('ice_forcing.atm_data_version', &
         e1253)
    call entry_char('ice_forcing.bgc_data_type', &
         e1254)
    call entry_char('ice_forcing.ocn_data_type', &
         e1255)
    call entry_char('ice_forcing.ice_data_type', &
         e1256)
    call entry_char('ice_forcing.ice_data_conc', &
         e1257)
    call entry_char('ice_forcing.ice_data_dist', &
         e1258)
    call entry_char('ice_forcing.precip_units', &
         e1259)
    call entry_logical('ice_forcing.rotate_wind', &
         e1260)
    call entry_char('ice_forcing.atm_data_dir', &
         e1261)
    call entry_char('ice_forcing.ocn_data_dir', &
         e1262)
    call entry_char('ice_forcing.wave_spec_dir', &
         e1263)
    call entry_char('ice_forcing.wave_spec_file', &
         e1264)
    call entry_char('ice_forcing.oceanmixed_file', &
         e1265)
    call entry_real('ice_forcing.frcvdr', &
         real(e1266,real64))
    call entry_real('ice_forcing.frcvdf', &
         real(e1267,real64))
    call entry_real('ice_forcing.frcidr', &
         real(e1268,real64))
    call entry_real('ice_forcing.frcidf', &
         real(e1269,real64))
    if (allocated(e1270)) then
      call entry_real('ice_forcing.ocn_frc_m', &
         real(e1270,real64),lbound(e1270))
    else
      write(meta_unit,'(A)') 'ice_forcing.ocn_frc_m U'
    endif
    call entry_logical('ice_forcing.restore_ocn', &
         e1271)
    call entry_int('ice_forcing.trestore', &
         int(e1272,int64))
    call entry_real('ice_forcing.trest', &
         real(e1273,real64))
    call entry_logical('ice_forcing.debug_forcing', &
         e1274)
    if (allocated(e1275)) then
      call entry_real('ice_forcing.jday_atm', &
         real(e1275,real64),lbound(e1275))
    else
      write(meta_unit,'(A)') 'ice_forcing.jday_atm U'
    endif
    call entry_int('ice_forcing.njday_atm', &
         int(e1276,int64))
    call entry_char('ice_forcing.snw_filename', &
         e1277)
    call entry_char('ice_forcing.snw_rhos_fname', &
         e1278)
    call entry_char('ice_forcing.snw_tgrd_fname', &
         e1279)
    call entry_char('ice_forcing.snw_t_fname', &
         e1280)
    call entry_char('ice_forcing.snw_tau_fname', &
         e1281)
    call entry_char('ice_forcing.snw_kappa_fname', &
         e1282)
    call entry_char('ice_forcing.snw_drdt0_fname', &
         e1283)
    if (allocated(e1284)) then
      call entry_real('ice_forcing_bgc.nitdat', &
         real(e1284,real64),lbound(e1284))
    else
      write(meta_unit,'(A)') 'ice_forcing_bgc.nitdat U'
    endif
    if (allocated(e1285)) then
      call entry_real('ice_forcing_bgc.sildat', &
         real(e1285,real64),lbound(e1285))
    else
      write(meta_unit,'(A)') 'ice_forcing_bgc.sildat U'
    endif
    if (allocated(e1286)) then
      call entry_real('ice_forcing_bgc.nit_data', &
         real(e1286,real64),lbound(e1286))
    else
      write(meta_unit,'(A)') 'ice_forcing_bgc.nit_data U'
    endif
    if (allocated(e1287)) then
      call entry_real('ice_forcing_bgc.sil_data', &
         real(e1287,real64),lbound(e1287))
    else
      write(meta_unit,'(A)') 'ice_forcing_bgc.sil_data U'
    endif
    call entry_real('ice_constants.omega', &
         real(e1288,real64))
    call entry_real('ice_constants.radius', &
         real(e1289,real64))
    call entry_real('ice_constants.spval_dbl', &
         real(e1290,real64))
    call entry_real('ice_constants.spval', &
         real(e1291,real64))
    call entry_real('ice_constants.shlat', &
         real(e1292,real64))
    call entry_real('ice_constants.nhlat', &
         real(e1293,real64))
    call entry_real('ice_constants.c0', &
         real(e1294,real64))
    call entry_real('ice_constants.c1', &
         real(e1295,real64))
    call entry_real('ice_constants.c1p5', &
         real(e1296,real64))
    call entry_real('ice_constants.c2', &
         real(e1297,real64))
    call entry_real('ice_constants.c3', &
         real(e1298,real64))
    call entry_real('ice_constants.c4', &
         real(e1299,real64))
    call entry_real('ice_constants.c5', &
         real(e1300,real64))
    call entry_real('ice_constants.c6', &
         real(e1301,real64))
    call entry_real('ice_constants.c8', &
         real(e1302,real64))
    call entry_real('ice_constants.c9', &
         real(e1303,real64))
    call entry_real('ice_constants.c10', &
         real(e1304,real64))
    call entry_real('ice_constants.c12', &
         real(e1305,real64))
    call entry_real('ice_constants.c15', &
         real(e1306,real64))
    call entry_real('ice_constants.c16', &
         real(e1307,real64))
    call entry_real('ice_constants.c20', &
         real(e1308,real64))
    call entry_real('ice_constants.c25', &
         real(e1309,real64))
    call entry_real('ice_constants.c30', &
         real(e1310,real64))
    call entry_real('ice_constants.c100', &
         real(e1311,real64))
    call entry_real('ice_constants.c180', &
         real(e1312,real64))
    call entry_real('ice_constants.c360', &
         real(e1313,real64))
    call entry_real('ice_constants.c365', &
         real(e1314,real64))
    call entry_real('ice_constants.c400', &
         real(e1315,real64))
    call entry_real('ice_constants.c1000', &
         real(e1316,real64))
    call entry_real('ice_constants.c3600', &
         real(e1317,real64))
    call entry_real('ice_constants.p001', &
         real(e1318,real64))
    call entry_real('ice_constants.p01', &
         real(e1319,real64))
    call entry_real('ice_constants.p025', &
         real(e1320,real64))
    call entry_real('ice_constants.p05', &
         real(e1321,real64))
    call entry_real('ice_constants.p1', &
         real(e1322,real64))
    call entry_real('ice_constants.p15', &
         real(e1323,real64))
    call entry_real('ice_constants.p2', &
         real(e1324,real64))
    call entry_real('ice_constants.p25', &
         real(e1325,real64))
    call entry_real('ice_constants.p3', &
         real(e1326,real64))
    call entry_real('ice_constants.p4', &
         real(e1327,real64))
    call entry_real('ice_constants.p5', &
         real(e1328,real64))
    call entry_real('ice_constants.p6', &
         real(e1329,real64))
    call entry_real('ice_constants.p75', &
         real(e1330,real64))
    call entry_real('ice_constants.p111', &
         real(e1331,real64))
    call entry_real('ice_constants.p166', &
         real(e1332,real64))
    call entry_real('ice_constants.p222', &
         real(e1333,real64))
    call entry_real('ice_constants.p333', &
         real(e1334,real64))
    call entry_real('ice_constants.p666', &
         real(e1335,real64))
    call entry_real('ice_constants.p055', &
         real(e1336,real64))
    call entry_real('ice_constants.p027', &
         real(e1337,real64))
    call entry_real('ice_constants.eps04', &
         real(e1338,real64))
    call entry_real('ice_constants.eps13', &
         real(e1339,real64))
    call entry_real('ice_constants.eps16', &
         real(e1340,real64))
    call entry_int('ice_constants.field_loc_unknown', &
         int(e1341,int64))
    call entry_int('ice_constants.field_loc_noupdate', &
         int(e1342,int64))
    call entry_int('ice_constants.field_loc_center', &
         int(e1343,int64))
    call entry_int('ice_constants.field_loc_necorner', &
         int(e1344,int64))
    call entry_int('ice_constants.field_loc_nface', &
         int(e1345,int64))
    call entry_int('ice_constants.field_loc_eface', &
         int(e1346,int64))
    call entry_int('ice_constants.field_type_unknown', &
         int(e1347,int64))
    call entry_int('ice_constants.field_type_noupdate', &
         int(e1348,int64))
    call entry_int('ice_constants.field_type_scalar', &
         int(e1349,int64))
    call entry_int('ice_constants.field_type_vector', &
         int(e1350,int64))
    call entry_int('ice_constants.field_type_angle', &
         int(e1351,int64))
    call entry_real('ice_constants.cm_to_m', &
         real(e1352,real64))
    call entry_real('ice_constants.m_to_cm', &
         real(e1353,real64))
    call entry_real('ice_constants.m2_to_km2', &
         real(e1354,real64))
    call entry_real('ice_constants.kg_to_g', &
         real(e1355,real64))
    call entry_real('ice_constants.mps_to_cmpdy', &
         real(e1356,real64))
    write(meta_unit,'(A,1X,I0)') 'END',byte_offset
    close(data_unit)
    close(meta_unit)
    write(nu_diag,'(A,1X,A)') '(step_entry) complete:',trim(stem)
  end subroutine write_step_entry

  logical function entry_grid(name,dims)
    character(len=*), intent(in) :: name
    integer, intent(in) :: dims(:)
    entry_grid = .false.
    if (size(dims) < 3) return
    if (index(name,'icepack_') == 1 .or. index(name,'layout.') == 1) return
    entry_grid = dims(1)==nx_block .and. dims(2)==ny_block .and. dims(size(dims))==max_blocks
  end function entry_grid

  subroutine entry_header(name,code,dims,lower,width,grid)
    character(len=*), intent(in) :: name,code
    integer, intent(in) :: dims(:),lower(:),width
    logical, intent(in) :: grid
    write(meta_unit,'(A,1X,A,1X,I0,1X,I0,1X,I0,1X,I0,*(1X,I0))') &
         name,code,size(dims),byte_offset,width,merge(1,0,grid),dims,lower
    byte_offset = byte_offset + int(product(int(dims,int64)),int64)*int(width,int64)
  end subroutine entry_header

  subroutine entry_real_0(name,value)
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: value
    call entry_header(name,'R',[integer ::],[integer ::],8,.false.)
    write(data_unit) value
  end subroutine entry_real_0

  subroutine entry_real_1(name,value,lower)
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: value(:)
    integer, intent(in) :: lower(1)
    integer :: dims(1)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    call entry_header(name,'R',dims,lower,8,grid)
    write(data_unit) value
  end subroutine entry_real_1

  subroutine entry_real_2(name,value,lower)
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: value(:,:)
    integer, intent(in) :: lower(2)
    integer :: dims(2)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    call entry_header(name,'R',dims,lower,8,grid)
    write(data_unit) value
  end subroutine entry_real_2

  subroutine entry_real_3(name,value,lower)
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: value(:,:,:)
    integer, intent(in) :: lower(3)
    integer :: dims(3)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    if (grid) then
      dims(3) = nblocks
      call entry_header(name,'R',dims,lower,8,grid)
      write(data_unit) value(:,:,1:nblocks)
    else
      call entry_header(name,'R',dims,lower,8,grid)
      write(data_unit) value
    endif
  end subroutine entry_real_3

  subroutine entry_real_4(name,value,lower)
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: value(:,:,:,:)
    integer, intent(in) :: lower(4)
    integer :: dims(4)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    if (grid) then
      dims(4) = nblocks
      call entry_header(name,'R',dims,lower,8,grid)
      write(data_unit) value(:,:,:,1:nblocks)
    else
      call entry_header(name,'R',dims,lower,8,grid)
      write(data_unit) value
    endif
  end subroutine entry_real_4

  subroutine entry_real_5(name,value,lower)
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: value(:,:,:,:,:)
    integer, intent(in) :: lower(5)
    integer :: dims(5)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    if (grid) then
      dims(5) = nblocks
      call entry_header(name,'R',dims,lower,8,grid)
      write(data_unit) value(:,:,:,:,1:nblocks)
    else
      call entry_header(name,'R',dims,lower,8,grid)
      write(data_unit) value
    endif
  end subroutine entry_real_5

  subroutine entry_int_0(name,value)
    character(len=*), intent(in) :: name
    integer(int64), intent(in) :: value
    call entry_header(name,'I',[integer ::],[integer ::],8,.false.)
    write(data_unit) value
  end subroutine entry_int_0

  subroutine entry_int_1(name,value,lower)
    character(len=*), intent(in) :: name
    integer(int64), intent(in) :: value(:)
    integer, intent(in) :: lower(1)
    integer :: dims(1)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    call entry_header(name,'I',dims,lower,8,grid)
    write(data_unit) value
  end subroutine entry_int_1

  subroutine entry_int_2(name,value,lower)
    character(len=*), intent(in) :: name
    integer(int64), intent(in) :: value(:,:)
    integer, intent(in) :: lower(2)
    integer :: dims(2)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    call entry_header(name,'I',dims,lower,8,grid)
    write(data_unit) value
  end subroutine entry_int_2


  subroutine entry_int_4(name,value,lower)
    character(len=*), intent(in) :: name
    integer(int64), intent(in) :: value(:,:,:,:)
    integer, intent(in) :: lower(4)
    integer :: dims(4)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    if (grid) then
      dims(4) = nblocks
      call entry_header(name,'I',dims,lower,8,grid)
      write(data_unit) value(:,:,:,1:nblocks)
    else
      call entry_header(name,'I',dims,lower,8,grid)
      write(data_unit) value
    endif
  end subroutine entry_int_4


  subroutine entry_logical_0(name,value)
    character(len=*), intent(in) :: name
    logical, intent(in) :: value
    call entry_header(name,'L',[integer ::],[integer ::],8,.false.)
    write(data_unit) merge(1_int64,0_int64,value)
  end subroutine entry_logical_0

  subroutine entry_logical_1(name,value,lower)
    character(len=*), intent(in) :: name
    logical, intent(in) :: value(:)
    integer, intent(in) :: lower(1)
    integer :: dims(1)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    call entry_header(name,'L',dims,lower,8,grid)
    write(data_unit) merge(1_int64,0_int64,value)
  end subroutine entry_logical_1


  subroutine entry_logical_3(name,value,lower)
    character(len=*), intent(in) :: name
    logical, intent(in) :: value(:,:,:)
    integer, intent(in) :: lower(3)
    integer :: dims(3)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    if (grid) then
      dims(3) = nblocks
      call entry_header(name,'L',dims,lower,8,grid)
      write(data_unit) merge(1_int64,0_int64,value(:,:,1:nblocks))
    else
      call entry_header(name,'L',dims,lower,8,grid)
      write(data_unit) merge(1_int64,0_int64,value)
    endif
  end subroutine entry_logical_3

  subroutine entry_logical_4(name,value,lower)
    character(len=*), intent(in) :: name
    logical, intent(in) :: value(:,:,:,:)
    integer, intent(in) :: lower(4)
    integer :: dims(4)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    if (grid) then
      dims(4) = nblocks
      call entry_header(name,'L',dims,lower,8,grid)
      write(data_unit) merge(1_int64,0_int64,value(:,:,:,1:nblocks))
    else
      call entry_header(name,'L',dims,lower,8,grid)
      write(data_unit) merge(1_int64,0_int64,value)
    endif
  end subroutine entry_logical_4


  subroutine entry_char_0(name,value)
    character(len=*), intent(in) :: name
    character(len=*), intent(in) :: value
    call entry_header(name,'C',[integer ::],[integer ::],len(value),.false.)
    write(data_unit) value
  end subroutine entry_char_0

  subroutine entry_char_1(name,value,lower)
    character(len=*), intent(in) :: name
    character(len=*), intent(in) :: value(:)
    integer, intent(in) :: lower(1)
    integer :: dims(1)
    logical :: grid
    dims = shape(value)
    grid = entry_grid(name,dims)
    call entry_header(name,'C',dims,lower,len(value),grid)
    write(data_unit) value
  end subroutine entry_char_1
end module ice_step_snapshot
