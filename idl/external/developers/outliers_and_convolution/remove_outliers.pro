;+
; NAME:
;     REMOVE_OUTLIERS
;
; PURPOSE:
;	Routine eliminates outliers. Quadratic trend is determined in a hollow
;	vicinity of each point. The data value is compared with the trend 
;	value. If the deviation is statistically improbable, the value is 
;	repaired. There are 6 options for repair to be set in the subroutine
;	remove_outliers_repair.pro. Routine gives the summary of its work: how 
;	many of the total number of numeric values were repaired, and the number
;	of failure cases (when it was impossible to establish a trend).
;
; CATEGORY:
;	Data Processing
;
; CALLING SEQUENCE:
;	remove_outliers, epoch, valuesin, d, tmax, nmax
;
; INPUTS:
;	EPOCH: time array for the data values. Any time units may be used, 
;		just do it consistently. Double 1D array.
;  VALUESIN: 1D array of values to filter; its numerical values are 
;		replaced by filtered data at the end.
;	D: half-size of the hollow vicinity of the point where trend is 
;		established (integer)
;	TMAX: maximal time interval covered by the hollow vicinity (double)
;	NMAX: maximal deviation from the trend deemed to be probable 
;		(in units of standard deviation). Integer.
;
; KEYWORDS: None
;
; PARAMETERS: Repair option set in subroutine remove_outliers_repair.pro.
;
; OUTPUTS:
;	VALUESIN: Array of filtered values (numerical values of input are replaced).
;     The code may produce "division by zero" warnings originated in the svdfit 
;     routine. They should be ignored.
;
; DEPENDENCIES: remove_outliers_repair.pro
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2007/12/28.
;-
;
; THE CODE BEGINS:

pro remove_outliers,epoch,valuesin,d,tmax,nmax

svin=size(valuesin)
ndim=svin[0]
if ndim eq 1 then begin
   vals=fltarr(svin[1],1)
   vals[*,0]=valuesin
   nvec=1
endif
if ndim eq 2 then begin
   vals=valuesin
   nvec=svin[2]
endif

for iii=0,nvec-1 do begin ;++++++++++++++++++++++++++++++++++++++
values=reform(vals[*,iii])

!quiet=1
nfail=0
ncorr=0

indgood=where(finite(values),ngood)
if ngood le 1 then begin
   print,'remove_outliers: No good values found. Exiting.'
   return
endif
valgood=values[indgood]
epgood=epoch[indgood]
nvalgood=ngood
valrms=fltarr(ngood)

;Evaluation starts
for i=0L,nvalgood-1 do begin
   now=epgood[i]
   valrms[i]=sqrt(abs(valgood[i]))
;print,'i= ',i
   indneib=[i-d]
   for j=1,2*d do indneib=[indneib,i-d+j]
   while indneib[0] lt 0 do indneib=indneib+1
   while indneib[2*d] ge nvalgood do indneib=indneib-1
   indin=where(indneib ge 0 and indneib lt nvalgood,nin)
   indneib=indneib[indin]
   indnoself=where(indneib ne i,nno)
   if nno gt 0 then begin
      indneibh=indneib[indnoself]
      timeneibh=epgood[indneibh]
      gap=0
      if max(abs(timeneibh-now)) gt tmax then begin
         gap=1
         tdiff=timeneibh-now
         stay=where(abs(tdiff) le tmax,nstay)
         if nstay gt 1 then indstayh=indneibh[stay] else gap=2
      endif
      if gap eq 0 then begin
         valneibh=valgood[indneibh]
         tnminti=epgood[indneibh]-now
      endif
      if gap eq 1 then begin
         valneibh=valgood[indstayh]
         tnminti=epgood[indstayh]-now
      endif
      if gap eq 2 then begin
         nfail=nfail+1
         continue
      endif
      valiin=valgood[i]
      remove_outliers_repair,valneibh,tnminti,valiin,nmax,valiout
      valgood[i]=valiout
      if valiin ne valiout then ncorr=ncorr+1
   endif
endfor
;return repaired values
values[indgood]=valgood
vals[*,iii]=values

print,'remove_outliers: removed outliers'
print,ngood,' finite values,',ncorr,' outliers repaired, in',$
   nfail,' points evaluation is impossible.'

endfor ;++++++++++++++++++++++++++++++++++++++++++++++++++++++++
valuesin=vals

return
end
