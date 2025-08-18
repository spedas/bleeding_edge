;20160926 Ali
;creates the time array of structures containting the reduced time resolution data and model results.
;also defines instrument and model constants.

pro mvn_pui_aos,nt=nt,np=np,ns=ns,eifactor=eifactor,binsize=binsize,trange=trange,do3d=do3d,nomodel=nomodel,c6=c6,d0=d0

  if n_elements(nt) eq 0 then nt=4
  if n_elements(np) eq 0 then np=3
  if n_elements(ns) eq 0 then ns=2
  if n_elements(eifactor) eq 0 then eifactor=10.
  if n_elements(binsize) eq 0 then binsize=0.
  if n_elements(trange) eq 0 then trange=0.
  if n_elements(do3d) eq 0 then do3d=0
  if n_elements(d0) eq 0 then d0=0
  if n_elements(nomodel) eq 0 then nomodel=0

  @mvn_pui_commonblock.pro ;common mvn_pui_common

  fnan=!values.f_nan
  fnanns=replicate(fnan,ns)
  xyz=replicate(fnan,3)
  rv=replicate(fnan,6) ;trajectory coordinates (rx,ry,rz,vx,vy,vz)

  pui0={              $ ;instrument and model constants structure
    sormd:500L,       $ ;sep open response matrix dimentions
    srefa:15.5,       $ ;sep-xz (ref) angle
    scrsa:21.0,       $ ;sep-xy (cross) angle
    shcoa:30.0,       $ ;sep half conic opening angle (estimating the edge effects)
    stdea:1.083,      $ ;sep total detector effective area (cm2) from GEANT4 and CAD model
    sopeb:30L,        $ ;sep open # of energy bins
    swieb:48L,        $ ;swia # of energy bins
    staeb:64L,        $ ;static C0 # of energy bins
    sd1eb:32L,        $ ;static D1 # of energy bins
    sd1mb:8L,         $ ;static D1 # of mass bins
    sweeb:64L,        $ ;swea # of energy bins
    toteb:100L,       $ ;total flux # of energy bins
    euvwb:190L,       $ ;euv # wavelength bins
    swina:16L,        $ ;swia and static # of azimuth bins
    swine:4L,         $ ;swia and static # of elevation bins
    swiatsa:!pi*2.8,  $ ;SWIA and STATIC total solid angle <5keV (2.8pi sr)
    swidee:.14464,    $ ;SWIA dE/E
    stadee:.1633,     $ ;STATIC dE/E for C0 data product (64 energy bins, rough estimate)
    swedee:.1165,     $ ;SWEA dE/E
    totdee:.1,        $ ;total flux binning dE/E
    np:np,            $ ;number of simulated particles
    nt:nt,            $ ;number of time steps
    ns:ns,            $ ;number of species [0:hydrogen, 1:oxygen, >1:other stuff]
    eifactor:eifactor,$ ;electron impact increase factor inside the bow shock
    ngps:fnanns,      $ ;number of gyro-periods solved
    mamu:fnanns,      $ ;mass of [H=1 C=12 N=14 O=16] (amu)
    msub:0,           $ ;species subscript (0=H, 1=O)
    tbin:binsize,     $ ;time bin size (s)
    trange:trange,    $ ;trange
    do3d:do3d,        $ ;do3d
    d0:d0,            $ ;load static d0
    nomodel:nomodel,  $ ;no model, just load and reduce data cadence
    d2mmap:100,       $ ;dimensions of 2D d2m map
    minpara:2.1,      $ ;discard eflux below this factor times min eflux
    maxthre:7e7,      $ ;above this eflux, we're probably looking at solar wind protons
    rmars:3400.,      $ ;Rm (km)
    magthresh:1e-9,   $ ;low mag threshold (high error in B)
    costubthresh:.97, $ ;thetaUB > 14deg
    swiqfthresh:.9    $ ;swia moments quality threshold
  }

  pui1={ $ ;energy bins structure
    totet:exp(pui0.totdee*findgen(pui0.toteb,start=126.5,increment=-1)), $ ;total flux energy bin midpoints (312 keV to 15.6 eV)
    swiet:exp(pui0.swidee*findgen(pui0.swieb,start=69.5,increment=-1)),  $ ;SWIA (post Nov 2014) energy bin midpoints (23 keV to 26 eV)
    staet:exp(pui0.stadee*findgen(pui0.staeb,start=63.4,increment=-1)),  $ ;STATIC (mode 4) energy bin midpoints (31 keV to 1.0 eV)
    sweet:exp(pui0.swedee*findgen(pui0.sweeb,start=72.5,increment=-1)),  $ ;SWEA energy bin midpoints (4627 eV to 3.0 eV)
    sepet:replicate({sepbo:replicate(fnan,pui0.sopeb)},2)                $ ;SEP 1&2 energy table
  }

  ;**********DATA**********
  sep={rate_bo:replicate(fnan,pui0.sopeb),rate_ao:replicate(fnan,pui0.sopeb),att:byte(0),fov:xyz,dt:fnan}
  sep=replicate(sep,2) ;2 SEP's
  swim2={usw:fnan,fsw:fnan,esw:fnan,efsw:fnan,mfsw:fnan} ;solar wind parameters (speed, flux, energy, energy flux, mass flux)
  if keyword_set(swim) then swi={swim:fill_nan(swim[0]),swis:fill_nan(swis[0]),swica:fill_nan(swics[0]),swim2:swim2,dt:fnan} else swi={swim:{density:fnan,velocity_mso:xyz},swim2:swim2}
  swe={eflux:replicate(fnan,pui0.sweeb),efpot:replicate(fnan,pui0.sweeb),enpot:replicate(fnan,pui0.sweeb),eden:fnan,edenpot:fnan,scpot:fnan}
  c0={eflux:replicate(fnan,[pui0.staeb,2]),energy:replicate(fnan,pui0.staeb)}
  d1=byte(0)
  if do3d or d0 then d1={eflux:replicate(fnan,[pui0.sd1eb,pui0.swina,pui0.swine,pui0.sd1mb]),energy:replicate(fnan,pui0.sd1eb),dt:fnan,dee:fnan,mass:replicate(fnan,pui0.sd1mb)}
  sta={fov:{x:xyz,z:xyz},c0:c0,d1:d1}
  mag={payload:xyz,mso:xyz}
  euv={l2:xyz,l3:replicate(fnan,pui0.euvwb)} ;here xyz is the 3 EUVM wavelength bands

  data={sep:sep,swi:swi,swe:swe,sta:sta,mag:mag,euv:euv,scp:xyz}

  ;*********MODEL**********
  if ~nomodel then begin
    pui2={vtot:fnan,rtot:fnan,dr:fnan,ke:fnan,de:fnan,mv:fnan}
    pui2=replicate(pui2,[np,nt]) ;temporary structure
    pui3=replicate({swi:fnanns,sta:fnanns},[pui0.d2mmap,pui0.d2mmap]) ;2D mapping of pickup ion d2m ratios

    pi={nm:replicate(fnan,pui0.euvwb),tot:fnan}
    ei={en:replicate(fnan,pui0.sweeb),tot:fnan}
    ifreq={pi:pi,cx:fnan,ei:ei,tot:fnan}

    swi1d=replicate({eflux:0.},pui0.swieb)
    sta1d=replicate({eflux:0.},pui0.staeb)
    swi3d=byte(0)
    sta3d=byte(0)
    if do3d then swi3d=replicate({eflux:0.,qf:fnan,rv:rv},[pui0.swieb,pui0.swina,pui0.swine])
    if do3d then sta3d=replicate({eflux:0.,qf:fnan,rv:rv},[pui0.sd1eb,pui0.swina,pui0.swine])
    sep={incident_rate:replicate(fnan,pui0.sormd),model_rate:replicate(fnan,pui0.sopeb),rv:rv,qf:fnan}
    sep=replicate(sep,2) ;2 SEP's
    toteflux=replicate(fnan,pui0.toteb)
    fluxes={sep:sep,swi1d:swi1d,swi3d:swi3d,sta1d:sta1d,sta3d:sta3d,toteflux:toteflux}
    params={fg:fnan,tg:fnan,rg:fnan,kemax:fnan,totphi:fnan,toteph:fnan,totmph:fnan,totnnn:fnan}

    model={ifreq:ifreq,rv:replicate(fnan,[6,np]),fluxes:fluxes,params:params}
    model=replicate(model,ns)

    ;*********Data to Model Ratio**********
    d2m=replicate({sep:xyz,swi:xyz,sta:xyz},ns) ;here xyz is tot[model,data,cme] for sep, and [mean,stdev,nsample] of different energy/anode/elevations for swi and sta

    pui=replicate({data:data,model:model,d2m:d2m,centertime:0d},nt) ;model-data array of structures
  endif else pui=replicate({data:data,centertime:0d},nt) ;data array of structures
end