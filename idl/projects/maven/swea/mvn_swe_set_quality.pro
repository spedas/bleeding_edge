;+
;PROCEDURE:   mvn_swe_set_quality
;PURPOSE:
;  Inspects SPEC, PAD and 3D data (survey and burst) in the common block.
;  Determines the time range spanned by the data, then reads in pre-determined
;  quality flags from IDL save/restore files.  Fills in QUALITY information
;  in the data structures.
;
;  Quality flag definitions:
;
;      0B = Data are affected by the low-energy anomaly.  There
;           are significant systematic errors below 28 eV.
;      1B = Unknown because: (1) the variability is too large to 
;           confidently identify anomalous spectra, as in the 
;           sheath, or (2) secondary electrons mask the anomaly,
;           as in the sheath just downstream of the bow shock.
;      2B = Data are not affected by the low-energy anomaly.
;           Caveat: There is increased noise around 23 eV, even 
;           for "good" spectra.
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
;       VALUE:         Set all quality flags to this value.  Must be a byte
;                      integer of 0B, 1B, or 2B.
;
;       DOPLOT:        If set, makes an energy spectrogram (SPEC) tplot panel
;                      with an 'x' marking anomalous spectra (quality = 0).
;                      Not recommended -- better to use the swe_quality tplot
;                      variable instead.
;
;       REFRESH:       Action to take if a quality save file is not found.
;                      This keyword can have one of three integer values:
;
;                        0 : Do nothing.  Just fill the quality flag array
;                            with 1's (unknown) for all times covered by the
;                            missing file.  Default.
;
;                        1 : Attempt to create the missing file, then try to 
;                            load it.
;
;                        2 : Create or recreate all files, overwriting any
;                            existing file(s).
;
;                      *** This keyword only works for authorized users! ***
;
;       SILENT:        Shhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-11-13 11:16:03 -0800 (Wed, 13 Nov 2024) $
; $LastChangedRevision: 32955 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_set_quality.pro $
;
;CREATED BY:  David Mitchell - August 2023
;-
pro mvn_swe_set_quality, trange=trange, missing=missing, value=value, doplot=doplot, $
                         silent=silent, refresh=refresh

  @mvn_swe_com

  user = (get_login_info()).user_name
  authorized = (user eq 'mitchell') or (user eq 'shaosui.xu') or (user eq 'muser')
  refresh = (n_elements(refresh) gt 0L) and authorized ? fix(refresh[0]) > 0 < 2 : 0
  if (n_elements(value) gt 0) then begin
    value = byte(fix(value[0]) > 0 < 2)
    force = 1
  endif else force = 0

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

  missing = replicate(0L,5)
  missing[0] = n_elements(swe_3d)
  missing[1] = n_elements(swe_3d_arc)
  missing[2] = n_elements(a2)
  missing[3] = n_elements(a3)
  missing[4] = n_elements(a4)

; Determine if quality file(s) exist.  Authorized users can generate missing
; files and/or update existing ones.

  if (~force) then begin

    rootdir='maven/data/sci/swe/anc/quality/YYYY/MM/'
    fname = 'mvn_swe_quality_YYYYMMDD.sav'
    file = mvn_pfp_file_retrieve(rootdir+fname,trange=trange,/daily_names,verbose=0)
    nfiles = n_elements(file)
    finfo = file_info(file)
    k = where(~finfo.exists, count)
    case (refresh) of
      0 : begin
            for i=0,(count-1) do print, "Quality file not found : ", file[k[i]]
            if (count gt 0) then print,"Missing quality flags set to 1 (unknown)."
          end
      1 : begin
            for i=0,(count-1) do begin
              print, "Quality file not found : ", file[k[i]]
              yyyy = strmid(file[k[i]],11,4,/reverse)
              mm = strmid(file[k[i]],7,2,/reverse)
              dd = strmid(file[k[i]],5,2,/reverse)
              date = yyyy + '-' + mm + '-' + dd
              print, "  Generating missing file ... "
              mvn_swe_quality_daily, date, /noload
            endfor
          end
      2 : begin
            for i=0,(nfiles-1) do begin
              yyyy = strmid(file[i],11,4,/reverse)
              mm = strmid(file[i],7,2,/reverse)
              dd = strmid(file[i],5,2,/reverse)
              date = yyyy + '-' + mm + '-' + dd
              print, "(Re)generating quality file: ", file[i]
              mvn_swe_quality_daily, date, /noload
            endfor
          end
      else : begin
               print, "% mvn_swe_set_quality: this should be impossible!"
               return
             end
    endcase

; Get the names of valid quality save files.  If no files are found, fill the
; quality arrays with 1 and return early.

    file = mvn_pfp_file_retrieve(rootdir+fname,trange=trange,/daily_names,verbose=0)
    finfo = file_info(file)
    k = where(finfo.exists, nfiles)
    if (nfiles eq 0) then begin
      print, "No quality save files found!  Setting all quality flags to 1 (unknown)."
      if (size(mvn_swe_engy,/type) eq 8) then $
        str_element, mvn_swe_engy, 'quality', replicate(1B,n_elements(mvn_swe_engy.time)), /add
      if (size(a2,/type) eq 8) then $
        str_element, a2, 'quality', replicate(1B,n_elements(a2.time)), /add
      if (size(a3,/type) eq 8) then $
        str_element, a3, 'quality', replicate(1B,n_elements(a3.time)), /add
      if (size(swe_3d,/type) eq 8) then $
        str_element, swe_3d, 'quality', replicate(1B,n_elements(swe_3d.time)), /add
      if (size(swe_3d_arc,/type) eq 8) then $
        str_element, swe_3d_arc, 'quality', replicate(1B,n_elements(swe_3d_arc.time)), /add
      return
    endif
    file = file[k]  ; only valid files

