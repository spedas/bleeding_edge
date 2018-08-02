;+
;
;NAME:
;  iug_plot2d_ear_fai
;
;PURPOSE:
;  Generate several 2-D plots from the FAI f-region observation data taken by the EAR. 
;
;SYNTAX:
;  iug_plot2d_ear_fai, valuename=valuename
;
;KEYWOARDS: 
;  VALUENAME = tplot variable names of ionosonde observation data.  
;         For example, iug_plot2d_ear_fai,valuename = 'faifb8p16m1'.
;         The default is 'faifb8p16m1'.
;  STIME = Start time of 2-D plot of the EAR-FAI observations.
;         For example, iug_plot2d_ear_fai, stime = '2012-03-23/15:00:00'.
;         The default is '2012-03-23/15:00:00'.
;  MINIMUM = Minimum value of color plot. For example, iug_plot2d_ear_fai, min = 0.
;         The default is 0.
;  MAXIMUM = Maximum value of color plot. For example, iug_plot2d_ear_fai, max = 60.
;         The default is 60.
;  ZTICKS = Number of zticks to divide the bar into. There will be (zticks + 1) annotations. 
;         The default is 6.
;  CHARSIZE = Select of character size. For example, iug_plot2d_ear_fai, charsize = 1.5.
;         The default is 1.5.
;NOTES:
;  Before you examine this procedure, the EAR-FAI data are necceary to load.
;
;CODE:
;  A. Shinbori, 08/07/2013.
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

pro iug_plot2d_ear_fai, valuename=valuename, $
   stime=stime, $
   minimum=minimum, $
   maximum=maximum, $
   zticks=zticks, $
   charsize=charsize

;*****************
;Value name check:
;*****************
if not keyword_set(valuename) then valuename='faifb8p16m1'

;*****************
;Start time check:
;*****************
if not keyword_set(stime) then valuename='2012-03-23/15:00:00'

;*******************
;Min and max check:
;*******************
if not keyword_set(minimum) then minimum=0
if not keyword_set(maximum) then maximum=60

;*******************
;Zticks check:
;*******************
if not keyword_set(zticks) then zticks=6

;*******************
;Charsize check:
;*******************
if not keyword_set(charsize) then charsize=1.5

;Call the color table:
loadct,39

;Definition of azimuth and zenith angles for each observation mode:
if (valuename eq 'faifb8p16') then begin
   Az=[171.0,174.0,177.0,180.0,183.0,186.0,189.0,192.0]
   Ze=[24.2,24.1,24.0,24.0,24.1,24.2,24.4,24.6]
endif
if (valuename eq 'faifb8p16m1') or (valuename eq 'faifb8p16k1') or (valuename eq 'faifb8p16k3') then begin
   Az=[125.0,137.0,151.0,165.0,180.0,195.0,209.0,223.0]
   Ze=[37.5,30.9,26.6,24.5,23.8,24.7,27.2,32.1]
endif
if (valuename eq 'faifb8p16m2') or (valuename eq 'faifb8p16k2') or (valuename eq 'faifb8p16k4') then begin
   Az=[130.0,144.0,158.0,172.0,188.0,202.0,216.0,230.0]
   Ze=[34.3,28.4,25.3,24.0,24.1,25.7,29.3,35.9]
endif

;Get the ionogram data from tplot variable:
result=tnames('iug_ear_'+valuename[0]+'_snr*')
print,result
if strlen(tnames(result[0])) eq 0 then begin
   print, 'Cannot find the tplot vars in argument!'
   return
endif
a=fltarr(n_elements(result))

!P.Multi=[0,4,3,0,0]
;Set up the window size of 2-D plot:
window ,1, xsize=1280,ysize=800,TITLE='IUGONET EAR-FAI data:'

for k=0,2 do begin
   for j=0,3 do begin
      for i=0, n_elements(result)-1 do begin
        ;Get data from tplot variables:
         get_data,result[i],data=d
         dtime=abs(time_double(stime)-d.x)
         idx=where(dtime eq min(dtime),cnt)
         if i eq 0 then begin
            a=fltarr(n_elements(result),n_elements(d.v))
            b=fltarr(n_elements(result),n_elements(d.v))
            snr_new=fltarr(n_elements(result),n_elements(d.v))
         endif
  
         a[i,*]=-1.0*d.v/tan((90.0-Ze[i])*!pi/180.0)*sin(Az[i]*!pi/180.0)
         b[i,*]=-1.0*d.v/tan((90.0-Ze[i])*!pi/180.0)*cos(Az[i]*!pi/180.0)
         c = d.y[idx+j+4*k,*]            
         wbad = where(c le -6,nbad)
         if nbad gt 0 then c[wbad] = !values.f_nan
         snr_new[i,*] =c 
      endfor

      contour,snr_new, a, b,/fill,/ISOTROPIC,/CELL_FILL,NLevels=25, xrange=[-400,400],yrange=[0,300],zrange=[minimum,maximum],$
              title=time_string(d.x[idx+j+4*k])+' [UTC]',xtitle='Zonal distance from EAR [km]!CWestward positive',$
              ytitle='Meridional distance!Cfrom EAR [km]!CSouthward positive',$
              charsize=charsize, position = [0.075+k*0.33,(0.84-(j)*0.23),0.3+k*0.33,(0.96-(j)*0.23)]
   endfor
endfor

colorbar,min=minimum,max=maximum,format='(I4)',charsize=charsize,divisions=zticks,$
         position = [0.1, 0.04, 0.9, 0.05],title='SNR [dB]',/right,/bottom

end