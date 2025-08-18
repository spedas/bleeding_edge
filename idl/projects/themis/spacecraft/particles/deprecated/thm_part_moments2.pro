;+
;PROCEDURE: thm_part_moments2
;PURPOSE: Calculates moments and spectra for themis particle distributions.
;
;SEE ALSO:
;	THM_CRIB_PART_GETSPEC, THM_PART_GETSPEC, THM_PART_GETANBINS, THM_LOAD_SST,
;   THM_LOAD_ESA_PKT, THM_FAC_MATRIX_MAKE,THM_CRIB_SST_CONTAMINATION,
;   THM_SST_REMOVE_SUNPULSE
;
;  dist_array:  Provide an array of data instead of having thm_part_getspec/thm_part_moments2 load the data directly.
;    This allows preprocessing/sanitization operations to be performed prior to moment generation.
;    See thm_part_dist_array.pro, thm_part_conv_units.pro   
;
;
;NOTE:
;  For documentation on sun contamination correction keywords that
;  may be passed in through the _extra keyword please see:
;  thm_sst_remove_sunpulse.pro or thm_crib_sst_contamination.pro
;
;MODIFIED BY:	Bryan kerr from Davin Larson's thm_part_moments
;
;  $LastChangedBy: pcruce $
;  $LastChangedDate: 2008-07-21 17:38:17 -0700 (Mon, 21 Jul 2008) $
;  $LastChangedRevision: 3298 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/spacecraft/particles/moments/thm_part_moments2.pro $
;-



;+
;HELPER Function. (Main routine below)
;
;Purpose: Checks returnd error messages from underlying routines
;         against previously returned messages. If the message 
;         is new it will be printed and added to the stored 
;         message array.
;         
;         This should allow messages generated within the loop 
;         over time to be printed once instead of hundreds or  
;         thousands of times.
;
;
;Usage: thm_part_moments2_msg, msg_ball, msg, dlevel=1
;
;Arguments:
;       msg_ball: string array of all previously printed messages
;       msg: string or string array of newly returned message(s)
;
;Keywords:
;       dlevel: Not a formal keyword, but passed through _extra
;
;Notes: This routine assumes it will get correct input, 
;       please do not disappoint it.
;
;-
pro thm_part_moments2_msg, msg_ball, msg, _extra=_extra

compile_opt idl2, hidden


;check for returned messages
if keyword_set(msg) then begin

  ;find unique messages, note ssl_set_complement returns -1 for empty set
  msg_new = ssl_set_complement(msg_ball,[msg])

  msg_new_type=size(msg_new,/type)

  ; If a message was found, msg_new will be a string that probably
  ; can't be converted to an integer, so we can't just compare
  ; to -1, we have to look at the type.

  if (msg_new_type EQ 7)  then begin
    msg_ball = [msg_ball,msg_new]
    for nm=0, n_elements(msg_new)-1 do begin
      ;most messages passed back here initially had dlevel=1
      dprint, msg_new[nm], sublevel=1, _extra=_extra
    endfor
  endif
endif

end


pro thm_part_moments2, instruments_types=instruments, probes=probes,  $  ;moments=moms,  $
                       moments_types=moments_types, $
                       verbose=verbose, $
                       trange=trange, $
                       tplotnames=tplotnames, $
                       tplotsuffix=tplotsuffix, $
                       set_opts=set_opts, $
                       scpot_suffix=scpot_suffix, mag_suffix=mag_suffix, $ ;'inputs: suffix specifying source of magdata and scpot (name - 'th?')
                       comps=comps, get_moments=get_moments,usage=usage, $
                       units=units, theta=theta, phi=phi, pitch=pitch, $
                       erange=erange, start_angle=start_angle, doangle=doangle, $
                       doenergy=doenergy, wrapphi=wrapphi, regrid=regrid, $
                       gyro=gyro, en_tnames=en_tnames, an_tnames=an_tnames, $
                       normalize=normalize, datagap=datagap, $
                     ; gui-related keywords
                       gui_flag=gui_flag, gui_statusBar=gui_statusBar, $
                       gui_historyWin=gui_historyWin, $
                       sst_cal=sst_cal,$
                       dist_array=dist_array,$
                     ; misc keywords
                       _extra=ex, test=test 


if n_elements(gui_flag) eq 0 then gui_flag=0

err_xxx = 0
Catch, err_xxx
IF (err_xxx NE 0) THEN BEGIN
  Catch, /Cancel
  if (err_xxx eq -152) AND gui_flag then begin
    mess = ['Not enough memory to process ' + strupcase(format) + ' . ' + $
            'Try reducing Regrid settings.', $
            'Moving on to next requested Data Type.']
    dum = dialog_message(mess, title='THM_PART_GETSPEC: Insufficient Memory', $
                    /center, /info)
  endif else message, /reissue_last

  RETURN
ENDIF

; begin legacy code from THM_PART_MOMENTS.PRO ==================================
defprobes = '?'
definstruments = 'p??f'
defmoments='density velocity t3 magt3'
start = systime(1)
dtype_prog = 0. ; initialize counter for progress of each data type

vprobes      = ['a','b','c','d','e']
if n_elements(probes) eq 1 then if probes eq 'f' then vprobes=['f']
vinstruments = ['peif','peef','psif','psef','peir','peer','psir','pser','peib','peeb','pseb']
vmoments     = strlowcase(strfilter(tag_names(moments_3d()),['TIME','ERANGE','MASS','VALID'],/negate))

if keyword_set(comps) or keyword_set(get_moments)  then begin
   scp = scope_traceback(/struct)
   nscp = n_elements(scp)
   print,'Keyword names have changed. Please change the calling routine: ',scp[nscp-2].routine
   usage=1
endif
if keyword_set(usage) then begin
   scp = scope_traceback(/struct)
   nscp = n_elements(scp)
   print,'Typical usage: '  ,scp[nscp-1].routine  ,", INSTRUMENT='pe?f', PROBES='a', MOMENTS='density velocity'"
   print,'Valid inputs:'
   print,'  PROBES=',"'"+vprobes+"'"
   print,'  INSTRUMENTS=',"'"+vinstruments+"'"
   print,'  MOMENTS=',"'"+vmoments+"'"
   return
endif

;probea = ssl_check_valid_name(size(/type,probes) eq 7 ? probes : '*',vprobes)

probes_a       = strfilter(vprobes,size(/type,probes) eq 7 ? probes : defprobes,/fold_case,delimiter=' ',count=nprobes)
instruments_a  = strfilter(vinstruments,size(/type,instruments)  eq 7 ? instruments  : definstruments,/fold_case,delimiter=' ',count=ninstruments)
moments_a      = strfilter(vmoments,  size(/type,moments_types)  eq 7 ? moments_types  : defmoments  ,/fold_case,delimiter=' ',count=nmoments)
tplotnames=''
if not keyword_set(tplotsuffix) then tplotsuffix=''

;if keyword_set(get_moments) then if not keyword_set(comps)  then comps = ['density','velocity','t3']
;comps = strfilter(vmoments,compmatch,/fold_case,delimiter=' ')
dprint,dlevel=2,/phelp,probes_a
dprint,dlevel=2,/phelp,instruments_a
dprint,dlevel=2,/phelp,moments_a

if keyword_set(sst_cal) then begin
  reduced_index=where(strmid(instruments_a,1,1) eq 's' and strmid(instruments_a,3,1) eq 'r',reduced_count)
  if (reduced_count gt 0) then begin
    dprint,dlevel=1,'WARNING: Beta SST calibrations should not be used with PSIR/PSER.'
  endif
endif

if size(/type,units) ne 7 then units='eflux'

; end legacy code from THM_PART_MOMENTS.PRO ====================================

facfull = 0 ;initial switch used for energy flux calculation branches


if ~ keyword_set(doangle) then doangle='none'

if ~ keyword_set(datagap) then data_gap=0 else data_gap=datagap


; Setup plotting boundaries for angular plots used by ylim
if keyword_set(start_angle) then begin
  philim = minmax(phi)
  philim += (philim[1]-philim[0])/2 * [-1,0]
  If(start_angle Ge philim[0] And start_angle Le philim[1]) Then Begin
    p_start_angle = start_angle
    p_end_angle = start_angle + phi[1] + wrapphi - phi[0]
  Endif Else Begin
    phi_mess = 'Input start_angle is out of range: '+strcompress(string(start_angle))
    dprint, dlevel=4, phi_mess
    if gui_flag then begin
      gui_statusBar -> update, phi_mess
      gui_historyWin -> update, phi_mess
    endif
    Return
  Endelse
endif else begin
   start_angle = phi[0]
   p_start_angle = phi[0]
   p_end_angle = phi[1] + wrapphi
   if doangle eq 'gyro' then begin
      start_angle = gyro[0]
      p_start_angle = gyro[0]
      p_end_angle = gyro[1] + wrapphi
   endif
endelse
th_start_angle = theta[0]
th_end_angle = theta[1]


;determine if full pitch/gyro range requested for energy spectra determination
if (pitch[1]-pitch[0]) eq 180. AND (gyro[1]-gyro[0]) ge 360. then facfull=1

;-----------------------------------------------------------------------

;begin loop over probes
for p = 0,nprobes-1 do begin

    probe= probes_a[p]
    thx = 'th'+probe

    ; begin loop over data_types
    for t=0,ninstruments-1 do begin

        next_type = 0 ; hack to help break out of loop
        instrument = instruments_a(t)
        format = thx+'_'+instrument
        if size(dist_array,/type) eq 10 then begin  ;properly formed dist_array will be an array of type pointer
          ;concatenate times into a single sequence
          for i = 0,n_elements(dist_array)-1 do begin
            times = array_concat((*dist_array[i]).time,times)
          endfor
        endif else begin
          times= thm_part_dist(format,/times,_extra=ex,sst_cal=sst_cal)
 ;        ns = n_elements(times) * keyword_set(times)
        endelse
     
        if size(times,/type) ne 5 then begin
           If(~keyword_set(trange)) Then trange = timerange()
           dprint, dlevel=1, 'No ',thx,'_',instrument,' data for time range ',time_string(trange[0]), $
                   ' to ',time_string(trange[1]),'. Continuing on to next data type.'
           
           if gui_flag then begin
             gui_mess = 'No '+thx+'_'+instrument+' data for time range '+ $
                        time_string(trange[0])+' to '+time_string(trange[1])+ $
                        '. Continuing on to next data type.'
             gui_statusBar->update, gui_mess
             gui_historyWin->update, gui_mess
           endif
;           dprint,  ''
           continue
        endif 
        
        ;time correction to point at bin center is applied for ESA, but not for SST
        if strmid(instrument,1,1) eq 's' then begin
          times += 1.5
        endif

        ; check if data exists w/in timerange set by user
        if keyword_set(trange) then tr = minmax(time_double(trange)) else tr=[1,1e20]
        ind = where(times ge tr[0] and times le tr[1],ns)

        if ns le 1 then begin ; won't bother with only 1 data point
          mess = 'WARNING: No data for '+ format +' in requested time range.'
          dprint, dlevel=1, mess
          if gui_flag then begin
            gui_statusBar->update, mess
            gui_historyWin->update, mess
          endif
        endif else begin
          dprint, dlevel=4,format,ns,' elements'
          gui_mess = format + ' ' + string(ns) + ' elements'
        endelse

        if ns gt 1  then begin ; if data exists within timerange set by user
           if keyword_set(mag_suffix) then begin ; interp mag data
                dprint,dlevel=2,verbose=verbose,'Interpolating mag data from: ',thx+mag_suffix
                tinterpol_mxn,thx+mag_suffix,times[ind],/nan_extrapolate,error=error
                if ~error then begin
                  err_mess = 'Error interpolating mag data.'
                  dprint, dlevel=1,err_mess
                  if gui_flag then begin
                    gui_statusBar->update, err_mess
                    gui_historyWin->update, err_mess
                  endif
                  return
                endif
           endif
