!=======================================================================

! Grid-dependent arrays needed for column package

! author: Elizabeth C. Hunke, LANL

      module icedrv_arrays_column

      use icedrv_kinds
      use icedrv_constants, only: nu_diag
      use icedrv_domain_size, only: nx, ncat, nilyr, nslyr, nfsd, nfreq
      use icedrv_domain_size, only: nblyr, max_nsw , max_ntrcr
      use icepack_intfc, only: icepack_max_nbtrcr, icepack_max_algae, icepack_max_aero
      use icepack_intfc, only: icepack_nmodal1, icepack_nmodal2
      use icepack_intfc, only: icepack_nspint_3bd, icepack_nspint_5bd
      use icepack_intfc, only: icepack_warnings_flush, icepack_warnings_aborted
      use icedrv_system, only: icedrv_system_abort

      implicit none

      ! icepack_atmo.F90
      real (kind=dbl_kind), public, &
         dimension (nx) :: &
         Cdn_atm     , & ! atm drag coefficient
         Cdn_ocn     , & ! ocn drag coefficient
                         ! form drag
         hfreebd,      & ! freeboard (m)
         hdraft,       & ! draft of ice + snow column (Stoessel1993)
         hridge,       & ! ridge height
         distrdg,      & ! distance between ridges
         hkeel,        & ! keel depth
         dkeel,        & ! distance between keels
         lfloe,        & ! floe length
         dfloe,        & ! distance between floes
         Cdn_atm_skin, & ! neutral skin drag coefficient
         Cdn_atm_floe, & ! neutral floe edge drag coefficient
         Cdn_atm_pond, & ! neutral pond edge drag coefficient
         Cdn_atm_rdg,  & ! neutral ridge drag coefficient
         Cdn_ocn_skin, & ! skin drag coefficient
         Cdn_ocn_floe, & ! floe edge drag coefficient
         Cdn_ocn_keel, & ! keel drag coefficient
         Cdn_atm_ratio   ! ratio drag atm / neutral drag atm

