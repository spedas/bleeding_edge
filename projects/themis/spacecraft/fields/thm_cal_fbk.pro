;+
;Procedure: THM_CAL_FBK
;
;Purpose:  Converts raw FBK (Filter Bank)  data into physical quantities.
;keywords:
;  probe = Probe name. The default is 'all', i.e., calibrate data for all
;          available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded, 'fbh', 'fb1', 'fb2'.  default is
;          'all', to calibrate all variables.
;           due to some last minute changes it is required that you include
;  both the raw and the calibrated datatype you want for this function
;  to perform properly
;  in_suffix =  optional suffix to add to name of input data quantity, which
;          is generated from probe and datatype keywords.
;  out_suffix = optional suffix to add to name for output tplot quantity,
;          which is generated from probe and datatype keywords.
;  /VALID_NAMES; returns the allowable input names in the probe and
;  datatype variables
;   /VERBOSE or VERBOSE=n ; set to enable diagnostic message output.
;		higher values of n produce more and lower-level diagnostic messages.
;
;Example:
;   thm_cal_fbk
;
;Notes:
;	-- Changes between signal sources are handled;
;		source info from HED data should be used to get actual units of a given spectrum.
;	-- fixed, nominal calibration pars used (gains and frequency responses), rather than proper time-dependent parameters.
;--must include raw types in datatype input for calibration to
;work properly(hopefully will be fixed post-release)
;--support data must be loaded to function properly
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-08-30 17:47:46 -0700 (Tue, 30 Aug 2016) $
; $LastChangedRevision: 21775 $
; $URL $
;-

pro thm_cal_fbk, probe=probe, datatype=datatype,trange=trange, $
	in_suffix = in_suffix,out_suffix = out_suffix, valid_names=valid_names,$
  verbose = verbose

thm_init

vprobes = ['a','b','c','d','e']

fbk_sel_str = [ 'v1', 'v2', 'v3', 'v4', 'v5', 'v6','edc12', 'edc34', 'edc56', $
                     'scm1', 'scm2', 'scm3', 'eac12', 'eac34', 'eac56' ]

fbk_valid_raw = 'fb'+['1', '2', 'h']

fbk_valid_names = ssl_set_union('fb_'+ [fbk_sel_str,'hff'], fbk_valid_raw)

if not keyword_set(in_suffix) then in_suffix = ''
if not keyword_set(out_suffix) then out_suffix = ''

if arg_present( valid_names) then begin
    probe = vprobes
    datatype = fbk_valid_names
	dprint, string( strjoin( fbk_valid_names, ','), format='( "Valid names:",X,A,".")')
	return
endif

;probe validation
if n_elements(probe) eq 1 then if probe eq 'f' then vprobes = ['f']
if not keyword_set(probe) then myprobe = vprobes else myprobe = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)
if not keyword_set(myprobe) then return
if keyword_set(verbose) then dprint,  myprobe

;datatype validation
  if not keyword_set(datatype) then dts = fbk_valid_names $
  else dts = ssl_check_valid_name(strlowcase(datatype), fbk_valid_names, /include_all)
  if keyword_set(verbose) then printdat, dts, /value, 'Datatypes'

; If dts is a scalar, convert it to a 1-element array to avoid a problem
; in ssl_set_intersection.

if (size(dts,/n_dim) EQ 0) then begin
  dts = [dts]    
endif

