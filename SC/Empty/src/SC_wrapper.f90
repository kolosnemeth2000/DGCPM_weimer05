!  Copyright (C) 2002 Regents of the University of Michigan,
!  portions used with permission
!  For more information, see http://csem.engin.umich.edu/tools/swmf

module SC_wrapper
  use CON_domain_decomposition
  ! Wrapper for an "empty" Solar Corona (SC) component
  use CON_coupler,             ONLY: SC_, GridType, LocalGridType
  implicit none

  private ! except

  ! CON wrapper
  public:: SC_set_param
  public:: SC_init_session
  public:: SC_run
  public:: SC_save_restart
  public:: SC_finalize

  ! Global buffer coupling
  public:: SC_get_for_global_buffer
  public:: SC_xyz_to_coord, SC_coord_to_xyz

  ! Coupling toolkit
  public:: SC_synchronize_refinement
  public:: SC_get_for_mh
  public:: SC_get_for_mh_with_xyz
  public:: SC_put_from_mh
  public:: SC_is_coupled_block
  public:: SC_interface_point_coords
  public:: SC_n_particle
  Character(len=3),    public :: TypeCoordSource    ! Coords of coupled model
  real,                public :: SourceToSC_DD(3,3) ! Transformation matrrix
  real,                public :: TimeMhToSC = -1.0  ! Time of coupling

  type(GridType),      public :: SC_Grid            ! Grid (MHD data)
  type(GridType),      public :: SC_LineGrid        ! Global GD for lines
  type(LocalGridType), public :: SC_LocalGrid       ! Local GD (MHD data)
  type(LocalGridType), public :: SC_LocalLineGrid   ! Local GD for lines)


  ! Coupling with SC
  public:: SC_set_buffer_grid_get_info
  public:: SC_save_global_buffer
  public:: SC_match_ibc

  ! Point coupling
  public:: SC_get_grid_info
  public:: SC_find_points

  ! Coupling with SP
  public:: SC_check_ready_for_sp
  public:: SC_extract_line
  public:: SC_put_particles
  public:: SC_get_particle_indexes
  public:: SC_get_particle_coords

  ! Coupling with GM
  public:: SC_get_for_gm

  ! Coupling with PT
  public:: SC_get_for_pt
  public:: SC_put_from_pt
  public:: SC_get_for_pt_dt

  ! Coupling with EE (for SC)
  public:: SC_get_for_ee
  public:: SC_put_from_ee

