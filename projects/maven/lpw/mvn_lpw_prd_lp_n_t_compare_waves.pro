;+
;THIS IS _V2: here I used oen set of params for Vsc > -1.5V. In this range, the corrections jump around, so the only way to do this is using  bulk stats for this region. Above this, corrections are a function of Vsc: this
;region is more stable and does not jump around. The corrections are also smaller. Compare_waves_lp4 is the major change in _V2 - I hard coded in the changes.
;
;Compare LPW waves densities with IV densities.
;.r /Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/mvn_lpw_prd_lp_n_t_compare_waves.pro
;
;compare_waves_lp1:
;Load in data for specified dates, save Ne, Te, Vsc, ErrA, NeWaves (NeW), altitude, position, UVI in a big save file, to be re-loaded in subsequent plotting routines.
;
;INPUTS:
;
;KEYWORDS:
;trange: string, two element array ['yyyy-mm-dd', 'yyyy-mm-dd'], the start and stop times to run the routine for. If not set the default range 2014-10-08 - 2015-11-31 will be used (when we have waves data).
;
;
;NOTES:
;The folder compare_data1 is for the default time range.
;
;-
;

pro compare_waves_lp1, trange=trange

if not keyword_set(trange) then trange = ['2014-10-08', '2015-11-31']

loadDIR1 = '/spg/maven/test_products/cmf_temp/filled_lpstruc19/'  ;<Feb 2015, better for bidir sweeps
loadDIR2 = '/spg/maven/test_products/cmf_temp/filled_lpstruc20/'  ;>Feb 2015, better for single sweeps
saveDIR = '/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/'

loadDIR1 = '/spg/maven/test_products/cmf_temp/filled_lpstruc19/'  ;<Feb 2015, better for bidir sweeps
loadDIR2 = '/spg/maven/test_products/cmf_temp/filled_lpstruc20/'  ;>Feb 2015, better for single sweeps

;WORK OUT WHICH FILES TO LOAD FROM WHICH FOLDER:
bidirDATE = time_double('2015-02-01')  ;from this time on use second folder above

fname = 'fitstruc_filled_*_b1.sav'  ;file names

files1 = file_search(loadDIR1+fname)  ;file filenames
files2 = file_search(loadDIR2+fname)

files1b = file_basename(files1)  ;just filename
files2b = file_basename(files1)

dates1 = strmid(files1b, 16, 10)  ;date
dates2 = strmid(files2b, 16, 10)

times1 = time_double(dates1)   ;UNIX times
times2 = time_double(dates2)

indsTMP1 = where(times1 lt bidirDATE)  ;bidir times that are ok in first folder
indsTMP2 = where(times2 ge bidirDATE, nindsTMP)   ;indices that have one dir sweeps

;COMBINE bidir sweeps with one dir sweeps into one folder:
filesF = [files1[indsTMP1], files2[indsTMP2]]   ;@#$^!#^@#% THIS CAN BE CHANGED IF WE USE A NEW FIT FOLDER WHERE BIDIR SWEEPS ARE OK 
datesF = [dates1[indsTMP1], dates2[indsTMP2]]
timesF = [times1[indsTMP1], times2[indsTMP2]]

tstart = time_double(trange[0])  ;start time
tfinish = time_double(trange[1])  ;end time

indsUSE = where(timesF ge tstart and timesF le tfinish, nFILES)  ;files to use that lie within trange.

icount = 0.
for ii = 0., nFILES-1. do begin  ;go over all files
      print, "I'm looking at file ", ii+1., " out of ", nFILES, "..."
      
      restore, filename=filesF[indsUSE[ii]]  ;load in file
      
      dateSTR = strmid(file_basename(filesF[indsUSE[ii]]), 16, 10)
      
      ;Find where valid eq 1:
      indsV = where(fitstruc.lpstruc.ree04.val.valid eq 1, nindsV)
      
      ;Store values. Subsequent plot routines will filter out bad values:
      structTMP = create_struct('Time'      ,   -999.d  , $
                                'ErrA'      ,   -999.   , $
                                'PosxMSO'   ,   -999.   , $
                                'PosyMSO'   ,   -999.   , $
                                'PoszMSO'   ,   -999.   , $
                                'Nlp'       ,   -999.   , $
                                'Nwa'       ,   -999.   , $
                                'NwaVALID'  ,   0.      , $
                                'Te'        ,   -999.   , $
                                'Vsc'       ,   -999.   , $
                                'UVI'       ,   -999.   , $
                                'AltIAU'    ,   -999.   )
                                
      structTMP2 = replicate(structTMP, nindsV)  ;replicate for each valid point.
      
      ;FILL IN DATA:
      structTMP2[*].Time = fitstruc.lpstruc[indsV].time
      structTMP2[*].ErrA = fitstruc.lpstruc[indsV].ree04.val.ErrA
      structTMP2[*].PosxMSO = fitstruc.lpstruc[indsV].anc.mso_pos.x                          
      structTMP2[*].PosyMSO = fitstruc.lpstruc[indsV].anc.mso_pos.y 
      structTMP2[*].PoszMSO = fitstruc.lpstruc[indsV].anc.mso_pos.z
      structTMP2[*].Nlp = fitstruc.lpstruc[indsV].ree04.val.N
      ;structTMP2[*].Nwa = fitstruc.lpstruc[indsV].wn.n   ;wave densities are shifted in fitstruc, use L2 data below
      ;structTMP2[*].NwaVALID = fitstruc.lpstruc[indsV].wn.valid
      structTMP2[*].Te = fitstruc.lpstruc[indsV].ree04.val.Te
      structTMP2[*].Vsc = fitstruc.lpstruc[indsV].ree04.val.Vsc
      structTMP2[*].UVI = fitstruc.lpstruc[indsV].ree04.val.UVI
      structTMP2[*].AltIAU = fitstruc.lpstruc[indsV].anc.alt_iau
  
      timespan, dateSTR, 1.
      mvn_lpw_load_l2, 'wn', /noTPLOT  ;get L2 wave data
  
      get_data, 'mvn_lpw_w_n_l2', data=dd1
      iKP = where(finite(dd1.y,/nan) eq 0., niKP)   ;find real data points
      tKP = dd1.x[iKP]
      dKP = dd1.y[iKP]
      for jj = 0., nindsV-1. do begin
          diff = abs(tKP - structTMP2[jj].TIME)
          m1 = min(diff, imin, /nan)
          
          if m1 lt 10. then begin
                structTMP2[jj].Nwa = dKP[imin]
                structTMP2[jj].NwaVALID = 1.
          endif
      endfor  ;jj
      
      
      if icount eq 0. then dataSTRUCT = structTMP2 else dataSTRUCT = [dataSTRUCT, structTMP2]  ;combine into large data structure.
      
      
      icount += 1.
endfor   ;ii
  
;SAVE:
fnameSAVE = 'compare_data.sav'
save, dataSTRUCT, filename=saveDIR+fnameSAVE

if file_search(saveDIR+fnameSAVE) ne '' then print, "File successfully saved at: ", saveDIR+fnameSAVE else print, "OOPS - I didn't save the file here - check why! ", saveDIR+fnameSAVE


end


;+
;Analyze the data saved from above. Enter various restrictions on what to plot below.
;
;INPUTS:
;filename: string, full directory name of file to load.
;
;
;KEYWORDS:
;errA: the value below which values are plotted. Default if not set is <50.
;VscH, VscL: values of Vsc to use: VscL < Vsc < VscH. Default if not used is -6 < Vsc < 5. NOTE don't use 0. as it's a keyword - it won't work, use 0.00001 or something.
;angCORRM: +1. or -1., manually set as auto software doesn't work.
;result: set to a variable that will contain the fitted parameters. 
;yesPLOT: set as a float: 1 to plot figures, 2 to NOT plot figures.
;
;compare_waves_lp2, '/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/compare_data.sav'   ;full datase with waves.
;
;-


pro compare_waves_lp2, filename, errA=errA, VscL=VscL, VscH=VscH, angCORRM=angCORRM, result=result, yesPLOT=yesPLOT

if not keyword_set(yesPLOT) then yesPLOT = 1.

;CHECKS:
if not keyword_set(errA) then errA = 50.
if not keyword_set(VscL) then VscL = -6. 
if not keyword_set(VscH) then VscH = 5.

NwaMAX = 49400. * 1.E6   ;the max density waves can measure. Don't use Nlp above this.

restore, filename=filename  ;loads dataSTRUCT

;====================
;====================
    ;RESTRICTIONS:
    ;Restrict by:
    ;Date
    ;Type - terminator, nightside, dayside, etc
    ;Density - pick good regions for waves: <1.E3, >1.E4, <cutoff for waves.
    ;UVI
    ;Altitude
    
    bidirTIME = time_double('2015-02-01')  ;time we didn't have bidir sweeps
    
    ;indsTMP = where(dataSTRUCT.NwaVALID eq 1. and dataSTRUCT.Nwa ne 0., npoints)  ;valid waves densities
    ;indsTMP = where(dataSTRUCT.NwaVALID eq 1. and dataSTRUCT.Nwa ne 0. and dataSTRUCT.Vsc gt VscL and dataSTRUCT.ErrA lt errA and dataSTRUCT.time ge bidirTIME, npoints)  ;valid waves densities, Vsc>-6, ErrA<50, >Feb 2015
    indsTMP = where(dataSTRUCT.NwaVALID eq 1. and dataSTRUCT.Nwa ne 0. and dataSTRUCT.Vsc gt VscL and dataSTRUCT.Vsc lt VscH and dataSTRUCT.ErrA lt errA and dataSTRUCT.time ge bidirTIME and dataSTRUCT.Nlp lt NwaMAX, npoints)

;====================
;====================

dataNlp = dataSTRUCT[indsTMP].Nlp / 1.E6  ;convert to /cc, pick data based on above restrictions
dataNwa = dataSTRUCT[indsTMP].Nwa
dataT = dataSTRUCT[indsTMP].Time


colors = bytscl(dataT)
iTMP = where(colors eq 255., niTMP)
if niTMP gt 0. then colors[iTMP] = 254. 

;PLOT:
;We believe waves are too low at N ~ 1.E3 - 1.E4, so do not fit in that region.
upp = 1.E4
low = 1.E3
iKP = where(dataNwa le low or dataNwa ge upp, niKP)  ;indices to keep