for s=0L,n_elements(myprobe)-1L do begin
     sc = myprobe[s]

     ;only requested raw datatypes are used in this loop
     dtl = ssl_set_intersection(dts, fbk_valid_raw)

     if(size(dtl, /n_dim) eq 0) then return

     for n=0L, n_elements( dtl)-1L do begin
       name = dtl[ n]
       tplot_var = thm_tplot_var( sc, name)

    ;if data is already calibrated skip this iteration
    if thm_data_calibrated(tplot_var+in_suffix) then continue

		get_data, tplot_var+in_suffix, data=d, limit=l, dlim=dl

		; default behavior is to preserve the RAW data under a different TPLOT variable name.
		;if not keyword_set( discard_raw) then begin
		;	str_element, dl, 'data_type', 'raw', /add
		;	tplot_var_raw = string( tplot_var, 'raw', format='(A,"_",A)')
		;	store_data, tplot_var_raw, data=d, limit=l, dlimit=dl
		;endif


		; handle regular FB and HF channels differently.
		switch strlowcase( name) of
			'fb1':
			'fb2':	begin
			  tplot_var_src_root = tplot_var + '_src'  
				tplot_var_src = tplot_var_src_root + in_suffix
				get_data, tplot_var_src, data=d_src, limit=l_src, dlim=dl_src	

				; check that returned data and hed structures are structures (get_data returns 0 if no TPLOT variable exists).
				if (size( d, /type) eq 8) and (size( d_src, /type) eq 8) then begin

          ;used for calculating size of the result set array
          res_size = size(d.y, /dimensions)

					; Determine what signal sources were selected over the given time interval,
					; and apply the appropriate RAW->PHYS conversion factors.
					fb_sel = d_src.y
					find_const_intervals, fb_sel, nint=nint, ibeg=ibeg, iend=iend


          if(nint gt 0) then begin
            ;an array holding the data from each interval
            res_arr = fltarr([res_size[0:1], nint]) + !values.f_nan

            ;a list of the sources for each interval
            sel_list = fltarr(nint)

            ;this call just gets the definition of cal_pars
            thm_get_fbk_cal_pars,0,0,1,cal_pars=cp_def

            ;this constructs an array of cal pars structs
            cp_list = replicate(cp_def,nint)

          endif

					for ii=0L,nint-1L do begin
						t_hdr = [ d_src.x, !values.d_infinity]
						tbeg = t_hdr[ ibeg[ ii]]
						tend = t_hdr[ iend[ ii] + 1L]
						; find all the spectra from the beginning of the first packet of the interval,
						; to the end of the last packet of the interval
						; (actually just before the beginning of the first packet of the next interval).
						idx = where( d.x ge tbeg and d.x lt tend, icnt)

                        ; Headers are not time-shifted, so the header time  corresponds to the sample
                        ; that came roughly half a sample period earlier.  Fix up the endpoints.
						if d.x[idx[0]] ne tbeg then $
						  if idx[0] ne 0 then $
						    if (tbeg-d.x[idx[0]-1]) lt (d.x[idx[0]]-d.x[idx[0]-1]) then begin
						      idx=[idx[0]-1,idx]
						      icnt++
						    endif
						if idx[n_elements(idx)-1] ne n_elements(d.x)-1 then $
                                                  if n_elements(idx) Ge 2 then begin
						  idx=idx[0:n_elements(idx)-2]
						  icnt--
						endif

						; Calibrate each interval
						if icnt gt 0 then begin
                          thm_get_fbk_cal_pars, tbeg, tend, fb_sel[ ibeg[ ii]], cal_pars=cp
                          res_arr[ idx, *, ii] = cp.gain*((1.0 + fltarr( icnt))#cp.freq_resp[ *])*(thm_fbk_decompress(d.y[ idx, *]))
                          sel_list[ii] = fb_sel[ibeg[ii]]
                          cp_list[ii]=cp
						endif
					endfor	; loop over constant source intervals.


          ;interval collation handles a very rare case of instrument
          ;reconfiguration
          out_data = thm_collate_intervals(res_arr, sel_list)

          sel = thm_get_unique_sel(sel_list, fbk_sel_str)

          cp = thm_get_unique_cp(sel_list,fbk_sel_str,cp_list)

          ;loop over collated sources
          for i = 0, n_elements(sel)-1L do begin

            units = '<|nT|>,<|V|>, or <|mV/m|>'

            out_name = 'th' + sc + '_fb_' + sel[i] 

            ; update the DLIMIT elements to reflect RAW->PHYS transformation, coordinate system, etc.

            str_element, dl, 'data_att', data_att, success = has_data_att
            if has_data_att then begin
              str_element, data_att, 'data_type', 'calibrated', /add
            endif else data_att = { data_type: 'calibrated' }
            str_element, data_att, 'coord_sys', 'sensor', /add
            str_element, data_att, 'units', cp[i].units, /add
            str_element, data_att, 'cal_par_time', cp[i].cal_par_time, /add
            str_element, data_att, 'source_var', tplot_var, /add
            str_element, dl, 'data_att', data_att, /add
            str_element, dl, 'ytitle', string( out_name, cp[i].units, format = '(A,"!C!C[",A,"]")'), /add
            str_element, dl, 'labels', ['3072 Hz','768 Hz','192 Hz','48 Hz','12 Hz', '3 Hz'], /add
            str_element, dl, 'labflag', 1, /add
            str_element, dl, 'colors', [ 1, 2, 3, 4, 5, 6], /add
            str_element, dl, 'ysubtitle',/delete
; Don't cut off top and bottom of frequency bands
            str_element, dl, 'overlay', 0, /add
; Set option for semilog scale
            str_element, dl, 'ylog', 1, /add

; store the transformed spectra back into the original TPLOT variable.
            foo = where(dts eq ('fb_'+ sel[i]), bar)

            if(bar eq 1) then begin
              valid_idx = where(finite(out_data[*,0,i]),bar)
              if bar gt 0 then $
                store_data, out_name+ out_suffix, $
                data = {x:d.x[valid_idx], y:out_data[valid_idx, *, i], $
                        v:[2048., 512., 128., 32., 8., 2.] }, lim = l, dlim = dl
            endif
        endfor

				endif else begin	; necessary TPLOT variables not present.
					if keyword_set(verbose) then $
						dprint, $
							string( tplot_var+in_suffix, tplot_var_src, $
							format='("necessary TPLOT variables (",A,X,A,") not present for RAW->PHYS transformation.")')
				endelse
				
				; change suffix to support data
				if in_suffix ne out_suffix then begin
          tplot_var_src_out = tplot_var_src_root + out_suff
          copy_data, tplot_var_src, tplot_var_src_out
          del_data, tplot_var_src 
				endif
				break
			end	; end of { FB1, FB2} calibration clause.
		'fbh':	begin	; FBH (HF or AKR band filter).
				; check that returned data and hed structures are structures (get_data returns 0 if no TPLOT variable exists).
				if (size( d, /type) eq 8) then begin
					cp = { $
						gain:2/!pi*1e3/49.6, freq_resp:3.0, units:'V [100-400 kHz]', $
						offset:215.0, slope: 17.81, $
						cal_par_time:'2002-01-01:00:00:00' $
					}

					; convert digital log-amp output to differential volts at input to V1-V2.
					res = exp((float(d.y)-cp.offset)/cp.slope)

					; convert differential volts at input to V1-V2 to differential volts, sphere1-sphere2.
					res = cp.gain*cp.freq_resp*res

					; update the DLIMIT elements to reflect RAW->PHYS transformation, coordinate system, etc.

          units = '|mV/m|'

          str_element, dl, 'data_att', data_att, success = has_data_att
          if has_data_att then begin
            str_element, data_att, 'data_type', 'calibrated', /add
          endif else data_att = { data_type: 'calibrated' }
          str_element, data_att, 'coord_sys', 'sensor', /add
          str_element, data_att, 'units', units, /add
          str_element, data_att, 'cal_par_time', cp.cal_par_time, /add
          str_element, dl, 'data_att', data_att, /add
          str_element, dl, 'ytitle', string( 'th'+sc+'_fb_hff', units, format='(A,"!C!C[",A,"]")'), /add
          str_element, dl, 'labels', ['pk','avg'], /add
          str_element, dl, 'labflag', 1, /add
          str_element, dl, 'colors', [ 1, 2]
          str_element, dl, 'ysubtitle',/delete

					; store the transformed spectra back into the original TPLOT variable.

          foo = where(dts eq ('fb_hff'), bar)

          if(bar eq 1) then $
            store_data, 'th'+sc+'_fb_hff'+out_suffix, $
            data = { x:d.x, y:res, v:d.v }, $
            lim = l, dlim = dl

				endif else begin	; necessary TPLOT variables not present.
					if keyword_set(verbose) then $
						dprint, $
							string( tplot_var+in_suffix, $
							format='("necessary TPLOT variable (",A,") not present for RAW->PHYS transformation.")')
				endelse
			break
		end
		else:	begin	; improperly defined name of FBK quantity.
		end
	endswitch

	endfor	; loop over datatypes.
endfor	; loop over spacecraft.

end
