;+
; NAME:
;   rbsp_efw_make_l2_spinfit (procedure)
;
; PURPOSE:
;   Generate level-2 EFW spin-fit waveform data. The axial boom is ignored as of
;   3/27/13.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_efw_make_l2_spinfit, sc, date, folder = folder
;
; ARGUMENTS:
;   sc: IN, REQUIRED
;         'a' or 'b'
;   date: IN, REQUIRED
;         A date string in format like '2013-02-13'
;
; KEYWORDS:
;   folder: IN, OPTIONAL
;         Default is something like
;           !rbsp_efw.local_data_dir/rbspa/l2/spinfit/2012/
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2013-03-19: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;	2013-04-24: modified by AWB to throw global flag if any of the antennas
;				are saturated or if the sc is in eclipse.
;	2013-11-25: Major changes by AWB. Now calls rbsp_efw_spinfit_vxb_subtract_crib.pro
;				
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2015-11-17 07:11:49 -0800 (Tue, 17 Nov 2015) $
; $LastChangedRevision: 19382 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_spinfit.pro $
;
;-

pro rbsp_efw_make_l2_spinfit, sc, date, folder = folder, $
                              magExtra = magExtra, version = version, save_flags = save_flags, $
                              no_spice_load = no_spice_load, no_cdf = no_cdf, testing=testing,$
                              boom_pair=bp
  
  compile_opt idl2

  rbsp_efw_init

  if n_elements(version) eq 0 then version = 1
  vstr = string(version, format='(I02)')

  if ~keyword_set(bp) then bp = '12'

  rbspx='rbsp' + strlowcase(sc[0])
  rbx = rbspx + '_'

;------------ Set up paths. BEGIN. ----------------------------

  if ~keyword_set(no_cdf) then begin

     year = strmid(date, 0, 4)
     if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
                                           'rbsp' + strlowcase(sc[0]) + path_sep() + $
                                           'l2' + path_sep() + $
                                           'spinfit' + path_sep() + $
                                           year + path_sep()

                                ; make sure we have the trailing slash on folder
     if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
     if ~keyword_set(no_cdf) then file_mkdir, folder


                                ; Grab the skeleton file.
     skeleton=rbspx+'/l2/e-spinfit-mgse/0000/'+ $
              rbspx+'_efw-l2_e-spinfit-mgse_00000000_v'+vstr+'.cdf'


     skeletonFile=file_retrieve(skeleton,_extra=!rbsp_efw)



                                ; use skeleton from the staging dir until we go live in the main data tree
                                ;skeletonFile='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton

                                ; make sure we have the skeleton CDF
     skeletonFile=file_search(skeletonFile,count=found) ; looking for single file, so count will return 0 or 1
;	if ~found then begin
;		dprint,'Could not find e-spinfit-mgse v'+vstr+' skeleton CDF, returning.'
;		return
;	endif
                                ; fix single element source file array
     skeletonFile=skeletonFile[0]

  endif


  if keyword_set(testing) then skeletonfile = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/rbspa_efw-l2_e-spinfit-mgse_00000000_v01.cdf'



;------------ Set up paths. END. ----------------------------


  timespan, date
  rbsp_efw_spinfit_vxb_subtract_crib,sc,no_spice_load=no_spice_load,/noplot,level='l2',$
                                     boom_pair=bp


;***********************************
;***********************************
;*****TEMPORARY...LOAD SINGLE-ENDED MEASUREMENTS TO CHECK FOR SATURATION
  rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='vsvy',/noclean
  get_data,rbx+'efw_vsvy',data=vsvy 
  datatimes = vsvy.x
  if ~is_struct(vsvy) then begin
     dprint,rbx+'efw_vsvy unavailable, returning.'
     return
  endif
;***********************************
;***********************************
;***********************************

  if keyword_set(no_cdf) then return


; Make quality flags
;-- epoch
  epoch_flag_times, date, 5, epochvals, timevals
  nt = n_elements(epochvals)
  flag_arr = intarr(nt, 20)
  flag_arr[*,*] = -1
; Look-up table for quality flags
;  0: global_flag
;  1: eclipse
;  2: maneuver
;  3: efw_sweep
;  4: efw_deploy
;  5: v1_saturation
;  6: v2_saturation
;  7: v3_saturation
;  8: v4_saturation
;  9: v5_saturation
; 10: v6_saturation
; 11: Espb_magnitude
; 12: Eparallel_magnitude
; 13: magnetic_wake
; 14: undefined	
; 15: undefined	
; 16: undefined	
; 17: undefined	
; 18: undefined	
; 19: undefined	

  flag_arr[*, 14:19] = -2       ; not relevant
; The following flags should be marked: 
; 1: eclipse
; 11: Espb_magnitude
; 12: Eparallel_magnitude



;*****TEMPORARY CODE*****
;set the eclipse flag in this program

