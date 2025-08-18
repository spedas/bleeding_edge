;+
; NAME:
;   rbsp_efw_make_l2_esvy_uvw (procedure)
;
; PURPOSE:
;   Generate level-2 esvy (sampled at 32 S/s) in UVW coordinate system.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_efw_make_l2_esvy_uvw, sc, date, folder = folder
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
;           !rbsp_efw.local_data_dir/rbspa/l2/esvy_uvw/2012/
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2013-03-19: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2017-04-05 12:36:48 -0700 (Wed, 05 Apr 2017) $
; $LastChangedRevision: 23118 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_esvy_uvw.pro $
;
;-

pro rbsp_efw_make_l2_esvy_uvw_remove_offset, data, winlen = winlen, $
  icomp = icomp, offset = offset_out
compile_opt idl2, hidden

; winlen -- smoothing window length in seconds
if n_elements(winlen) eq 0 then winlen = 220d   ; default is 220 seconds

; icomp -- component indices for which the removal is done.
if n_elements(icomp) eq 0 then icomp = [0, 1]

rbsp_btrange, data, /structure, btr = btr, nb = nb, tind = tind

dt = median(data.x[1:*] - data.x)
seglen = winlen / dt

offset_out = data.y

for i = 0, n_elements(icomp) - 1 do begin
  ic = icomp[i]
  for ib = 0, nb - 1 do begin
    ista = tind[ib, 0]
    iend = tind[ib, 1]
    tlen = btr[ib, 1] - btr[ib, 0]
    arr = data.y[ista:iend, ic]
    narr = n_elements(arr)

    if tlen le winlen * 2d then begin
      offset = arr * 0d + median(arr)
      arr = arr - offset
    endif else begin
      nseg = long(narr / seglen)
      offset = arr * 0d + !values.f_nan
      for iseg = 0L, nseg - 1 do begin
        ista_tmp = iseg * seglen
        if iseg eq nseg - 1 then iend_tmp = narr - 1 else $
          iend_tmp = ista_tmp + seglen - 1
        imid = (ista_tmp + iend_tmp) / 2
        offset[imid] = median(arr[ista_tmp:iend_tmp])
        if iseg eq 0 then offset[0] = offset[imid]
        if iseg eq nseg-1 then offset[nseg-1] = offset[imid]
      endfor
      offset = interp(offset, findgen(narr), findgen(narr), /ignore_nan)
      arr = arr - offset
    endelse
    data.y[ista:iend, ic] = arr
    offset_out[ista:iend, ic] = offset
  endfor
endfor

end


;-------------------------------------------------------------------------------
pro rbsp_efw_make_l2_esvy_uvw, sc, date, folder = folder, $
        version = version, save_flags = save_flags, $
        save_offset = save_offset, no_spice_load = no_spice_load,testing=testing

compile_opt idl2

rbsp_efw_init

if n_elements(version) eq 0 then version = 1
vstr = string(version, format='(I02)')

;------------ Set up paths. BEGIN. ----------------------------
; if ~keyword_set(folder) then folder = '/Users/jianbao/rbsp/idlstuff/cdf/'
year = strmid(date, 0, 4)
if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
  'rbsp' + strlowcase(sc[0]) + path_sep() + $
  'l2' + path_sep() + $
  'esvy_uvw' + path_sep() + $
  year + path_sep()

; make sure we have the trailing slash on folder
if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
file_mkdir, folder

rbspx='rbsp' + strlowcase(sc[0])
rbx = rbspx + '_'

; Grab the skeleton file.
skeleton=rbspx+'/l2/e-hires-uvw/0000/'+ $
	rbspx+'_efw-l2_e-hires-uvw_00000000_v'+vstr+'.cdf'
skeletonFile=file_retrieve(skeleton,_extra=!rbsp_efw)

; use skeleton from the staging dir until we go live in the main data tree
;skeletonFile='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton	


if keyword_set(testing) then begin
	skeleton = rbspx+'_efw-l2_e-hires-uvw_00000000_v'+vstr+'.cdf'
	source_file='~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/' + skeleton
endif



	
; make sure we have the skeleton CDF
skeletonFile=file_search(skeletonfile,count=found) ; looking for single file, so count will return 0 or 1


if ~found then begin
	dprint,'Could not find e-hires-uvw v'+vstr+' skeleton CDF, returning.'
	return
endif
; fix single element source file array
skeletonFile=skeletonFile[0]
;------------ Set up paths. END. ----------------------------