dataNwaKP = dataNwa[iKP]
dataNlpKP = dataNlp[iKP]

if yesPLOT eq 1. then begin
    ;waves N vs LP N
    yrangeN = [1.E1, 1.E6]
    pos1 = [0.1,0.1, 0.45,0.93]
    fs=22.
    p0 = plot(dataNwaKP, dataNlpKP, linestyle='none', symbol='.', /xlog, /ylog, yrange=yrangeN, xrange=yrangeN, xtitle='Nwaves [/cc]', ytitle='Nlp [/cc]', title='Uncorrected data', position=pos1, font_style=1, font_size=fs)
    
    ;1:1 LINES
    pl1 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]], linestyle='dashed', thick=3., color='red', overplot=p0)
    pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*1.25, linestyle='dashed', thick=3., color='red', overplot=p0)
    pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*0.75, linestyle='dashed', thick=3., color='red', overplot=p0)
endif
;######################
      ;PLOT MEDIAN Nlp value: 
      ;Due to log sizing on bins, split into 2 sections: 10<N<1000, binsizes of 20. 1000<N<1E5, binsizes of 500.  ;These ranges are hardcoded, not based on yrangeN.

      ;MEDIAN LOWER N BINS: (smaller binsize)
      result1 = compare_waves_lp3(dataNwa, dataNlp, 20., 10., 1.E3)

      ;MEDIAN UPPER N BINS: (larger binsize)
      result2 = compare_waves_lp3(dataNwa, dataNlp, 500., 1.E3, 1.E5)

      Xbins = [result1.Xbins, result2.Xbins]  ;bin locations used
      Ymed = [result1.med, result2.med]  ;median
      YmedU = [result1.medupp, result2.medupp]  ;median +- stddevs
      YmedL = [result1.medlow, result2.medlow]

     
      ;REMOVE NANS from array - log scale means a lot of higher points are NaN, and don't plot. 
      iTMP = where(finite(Xbins,/nan) eq 0., niTMP)  ;keep these points
      if niTMP gt 0. then begin
        Xbins = Xbins[iTMP]
        Ymed = Ymed[iTMP]
        YmedU = YmedU[iTMP]
        YmedL = YmedL[iTMP]
      endif
      
      if yesPLOT eq 1. then begin
          pmed = plot(Xbins, Ymed, color='purple', thick=3, overplot=p0)
          pmedup = plot(Xbins, YmedU, color='purple', thick=3, overplot=p0)
          pmeddo = plot(Xbins, YmedL, color='purple', thick=3, overplot=p0)
      endif
;######################

;=============
;FIT TO SLOPE:
;=============
;Fit line to medXT2 and medYT2
;y=A+Bx
;ladfit, result = [A,B]
;Sort X  values into ascending order first:
sortedX = sort(Xbins)
xx = Xbins[sortedX]
yy = Ymed[sortedX,0]

;Very lowest densities are very different correction from rest, so exclude for now. "Main" fit region is: 150 < N <1.E3, 1.E4<N  /cc.
lowDEN = 0. ;150.
iTMP = where((xx gt lowDEN and xx lt low) or (xx gt upp), niTMP)   ;SELECT HERE WHICH PARTS OF THE CURVE TO LOOK AT. Fit to just above 150/cc as will need a different line ebelow. Ignore middle densities
xx2 = xx[iTMP]
yy2 = yy[iTMP]

xx3 = alog10(xx2)   ;MAKE LOG SCALE
yy3 = alog10(yy2)
xxL = alog10(xx)  ;log this

;Make xxL out of many points, so that it has the resolution to find the correct crossing point:
xxL2 = (dindgen(500000)+1.)*1.
xxL2 = alog10(xxL2)

result = ladfit(xx3, yy3)     ;ladfit just the median, not +- stddev
ladplot = result[0] + (result[1] * xxL2)   ;NOTE: HERE we do ladfit for the entire x range - this is the model, through the bad parts of the curve. We need to know where the fit and data cross, which is in the middle of the bad part of the curve.
ladplot2 = result[0] + (result[1] * xx3)  ;fit for just the good parts of the curve

;Result is a fn(x) which is the waves density - we don't want this! Rearrange y=mx+c to x = (y-c)/m later so that we get the predicted waves density as a fn(lp density)

xx4 = 10.^xxL2  ;MAKE LINEAR SCALE AGAIN, for entire density range (good and bad)
yy4 = 10.^ladplot

if yesPLOT eq 1. then pfit = plot(xx4, yy4, color='blue', thick=3, overplot=p0)  ;plot linear scale arrays, but p0 is log-log.

;Subtract - the minimum in this array is where they cross. Do in log space still.
diff = abs(xxL2 - ladplot)   ;do in log space, entire curve, good and bad part
m1 = min(diff, imin, /nan)
Xp = xxL2[imin]  ;crossing point will be in the part of the curve
Yp = Xp  ;ladplot[imin]   ;Xp and Yp are where the fit line crosses the 1:1 line, so Xp should = Yp.

xxTMP2 = xxL2 ;for finding angCORR below
yyTMP2 = xxL2  

;Sometimes the fit line will not cross the 1:1 line. If this is the case, Yp will equal max(xxL) or min(xxL). If so, extrapolate the fit line for longer, until it crosses 1:1 line:
if Xp eq max(xxL2) then begin
    xxTMP = alog10(dindgen(50000000)*1000.)  ;if we're at the upper end, can use a smaller binsize as will be >1.E5
    yyTMP = alog10(dindgen(50000000)*1000.)  ;1:1 line
    fitTMP = result[0] + (result[1] * xxTMP)
    
    diff = abs(xxTMP - fitTMP)
    m1 = min(diff, imin, /nan)
    Xp = xxTMP[imin]
    Yp = yyTMP[imin]
    
    xxTMP2 = xxTMP
    yyTMP2 = yyTMP
endif
if Xp eq min(xxL2) then begin
    xxTMP = alog10(dindgen(5000000)*0.0000000002)  ;This is the 1:1 line. The top end must just overlap xxL so that Xp and Yp lies somewhere on [xxTMP, xxL].
    yyTMP = alog10(dindgen(5000000)*0.0000000002)    
    fitTMP = result[0] + (result[1] * xxTMP)
    
    diff = abs(xxTMP - fitTMP)
    m1 = min(diff, imin, /nan)
    Xp = xxTMP[imin]
    Yp = yyTMP[imin]
    
    xxTMP2 = xxTMP
    yyTMP2 = yyTMP
endif

;================
;DEFINE angCORR: This can be both ways. Pick median wave density, and corresponding fit value. IS the fit value above or below 1:1 line, and to left or right of Xp? These determine direction angCORR should be:
;Pick a point above Xp, call it Xp1. If Yp1 > Xp1 then line needs to rotate clockwise, and vice versa. If Xp1 is to the max right, then pick a point below it.
;Use xxTMP, yyTMP:
nelexxTMP = n_elements(xxTMP2)
iTMPx = where(xxTMP2 eq Xp)
iTMPy = where(yyTMP2 eq Yp)

iTMPx = iTMPx[0]  ;should really use double precisin but meh accurate enough
iTMPy = iTMPy[0]

if nelexxTMP gt 200. then len = 20. else len = 3.  
if iTMPx le nelexxTMP-len-1. then begin  ;if Xp and Yp are not the furthest max points:
      Xp1 = xxTMP2[iTMPx+len]  ;one point up is the indice for Xp, Yp, plus one.
      Yp1 = result[0] + (result[1]*Xp1)
      
      if Yp1 gt Xp1 then angCORR = 1.
      if Yp1 lt Xp1 then angCORR = -1.
endif else begin  ;if we have to use a point to the left of Xp:
      Xp1 = xxTMP2[iTMPx-len]
      Yp1 = result[0] + (result[1]*Xp1)
      
      if Yp1 lt Xp1 then angCORR = 1.
      if Yp1 gt Xp1 then angCORR = -1.
endelse

if keyword_set(angCORRM) then angCORR = angCORRM
;================
if yesPLOT eq 1. then begin
    pp1 = plot(10.^[Xp,Xp], [yrangeN[0], yrangeN[1]], overplot=p0, color='red')  ;plot crossing point
    pp2 = plot([yrangeN[0], yrangeN[1]], 10.^[Yp,Yp], overplot=p0, color='red')
endif
;=============
;Work out angle between median best fit, and 1:1 line:
;Pick a point on xx4 greater than Xp:
iTMP = where(xx3 gt Xp, niTMP)  ;now go back to using just the good part of the curve. 
if niTMP gt 0. then indTMP = iTMP[0] else indTMP = xx3[n_elements(xx3)-1.]  ;if curve never crosses 1:1 line, assume the best point is the highest xx3 we can go. Make sure the lowest density isn't actually the best!

Xf = xx3[indTMP]  ;x and y points on the fit line. We may want to use iTMP[>0] here.
Yf = ladplot2[indTMP]
X1 = Xf  ;on the 1:1 line, X=Y
Y1 = Xf

rtod = 180./!pi

;Use cosine rule to work out angle between the two lines. Positive angle is for fit line > 1:1 line when > Xp.
a3 = Yf - Y1  ;this should be positive for above definition
b3 = sqrt( (Xf-Xp)^2 + (Yf-Yp)^2 )   ;best fit line length from Xp to Xf,Yf
c3 = sqrt( (X1-Xp)^2 + (Y1-Yp)^2 )   ;1:1 line length from Xp tp X1,Y1
cosA = (b3^2 + c3^2 - a3^2) / (2.*b3*c3)
Ar = acos(cosA)  ;angle in radians, should be a few degrees
Ad = Ar * rtod  ;degrees

;=============
;We can now do a simply cartesian rotation through Ar to get the corrected densities.
;First, subtract Xp and Yp from the data so that the rotation point is from [0,0]
xn = xxL2 - Xp   ;do for entire curve.
yn = ladplot - Yp

