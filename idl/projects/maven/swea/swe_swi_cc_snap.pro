;+
;FUNCTION:   swe_swi_cc_snap
;PURPOSE:
;  Gets cross calibration factor from SWE-SWI density ratio.
;
;USAGE:
;  swe_swi_cc_snap
;INPUTS:
;   None.      Data are selected from tplot window.
;
;KEYWORDS:
;   NRANGES:   Number of time ranges to select.
;
;   CCAL:      Cross calibration factors.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-08-02 11:15:31 -0700 (Wed, 02 Aug 2023) $
; $LastChangedRevision: 31976 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_swi_cc_snap.pro $
;
;CREATED BY:	David L. Mitchell, some time in 2014
;-
pro swe_swi_cc_snap, nranges=nranges, ccal=ccal

  ccal = 0  ; reset
  if (n_elements(nranges) eq 0) then nranges = 1

  for i=0,(nranges-1) do tmean, 'swe_swi_crosscal', result=ccal, outlier=3

  ostring = string(time_string(ccal[0].time,prec=-3),ccal[0].mean,format='(a,7x,"[",f4.2)')
  for i=1,(nranges-1) do ostring += string(ccal[i].mean,format='(", ",f4.2)')
  ostring += "]"
  for i=strlen(ostring),47 do ostring += " "
  ostring += string(mean(ccal.mean),stddev(ccal.mean) > mean(ccal.stddev),format='("--> ",f4.2," +- ",f4.2)')

  print,ostring,format='(/,a,/)'

  return

end
