;+
;Procedure: st_swea_load
;
;Purpose:  Loads stereo swea data
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;Example:
;   st_swea_load
;Notes:
;  This routine is (should be) platform independent.
;
;
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision: $
; $URL:$
;-



pro stereo_swea_dist3d__define,structdef=dat

nenergy = 16
nbins = 80
dims = [nenergy,nbins]
nan =!values.f_nan

dat = {stereo_swea_dist3d, inherits dist3d, $
       mode:                 0    , $
       cnfg:                 0   ,$
       nspins:               0    ,  $
       magf_name:'' , $
       data:    fltarr(dims)      , $
       energy:  fltarr(dims)    , $
       theta:   fltarr(dims)    , $
       phi:     fltarr(dims)    , $
       denergy: fltarr(dims)      , $
       dtheta:  fltarr(dims)    , $
       dphi:    fltarr(dims)    , $
 ;      domega:  fltarr(dims)     ,$
       bins:    intarr(dims)     ,$
       gf:      fltarr(dims)     ,$
       integ_t: fltarr(dims)    , $
       dt:      fltarr(dims)    , $
       deadtime:fltarr(dims)    , $
       eff:     fltarr(dims)    , $
       geomfactor: nan  ,  $
       v0:      nan,  $
       e_shift: nan ,   $
       atten:   -1   $
       }
dat.nenergy = nenergy
dat.nbins = nbins

end





pro st_swea_mag_load,probe=probe,dist_name=dist_name,magname_format=magname_format

   if not keyword_set(probe) then begin
       st_swea_mag_load,probe='a',dist_name=dist_name,magname_format=magname_format
       st_swea_mag_load,probe='b',dist_name=dist_name,magname_format=magname_format
       return
   endif

      if not keyword_set(dist_name) then dist_name='st?_SWEA_Distribution'
      dist = dist_name
      str_replace,dist,'st?','st'+probe

;   dat3d.magf_name = magname
      get_data,dist,ptr_str=ptrs
      if not keyword_set(ptrs) then begin
         dprint,'No Data found for: ',dist
         return
      endif

      if not keyword_set(magname_format) then magname_format='st?_l1_mag_sc'
      magname=magname_format
      str_replace,magname,'st?','st'+probe
      mag_rtn = data_cut(magname,*ptrs.x)

      if not keyword_set(mag_rtn) then begin
         dprint,'No Data found for: ',magname
         return
      endif
      dprint,dlevel=1,'Using ',magname,' for mag input with ',dist
      if keyword_set(mag_rtn) then begin
         rotmat1 = [[0,1d,0],[0,0,1d],[1d,0,0]]
         mag_rtn = mag_rtn # rotmat1
         if ptr_valid(ptrs.magf) then *ptrs.magf = mag_rtn else ptrs.magf = ptr_new(mag_rtn)
         store_data,dist,data=ptrs
         if 1 then begin
            tname_B = dist+'_B'
            store_data,tname_B,data={x:ptrs.x, y:ptrs.magf},dlim={colors:'bgr'}
         endif
         (*ptrs.dat3d).magf_name = magname
      endif  ; else ptr_free,ptrs.magf

end






pro st_swea_load,type=type,all=all,files=files,trange=trange, $
    verbose=verbose,burst=burst,probes=probes, $
    source_options=source_options, $
    version=ver

if not keyword_set(source_options) then begin
    stereo_init
    source_options = !stereo
endif
mystereo = source_options


scdirs = ['ahead','behind']
if not keyword_set(probes) then probes = ['a','b']
if not keyword_set(type) then type = keyword_set(burst) ? 'DISB' : 'DIST'
if not keyword_set(ver) then ver='V02'

res = 3600l*24     ; one day resolution in the files
tr = timerange(trange)
n = ceil((tr[1]-tr[0])/res)  > 1
dates = dindgen(n)*res + tr[0]

