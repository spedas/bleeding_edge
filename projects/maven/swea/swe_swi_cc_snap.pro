;+
;FUNCTION:   swe_swi_cc_snap
;PURPOSE:
;  Gets cross calibration factor from SWE-SWI density ratio.
;
;USAGE:
;  swe_swi_cc_snap
;INPUTS:
;
;KEYWORDS:
;CREATED BY:	David L. Mitchell  01-15-98
;FILE:  nibble.pro
;VERSION:  1.2
;LAST MODIFICATION:  01-31-98
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