;Rotate using [x'] = [ cos(Ar)   sin(Ar)] [xn]   ;THIS gives clockwise rotation for positive theta, as defined above. If theta is -ve, this should then rotate counter clockwise, the right way.
;             [y'] = [-sin(Ar)   cos(Ar)] [yn]

if angCORR eq 1. then begin
  ;Rotate using [x'] = [ cos(Ar)   sin(Ar)] [xn]   ;THIS gives clockwise rotation for positive theta, as defined above. 
  ;             [y'] = [-sin(Ar)   cos(Ar)] [yn]
    xpr = (        xn * cos(Ar)) + (yn * sin(Ar))
    ypr = ((-1.)*(xn * sin(Ar))) + (yn * cos(Ar))
endif else begin
  ;Rotate using [x'] = [ cos(Ar)  -sin(Ar)] [xn]   ;THIS gives anti clockwise rotation for positive theta, as defined above.
  ;             [y'] = [sin(Ar)    cos(Ar)] [yn]
    xpr = ( xn * cos(Ar)) - (yn * sin(Ar))
    ypr =  (xn * sin(Ar)) + (yn * cos(Ar)) 
endelse

;Add on Xp and Yp to shift to correct center point:
xpr += Xp  
ypr += Yp

;Convert back to linear:
xprL = 10.^xpr
yprL = 10.^ypr

;REPLOT:
if yesPLOT eq 1. then p20 = plot(xprL, yprL, color='green', overplot=p0, thick=3.)

;==============
;==============
;ADJUST DATA POINTS AND RECALCULATE MEDIAN ETC:

;NOTE that this shows theta is correct, but it is not the correct way to correct the data - x values need to stay constant, they don't here! Need to adjust y, based on theta, and how far from Xp,Yp you are:
;assume that correction to be applied is based on the median fit line - the only thing that matters is the x value of the data, not it's y value.
;if we have Xd and Yd, these are actual data. Work out Xp and Yp and theta (angle between data fit and 1:1 line).
;Work out best fit line for Xd: Fd is the value it should be to lie on top of the median line. Fd = result[0] + (result[1] * Xd). Yd=/=Fd - they are offset by theta.
;Use pythag to figure out what to subtract from Yd to get Yf: this is applied. See my MAVEN LPW notebook, page 6, for the diagram!
;dataNwaKP and dataNlpKP are the data in the good parts of the curve
;We have Ar (theta), Xp, Yp, result from above

    ;==========
    ;THIS CODE IS A FN(WAVES DENSITY). I NEED IT A FUNCTION OF LP DENSITY ONLY
 ;   sortI = sort(dataNwaKP)
 ;   Xd = alog10(dataNwaKP[sortI])  ;the data, correction done in log space
 ;   Yd = alog10(dataNlpKP[sortI])
 ;   Fd = result[0] + (result[1] * Xd)  ;these are what the Yd data would be if they fit the median fit line.
 ;   
 ;   cc = Xd - Xp  ;distance data is from Xp, in x direction
 ;   aa = Fd - Yp  ;distance data is from Yp, in y direction, for the fitted line.
 ;   
 ;   aa2 = cc * tan(45.*!pi/180.)  ;distance from Yp up to best fit line
 ;   aa1 = aa - aa2  ;difference in y that needs to be subtracted.
 ;   
 ;   Yd2 = Yd - aa1  ;corrected Y axis densities.
 ;   
 ;   ;Make linear:
 ;   Yd3 = 10.^Yd2
 ;   Xd3 = 10.^Xd
    ;===========

    ;==========
    ;THIS CODE IS A FN(LP DENSITY) ONLY: see page 7 of CMF notebook for diagram! Do not correct below ~150\cc, called lowDEN here.
    ;Split apart based on lowDEN, correct above lowDEN, recombine arrays at end.
    ilowDEN = where(dataNlpKP lt lowDEN, nilowDEN)  ;below 150  dataNlpKP is data that does not include 1.E3-1.E4, where waves is low.
    iuppDEN = where(dataNlpKP ge lowDEN, niuppDEN)  ;above
    
    ;Don't correct <lowDEN:
    YwaL = dataNwaKP[ilowDEN]  ;waves, for plotting only
    YwaU = dataNwaKP[iuppDEN]
    YlpL = dataNlpKP[ilowDEN]  ;lp density, for correcting
    YlpU = dataNlpKP[iuppDEN]
    
    ;Xd = alog10(dataNwaKP)  ;the data, correction done in log space. DO NOT USE WAVES DENSITY for actual correction, jsut plotting.
    Yd = alog10(YlpU)  ;only correct above lowDEN
    
    Xddd = (Yd-result[0])/result[1]
    
;    Fd = result[0] + (result[1] * Xd)  ;these are what the Yd data would be if they fit the median fit line. NOTE: we only use Fd to plot the line here for testing. Fd = Yd for actual processing.
    Fd = Yd

    aa = Fd - Yp  ;distance data is from Yp, in y direction, for the fitted line.
    angPL = (!pi/2.) - (!pi/4.) - Ar   ;the angle between the vertical and the fit to data line. 90 - 45 - Ar (but all in radians)
    Xl = aa * tan(angPL)  ;the "empircal" distance in X that the fit point is from Xp. We do this based on Ar, not the actual Waves density, as we don't want to use the waves density as an input.
    aa2 = Xl * tan(!pi/4.)  ;the value that Yd should be.
    
    aa1 = aa - aa2  ;difference in y that needs to be subtracted.

    Yd2 = Yd - (aa1*angCORR)  ;corrected Y axis densities for all data points. angCORR needed when correction goes other way sometimes.

    ;Make linear:
    Yd3U = 10.^Yd2 
    
    ;COMBINE:
    Yd3 = [YlpL, Yd3U]  ;linear numbers now, not logged.
    Xd3 = [YwaL, YwaU]
    ;===========

;PLOT:
if yesPLOT eq 1. then begin
    angSTR = strtrim(Ad,2)
    pos2 = [0.55,0.1, 0.95,0.93]
    p50 = plot(Xd3, Yd3, linestyle='none', symbol='.', /xlog, /ylog, yrange=yrangeN, xrange=yrangeN, xtitle='Nwaves [/cc]', ytitle='Nlp [/cc]', title='Corrected data, '+angSTR+' degrees', position=pos2, /current, font_style=1, font_size=fs)
    ;1:1 LINES
    pl10 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]], linestyle='dashed', thick=3., color='red', overplot=p50)
    pl11 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*1.25, linestyle='dashed', thick=3., color='red', overplot=p50)
    pl12 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*0.75, linestyle='dashed', thick=3., color='red', overplot=p50)
    pl20 = plot([lowDEN, lowDEN], [yrangeN[0], yrangeN[1]], overplot=p50, color='red')   ;values below this are not corrected.
    
    ;###################### This part copied from above
          ;PLOT MEDIAN Nlp value:
          ;Due to log sizing on bins, split into 2 sections: 10<N<1000, binsizes of 20. 1000<N<1E5, binsizes of 500.  ;These ranges are hardcoded, not based on yrangeN.
          
          ;MEDIAN LOWER N BINS: (smaller binsize)
          result1 = compare_waves_lp3(Xd3, Yd3, 10., 10., 1.E3)
        
          ;MEDIAN UPPER N BINS: (larger binsize)
          result2 = compare_waves_lp3(Xd3, Yd3, 200., 1.E3, 1.E5)
    
          Xbins = [result1.Xbins, result2.Xbins]  ;bin locations used
          Ymed = [result1.med, result2.med]  ;median
          YmedU = [result1.medupp, result2.medupp]  ;median +- stddevs
          YmedL = [result1.medlow, result2.medlow]
    
          ;REMOVE NANS from array - log scale means a lot of higher points are NaN, and don't plot.
          iTMP = where(finite(Xbins,/nan) eq 0., niTMP)  ;keep these points
          if niTMP gt 0. then begin
            Xbins = Xbins[iTMP]
            Ymed = Ymed[iTMP]
            YmedU = YmedU[iTMP]
            YmedL = YmedL[iTMP]
          endif
          
          pmed = plot(Xbins, Ymed, color='purple', thick=3, overplot=p50)
          pmedup = plot(Xbins, YmedU, color='purple', thick=3, overplot=p50)
          pmeddo = plot(Xbins, YmedL, color='purple', thick=3, overplot=p50)
    ;######################
endif  ;yesPLOT eq 1.



;=============




;ADJUST USING BOBS FUDGE FORMULA:
;fudge = 0.9 ; MY BEST EFFORT FROM DEEP DIP
;crossover = 10.0 ; 10^4 /cc density
;Nfix = 10^((alog10(dataNlpKP)-crossover)*fudge + crossover) 
;p0 = plot(dataNwaKP, Nfix, linestyle='none', symbol='.', /xlog, /ylog, yrange=yrangeN, xrange=yrangeN, xtitle='Nwaves [/cc]', ytitle='Nlp [/cc]', title='Fixed LP')



;INFORMATION:
print, ""
print, "There are ", npoints, " data points plotted."
print, ""
print, "Information:"
print, "Average Vsc: ", mean([VscL, VscH])
print, "Vsc range: ", VscL, VscH
print, "Xp, Yp: ", Xp, Yp
print, "Ar (radians, degrees):" , Ar, Ad
print, "result[0], [1]: ", result[0], result[1]
print, "angCORR: ", angCORR
print, ""

result = create_struct('Npts'     ,     npoints      , $
                       'VscL'     ,     VscL      , $
                       'VscH'     ,     VscH      , $
                       'VscM'     ,     (VscH+VscL)/2. , $
                       'Xp'       ,     double(Xp)        , $
                       'Yp'       ,     double(Yp)        , $
                       'Ar'       ,     double(Ar)        , $
                       'result0'  ,     result[0] , $
                       'result1'  ,     result[1] , $
                       'angCORR'  ,     angCORR  )


;TO DO: adjust binsizes, 500 => 100 probably ok.

;stop
end

;==============

;+
;Calculate median, and stddev (based on median) of some data. Give X,Y pairs as two arrays, binsize and min/max bin values. Returned are two arrays: the 'X axis' (the bins used), and the computed results as an Nx3 array: median, median+-stddev.
;Use the median instead of mean as this is much better for datasets that can have one or two large points the skew the mean.
;
;INPUTS:
;Xdata: array, X data points
;Ydata: array, Y data points
;binsize: size of bins
;low: lowest X value to consider when binning.
;upp: highest X value to consider when binning. Points outside of low and upp are not considered.
;
;
;KEYWORDS:
;
;RETURNS:
;structue containing two arrays:
;result.Xbins = bins used, for labeling the X axis.
;result.med = median value in each bin.
;result.medupp = median + stddev in each bin.
;result.medlow = median - stddev in each bin.
;
;
;-

function compare_waves_lp3, Xdata, Ydata, binsize, low, upp

;PARAMETERS
binsize1 = binsize
minbb1 = low ;smallest density to consider
maxbb1 = upp  ;largest
nbins1 = ceil((maxbb1 - minbb1)/binsize1)  ;hard coded at 10   ;DID fixing mibb fix this ??!@$%!$^!#%^!#%^

medX10 = fltarr(nbins1)+!values.f_nan  ;store values
medY10 = fltarr(nbins1,3)+!values.f_nan   ;rows: median, upper and lower stddev

for bb = 0., nbins1-1. do begin
  b1 = minbb1 + (binsize1*bb)  ;low and high limits of bin to look at
  b2 = b1 + binsize1
  midb = b1 + ((b2-b1)/2.)  ;midpoint of bin

  ;BASE on waves N:
  indsTMP = where(Xdata ge b1 and Xdata le b2, nindsTMP)  ;waves N in bin

  if nindsTMP gt 0. then begin
    lpnTMP = Ydata[indsTMP]  ;corresponding median LP N for bin
    lpnmed = median(lpnTMP)
    ;lpnstd = stddev(lpntmp)  ;stddev of data - this uses the mean - use stddev below
    lpnstd = sqrt( (1./nindsTMP) * total((lpnTMP - lpnmed)^2) )

    ;STORE:
    medX10[bb] = midb
    medY10[bb,0] = lpnmed
    medY10[bb,1] = lpnmed + lpnstd
    medY10[bb,2] = lpnmed - lpnstd
  endif
endfor

result = create_struct('Xbins'    ,   medX10  , $
                       'med'      ,   medY10[*,0] , $
                       'medupp'   ,   medY10[*,1] , $
                       'medlow'   ,   medY10[*,2] )

return, result


end


;==============
;==============

;+
;Things that need saving to work out correction to Nlp. These things are all a function of Vsc.
;Vsc middle - spacecraft potential: value at the middle of the bin used.
;Xp,Yp - point where median fit line (to data) crosses 1:1 line.
;Ar - angle between fit line and 1:1 line (radians)
;result[0], result[1]: A, B(*x) - constants for best fit line.
;
;
; = 6 parameters (1 indpendent (Vsc), 5 dependent).
;
;KEYWORDS:
;set /saveVALS to save the fitted parameters into an IDL save file structure.
;
;-

pro compare_waves_lp4, saveVALS=saveVALS

;Above -6v Vsc, we do not have enough points to do this reliably. 0 to -1 V is also a separate regime. To generate these arrays below I used compare_waves_lp2, 
;with a Vsc range of 0.5v. The lower and upper limits are slid across 0. to -7v, and the values recorded below. AngCORRM has to be set manually.

;NEW points are in a save file created by compare_waves_lp7:
restore, filename='/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/FIT_ARRAYS.sav'  ;hard  coded, restores 'data'

;==============
;THIS IS A MAJOR CHANGE: add in constant values for Vsc > -1.5:
;Split curve into three parts: lower, upper, and joining part.

;JOINING PART:
a = 1.8  ;X values at LHS and RHS, Y values determined later
b = 1.9
cutV = (-1.)*b  ;make -ve

iKP = where(data[*].VscM lt cutV, niKP)  ;keep data 
if niKP gt 0. then data = data[iKP]
;==============

neleD = n_elements(data[*].VscM)
start = 0.

;Take remaining data:
VscM = double(data[start:neleD-1].VscM)
result0 = data[start:neleD-1].result0
result1 = double(data[start:neleD-1].result1)

;==============


neleADD = b*10.  ;number of voltage points added
VscADD = (findgen(neleADD)/10.)*(-1.)
VscM = [VscADD, VscM]

result0 = [replicate(-0.0314670d, neleADD), result0]  ;straight lines below this
result1 = [replicate(1.03691d, neleADD), result1]
;==============
VscMP = VscM*(-1.)

neleV = n_elements(VscMP)  ;number of voltage points

frac = 1./6.5  ;each plot takes up this much y space  (extra space for x axis title at bottom)

p4 = plot(VscMp, result0, ytitle='result0', position=[0.1, 0.55, 0.9, 0.95], symbol='+')
p5 = plot(VscMp, result1, ytitle='result1', position=[0.1, 0.1, 0.9, 0.5], /current, symbol='+', xtitle='Voltage [V]')

;FIT PARAMETERS: split into 0 to -1, and -1 to -7 volts.

;========
;RESULT0:
;========
    X = VscMP
    Y = result0
       
    ;===========
    ;First part of curve:
    Ikp = where(X le a, N1)
    X1 = X[Ikp]
    Y1 = Y[Ikp]
    yfit1 = Y1
    
    ;===========
    ;Only ladfit to upper part of curve:
    Ilad = where(X ge b, N2)
    X2 = X[Ilad]  ;top part of curve
    Y2 = Y[Ilad]
    
    ladR2 = ladfit(X2, Y2)
    
    yfit2 = ladR2[0] + (ladR2[1]*X2)
    
    ;=============
    ;JOINING PART:
    c = yfit1[N1-1]  ;Y value at LHS at join
    d = yfit2[0]  ;Y value at RHS at join
    
    m = (d-c) / (b-a)  ;gradient of joining line
    cji = c - m*a  ;intercept of joining line
    
    
    length = b-a  ;width of join region
    npts=10.
    distp = length/npts
    xj = (findgen(npts+1.)*distp)+a  ;x points for joining line
    yj = xj*m + cji
    
    ;=========
    ;FULL EQN:
    ;=========
    ;Use tanh functions to join all three curves:
    Xall = findgen(7000.)/1000.
    ;FIRST JOIN:
    K1 = 10.
    K2 = 10.
    
    ;A VALUES:
    Aresult0KP = [K1, K2, a, b, c, d, yfit1[0], m, cji, ladR2[0], ladR2[1]]
    A1 = Aresult0KP
    
    ;yy1 = (yfit1[0]) + ((1. + tanh(K1*(Xall - a)))/2.) * (-yfit1[0] + (m*Xall) + cji)   +   ((1. + tanh(K2*(Xall-b)))/2.) * (-((yfit1[0]) + ((1. + tanh(K1*(Xall - a)))/2.) * (-yfit1[0] + (m*Xall) + cji)) + ladR2[0] + (ladR2[1]*Xall) )
    ;yy1 = (A1[6]) + ((1. + tanh(A1[0]*(Xall - A1[2])))/2.) * (-A1[6] + (A1[7]*Xall) + A1[8])   +   ((1. + tanh(A1[1]*(Xall-A1[3])))/2.) * (-((A1[6]) + ((1. + tanh(A1[0]*(Xall - A1[2])))/2.) * (-A1[6] + (A1[7]*Xall) + A1[8])) + A1[9] + (A1[10]*Xall) )
    yy1 = paramFIT(Xall, A1)
    
    p4b = plot(X1, yfit1, overplot=p4, color='red')
    p4c = plot(X2, yfit2, overplot=p4, color='red')
    p4d = plot(xj, yj, overplot=p4, color='red')
    p4e = plot(Xall, yy1, overplot=p4, color='blue')
    

;========
;RESULT1:
;========
    X = VscMP
    Y = result1
    
    ;===========
    ;First part of curve:
    Ikp = where(X le a, N1)
    X1 = X[Ikp]
    Y1 = Y[Ikp]
    yfit1 = Y1
    
    ;===========
    ;Only ladfit to upper part of curve:
    Ilad = where(X ge b, N2)
    X2 = X[Ilad]  ;top part of curve
    Y2 = Y[Ilad]
    
    ladR2 = ladfit(X2, Y2)
    
    yfit2 = ladR2[0] + (ladR2[1]*X2)
    
    ;=============
    ;JOINING PART:
    c = yfit1[N1-1]  ;Y value at LHS at join
    d = yfit2[0]  ;Y value at RHS at join
    
    m = (d-c) / (b-a)  ;gradient of joining line
    cji = c - m*a  ;intercept of joining line
    
    
    length = b-a  ;width of join region
    npts=10.
    distp = length/npts
    xj = (findgen(npts+1.)*distp)+a  ;x points for joining line
    yj = xj*m + cji
    
    ;=========
    ;FULL EQN:
    ;=========
    ;Use tanh functions to join all three curves:
    Xall = findgen(7000.)/1000.
    ;FIRST JOIN:
    K1 = 10.
    K2 = 10.
    
    Aresult1KP = [K1, K2, a, b, c, d, yfit1[0], m, cji, ladR2[0], ladR2[1]]
    A1 = Aresult1KP

    ;yy1 = (yfit1[0]) + ((1. + tanh(K1*(Xall - a)))/2.) * (-yfit1[0] + (m*Xall) + cji)   +   ((1. + tanh(K2*(Xall-b)))/2.) * (-((yfit1[0]) + ((1. + tanh(K1*(Xall - a)))/2.) * (-yfit1[0] + (m*Xall) + cji)) + ladR2[0] + (ladR2[1]*Xall) )
    ;yy1 = (A1[6]) + ((1. + tanh(A1[0]*(Xall - A1[2])))/2.) * (-A1[6] + (A1[7]*Xall) + A1[8])   +   ((1. + tanh(A1[1]*(Xall-A1[3])))/2.) * (-((A1[6]) + ((1. + tanh(A1[0]*(Xall - A1[2])))/2.) * (-A1[6] + (A1[7]*Xall) + A1[8])) + A1[9] + (A1[10]*Xall) )  ;this is the same eqn as result0
    yy1 = paramFIT(Xall, A1)
    
    p5b = plot(X1, yfit1, overplot=p5, color='red')
    p5c = plot(X2, yfit2, overplot=p5, color='red')
    p5d = plot(xj, yj, overplot=p5, color='red')
    p5e = plot(Xall, yy1, overplot=p5, color='blue')
    
  
;=============
;STORE VALUES:
;=============
if keyword_set(saveVALS) then begin
      params = create_struct('Aresult0'   ,   Aresult0KP  , $
                             'Aresult1'   ,   Aresult1KP  , $
                             'Aangcorr'   ,   1.   )
                             
     saveDIR = '/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/'
     fname1 = time_string(systime(1)) ;add date so we don't overwrite by mistake
     fname2 = strmid(fname1,0,10)+'T'+strmid(fname1,11,8) 
     fname3 = 'EMP_PARAMS_'+fname2+'.sav'
     save, params, filename=saveDIR+fname3                      
     
     if file_search(saveDIR+fname3) ne '' then print, "Parameter file successfully saved: ", saveDIR+fname3 else print, "### WARNING ### : Parameter file didn't save!"
     
endif

end

;==============
;==============

function paramFIT, X, A   ;new function for result0 and result1
  A1 = A
  Xall = X
  
  F = (A1[6]) + ((1. + tanh(A1[0]*(Xall - A1[2])))/2.) * (-A1[6] + (A1[7]*Xall) + A1[8])   +   ((1. + tanh(A1[1]*(Xall-A1[3])))/2.) * (-((A1[6]) + ((1. + tanh(A1[0]*(Xall - A1[2])))/2.) * (-A1[6] + (A1[7]*Xall) + A1[8])) + A1[9] + (A1[10]*Xall) )  ;this is the same eqn as result0
  
  return, F
end

;===================================
;===================================

;+
;This routine will correct LP densities as fn(Ne, Vsc). Give the routine Ne and Vsc from the LP fits. It will look up the correction parameters saved using the above routines. These parameters are then used to correct the data usign the formula within 
;the code. This formula is also in the above routines.
;
;RESTRICTIONS:
;Currently empircal correction only works for -0.1 > Vsc > -7  V. There is not enough data statistically do this correction outside of these ranges.
;
;INPUTS:
;N: density for LP (in units /cc) (float).
;Vsc: spacecraft potential from LP (volts, sign is negative for 99% of the mission) (float).
;Nwaves: waves density (/cc) (float) to compare with LP density.
;
;
;KEYWORDS:
;paramfile: string: name of param file to load.
;output: set to a named variable that will contain the output structure. This structure will contain Nin, Vscin, and Nout, the corrected densities. 
;VscR: Vsc range: set low to high, eg [-6., -1.], to only use points in that range. Default [-7., -0.1] used if not set. This is for plotting purposes only.
;Set /plotC to plot the corrected data. This requires you to specify the waves data as well. This will plot Nwaves vs Nlp. If you don't have Nwaves, the routine will still work, but cannot produce this plot.
;
;
;NOTES:
;Densities are converted to log10 space, corrected, and then converted back to linear. Correct units are essential!
;
;EXAMPLE:
;For Chris:
;d = compare_waves_lp6()
;compare_waves_lp5, d.nlp, d.vsc, d.nwa, paramfile='EMP_PARAMS_2016-03-01T17-40-21.sav', /plotC      ;plot the corrections as fn(Nwaves) - NOTE: you must give the routine Nwaves.
;
;
;For someone else:
;First set 'loadDIR' below to whereever you saved the params file.
;Get Nlp and Vsc in arrays, 'NinLP' and 'Vscin'.
;Use:
;
;compare_waves_lp5, NinLP, Vscin, paramfile='EMP_PARAMS_2016-02-09T19-10-41.sav', output=output ; OLD FILE ;don't give the routine Nwaves; just do the corrections, and return them in 'output'.
;compare_waves_lp5, NinLP, Vscin, paramfile='EMP_PARAMS_2016-02-16T16-15-15.sav', output=output  ; NEW FILE, params-2.
;compare_waves_lp5, NinLP, Vscin, paramfile='EMP_PARAMS_2016-02-29T21-56-46.sav', output=output  ;Latest params-1.
;compare_waves_lp5, NinLP, Vscin, Nwa, paramfile='EMP_PARAMS_2016-02-29T21-56-46.sav', output=output  ;Latest params-1., if you have waves
;compare_waves_lp5, NinLP, Vscin, Nwa, paramfile='EMP_PARAMS_2016-03-01T00-45-20.sav', output=output  ;Latest params, if you have waves
;compare_waves_lp5, NinLP, Vscin, Nwa, paramfile='EMP_PARAMS_2016-03-01T01-26-24.sav', output=output  ;Latest +1
;compare_waves_lp5, NinLP, Vscin, Nwa, paramfile='EMP_PARAMS_2016-03-01T17-40-21.sav',    ;latest+2
;
;compare_waves_lp5, d.NLP, d.Vsc, d.Nwa, paramfile='EMP_PARAMS_2016-03-03T19-34-50.sav'   ;latest+3 - NOTE: format change, I only save result0 and result1 now, so this file is different in compare_waves_lp_V2.pro.
;
;the array output will contain the input variables, and the corrected densities.
;This routine can be given any range of Vsc and density values - it will only correct those where -1>Vsc>-7 volts.
;
;
;-


pro compare_waves_lp5, N, Vsc, Nwaves, paramfile=paramfile, output=output, VscR=VscR, plotC=plotC

if size(Nwaves,/type) eq 0. then Nwaves = 0.
rtod = 180./!pi

;PARAM FILE:
loadDIR = '/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/'
restore, filename=loadDIR+paramfile  ;loads 'params'

if not keyword_set(VscR) then VscR = [-7., 0.]  ;default
vscSTR1 = strtrim(VscR,2)
vscSTR2 = vscSTR1[0]+' : '+vscSTR1[1]

;EMPIRCAL CORRECTIONS: This is copy and pasted from above:
;THIS CODE IS A FN(LP DENSITY) ONLY: see page 7 of CMF notebook for diagram! Do not correct below ~150\cc, called lowDEN here.

lowDEN = 0.

;KEEP DENSITY AND VSC in same order as input so can give output. Get parameters for all values, but only correct those that lie within the right ranges:
Nall0 = N
Vscall0 = Vsc
Nwavesall = Nwaves
neleIN = n_elements(Nall0)  ;number of points


    ;SEND IN ONLY HIGH DENSITIES! Not lowDEN. Arrays must all be the same size.
    ;Send in Vsc to get params for each point. Can use array math to do this:    

    Vsc3 = (-1.) * Vscall0  ;make positive for the below to work.
    
    Presult0 = paramFIT(Vsc3, params.Aresult0)
    Presult1 = paramFIT(Vsc3, params.Aresult1)
    PangCORR = params.Aangcorr  ;always 1 now.

    ;==================
    ;DERIVE PARAMETERS:
    ;==================
    ;We can use result[0] and [1], and a 1:1 line, to determine Xp, Yp, angle for all points. This will be more accurate than getting these parameters from the fitted functions (Xp and Yp in particular are not very accurate fits).
    ;angCORR will have to be a simple step function determined here.
    
    ;X ARRAY FOR RESULT AND 1:1 LINES:
    xxALL = (dindgen(500000)+1.)*1.  ;already in log space   ;OPTIMIZE NUMBER OF ELEMENTS HERE
    xxALL = alog10(xxALL)
    xxALLmax = max(xxALL,/nan)
    xxALLmin = min(xxALL,/nan)
       
    XpALL = fltarr(neleIN)  ;store Xp and Yp for all data points
    YpALL = fltarr(neleIN)
    
    ;Find Xp and Yp for all data points. This takes a long time:
    for abc = 0., (neleIN-1.) do begin
        resultYYTMP = Presult0[abc] + (Presult1[abc] * xxALL)  ;the y points for the fit lines based on Nlp, for N[abc].
        
        ;Find where the fit line crosses 1:1 line (yyALL = xxALL)
        diff = abs(xxALL - resultYYTMP)   ;find where they cross
        m1 = min(diff, imin, /nan)
        XpTMP = xxALL[imin]
  
        ;Sometimes the fit line will not cross the 1:1 line. If this is the case, Yp will equal max(xxL) or min(xxL). If so, extrapolate the fit line for longer, until it crosses 1:1 line:
        if XpTMP eq xxALLmax then begin
            xxTMP = alog10(dindgen(50000000)*1000.)  ;if we're at the upper end, can use a smaller binsize as will be >1.E5
            fitTMP = Presult0[abc] + (Presult1[abc] * xxTMP)
      
            diff = abs(xxTMP - fitTMP)
            m1 = min(diff, imin, /nan)
            XpTMP = xxTMP[imin]
        endif
        if XpTMP eq xxALLmin then begin
            xxTMP = alog10(dindgen(5000000)*0.0000000002)  ;This is the 1:1 line. The top end must just overlap xxL so that Xp and Yp lies somewhere on [xxTMP, xxL].
            fitTMP = Presult0[abc] + (Presult1[abc] * xxTMP)
      
            diff = abs(xxTMP - fitTMP)
            m1 = min(diff, imin, /nan)
            XpTMP = xxTMP[imin]    
        endif
         
        XpALL[abc] = (XpTMP)  ;crossing point will be in the part of the curve
        YpALL[abc] = (XpTMP)   ;If the result line is crossing the 1:1 line, then Xp = Yp by definition (1:1!).
         
    endfor  ;abc 

    ;Work out angle between median best fit, and 1:1 line. Result0,1 and Xp, Yp need to be in log space (I think)
    ;Equation of each line is simply DelX-Xp, DelY-Yp:
    Delx = alog10(100.)  ;equal jump for fit and 1:1
    
    Xoto1 = XpALL   ;1:1 line, point A
    Yoto1 = XpALL
    Xoto2 = XpALL+Delx ;point B
    Yoto2 = XpALL+Delx
      
    Xfit1 = XpALL ;fit line, where it crosses 1:1
    Yfit1 = XpALL
    Xfit2 = XpALL+Delx
    Yfit2 = (Presult0 + (Presult1*(XpALL+Delx)))   ;fit line, based on line eqn
    
    ;Use cosine rule to work out angle between the two lines. Positive angle is for fit line > 1:1 line when > Xp.
    a3 = Yfit2 - Yoto2  ;this should be positive for above definition  ;length of line opposite angle.
    b3 = sqrt( (Xfit2 - Xfit1)^2 + (Yfit2 - Yfit1)^2 )  ;length of fit line from Xp to Xp+Delx
    c3 = sqrt( (Xoto2 - Xoto1)^2 + (Yoto2 - Yoto1)^2 )      ;length of 1:1 line from Xp to Xp+Delx
    
    ;b3 = sqrt( (Xf-Xp)^2 + (Yf-Yp)^2 )   ;best fit line length from Xp to Xf,Yf
    ;c3 = sqrt( (X1-Xp)^2 + (Y1-Yp)^2 )   ;1:1 line length from Xp tp X1,Y1
    cosA = (b3^2 + c3^2 - a3^2) / (2.*b3*c3)
    Ar = acos(cosA)  ;angle in radians, should be a few degrees
    Ad = Ar ;* rtod  ;degrees  LEAVE IN RADIANS HERE!
    
    Pangles = Ad  ;final angles
    
    ;==================

;Correction done in log space. DO NOT USE WAVES DENSITY for actual correction, just plotting.
Yd = alog10(Nall0)
Xddd = (Yd-Presult0)/Presult1

;Fd = result[0] + (result[1] * Xd)  ;these are what the Yd data would be if they fit the median fit line. NOTE: we only use Fd to plot the line here for testing. Fd = Yd for actual processing.
Fd = Yd

aa = Fd - YpALL   ;PYp  ;distance data is from Yp, in y direction, for the fitted line.
angPL = (!pi/2.) - (!pi/4.) - Pangles   ;the angle between the vertical and the fit to data line. 90 - 45 - Ar (but all in radians)
Xl = aa * tan(angPL)  ;the "empircal" distance in X that the fit point is from Xp. We do this based on Ar, not the actual Waves density, as we don't want to use the waves density as an input.
aa2 = Xl * tan(!pi/4.)  ;the value that Yd should be.

aa1 = aa - aa2  ;difference in y that needs to be subtracted.

lowdenC = (Nall0 gt lowDEN)

;RANGE OVER VSC WHICH CAN BE CORRECTED:
vscCORR1 = 0.  ;"actual" values
vscCORR2 = -7.
vscCORR1a = abs(vscCORR1)  ;absolute values
vscCORR2a = abs(vscCORR2)

vscC = (Vscall0 ge vscCORR2 and Vscall0 le vscCORR1)   ;this is '1' if Vsc lies within the accepted range, and zero if not.

;Smoothing functions at either end of Vsc range:
;Smooth the correction factor aa1 from 100% to 0% over the course of 0.25 volts at either end:
lv1a = vscCORR1a  ;the range of smoothing for each end
lv1b = vscCORR1a + 0.5  ;these are the ranges over which to smooth the correction down to zero so we get smooth ends within the correction range of  Vsc
lv2a = vscCORR2a - 0.5
lv2b = vscCORR2a

smooth11 = 1. - ((Vsc3 lt lv1b) * ((lv1b - Vsc3)/(lv1b-lv1a)))  ;smooth valeus at either end of Vsc range, so that we don't get a jump outside of the allowed range.
smooth22 = 1. - ((Vsc3 gt lv2a) * ((Vsc3 - lv2a)/(lv2b-lv2a)))  

Yd2 = Yd - ((aa1*PangCORR) * lowdenC * vscC * smooth11 * smooth22)  ;corrected Y axis densities for all data points. angCORR needed when correction goes other way sometimes. ONLY CORRECT DENSITIES ABOVE 150 /CC, and Vsc within -7 to -0.1 v.

;Make linear:
NallOUT = 10.^Yd2

;OUTPUT:
output = create_struct('Nin'      ,     N ,  $   ;waves density may not be given. Only use that for plotting below.
                       'Vscin'    ,     Vsc,  $
                       'Nout'     ,     NallOUT  )


if keyword_set(plotC) then begin
      if size(Nwaves , /type) eq 0. then begin
          print, ""
          print, "### WARNING ###: To plot the corrected results you must give me corresponding wave densities, Nwaves. I am trying to plot Nwaves vs Nlp. Output still contains the corrected density values, I just can't make this plot without Nwaves."
          return
      endif

      ;======================
      ;PLOT BEFORE AND AFTER:
      ;======================
      ;Remove any points with Nwaves between 1.E3 and 1.E4 so they don't mess up the plot (Nwaves too low).
      indsKP = where(Nwaves lt 1.E3 or Nwaves gt 1.E4, nindsNAN)
      if nindsNAN gt 0. then begin
          NwavesKP = Nwaves[indsKP]
          NKP = N[indsKP]
          NcorrKP = NallOUT[indsKP]
      endif
      
      fs = 22.
      pos1 = [0.1,0.1, 0.45,0.93]
      pos2 = [0.55,0.1, 0.95,0.93]
      yrangeN = [1.E1, 1.E6]
      p1 = plot(NwavesKP, NKP, linestyle='none', symbol='.', xtitle='Waves N [/cc]', ytitle='LP N [/cc]', title='Before', font_style=1, font_size=fs, position=pos1, xrange=yrangeN, yrange=yrangeN, /xlog, /ylog)
      
          ;1:1 LINES
          pl1 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]], linestyle='dashed', thick=3., color='red', overplot=p1)
          pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*1.25, linestyle='dashed', thick=3., color='red', overplot=p1)
          pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*0.75, linestyle='dashed', thick=3., color='red', overplot=p1)
      
          ;=============
          ;PLOT MEDIAN Nlp value:
          ;Due to log sizing on bins, split into 2 sections: 10<N<1000, binsizes of 20. 1000<N<1E5, binsizes of 500.  ;These ranges are hardcoded, not based on yrangeN.
          
          ;MEDIAN LOWER N BINS: (smaller binsize)
          result1 = compare_waves_lp3(NwavesKP, NKP, 20., 10., 1.E3)
          
          ;MEDIAN UPPER N BINS: (larger binsize)
          result2 = compare_waves_lp3(NwavesKP, NKP, 500., 1.E3, 1.E5)
          
          Xbins1 = [result1.Xbins, result2.Xbins]  ;bin locations used
          Ymed1 = [result1.med, result2.med]  ;median
          YmedU1 = [result1.medupp, result2.medupp]  ;median +- stddevs
          YmedL1 = [result1.medlow, result2.medlow]
          
          ;REMOVE NANS from array - log scale means a lot of higher points are NaN, and don't plot.
          iTMP = where(finite(Xbins1,/nan) eq 0., niTMP)  ;keep these points
          if niTMP gt 0. then begin
            Xbins1 = Xbins1[iTMP]
            Ymed1 = Ymed1[iTMP]
            YmedU1 = YmedU1[iTMP]
            YmedL1 = YmedL1[iTMP]
          endif
          
          pmed = plot(Xbins1, Ymed1, color='purple', thick=3, overplot=p1)
          pmedup = plot(Xbins1, YmedU1, color='purple', thick=3, overplot=p1)
          pmeddo = plot(Xbins1, YmedL1, color='purple', thick=3, overplot=p1)
          ;============
      
      p2 = plot(NwavesKP, NcorrKP, linestyle='none', symbol='.', xtitle='Waves N [/cc]', title='Corrected', font_style=1, font_size=fs, position=pos2, /current, xrange=yrangeN, yrange=yrangeN, /xlog, /ylog)
      
          ;1:1 LINES
          pl1 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]], linestyle='dashed', thick=3., color='red', overplot=p2)
          pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*1.25, linestyle='dashed', thick=3., color='red', overplot=p2)
          pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*0.75, linestyle='dashed', thick=3., color='red', overplot=p2)
      
          ;=============
          ;PLOT MEDIAN Nlp value:
          ;Due to log sizing on bins, split into 2 sections: 10<N<1000, binsizes of 20. 1000<N<1E5, binsizes of 500.  ;These ranges are hardcoded, not based on yrangeN.
          
          ;MEDIAN LOWER N BINS: (smaller binsize)
          result1 = compare_waves_lp3(NwavesKP, NcorrKP, 20., 10., 1.E3)
          
          ;MEDIAN UPPER N BINS: (larger binsize)
          result2 = compare_waves_lp3(NwavesKP, NcorrKP, 500., 1.E3, 1.E5)
          
          Xbins2 = [result1.Xbins, result2.Xbins]  ;bin locations used
          Ymed2 = [result1.med, result2.med]  ;median
          YmedU2 = [result1.medupp, result2.medupp]  ;median +- stddevs
          YmedL2 = [result1.medlow, result2.medlow]
          
          ;REMOVE NANS from array - log scale means a lot of higher points are NaN, and don't plot.
          iTMP = where(finite(Xbins2,/nan) eq 0., niTMP)  ;keep these points
          if niTMP gt 0. then begin
            Xbins2 = Xbins2[iTMP]
            Ymed2 = Ymed2[iTMP]
            YmedU2 = YmedU2[iTMP]
            YmedL2 = YmedL2[iTMP]
          endif
          
          pmed = plot(Xbins2, Ymed2, color='purple', thick=3, overplot=p2)
          pmedup = plot(Xbins2, YmedU2, color='purple', thick=3, overplot=p2)
          pmeddo = plot(Xbins2, YmedL2, color='purple', thick=3, overplot=p2)
          ;============
      
      ;=============
      ;PLOT CHANGES:
      ;=============
      ;Plot old and new median lines on top of each other and the 1:1 lines to see differences:
      p100 = plot([0.], [0.], /nodata, font_style=1., font_size=fs, xtitle='Waves N [/cc]', ytitle='LP N [/cc]', title='Median fit lines, Vsc: '+vscSTR2, xrange=yrangeN, yrange=yrangeN, /xlog, /ylog)
      
      ;1:1 LINES
      pl1 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]], linestyle='dashed', thick=3., color='red', overplot=p100)
      pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*1.25, linestyle='dashed', thick=3., color='red', overplot=p100)
      pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*0.75, linestyle='dashed', thick=3., color='red', overplot=p100)
      
      ;Original in blue:
      pmed = plot(Xbins1, Ymed1, color='blue', thick=3, overplot=p100)
      pmedup = plot(Xbins1, YmedU1, color='blue', thick=3, overplot=p100)
      pmeddo = plot(Xbins1, YmedL1, color='blue', thick=3, overplot=p100)
      
      ;Corrected in green:
      pmed = plot(Xbins2, Ymed2, color='green', thick=3, overplot=p100)
      pmedup = plot(Xbins2, YmedU2, color='green', thick=3, overplot=p100)
      pmeddo = plot(Xbins2, YmedL2, color='green', thick=3, overplot=p100)
      
      ;Mark lowDEN, and region not looked at due to low waves:
      paa1 = plot([lowDEN, lowDEN], [yrangeN[0], yrangeN[1]], overplot=p100, color='grey',thick=2.)
      paa2 = plot([1.E3, 1.E3], [yrangeN[0], yrangeN[1]], overplot=p100, color='grey',thick=2.)
      paa3 = plot([1.E4, 1.E4], [yrangeN[0], yrangeN[1]], overplot=p100, color='grey',thick=2.)
      
      print, ""
      print, "Number of points (all, just fit): ", n_elements(N), n_elements(NcorrKP)