;           if keyword_set(scpot_suffix) then begin ; interp sc potential data
;                dprint,dlevel=2,verbose=verbose,'Interpolating sc potential from:',thx+scpot_suffix
;                scpot = data_cut(thx+scpot_suffix,times[ind])
;           endif
           
           ;pointer array indicates that data is provided using new vectorized system
           if size(dist_array,/type) eq 10 then begin
             dat = (*dist_array[0])[0]
             dat_seg_index=ind[0] ;find the index of the first time from the data structure, 
                                  ;since the data is organized a little bit differently, you can't quite use a single number to index
                                  ;Instead it just uses some bounds checks to fit a 2-index loop into a 1-index one so that we can maintain backwards compatibility
                
             ;find segment and subsegment index for the beginning of the requested time interval                  
             for dat_ptr_index = 0,n_elements(dist_array)-1l do begin
               if dat_seg_index lt n_elements(*dist_array[dat_ptr_index]) then break
               dat_seg_index-=n_elements(*dist_array[dat_ptr_index])
             endfor
             
             maxnrgs=0
             for max_n_energy_index = 0,n_elements(dist_array)-1l do begin
               maxnrgs = maxnrgs > (*dist_array[max_n_energy_index])[0].nenergy
             endfor
           endif else begin 
             dat = thm_part_dist(format,index=0,_extra=ex,sst_cal=sst_cal)
             maxnrgs = strmid(instrument,1,1) eq 'e' ? 32 : 16 ;hard coding is a problem....but...*shrug*...problem fixed in new particle system
           endelse

           if keyword_set(nmoments) then moms = replicate( moments_3d(), ns )
           time = replicate(!values.d_nan,ns)
           dprint,dlevel=4,/phelp,maxnrgs
           spec = replicate(!values.f_nan, ns, maxnrgs )
           energy =  replicate(!values.f_nan,ns, maxnrgs )
           ;  double-check the dimension of these arrays??
;           phispec = replicate(!values.f_nan,ns, 28) ; might have to change the 2nd dim max
           phispec = replicate(!values.f_nan,ns, 88) ; might have to change the 2nd dim max
           ;thetaspec = replicate(!values.f_nan,ns, 28) ; might have to change the 2nd dim max
           thetaspec = replicate(!values.f_nan,ns, 88) ; might have to change the 2nd dim max
           angs_red = replicate(!values.f_nan, 128) ; max # of reduced angles
           max_angs_red = angs_red
           min_angs_red = angs_red
           last_angarray = 0

           ;xxx: ; create new FAC distribution
           if doangle eq 'pa' || doangle eq 'gyro' || keyword_set(doenergy) then begin

              nphifac = long(regrid[0])
              nthfac = long(regrid[1])

              n_anbinsfac = nphifac*nthfac
              
              ; check to make sure the xyz array sizes don't exceed 32-bit limit
              if (n_anbinsfac * ns * 3D * 8 gt 2D^31) AND gui_flag then begin
                mess = ['Regrid sizes are too large for amount of time requested.', $
                        strupcase(format) + ' will not be processed.']
                dum = dialog_message(mess, title='THM_PART_GETSPEC: Insufficient Memory', $
                                /center, /info)
                continue
              end

              ; create FAC version of phis, thetas, dphis, dthetas using REGRID input
              dphifac = 360./nphifac
              dthfac = 180./nthfac
              phifac = (indgen(nphifac*nthfac,/float) mod nphifac)*dphifac + dphifac/2
              thfac = fix(indgen(nphifac*nthfac,/float)/nphifac)*dthfac + dthfac/2 - 90
              dphifac = temporary(dphifac)*(fltarr(nphifac*nthfac)+1)
              dthfac = temporary(dthfac)*(fltarr(nphifac*nthfac)+1)
              ;new_domega = dphifac*!pi/180 * (sin(!pi/180*(thfac+dthfac/2)) - sin(!pi/180*(thfac-dthfac/2)))

              ; create tplot variable of interpolated mag data
              mat_name = thx+'_fgs_dsl2fac_mat'
              ; create rotation matrix
              thm_fac_matrix_make, thx+mag_suffix+'_interp', newname=mat_name, $
                                   pos_var_name=thx+'_state_pos',error=error, _extra=ex
              if ~error then begin
                err_mess = 'Error generating field aligned coordinate matrix.'
                dprint, dlevel=1, err_mess
                if gui_flag then begin
                  gui_statusBar->update, err_mess
                  gui_historyWin->update, err_mess
                endif
                return
              endif
              
              get_data, mat_name, data=d,limits=l,dlimits=dl

              ; create transpose of rotation matrix so FAC dist can be rotated in DSL coord
              tmat=transpose(d.y,[0,2,1])
              store_data, thx+'_fgs_fac2dsl_mat',data={x:d.x,y:tmat},limits=l,dlimits=dl
              ;identity matrix for testing
;              tmat[*,0,0] = 1
;              tmat[*,0,1] = 0
;              tmat[*,0,2] = 0
;              tmat[*,1,0] = 0
;              tmat[*,1,1] = 1
;              tmat[*,1,2] = 0
;              tmat[*,2,0] = 0
;              tmat[*,2,1] = 0
;              tmat[*,2,2] = 1
              ; create x,y,z vector of FAC angle bin centers
              r = dblarr(n_anbinsfac) + 1
              xyzfac = dblarr(ns,n_anbinsfac,3)
              xyzdsl = xyzfac
              timesfac = dblarr(ns)
              sphere_to_cart,r,thfac,phifac,vec=vec

              ; loop over time to put all FAC angles into a tplot variable
              for i=0L,ns-1 do begin  ; loop over time

                 v_s = size(vec,/dimension)
                 ;calculation is pretty straight forward
                 ;we turn x into an N x 3 x 3 so computation can be done element by element
                 tvec = rebin(vec,v_s[0],v_s[1],v_s[1])
                 newtmat = tmat[i,*,*]
                 newtmat = congrid(newtmat,v_s[0],v_s[1],v_s[1])
                 ;custom multiplication requires rebin to stack vector across rows,
                 ;not columns
                 tvec = transpose(tvec, [0, 2, 1])

                 xyzdsltemp = total(tvec*newtmat,3)

                 xyzdsl[i,*,*] = xyzdsltemp

              endfor ; end loop over time

              del_data, '*_tmp'

              ; convert rotated vectors to spherical coords
              cart_to_sphere, xyzdsl[*,*,0], xyzdsl[*,*,1], xyzdsl[*,*,2], rdsldummy, thdsl, phidsl, ph_0_360=1

              if doangle eq 'pa' || doangle eq 'gyro' then begin
                 phispec = replicate(!values.f_nan,ns, nphifac) ; might have to change the 2nd dim max
                 thetaspec = replicate(!values.f_nan,ns, nthfac) ; might have to change the 2nd dim max
                 ;theta = shift(90-pitch,1)
              endif 

           endif ; doangle eq 'pa' || 'gyro' branch
           ;** end development section for pitch angle tplot variables

           nmode=0L ; initialize number of angle modes in time range
           mindex = 0L ; initialize array of the last time index for each mode
           nangs_red = 0L ; initialize array of # of reduced angles for each mode
    
           enoise_tot = thm_sst_erange_bin_val(thx, instrument, times, sst_cal=sst_cal,_extra = ex)
           mask_tot = thm_sst_find_masking(thx,instrument,ind,sst_cal=sst_cal,_extra=ex)

           newtime = systime(1) ; for progress counter
           
           
         ;****************************
         ;xxx: Begin loop over time
         ;****************************
         
           ;aggregate all error messages generated by lower level routines
           ;this will allow each to be printed once instead of once per loop
           ;(which can yield thousands of identical ouput messages)
           msg_ball = ['']
           
           for i=0L,ns-1  do begin
             
             if size(dist_array,/type) eq 10 then begin
                
                dat = (*dist_array[dat_ptr_index])[dat_seg_index]
                dat_seg_index++
                if dat_seg_index eq n_elements(*dist_array[dat_ptr_index]) then begin
                  dat_seg_index=0
                  dat_ptr_index++
                endif
                
              endif else begin
                dat = thm_part_dist(format,index=ind[i],err_msg=err_msg, msg_suppress=1, mask_tot=mask_tot,enoise_tot=enoise_tot,_extra=ex,sst_cal=sst_cal)
              endelse
             
             ;this function will print any new messages and add them 
             ;to the msg_ball array 
             thm_part_moments2_msg, msg_ball, err_msg, dlevel=1
             
  ;quick fix to time offset problems, jmm, 28-apr-2008
             If(size(dat, /type) Eq 8) Then Begin
               mid_time = (dat.time+dat.end_time)/2.0
               jtrange = [dat.time, dat.end_time]
               dat.time = mid_time
               str_element, dat, 'end_time', /delete
               str_element, dat, 'trange', jtrange, /add_replace
             Endif
             mode = dat.mode
             ;temp fix because thm_sst_* doesn't set dat.mode
             ;  make sure this still works correctly for 'er'??
             if strmid(instrument,1,1) eq 's' then begin
                if strmid(instrument,1,1) eq 'er' then begin
                   case dat.nbins of
                      1: mode = 1
                      6: mode = 0
                   endcase
                endif else mode = ''
             endif

             ;  give energy dependence to phi here??
             avgphi=average(dat.phi,1)
             avgtheta=average(dat.theta,1)

             nrg = average(dat.energy,2)
             if i eq 0 && doangle eq 'pa' || doangle eq 'gyro' then pa_red = replicate(!values.f_nan,ns,nthfac)
             if i eq 0 && doangle eq 'pa' || doangle eq 'gyro' then paspec = replicate(!values.f_nan,ns,nthfac)
             angarr=[dat.theta,dat.phi,dat.dtheta,dat.dphi]
             
             new_ang_mode = 0 ; reset new_ang_mode flag
             
             ; Sense change in mode
             ;---------------------
             if array_equal(last_angarray,angarr) eq 0 then begin
                new_ang_mode = 1
                last_angarray = angarr
                domega = 0
                ;   store previous mode in temp structure??
                nmode++ ; increment number of angle modes w/in timerange
                if nmode gt 1 AND doangle ne 'none' then begin
                   mindex = [mindex, i-1] ; last time index of previous mode
                   ;angspec_temp = angspec[0:i-1,*]
                   angs_red_t = replicate(!values.f_nan, 128) ; max number of reduced angles possible
                   angs_red_t[0:nang_red-1] = ang_red ; array of reduced angles from previous mode
                   angs_red = [angs_red, angs_red_t]
                   
                   max_angs_red_t = replicate(!values.f_nan, 128)
                   max_angs_red_t[0:nang_red-1] = max_ang_red
                   max_angs_red = [max_angs_red, max_angs_red_t]
                   
                   min_angs_red_t = replicate(!values.f_nan, 128)
                   min_angs_red_t[0:nang_red-1] = min_ang_red
                   min_angs_red = [min_angs_red, min_angs_red_t]
                                       
                   nangs_red= [nangs_red, nang_red] ; keep track of # of reduced angles for each mode
                   
                endif
                dprint, dlevel=4,verbose=verbose,'Index=',strcompress(i),'.  New mode at: ', $
                      time_string(dat.time), '.  Mode: ', strcompress(mode), ' (', $
                      strcompress(dat.nenergy),'E x', strcompress(dat.nbins),'A)'
                ; renew angle bin maps
                thm_part_getanbins, theta=theta, phi=phi, erange=erange, $
                ;thm_part_getanbins, theta=[-90,90], phi=[0,360], erange=erange, $ ; add this later (if doangle eq 'pa' or 'gyro')
                                   data_type=instrument, en_an_bins=en_an_bins, $
                                   an_bins=an_bins, en_bins=en_bins, nrg=nrg, $
                                   avgphi=avgphi, avgtheta=avgtheta

                if new_ang_mode then begin
                  if total(an_bins) eq 0 then begin
                     err_mess='WARNING: No angle bins turned on for '+instrument+ $
                             ' data at '+time_string(dat.time)
                     dprint, dlevel=1, err_mess
                     if gui_flag then begin
                       gui_statusBar->update, err_mess
                       gui_historyWin->update, err_mess
                     endif
                  endif
                  if total(en_bins) eq 0 then begin
                     err_mess='WARNING: No energy bins turned on for '+instrument+ $
                          ' data at '+time_string(dat.time)
                     dprint, dlevel=1, err_mess
                     if gui_flag then begin
                       gui_statusBar->update, 'THM_PART_MOMENTS2: '+ err_mess
                       gui_historyWin->update, 'THM_PART_MOMENTS2: '+ err_mess
                     endif
;                     next_type = 1 ; continue to next data type
;                     break
                  endif
                endif

             endif