timespan, date
rbsp_load_state, probe = sc, no_spice_load = no_spice_load, $
  no_eclipse = no_eclipse
;rbsp_load_state, probe = sc, no_spice_load = no_spice_load, $
;  no_eclipse = 1


errorNumber = 0L
catch, errorNumber
if (errorNumber ne 0L) then begin
  catch, /cancel
  dprint, !error_state.msg
  dprint, 'Error occurred. Exit processing.'
  return
endif


; Get l1 data.
rbsp_load_efw_waveform, probe = sc, datatype = 'esvy', coord = 'uvw'
tvar = rbx + 'efw_esvy'
if ~spd_check_tvar(tvar) then begin
  dprint, tvar, ' is not available. Exit processing.'
  return
endif


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





get_data, rbx + 'efw_esvy', data = d

; Remove NaNs. (Ignore AXB)
ind = where(finite(d.x) and finite(d.y[*,0]) and finite(d.y[*,1]), nind)
if nind eq 0 then begin
  dprint, 'No valid data. Abort.'
  return
endif
d = {x:d.x[ind], y:d.y[ind, *]}

; Remove offsets in SPB components.
rbsp_efw_make_l2_esvy_uvw_remove_offset, d, winlen = 220d, icomp=[0, 1], $
  offset = offset

if keyword_set(save_offset) then begin
  store_data, rbx + 'offset', data = {x:d.x, y:offset}
  options, rbx + 'offset', ysubtitle = '[mV/m]', colors = [2, 4, 6], $
    labels = ['u', 'v', 'w']
endif

store_data, rbx + 'efw_esvy_no_offset', data = d
options, rbx + 'efw_esvy_no_offset', colors = [2, 4, 6], $
  labels = ['u', 'v', 'w']
; return

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

flag_arr[*, 14:19] = -2 ; not relevant
; The following flags should be marked: 
; 1: eclipse
; 11: Espb_magnitude

;;-- flag eclipse
;iflag = 1
;flag_arr[*,iflag] = 0

; it seems like no_eclipse is always equal to zero.
; we should see no_eclipse==1 if we don't have an eclipse.
; we set the flag when no_eclipse=0, so this causes an
; undefined structure error when we don't actually have
; an eclipse.  at least that's what I gather.  -KK
;
; as a workaround, we're going to make sure usta and uend are
;    both structures before we proceed.  -KK

;if no_eclipse eq 0 then begin



;*****TEMPORARY CODE*****
;set the eclipse flag in this program

; Load and overplot eclipse times 
;rbsp_load_eclipse_predict,sc,date
rbsp_load_eclipse_predict,sc,date,$
	local_data_dir='~/data/rbsp/',$
	remote_data_dir='http://themis.ssl.berkeley.edu/data/rbsp/'
get_data,rbx + 'umbra',data=eu
get_data,rbx + 'penumbra',data=ep

eclipset = replicate(0B,n_elements(datatimes))


flag_arr[*,1] = 0.    ;default to no eclipse
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

flag_arr[*,1] = ceil(interpol(eclipset,vsvy.x,timevals))

;***********************


;get_data, rbx + 'umbra_sta', data = usta
;get_data, rbx + 'umbra_end', data = uend
;if is_struct(usta) and is_struct(uend) then begin
;  dprint,'FLAGGING ECLIPSE'
;  n_umbra = n_elements(usta.x)
;  for i = 0, n_umbra - 1 do begin
;    tsta = usta.x[i]
;    tend = uend.x[i]
;    ind = where(timevals ge tsta and timevals le tend, nind)
;    if nind gt 0 then flag_arr[ind, 1] = 100
;  endfor
;endif



;***********************************
;***********************************
;********TEMPORARY*******************
;Throw global flag during eclipse times

goo = where(flag_arr[*,1] eq 1)
if goo[0] ne -1 then flag_arr[goo,0] = 1


;***********************************
;***********************************
;**********TEMPORARY*********************
;--flag single-ended saturation
maxvolts = 195.

tmp_flag = replicate(0,n_elements(vsvy.x),6)
offset = 5   ;position in flag_arr of "v1_saturation" 


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
get_data, rbx + 'efw_esvy_no_offset', data = d
Espb = sqrt(d.y[*,0]^2 + d.y[*,1]^2)
Espb = interp(Espb, d.x, timevals, /ignore_nan)
ind = where(Espb gt 500, nind)
if nind gt 0 then flag_arr[ind,iflag] = iflag * 100

