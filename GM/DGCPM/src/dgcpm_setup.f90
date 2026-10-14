!  Copyright (C) 2002 Regents of the University of Michigan, portions used with permission 
!  For more information, see http://csem.engin.umich.edu/tools/swmf
! File name: dgcpm_setup.f90
!
! Contains: Routines for DGCPM
!	GETKPA
!       SHUE
!	THERMAL
!
! Change from 011 to 012: Supports SWMF Style Input, removes legacy
!        inoperable HEIDI code.
!
! Last Modified: January 2012, Aron Dodger
!
!
! **********************************************************************
!                             GETKPA
!	Finds KP and other parameters as well as convection strength A
!	Note [A]= V/m * 1/Re^(lamgam-1), last term =1 (in units of L)
!
!       Previously, five Kp choices were available via "IKP".  These have
!       been reduced to two options, set via the #KP param command.
!
!  NameSourceKp Options:
!       'const'   Constant Kp.
!       'file'    Read from NGDC-formatted file; interpolate.
!
!  OBSOLETE IKP choices [removed]:
!	IKP=0  Static Kp
!	IKP=1  Decrease by DKP until Kp=1
!	IKP=2  Read from table
!	IKP=3  Read from file
!	IKP=4  Read from MBI file (also read kp file for other inputs)
!       IKP=5  Read from file (Direct file values, no interpolation)
!       IKP=6  Read from NGDC formatted file with interpolation.
! **********************************************************************
!! SUBROUTINE GETKPA(i3,nst,i2,nkp)
SUBROUTINE GETKPA

  use ModIoDGCPM,   ONLY: Kp, NameSourceKp, KpConst
  use ModMainDGCPM, ONLY: A
  use ModTimeDGCPM, ONLY: CurrentTime
  use ModIndicesInterfaces
  use ModUtilities, ONLY: CON_set_do_test, CON_stop

  implicit none

  integer :: ierror

  logical :: DoTest, DoTestMe
  character(len=*), parameter :: NameSub = 'getkpa'  
  !--------------------------------------------------------------------
  call CON_set_do_test(NameSub, DoTest, DoTestMe)

  ! Get Kp values either constant or from file:
  if (NameSourceKp .eq. 'const') then
     Kp=kpConst
  else if (index(NameSourceKp, 'file')>0) then
     ! Interpolate to current time:
     call get_kp(CurrentTime, Kp, iError)
     if (iError /= 0) call CON_stop(NameSub//' DGCPM error getting Kp')
  else
     call CON_stop(NameSub//' Unrecognized NameSourceKp='//NameSourceKp)
  end if

  A=7.05E-6/(1.-0.159*KP+0.0093*KP**2)**3

  ! Write test info to screen as necessary:
  if (DoTestMe) write(*,'(a,a,a,f15.1,a, f4.2, E12.3)') &
       'PS/DGCPM: Source=', NameSourceKp,' T=', CurrentTime,' Kp, A = ', Kp, A
  
END SUBROUTINE GETKPA

!
! End of subroutine GETKPA
!

! **********************************************************************
!                               SHUE
!   Calculates the magnetopause location using the equation described
!   in Shue et al. 1998. Equation is a function of the solar wind 
!   dynamic pressure (in nPa) and Bz field strength (in nT)
! **********************************************************************

    subroutine Shue()

    use ModSizeDGCPM 
    use ModMainDGCPM
    use ModTimeDGCPM
    use ModIndicesInterfaces
    
        implicit none

! r0 is the subsolar standoff distance in Re
        real r0, r, theta, temp_r
! alpha is the power factor for the angular dependance
        real alpha
! Dp is the solar wind dynamic pressure, in nPa
        real Dp

        integer i, j, iError

!        call get_IMF_Bz(CurrentTime, IMF_Bz, iError)
!        if (iError /= 0) then
!           write(*,*) "Can not find IMF Bz."
!        endif

!        call get_SW_V(CurrentTime, SW_V, iError)
!        if (iError /= 0) then
!           write(*,*) "Can not find SW_V."
!        endif

!        call get_SW_N(CurrentTime, SW_N, iError)
!        if (iError /= 0) then
!           write(*,*) "Can not find IMF Bz."
!        endif

        ! Ideiglenes fix a fordításhoz:
        IMF_Bz = -5.0   ! Alapértelmezett érték (nT)
        SW_V = 400.0    ! Alapértelmezett sebesség (km/s)
        SW_N = 5.0      ! Alapértelmezett sűrűség (n/cc)
        iError = 0

! A régi hívásokat kommentezd ki:
!       call get_IMF_Bz(CurrentTime, IMF_Bz, iError)
!       ... stb ...
        
        SW_V = SW_V * 1000.
        SW_N = SW_N * (1./100.) ** 3.

        Dp = ((SW_V ** 2.0) * SW_N * 1.67262158E-27) * (1E21)

        r0 = (10.22 + 1.29 * tanh( 0.184 * ( IMF_Bz + 8.14 ) ) ) * &
               (Dp ** (- (1.0 / 6.6 ) ) )

        alpha = (0.58 - 0.007 * IMF_Bz) * (1.0 + 0.024 * alog(Dp)) 

        do i=1, nthetacells
            do j=1, nphicells
                temp_r = vrcells(i)
                theta  = atan(mgridx(i,j) / mgridy(i,j))
                r = r0 * ( 2.0 / (1.0 + cos(theta))) ** alpha

                if (r.lt.temp_r) then
                    mgridoc(i,j) = 1. 
                else 
                    mgridoc(i,j) = 0.
                endif
            enddo
        enddo

        return
      END SUBROUTINE SHUE
!
! End of subroutine SHUE
!


! **********************************************************************
!				THERMAL
!	  Dynamic Global Core Plasma Model (DGCPM) is called
!         through Thermal via the plasmasphere command. This routine
!         also performs most of the necessary setup and initialization
!         commands necessary for the model itself. 
! **********************************************************************
SUBROUTINE THERMAL

  use ModSizeDGCPM
  use ModMainDGCPM
  use ModIoDGCPM
  use ModConstDGCPM
  use ModCoupleDGCPM
  use ModTimeDGCPM

  implicit none

  integer :: i,j,i1,j1,l,jj,jjj,j2,ier,ntimestep,n,testi,testj
  real :: EO,FAC,FACI
  real :: delt, par(2)
  real :: chi1, kpinit, dtimestep
  character(len=100) ::  filename =''
  integer :: ierror

  par(1)=-1.0
  par(2)=-1.0
  ntimestep=10
  dtimestep=1./ntimestep

  !  If ITHERMFIRST=1, then do initial setup for the plasmasphere code
  !  and RETURN
  IF (ithermfirst.eq.1) then
    
     call initmain()
     call getgrid(vthetacells,nthetacells,vphicells,nphicells)
     call getxydipole()
     do i=1,nthetacells
        vlzcells(i)=1./sin(dtor*vthetacells(i))**2.
     enddo
     do j=1,nphicells
        vmltcells(j)=vphicells(j)/15.
     enddo

     ithermfirst=2
     RETURN

  END IF

  ! Call the plasmasphere code and interpolate onto our spatial grid
  delt=2*DT*dtimestep
  If (ithermfirst.eq.2) then
     If (itherminit.eq.1) then  ! Read initial plasmasphere from file
        filename=cRestartIn//'dgcpm_restart.dat'
        if (debug .gt. 0) write(*,*) &
             'Reading in plasmasphere file: ', trim(filename)
        call load_restart_file(trim(filename))
        call getdensity(vthetacells,nthetacells,vphicells,nphicells, &
             dendgcpm)
        delt=0.        
     else	 ! initialize plasmasphere with 48 h of low activity
        if (debug .gt. 0) write(*,*) 'Initializing Plasmasphere with 48h of Low Activity'
        kpinit = 1.0 
        chi1 = 7350.0 / (9.0 - kpinit)
        delt=48.0*60.0*60.0
        do i = 1, nthetacells
           do j = 1, nphicells
              fac = vlzcells(i) * sin(dtor*vphicells(j))
              potdgcpm(i,j) = chi1 * fac
           enddo
        enddo
     endif  ! itherminit
  endif    ! ithermfirst

  If (delt.gt.0.) then
     if (isCoupled) then
        call setpot(IeTheta_I, nThetaIe, IePhi_I, nPhiIe, IePot_II)
     else
        if (index(EFieldModel, 'weimer05') > 0 .or. index(EFieldModel, 'WEIMER05') > 0) then
           call set_weimer05_potential(CurrentTime, mgridpot)
        else
           call magconv
        endif
        call setpot(real(vthetacells, 8), nthetacells, real(vphicells, 8), nphicells, mgridpot)
     endif

    ! Shue Magnetopause - Still in testing
    If (UseShue) then
        call shue()
    endif
     
     do n=1,ntimestep
        call plasmasphere(delt,par)
     end do
     call getdensity(vthetacells,nthetacells,vphicells,nphicells,dendgcpm)
  endif

  ithermfirst = 0
  RETURN
END SUBROUTINE THERMAL
!
! End of subroutine THERMAL
!

! **********************************************************************
!                         SET_WEIMER05_POTENTIAL
!   Computes potential on the DGCPM grid using the EIE Weimer05 model.
!   The driver data (IMF/SW) can be loaded from fixed values or from
!   an MHD/IMF index file through DATAREAD indices.
! **********************************************************************
subroutine set_weimer05_potential(TimeIn, PotOut_II)

  use ModSizeDGCPM
  use ModMainDGCPM
   use ModIndicesInterfaces
  use ModUtilities, ONLY: CON_stop

  implicit none

  real*8, intent(in) :: TimeIn
  real, intent(out) :: PotOut_II(nthetacells, nphicells)

  integer :: i, j, iError
  real :: By, Bz, Vsw, Nsw
  real, save :: MLT_II(nphicells, nthetacells)
  real, save :: MLat_II(nphicells, nthetacells)
  real :: PotTmp_II(nphicells, nthetacells)
  logical, save :: IsInit = .false.
  character(len=100), save :: Lines_I(100)
  character(len=100), save :: cIndexInput(4)

  if (.not.IsInit) then
     Lines_I = ''
     Lines_I(1)  = '#BACKGROUND'
     Lines_I(2)  = 'EIE/'
     Lines_I(3)  = 'weimer05'
     Lines_I(4)  = 'ihp'
     Lines_I(5)  = 'idontknow'
     Lines_I(6)  = ''
     Lines_I(7)  = '#DEBUG'
     Lines_I(8)  = '0'
     Lines_I(9)  = '0'
     Lines_I(10) = ''
     Lines_I(11) = '#END'

     call EIE_set_inputs(Lines_I)
     write(*,*) 'DEBUG: set_weimer05_potential before EIE_Initialize, ModelDir=EIE/'
     call flush(6)
     call EIE_Initialize(iError)
     write(*,*) 'DEBUG: set_weimer05_potential after EIE_Initialize, iError=', iError
     call flush(6)
     if (iError /= 0) call CON_stop('PS::set_weimer05_potential: EIE_Initialize failed')

     if (index(WeimerInput, 'file') > 0 .or. index(WeimerInput, 'FILE') > 0) then
      cIndexInput(1) = '#MHD_INDICES'
        cIndexInput(2) = trim(WeimerImfFile)
        cIndexInput(3) = ' '
        cIndexInput(4) = '#END'
        write(*,*) 'DEBUG: set_weimer05_potential before read_MHDIMF_Indices, file=', trim(WeimerImfFile)
        call flush(6)
        call IO_set_inputs(cIndexInput)
        call read_MHDIMF_Indices(iError)
        write(*,*) 'DEBUG: set_weimer05_potential after read_MHDIMF_Indices, iError=', iError
        call flush(6)
        if (iError /= 0) then
           call CON_stop('PS::set_weimer05_potential: read_MHDIMF_Indices failed')
        endif
     else
        call IO_set_IMF_By_single(WeimerBy)
        call IO_set_IMF_Bz_single(WeimerBz)
        call IO_set_SW_v_single(abs(WeimerV))
        call IO_set_SW_n_single(WeimerN)
     endif

     do i = 1, nthetacells
        do j = 1, nphicells
           MLT_II(j,i) = mod(vphicells(j)/15.0 + 12.0, 24.0)
           MLat_II(j,i) = 90.0 - vthetacells(i)
        end do
     end do

     IsInit = .true.
  endif

  call get_IMF_By(TimeIn, By, iError)
  call get_IMF_Bz(TimeIn, Bz, iError)
  call get_SW_V(TimeIn, Vsw, iError)
  call get_SW_N(TimeIn, Nsw, iError)
  if (iError /= 0) call CON_stop('PS::set_weimer05_potential: IMF/SW drivers unavailable')

  call IO_SetnMLTs(nphicells)
  call IO_SetnLats(nthetacells)
  call IO_SetNorth
  call IO_SetTime(TimeIn)
  call IO_SetIMFBy(By)
  call IO_SetIMFBz(Bz)
  call IO_SetSWV(abs(Vsw))
  call IO_SetSWN(Nsw)
  call IO_SetGrid(MLT_II, MLat_II, iError)
  if (iError /= 0) call CON_stop('PS::set_weimer05_potential: IO_SetGrid failed')

  call IO_GetPotential(PotTmp_II, iError)
  if (iError /= 0) call CON_stop('PS::set_weimer05_potential: IO_GetPotential failed')

  do i = 1, nthetacells
     do j = 1, nphicells
        PotOut_II(i,j) = PotTmp_II(j,i)
     end do
  end do

end subroutine set_weimer05_potential