;             dsl_an_bins = an_bins;test code
;             dsl_en_an_bins = en_an_bins;test code

             time[i] = dat.time
             dim = size(/dimen,dat.data)
             dim_spec = size(/dimensions,spec)

             ; this IF block spans most of the for-loop over time
             ;---------------------------------------------------
             if keyword_set(units) then begin
               udat = conv_units(dat,units+'',_extra=ex)
               bins = udat.bins
               dim_data = size(/dimensions,udat.data)
               nd = size(/n_dimensions,udat.data)
               dim_bins = size(/dimensions,bins)
               if array_equal(dim_data,dim_bins) eq 0 then begin
                  bins = replicate(1,udat.nenergy) # bins   ; special case for McFadden's 3D structures
               endif
               ; Program caused arithmetic error: Floating illegal operand
               ; whenever there's a zero in total(bins ne 0,2)

               bins = bins * en_an_bins

               ; average flux over all energy bins that are "on" for each angle bin
               asp = nd eq 1 ? udat.data : total(udat.data * (bins ne 0),1) / total(bins ne 0,1) ; avg over all nrg bins
               finite_ind = where(finite(asp),COMPLEMENT=infinite_ind, NCOMPLEMENT=ninfinite)

  ;             if ninfinite gt 0 then begin
  ;                asp[infinite_ind] = 0 ; turning this on produces the zeros in pitch/gyro
  ;             endif                    ; plots when narrow phi/theta/energy ranges used.

               bad_ang = where(finite(total(udat.bins,1),/NAN),n); find sst "sunmasked" bins
               if n gt 0 then asp[bad_ang]=!values.f_nan ; re-insert NaNs for sunmasked" bins

                  ; Test #1  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  ; Test output when average flux is of all angle bins is a constant
                  if keyword_set(test) && test eq 1 then begin
                     asp = asp * 0. + 1e5
                  endif
                  ; Test #1  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

                  ; Test #3  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  ; Test output when average flux is of all angle bins is a constant
                  ; This tests energy spectra
                  if keyword_set(test) && test eq 3 then begin
                     udat.data = udat.data * 0. + 1e5
                  endif
                  ; Test #3  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



               ;xxx: do energy spectra
               ;----------------------
               if keyword_set(doenergy) then begin
                  if keyword_set(facfull) OR (dat.nbins eq 1) then begin
                  ; create standard data/angle distribution for energy spectra if no pitch/gyro
                  ; limits or distribution is single-angle

                     ; average flux over all angle bins that are "on" for each nrg channel
                     sp = nd eq 1 ? udat.data * bins  : total(udat.data * (bins gt 0),2) / total(bins gt 0,2)
    
                     ; create array of values of nrg bin centers that are are "on" for each nrg channel
                     en = nd eq 1 ? udat.energy * bins : total(udat.energy * (bins gt 0),2) / total(bins gt 0,2)
                     if nd eq 1 then begin
                        sp = (udat.data * (bins gt 0)) / (bins gt 0)
                        en = (udat.energy * (bins gt 0)) / (bins gt 0)
                     endif
                     spec[ i, 0:dim[0]-1] = sp ; en_eflux created here
    
                     ; normalize flux to between 0 and 1
                     if keyword_set(normalize) then spec[i,*] = spec[i,*]/max(spec[i,*],/NAN)
                     
                     energy[ i,0:dim[0]-1] = en ; en_eflux channels for y-axis created here
 
    
                  endif else begin ; create FAC data/angle distribution for energy spectra
 
                     ; select which fac angle bins are turned on
                     thm_part_getanbins, theta=shift(90-pitch,1), phi=gyro, erange=erange, $
                                        data_type=instrument, en_an_bins=fac_en_an_bins, $
                                        an_bins=fac_an_bins, en_bins=fac_en_bins, nrg=nrg, $
                                        avgphi=phifac, avgtheta=thfac

                     if new_ang_mode then begin
                       if total(fac_an_bins) eq 0 then begin

                          err_mess='WARNING: No FAC angle bins turned on for '+instrument+ $
                                  ' data at '+time_string(dat.time)
                          dprint, dlevel=1, err_mess
                          if gui_flag then begin
                            gui_statusBar->update, 'THM_PART_MOMENTS2: '+ err_mess
                            gui_historyWin->update, 'THM_PART_MOMENTS2: '+ err_mess
                          endif
                       endif
                       if total(fac_en_bins) eq 0 then begin
                          err_mess='WARNING: No FAC energy bins turned on for '+instrument+ $
                               ' data at '+time_string(dat.time)
                          dprint, dlevel=1, err_mess
                          if gui_flag then begin
                            gui_statusBar->update, 'THM_PART_MOMENTS2: '+ err_mess
                            gui_historyWin->update, 'THM_PART_MOMENTS2: '+ err_mess
                          endif
                       endif
                     endif
 
                     fac_en_bins = fix(fac_en_bins*average(udat.bins,2))
                     ;an_bins = fac_an_bins
                     fac_en_an_bins = fix(fac_en_bins#fac_an_bins)
                     facbins_en = fix(fac_en_bins#an_bins) ; facbin for turning on NRG channel labels
 
                     aspfac = fltarr(n_anbinsfac)
                     ;datafac = fac_en_an_bins*0. ; FAC version of energy spectra
                     datafac = fac_en_an_bins*!values.F_NAN ; FAC version of energy spectra
                     nd_fac = size(/n_dimensions,datafac) ; # of dims of FAC data array
                     anatphi=average(udat.phi,1); average native phi
                     anatth=average(udat.theta,1); average native theta
                     anatdphi=average(udat.dphi,1); average native dphi
                     anatdth=average(udat.dtheta,1); average native dtheta
                     natmaxphi = anatphi + anatdphi/2
                     natminphi = anatphi - anatdphi/2
                     natmaxth = anatth + anatdth/2
                     natminth = anatth - anatdth/2
 
                     
                     ; convert any phi's gt 360
                     gt360_ind = where(anatphi gt 360,gt360_count)
                     if gt360_count ne 0 then begin
                        anatphi[gt360_ind] = anatphi[gt360_ind] - 360
                        natmaxphi[gt360_ind] = natmaxphi[gt360_ind] - 360
                        natminphi[gt360_ind] = natminphi[gt360_ind] - 360
                     endif
                
                     facbininds=[0] ; array of fac angle bins that successfully sampled native angle bins

                     for j=0L,n_anbinsfac-1 do begin ; loop over fac angle bins
                    
                         if n_elements(anatth) eq 1 then begin
                           ;this simplifies the commented statement....which looks to be wrong to me....
                           datafac[*,*] = total(udat.data * (bins ne 0),1) / total(bins ne 0,1)
                           ;datafac[k,*] = total(udat.data * (bins ne 0),1) / total(bins ne 0,1) ;k used to loop over energy

                           continue
                         endif
                         tphidsl = phidsl[i,j]
                         tthdsl = thdsl[i,j]

                         natbinind = where(tphidsl lt natmaxphi AND tphidsl gt natminphi $
                                           AND tthdsl lt natmaxth AND tthdsl ge natminth $
                                           AND tphidsl le phi[1] AND tphidsl ge phi[0] $
                                           AND tthdsl le theta[1] AND tthdsl ge theta[0] ,n)
                                           
                       
                         if n eq 1 then begin
                           datafac[*,j] = udat.data[*,natbinind]
                         endif else if n gt 1 then begin
                           datafac[*,j] = total(udat.data[*,natbinind],2)/n
                         endif
    
                         if n eq 0 then begin ; account for wrapping around 360 or 0 degrees in phi
                            wrap360 = where(natmaxphi ge 360.,nwrap360)
                            if nwrap360 gt 0 then begin
                               wrap360ind = where(tphidsl+360. lt natmaxphi AND tphidsl+360. gt natminphi $
                                                  AND tthdsl lt natmaxth AND tthdsl ge natminth $
                                                  AND tphidsl le phi[1] AND tphidsl ge phi[0] $
                                                  AND tthdsl le theta[1] AND tthdsl ge theta[0] ,nwrap360ind)
                            endif else nwrap360ind = 0
    
                            wrap0 = where(natminphi le 0.,nwrap0)
                            if nwrap0 gt 0 then begin
                               wrap0ind = where(tphidsl-360. lt natmaxphi AND tphidsl-360. gt natminphi $
                                                AND tthdsl lt natmaxth AND tthdsl ge natminth $
                                                AND tphidsl le phi[1] AND tphidsl ge phi[0] $
                                                AND tthdsl le theta[1] AND tthdsl ge theta[0] ,nwrap0ind)
                            endif else nwrap0ind = 0
  
                            if nwrap360ind gt 0 then natbinind = wrap360ind
                            if nwrap0ind gt 0 then begin
                               if nwrap360ind gt 0 then natbinind = [natbinind, wrap0ind] else natbinind = wrap0ind
                            endif
    
                            if nwrap360ind gt 0 OR nwrap0ind gt 0 then begin
                              ;reform operation guarantees correct # of dimensions for total fx
                              datafac[*,j] = total(reform(udat.data[*,natbinind],n_elements(nrg),n_elements(natbinind)),2)/n_elements(natbinind)
                            endif else begin
                              datafac[*,j] = !values.f_nan
                            endelse
  
                         endif
                    
;This code replaced with code above  No need to loop over energy bins and looping is terribly inefficient
;As soon as the new code is verified, the commented code below should be removed
;                        for k=0L,udat.nenergy-1 do begin ; loop over energy bins
;                           if n_elements(anatth) eq 1 then begin
;                              ;aspfac[*] = total(udat.data * (bins ne 0),1) / total(bins ne 0,1)
;                              datafac[k,*] = total(udat.data * (bins ne 0),1) / total(bins ne 0,1)
;                                 ; Test #1  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;                                 ; Test output when average flux is of all angle bins is a constant
;                                 ;if keyword_set(test) && test eq 1 then begin
;                                 ;   aspfac = aspfac * 0. + 1e5
;                                 ;endif
;                                 ; Test #1  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;                              continue
;                           endif
;                           tphidsl = phidsl[i,j]
;                           tthdsl = thdsl[i,j]
;    ;                       natbinind = where(tphidsl lt natmaxphi AND tphidsl ge natminphi $
;    ;                                  AND tthdsl lt natmaxth AND tthdsl ge natminth,n)
;                           natbinind = where(tphidsl lt natmaxphi AND tphidsl gt natminphi $
;                                             AND tthdsl lt natmaxth AND tthdsl ge natminth $
;                                             AND tphidsl le phi[1] AND tphidsl ge phi[0] $
;                                             AND tthdsl le theta[1] AND tthdsl ge theta[0] ,n)
;                           if n eq 1 then begin
;                              ;aspfac[j]=asp[natbinind]
;                              datafac[k,j] = udat.data[k,natbinind]
;                           endif
; 
;                           if n gt 1 then begin
;                              ;aspfac[j] = total(asp[natbinind])/n
;                              datafac[k,j] = total(udat.data[k,natbinind])/n
;                           endif
;    
;                           if n eq 0 then begin ; account for wrapping around 360 or 0 degrees in phi
;                              wrap360 = where(natmaxphi ge 360.,nwrap360)
;                              if nwrap360 gt 0 then begin
;                                 wrap360ind = where(tphidsl+360. lt natmaxphi AND tphidsl+360. gt natminphi $
;                                                    AND tthdsl lt natmaxth AND tthdsl ge natminth $
;                                                    AND tphidsl le phi[1] AND tphidsl ge phi[0] $
;                                                    AND tthdsl le theta[1] AND tthdsl ge theta[0] ,nwrap360ind)
;                              endif else nwrap360ind = 0
;    
;                              wrap0 = where(natminphi le 0.,nwrap0)
;                              if nwrap0 gt 0 then begin
;                                 wrap0ind = where(tphidsl-360. lt natmaxphi AND tphidsl-360. gt natminphi $
;                                                  AND tthdsl lt natmaxth AND tthdsl ge natminth $
;                                                  AND tphidsl le phi[1] AND tphidsl ge phi[0] $
;                                                  AND tthdsl le theta[1] AND tthdsl ge theta[0] ,nwrap0ind)
;                              endif else nwrap0ind = 0
;    
;                              if nwrap360ind gt 0 then natbinind = wrap360ind
;                              if nwrap0ind gt 0 then begin
;                                 if nwrap360ind gt 0 then natbinind = [natbinind, wrap0ind] else natbinind = wrap0ind
;                              endif
;    
;                              if nwrap360ind gt 0 OR nwrap0ind gt 0 then begin
;                                ;aspfac[j] = average(asp[natbinind])
;                                datafac[k,j] = average(udat.data[k,natbinind])
;                              endif else begin
;                                ;aspfac[j] = !values.f_nan
;                                datafac[k,j] = !values.f_nan
;                              endelse
;    
;                           endif
;                           
;    ;                       if aspfac[j] eq 0.0 then begin
;    ;                             print, j
;    ;                       endif
; 
;                        endfor ; loop over energy bins
                        
                        if natbinind[0] ne -1 then facbininds = [facbininds, j]
                        
                     endfor ; loop over fac angle bins
 
 
                     facbins = fac_en_an_bins
                     if n_elements(facbininds) gt 1 then $
                       facbininds = facbininds[1:n_elements(facbininds)-1] $
                       else facbininds = [0]
                     fac_an_bins_inds = where(fac_an_bins)
                     ; # of native bins that are sampled by fac grid and in requested pitch/gyro ranges
                     fac_ang_on = ssl_set_intersection(facbininds, fac_an_bins_inds)
                     n_fac_ang_on = n_elements(fac_ang_on)
                     if (n_fac_ang_on eq 1) && (fac_ang_on eq -1) then n_fac_ang_on=0
    
                     ; average flux over all angle bins that are "on" for each nrg channel
                     ; divides only by number of fac angle bins that successfully sampled a native dsl bin
                     sp = nd_fac eq 1 ? datafac * facbins : total(datafac * (facbins gt 0),2,/NAN) / n_fac_ang_on / fac_en_bins
                    
                     ; create array of values of nrg bin centers that are are "on" for each nrg channel
                     en = nd eq 1 ? udat.energy * facbins_en : total(udat.energy * (facbins_en gt 0),2) / total(facbins_en gt 0,2)

                     if nd_fac eq 1 then sp = (datafac * (facbins gt 0)) / (facbins gt 0)
                     if nd eq 1 then en = (udat.energy * (facbins_en gt 0)) / (facbins_en gt 0)

                     spec[ i, 0:dim[0]-1] = sp ; en_eflux created here
    
                     ; normalize flux to between 0 and 1
                     if keyword_set(normalize) then spec[i,*] = spec[i,*]/max(spec[i,*],/NAN)
                     
                     energy[ i,0:dim[0]-1] = en ; en_eflux channels for y-axis created here
 
 
                     ;asp = aspfac
                     ;udat_init=fltarr(udat.nenergy)+1
                     ;udatphi = udat_init#phifac
                     ;udattheta = udat_init#thfac
                     ;udatdphi = udat_init#dphifac
                     ;udatdtheta = udat_init#dthfac
 
                  endelse ; create FAC data/angle distribution for energy spectra
               endif ; doenergy


               udatphi = udat.phi
               udattheta = udat.theta
               udatdphi = udat.dphi
               udatdtheta = udat.dtheta
               
               ;xxx: create FAC data/angle distribution for pa/gyro spectra (computation done later)
               ;-------------------------------------------------------
               if doangle eq 'pa' || doangle eq 'gyro' then begin 

                 ; select which fac angle bins are turned on
                 thm_part_getanbins, theta=shift(90-pitch,1), phi=gyro, erange=erange, $
                                    data_type=instrument, en_an_bins=fac_en_an_bins, $
                                    an_bins=fac_an_bins, en_bins=fac_en_bins, nrg=nrg, $
                                    avgphi=phifac, avgtheta=thfac

                 if new_ang_mode then begin
                   if total(fac_an_bins) eq 0 then begin

                      err_mess='WARNING: No FAC angle bins turned on for '+instrument+ $
                              ' data at '+time_string(dat.time)
                      dprint, dlevel=1, err_mess
                      if gui_flag then begin
                        gui_statusBar->update, 'THM_PART_MOMENTS2: '+ err_mess
                        gui_historyWin->update, 'THM_PART_MOMENTS2: '+ err_mess
                      endif
                   endif
                   if total(fac_en_bins) eq 0 then begin
                      err_mess='WARNING: No FAC energy bins turned on for '+instrument+ $
                           ' data at '+time_string(dat.time)
                      dprint, dlevel=1, err_mess
                      if gui_flag then begin
                        gui_statusBar->update, 'THM_PART_MOMENTS2: '+ err_mess
                        gui_historyWin->update, 'THM_PART_MOMENTS2: '+ err_mess
                      endif
                   endif
                 endif

                 an_bins = fac_an_bins
                 en_bins = fac_en_bins
                 ;en_an_bins = fac_en_an_bins

                 aspfac = fltarr(n_anbinsfac)
                 anatphi=average(udat.phi,1); average native phi
                 anatth=average(udat.theta,1); average native theta
                 anatdphi=average(udat.dphi,1); average native dphi
                 anatdth=average(udat.dtheta,1); average native dtheta
                 natmaxphi = anatphi + anatdphi/2
                 natminphi = anatphi - anatdphi/2
                 natmaxth = anatth + anatdth/2
                 natminth = anatth - anatdth/2

                 ; convert any phi's gt 360
                 gt360_ind = where(anatphi gt 360,gt360_count)
                 if gt360_count ne 0 then begin
                   anatphi[gt360_ind] = anatphi[gt360_ind] - 360
                   natmaxphi[gt360_ind] = natmaxphi[gt360_ind] - 360
                   natminphi[gt360_ind] = natminphi[gt360_ind] - 360
                 endif

                 for j=0L,n_anbinsfac-1 do begin ; loop over fac angle bins
                   if n_elements(anatth) eq 1 then begin
                     aspfac[*] =total(udat.data * (bins ne 0),1) / total(bins ne 0,1)
  
                     continue
                   endif
                   tphidsl = phidsl[i,j]
                   tthdsl = thdsl[i,j]
  ;                 natbinind = where(tphidsl lt natmaxphi AND tphidsl ge natminphi $
  ;                            AND tthdsl lt natmaxth AND tthdsl ge natminth,n)
                   natbinind = where(tphidsl lt natmaxphi AND tphidsl gt natminphi $
                                     AND tthdsl lt natmaxth AND tthdsl ge natminth $
                                     AND tphidsl le phi[1] AND tphidsl ge phi[0] $
                                     AND tthdsl le theta[1] AND tthdsl ge theta[0] ,n)
                   if n eq 1 then begin
                     aspfac[j]=asp[natbinind]
                   endif

                   if n gt 1 then begin
                     aspfac[j] = total(asp[natbinind])/n
                   endif

                   if n eq 0 then begin ; account for wrapping around 360 or 0 degrees in phi
                     wrap360 = where(natmaxphi ge 360.,nwrap360)
                     if nwrap360 gt 0 then begin
                       wrap360ind = where(tphidsl+360. lt natmaxphi AND tphidsl+360. gt natminphi $
                                          AND tthdsl lt natmaxth AND tthdsl ge natminth $
                                          AND tphidsl le phi[1] AND tphidsl ge phi[0] $
                                          AND tthdsl le theta[1] AND tthdsl ge theta[0] ,nwrap360ind)
                     endif else nwrap360ind = 0

                     wrap0 = where(natminphi le 0.,nwrap0)
                     if nwrap0 gt 0 then begin
                       wrap0ind = where(tphidsl-360. lt natmaxphi AND tphidsl-360. gt natminphi $
                                        AND tthdsl lt natmaxth AND tthdsl ge natminth $
                                        AND tphidsl le phi[1] AND tphidsl ge phi[0] $
                                        AND tthdsl le theta[1] AND tthdsl ge theta[0] ,nwrap0ind)
                     endif else nwrap0ind = 0

                     if nwrap360ind gt 0 then natbinind = wrap360ind
                     if nwrap0ind gt 0 then begin
                       if nwrap360ind gt 0 then natbinind = [natbinind, wrap0ind] else natbinind = wrap0ind
                     endif

                     if nwrap360ind gt 0 OR nwrap0ind gt 0 then begin
                       aspfac[j] = average(asp[natbinind])
                     endif else begin
                       aspfac[j] = !values.f_nan
                     endelse

                   endif

   ;                if aspfac[j] eq 0.0 then begin
   ;                      print, j
   ;                endif

                 endfor ; loop over fac angle bins


                 asp = aspfac
                 udat_init=fltarr(udat.nenergy)+1
                 udatphi = udat_init#phifac
                 udattheta = udat_init#thfac
                 udatdphi = udat_init#dphifac
                 udatdtheta = udat_init#dthfac

               endif ; create FAC data/angle distribution for pa/gyro spectra



               ;xxx: compute phi or gyro angle spectra
               ;-------------------------------
               if doangle eq 'phi' || doangle eq 'gyro' then begin

                 ; Test #2  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                 ; Test output when average flux is of all angle bins is a constant
                 if keyword_set(test) && test eq 2 then begin
                    ;asp = fltarr(88) + 1e5 ;test remove when done
                    ;asp = fltarr(64) + 1e5 ;test remove when done
                    asp =fltarr(6) + 1e5 ;test remove when done
                    asp[1] = 0
                    ;asp[2:5] = 1e7
                    ;asp[3:4] = 1e3
                    ;asp[0:1] = 0
                    ;aspi1=[0,4,8,9,16,17];,24,40,56,72]
                    ;aspi1=[0,1,2,3,4,5,6,7]
                    ;aspi2=[4,5,6,7]
                    ;asp(0:3) = 1e4
                    ;asp(16:19) = 1e6
                    ;aspi3=[1,2,3,4,10,11,18,19,5,6,7,8,30,62,78,46,31,63,77,47,28,60,76,44]
                    ;asp[aspi3] = 0
                  endif
                 ; Test #2  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

                 asp_on = intarr(n_elements(asp))
                 asp_on_ind = where(asp gt 0,n_asp_on_ind) ; index of angle bin where spectra has been calc'd
  

                 if (total(an_bins) gt 0) && (total(en_bins) gt 0) && (n_asp_on_ind gt 0) then begin
                 ; if angle & nrg bins exist in reqested ranges and spectra exist for 1 or more angle bins
                   an_bins_ind = where(an_bins eq 1)

                   en_binsi = where(en_bins gt 0, n_en_binsi)
                   dphi = average(udatdphi[en_binsi,*],1)
                   dtheta = average(udatdtheta[en_binsi,*],1)

                   asp_on[asp_on_ind] = 1
                   ;aphi = average(udatphi[en_binsi,*],1) ; avg phi of nrgies collected in each angle bin
                   aphi = average(udatphi,1) ; avg phi of all available nrgies in each angle bin
                   ;maxphi = max(udatphi[en_binsi,*],dimension=1, min=minphi) ; min/max phi of energies collected in each angle bin
                   ; use this if you want the min/max phi of each bin regardless of nrgies picked
                   maxphi = max(udatphi,dimension=1, min=minphi)
                   if strmid(instrument,1,1) eq 's' AND doangle eq 'phi' then begin
                     maxphi = aphi + 11 ; based on SST angular response FWHM of ~22 degrees
                     minphi = aphi - 11 ; based on SST angular response FWHM of ~22 degrees
                   endif else begin
                     if array_equal(maxphi, aphi) then begin
                       maxphi = aphi + dphi/4 ;the 4 is arbitrary since angular response not in dist.
                       minphi = aphi - dphi/4 ;the 4 is arbitrary since angular response not in dist.
                     endif
                   endelse
  
                   ; convert any phi's gt 360
                   gt360_ind = where(aphi gt 360,gt360_count)
                   if gt360_count ne 0 then begin
                     aphi[gt360_ind] = aphi[gt360_ind] - 360
                     maxphi[gt360_ind] = maxphi[gt360_ind] - 360
                     minphi[gt360_ind] = minphi[gt360_ind] - 360
                   endif
  
                   atheta = average(udattheta[en_binsi,*],1) ; avg theta of energies collected in each angle bin
                   aphi_on = aphi[an_bins_ind] ; array of aphi reduced to only bins that are on
                   maxphi_on = maxphi[an_bins_ind]
                   minphi_on = minphi[an_bins_ind]
                   atheta_on = atheta[an_bins_ind] ; array of atheta reduced to only bins that are on
                   dphi_on = average(udatdphi[0,an_bins_ind],1)
                   dtheta_on = average(udatdtheta[0,an_bins_ind],1)
                   ; might have to test the fact that SORT might treat identical
                   ; elements differently on different OS's won't affect output
                   phi_dat_ind = uniq(aphi_on, sort(aphi_on)); udatphi bin #'s of unique and sorted phi's
                   aphi_red = aphi_on[phi_dat_ind] ; sort and pick out unique avgphi's
                   maxphi_red = maxphi_on[phi_dat_ind]
                   minphi_red = minphi_on[phi_dat_ind]
                   atheta_red = atheta_on[phi_dat_ind] ; sort and pick out unique avgtheta's
                   dphi_red = dphi_on[phi_dat_ind]
                   nphi = n_elements(aphi_red)
  
                   for a = 0L,nphi-1 do begin
                     ; look for bins that fall in current bin's primary angle range
                     if minphi_red[a] lt 0 then begin
                       combins = where((aphi*an_bins + dphi*an_bins/2) gt minphi_red[a] $
                                        AND (aphi*an_bins - dphi*an_bins/2) lt maxphi_red[a])
                       wrapbin = where((aphi*an_bins + dphi*an_bins/2) ge 360,nwrapbin) ;account for bins with boundary at 360 degrees
                       if nwrapbin gt 0 then begin
                         if (aphi[wrapbin]*an_bins[wrapbin] + $
                           dphi[wrapbin]*an_bins[wrapbin]/2) gt (minphi_red[a] + 360) then begin
                           combins = [combins, wrapbin]
                         endif
                       endif
  
                       large_dphi_ind = where((aphi[combins] + dphi[combins]/2) gt maxphi_red[a] $
                                           AND (aphi[combins] - dphi[combins]/2) lt minphi_red[a], $
                                           nlarge_dphi, COMPLEMENT=small_dphi_ind, $
                                           NCOMPLEMENT=nsmall_dphi)
                     endif else begin
                       combins = where((aphi*an_bins + dphi*an_bins/2) gt minphi_red[a] $
                                        AND (aphi*an_bins - dphi*an_bins/2) lt maxphi_red[a], ncombins)
                       wrapbin = where((aphi*an_bins + dphi*an_bins/2) ge 360,nwrapbin) ;account for bins with boundary at 360 degrees
                       fullbins = where(dphi*an_bins eq 360, nfullbins)
                       if ncombins eq 1 AND nfullbins gt 0 then begin
                         combins = [fullbins, combins]
                         large_dphi_ind = indgen(n_elements(combins))
                         nlarge_dphi = n_elements(large_dphi_ind)
                         nsmall_dphi = 0
                       endif else begin
  
                         large_dphi_ind = where((aphi[combins] + dphi[combins]/2) gt maxphi_red[a] $
                                          AND (aphi[combins] - dphi[combins]/2) lt minphi_red[a], $
                                          nlarge_dphi, COMPLEMENT=small_dphi_ind, $
                                          NCOMPLEMENT=nsmall_dphi)
                       endelse
                     endelse
  
;beginnings of some code to replace the code above...this code is simpler, but it doesnt' produce exactly identical results...although it isn't obviously wrong
;                     combins = where(((aphi*an_bins + dphi*an_bins/2)) gt minphi_red[a] $
;                                        AND ((aphi*an_bins - dphi*an_bins/2)) lt maxphi_red[a], ncombins)
;                                        
;                     if ncombins gt 0 then begin          
;                       large_dphi_ind = where((aphi[combins] + dphi[combins]/2) gt maxphi_red[a] $
;                                    AND (aphi[combins] - dphi[combins]/2) lt minphi_red[a], $
;                                    nlarge_dphi, COMPLEMENT=small_dphi_ind, $
;                                    NCOMPLEMENT=nsmall_dphi)
;                     
;                     endif else begin
;                       nlarge_dphi = 0
;                       nsmall_dphi = 0
;                     endelse
                                    
                     ;for some cases, there can be no "large dphi"(what constitutes a large dphi is never described or defined in comments)
                     ;If these cases occur code will crash in absence of the following check
                     if nlarge_dphi gt 0 then begin
                       phispec_c = fltarr(nlarge_dphi)
                     endif else begin
                       phispec_c = 0
                     endelse
                     
                     del_omega_rad_c = phispec_c
  
                     if nsmall_dphi gt 0 then begin
                       phispec_b = fltarr(nsmall_dphi)
                       del_omega_rad_b = phispec_b
  
                       for b = 0,nsmall_dphi-1 do begin
                         temp_ind = combins[small_dphi_ind[b]]
                         if strmid(instrument,1,1) eq 's' then begin
                           ;hw = min(dphi_red) / 4 ; fix in absence of sst phi-collection range
                           hw = (maxphi_red[a] - minphi_red[a])/2
                         endif else begin
                           ; use this if avg phi is based on nrgies collected in each angle bin
                           ;hw = (maxphi_red[a] - minphi_red[a] + $
                           ;     (maxphi_red[a] - minphi_red[a]) / (n_en_binsi - 1)) / 2
                           hw = (maxphi_red[a] - minphi_red[a] + $
                                (maxphi_red[a] - minphi_red[a]) / (dat.nenergy - 1)) / 2
                         endelse
                         if aphi_red[a] gt aphi[temp_ind] then begin
                           w = (aphi[temp_ind] + dphi[temp_ind]/2) - (aphi_red[a] - hw)
                         endif else if aphi_red[a] lt aphi[temp_ind] then begin
                           if (aphi[temp_ind] + dphi[temp_ind]) gt aphi_red[a] $
                             AND (aphi[temp_ind] - dphi[temp_ind]) gt aphi_red[a] then begin
                             w = aphi_red[a] + hw + 360 - $
                                 (aphi[temp_ind] + dphi[temp_ind]/2)
                           endif else begin
                             w = (aphi_red[a] + hw) - (aphi[temp_ind] - dphi[temp_ind]/2)
                           endelse
                         endif else begin
                           w = 2 * hw
                         endelse
                         th0_rad = (atheta[temp_ind] + dtheta[temp_ind]/2.)*!pi/180.
                         th1_rad = (atheta[temp_ind] - dtheta[temp_ind]/2.)*!pi/180.
                         w_rad = w * !pi/180.
                         del_omega_rad_b[b] = w_rad * (sin(th0_rad) - sin(th1_rad))
                         if ~ finite(asp[temp_ind]) then del_omega_rad_b[b] = 0.
                         phispec_b[b] = asp[temp_ind] * del_omega_rad_b[b]
                         ;phispec_b[b] = asp[temp_ind] * finite(asp[temp_ind]);testing line
                       endfor
  
                     endif else begin
                       phispec_b = 0.
                       del_omega_rad_b = 0.
                     endelse
  
                     for c = 0,nlarge_dphi-1 do begin
                       temp_ind = combins[large_dphi_ind[c]]
                       th0_rad = (atheta[temp_ind] + dtheta[temp_ind]/2.)*!pi/180.
                       th1_rad = (atheta[temp_ind] - dtheta[temp_ind]/2.)*!pi/180.
                       if strmid(instrument,1,1) eq 's' then begin
                         w = maxphi_red[a] - minphi_red[a] ; fix in absence of sst phi-collection range
                       endif else begin
                         ; use this if avg phi is based on nrgies collected in each angle bin
                         ;w = maxphi_red[a] - minphi_red[a] + $
                         ;    (maxphi_red[a] - minphi_red[a]) / (n_en_binsi - 1)
                         w = maxphi_red[a] - minphi_red[a] + $
                             (maxphi_red[a] - minphi_red[a]) / (dat.nenergy - 1)
                       endelse
                       w_rad = w * !pi/180
                       del_omega_rad_c[c] = w_rad * (sin(th0_rad) - sin(th1_rad))
                       if ~ finite(asp[temp_ind]) then del_omega_rad_c[c] = 0.
                       phispec_c[c] = asp[temp_ind] * del_omega_rad_c[c]
                       ;phispec_c[c] = asp[temp_ind] * finite(asp[temp_ind]);testing line
                     endfor
  
                     del_omega_rad2 = total(del_omega_rad_b) + total(del_omega_rad_c)
                     phispec[i,a] = (total(phispec_b,/NAN) + total(phispec_c,/NAN)) / del_omega_rad2
                     ;phispec[i,a] = (total(phispec_b,/NAN) + total(phispec_c,/NAN));testing line
                   endfor ; loop over phi's
  
                 endif else begin ; branch if no spectra in any angle bins
                   ;all bins have zero spectra data
                   if i gt 0 then begin
                     nphi_bins = n_elements(phispec[i-1])
                     phispec[i] = fltarr(nphi_bins)
                   endif else begin
                     phispec[i,*] = 0; the initial size of the phispec array
                     nphi = n_elements(phispec[i,*])
                     aphi_red = fltarr(nphi)
                     dphi_red = fltarr(nphi)
                     maxphi_red = fltarr(nphi)
                     minphi_red = fltarr(nphi)
                   endelse
                 endelse
  
                 ; normalize flux
                 if keyword_set(normalize) then phispec[i,*] = phispec[i,*]/max(phispec[i,*],/NAN)
  
                 angspec = phispec
                 ang_red = aphi_red
                 nang_red = n_elements(ang_red)
                 max_ang_red = maxphi_red
                 min_ang_red = minphi_red
                 ; end compute phi angle spectra




               ;xxx: compute pitch angle or theta spectra
               ;--------------------------------------
               endif else if doangle eq 'pa' || doangle eq 'theta' then begin
     ;            endif else if doangle eq 'theta' then begin
     ;            ; compute theta angle spectra

      ;           ;test section
      ;           asp = fltarr(88) + 1e5 ;test remove when done
      ;           asp = fltarr(64) + 1e5 ;test remove when done
                 ;asp =fltarr(6) + 1e5 ;test remove when done
                 ;asp[0] = 1e7
                 ;asp[3:4] = 0
      ;           ;aspi1=[0,4,8,9,16,17];,24,40,56,72]
      ;           aspi1=[0,1,2,3,4,5,6,7]
      ;           aspi2=[4,5,6,7]
      ;           asp(0:3) = 1e4
      ;           asp(16:19) = 1e6
      ;           aspi3=[1,2,3,4,10,11,18,19,5,6,7,8,30,62,78,46,31,63,77,47,28,60,76,44]
      ;           asp[aspi3] = 0

                 asp_on = intarr(n_elements(asp))
                 asp_on_ind = where(asp gt 0,n_asp_on_ind) ; index of angle bin where spectra has been calc'd
                 if (total(an_bins) gt 0) && (total(en_bins) gt 0) && (n_asp_on_ind gt 0) then begin
                 ; if angle & nrg bins exist in reqested ranges and spectra exist for 1 or more angle bins
                   an_bins_ind = where(an_bins eq 1, n_an_bins)

                   en_binsi = where(en_bins gt 0, n_en_binsi)
                   dphi = average(udatdphi[en_binsi,*],1)
                   dtheta = average(udatdtheta[en_binsi,*],1)

                   asp_on(asp_on_ind) = 1
                   aphi = average(udatphi,1) ; avg phi of all available nrgies in each angle bin

                   ;maxphi = max(udatphi[en_binsi,*],dimension=1, min=minphi) ; min/max phi of energies collected in each angle bin
                   ; use this if you want the min/max phi of each bin regardless of nrgies picked
                   maxphi = max(udatphi,dimension=1, min=minphi)

                   if strmid(instrument,1,1) eq 's' AND doangle eq 'theta' then begin
                     maxphi = aphi + 11 ; based on SST angular response FWHM of ~22 degrees
                     minphi = aphi - 11 ; based on SST angular response FWHM of ~22 degrees
                   endif else begin
                     if array_equal(maxphi, aphi) then begin
                       maxphi = aphi + dphi/4 ;the 4 is arbitrary since angular response not in dist.
                       minphi = aphi - dphi/4 ;the 4 is arbitrary since angular response not in dist.
                     endif
                   endelse

                   atheta = average(udattheta,1) ; avg theta of energies collected in each angle bin
                   ; use this if you want the min/max phi of each bin regardless of nrgies picked
                   maxtheta = max(udattheta,dimension=1, min=mintheta)
                   if array_equal(maxtheta, atheta) then begin
                     maxtheta = atheta + dtheta/2
                     mintheta = atheta - dtheta/2
                   endif

                   ; convert any phi's gt 360
                   gt360_ind = where(aphi gt 360,gt360_count)
                   if gt360_count ne 0 then begin
                     aphi(gt360_ind) = aphi(gt360_ind) - 360
                     maxphi(gt360_ind) = maxphi(gt360_ind) - 360
                     minphi(gt360_ind) = minphi(gt360_ind) - 360
                   endif

                   aphi_on = aphi(an_bins_ind) ; array of aphi reduced to only bins that are on
                   maxphi_on = maxphi(an_bins_ind)
                   minphi_on = minphi(an_bins_ind)
                   atheta_on = atheta(an_bins_ind) ; array of atheta reduced to only bins that are on
                   maxtheta_on = maxtheta(an_bins_ind)
                   mintheta_on = mintheta(an_bins_ind)
                   dphi_on = average(udatdphi(0,an_bins_ind),1)
                   dtheta_on = average(udatdtheta(0,an_bins_ind),1)
                   ; might have to test the fact that SORT might treat identical
                   ; elements differently on different OS's won't affect output
                   phi_dat_ind = uniq(aphi_on, sort(aphi_on)); udatphi bin #'s of unique and sorted phi's
                   theta_dat_ind = uniq(atheta_on, sort(atheta_on)); udattheta bin #'s of unique and sorted theta's
                   aphi_red = aphi_on(phi_dat_ind) ; sort and pick out unique avgphi's
                   atheta_red = atheta_on(theta_dat_ind) ; sort and pick out unique avgtheta's
                   maxphi_red = maxphi_on(phi_dat_ind)
                   minphi_red = minphi_on(phi_dat_ind)
                   maxtheta_red = maxtheta_on(theta_dat_ind)
                   mintheta_red = mintheta_on(theta_dat_ind)
                   dphi_red = dphi_on(phi_dat_ind)
                   nphi = n_elements(aphi_red)
                   dtheta_red = dtheta_on(theta_dat_ind)
                   ntheta = n_elements(atheta_red)

                   for a = 0L,ntheta-1 do begin
               
                      ;NOTE this code replaces an older version which was substantially different.
                      ;The old version of the code contained an error which would improperly order theta results for SST data.
                      ;If you want to view the old version.  Look at TDAS revision 7838 or older. (Sept 27,2010 or older) 
                   
                     ;finds bins with each particular theta using sorted list of uniq theta values
                     temp_idx = where(atheta*an_bins eq atheta_red[a],c)
                     
                     ;for each theta scale the average flux based on the area of each bin in steradians
                     if c gt 0 then begin
                     
                       ;this is a fix to account for some feature of ESA.
                       ;It was copied over from the older version of this code.
                       ;Assume it is correct, but there were no comments with the original
                       if strmid(instrument,1,1) eq 's' then begin
                         w = (maxphi_red - minphi_red) * !dtor ;Width along phi in radians(should be array of values for each phi bin @ this theta)
                       endif else begin
                         w = (maxphi_red - minphi_red + $
                              (maxphi_red - minphi_red) / (dat.nenergy - 1)) *!dtor ;Width along phi in radians(should be array of values for each phi bin @ this theta)
                       endelse
                       
                       th0_rad = (atheta[temp_idx] + dtheta[temp_idx]/2.)*!dtor ;theta boundary one in radians (should be array of values for each phi bin @ this theta)
                       th1_rad = (atheta[temp_idx] - dtheta[temp_idx]/2.)*!dtor ;theta boundary two in radians (should be array of values for each phi bin @ this theta)
                       
                       del_omega_rad = w * (sin(th0_rad) - sin(th1_rad)) ;area of each  bin(should be array of values for each phi bin @ this theta)
                       idx = where(~finite(asp[temp_idx]),c)  ;If nans are in data values, don't include bin area in total.
                       if c gt 0 then del_omega_rad[idx] = 0. ;This check was copied from original code.  Ultimately, this turns some of the final output values into missing data.  Without this check they end up 0. 
                                   
                       ;Calculate average over phi for each theta, weighted by bin area in steradians.                                               
                       thetaspec[i,a] = total(asp[temp_idx]*del_omega_rad,/nan)/total(del_omega_rad,/nan)
                     endif
                         
                         ;End of replacement code section.
                         
                   endfor ; loop over theta's

                 endif else begin
                   ;all bins have zero spectra data
                    thetaspec[i,*] = 0; the initial size of the thetaspec array
                    ntheta = n_elements(thetaspec[i,*])   

                    if i eq 0 then begin
                      atheta_red = fltarr(ntheta)
                      dtheta_red = fltarr(ntheta)
                      maxtheta_red = fltarr(ntheta)
                      mintheta_red = fltarr(ntheta)
                    endif
                   
                 endelse

                 ; normalize flux
                 if keyword_set(normalize) then thetaspec[i,*] = thetaspec[i,*]/max(thetaspec[i,*],/NAN)

                 angspec = thetaspec
                 ang_red = atheta_red
                 nang_red = n_elements(ang_red)
                 max_ang_red = maxtheta_red
                 min_ang_red = mintheta_red

                 if doangle eq 'pa' then begin ; convert to pitch angle
                   finspec = where(finite(thetaspec[i,*]),complement=infspec,ncomplement=ninfspec)
                   real_nan = where(finite(thetaspec[i,*], /NAN, sign=-1), nreal_nan) ;look for negative NaNs created
                   if nreal_nan gt 0 then ninfspec = ninfspec - nreal_nan             ;where thetaspec[i,a] is written
                   if ninfspec gt 0 AND ntheta lt nthfac then begin

                     blanks = replicate(!values.f_nan,ninfspec)
                     p_angleb = [90-atheta_red,blanks]
                     pa_sort_indb = sort(p_angleb)
                     pa_redb = p_angleb[pa_sort_indb]
                     npab = n_elements(pa_redb)

                     p_angle = 90-atheta_red
                     pa_sort_ind = sort(p_angle)
                     pa_red = p_angle[pa_sort_ind]
                     npa = n_elements(pa_red)
                    
                     paspec[i,*] = thetaspec[i,pa_sort_indb]
                     
                   endif else begin

                     p_angle = 90-atheta_red
                     pa_sort_ind = sort(p_angle)
                     pa_red = p_angle[pa_sort_ind]
                     npa = n_elements(pa_red)
                     npab = npa
                     paspec[i,0:n_elements(pa_sort_ind)-1] = thetaspec[i,pa_sort_ind]
                   endelse

                   angspec=paspec
                   ; might have to fix this for stitching as well.

                 endif

                 ; end compute theta angle spectra
                 ; end compute pitch angle spectra testing version


               endif else if doangle eq 'none' then begin
                 angspec = 0