; Restore the quality flags

    restore,filename=file[0]
    qtime = quality.time
    qflag = quality.flag
    for j=1,nfiles-1 do begin
      restore,filename=file[j]
      qtime = [temporary(qtime), quality.time]
      qflag = [temporary(qflag), quality.flag]
    endfor

    undefine, quality
  endif

; Set the quality flags

  if (size(mvn_swe_engy,/type) eq 8) then begin
    if (~force) then begin
      str_element, mvn_swe_engy, 'quality', replicate(1B,n_elements(mvn_swe_engy.time)), /add
      i = nn2(qtime, mvn_swe_engy.time, maxdt=0.5D, /valid, vindex=j, badindex=k)
      if (max(j) ge 0L) then mvn_swe_engy[j].quality = qflag[i]
      if (max(k) ge 0L) then missing[4] = n_elements(k)
    endif else begin
      str_element, mvn_swe_engy, 'quality', replicate(value,n_elements(mvn_swe_engy.time)), /add
      missing[4] = 0L
    endelse
  endif

  if (size(a2,/type) eq 8) then begin
    if (~force) then begin
      str_element, a2, 'quality', replicate(1B,n_elements(a2.time)), /add
      i = nn2(qtime, a2.time + delta_t, maxdt=0.8D, /valid, vindex=j, badindex=k)
      if (max(j) ge 0L) then a2[j].quality = qflag[i]
      if (max(k) ge 0L) then missing[2] = n_elements(k)
    endif else begin
      str_element, a2, 'quality', replicate(value,n_elements(a2.time)), /add
      missing[2] = 0L
    endelse
  endif

  if (size(a3,/type) eq 8) then begin
    if (~force) then begin
      str_element, a3, 'quality', replicate(1B,n_elements(a3.time)), /add
      i = nn2(qtime, a3.time + delta_t, maxdt=0.8D, /valid, vindex=j, badindex=k)
      if (max(j) ge 0L) then a3[j].quality = qflag[i]
      if (max(k) ge 0L) then missing[3] = n_elements(k)
    endif else begin
      str_element, a3, 'quality', replicate(value,n_elements(a3.time)), /add
      missing[3] = 0L
    endelse
  endif

  if (size(swe_3d,/type) eq 8) then begin
    if (~force) then begin
      str_element, swe_3d, 'quality', replicate(1B,n_elements(swe_3d.time)), /add
      i = nn2(qtime, swe_3d.time + delta_t, maxdt=0.8D, /valid, vindex=j, badindex=k)
      if (max(j) ge 0L) then swe_3d[j].quality = qflag[i]
      if (max(k) ge 0L) then missing[0] = n_elements(k)
    endif else begin
      str_element, swe_3d, 'quality', replicate(value,n_elements(swe_3d.time)), /add
      missing[0] = 0L
    endelse
  endif

  if (size(swe_3d_arc,/type) eq 8) then begin
    if (~force) then begin
      str_element, swe_3d_arc, 'quality', replicate(1B,n_elements(swe_3d_arc.time)), /add
      i = nn2(qtime, swe_3d_arc.time + delta_t, maxdt=0.8D, /valid, vindex=j, badindex=k)
      if (max(j) ge 0L) then swe_3d_arc[j].quality = qflag[i]
      if (max(k) ge 0L) then missing[1] = n_elements(k)
    endif else begin
      str_element, swe_3d_arc, 'quality', replicate(value,n_elements(swe_3d_arc.time)), /add
      missing[1] = 0L
    endelse
  endif

; Report missing quality flag data

  if (blab) then begin
    msg = ['a0','a1','a2','a3','a4'] + ' flags: ' + strtrim(string(missing),2)
    for i=0,4 do if (missing[i] gt 0L) then print,"% mvn_swe_quality: missing ",msg[i]
    if (force) then print,"  all quality flags set to: ",value
  endif

; Make the enery spectrogram with 'x' overlay marking anomalous spectra

  if (doplot) then begin
    get_data, 'swe_a4', data=dat, index=k
    if (k gt 0) then begin
      flag = replicate(1B, n_elements(dat.x))
      i = nn2(qtime, dat.x, maxdt=0.25D, /valid, vindex=j, badindex=k)
      if (max(j) ge 0L) then flag[j] = qflag[i]

      y = replicate(!values.f_nan, n_elements(dat.x))
      i = where(flag eq 0B, count)
      if (count gt 0L) then y[i] = 4.4

      store_data,'swe_flag',data={x:dat.x, y:y}
      options,'swe_flag','psym',7
      options,'swe_flag','colors',0
      options,'swe_flag','symsize',0.6
      store_data,'swe_a4_mask',data=['swe_a4','swe_flag']
      ylim,'swe_a4_mask',3,4627.5,1
    endif
  endif

end