endif  ;/plotC

;stop


end



;=================
;=================

;+
;Routine to load in NE and Vsc from a save file. Output is filtered for ErrA and valid, and is a data structure.
;
;EXAMPLE:
;d = compare_waves_lp6()
;
;-


function compare_waves_lp6, errA=errA, VscL=VscL, VscH=VscH

restore, filename='/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/compare_data.sav'

if not keyword_set(errA) then errA = 50.
if not keyword_set(VscL) then VscL = -7.
if not keyword_set(VscH) then VscH = -0.1

bidirTIME = time_double('2015-02-01')  ;time we didn't have bidir sweeps
indsTMP = where(dataSTRUCT.NwaVALID eq 1. and dataSTRUCT.Nwa ne 0. and dataSTRUCT.Nlp lt 1.E11 and dataSTRUCT.Vsc gt VscL and dataSTRUCT.Vsc lt VscH and dataSTRUCT.ErrA lt errA and dataSTRUCT.time ge bidirTIME, npoints)

;GET DATA:
dataNlp = dataSTRUCT[indsTMP].Nlp / 1.E6  ;convert to /cc, pick data based on above restrictions
dataNwa = dataSTRUCT[indsTMP].Nwa
dataT = dataSTRUCT[indsTMP].Time
dataVsc = dataSTRUCT[indsTMP].Vsc

