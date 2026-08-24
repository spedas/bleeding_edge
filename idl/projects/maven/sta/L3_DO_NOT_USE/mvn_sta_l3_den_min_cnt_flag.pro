;+
;STATIC L3 processing routine. Input the tplot variable names that contain the dat.cnts values for the 
;specific mass. This routine will flag when dat.cnts falls below the specified threshold. The output flag will
;be saved into a tplot variable (name also input to this routine). For the flag, 0=ok (dat.cnts > threshold); 1=bad 
;(dat.cnts - dat.bkg < threshold).
;
;
;INPUTS:
;tplotname: string: the tplot variable to look at, which contains the total counts as a function of time, for a STATIC apid and mass range.
;outname: string: the tplot variable that the flag output is saved into.
;
;mincnts: long: min number of counts needed; flag=0 if counts>=mincnts; flag=1 if counts<mincnts. Default is mincnts=25l if not set.
;
;OUTPUT:
;Routine will create a tplot variable containing a flag at each timestep. flag=0 means counts>= min counts; flag=1 means counts< min counts.
;The tplot variable will be named "tplotname_min_cnt_flag", where tplotname is input by the user.
;
;
;mvn_sta_l3_den_min_cnt_flag -> mvn_sta_l3_den_min_cnt_flag
;-


pro mvn_sta_l3_den_min_cnt_flag, tplotname, outname, mincnts=mincnts, success=success

proname = 'mvn_sta_l3_den_min_cnt_flag'

if size(tplotname, /type) ne 7 then begin
    print, proname, ": you must specify the tplot variable name that you want me to check."
    success=0
    return
endif

if size(outname, /type) ne 7 then begin
    print, proname, ": you must specify the tplot variable I should save the ouput to."
    success=0
    return
endif

if size(mincnts,/type) eq 0 then mincnts=25l

get_data, tplotname, data=ddcnts

if size(ddcnts, /type) ne 8 then begin
    print, proname, ": the input tplot variable doesn't contain any data."
    success=0
    return
endif

neleT = n_elements(ddcnts.x)
cnt_arr = fltarr(neleT)+1.  ;0=no problem, 1=flag. Default start is all flagged.

iOK = where(ddcnts.y ge mincnts, niOK)
if niOK gt 0 then cnt_arr[iOK] = 0.

store_data, outname, data={x: ddcnts.x, y: cnt_arr}
  ylim, outname, -1, 2
  options, outname, ytitle='STA!Ccnt flag'

success=1


end