; Load and overplot eclipse times 
  rbsp_load_eclipse_predict,sc,date,$
                            local_data_dir='~/data/rbsp/',$
                            remote_data_dir='http://themis.ssl.berkeley.edu/data/rbsp/'
  get_data,rbx + 'umbra',data=eu
  get_data,rbx + 'penumbra',data=ep

  eclipset = replicate(0B,n_elements(datatimes))


  flag_arr[*,1] = 0.            ;default to no eclipse
;Umbra
  if is_struct(eu) then begin
     for bb=0,n_elements(eu.x)-1 do begin
        goo = where((vsvy.x ge eu.x[bb]) and (vsvy.x le (eu.x[bb]+eu.y[bb])))
        if goo[0] ne -1 then eclipset[goo] = 1
     endfor
  endif
;Penumbra
  if is_struct(ep) then begin
     for bb=0,n_elements(ep.x)-1 do begin
        goo = where((vsvy.x ge ep.x[bb]) and (vsvy.x le (ep.x[bb]+ep.y[bb])))
        if goo[0] ne -1 then eclipset[goo] = 1
     endfor
  endif

  flag_arr[*,1] = ceil(interpol(eclipset,datatimes,timevals))

;***********************

;***********************************
;********TEMPORARY*******************
;Throw global flag during eclipse times

;goo = where(flag_arr[*,1] eq 100)
  goo = where(flag_arr[*,1] eq 1)
  if goo[0] ne -1 then flag_arr[goo,0] = 1



;***********************************
;***********************************
;**********TEMPORARY*********************
;--flag single-ended saturation
  maxvolts = 195.

  tmp_flag = replicate(0,n_elements(vsvy.x),6)
  offset = 5                    ;position in flag_arr of "v1_saturation" 


  for vv=0,5 do begin

     vbad = where(abs(vsvy.y[*,vv]) ge maxvolts)
     if vbad[0] ne -1 then tmp_flag[vbad,vv] = 1

                                ;set good values
     vgood = where(abs(vsvy.y[*,vv]) lt maxvolts)
     if vgood[0] ne -1 then tmp_flag[vgood,vv] = 0

                                ;Interpolate the bad data values onto the pre-defined flag value times
     flag_arr[*,vv+offset] = ceil(interpol(tmp_flag[*,vv],vsvy.x,timevals))

  endfor

;***********************************
;***********************************
;****TEMPORARY CODE******
;Throw the global flag if any of the single-ended flags are thrown.

  goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,6] eq 1) or (flag_arr[*,7] eq 1) or (flag_arr[*,8] eq 1))
  if goo[0] ne -1 then flag_arr[goo,0] = 1

;***********************************
;***********************************
;************************
;******************************************


;-- flag Espb_magnitude
  iflag = 11
  flag_arr[*,iflag] = 0

  get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=d
  Espb = sqrt(d.y[*,0]^2 + d.y[*,1]^2)
  Espb = interp(Espb, d.x, timevals, /ignore_nan)
  ind = where(Espb gt 500, nind)
  if nind gt 0 then flag_arr[ind,iflag] = iflag * 100

;-- flag Eparallel_magnitude
  iflag = 12
  flag_arr[*,iflag] = 0
  get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=edat
  get_data, rbx + 'mag_mgse',    data = bdat
  ex = edat.y[*,0]
  ey = edat.y[*,1]
  ez = ex * 0d
  bx = interp(bdat.y[*,0], bdat.x, edat.x, /ignore_nan)
  by = interp(bdat.y[*,1], bdat.x, edat.x, /ignore_nan)
  bz = interp(bdat.y[*,2], bdat.x, edat.x, /ignore_nan)
  btot = sqrt(bx^2 + by^2 + bz^2)
  Epara = (ex * bx + ey * by + ez * bz) / btot
  ind = where(abs(Epara) gt 500, nind)
  if nind gt 0 then flag_arr[ind,iflag] = iflag * 100

  if keyword_set(save_flags) then $
     store_data, rbx + 'efw_qual', data = {x:timevals, y:flag_arr}




;Interpolate the corotation field to be at correct times
  get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=d
  tinterpol_mxn,rbx+'E_coro_mgse',d.x,newname=rbx+'E_coro_mgse'

  split_vec,rbx+'vxb'

;Interpolate vsc x b values to be at correct times
  tinterpol_mxn,rbx+'vxb_x',d.x,newname='vxb_x'
  tinterpol_mxn,rbx+'vxb_y',d.x,newname='vxb_y'
  tinterpol_mxn,rbx+'vxb_z',d.x,newname='vxb_z'


  get_data,'vxb_x',data=vxbx
  get_data,'vxb_y',data=vxby
  get_data,'vxb_z',data=vxbz

  vxb = [[vxbx.y],[vxby.y],[vxbz.y]]



;---------------------------------------------------------------------
; Put sfit12_mgse into CDF.