dataR = create_struct('Nlp'   ,   dataNlp   , $
                      'Nwa'   ,   dataNwa   , $
                      'Vsc'   ,   dataVsc   , $
                      'time'  ,   dataT  )

return, dataR

end



;==============
;==============

;+
;Use compare_waves_lp2 to generate data arrays containing fit parameters. This routine uses a for loop to generate the values for many Vsc values quickly.
;The data are put into a save file.
;
;
;-

pro compare_waves_lp7

saveDIR = '/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/'
fname = 'FIT_ARRAYS.sav'

DVsc = 0.02  ;move up median Vsc by this much each step

maxVsc = -0.1
minVsc = -7.
neleVsc = ceil((maxVsc-minVsc)/DVsc)
window = 0.05  ;the Vsc range is 2*window below

for ii = 0., neleVsc-1. do begin
    VscMID = maxVsc - (ii*Dvsc)
    Vsc1 = VscMID+window  ;Vsc range
    Vsc2 = VscMID-window
    
    compare_Waves_lp2, '/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/compare_data.sav', VscH=Vsc1, VscL=Vsc2, result=result, yesPLOT = 2.
    
    ;STORE RESULTS:
    if ii eq 0. then data = create_struct('Npts'     ,     result.npts      , $
                                          'VscL'     ,     result.VscL      , $
                                          'VscH'     ,     result.VscH      , $
                                          'VscM'     ,     result.VscM      , $
                                          'Xp'       ,     result.Xp        , $
                                          'Yp'       ,     result.Yp        , $
                                          'Ar'       ,     result.Ar        , $
                                          'result0'  ,     result.result0 , $
                                          'result1'  ,     result.result1 , $
                                          'angCORR'  ,     result.angCORR  ) else data = [data, result]
  
