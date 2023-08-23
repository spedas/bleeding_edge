;+
;PROCEDURE:   mvn_swe_set_quality
;PURPOSE:
;  Inspects SPEC, PAD and 3D data (survey and burst) in the common block.
;  Determines the time range spanned by the data, then reads in pre-determined
;  quality flags from IDL save/restore files.  Fills in QUALITY information
;  in the data structures.
;
;USAGE:
;  mvn_swe_set_quality
;
;INPUTS:
;       None:          All information is obtained from the common block.
;
;KEYWORDS:
;       TRANGE:        Time range to process.  If not set, then get time range
;                      from data stored in the common block.
;
;       MISSING:       Returns a 5-element array with the number of quality
;                      flags that were NOT found in the database for each of
;                      data type: 3D_SVY, 3D_ARC, PAD_SVY, PAD_ARC, SPEC.  If
;                      everything works perfectly, then MISSING = [0,0,0,0,0].
;
;       DOPLOT:        If set, makes an energy spectrogram (SPEC) tplot panel
;                      with an 'x' marking anomalous spectra (quality = 0).
;
;       SILENT:        Shhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-22 13:45:08 -0700 (Tue, 22 Aug 2023) $
; $LastChangedRevision: 32054 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_set_quality.pro $
;
;CREATED BY:  David Mitchell - August 2023
;-
pro mvn_swe_set_quality, trange=trange, missing=missing, doplot=doplot, silent=silent

  @mvn_swe_com

  missing = replicate(0L,5)
  doplot = keyword_set(doplot) and (find_handle('swe_a4') gt 0)
  blab = ~keyword_set(silent)

; Get the time range

  delta_t = 1.95D/2D  ; start time to center time for PAD and 3D packets

  if (n_elements(trange) lt 2) then begin
    trange = [0D]
    if (size(mvn_swe_engy,/type) eq 8) then trange = [trange, minmax(mvn_swe_engy.time)]
    if (size(a2,/type) eq 8) then trange = [trange, minmax(a2.time) + delta_t]
    if (size(a3,/type) eq 8) then trange = [trange, minmax(a3.time) + delta_t]
    if (size(swe_3d,/type) eq 8) then trange = [trange, minmax(swe_3d.time) + delta_t]
    if (size(swe_3d_arc,/type) eq 8) then trange = [trange, minmax(swe_3d_arc.time) + delta_t]
    if (n_elements(trange) lt 3) then begin
      print,"% mvn_swe_set_quality: no data found in the common block"
      return
    endif
    trange = minmax(trange[1:*])
  endif else trange = minmax(time_double(trange))

; Restore quality flags

  rootdir='maven/data/sci/swe/anc/quality/YYYY/MM/'
  fname = 'mvn_swe_quality_YYYYMMDD.sav'
  file = mvn_pfp_file_retrieve(rootdir+fname,trange=trange,/daily_names,/valid)
  i = where(file ne '', nfiles)
  if (nfiles eq 0L) then begin
    tstr = time_string(trange)
    print,"% mvn_swe_set_quality: no quality flags found: ",tstr[0]," to ",tstr[1]
    return
  endif
  file = file[i]

  restore,filename=file[0]
  qtime = quality.time
  qflag = quality.flag
  for j=1,nfiles-1 do begin
    restore,filename=file[j]
    qtime = [temporary(qtime), quality.time]
    qflag = [temporary(qflag), quality.flag]
  endfor

  undefine, quality

; Set the quality flags

  if (size(mvn_swe_engy,/type) eq 8) then begin
    str_element, mvn_swe_engy, 'quality', replicate(1B,n_elements(mvn_swe_engy.time)), /add
    i = nn2(qtime, mvn_swe_engy.time, maxdt=0.25D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then mvn_swe_engy[j].quality = qflag[i]
    if (max(k) ge 0L) then missing[4] = n_elements(k)
  endif

  if (size(a2,/type) eq 8) then begin
    str_element, a2, 'quality', replicate(1B,n_elements(a2.time)), /add
    i = nn2(qtime, a2.time + delta_t, maxdt=0.6D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then a2[j].quality = qflag[i]
    if (max(k) ge 0L) then missing[2] = n_elements(k)
  endif

  if (size(a3,/type) eq 8) then begin
    str_element, a3, 'quality', replicate(1B,n_elements(a3.time)), /add
    i = nn2(qtime, a3.time + delta_t, maxdt=0.6D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then a3[j].quality = qflag[i]
    if (max(k) ge 0L) then missing[3] = n_elements(k)
  endif

  if (size(swe_3d,/type) eq 8) then begin
    str_element, swe_3d, 'quality', replicate(1B,n_elements(swe_3d.time)), /add
    i = nn2(qtime, swe_3d.time + delta_t, maxdt=0.6D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then swe_3d[j].quality = qflag[i]
    if (max(k) ge 0L) then missing[0] = n_elements(k)
  endif

  if (size(swe_3d_arc,/type) eq 8) then begin
    str_element, swe_3d_arc, 'quality', replicate(1B,n_elements(swe_3d_arc.time)), /add
    i = nn2(qtime, swe_3d_arc.time + delta_t, maxdt=0.6D, /valid, vindex=j, badindex=k)
    if (max(j) ge 0L) then swe_3d_arc[j].quality = qflag[i]
    if (max(k) ge 0L) then missing[1] = n_elements(k)
  endif

; Report missing quality flag data

  if (blab) then begin
    msg = ['a0','a1','a2','a3','a4'] + ' flags: ' + strtrim(string(missing),2)
    for i=0,4 do if (missing[i] gt 0L) then print,"% mvn_swe_quality: missing ",msg[i]
  endif

; Make the enery spectrogram with 'x' overlay marking anomalous spectra

  if doplot then begin
    get_data, 'swe_a4', data=dat, index=k
    if (k gt 0) then begin
      flag = replicate(1B, n_elements(dat.x))
      i = nn2(qtime, dat.x, maxdt=0.25D, /valid, vindex=j, badindex=k)
      if (max(j) ge 0L) then flag[j] = qflag[i]

      y = replicate(!values.f_nan, n_elements(dat.x))
      i = where(flag eq 0B, count)
      if (count gt 0L) then y[i] = 4.4

      store_data,'flag',data={x:dat.x, y:y}
      options,'flag','psym',7
      options,'flag','colors',0
      options,'flag','symsize',0.6
      store_data,'swe_a4_mask',data=['swe_a4','flag']
      ylim,'swe_a4_mask',3,4627.5,1
    endif
  endif

end