; Make an empty CDF from the skeleton CDF.
; folder = '/Users/jianbao/rbsp/idlstuff/cdf/'


  year = strmid(date, 0, 4)
  mm   = strmid(date, 5, 2)
  dd   = strmid(date, 8, 2)
  datafile = folder + rbx + 'efw-l2_e-spinfit-mgse_' + year + mm + dd + $
             '_v' + vstr + '.cdf'
; skeletonFile = sktfolder + 'rbsp' + strlowcase(sc[0]) + $
;   '_efw-l2_e-spinfit-mgse_00000000_v' + vstr + '.cdf'

; filematch = file_search(datafile, count = filecount)
; if filecount eq 0 then file_copy, skeletonFile, datafile
  file_copy, skeletonFile, datafile, /overwrite ; Force to replace old file.

; Open CDF and get a CDF id.
  cdfid = cdf_open(datafile)



;***********************************
;***********************************
;***********************************
;**************TEMPORARY ********************
;Set all globally-flagged data to the ISTP fill_value

  badvs = where(flag_arr[*,0] eq 1)
  if badvs[0] ne -1 then begin

     get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=dtmp
     newflags = ceil(interpol(flag_arr[*,0],timevals,dtmp.x))
     goo = where(newflags eq 1)
     if goo[0] ne -1 then dtmp.y[goo,*] = -1.0E31
     store_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=dtmp

  endif

;***********************************
;***********************************
;***********************************
;*************************************************


;-------------------- spinfit --------------------------
; time
;tvar = rbx + 'sfit12_mgse'
  tvar = rbx+'efw_esvy_mgse_vxb_removed_spinfit'
  cdfhandle = 'epoch'
  get_data, tvar, data = d, dlim = dl
  epoch = tplot_time_to_epoch(d.x, /epoch16)
  cdf_varput, cdfid, cdfhandle, epoch

; Write sfit12
  fill_value = -1e31            ; 
  tvar = rbx+'efw_esvy_mgse_vxb_removed_spinfit'
;cdfhandle = 'e12_spinfit_mgse'
  cdfhandle = 'efield_spinfit_mgse'
  get_data, tvar, data = d, dlim = dl
  d.y[*,0] = fill_value         ; fill the axial component
  cdf_varput, cdfid, cdfhandle, transpose(d.y)

; Write vxb
;cdfhandle = 'vxb_spinfit_mgse'
  cdfhandle = 'VxB_mgse'
  cdf_varput, cdfid, cdfhandle, transpose(vxb)

; Write corotation field
  tvar = rbx+'E_coro_mgse'
  cdfhandle = 'efield_coro_mgse'
  get_data, tvar, data = d, dlim = dl
  cdf_varput, cdfid, cdfhandle, transpose(d.y)



;; Write sigma
;tvar = rbx + 'efw_esvy_spinfit_e12_sig'
;cdfhandle = 'sigma12_spinfit_mgse'
;get_data, tvar, data = d, dlim = dl
;cdf_varput, cdfid, cdfhandle, d.y

;; Write npoints
;tvar = rbx + 'efw_esvy_spinfit_e12_npoints'
;cdfhandle = 'npoints12_spinfit_mgse'
;get_data, tvar, data = d, dlim = dl
;cdf_varput, cdfid, cdfhandle, d.y

;-------------------- efw_qual --------------------------
  cdf_varput, cdfid, 'epoch_qual',epochvals
  cdf_varput, cdfid, 'e_spinfit_mgse_efw_qual', transpose(flag_arr)

;-------------------- BEB/DFB config --------------------------
;; epoch_hsk
;tvar = rbx + 'efw_esvy_ccsds_data_BEB_config'
;get_data, tvar, data = d, dlim = dl
;epoch_hsk = tplot_time_to_epoch(d.x,/epoch16)
;cdfhandle = 'epoch_hsk'
;cdf_varput, cdfid, cdfhandle, epoch_hsk

;; BEB_config
;cdfhandle = 'e_spinfit_mgse_BEB_config'
;cdf_varput, cdfid, cdfhandle, d.y

;; DFB_config
;tvar = rbx + 'efw_esvy_ccsds_data_DFB_config'
;cdfhandle = 'e_spinfit_mgse_DFB_config'
;get_data, tvar, data = d, dlim = dl
;cdf_varput, cdfid, cdfhandle, d.y



;********************
;need to populate these
;********************

;mlt, mlat, lshell, pos_gse, vel_gse, spinaxis_gse






;--------------------------------------------------
;DELETE UNNECESSARY VARIABLES FROM CDF FILE
;--------------------------------------------------

;; cdf_vardelete,cdfid,'density'
;; cdf_vardelete,cdfid,'bfield_mgse'
;; cdf_vardelete,cdfid,'bfield_model_mgse'
;; cdf_vardelete,cdfid,'bfield_minus_model_mgse'
;; cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
;; cdf_vardelete,cdfid,'efield_raw_uvw'




  cdf_close, cdfid

end
