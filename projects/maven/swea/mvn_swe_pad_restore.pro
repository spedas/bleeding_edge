;+
;PROCEDURE:   mvn_swe_pad_restore
;PURPOSE:
;  Reads in resampled pad data (100-150 eV) precalculated by mvn_swe_pad_resample
;  and stored in a tplot save/restore file.  Command line used to create the tplot
;  variables was:
;
;    mvn_swe_pad_resample, nbins=128, erange=[100.,150.], /norm, /mask
;
;  Can also be used to restore resampled 2D energy-pitch angle data.  In this case,
;  use the FULL and PAD keywords.  Note that 2D pad data consume up to 375 MB/date, 
;  so use these keywords with caution.
;
;USAGE:
;  mvn_swe_pad_restore, trange
;
;INPUTS:
;       trange:        Restore data over this time range.  If not specified, then
;                      uses the current tplot range.
;
;KEYWORDS:
;       ORBIT:         Restore pad data by orbit number.
;
;       LOADONLY:      Download but do not restore any pad data.
;
;       UNNORM:        Unnormalize the color code.  (Only applies to single-energy
;                      100-150-eV pad data.  Full 2D pad data are not normalized
;                      in the first place.)
;
;       FULL:          Restore the resampled 2D energy-pitch angle data, instead
;                      of just the 100-150-eV range.  Must be used with keyword PAD.
;
;       PAD:           Named variable to hold the restored 2D energy-pitch angle
;                      data.  Must be used with keyword FULL.
;
;       L2ONLY:        Insist that MAG L2 data were used for resampling.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-04-20 11:00:34 -0700 (Tue, 20 Apr 2021) $
; $LastChangedRevision: 29892 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_pad_restore.pro $
;
;CREATED BY:    David L. Mitchell  04-25-13
;FILE: mvn_swe_pad_restore.pro
;-
pro mvn_swe_pad_restore, trange, orbit=orbit, loadonly=loadonly, unnorm=unnorm, full=full, pad=pad, $
                         l2only=l2only

; Process keywords
  if keyword_set(full) then begin
    rootdir = 'maven/data/sci/swe/l3/pad_resample/YYYY/MM/'
    fname = 'mvn_swe_l3_padfull_YYYYMMDD_v??_r??.sav'
    tname = 'mvn_swe_epad_resample'
  endif else begin
    rootdir = 'maven/data/sci/swe/l1/pad_resample/YYYY/MM/'
    fname = 'mvn_swe_pad_YYYYMMDD.tplot'
    tname = 'mvn_swe_pad_resample'
  endelse
  
  if keyword_set(orbit) then begin
    imin = min(orbit, max=imax)
    trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
  endif

  tplot_options, get_opt=topt
  tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
  if ((size(trange,/type) eq 0) and tspan_exists) then trange = topt.trange_full

; Get file names associated with trange or from one or more named
; file(s).  If you specify a time range and are working off-site, 
; then the files are downloaded to your local machine, which might
; take a while.

  if (size(trange,/type) eq 0) then begin
    print,"You must specify a time or orbit range."
    return
  endif
  tmin = min(time_double(trange), max=tmax)
  file = mvn_pfp_file_retrieve(rootdir+fname,trange=[tmin,tmax],/daily_names)
  nfiles = n_elements(file)
  
  finfo = file_info(file)
  indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
  for j=0,(n-1) do print,"File not found: ",file[jndx[j]]  
  if (nfiles eq 0) then return
  file = file[indx]
  finfo = finfo[indx]

  indx = where(finfo.size gt 1000000LL, nfiles, comp=jndx, ncomp=n)
  for j=0,(n-1) do print,"Bad tplot save file: ",file[jndx[j]]
  if (nfiles eq 0) then return
  file = file[indx]

  if keyword_set(loadonly) then begin
    print,''
    print,'Files found:'
    for i=0,(nfiles-1) do print,file[i],format='("  ",a)'
    print,''
    return
  endif

  if keyword_set(full) then begin

; Restore the save file(s)

    first = 1
    docat = 0
    pad = 0
  
    for i=0,(nfiles-1) do begin
      print,"Processing file: ",file_basename(file[i])
    
      if (first) then begin
        restore, filename=file[i]
        if (size(pad,/type) eq 8) then begin
          epad = temporary(pad)
          first = 0
        endif else print,"No data were restored."
      endif else begin
        restore, filename=file[i]
        if (size(pad,/type) eq 8) then begin
          epad = [temporary(epad), temporary(pad)]
        endif else print,"No data were restored."
      endelse
    endfor

    npts = n_elements(epad.time)