endfor  ;ii


;SAVE:
save, data, filename=saveDIR+fname
if file_search(saveDIR+fname) ne '' then print, "File successfully saved: ", saveDIR+fname else print, "### WARNING ### : file didn't save!", filename+fname

end


;=============
;=============

;+
;Routine to plot the surface contour of the corrections used as fns(vsc, density). This routine makes a 2D array where one axis is Vsc, one is density. It uses
;compare_waves_lp7 to feed in these values, and calculates the correction to density. This is saves in the 2D array. The surface of this array is then plotted.
;
;KEYWORDS:
;set loadFILE to string - the filename to load in a datagrid instead of deriving. This is much quicker.
;set save='filename.sav' to save the datagrid into a save file, with this filename. Save directory is set below.
;
;
;EXAMPLES:
;compare_waves_lp8, loadFILE='LPcorrectionDATA_HiRes.sav'   ;hi res grid file
;compare_waves_lp8, loadFILE='LPcorrectionDATA_LowRes.sav'   ;low res grid file (for testing)
;
;
;-

pro compare_waves_lp8, loadFILE=loadFILE, save=save

if keyword_set(loadFILE) then begin
    loadDIR = '/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/'
    if file_search(loadDIR+loadFILE) eq '' then begin
        print, ""
        print, "I can't find a file with this name: ", loadDIR+save
        return
    endif
    
    restore, filename=loadDIR+loadFILE  ;loads 'LPcorrectionDATA'
    
    correction = LPcorrectionDATA.grid1
    vscAXIS = LPcorrectionDATA.xAXIS
    denAXIS = LPcorrectionDATA.yAXIS
    xBIN = LPcorrectionDATA.xBIN
    yBIN = LPcorrectionDATA.yBIN
