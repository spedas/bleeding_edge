;+
;Check Jims new c6_c02 bkg routine - check what comes out in the dat structure - dat.bkg should now be complete.
;
;Load c6 data for a day. Run this routine - click a time at periapsis to look at. Routine will plot iv4 bkg, and then the updated
;c6-c02 bkg.
;
;
;
;.r /Users/cmfowler/IDL/STATIC_routines/Density_routines/mvn_sta_test_new_c6_co2.pro
;-
;

pro mvn_sta_test_new_c6_co2, twt=twt

@'qualcolors'

common mvn_c6, get_ind_c6, all_dat_c6

ctime, tt, npoints=1

iFI = where(all_dat_c6.time ge tt[0])
i=iFI[0]

dat1 = mvn_sta_get_c6(index=i)

dat2 = mvn_sta_get_c6_co2(index=i)

;Sum over energy array, plot mass vs counts:
massarray = dat1.mass_arr[0,*]

counts1 = dat1.cnts - dat1.bkg
if keyword_set(twt) then counts1 = counts1/dat1.twt_arr
counts1b = total(counts1,1)

counts2 = dat2.cnts - dat2.bkg
if keyword_set(twt) then counts2 = counts2/dat2.twt_arr
counts2b = total(counts2,1)

window, 1
cth=1.7
csi=1.7
time = time_string(dat2.time)+' - '+time_string(dat2.end_time)
yran = [1., 1.1*(max(counts1b) > max(counts2b))]
if keyword_set(twt) then ytitle='(Counts-bkg)/twt' else ytitle='Counts-bkg'
plot, massarray, counts1b, xtitle='Mass', ytitle=ytitle, /ylog, yrange=yran, ysty=1, title=time, charsize=csi, charthick=cth

oplot, massarray, counts2b, color=qualcolors.blue

oplot, [44,44], yran

xyouts, 0.6, 0.8, "mvn_sta_get_c6", /normal, charsize=csi, charthick=cth
xyouts, 0.6, 0.75, "mvn_sta_get_c6_co2", color=qualcolors.blue, /normal, charsize=csi, charthick=cth

stop


end