if keyword_set(save_flags) then $
  store_data, rbx + 'efw_qual', data = {x:timevals, y:flag_arr}

; Use timevals as epoch of L_vector
get_data, rbx + 'Lvec', data = d
nt = n_elements(timevals)
L_vector = fltarr(nt, 3)
L_vector[*,0] = interp(d.y[*,0], d.x, timevals, /ignore_nan)
L_vector[*,1] = interp(d.y[*,1], d.x, timevals, /ignore_nan)
L_vector[*,2] = interp(d.y[*,2], d.x, timevals, /ignore_nan)




;***********************************
;***********************************
;***********************************
;**************TEMPORARY ********************
;Set all globally-flagged data to the ISTP fill_value

badvs = where(flag_arr[*,0] eq 1)
if badvs[0] ne -1 then begin

	get_data,rbx+'efw_esvy',data=dtmp
	newflags = ceil(interpol(flag_arr[*,0],timevals,dtmp.x))
	goo = where(newflags eq 1)
	if goo[0] ne -1 then dtmp.y[goo,*] = -1.0E31
	store_data,rbx+'efw_esvy',data=dtmp

	get_data,rbx + 'efw_esvy_no_offset',data=dtmp
	newflags = ceil(interpol(flag_arr[*,0],timevals,dtmp.x))
	goo = where(newflags eq 1)
	if goo[0] ne -1 then dtmp.y[goo,*] = -1.0E31
	store_data,rbx + 'efw_esvy_no_offset',data=dtmp

endif

;***********************************
;***********************************
;***********************************
;*************************************************


;---------------------------------------------------------------------
; Put data into CDF.
; return

; Make an empty CDF from the skeleton CDF.

year = strmid(date, 0, 4)
mm   = strmid(date, 5, 2)
dd   = strmid(date, 8, 2)
datafile = folder + rbx + 'efw-l2_e-hires-uvw_' + year + mm + dd + $
  '_v' + vstr + '.cdf'
file_copy, skeletonFile, datafile, /overwrite; Force to replace old file.

; Open CDF and get a CDF id.
cdfid = cdf_open(datafile)


;-------------------- e_hires_uvw --------------------------
; time
tvar = rbx + 'efw_esvy'
cdfhandle = 'epoch'
get_data, tvar, data = d, dlim = dl
epoch = tplot_time_to_epoch(d.x, /epoch16)
cdf_varput, cdfid, cdfhandle, epoch

; shorting factor and boom length
cdf_varput, cdfid, 'e_shorting_factor', dl.data_att.boom_shorting_factor
cdf_varput, cdfid, 'e_boom_length', dl.data_att.boom_length

; Write e_hires_uvw
fill_value = -1e31 ; 
tvar = rbx + 'efw_esvy_no_offset'
cdfhandle = 'efield_uvw'
get_data, tvar, data = d, dlim = dl
d.y[*,2] = fill_value  ; fill the axial component
cdf_varput, cdfid, cdfhandle, transpose(d.y)

; Write e_hires_uvw_raw
fill_value = -1e31 ; 
tvar = rbx + 'efw_esvy'
cdfhandle = 'efield_raw_uvw'
get_data, tvar, data = d, dlim = dl
d.y[*,2] = fill_value  ; fill the axial component
cdf_varput, cdfid, cdfhandle, transpose(d.y)

;-------------------- efw_qual --------------------------
cdf_varput, cdfid, 'epoch_qual',epochvals
cdf_varput, cdfid, 'e_hires_uvw_efw_qual', transpose(flag_arr)

;-------------------- L_vector --------------------------
cdf_varput, cdfid, 'L_vector', transpose(L_vector)

;-------------------- BEB/DFB config --------------------------
; epoch_hsk
tvar = rbx + 'efw_esvy_ccsds_data_BEB_config'
get_data, tvar, data = d, dlim = dl
epoch_hsk = tplot_time_to_epoch(d.x,/epoch16)
cdfhandle = 'epoch_hsk'
cdf_varput, cdfid, cdfhandle, epoch_hsk

; BEB_config
cdfhandle = 'e_hires_uvw_BEB_config'
cdf_varput, cdfid, cdfhandle, d.y

; DFB_config
tvar = rbx + 'efw_esvy_ccsds_data_DFB_config'
cdfhandle = 'e_hires_uvw_DFB_config'
get_data, tvar, data = d, dlim = dl
cdf_varput, cdfid, cdfhandle, d.y

cdf_close, cdfid


end