endif else begin

      ;MAKE ARRAYS:
      vscMAX = 1.
      vscMIN = -9.
      vscBIN = 0.1  ;binsize/increment
      vscAXIS = [vscMIN : vscMAX : vscBIN]  ;make array
      neleVsc = n_elements(vscAXIS)
      
      denMAX = 7.  ;logged values
      denMIN = 1.
      denBIN = 0.1
      denAXIS = 10.^[denMIN : denMAX : denBIN]  ;make into real values
      neleDEN = n_elements(denAXIS)
      
      correction = fltarr(neleVsc, neleDEN)
      
      ;Go over each axis, storing correction amount into 2D array:
      for vv = 0., neleVSC-1. do begin
            for dd = 0., neleDEN-1. do begin
                  vscTMP = vscAXIS[vv]  ;new values
                  denTMP = denAXIS[dd]
                  
                  compare_waves_lp5, denTMP, vscTMP, paramfile='EMP_PARAMS_2016-03-03T19-34-50.sav' , output=output
                  
                  denNEW = output.Nout  ;corrected density [in /cc]
                  correctTMP = ((denNEW - denTMP) / denTMP) * 100.  ;correction % 
                  
                  correction[vv,dd] = correctTMP
          
            endfor  ;dd  
      endfor  ;vv

endelse  ;not load
     
fs = 22.
p0 = surface(correction, vscAXIS, denAXIS, xtitle='Vsc', ytitle='Density [/cc]', /ylog, font_style=1, font_size=fs)
;p2 = surface(correction2, vscAXIS, denAXIS, xtitle='Vsc', ytitle='Density [/cc]', /ylog, font_style=1, font_size=fs)


;p1 = surface(smooth(correction,[70,30]), vscAXIS, denAXIS, xtitle='Vsc', ytitle='Density [/cc]', /ylog, font_style=1, font_size=fs)

      
      
      
;X and Y grids to interpolate to: this doesn't work very well for some reason
if 'y' eq 'n' then begin
    ;Interpolate to finer grid:
    ;Run through grid_input to sort
    denAXIS2 = alog10(denAXIS)  ;log for interpolation
  
    ;To use triangulate etc, I must enter data as 1D arrays, not a 2D matrix. Rebin everything to 1D arrays here:
    neleC = n_elements(correction)
    neleR = n_elements(correction[0,*])  ;number of rows
    neleCol = n_elements(correction[*,0])  ;number of columns
    xNEW = vscAXIS
    yNEW = denAXIS2
    dNEW = correction[*,0]
    for ii = 1., neleR-1. do xNEW = [xNEW, vscAXIS[*]]   ;start at ii = 1. as we have the first row already
    for ii = 1., neleCol-1. do yNEW = [yNEW, denAXIS2[*]]
    for ii = 1., neleR-1. do dNEW = [dNEW, correction[*,ii]]
  
    grid_input, xNEW, yNEW, dNEW, xSORTED, ySORTED, dataSORTED, duplicates='First'  ;sort x,y, f values in order for next step
  
    xmin = -9.
    xmax = 1.
    xbin = 0.01
    xaxisTMP = [xmin : xmax : xbin]
    neleX = n_elements(xaxisTMP)
    
    ymin = 1.
    ymax = 7.
    ybin = 0.1
    yaxisTMP = [ymin : ymax : ybin]
    neleY = n_elements(yaxisTMP)
    
    gridSize = [neleX,neleY]
    ;Produce X and Y axes:
    startVALS = [min(xaxisTMP), min(yaxisTMP)]
    delta = [xbin,ybin]
    xAXIS = (findgen(gridsize[0])*delta[0])+startVALS[0]
    yAXIS = (findgen(gridsize[1])*delta[1])+startVALS[1]
    
    ;Run through griddata to grid
    triangulate, xsorted, ysorted, triangles
    correction2 = GridData(xSORTED, ySORTED, dataSORTED, /NATURAL_NEIGHBOR, TRIANGLES=triangles, DELTA=delta, DIMENSION=gridSize, START=startVALS, MISSING=!Values.F_NAN)
    
    ;PLOT:
    p20 = surface(correction2, xAXIS, yAXIS, xtitle='Vsc', ytitle='Density [/cc]', font_style=1, font_size=fs)
endif


;Cut off above a certain value:
correction2 = correction
if n_elements(vscAXIS) gt 200 then smf = 200. else smf = 50.  ;low res grid needs to smooth over fewer points.
maxP = 0.
ism = where(correction2 gt maxP, nism)
;if nism gt 0. then correction2[ism] = maxP + ((correction2[ism]-maxP)/4.)  ;reduce by factor of 10 if over limit
if nism gt 0. then correction2[ism] = maxP

p2 = surface(correction2, vscAXIS, denAXIS, xtitle='Vsc', ytitle='Density [/cc]', /ylog, font_style=1, font_size=fs)
p3 = surface(smooth(correction2,200, /edge_mirror), vscAXIS, denAXIS, xtitle='Vsc', ytitle='Density [/cc]', /ylog, font_style=1, font_size=fs)

if keyword_set(save) then begin
    ;STORE 2D GRID, and USE to get to get new densities based in indices:
    LPcorrectionDATA = create_struct('grid1'  ,     correction    , $  ;raw grid
                                     'grid2'  ,     correction2   , $  ;after some tinkering
                                     'xAXIS'  ,     vscAXIS         , $
                                     'yAXIS'  ,     denAXIS         , $
                                     'xMIN'   ,     min(vscAXIS)        , $
                                     'xMAX'   ,     max(vscAXIS)        , $
                                     'xBIN'   ,     xBIN                , $
                                     'yMIN'   ,     min(denAXIS)        , $
                                     'yMAX'   ,     max(denAXIS)        , $
                                     'yBIN'   ,     yBIN  )

    saveDIR = '/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/'       
    fname = save   ;'LPcorrectionDATA.sav'
    
    save, LPcorrectionDATA, filename = saveDIR+fname        
