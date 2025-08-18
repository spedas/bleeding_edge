;+
;PROCEDURE:   mvn_swe_stat
;PURPOSE:
;  Reports the status of SWEA data loaded into the common block.
;
;USAGE:
;  mvn_swe_stat
;
;INPUTS:
;
;KEYWORDS:
;
;    NPKT:          Returns the number of packets of each type.
;
;    FULL:          If set, then display version information about IDL
;                   and the SPICE and CDF dynamic load modules.
;
;    SILENT:        Shhhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-03 11:57:08 -0700 (Tue, 03 Jun 2025) $
; $LastChangedRevision: 33362 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_stat.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro mvn_swe_stat, npkt=npkt, full=full, silent=silent

  @mvn_swe_com

  npkt = replicate(0L,8)

  if (size(swe_hsk,/type) ne 8) then begin
    print,""
    print,"No SWEA data loaded."
    print,""
    return
  endif

  if (n_elements(swe_hsk) eq 2) then begin
    n_pfp = 0L
    n_hsk = 0L
    n_a6 = 0L
    if (size(mvn_swe_3d,/type) eq 8)       then n_a0 = n_elements(mvn_swe_3d)       else n_a0 = 0L
    if (size(mvn_swe_3d_arc,/type) eq 8)   then n_a1 = n_elements(mvn_swe_3d_arc)   else n_a1 = 0L
    if (size(mvn_swe_pad,/type) eq 8)      then n_a2 = n_elements(mvn_swe_pad)      else n_a2 = 0L
    if (size(mvn_swe_pad_arc,/type) eq 8)  then n_a3 = n_elements(mvn_swe_pad_arc)  else n_a3 = 0L
    if (size(mvn_swe_engy,/type) eq 8)     then n_a4 = n_elements(mvn_swe_engy)     else n_a4 = 0L
    if (size(mvn_swe_engy_arc,/type) eq 8) then n_a5 = n_elements(mvn_swe_engy_arc) else n_a5 = 0L

    first = 1
    if (n_a0 gt 0L) then begin
      tsp = minmax(mvn_swe_3d.time)
      first = 0
    endif
    if (n_a1 gt 0L) then begin
      tsp = first ? minmax(mvn_swe_3d_arc.time) : minmax([tsp, mvn_swe_3d_arc.time])
      first = 0
    endif
    if (n_a2 gt 0L) then begin
      tsp = first ? minmax(mvn_swe_pad.time) : minmax([tsp, mvn_swe_pad.time])
      first = 0
    endif
    if (n_a3 gt 0L) then begin
      tsp = first ? minmax(mvn_swe_pad_arc.time) : minmax([tsp, mvn_swe_pad_arc.time])
      first = 0
    endif
    if (n_a4 gt 0L) then begin
      tsp = first ? minmax(mvn_swe_engy.time) : minmax([tsp, mvn_swe_engy.time])
      first = 0
    endif
    if (n_a5 gt 0L) then begin
      tsp = first ? minmax(mvn_swe_engy_arc.time) : minmax([tsp, mvn_swe_engy_arc.time])
      first = 0
    endif

  endif else begin
    if (size(pfp_hsk,/type) eq 8) then n_pfp = n_elements(pfp_hsk) else n_pfp = 0L
    if (size(swe_hsk,/type) eq 8) then n_hsk = n_elements(swe_hsk) else n_hsk = 0L
    if (size(swe_3d,/type) eq 8) then n_a0 = n_elements(swe_3d) else n_a0 = 0L
    if (size(swe_3d_arc,/type) eq 8) then n_a1 = n_elements(swe_3d_arc) else n_a1 = 0L
    if (size(a2,/type) eq 8) then n_a2 = n_elements(a2) else n_a2 = 0L
    if (size(a3,/type) eq 8) then n_a3 = n_elements(a3) else n_a3 = 0L
    if (size(a4,/type) eq 8) then n_a4 = n_elements(a4)*16 else n_a4 = 0L
    if (size(a5,/type) eq 8) then n_a5 = n_elements(a5)*16 else n_a5 = 0L
    if (size(a6,/type) eq 8) then n_a6 = n_elements(a6) else n_a6 = 0L

    first = 1
    if (n_a0 gt 0L) then begin
      tsp = minmax(swe_3d.time)
      first = 0
    endif
    if (n_a1 gt 0L) then begin
      tsp = first ? minmax(swe_3d_arc.time) : minmax([tsp, swe_3d_arc.time])
      first = 0
    endif
    if (n_a2 gt 0L) then begin
      tsp = first ? minmax(a2.time) : minmax([tsp, a2.time])
      first = 0
    endif
    if (n_a3 gt 0L) then begin
      tsp = first ? minmax(a3.time) : minmax([tsp, a3.time])
      first = 0
    endif
    if (n_a4 gt 0L) then begin
      tsp = first ? minmax(a4.time) : minmax([tsp, a4.time])
      first = 0
    endif
    if (n_a5 gt 0L) then begin
      tsp = first ? minmax(a5.time) : minmax([tsp, a5.time])
      first = 0
    endif

  endelse
  
  npkt = [n_a0, n_a1, n_a2, n_a3, n_a4, n_a5, n_a6, n_hsk, n_pfp]

  if not keyword_set(silent) then begin
    print,""
    print,"SWEA Common Block:"
    print,n_pfp," Housekeeping packets (PFDPU)"
    print,n_hsk," Housekeeping packets (normal)"
    print,n_a6," Housekeeping packets (fast)"
    print,n_a0," 3D distributions (survey)"
    print,n_a1," 3D distributions (burst)"
    print,n_a2," PAD distributions (survey)"
    print,n_a3," PAD distributions (burst)"
    print,n_a4," ENGY Spectra (survey)"
    print,n_a5," ENGY Spectra (burst)"
    print,swe_active_tabnum,format='("Sweep Table: ",i2)'
    print,""

    if ~first then print,"Data time range: ",time_string(tsp[0])," - ",time_string(tsp[1])

    if (n_elements(swe_hsk) ne 2) then begin
      if (swe_cc_switch) then print,"SWE-SWI cross calibration enabled" $
                         else print,"SWE-SWI cross calibration disabled"

      if (swe_es_switch) then print,"Electron suppression correction enabled" $
                         else print,"Electron suppression correction disabled"

      case (swe_ff_state) of
        0 : print,"Flatfield correction disabled"
        1 : print,"Flatfield correction enabled"
        2 : print,"User-defined flatfield correction"
      endcase
    endif

    if (size(swe_mag1,/type) eq 8) then begin
      maglev = string(swe_mag1[0].level, format='("L",i1)')
      print,"MAG " + maglev + " data loaded"
    endif else print,"MAG data not loaded"

    print,""

    if keyword_set(full) then begin
      print, 'IDL ', !version.release
      help,'cdf',/dlm
      help,'icy',/dlm
      print,""
    endif
  endif

  return

end