; Trim to the requested time range

    indx = where((epad.time ge tmin) and (epad.time le tmax), mpts)
    if (mpts eq 0L) then begin
      print,"No data within specified time range!"
      epad = 0
      return
    endif
    if (mpts lt npts) then begin
      epad = temporary(epad[indx])
      npts = mpts
    endif
    pad = epad
  endif else begin

; Restore tplot save file(s)

    first = 1
    docat = 0

    for i=0,(nfiles-1) do begin
      print,"Processing file: ",file_basename(file[i])

      if (first) then begin
        tplot_restore, filename=file[i]
        get_data,tname,data=pad,index=k, alim=dl
        if (k gt 0L) then begin
          npts = n_elements(pad.x)
          x = pad.x
          y = pad.y
          v = pad.v
          nf = dl.nfactor
          first = 0
        endif else print,"No data were restored."
      endif else begin
        tplot_restore, filename=file[i]
        get_data,tname,data=pad,index=k, alim=dl
        if (k gt 0L) then begin
          mpts = n_elements(pad.x)
          x = [temporary(x), pad.x]

          y1 = fltarr(npts+mpts,128)
          y1[0L:(npts-1L),*] = temporary(y)
          y1[npts:(npts+mpts-1L),*] = pad.y
          y = temporary(y1)

          v1 = fltarr(npts+mpts,128)
          v1[0L:(npts-1L),*] = temporary(v)
          v1[npts:(npts+mpts-1L),*] = pad.v
          v = temporary(v1)
        
          nf = [temporary(nf), dl.nfactor]
          npts = npts + mpts
          docat = 1
        endif else print,"No data were restored."
      endelse
    endfor
  
    nf = rebin(temporary(nf), npts, n_elements(y[0, *]))

; Trim to the requested time range

    indx = where((x ge tmin) and (x le tmax), mpts)
    if (mpts eq 0L) then begin
      print,"No data within specified time range!"
      get_data,tname,index=k
      if (k gt 0L) then store_data,tname,/delete
      return
    endif
    if (mpts lt npts) then begin
      x = temporary(x[indx])
      y = temporary(y[indx,*])
      v = temporary(v[indx,*])
      nf = temporary(nf[indx,*])
      npts = mpts
      dotrim = 1
    endif else dotrim = 0

; Remove normalization, if requested

    if keyword_set(unnorm) then begin
      y *= nf
      str_element, dl, 'ztitle', ztit
      ztit = (strsplit(ztit, /extract))[1]
      str_element, dl, 'ztitle', ztit, /add_replace
    endif

; Check on MAG data level

    get_data, tname, data=pad, alim=alim, index=k
    if (k eq 0) then begin
      print, "No pad data were restored."
      return
    endif
    str_element, alim, 'maglev', maglev, success=ok
    if (not ok) then begin
      print, "Can't determine MAG data level!  Assuming L1."
      maglev = replicate(1B, n_elements(pad.x))
      options,tname,'maglev',maglev
    endif
    indx = where(maglev lt 2B, count)
    if (count gt 0L) then begin
      print, "*****************************************************"
      print, "PAD data are based, at least in part, on L1 MAG data."
      print, "These data may not be used for publication."
      print, "*****************************************************"
      if keyword_set(l2only) then begin
        store_data,tname,/delete
        return
      endif
      options, tname, 'ytitle', 'SWEA L1 PAD!c(111-140 eV)'
      str_element, dl, 'ytitle', 'SWEA L1 PAD!c(111-140 eV)', /add_replace
    endif else begin
      print,"PAD data are based on L2 MAG data."
      options, tname, 'ytitle', 'SWEA L2 PAD!c(111-140 eV)'
      str_element, dl, 'ytitle', 'SWEA L2 PAD!c(111-140 eV)', /add_replace
    endelse

; Store the result back into tplot

    str_element, dl, 'nfactor', reform(nf[*, 0]), /add_replace ; Reinserting the truncated normalization factor.
    if (docat or dotrim) then begin
      print,"Saving merged/trimmed tplot variable: ", tname
      store_data,tname,data={x:x, x_ind:[npts], $
                             y:y, y_ind:[npts], $
                             v:v, v_ind:[npts]   }, dl=dl
    endif

    if keyword_set(unnorm) then zlim, tname, 0, 0, 1, /def

  endelse

  return

end