contains
  !============================================================================
  subroutine SC_set_param(CompInfo, TypeAction)

    use CON_comp_info

    ! Arguments
    type(CompInfoType), intent(inout):: CompInfo   ! Information for this comp.
    character (len=*), intent(in)    :: TypeAction ! What to do
    character(len=*), parameter:: NameSub = 'SC_set_param'
    !--------------------------------------------------------------------------
    select case(TypeAction)
    case('VERSION')
       call put(CompInfo,&
            Use        =.false., &
            NameVersion='Empty', &
            Version    =0.0)

    case default
       call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
    end select

  end subroutine SC_set_param
  !============================================================================

  subroutine SC_init_session(iSession, TimeSimulation)

    integer,  intent(in) :: iSession         ! session number (starting from 1)
    real,     intent(in) :: TimeSimulation   ! seconds from start time

    character(len=*), parameter:: NameSub = 'SC_init_session'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_init_session
  !============================================================================

  subroutine SC_finalize(TimeSimulation)

    real,     intent(in) :: TimeSimulation   ! seconds from start time

    character(len=*), parameter:: NameSub = 'SC_finalize'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_finalize
  !============================================================================

  subroutine SC_save_restart(TimeSimulation)

    real,     intent(in) :: TimeSimulation   ! seconds from start time

    character(len=*), parameter:: NameSub = 'SC_save_restart'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_save_restart
  !============================================================================

  subroutine SC_run(TimeSimulation,TimeSimulationLimit)

    real, intent(inout):: TimeSimulation   ! current time of component

    real, intent(in):: TimeSimulationLimit ! simulation time not to be exceeded

    character(len=*), parameter:: NameSub = 'SC_run'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_run
  !============================================================================
  subroutine SC_get_grid_info(nDimOut, iGridOut, iDecompOut)

    integer, intent(out):: nDimOut    ! grid dimensionality
    integer, intent(out):: iGridOut   ! grid index (increases with AMR)
    integer, intent(out):: iDecompOut ! decomposition index

    character(len=*), parameter:: NameSub = 'SC_get_grid_info'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_get_grid_info
  !============================================================================
  subroutine SC_coord_to_xyz(CoordIn_D, XyzOut_D)
    real, intent(in) :: CoordIn_D(3)
    real, intent(out):: XyzOut_D( 3)
    character(len=*), parameter:: NameSub = 'SC_coord_to_xyz'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_coord_to_xyz
  !============================================================================
  subroutine SC_xyz_to_coord(XyzIn_D, CoordOut_D)
    real,             intent(in ) :: XyzIn_D(3)
    real,             intent(out) :: CoordOut_D(3)
    character(len=*), parameter:: NameSub = 'SC_xyz_to_coord'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_xyz_to_coord
  !============================================================================
  subroutine SC_find_points(nDimIn, nPoint, Xyz_DI, iProc_I)

    integer, intent(in) :: nDimIn                ! dimension of position vectors
    integer, intent(in) :: nPoint                ! number of positions
    real,    intent(in) :: Xyz_DI(nDimIn,nPoint) ! positions
    integer, intent(out):: iProc_I(nPoint)       ! processor owning position

    ! Find array of points and return processor indexes owning them
    ! Could be generalized to return multiple processors...

    character(len=*), parameter:: NameSub = 'SC_find_points'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_find_points
  !============================================================================

  subroutine SC_synchronize_refinement(iProc0,iCommUnion)

    integer, intent(in) ::iProc0,iCommUnion

    character(len=*), parameter:: NameSub = 'SC_synchronize_refinement'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_synchronize_refinement
  !============================================================================

  subroutine SC_get_for_gm(&
       nPartial,iGetStart,Get,W,State_V,nVar,TimeCoupling)

    use CON_router, ONLY: IndexPtrType, WeightPtrType

    integer,intent(in)::nPartial,iGetStart,nVar
    type(IndexPtrType),intent(in)::Get
    type(WeightPtrType),intent(in)::W
    real,dimension(nVar),intent(out)::State_V
    real,intent(in)::TimeCoupling

    character(len=*), parameter:: NameSub = 'SC_get_for_gm'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_get_for_gm
  !============================================================================
  logical function SC_is_coupled_block(iBlock)
    integer, intent(in) :: iBlock
    character(len=*), parameter:: NameSub = 'SC_is_coupled_block'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end function SC_is_coupled_block
  !============================================================================
  subroutine SC_interface_point_coords(nDim, Xyz_D, nIndex, iIndex_I, &
       IsInterfacePoint)
    integer,intent(in)   :: nDim
    real,   intent(inout):: Xyz_D(nDim)
    integer,intent(in)   :: nIndex
    integer,intent(inout):: iIndex_I(nIndex)
    logical,intent(out)  :: IsInterfacePoint
    character(len=*), parameter:: NameSub = 'SC_interface_point_coords'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_interface_point_coords
  !============================================================================
  subroutine SC_get_for_mh(&
       nPartial,iGetStart,Get,W,State_V,nVar)

    use CON_router, ONLY: IndexPtrType, WeightPtrType

    integer,intent(in)              ::nPartial,iGetStart,nVar
    type(IndexPtrType),intent(in)   ::Get
    type(WeightPtrType),intent(in)  ::W
    real,dimension(nVar),intent(out)::State_V

    character(len=*), parameter:: NameSub = 'SC_get_for_mh'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_get_for_mh
  !============================================================================
  subroutine SC_get_for_mh_with_xyz(&
       nPartial,iGetStart,Get,W,State_V,nVar)

    use CON_router, ONLY: IndexPtrType, WeightPtrType

    integer,intent(in)               :: nPartial,iGetStart,nVar
    type(IndexPtrType),intent(in)    :: Get
    type(WeightPtrType),intent(in)   :: W
    real,dimension(nVar),intent(out) ::State_V

    character(len=*), parameter:: NameSub = 'SC_get_for_mh_with_xyz'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_get_for_mh_with_xyz
  !============================================================================
  subroutine SC_check_ready_for_sp(IsReady)
    logical, intent(out):: IsReady
    character(len=*), parameter:: NameSub = 'SC_check_ready_for_sp'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_check_ready_for_sp
  !============================================================================
  subroutine SC_get_particle_indexes(iParticle, iIndex_I)
    integer, intent(in) :: iParticle
    integer, intent(out):: iIndex_I(2)
    character(len=*), parameter:: NameSub = 'SC_get_particle_indexes'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_get_particle_indexes
  !============================================================================
  subroutine SC_get_particle_coords(iParticle, Xyz_D)
    integer, intent(in) :: iParticle
    real,    intent(out):: Xyz_D(3)
    character(len=*), parameter:: NameSub = 'SC_get_particle_coords'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_get_particle_coords
  !============================================================================
  subroutine SC_extract_line(Xyz_DI, iTraceMode, &
       iIndex_II, RSoftBoundary)
    real,             intent(in) :: Xyz_DI(:, :)
    integer,          intent(in) :: iTraceMode
    integer,          intent(in) :: iIndex_II(:,:)
    real,             intent(in) :: RSoftBoundary
    character(len=*), parameter:: NameSub = 'SC_extract_line'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_extract_line
  !============================================================================
  subroutine SC_put_particles(Xyz_DI, iIndex_II)
    real,    intent(in) :: Xyz_DI(:, :)
    integer, intent(in) :: iIndex_II(:,:)
    character(len=*), parameter:: NameSub = 'SC_put_particles'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_put_particles
  !============================================================================
  subroutine SC_put_from_mh(nPartial,&
       iPutStart,&
       Put,&
       Weight,&
       DoAdd,&
       StateSI_V,&
       nVar)
    use CON_router,    ONLY: IndexPtrType, WeightPtrType

    integer,intent(in)::nPartial,iPutStart,nVar
    type(IndexPtrType),intent(in)::Put
    type(WeightPtrType),intent(in)::Weight
    logical,intent(in)::DoAdd
    real,dimension(nVar),intent(in)::StateSI_V

    character(len=*), parameter:: NameSub = 'SC_put_from_mh'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_put_from_mh
  !============================================================================
  subroutine SC_match_ibc

    character(len=*), parameter:: NameSub = 'SC_match_ibc'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_match_ibc
  !============================================================================
  subroutine SC_set_buffer_grid_get_info(&
       nR, nPhi, nTheta, BufferMinMax_DI)

    integer, intent(out)    :: nR, nPhi, nTheta
    real, intent(out)       :: BufferMinMax_DI(3,2)

    ! ---------------------------------------------------------------

    character(len=*), parameter:: NameSub = 'SC_set_buffer_grid_get_info'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_set_buffer_grid_get_info
  !============================================================================
  subroutine SC_save_global_buffer(nVar, nR, nLon, nLat, BufferIn_VG)

    integer,intent(in) :: nVar, nR, nLon, nLat
    real,intent(in)    :: BufferIn_VG(nVar, nR, 0:nLon+1, 0:nLat+1)

    character(len=*), parameter:: NameSub = 'SC_save_global_buffer'
    !--------------------------------------------------------------------------

    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_save_global_buffer
  !============================================================================
  subroutine SC_get_for_global_buffer(&
       nR, nPhi,nTheta, BufferMinMax_DI, Buffer_VG)

    ! Buffer size and limits
    integer,intent(in) :: nR, nPhi, nTheta
    real, intent(in)   :: BufferMinMax_DI(3,2)

    ! State variables to be fiiled in all buffer grid points
    real, intent(out):: Buffer_VG(:,:,:,:)

    character(len=*), parameter:: NameSub = 'SC_get_for_global_buffer'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_get_for_global_buffer
  !============================================================================
  subroutine SC_get_for_pt(IsNew, NameVar, nVarIn, nDimIn, nPoint, Xyz_DI, &
       Data_VI)

    ! Get magnetic field data from SC to PT
    logical,          intent(in):: IsNew   ! true for new point array
    character(len=*), intent(in):: NameVar ! List of variables
    integer,          intent(in):: nVarIn  ! Number of variables in Data_VI
    integer,          intent(in):: nDimIn  ! Dimensionality of positions
    integer,          intent(in):: nPoint  ! Number of points in Xyz_DI

    real, intent(in) :: Xyz_DI(nDimIn,nPoint)  ! Position vectors
    real, intent(out):: Data_VI(nVarIn,nPoint) ! Data array

    character(len=*), parameter:: NameSub = 'SC_get_for_pt'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_get_for_pt
  !============================================================================

  subroutine SC_put_from_pt( &
       NameVar, nVar, nPoint, Data_VI, iPoint_I, Pos_DI)

    character(len=*), intent(inout):: NameVar ! List of variables
    integer,          intent(inout):: nVar    ! Number of variables in Data_VI
    integer,          intent(inout):: nPoint  ! Number of points in Pos_DI

    real,    intent(in), optional:: Data_VI(:,:)    ! Recv data array
    integer, intent(in), optional:: iPoint_I(nPoint)! Order of data
    real, intent(out), allocatable, optional:: Pos_DI(:,:) ! Position vectors

    character(len=*), parameter:: NameSub = 'SC_put_from_pt'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_put_from_pt
  !============================================================================
  subroutine SC_get_for_pt_dt(DtSi)
    real, intent(out) ::  DtSi
    character(len=*), parameter:: NameSub = 'SC_get_for_pt_dt'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end subroutine SC_get_for_pt_dt
  !============================================================================

  subroutine SC_get_for_ee(IsNew, NameVar, nVarIn, nDimIn, nPoint, Xyz_DI, &
       Data_VI)

    ! This routine is actually for SC-EE coupling

    ! Interpolate Data_VI from SC at the list of positions Xyz_DI
    ! required by EE

    logical,          intent(in):: IsNew   ! true for new point array
    character(len=*), intent(in):: NameVar ! List of variables
    integer,          intent(in):: nVarIn  ! Number of variables in Data_VI
    integer,          intent(in):: nDimIn  ! Dimensionality of positions
    integer,          intent(in):: nPoint  ! Number of points in Xyz_DI

    real, intent(in) :: Xyz_DI(nDimIn,nPoint)  ! Position vectors
    real, intent(out):: Data_VI(nVarIn,nPoint) ! Data array

    character(len=*), parameter:: NameSub = 'SC_get_for_ee'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_get_for_ee
  !============================================================================

  subroutine SC_put_from_ee( &
       NameVar, nVarData, nPoint, Data_VI, iPoint_I, Pos_DI)

    ! This routine is actually for EE-SC coupling

    character(len=*), intent(inout):: NameVar ! List of variables
    integer,          intent(inout):: nVarData! Number of variables in Data_VI
    integer,          intent(inout):: nPoint  ! Number of points in Pos_DI

    real,    intent(in), optional:: Data_VI(:,:)    ! Recv data array
    integer, intent(in), optional:: iPoint_I(nPoint)! Order of data
    real, intent(out), allocatable, optional:: Pos_DI(:,:) ! Position vectors

    character(len=*), parameter:: NameSub = 'SC_put_from_ee'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')

  end subroutine SC_put_from_ee
  !============================================================================
  integer function SC_n_particle(iBlockLocal)
    integer, intent(in) :: iBlockLocal

    character(len=*), parameter:: NameSub = 'SC_n_particle'
    !--------------------------------------------------------------------------
    call CON_stop(NameSub//': SC_ERROR: empty version cannot be used!')
  end function SC_n_particle
  !============================================================================

end module SC_wrapper
!==============================================================================

