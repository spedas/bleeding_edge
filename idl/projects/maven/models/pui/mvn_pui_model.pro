;20160404 Ali
;This code uses analytical solutions to the equations of motion
;of pickup ions in the upstream undisturbed solar wind uniform fields
;and finds pickup ion fluxes near Mars at the location of MAVEN.
;For more info, refer to Ali's PhD thesis (2016), also see Rahmati et al. (2014, 2015, 2017, 2018)
;Note that the results are only valid when MAVEN is outside the bow shock
;and in the upstream undisturbed solar wind, when upstream drivers are available.
;This code assumes that the user has access to the MAVEN PFP data.
;mvn_pui_tplot can be used to store and plot 3d pickup ion model-data comparisons.
;please send bugs/comments to rahmati@ssl.berkeley.edu
;
;Keywords:
;   binsize: specifies the time cadense (time bin size) for simulation in seconds. if not set, default is used (32 sec)
;   trange: time range for simulation. if not set, timespan will be called
;   np: number of simulated particles in each time bin. if not set, default is used (3333 particles)
;   ns: number of simulated species. default is 2 (H and O)
;   do3d: models pickup oxygen and hydrogen 3D spectra for SWIA and STATIC, a bit slower than 1D spectra and requires more memory
;   savetplot: saves the model-data comparison tplots as png files
;   exoden: sets exospheric neutral densities to n(r)=1 cm-3 for exospheric density retrieval by a reverse method
;   nodataload: skips loading any data. use if you want to re-run the simulation with all the required data already loaded
;   nomag: skips loading mag data. if not already loaded, uses default IMF
;   noswia: skips loading swia data. if not already loaded, uses default solar wind parameters
;   noswea: skips loading swea data. if not already loaded, uses default electron impact ionization frequencies
;   nostatic: skips loading static data
;   nosep: skips loading sep data
;   noeuv: skips loading euv data. if not already loaded, uses default photoionization frequencies
;   nospice: skips loading spice kernels (use in case spice is already loaded, otherwise the code may fail)
;   nomodel: only loads the data and downsamples to the specified binsize
;   tohban: creates a tohban tplot

pro mvn_pui_model,binsize=binsize,trange=trange,np=np,ns=ns,do3d=do3d,exoden=exoden,savetplot=savetplot,nodataload=nodataload,c6=c6,d0=d0, $
  nomag=nomag,noswia=noswia,noswea=noswea,nostatic=nostatic,nosep=nosep,noeuv=noeuv,nospice=nospice,nomodel=nomodel,tohban=tohban, $
  eifactor=eifactor

  @mvn_pui_commonblock.pro ;common mvn_pui_common

  if keyword_set(tohban) then begin
    timespan,c=30 ;last 30 days
    binsize=300. ;5min time resolution
    np=3 ;just to run fast
  endif
  if ~keyword_set(binsize) then binsize=32. ;simulation resolution or cadense (seconds)
  if ~keyword_set(trange) then get_timespan,trange else timespan,trange
  if ~keyword_set(np) then np=3333; number of simulated particles (1000 is usually enough for one gyro-period; increase for better statistics)
  if ~keyword_set(ns) then ns=2; number of simulated species. default is 2 (H and O)
  if ~keyword_set(eifactor) then eifactor=10.; electron impact increase factor inside the bow shock
  if ~keyword_set(nodataload) then mvn_pui_data_load,do3d=do3d,nomag=nomag,noswia=noswia,noswea=noswea,nostatic=nostatic,nosep=nosep,noeuv=noeuv,nospice=nospice,c6=c6,d0=d0,tohban=tohban
  if np lt 2 then begin
    dprint,'number of simulated particles in each time bin must be greater than 1'
    return
  endif

  trange=time_double(trange)
  binsize=float(binsize)
  nt=1+floor((trange[1]-binsize/2.-trange[0])/binsize) ;number of time steps
  mvn_pui_aos,nt=nt,np=np,ns=ns,eifactor=eifactor,binsize=binsize,trange=trange,do3d=do3d,nomodel=nomodel,c6=c6,d0=d0 ;initializes the array of structures for time series (pui) and defines intrument constants
  mvn_pui_data_res ;changes data resolution and loads instrument pointings and puts them in arrays of structures
  if pui0.nomodel then return
  mvn_pui_data_analyze ;analyzes data: calculates ionization frequencies, etc.

  ttdtsf=1. ;time it takes to do the simulation factor
  if pui0.do3d then ttdtsf=2.4 ;2.4 times slower if you do3d!
  simpred=ceil(10.*np*nt/1000./2880.*ttdtsf) ;predicted simulation time (s)
  dprint,dlevel=2,'All data loaded successfully, the pickup ion model is now calculating...'
  dprint,dlevel=2,'The simulation should take ~'+strtrim(simpred,2)+' seconds on a modern machine.'
  simtime=systime(1) ;simulation start time, let's do this!
  ;----------------------------------------
  species=['H','O','H2']
  mamu=[1.,16.,1.]; mass of [H=1 O=16 H2=2] (amu)
  nfacs=[1.,1.,1] ;neutral density scale factor (scales according to radius, seasonal change in hydrogen density, etc.)
  ngps=[3.,1.,1.] ;a few gyro-periods required for pickup H+ and (H2)+, 1 gyroperiod is enough for pickup O+
  ngpsexoden=1. ;1 gyro-period for SWIA/STATIC reverse model
  for is=0,ns-1 do begin ;modeling pickup ions for each species
    pui0.msub=is ;species subscript (0=H, 1=O, 2=other stuff)
    pui0.mamu[is]=mamu[is]
    pui0.ngps[is]=ngps[is]
    if keyword_set(exoden) then pui0.ngps[is]=ngpsexoden
    mvn_pui_solver ;solve pickup ion trajectories
    rtot=pui2.rtot
    dprint,dlevel=2,'Pickup '+species[is]+'+ trajectories solved, now binning...'
    nfac=replicate(nfacs[is],np,nt)
    nfac[where(rtot lt 6000e3,/null)]=eifactor ;increase in electron impact ionization rate inside the bow shock due to increased electron flux
    nfac[where(rtot lt 3600e3,/null)]=0. ;no pickup source below the exobase (zero neutral density)
    rtot[where(rtot lt 3600e3,/null)]=3600e3 ;to ensure the radius doesn't go below the exobase
    nden=mvn_pui_exoden(rtot,species=species[is]) ;density (cm-3)
    nden*=nfac
    if keyword_set(exoden) then nden=1. ;assuming n(r)=1 cm-3
    dphi=mvn_pui_flux_calculator(nden)
    mvn_pui_binner,dphi ;bin the results
    dprint,dlevel=2,'Pickup '+species[is]+'+ binning done.'
    mvn_pui_sep_energy_response
  endfor
  ;------------------------------------------
  if ~keyword_set(exoden) then mvn_pui_tplot,/store,/tplot,savetplot=savetplot,tohban=tohban ;store the results in tplot variables and plot them
  dprint,dlevel=2,'Simulation time: '+strtrim(systime(1)-simtime,2)+' seconds'

end