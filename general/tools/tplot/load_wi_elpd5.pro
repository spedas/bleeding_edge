;+
;PROCEDURE:	load_wi_elpd5
;PURPOSE:	
;   loads WIND 3D Plasma Experiment key parameter data for "tplot".
;
;INPUTS:
;  none, but will call "timespan" if time_range is not already set.
;KEYWORDS:
;  DATA:        Raw data can be returned through this named variable.
;  TIME_RANGE:  2 element vector specifying the time range
;RESTRICTIONS:
;  This routine expects to find the master file: 'wi_elsp_3dp_files'
;  In the directory specified by the environment variable: 'CDF_INDEX_DIR'
;  See "make_cdf_index" for more info.
;SEE ALSO: 
;  "make_cdf_index","loadcdf","loadcdfstr","loadallcdf"
;
;CREATED BY:	Davin Larson
;FILE:  load_wi_elpd4.pro
;LAST MODIFICATION: 99/05/27
;-
pro load_wi_elpd5 $
   ,trange=trange $
   ,filenames=fnames $
   ,masterfile = mfile $
   ,bartel = bartel $
   ,data=d $
   ,pos=pos $
   ,omni_flux=omni_flux $
   ,nvdata = nd $
   ,resolution=res $
   ,prefix = prefix $
   ,no_reduce=no_reduce $
   ,fits = fits $
   ,ace = ace $
   ,polar=polar




;cdfnames = ['FLUX',  'ENERGY' ,'PANGLE','MAGF','VSW']
;if keyword_set(fits) then cdfnames=[cdfnames,'DENS_CORE','TEMP_CORE', $
;  'TDIF_CORE','VEL_CORE','DENS_HALO','VTH_HALO','K_HALO','VEL_HALO','E_SHIFT', $
;  'SC_POT']

if not keyword_set(mfile) then mfile = 'wi_3dp_elpd_files'
if keyword_set(bartel) then mfile = 'wi_3dp_elpd_B_files'

loadallcdf,master=mfile,time_range=trange,cdfnames=cdfnames,data=d, $
   novarnames=novarnames,novard=nd,resolution=res,filenames=fnames

if not keyword_set(d) then return

if n_elements(ace) eq 0 then ace=1
if n_elements(omni_flux) eq 0 then omni_flux=1

if keyword_set(ace) then no_reduce=1

if data_type(prefix) eq 7 then px=prefix else px = 'elpd'

energies = transpose(d.energy)
angles = transpose(d.pangle)

store_data,px,data={x:d.time,y:transpose(d.flux,[2,0,1]), $
  v1:energies,v2:angles},dlim={ylog:1}


ang_size = size(angles)
e_size = size(energies)

n_ang = ang_size(ang_size(0))
n_nrg = e_size(e_size(0))

pdname ='elpd'

if not keyword_set(no_reduce) then begin
   for i = 0, n_nrg-1 do  reduce_pads,pdname,1,i,i
   reduce_pads,pdname,2,n_ang-2,n_ang-1
   reduce_pads,pdname,2, round((n_ang-1)/2.-.9),round((n_ang-1)/2.+.9)
   reduce_pads,pdname,2,0,1
   ylim,tnames(pdname+'-2-*'),10,1e8,1,/def
endif

if keyword_set(ace) then begin
   energy = [73.328571,102.00000, $
      142.14286,196.57143,272.00000,372.71429, $
      519.00000,712.57143,987.14286,1370.0000]
   reduce_pads,'elpd',energy
   pdname = 'elpd_'+strtrim(round(energy),2)+'eV'
   ylims = [420000., 170000., 72000., 30000., 11000., 4000., 1100., 300., 70., 20.]
   for e=0,10-1 do zlim,pdname[e],ylims[e]/5,ylims[e]*5,1  ,/default
endif

store_data,'elm',data=d.mom

store_data,'NSW',data={x:d.time,y:d.nsw}
store_data,'VSW',data={x:d.time,y:transpose(d.vsw)}
store_data,'TSW',data={x:d.time,y:d.tsw}
mass = 1836*5.6856591e-6             ; mass eV/(km/sec)^2
store_data,'VthSW',data={x:d.time,y: sqrt(2*d.tsw/mass) }
store_data,'MAGF',data={x:d.time,y:transpose(d.magf)}
store_data,'sc_pot_el',data={x:d.time,y:d.sc_pot_el}
store_data,'sc_pot_nsw',data={x:d.time,y:d.sc_pot_nsw}
if keyword_set(pos) then store_data,'wi_pos',data={x:d.time,y:transpose(d.pos)}
if keyword_set(omni_flux) then begin
   store_data,'elsp',data={x:d.time,y:transpose(d.omni_eflux/d.omni_nrg),v:transpose(d.omni_nrg)}, $
      dlim={yrange:[1e-2,1e7],ylog:1,ystyle:1,panel_size:2.}
endif
return
end