!-------------------------------------------------------------------
! a note regarding hi_min and hin_max(0):
! both represent a minimum ice thickness.  hin_max(0) is
! intended to be used for particular numerical implementations
! of category conversions in the ice thickness distribution.
! hi_min is a more general purpose parameter, but is specifically
! for maintaining stability in the thermodynamics.
! hin_max(0) = 0.1 m for the delta function itd
! hin_max(0) = 0.0 m for linear remapping
!
! Also note that the upper limit on the thickest category
! is only used for the linear remapping scheme
! and it is not a true upper limit on the thickness
!-------------------------------------------------------------------

      ! icepack_itd.F90
      real (kind=dbl_kind), public :: &
         hin_max(0:ncat) ! category limits (m)

      character (len=35), public :: c_hi_range(ncat)

      ! icepack_snow.F90
      real (kind=dbl_kind), public, &
         dimension (nx) :: &
         meltsliq     ! snow melt mass (kg/m^2/step-->kg/m^2/day)

      real (kind=dbl_kind), &
         dimension (nx,ncat), public, save :: &
         meltsliqn    ! snow melt mass in category n (kg/m^2)

      ! icepack_meltpond_lvl.F90
      real (kind=dbl_kind), public, &
         dimension (nx, ncat) :: &
         dhsn       , & ! depth difference for snow on sea ice and pond ice
         ffracn         ! fraction of fsurfn used to melt ipond

      ! icepack_shortwave.F90
      ! category albedos
      real (kind=dbl_kind), &
         dimension (nx, ncat) :: &
         alvdrn     , & ! visible direct albedo           (fraction)
         alidrn     , & ! near-ir direct albedo           (fraction)
         alvdfn     , & ! visible diffuse albedo          (fraction)
         alidfn         ! near-ir diffuse albedo          (fraction)

      ! albedo components for history
      real (kind=dbl_kind), &
         dimension (nx, ncat) :: &
         albicen    , & ! bare ice
         albsnon    , & ! snow
         albpndn    , & ! pond
         apeffn         ! effective pond area used for radiation calculation

      real (kind=dbl_kind), dimension (nx, ncat), public :: &
         snowfracn      ! Category snow fraction used in radiation

      ! shortwave components
      real (kind=dbl_kind), &
         dimension (nx,nilyr,ncat), public :: &
         Iswabsn        ! SW radiation absorbed in ice layers (W m-2)

      real (kind=dbl_kind), &
         dimension (nx,nslyr,ncat), public :: &
         Sswabsn        ! SW radiation absorbed in snow layers (W m-2)

      real (kind=dbl_kind), dimension (nx,ncat), &
         public :: &
         fswsfcn    , & ! SW absorbed at ice/snow surface (W m-2)
         fswthrun   , & ! SW through ice to ocean            (W/m^2)
         fswthrun_vdr, & ! vis dir SW through ice to ocean            (W/m^2)
         fswthrun_vdf, & ! vis dif SW through ice to ocean            (W/m^2)
         fswthrun_idr, & ! nir dir SW through ice to ocean            (W/m^2)
         fswthrun_idf, & ! dir dif SW through ice to ocean            (W/m^2)
         fswintn        ! SW absorbed in ice interior, below surface (W m-2)

      real (kind=dbl_kind), dimension (nx,nilyr+1,ncat), &
         public :: &
         fswpenln       ! visible SW entering ice layers (W m-2)

      ! biogeochemistry components

      real (kind=dbl_kind), dimension (nx,ncat), public :: &
         first_ice_real ! .true. = c1, .false. = c0

      logical (kind=log_kind), &
         dimension (nx,ncat), public :: &
         first_ice      ! distinguishes ice that disappears (e.g. melts)
                        ! and reappears (e.g. transport) in a grid cell
                        ! during a single time step from ice that was
                        ! there the entire time step (true until ice forms)

      real (kind=dbl_kind), &
         dimension (nx,icepack_max_nbtrcr), public :: &
         ocean_bio      ! contains all the ocean bgc tracer concentrations

      ! diagnostic fluxes
      real (kind=dbl_kind), &
         dimension (nx,icepack_max_nbtrcr), public :: &
         fbio_snoice, & ! fluxes from snow to ice
         fbio_atmice    ! fluxes from atm to ice

      real (kind=dbl_kind), dimension (nx,icepack_max_nbtrcr), public :: &
         ocean_bio_all  ! fixed order, all values even for tracers false
                        ! N(1:max_algae) = 1:max_algae
                        ! Nit = max_algae + 1
                        ! DOC(1:max_doc) = max_algae + 2 : max_algae + max_doc + 1
                        ! DIC(1:max_dic) = max_algae + max_doc + 2 : max_algae + max_doc + 1 + max_dic
                        ! chl(1:max_algae) =  max_algae + max_doc + 2 + max_dic :
                        !                   2*max_algae + max_doc + 1 + max_dic
                        ! Am =  2*max_algae + max_doc + 2 + max_dic
                        ! Sil=  2*max_algae + max_doc + 3 + max_dic
                        ! DMSPp=  2*max_algae + max_doc + 4 + max_dic
                        ! DMSPd=  2*max_algae + max_doc + 5 + max_dic
                        ! DMS  =  2*max_algae + max_doc + 6 + max_dic
                        ! PON  =  2*max_algae + max_doc + 7 + max_dic
                        ! DON(1:max_don)  =  2*max_algae + max_doc + 8 + max_dic :
                        !                    2*max_algae + max_doc + 7 + max_dic + max_don
                        ! Fed(1:max_fe) = 2*max_algae + max_doc + 8 + max_dic + max_don :
                        !                 2*max_algae + max_doc + 7 + max_dic + max_don + max_fe
                        ! Fep(1:max_fe) = 2*max_algae + max_doc + 8 + max_dic + max_don + max_fe :
                        !                 2*max_algae + max_doc + 7 + max_dic + max_don + 2*max_fe
                        ! zaero(1:max_aero) = 2*max_algae + max_doc + 8 + max_dic + max_don + 2*max_fe :
                        !                     2*max_algae + max_doc + 7 + max_dic + max_don + 2*max_fe + max_aero
                        ! humic =  2*max_algae + max_doc + 8 + max_dic + max_don + 2*max_fe + max_aero

      integer (kind=int_kind), dimension(nx,icepack_max_algae), public :: &
         algal_peak     ! vertical location of algal maximum, 0 if no maximum

      real (kind=dbl_kind), &
         dimension (nx,nblyr+1,ncat), public :: &
         Zoo            ! N losses accumulated in timestep (ie. zooplankton/bacteria)
                        ! (mmol/m^3)

      real (kind=dbl_kind), &
         dimension (nx,ncat), public :: &
         dhbr_top   , & ! brine top change
         dhbr_bot       ! brine bottom change

      real (kind=dbl_kind), &
         dimension (nx), public :: &
         grow_net   , & ! Specific growth rate (/s) per grid cell
         PP_net     , & ! Total production (mg C/m^2/s) per grid cell
         hbri           ! brine height, area-averaged for comparison with hi (m)

      real (kind=dbl_kind), &
         dimension (nx,nblyr+2,ncat), public :: &
         bphi       , & ! porosity of layers
         bTiz           ! layer temperatures interpolated on bio grid (C)

      real (kind=dbl_kind), &
         dimension (nx,ncat), public :: &
         darcy_V            ! darcy velocity positive up (m/s)

      real (kind=dbl_kind), dimension (nx), public :: &
         chl_net    , & ! Total chla (mg chla/m^2) per grid cell
         NO_net         ! Total nitrate per grid cell

      real (kind=dbl_kind), dimension (nx,nblyr+1,ncat), public :: &
         zfswin         ! Shortwave flux into layers interpolated on bio grid  (W/m^2)

      real (kind=dbl_kind), dimension (nx,nblyr+1,ncat), public :: &
         iDi        , & ! igrid Diffusivity (m^2/s)
         iki            ! Ice permeability (m^2)

      real (kind=dbl_kind), dimension (nx), public :: &
         upNO       , & ! nitrate uptake rate (mmol/m^2/d) times aice
         upNH           ! ammonium uptake rate (mmol/m^2/d) times aice

      real (kind=dbl_kind), &
         dimension(nx,max_ntrcr,ncat), public :: &
         trcrn_sw       ! bgc tracers active in the delta-Eddington shortwave
                        ! calculation on the shortwave grid (swgrid)

      real (kind=dbl_kind), &
         dimension (nx,icepack_max_nbtrcr), public :: &
         ice_bio_net, & ! depth integrated tracer (mmol/m^2)
         snow_bio_net   ! depth integrated snow tracer (mmol/m^2)

      ! floe size distribution
      real(kind=dbl_kind), dimension(nfsd), public ::  &
         floe_rad_c     ! fsd size bin centre in m (radius)

      real (kind=dbl_kind), dimension (nx), public :: &
         wave_sig_ht    ! significant height of waves (m)

      real (kind=dbl_kind), dimension (nfreq), public :: &
         wavefreq,   &  ! wave frequencies
         dwavefreq      ! wave frequency bin widths

      real (kind=dbl_kind), dimension (nx,nfreq), public :: &
         wave_spectrum  ! wave spectrum

      real (kind=dbl_kind), dimension (nx,nfsd), public :: &
         ! change in floe size distribution due to processes
         d_afsd_newi, d_afsd_latg, d_afsd_latm, d_afsd_wave, d_afsd_weld

!=======================================================================

      end module icedrv_arrays_column

!=======================================================================