;                 continue


               endif else begin
                 dprint, dlevel=1, 'ERROR: ', doangle, ' is not a valid spectrogram
                 doangle = 'none'
               endelse



             endif ; keyword_set(units)
             
     ;        if  nmoments ne 0 then begin
     ;;          dat.dead = 0
     ;          if keyword_set(magf) then  dat.magf=magf[i,*]
     ;          if keyword_set(scpot) then dat.sc_pot=scpot[i]
     ;          moms[i] = moments_3d( dat , domega=domega )
     ;        endif

           ; begin progress counter             
             newtime = systime(1)
             if ~keyword_set(lasttime) then lasttime = newtime
             
             if 10. gt (newtime-lasttime) then continue
             dtype_prog = float(i)/ns
             dtype_prog_msg = format+' is ' + strcompress(string(long(100*dtype_prog)),/remove) $
                              + '% done.'
             if gui_flag then gui_statusBar->update, dtype_prog_msg
             dprint, dlevel=2, dtype_prog_msg
             ;dprint,dwait=10.,format,i,'/',strcompress(ns);,'    ',time_string(dat.time)   ; update every 10 seconds
             
             lasttime = newtime
           ; end progress counter
           endfor
         ;*************************
         ;End loop over time
         ;*************************

           if next_type then continue

           
           if doangle eq 'phi' || doangle eq 'theta' then begin
              finite_ind = where(finite(angspec),COMPLEMENT=infinite_ind, NCOMPLEMENT=ninfinite)
              if ninfinite gt 0 then begin
                 angspec[infinite_ind] = 0
              endif
           endif
              
           if doangle eq 'phi' || doangle eq 'theta' || doangle eq 'gyro' then begin   
              ; setup for stitching different modes together
              mindex = [mindex, i-1] ; last time index of previous mode
              angs_red_t = replicate(!values.f_nan, 128) ; max number of reduced angles possible
              angs_red_t[0:nang_red-1] = ang_red ; array of reduced angles from previous mode
              angs_red = [angs_red, angs_red_t]
              nangs_red= [nangs_red, nang_red]
              maxangs_red = max(nangs_red) ; max number of reduce angles
              
              max_angs_red_t = replicate(!values.f_nan, 128)
              max_angs_red_t[0:nang_red-1] = max_ang_red
              max_angs_red = [max_angs_red, angs_red_t]
                            
              min_angs_red_t = replicate(!values.f_nan, 128)
              min_angs_red_t[0:nang_red-1] = min_ang_red
              min_angs_red = [min_angs_red, angs_red_t]
              
             
              angs_red = reform(temporary(angs_red),128,nmode+1)
              angs_red = transpose(temporary(angs_red))
              
              max_angs_red = reform(temporary(max_angs_red),128,nmode+1)
              max_angs_red = transpose(temporary(max_angs_red))
              
              min_angs_red = reform(temporary(min_angs_red),128,nmode+1)
              min_angs_red = transpose(temporary(min_angs_red))
             
              angspect = angspec ; create copy of angspec
              ; end setup for stitching different modes together
           endif


           ;test section
           ;angspec[*,10]=0
           ;angspec[1,3]=0.1
           ;end test section

           if not keyword_set(no_tplot) then begin
              prefix = thx+'_'+instrument+'_'
              suffix = '_'+strlowcase(units)+tplotsuffix
              if keyword_set(units) then begin
                 ; case for units strings:
                  case strlowcase(units) of 
                      'compressed' : units_str = units
                      'counts' : units_str = units
                      'rate'   : units_str = 'counts/sec'
                      'crate'  : units_str = 'counts (dead-time-corrected)/sec'
                      'eflux'  : units_str = 'eV/(cm^2-sec-sr-eV)'
                      'flux'   : units_str = '1/(cm^2-sec-sr-eV)'
                      'df'     : units_str = '1/(cm^3-(km/s)^3)'
                      else: begin
                          dprint, dlevel=1, 'Unknown starting units: ',units
                      end
                  endcase

                 ; beg create tplot vars for energy spectra
                 if keyword_set(doenergy) then begin
                   en_tname = prefix+'en'+suffix
