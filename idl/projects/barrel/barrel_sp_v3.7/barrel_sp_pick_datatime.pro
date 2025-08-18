;+
;NAME: barrel_sp_pick_datatime.pro
;
;DESCRIPTION: Pick start and stop times for spectral accumulation and
;background 

;
;REQUIRED INPUTS:
;ss                spectrum structure
;startdatetime     start time for plot from which we will pick source
;                  and background times, format yyyy-mm-dd/hh:mm:ss
;duration          duration in hours to look, starting at startdatetime
;payload           payload ID, with format, e.g., '1G'
;bkgmethod         1=select bkg intervals from data stream
;                  2=use bkg model from U. of Washington       
;
;OPTIONAL INPUTS:
;lcband            which FSPC band to plot during selection (default 1)
;uselog            plot FSPC data on a log scale (default 0)
;level             data CDF level (default 'l2')
;version           data CDF version for barrel_load_data.  If not
;                  specified, use that routine's default
;starttimes,endtimes,startbkg,endbkg:
;   start and end times (string format or unix epoch) for source
;   and background intervals (if not to be selected graphically)
;
;medticks,slowticks   Show vertical dotted lines at the start and
;                     and of medium, slow spectra (for use only
;                     when zoomed in to small times!
;
;OUTPUTS: No direct outputs, but the spectrum structure ss gets
;updated with trange and bkgtrange (primary purpose of this routine),
;also: payload,askdate, askduration, bkgmethod
;
;CALLS: barrel_load_data, barrel_selecttimes
;
;NOTES: 
;
;STATUS: 
;
;TO BE ADDED:
;
;REVISION HISTORY:
;Version 3.0 DMS 9/9/13
;   Most recent changes from v2.9:
;   remove passing x start and stop values to barrel_selecttimes 
;KY 8/28/13 'brl???_' -> 'brl' and '_LC' -> '_FSPC' (update tplot
;   variable names)
;9/30/13 -- remove "dobkg"; whether background intervals are
;   selected should automatically follow bkgmethod.
;10/1/13 -- put in option for already having specified the time ranges
;           by hand. (start/end times/bkgs)
;10/25/13 -- add provision for start/end times entered by hand to be
;           already in unix epoch (as from a prev. run)
;10/29/13 - Add plot of altitude to assist in background selection
;11/12/13 - Add option for vertical ticks for medium and slow spectra
;11/12/13 - Add default "no update" for reading FSPC data
;2/10/15 DMS - collect altitude using correct source time interval (average)
;3/5/15 DMS - cull out "NaNs" from altitude data before averaging
;8/20/15 DMS - fix bug wherein 3/5 fix only applied to
;              screen-selected, not predetermined time intervals.
;              This reorders operations somewhat 
;4/5/16 DMS - fixed erroneous "numspec" to "numbkg" when looping to
;             set multiple background intervals by hand.
;-

pro barrel_sp_pick_datatime,ss,startdatetime,duration,payload,bkgmethod,$
  lcband=lcband,uselog=uselog,level=level,version=version,$
  starttimes=starttimes,endtimes=endtimes,startbkgs=startbkgs,$
  endbkgs=endbkgs,mticks=mticks,sticks=sticks,altitude=altitude

if not keyword_set(level) then level='l2'
if not keyword_set(lcband) then lcband=1
if not keyword_set(uselog) then uselog=0

payload = strupcase(payload)   ;just in case it was entered lowercase
ss.payload = payload
ss.askdate = startdatetime
ss.askduration = duration
ss.bkgmethod = bkgmethod

;This time range should include what you will use for src and bkg, ideally
;startdatetime format 
;duration is in hours

timespan,startdatetime,duration,/hour

;Get altitude data:
if not keyword_set(altitude) then begin
  barrel_load_data, probe=payload, datatype=['GPS'], level=level,/no_clobber,$
    version=version
  varname='brl'+payload+'_GPS_Alt'
  tplot_names,varname, NAMES=matches2,/ASORT
  if (n_elements(matches2) EQ 1) then get_data, matches2[0], data=gpsalt
  altsum=0.d
  altnorm=0.d
endif

;If the times have already been specified by hand, use them and go: 
if keyword_set(starttimes) then begin

    typ = size(starttimes[0],/type)
    if typ EQ 7 then begin
       for i=0,ss.numsrc-1 do ss.trange[0,i] = str2time(starttimes[i],informat='YMDhms')
       for i=0,ss.numsrc-1 do ss.trange[1,i] = str2time(endtimes[i],informat='YMDhms')
    endif else begin
       for i=0,ss.numsrc-1 do ss.trange[0,i] = starttimes[i]
       for i=0,ss.numsrc-1 do ss.trange[1,i] = endtimes[i]
    endelse

    if ss.bkgmethod eq 1 then begin  
       typ = size(startbkgs[0],/type)
       if typ EQ 7 then begin
          for i=0,ss.numbkg-1 do ss.bkgtrange[0,i] = str2time(startbkgs[i],informat='YMDhms')
          for i=0,ss.numbkg-1 do ss.bkgtrange[1,i] = str2time(endbkgs[i],informat='YMDhms')
       endif else begin
          for i=0,ss.numbkg-1 do ss.bkgtrange[0,i] = startbkgs[i]
          for i=0,ss.numbkg-1 do ss.bkgtrange[1,i] = endbkgs[i]
       endelse
    endif
endif  else begin

barrel_load_data, probe=payload, datatype=['FSPC'], level=level,/no_clobber,$
    version=version,/no_update
varname='brl'+payload+'_FSPC'+strtrim(lcband,2)   
tplot_names,varname, NAMES=matches,/ASORT
if matches eq '' then begin
     print,'Warning: original LC band '+string(lcband)+' not available, using 1b!'
     varname='brl'+payload+'_FSPC1b'
     tplot_names,varname, NAMES=matches,/ASORT
endif    

if (n_elements(matches) EQ 1) then get_data, matches[0], data=lc $
else message, 'Bad number of variable name matches: '+ $
        strtrim(n_elements(matches))

if keyword_set(mticks) then begin
   barrel_load_data, probe=payload, datatype=['MSPC'], level=level,$
     version=version,/no_update
   varname='brl'+payload+'_MSPC'
   tplot_names,varname, NAMES=matches,/ASORT
   if (n_elements(matches) EQ 1) then get_data, matches[0], data=med $
   else message, 'Bad number of variable name matches for MSPC: '+ $
        strtrim(n_elements(matches))
   medsum = total(med.y,2)
endif

yr=strmid(startdatetime,0,4)
reads,yr,year
mo=strmid(startdatetime,5,2)
reads,mo,month
dy=strmid(startdatetime,8,2)
reads,dy,day
hr=strmid(startdatetime,11,2)
reads,hr,hour
mn=strmid(startdatetime,14,2)
reads,mn,minute
sc=strmid(startdatetime,17,2)
reads,mn,second

daystart = str2time(strmid(startdatetime,0,10),informat='YMD')
hourtimes = (lc.x - daystart)/3600.d
timestart = str2time(startdatetime,informat='YMDhms')
hourstart = (timestart-daystart)/3600.d

w=where(hourtimes GE hourstart and hourtimes LE hourstart+duration,nw)
if nw EQ 0 then begin
   print,'No data available in range!'
   return
end

if keyword_set(mticks) then begin
   hourtimes_med = (med.x - daystart)/3600.d
   wm=where(hourtimes_med GE hourstart and hourtimes_med LE hourstart+duration,nwm)
   if nwm EQ 0 then begin
        print,'No medium data available in range!'
        mticks=0
   endif
end

;set up plot
window,2,xsize=1200,ysize=600
!p.multi=[0,1,2]

;Plot altitude as well to guide bkg selection:
hourtimes2=(gpsalt.x-daystart)/3600.d
plot,hourtimes2,gpsalt.y,xrange=[hourstart,hourstart+duration],ytitle='Altitude, km'

;Now plot the actual lightcurve & hope the clicking will apply to this:
if uselog then yrange=[0.5,max(lc.y[w])*2.] else yrange=[0,max(lc.y[w])*1.1]
plot,hourtimes[w],lc.y[w],xrange=[hourstart,hourstart+duration],yrange=yrange,$
   ylog=uselog,xtitle='hours from start time',ytitle='counts/50ms'

if keyword_set(mticks) then begin
    medsumscale = medsum*max(lc.y[w])/max(medsum)
    oplot,hourtimes_med[wm],medsumscale[wm],psym=10,color=1
endif

for ns=0,ss.numsrc-1 do begin

  ;Select a subset of the data graphically:
  print,'Click at the left and right of a time range for spectral interval ',ns+1
  barrel_selecttimes,hourtimes,lc.y, datause, ndatause, color=3

  ;Fill in the appropriate part of the structure:
  ss.trange[*,ns] = [lc.x[datause[0]], lc.x[datause[ndatause-1]]]

end

if ss.bkgmethod eq 1 then begin  

  for nb=0,ss.numbkg-1 do begin

    ;Select a subset of the data graphically:
    print,'Click at the left and right of a time range for background interval ',nb+1
    barrel_selecttimes,hourtimes,lc.y, datause, ndatause, color=6

    ;Fill in the appropriate part of the structure:
    ss.bkgtrange[*,nb] = [lc.x[datause[0]], lc.x[datause[ndatause-1]]]

  end
endif

endelse

if not keyword_set(altitude) then begin 
      ;get altitude
      for i=0,ss.numsrc-1 do begin
        w=where(gpsalt.x ge ss.trange[0,i] and gpsalt.x le ss.trange[1,i],nw)
        ;patch for NaN values possible on day boundary (?):
        vals = gpsalt.y[w]
        wbad = where(finite(vals) eq 0,nbad)
        if nbad gt 0 then begin
           wfin=where(finite(vals))
           altave = average( vals[wfin] )
           vals[wbad] = altave
        endif
        altsum += total(vals)
        altnorm += 1.d * nw
      endfor
      altitude = altsum/altnorm
endif
  
altitude = altsum/altnorm
print,'ALTITUDE! ' , altitude

end