endif



stop

end


;============
;============

;+
;New way of calculating correction amount based on a 2D grid. Using Vsc and density, the  correct indices are calculated and the correction amount (%) identified. This is applied to the input density, to give the output.
;This method will be faster then compware_waves_lp5.
;
;Currently empircal correction only works for -0.1 > Vsc > -7  V. There is not enough data statistically do this correction outside of these ranges.
;
;INPUTS:
;NlpIN: density for LP (in units /cc) (float).
;VscIN: spacecraft potential from LP (volts, sign is negative for 99% of the mission) (float).
;NwaIN: waves density (/cc) (float) to compare with LP density. If not set, this is ignored. If set, a before and after plot will be produced.
;filename: string: the full directory and filename of the IDL save file containing the 2D surface information.
;
;OUTPUTS:
;NlpOUT: set to a variable to contain the corrected densities, in the same order as they were input.
;success: 0 means no success. 1 means successful
;corrected: an array of same length NlpIN: it will contain 1s and 0s: 1 means this indice was corrected, 0 means it was not (it lays outside of the correction ranges applicable).
;
;
;EXAMPLES:
;compare_waves_lp9, d.Nlp, d.Vsc, d.Nwa, filename='/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/LPcorrectionDATA_HiRes.sav', NlpOUT=NlpOUT, corrected=corrected, success=success
;
;-

pro compare_waves_lp9, NlpIN, VscIN, NwaIN, filename=filename, NlpOUT=NlpOUT, success=success, corrected=corrected

success = 0.

;CHECKS:
if n_elements(VscIN) ne n_elements(NlpIN) then begin
    print, ""
    print, "### VscIN and NlpIN must be arrays of the same length."
    return
endif

corrected = fltarr(n_elements(VscIN))

if file_search(filename) eq '' then begin
    print, ""
    print, "### I couldn't find the load file: ", filename
    return
endif else restore, filename=filename  ;loads in 'LPcorrectedDATA'

;Log densities to get even spaced bins in log space:
NlpIN2 = alog10(NlpIN)
VscIN2 = (-1.) * VscIN

;GET INDICES BASED on position in the 2D grid:
Nmin = alog10(LPcorrectionDATA.yMIN)
Nmax = alog10(LPcorrectionDATA.yMAX)
Vmin = LPcorrectionDATA.xMIN
Vmax = LPcorrectionDATA.xMAX
neleX = n_elements(LPcorrectionDATA.xAXIS)
neleY = n_elements(LPcorrectionDATA.yAXIS)

indsY = floor( (NlpIN2 - Nmin) / (LPcorrectionDATA.yBIN))  ;note that indices that lay outside of Nmin/max and Vmin/max will still have real values, but will be negative, or greater than the number of elements in the axis arrays. These should
indsX = floor( (VscIN - Vmin) / (LPcorrectionDATA.xBIN))  ;correspond to the indices below.

iKP = where(VscIN gt Vmin and VscIN lt Vmax and NlpIN2 gt Nmin and NlpIN2 lt Nmax, niKP)

Ncorrected = NlpIN  ;copy, so that we can keep arrays in the same order.

if niKP gt 0. then begin
    for ii = 0., niKP-1. do begin
          cfTMP = LPcorrectionDATA.grid2[indsX[iKP[ii]], indsY[iKP[ii]]]   ;the % to multply by, ranges from ~-40% to +40%
          cf2TMP = (100. + cfTMP)/100.  ;cfTMP is + or -, so cf2TMP will be between 0.6 and 1.4
          Ncorrected[iKP[ii]] = 10.^(NlpIN2[iKP[ii]]) * cf2TMP  ;apply correction in REAL SPACE! 
          corrected[iKP[ii]] = 1.  ;this step was corrected         
    endfor  
    success = 1.
endif  ;iKP

NlpOUT = Ncorrected

;PLOT CORRECTIONS IF WAVES GIVEN:
if size(NwaIN,/type) ne 0. then begin  ;if waves were also input
    ;Only plot waves densities that lie in good ranges:
    iKP2 = where(NwaIN lt 1.E3 or NwaIN gt 1.E4, niKP2)
    NwavesKP = NwaIN[iKP2]
    NKP = NlpIN[iKP2]
    NCKP = Ncorrected[iKP2]
    
    ;Plot original data:
    fs=22.
    pos1 = [0.1,0.1, 0.45,0.93]
    pos2 = [0.55,0.1, 0.95,0.93]
    yrangeN = [1.E1, 1.E6]
    p0 = plot(NwavesKP, NKP, symbol='.', linestyle='none', xtitle='Waves [/cc]', ytitle='LP [/cc]', title='Before', /xlog, /ylog, font_style=1, font_size=fs, yrange=yrangeN, xrange=yrangeN, position=pos1)
    
    ;1:1 LINES
    pl1 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]], linestyle='dashed', thick=3., color='red', overplot=p0)
    pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*1.25, linestyle='dashed', thick=3., color='red', overplot=p0)
    pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*0.75, linestyle='dashed', thick=3., color='red', overplot=p0)
    
        ;=============
        ;PLOT MEDIAN Nlp value:
        ;Due to log sizing on bins, split into 2 sections: 10<N<1000, binsizes of 20. 1000<N<1E5, binsizes of 500.  ;These ranges are hardcoded, not based on yrangeN.
    
        ;MEDIAN LOWER N BINS: (smaller binsize)
        result1 = compare_waves_lp3(NwavesKP, NKP, 20., 10., 1.E3)
    
        ;MEDIAN UPPER N BINS: (larger binsize)
        result2 = compare_waves_lp3(NwavesKP, NKP, 500., 1.E3, 1.E5)
    
        Xbins1 = [result1.Xbins, result2.Xbins]  ;bin locations used
        Ymed1 = [result1.med, result2.med]  ;median
        YmedU1 = [result1.medupp, result2.medupp]  ;median +- stddevs
        YmedL1 = [result1.medlow, result2.medlow]
    
        ;REMOVE NANS from array - log scale means a lot of higher points are NaN, and don't plot.
        iTMP = where(finite(Xbins1,/nan) eq 0., niTMP)  ;keep these points
        if niTMP gt 0. then begin
          Xbins1 = Xbins1[iTMP]
          Ymed1 = Ymed1[iTMP]
          YmedU1 = YmedU1[iTMP]
          YmedL1 = YmedL1[iTMP]
        endif
    
        pmed = plot(Xbins1, Ymed1, color='purple', thick=3, overplot=p0)
        pmedup = plot(Xbins1, YmedU1, color='purple', thick=3, overplot=p0)
        pmeddo = plot(Xbins1, YmedL1, color='purple', thick=3, overplot=p0)
        ;============

    ;CORRECT DATA:
    p1 = plot(NwavesKP, NCKP, symbol='.', linestyle='none', xtitle='Waves [/cc]', ytitle='LP [/cc]', title='After', /xlog, /ylog, font_style=1, font_size=fs, yrange=yrangeN, xrange=yrangeN, position=pos2, /current) 
    
    ;1:1 LINES
    pl1 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]], linestyle='dashed', thick=3., color='red', overplot=p1)
    pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*1.25, linestyle='dashed', thick=3., color='red', overplot=p1)
    pl2 = plot([yrangeN[0], yrangeN[1]], [yrangeN[0], yrangeN[1]]*0.75, linestyle='dashed', thick=3., color='red', overplot=p1)
    
    ;OLD FIT:
    pmed = plot(Xbins1, Ymed1, color='purple', thick=3, overplot=p1)
    pmedup = plot(Xbins1, YmedU1, color='purple', thick=3, overplot=p1)
    pmeddo = plot(Xbins1, YmedL1, color='purple', thick=3, overplot=p1)
    
        ;=============
        ;PLOT MEDIAN Nlp value:
        ;Due to log sizing on bins, split into 2 sections: 10<N<1000, binsizes of 20. 1000<N<1E5, binsizes of 500.  ;These ranges are hardcoded, not based on yrangeN.
    
        ;MEDIAN LOWER N BINS: (smaller binsize)
        result1 = compare_waves_lp3(NwavesKP, NCKP, 20., 10., 1.E3)
    
        ;MEDIAN UPPER N BINS: (larger binsize)
        result2 = compare_waves_lp3(NwavesKP, NCKP, 500., 1.E3, 1.E5)
    
        Xbins1 = [result1.Xbins, result2.Xbins]  ;bin locations used
        Ymed1 = [result1.med, result2.med]  ;median
        YmedU1 = [result1.medupp, result2.medupp]  ;median +- stddevs
        YmedL1 = [result1.medlow, result2.medlow]
    
        ;REMOVE NANS from array - log scale means a lot of higher points are NaN, and don't plot.
        iTMP = where(finite(Xbins1,/nan) eq 0., niTMP)  ;keep these points
        if niTMP gt 0. then begin
          Xbins1 = Xbins1[iTMP]
          Ymed1 = Ymed1[iTMP]
          YmedU1 = YmedU1[iTMP]
          YmedL1 = YmedL1[iTMP]
        endif
    
        pmed = plot(Xbins1, Ymed1, color='green', thick=3, overplot=p1)
        pmedup = plot(Xbins1, YmedU1, color='green', thick=3, overplot=p1)
        pmeddo = plot(Xbins1, YmedL1, color='green', thick=3, overplot=p1)
        ;============  
  
endif

;stop
end




;============
;============

pro mvn_lpw_prd_lp_n_t_compare_waves, N, Vsc, Nwaves, paramfile=paramfile, NlpOUT=NlpOUT, corrected=corrected, success=success
  
  ;paramfile='/Users/chfo8135/IDL/MAVEN/Software/analysis_software/ImprovedFitRoutines/compare_waves_lp/compare_data1/LPcorrectionDATA_HiRes.sav'
  
  ;COMPARE_WAVES_LP5, N, Vsc, Nwaves, paramfile=paramfile, output=output, VscR=VscR, plotC=plotC
  compare_waves_lp9, N, Vsc, Nwaves, filename=paramfile, NlpOUT=NlpOUT, corrected=corrected, success=success

end