; I'm disabling this block of code.  I'm not at all clear why this code should remove data whose sum over time is le 0.
; Better that missing data actually shows up in the output.  pcruce 09/5/2012
;                   spec_ind = where(total(spec,1,/NAN) gt 0,n)
;
;                   if n eq 0 then begin
;                   ; no data. spec array is empty
;                     err_mess = 'No '+strupcase(en_tname)+' data for current settings.'
;                     dprint, dlevel=1, err_mess
;                     if gui_flag then begin
;                       gui_statusBar->update, err_mess
;                       gui_historyWin->update, 'THM_PART_MOMENTS2: ' + err_mess
;                     endif
;                     continue
;                   endif
;
;                   if n eq 1 then begin
;                   ; spec array has only one element
;                      store_data,en_tname, data={x:time, y:spec[*,spec_ind], v:energy[*,spec_ind]},$
;                                 dlim={spec:0,zlog:1,ylog:1,datagap:data_gap,data_att:{units:units_str}}
;                      ;options,en_tname, 'max_gap_interp',30,/def
;                   endif else begin
;                      store_data,en_tname, data={x:time, y:spec[*,spec_ind[0]:spec_ind[n-1]], $
;                                 v:energy[*,spec_ind[0]:spec_ind[n-1]]}, dlim={spec:1,zlog:1,ylog:1, $
;                                 datagap:data_gap,data_att:{units:units_str}}
;                   endelse
                             
                   store_data,en_tname, data={x:time, y:spec, v:energy}, dlim={spec:1,zlog:1,ylog:1, datagap:data_gap,data_att:{units:units_str}}
     
                   if size(en_tnames,/type) eq 0 then en_tnames = en_tname $
                      else en_tnames = [en_tnames, en_tname]
                 endif ; end create tplot vars for energy spectra


                 ;XXX: begin create tplot vars for phi/gyro angle spectra
                 if doangle eq 'phi' || doangle eq 'gyro' then begin
                   an_tname = prefix + 'an_'+strlowcase(units)+'_' + doangle + tplotsuffix
                   ; beg re-sort of phi's so they go from 0-360
                   
                   ; beg mode stitching code
                   fbnd_angspec = replicate(!values.f_nan,i,maxangs_red + 2)
                   nang_fbnd_angspec = n_elements(fbnd_angspec[0,*]) ; # of angles in final boundary angspec
                   fbnd_aphi_red = fbnd_angspec
                   aphi_redt = aphi_red
                   
                   for m=1,nmode do begin ; loop over angle modes
                     
                     aphi_red = angs_red[m,0:nangs_red[m]-1]
                     maxphi_red = max_angs_red[m,0:nangs_red[m]-1]
                     minphi_red = min_angs_red[m,0:nangs_red[m]-1]
                     nphi = nangs_red[m]
                     mns = mindex[m] - mindex[m-1]         ; number of samples for each mode
                     if m eq 1 then mns = mns + 1          ; account for first time index number = 0
                     ;angspect = angspec[mindex[m-1]:mindex[m],*] ; create sep. angspec 4 each mode ;This line was commented out by someone for some reason not explained.
                     ;angspect = angspec[mindex[m-1]+1:mindex[m],0:nphi-1] ; create sep. angspec 4 each mode ;This line caused a crash in a case where the first two entries in mindex where [0,0] date 2010-02-10/06:00:00-09:00:00 Probe D PSIR
                  
                     ;the line below was just overwriting the previous one
                     ;if m eq 1 then angspect = angspec[mindex[m-1]:mindex[m],0:nphi-1] ; create sep. angspec 4 each mode
                     ;
                     ;This code makes my brain hurt
                     ;
                     ;My solution is to combine the two previous lines in an if-else block, although I have no idea what it is doing...or why
                     if m eq 1 then begin
                       angspect = angspec[mindex[m-1]:mindex[m],0:nphi-1] ; create sep. angspec 4 each mode
                     endif else begin
                       angspect = angspec[mindex[m-1]+1:mindex[m],0:nphi-1]
                     endelse
                     
                     ;
                     ; end mode stitching code
                     
                     ps_size = n_elements(angspect[0,*])
                     if ps_size gt nphi then begin
                        angspect = angspect[*,0:nphi-1]
                        ps_size = n_elements(angspect[0,*])
                     endif
  
                     if keyword_set(start_angle) then begin
                        if start_angle lt 0 then begin
                           aphi_red = aphi_red - 360
                           st_ind = min(where(start_angle lt aphi_red))
                           aphi_red = shift(aphi_red, -st_ind)
                           too_low_ind = where(start_angle gt aphi_red)
                           aphi_red[too_low_ind] = aphi_red[too_low_ind] + 360
                        endif else begin
                           st_ind = min(where(start_angle le aphi_red))
                           aphi_red = shift(aphi_red, -st_ind)
                           too_low_ind = where(start_angle gt aphi_red,n)
                           if n gt 0 then aphi_red[too_low_ind] = aphi_red[too_low_ind] + 360
                           ;aphi_red[too_low_ind] = aphi_red[too_low_ind] + 360
                        endelse
                     endif else st_ind = 0
  
                     if nd gt 1 then begin
                        if size(/n_dimensions,angspect) eq 1 then begin
                           angspect = reform(angspect,n_elements(angspect),1)
                        endif else begin
                           angspect = shift(angspect, 0, -st_ind)
                        endelse
                     endif
  
                     nwrap = 0
                     ; begin append wrapped phi bins
                     wrap_ind = where((aphi_red gt start_angle) AND $
                                      (aphi_red lt (start_angle + wrapphi)), nwrap)
