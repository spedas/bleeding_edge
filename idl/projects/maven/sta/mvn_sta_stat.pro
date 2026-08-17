;+
;PROCEDURE:   mvn_sta_stat
;PURPOSE:
;  Reports the status of STATIC data loaded into the common blocks.
;  Only checks the most-used APID's: c0, c6, c8, d0, d1.
;
;USAGE:
;  mvn_sta_stat
;
;INPUTS:
;
;KEYWORDS:
;
;    RESULT:        Returns an array of structures with the following tags:
;                     apid, nspec, trange, delta_t
;
;    ISUP:          Flag indicating whether or not ion suppression is enabled.
;
;    FULL:          If set, then display version information about IDL and the 
;                   SPICE and CDF dynamic load modules.
;
;    SILENT:        Shhhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-08-11 13:08:46 -0700 (Tue, 11 Aug 2026) $
; $LastChangedRevision: 34722 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_stat.pro $
;
;CREATED BY:    David L. Mitchell  Aug 2026
;-
pro mvn_sta_stat, result=result, isup=isup, full=full, silent=silent

  common mvn_sta_kk3_anode, kk3_anode
  common mvn_c0, mvn_c0_ind, mvn_c0_dat
  common mvn_c6, mvn_c6_ind, mvn_c6_dat
  common mvn_c8, mvn_c8_ind, mvn_c8_dat
  common mvn_d0, mvn_d0_ind, mvn_d0_dat
  common mvn_d1, mvn_d1_ind, mvn_d1_dat

  npkt = replicate(0L,5)
  str_element, mvn_c0_dat, 'time', time  &  npkt[0] = n_elements(time)
  str_element, mvn_c6_dat, 'time', time  &  npkt[1] = n_elements(time)
  str_element, mvn_c8_dat, 'time', time  &  npkt[2] = n_elements(time)
  str_element, mvn_d0_dat, 'time', time  &  npkt[3] = n_elements(time)
  str_element, mvn_d1_dat, 'time', time  &  npkt[4] = n_elements(time)

  trange = replicate(0D, 2, 5)
  dt = replicate(-1D, 5)
  result = {apid:'', nspec:0L, trange:[0D,0D], delta_t:0D}
  result = replicate(result,5)
  result.apid = ['c0','c6','c8','d0','d1']
  isup = keyword_set(kk3_anode)

  first = 1
  if (npkt[0] gt 0L) then begin
    trange[*,0] = minmax(mvn_c0_dat.time)
    tsp = trange[*,0]
    dt[0] = median(mvn_c0_dat.delta_t)
    first = 0
  endif
  if (npkt[1] gt 0L) then begin
    trange[*,1] = minmax(mvn_c6_dat.time)
    tsp = first ? trange[*,1] : minmax([tsp, trange[*,1]])
    dt[1] = median(mvn_c6_dat.delta_t)
    first = 0
  endif
  if (npkt[2] gt 0L) then begin
    trange[*,2] = minmax(mvn_c8_dat.time)
    tsp = first ? trange[*,2] : minmax([tsp, trange[*,2]])
    dt[2] = median(mvn_c8_dat.delta_t)
    first = 0
  endif
  if (npkt[3] gt 0L) then begin
    trange[*,3] = minmax(mvn_d0_dat.time)
    tsp = first ? trange[*,3] : minmax([tsp, trange[*,3]])
    dt[3] = median(mvn_d0_dat.delta_t)
    first = 0
  endif
  if (npkt[4] gt 0L) then begin
    trange[*,4] = minmax(mvn_d1_dat.time)
    tsp = first ? trange[*,4] : minmax([tsp, trange[*,4]])
    dt[4] = median(mvn_d1_dat.delta_t)
    first = 0
  endif

  if not keyword_set(silent) then begin
    if (total(npkt) gt 0L) then begin
      print,""
      print,"STATIC Common Blocks:"
      print,npkt[0]," c0 (64e  2m        )  delta_t = " + strtrim(string(round(dt[0])),2)
      print,npkt[1]," c6 (32e 64m        )  delta_t = " + strtrim(string(round(dt[1])),2)
      print,npkt[2]," c8 (32e     16d    )  delta_t = " + strtrim(string(round(dt[2])),2)
      print,npkt[3]," d0 (32e  8m  4d 16a)  delta_t = " + strtrim(string(round(dt[3])),2)
      print,npkt[4]," d1 (32e  8m  4d 16a)  delta_t = " + strtrim(string(round(dt[4])),2)
      print,""

      if ~first then begin
        print,"Data time range: ",time_string(tsp[0])," - ",time_string(tsp[1]),format='(4a,/)'
        if isup then print,mvn_sta_get_kk3(mean(tsp),/n),format='("Ion suppression (kk3) : ",4(f4.1,1x),/)' $
                else print,"Ion suppression not enabled.",format='(a,/)'
      endif
    endif else begin
      print,""
      print,"No STATIC data loaded."
      print,""
    endelse
  endif

  result.nspec = npkt
  result.trange = trange
  result.delta_t = dt

  if keyword_set(full) then begin
    print, 'IDL ', !version.release
    help,'cdf',/dlm
    help,'icy',/dlm
    print,""
  endif

end