for i=0,n_elements(probes)-1 do begin
   probe = probes[i]
   pn = (byte(probe)- byte('a'))[0]   ; probe number: 0 or 1
   pref = 'st'+probe+'_SWEA' + (keyword_set(burst) ? 'b' : '')+'_'

   path = 'impact/level1/?DIR?/swea/YYYY/MM/ST?_L1_SWEA_?TYPE?_YYYYMMDD_V??.cdf'
   str_replace,path,'?DIR?',scdirs[pn]
   str_replace,path,'ST?','ST'+strupcase(probe)
   str_replace,path,'?TYPE?',type
   str_replace,path,'V??',ver
   dprint,dlevel=2,'PATH: ',path
   relpathnames= time_string(dates,tformat= path)

   files = file_retrieve(relpathnames,_extra = mystereo)
   vfm = 'Distribution V0 Energy' ; ' SWEAModeID SWEADistInterval'

   cdf2tplot,file=files,varformat=vfm,all=all,verbose=!stereo.verbose ,prefix=pref , /convert_int1   ; load data into tplot variables
;   cdfi = cdf_load_vars(files,varformat=vfm,var_type=var_type,/spdf_depend, $
;       varnames=varnames2,verbose=verbose,record=record, /convert_int1_to_int2)

   tname=pref+'Distribution'

   get_data,tname,ptr_str=ptrs
   if keyword_set(ptrs) then begin
      dprint, 'Initializing SWEA 3D data'
      dat3d = {stereo_swea_dist3d}

      nenergy = 16
      phi1 = (findgen(16)+.5)*22.5  + 90.-40.
      phip = (findgen(8)+.5) *45.   + 90.-40.
      if probe eq 'b' then begin
         phi1 += 180
         phip += 180
      endif

      theta1 = (findgen(6)-2.5)*22.5
      dtheta = replicate(22.5,6)
      if 0 then begin      ; set to 1 to fill in polar sections
        theta1[0]  = -90+22.5   &  dtheta[0] = 45.
        theta1[5]  =  90-22.5   &  dtheta[5] = 45.
      endif
      dphi1 = [2,1,1,1,1,2] * 22.5
      i8 = intarr(8)
      i16 = intarr(16)
      allphi = [phip,phi1,phi1,phi1,phi1,phip]
      i80 = [replicate(0,8),replicate(1,16),replicate(2,16),replicate(3,16),replicate(4,16),replicate(5,8)]
      alltheta = theta1[i80]
      alldphi = dphi1[i80]
      alldtheta = dtheta[i80]

      nan = !values.f_nan

      dat3d.project_name = 'STEREO '+strupcase(probe)
      dat3d.data_name = 'SWEA' + (keyword_set(burst) ? ' Burst' : '')
      dat3d.units_name = 'counts'
      dat3d.units_procedure = 'st_swea_convert_units' ; 'ste_swea_convert_units'
      dat3d.nbins = 80
      dat3d.nenergy = 16
      dat3d.magf = nan
      dat3d.sc_pot = nan
      dat3d.v0 = nan
      dat3d.mass = 511000./299792.^2
      dat3d.data = nan
      dat3d.energy = *(ptrs.v1) # replicate(1,80)
      dat3d.denergy = dat3d.energy *.2  ; should be fixed!
      dat3d.phi   = replicate(1,nenergy) # allphi
      dat3d.dphi  = replicate(1,nenergy) # alldphi
      dat3d.theta = replicate(1,nenergy) # alltheta
      dat3d.dtheta =replicate(1,nenergy) # alldtheta
      dat3d.geomfactor = 0.002 * 22.5 /360.
      dat3d.gf =  replicate(1,nenergy) # ([2,1,1,1,1,2])[i80]
      dat3d.integ_t = 2./16./7.
      dat3d.dt = dat3d.integ_t
      dat3d.bins = 1

      magfp = ptr_new()
      str_element,/add,ptrs,'magf',magfp
      str_element,/add,ptrs,'v0',ptr_new()
      str_element,/add,ptrs,'dat3d',dat3d
      store_data,tname,data=ptrs
      dprint,dlevel=2,'dat3d is re-defined;'

      st_swea_mag_load,probe=probe

      d2 = {x:ptrs.x,  y:total(*ptrs.y,2), v:ptrs.v1}
;   printdat,d2
      store_data,pref+'en',data=d2,dlimit={spec:1,zlog:1,ylog:1}
   endif
endfor


end