;Guard against nwrap being too large, this can happen if phi_max is large
                     If(nwrap Ge n_elements(aphi_red)) Then Begin
                       nwrap = n_elements(aphi_red)-1
                       wrap_ind = wrap_ind[0:nwrap-1]
;                       wrap_mess = 'Wrap Index Max has been reset to avoid out-of-bounds Error. '
;                       dprint, wrap_mess
;                       if gui_flag then begin
;                         gui_statusBar -> update, wrap_mess
;                         gui_historyWin -> update, wrap_mess
;                       endif
                     Endif
                     
                     if (wrapphi gt 0) AND (nwrap gt 0) then begin
;                     if wrapphi gt 0 then begin
;                        wrap_ind = where((aphi_red gt start_angle) AND $
;                                        (aphi_red lt (start_angle + wrapphi)),nwrap)
                        wrap_angspec = replicate(0.,ns, ps_size+nwrap)
                        wrap_angspec[*,0:nphi-1] = angspect
                        wrap_angspec[*,nphi:nphi + nwrap-1] = angspect[*,0:nwrap-1]
  
                        wrap_ps_size = n_elements(wrap_angspec[0,*])
                        wrap_aphi_red = replicate(0.,wrap_ps_size)
                        wrap_aphi_red[0:nphi-1] = aphi_red
                        wrap_aphi_red[nphi:nphi + nwrap-1] = aphi_red[0:nwrap-1] + 360
  
                        bnd_angspec = replicate(0.,mns,wrap_ps_size+2)
                        bnd_angspec[*,1:wrap_ps_size] = wrap_angspec
                        bnd_angspec[*,0] = angspect[*,ps_size-1]; might have to make this zeros or NaNs
                        bnd_angspec[*,wrap_ps_size+1] = angspect[*,nwrap] ; what if angspect[*,nwrap] doesn't exist?
  
                        bnd_aphi_red = replicate(0.,wrap_ps_size+2)
                        bnd_aphi_red[1:wrap_ps_size] = wrap_aphi_red
                        bnd_aphi_red[0] = aphi_red[ps_size-1] - 360
                        bnd_aphi_red[wrap_ps_size+1] = aphi_red[nwrap] + 360
                        
                        ; begin stitching code
                        nbnd_angs_red = n_elements(bnd_aphi_red)
                        if nang_fbnd_angspec lt nbnd_angs_red then begin
                           ; enlarge angle dimension of final boundary angspec
                           fbnd_angspect = replicate(!values.f_nan, i, nbnd_angs_red) ; create temp var
                           fbnd_aphi_redt = fbnd_angspect
                           fbnd_angspect[*,0:nang_fbnd_angspec-1] = fbnd_angspec        ; fill temp var
                           ;fbnd_aphi_redt[*,0:nang_fbnd_angspec-1] = bnd_aphi_red
                           fbnd_aphi_redt[*,0:nang_fbnd_angspec-1] = fbnd_aphi_red
                           fbnd_angspec = temporary(fbnd_angspect)            ; fill resized angspec array
                           fbnd_aphi_red = temporary(fbnd_aphi_redt)
                           nang_fbnd_angspec = nbnd_angs_red                  ; resize nang_fbnd_angspec
                        endif
                        ; end stitching code
                     endif else begin ; begin append wrapped phi bins if necceary
                        if (phi[1] - phi[0]) lt 360 then begin
                           bnd_angspec = angspect
                           bnd_aphi_red = aphi_red
                           p_start_angle = aphi_red[0] ; might have to add '- dphi_red[0]/2
                           p_end_angle = aphi_red[nphi-1] ; might have to add '+ dphi_red[nphi-1]/2
                           if n_elements(angspect[0,*]) eq 1 then begin
                              ;p_start_angle = minphi_red
                              ;p_end_angle = maxphi_red
                              bnd_angspec = replicate(0.,mns,ps_size+nwrap+2)
                              bnd_angspec[*,1:nphi] = angspect
                              bnd_angspec[*,0] = angspect
                              bnd_angspec[*,nphi+1] = angspect
                              ; end get y boundaries correct
                              ; look for phi angles gt 360 and wrap around to 0
                              bnd_aphi_red = replicate(0.,ps_size+2)
                              bnd_aphi_red[1:nphi] = aphi_red
                              bnd_aphi_red[0] = minphi_red
                              bnd_aphi_red[nphi+1] = maxphi_red
                           endif
                        endif else begin
                           ; begin get y boundaries correct
                           bnd_angspec = replicate(0.,mns,ps_size+nwrap+2)
                           bnd_angspec[*,1:nphi] = angspect
                           bnd_angspec[*,0] = angspect[*,nphi-1]
                           bnd_angspec[*,nphi+1] = angspect[*,0]
                           ; end get y boundaries correct
                           ; look for phi angles gt 360 and wrap around to 0
                           bnd_aphi_red = replicate(0.,ps_size+2)
                           bnd_aphi_red[1:nphi] = aphi_red
                           bnd_aphi_red[0] = aphi_red[nphi-1]-360
                           bnd_aphi_red[nphi+1] = aphi_red[0]+360
                        endelse
                     endelse
                     nbnd_angs_red = n_elements(bnd_aphi_red)
