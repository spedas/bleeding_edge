;+
;
;NAME:
;  iug_plot2d_ionogram
;
;PURPOSE:
;  Generate several ionogram plots from the ionogram data taken by the ionosonde. 
;
;SYNTAX:
;  iug_plot2d_ionogram, valuename=valuename
;
;KEYWOARDS:
;  VALUENAME = tplot variable names of ionosonde observation data.  
;         For example, iug_plot2d_ionogram,valuename = 'iug_ionosonde_sgk_ionogram'.
;         The default is 'iug_ionosonde_sgk_ionogram'.
;
;CODE:
;  A. Shinbori, 11/01/2013.
;  
;MODIFICATIONS:
;  A. Shinbori, 09/01/2014.
;  
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_plot2d_ionogram, valuename=valuename

;*****************
;Value name check:
;*****************
if not keyword_set(valuename) then valuename='iug_ionosonde_sgk_ionogram'

;window,0,xs=512,ys=512
;loadct,39

;Get the ionogram data from tplot variable:
if strlen(tnames(valuename[0])) eq 0 then begin
   print, 'Cannot find the tplot vars in argument!'
   return
endif
get_data,valuename,data=d

;Number of total frames:
Nt=n_elements(d.y[*,0,0])
print,'The number of total frames: ',Nt
print,n_elements(d.y[0,*,0]),n_elements(d.y[0,0,*])

;Definition of temporary array:
tmp=fltarr(n_elements(d.y[0,*,0]),n_elements(d.y[0,0,*]))

X=round(fix(Nt)/4)
if Nt le 3 then begin 
   Y=Nt
endif else begin
   Y=4
endelse
print, X, Y

;Set up the window size of ionogram plot:
window ,0, xsize=1280,ysize=800,TITLE='IUGONET ionosonde data:'

;plot ionograms:
for t=0,Nt-1 do begin
   tmp[*,*]=d.y[t,*,*]
   time = d.x[t]
   if t eq 0 then begin
      plotxyz,d.v1,d.v2,tmp,/noisotropic,/interpolate,xtitle='Frequency [MHz]',ytitle='Height [km]',ztitle ='Echo power [dBV]',$
              multi= strtrim(string(X),2)+','+strtrim(string(Y),2),window=0,charsize =0.75, title = time_string(time),xmargin=[0.2,0.2],ymargin=[0.18,0.18]
   endif else begin
      plotxyz,d.v1,d.v2,tmp,/noisotropic,/interpolate,/add,xtitle='Frequency [MHz]',ytitle='Height [km]',ztitle ='Echo power [dBV]',$
              window=0,charsize =0.75, title = time_string(time),xmargin=[0.2,0.2],ymargin=[0.18,0.18]
   endelse
endfor
end