;
; THIS FUNCTION IS CALLED IN A SIMILAR (NEAR-IDENTICAL) WAY AS CREATEBOXPLOTDATA IN IDL
; 
; robustboxplotdata.pro (fylly in IDL) mimics the behavior of createboxplotdata.pro (written in C) but
; without crashing and burning when the number of useable points within the set is <5. 
; 
; Also: createboxplotdata ignores infinity, and averages median between center points for even 
; data points and does not produce quartiles but some other interpolated value to the data. 
; This program, robustboxplotdata, treats infinity as a very large positive or negative value (ignores NaNs);
; if the median is between 2 values it produces the lower value, and it also produces quartiles; 
; 
; mydata=[-1.,0.,-5.,0.5,-10.,+20.,1./0.,1./0.,-1./0.,-0./0.,-0./0.,0./0.,0./0.]
; mydata_sorted=mydata[sort(mydata)] ; this sorts +/-NaNs to the right but doesn't matter as NaNs are ignored
; 
; myboxc=createboxplotdata(mydata,mean_values=mydata_avg,ignore=-99.) ; ignores Inf, fits the data for median and quartiles!
; myboxr=robustboxplotdata(mydata,mean_values=mydata_avg,ignore=-99.) ; this does not ignore infinity (+Inf counts as a point), gives correct quartiles
; 
function robustboxplotdata,mydata,mean_values=mydata_avg,npnts_used=npntsgood,ignore=myignoreval,even=even
arrayinfo_raw=size(mydata)
if arrayinfo_raw[0] gt 2 then stop,'Array has more than 2 dimensions' ; can be 0, 1 or 2 only!
if arrayinfo_raw[0] eq 0 then mytemp=reform(mydata,1,1) ; turns single number into 2D array of 1 element, just in case
if arrayinfo_raw[0] eq 1 then mytemp=reform(mydata,1,arrayinfo_raw[3]) ; turns 1D array into 2D array of 1xN elements, just in case
if arrayinfo_raw[0] eq 2 then mytemp=mydata
arrayinfo=size(mytemp) ; now dimension is 2 for sure
arr_dim= arrayinfo[0]
ntotlpnts=arrayinfo[4] ; could have multiple quantities: nquants
mytype=arrayinfo[3]
ntimes=arrayinfo[2]
nquants=arrayinfo[1]
if keyword_set(myignoreval) then begin
  mytemp=reform(mytemp,ntotlpnts)
  iignore=where(abs(mytemp-myignoreval) lt 1.e-3*abs(myignoreval), jignore) ; if less than 10^-3 of ignorevalue
  if jignore gt 0 then mytemp[iignore]=!VALUES.F_NaN
  mytemp=reform(mytemp,nquants,ntimes)
endif
myresult=make_array(nquants,5,type=mytype) ; filled with zeros initially
mydata_avg=make_array(nquants,type=mytype) 
npntsgood=make_array(nquants,/long)
for jthquant=0,nquants-1 do begin
  imysort=sort(mytemp[jthquant,*])
  iuse=where(~finite(mytemp[jthquant,imysort],/NaN),juse); positive and negative NaNs are excluded
  npntsgood[jthquant]=juse
  if juse lt 1 then begin ; there are only NaNs here!
    myresult[jthquant,0:1]=mytemp[jthquant,imysort[0]] ; could be -NaNs
    myresult[jthquant,2:4]=mytemp[jthquant,imysort[ntimes-1]]; could be +NaNs
    mydata_avg[jthquant]=myresult[jthquant,2] ; pick the median NaN as the average
  endif else begin ; there are juse good data here
    myresult[jthquant,0]=mytemp[jthquant,imysort[0]] ; minimum is first good point
    myresult[jthquant,1]=mytemp[jthquant,imysort[long((25./100.)*juse)]] ; 25 percentile
    if 2*long(juse/2) eq juse then begin ; even even number of points then
      if keyword_set(even) then myresult[jthquant,2]=average(mytemp[jthquant,imysort[long((50./100.)*juse)-1:long((50./100.)*juse)]]) else $
      myresult[jthquant,2]=mytemp[jthquant,imysort[long((50./100.)*juse)-1]] ; 50 percentile
    endif else begin
      myresult[jthquant,2]=mytemp[jthquant,imysort[long((50./100.)*juse)]] ; if odd, always the midpoint
    endelse
    myresult[jthquant,3]=mytemp[jthquant,imysort[long((75./100.)*juse)]] ; 75 percentile    
    myresult[jthquant,4]=mytemp[jthquant,imysort[juse-1]] ; maximum is last good point, could be Inf
    mydata_avg[jthquant]=average(mytemp[jthquant,imysort[iuse]],/NaN); this excludes NaNs and Inf
  endelse
endfor
if arrayinfo_raw[0] lt 2 then begin
  myresult = reform(myresult,5)
endif
;stop
return,myresult
end