;                     if nang_fbnd_angspec lt nbnd_angs_red then begin
;                        ; enlarge angle dimension of final boundary angspec
;                        fbnd_angspect = replicate(!values.f_nan, i, nbnd_angs_red) ; create temp var
;                        fbnd_aphi_redt = fbnd_angspect
;                        fbnd_angspect[*,0:nang_fbnd_angspec-1] = fbnd_angspec        ; fill temp var
;                        fbnd_aphi_redt[*,0:nang_fbnd_angspec-1] = bnd_aphi_red
;                        fbnd_angspec = temporary(fbnd_angspect)            ; fill resized angspec array
;                        fbnd_aphi_red = temporary(fbnd_aphi_redt)
;                        nang_fbnd_angspec = nbnd_angs_red                  ; resize nang_fbnd_angspec
;                     endif
                     if m eq 1 then begin
                         fbnd_angspec[mindex[m-1]:mindex[m], 0:nbnd_angs_red-1] = bnd_angspec ; create final bnd_angspec
                         fbnd_aphi_red[mindex[m-1]:mindex[m], 0:nbnd_angs_red-1] = replicate(1,mns)#bnd_aphi_red ; create final bnd_aphi_red
                     endif else begin
                         fbnd_angspec[mindex[m-1]+1:mindex[m], 0:nbnd_angs_red-1] = bnd_angspec ; create final bnd_angspec
                         fbnd_aphi_red[mindex[m-1]+1:mindex[m], 0:nbnd_angs_red-1] = replicate(1,mns)#bnd_aphi_red ; create final bnd_aphi_red
                     endelse
                   endfor ; loop over angle modes
                   store_data,an_tname, data= {x:time, y:fbnd_angspec ,v:fbnd_aphi_red}, $
                              dlim={spec:1,zlog:1,ylog:0,datagap:data_gap,data_att:{units:units_str}}
                   ylim,an_tname,p_start_angle, p_end_angle,log=0,/default
                 endif ; end create tplot vars for phi angle spectra



                 ;xxx: begin create tplot vars for theta angle spectra
                 if doangle eq 'theta' then begin
                   an_tname = prefix + 'an_'+strlowcase(units)+'_' + doangle + tplotsuffix
                   ; beg re-sort of theta's so they go from -90 to 90
                   
                   ; beg mode stitching code
                   fbnd_angspec = replicate(!values.f_nan,i,maxangs_red + 2)
                   nang_fbnd_angspec = n_elements(fbnd_angspec[0,*]) ; # of angles in final boundary angspec
                   fbnd_atheta_red = fbnd_angspec
                   atheta_redt = atheta_red
                   
                   for m=1,nmode do begin ; loop over angle modes
                     
                     atheta_red = angs_red[m,0:nangs_red[m]-1]
                     maxtheta_red = max_angs_red[m,0:nangs_red[m]-1]
                     mintheta_red = min_angs_red[m,0:nangs_red[m]-1]
                     ntheta = nangs_red[m]
                     mns = mindex[m] - mindex[m-1]         ; number of samples for each mode
                     if m eq 1 then mns = mns + 1          ; account for first time index number = 0
                     ;angspect = angspec[mindex[m-1]:mindex[m],*] ; create sep. angspec 4 each mode
                     angspect = angspec[mindex[m-1]+1:mindex[m],0:ntheta-1] ; create sep. angspec 4 each mode
                     ;if m eq 1 then angspect = angspec[mindex[m-1]:mindex[m],0:nphi-1] ; create sep. angspec 4 each mode
                     if m eq 1 then angspect = angspec[mindex[m-1]:mindex[m],0:ntheta-1] ; create sep. angspec 4 each mode
                     ; end mode stitching code
                   
                     ps_size = n_elements(angspect[0,*])
                     if ps_size gt ntheta then begin
                        angspect = angspect[*,0:ntheta-1]
                        ps_size = n_elements(angspect[0,*])
                     endif
  
                     if 0 then begin ;keyword_set(start_angle) then begin
                        if start_angle lt 0 then begin
                           aphi_red = aphi_red - 360
                           st_ind = min(where(start_angle lt aphi_red))
                           aphi_red = shift(aphi_red, -st_ind)
                           too_low_ind = where(start_angle gt aphi_red)
                           aphi_red[too_low_ind] = aphi_red[too_low_ind] + 360
                        endif else begin
                           st_ind = min(where(start_angle lt aphi_red))
                           aphi_red = shift(aphi_red, -st_ind)
                           too_low_ind = where(start_angle gt aphi_red,n)
                           if n gt 0 then aphi_red[too_low_ind] = aphi_red[too_low_ind] + 360
                           ;aphi_red[too_low_ind] = aphi_red[too_low_ind] + 360
                        endelse
                     endif else st_ind = 0
  
                     if nd gt 1 then begin
                        if size(/n_dimensions,angspect) eq 1 then begin
                           angspect = reform(angspect,n_elements(angspect),1)
                        endif else begin
                           angspect = shift(angspect, 0, -st_ind)
                        endelse
                     endif
  
                     nwrap = 0
                     ; begin append wrapped theta bins
  ;                     wrap_ind = where((aphi_red gt start_angle) AND $
  ;                                     (aphi_red lt (start_angle + wrapphi)),nwrap)
  ;                     
  ;                     if (wrapphi gt 0) AND (nwrap gt 0) then begin
  ;;                     if wrapphi gt 0 then begin
  ;;                        wrap_ind = where((aphi_red gt start_angle) AND $
  ;;                                        (aphi_red lt (start_angle + wrapphi)),nwrap)
  ;                      wrap_angspec = replicate(0.,ns, ps_size+nwrap)
  ;                      wrap_angspec[*,0:nphi-1] = angspec
  ;                      wrap_angspec[*,nphi:nphi + nwrap-1] = angspec[*,0:nwrap-1]
  ;
  ;                      wrap_ps_size = n_elements(wrap_angspec[0,*])
  ;                      wrap_aphi_red = replicate(0.,wrap_ps_size)
  ;                      wrap_aphi_red[0:nphi-1] = aphi_red
  ;                      wrap_aphi_red[nphi:nphi + nwrap-1] = aphi_red[0:nwrap-1] + 360
  ;
  ;                      bnd_angspec = replicate(0.,ns,wrap_ps_size+2)
  ;                      bnd_angspec[*,1:wrap_ps_size] = wrap_angspec
  ;                      bnd_angspec[*,0] = angspec[*,ps_size-1]; might have to make this zeros or NaNs
  ;                      bnd_angspec[*,wrap_ps_size+1] = angspec[*,nwrap] ; what if angspec[*,nwrap] doesn't exist?
  ;
  ;                      bnd_aphi_red = replicate(0.,wrap_ps_size+2)
  ;                      bnd_aphi_red[1:wrap_ps_size] = wrap_aphi_red
  ;                      bnd_aphi_red[0] = aphi_red[ps_size-1] - 360
  ;                      bnd_aphi_red[wrap_ps_size+1] = aphi_red[nwrap] + 360
  ;                   endif else begin ; begin append wrapped theta bins if necceary
                        if (theta[1] - theta[0]) lt 180 then begin
                           bnd_angspec = angspect
                           bnd_atheta_red = atheta_red
                           ;th_start_angle = theta[0] ; atheta_red[0]
                           ;th_end_angle = theta[1] ; atheta_red[ntheta-1]
                           th_start_angle = atheta_red[0] - dtheta_red[0]/2
                           th_end_angle = atheta_red[ntheta-1] + dtheta_red[ntheta-1]/2
                           if n_elements(angspect[0,*]) eq 1 then begin
                              ;th_start_angle = mintheta_red
                              ;th_end_angle = maxtheta_red
                              bnd_angspec = replicate(0.,mns,ps_size+nwrap+2)
                              bnd_angspec[*,1:ntheta] = angspect
                              bnd_angspec[*,0] = angspect
                              bnd_angspec[*,ntheta+1] = angspect
                              ; end get y boundaries correct
                              ; look for phi angles gt 90 and wrap around to -90
                              bnd_atheta_red = replicate(0.,ps_size+2)
                              bnd_atheta_red[1:ntheta] = atheta_red
                              bnd_atheta_red[0] = mintheta_red
                              bnd_atheta_red[ntheta+1] = maxtheta_red
                           endif
                        endif ;else begin
                           ; begin get y boundaries correct
                           bnd_angspec = replicate(0.,mns,ps_size+nwrap+2)
                           bnd_angspec[*,1:ntheta] = angspect
                           bnd_angspec[*,0] = angspect[*,ntheta-1]
                           bnd_angspec[*,ntheta+1] = angspect[*,0]
                           ; end get y boundaries correct
                           ; look for theta angles gt 90 and wrap around to -90
                           bnd_atheta_red = replicate(0.,ps_size+2)
                           bnd_atheta_red[1:ntheta] = atheta_red
                           bnd_atheta_red[0] = atheta_red[ntheta-1]-180
                           bnd_atheta_red[ntheta+1] = atheta_red[0]+180
                       ; endelse
                     ;endelse
                     nbnd_angs_red = n_elements(bnd_atheta_red)
                     if m eq 1 then begin
                         fbnd_angspec[mindex[m-1]:mindex[m], 0:nbnd_angs_red-1] = bnd_angspec ; create final bnd_angspec
                         fbnd_atheta_red[mindex[m-1]:mindex[m], 0:nbnd_angs_red-1] = replicate(1,mns)#bnd_atheta_red ; create final bnd_aphi_red
                     endif else begin
                         fbnd_angspec[mindex[m-1]+1:mindex[m], 0:nbnd_angs_red-1] = bnd_angspec ; create final bnd_angspec
                         fbnd_atheta_red[mindex[m-1]+1:mindex[m], 0:nbnd_angs_red-1] = replicate(1,mns)#bnd_atheta_red ; create final bnd_aphi_red
                     endelse
                   endfor ; loop over angle modes                   
                   store_data,an_tname, data= {x:time, y:fbnd_angspec ,v:fbnd_atheta_red}, $
                              dlim={spec:1,zlog:1,ylog:0,datagap:data_gap,data_att:{units:units_str}}
                   if theta[0] gt th_start_angle then th_start_angle = theta[0]
                   if theta[1] lt th_end_angle then th_end_angle = theta[1]
                   ylim, an_tname, th_start_angle, th_end_angle,log=0,/default
                 endif ; end create tplot vars for theta angle spectra




                 ;xxx: begin create tplot vars for pitch angle spectra
                 if doangle eq 'pa' then begin
                   an_tname = prefix + 'an_'+strlowcase(units)+'_' + doangle + tplotsuffix
                   ; beg re-sort of pa's so they go from -90 to 90
                   ps_size = n_elements(angspec[0,*])
                   if ps_size gt npab then begin
                      angspec = angspec[*,0:npab-1]
                      ps_size = n_elements(angspec[0,*])
                   endif

                   if 0 then begin ;keyword_set(start_angle) then begin
                      if start_angle lt 0 then begin
                         aphi_red = aphi_red - 360
                         st_ind = min(where(start_angle lt aphi_red))
                         aphi_red = shift(aphi_red, -st_ind)
                         too_low_ind = where(start_angle gt aphi_red)
                         aphi_red[too_low_ind] = aphi_red[too_low_ind] + 360
                      endif else begin
                         st_ind = min(where(start_angle lt aphi_red))
                         aphi_red = shift(aphi_red, -st_ind)
                         too_low_ind = where(start_angle gt aphi_red,n)
                         if n gt 0 then aphi_red[too_low_ind] = aphi_red[too_low_ind] + 360
                         ;aphi_red[too_low_ind] = aphi_red[too_low_ind] + 360
                      endelse
                   endif else st_ind = 0

                   if nd gt 1 then begin
                      if size(/n_dimensions,angspec) eq 1 then begin
                         angspec = reform(angspec,n_elements(angspec),1)
                      endif else begin
                         angspec = shift(angspec, 0, -st_ind)
                      endelse
                   endif

                   nwrap = 0
                   ; begin append wrapped theta bins
