! Standalone diagnostic. Original stability routines below retain CICE expressions.
! Build with the case's Fortran compiler and -O2; run from the case directory.
program stability_probe
  use iso_fortran_env, only: real64
  implicit none
  integer, parameter :: dbl_kind = real64
  real(dbl_kind), parameter :: c1=1.0_dbl_kind, c2=2.0_dbl_kind, c8=8.0_dbl_kind
  real(dbl_kind), parameter :: c16=16.0_dbl_kind, p5=0.5_dbl_kind
  real(dbl_kind) :: hol, pih, original, stable, full_fortran, full_jax, values(17)
  real(dbl_kind), volatile :: exp_arg, exp_value, stable_a, stable_b, stable_c, stable_sum
  real(dbl_kind), volatile :: xd_arg, xd, xd_squared, momentum_arg, log_m, atan_xd, scalar_arg, log_s
  real(dbl_kind), volatile :: term1, term2, stable_part, unstable_part, split
  integer :: unit, status, step, i, j, cat, record, kind, k
  character(len=8) :: qty
  character(len=20), parameter :: fields(17) = [character(len=20) :: &
     'hol', 'pih', 'psi_original', 'psi_split', 'exp_arg', 'exp_value', &
     'stable_a', 'stable_b', 'stable_c', 'stable_sum', 'xd_arg', 'xd', &
     'momentum_arg', 'log_m', 'atan_xd', 'scalar_arg', 'log_s']

  open(newunit=unit, file='comparison_logs/stability_probe_inputs.txt', status='old', action='read')
  do
     read(unit,*,iostat=status) step, i, j, cat, record, kind, hol, pih, full_fortran, full_jax
     if (status < 0) exit
     if (status /= 0) error stop "Invalid stability probe input"
     if (kind == 1) then
        qty = 'momentum'
     elseif (kind == 2) then
        qty = 'scalar'
     else
        error stop "Invalid stability probe kind"
     endif
     call compute_stability_function(qty, hol, stable, original)

     ! VOLATILE intermediates provide a separately rounded diagnostic variant.
     exp_arg = -0.35_dbl_kind * hol
     exp_value = exp(exp_arg)
     stable_a = 0.7_dbl_kind * hol
     term1 = hol - 14.3_dbl_kind
     stable_b = 0.75_dbl_kind * term1
     stable_c = stable_b * exp_value
     stable_sum = stable_a + stable_c
     term1 = stable_sum + 10.7_dbl_kind
     stable_part = -term1
     term1 = c16 * hol
     xd_arg = c1 - term1
     term1 = sqrt(abs(xd_arg))
     xd = sqrt(max(term1, c1))
     xd_squared = xd * xd
     term1 = c2 + xd
     term2 = xd * term1
     term1 = c1 + term2
     term2 = c1 + xd_squared
     momentum_arg = term1 * term2
     momentum_arg = momentum_arg / c8
     log_m = log(momentum_arg)
     atan_xd = atan(xd)
     term1 = c1 + xd_squared
     scalar_arg = term1 / c2
     log_s = log(scalar_arg)
     if (kind == 1) then
        term1 = c2 * atan_xd
        term2 = log_m - term1
        unstable_part = term2 + pih
     else
        unstable_part = c2 * log_s
     endif
     term1 = stable_part * stable
     term2 = (c1 - stable) * unstable_part
     split = term1 + term2
     values = [hol, pih, original, split, exp_arg, exp_value, &
               stable_a, stable_b, stable_c, stable_sum, xd_arg, xd, &
               momentum_arg, log_m, atan_xd, scalar_arg, log_s]
     write(*,'(a,i0,a,i0,a,i0,a,i0,a,i0,a,i0,19(a,a,a,es25.17e3),a,l1,a,l1)') &
        '(stability_fortran) step=', step, ' i=', i, ' j=', j, ' cat=', cat, &
        ' record=', record, ' kind=', kind, &
        (' ', trim(fields(k)), '=', values(k), k=1,17), &
        ' ', 'full_fortran', '=', full_fortran, ' ', 'full_jax', '=', full_jax, &
        ' original_matches_full=', original == full_fortran, &
        ' split_matches_original=', split == original
  enddo
  close(unit)
contains

      subroutine compute_stability_function(qty, hol, stable, psi)

      character (len=*), intent(in) :: &
         qty          ! 'momentum' or 'scalar'

      real (kind=dbl_kind), intent(in) :: &
         hol          ! H over L

      real (kind=dbl_kind), intent(out) :: &
         psi          , & ! stability function at hol
         stable           ! unit step function at hol

      ! local variables

      real (kind=dbl_kind) :: &
         psi_stable   , & ! stable stability funcion at hol
         psi_unstable     ! unstable stability funcion at hol

      character(len=*),parameter :: subname='(compute_stability_function)'

      stable = p5 + sign(p5 , hol)

      psi_stable = -(0.7_dbl_kind*hol &
                 + 0.75_dbl_kind*(hol-14.3_dbl_kind) &
                 * exp(-0.35_dbl_kind*hol) + 10.7_dbl_kind)

      if(trim(qty) == 'momentum') then
         psi_unstable = psi_momentum_unstable(hol)
      elseif(trim(qty) == 'scalar') then
         psi_unstable = psi_scalar_unstable(hol)
      else
         error stop "Unknown stability quantity"
      endif

      psi = psi_stable*stable + (c1 - stable)*psi_unstable

   end subroutine compute_stability_function

!------------------------------------------------------------
! Define functions
!------------------------------------------------------------

!=======================================================================

      real(kind=dbl_kind) function psi_momentum_unstable(hol)

      real(kind=dbl_kind), intent(in) :: hol

      real(kind=dbl_kind) :: xd

      xd = capital_X(hol)

      psi_momentum_unstable = log((c1+xd*(c2+xd))*(c1+xd*xd)/c8) &
                              - c2*atan(xd) + pih

      end function psi_momentum_unstable

!=======================================================================

      real(kind=dbl_kind) function psi_scalar_unstable(hol)

      real(kind=dbl_kind), intent(in) :: hol

      real(kind=dbl_kind) :: xd

      xd = capital_X(hol)

      psi_scalar_unstable =  c2 * log((c1 + xd*xd)/c2)

      end function psi_scalar_unstable

!=======================================================================

      real(kind=dbl_kind) function capital_X(hol)

      real(kind=dbl_kind), intent(in) :: hol

      capital_X =  sqrt(max(sqrt(abs(c1 - c16*hol)) , c1))

      end function capital_X
end program stability_probe