;                     wrap_ind = where((aphi_red gt start_angle) AND $
;                                     (aphi_red lt (start_angle + wrapphi)),nwrap)
;                     
;                     if (wrapphi gt 0) AND (nwrap gt 0) then begin
;;                     if wrapphi gt 0 then begin
;;                        wrap_ind = where((aphi_red gt start_angle) AND $
;;                                        (aphi_red lt (start_angle + wrapphi)),nwrap)
;                      wrap_angspec = replicate(0.,ns, ps_size+nwrap)
;                      wrap_angspec[*,0:nphi-1] = angspec
;                      wrap_angspec[*,nphi:nphi + nwrap-1] = angspec[*,0:nwrap-1]
;
;                      wrap_ps_size = n_elements(wrap_angspec[0,*])
;                      wrap_aphi_red = replicate(0.,wrap_ps_size)
;                      wrap_aphi_red[0:nphi-1] = aphi_red
;                      wrap_aphi_red[nphi:nphi + nwrap-1] = aphi_red[0:nwrap-1] + 360
;
;                      bnd_angspec = replicate(0.,ns,wrap_ps_size+2)
;                      bnd_angspec[*,1:wrap_ps_size] = wrap_angspec
;                      bnd_angspec[*,0] = angspec[*,ps_size-1]; might have to make this zeros or NaNs
;                      bnd_angspec[*,wrap_ps_size+1] = angspec[*,nwrap] ; what if angspec[*,nwrap] doesn't exist?
;
;                      bnd_aphi_red = replicate(0.,wrap_ps_size+2)
;                      bnd_aphi_red[1:wrap_ps_size] = wrap_aphi_red
;                      bnd_aphi_red[0] = aphi_red[ps_size-1] - 360
;                      bnd_aphi_red[wrap_ps_size+1] = aphi_red[nwrap] + 360
;                   endif else begin ; begin append wrapped theta bins if necceary
                      ;if (pitch[1] - pitch[0]) le 180 then begin
                         bnd_angspec = angspec
                         bnd_pa_red = pa_red
                         th_start_angle = pitch[0] ; pa_red[0] - dthfac[0]/2
                         th_end_angle = pitch[1] ; pa_red[npa-1] + dthfac[0]/2
                         if n_elements(angspec[0,*]) eq 1 then begin
                            th_start_angle = pa_red - 0.5 ; arbitrary bounds
                            th_end_angle = pa_red + 0.5 ; arbitrary bounds
                            bnd_angspec = replicate(0.,ns,ps_size+nwrap+2)
                            bnd_angspec[*,1:npa] = angspec
                            bnd_angspec[*,0] = angspec
                            bnd_angspec[*,npa+1] = angspec
                            ; end get y boundaries correct
                            ; look for phi angles gt 90 and wrap around to -90
                            bnd_pa_red = replicate(0.,ps_size+2)
                            bnd_pa_red[1:npa] = pa_red
                            bnd_pa_red[0] = pa_red - 0.5 ; arbitrary bouns
                            bnd_pa_red[npa+1] = pa_red + 0.5 ; arbitrary bounds
                         endif
                      ;endif else begin
                         ; begin get y boundaries correct
                         bnd_angspec = replicate(!values.f_nan,ns,ps_size+nwrap+2)
                         ;bnd_angspec[*,1:npa] = angspec
                         bnd_angspec[*,1:npa] = angspec[*,0:npa-1]
                         bnd_angspec[*,0] = angspec[*,npa-1]
                         bnd_angspec[*,npa+1] = angspec[*,0]
                         ; end get y boundaries correct
                         ; look for theta angles gt 90 and wrap around to -90
                         bnd_pa_red = replicate(!values.f_nan,ps_size+2)
                         bnd_pa_red[1:npa] = pa_red
                         bnd_pa_red[0] = pa_red[npa-1]-180
                         bnd_pa_red[npa+1] = pa_red[0]+180
                      ;endelse
;                   endelse
                   store_data,an_tname, data= {x:time, y:bnd_angspec ,v:bnd_pa_red}, $
                              dlim={spec:1,zlog:1,ylog:0,datagap:data_gap,data_att:{units:units_str}}
                   if pitch[0] gt th_start_angle then th_start_angle = pitch[0]
                   if pitch[1] lt th_end_angle then th_end_angle = pitch[1]
                   ylim, an_tname, th_start_angle, th_end_angle,log=0,/default
                 endif ; end create tplot vars for theta angle spectra
                 if doangle ne 'none' then begin
                    if size(an_tnames,/type) eq 0 then an_tnames = an_tname $
                       else an_tnames = [an_tnames, an_tname]
                 endif




              endif ; keyword set(units)
          endif ; not keyword_set(no_tplot)
        endif ; data exists w/in timerange set by user
    endfor ; loop over data types
endfor ; loop over probes
dprint,dlevel=4,verbose=verbose,'Run Time: ',systime(1)-start,' seconds

tn=tplotnames
options,strfilter(tn,'*_density'),/def ,yrange=[.01,200.],/ystyle,/ylog,ysubtitle='!c[1/cc]'
options,strfilter(tn,'*_velocity'),/def ,yrange=[-800,800.],/ystyle,ysubtitle='!c[km/s]'
options,strfilter(tn,'*_flux'),/def ,yrange=[-1e8,1e8],/ystyle,ysubtitle='!c[#/s/cm2 ??]'
options,strfilter(tn,'*t3'),/def ,yrange=[1,10000.],/ystyle,/ylog,ysubtitle='!c[eV]'

end
