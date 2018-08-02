;+
;
;NAME:
;  iug_plot2d_mu_fai
;
;PURPOSE:
;  Generate several 2-D plots from the FAI f-region observation data taken by the MU radar. 
;
;SYNTAX:
;  iug_plot2d_mu_fai, valuename=valuename
;
;KEYWOARDS:
;  VALUENAME = tplot variable names of ionosonde observation data.  
;         For example, iug_plot2d_mu_fai,valuename = 'ifco16'.
;         The default is 'ifco16'.
;  STIME = Start time of 2-D plot of the EAR-FAI observations.
;         For example, iug_plot2d_mu_fai, stime = '2007-01-09/15:00:00'.
;         The default is '2007-01-09/15:00:00'.
;  MINIMUM = Minimum value of color plot. For example, iug_plot2d_mu_fai, min = 0.
;         The default is 0.
;  MAXIMUM = Maximum value of color plot. For example, iug_plot2d_mu_fai, max = 50.
;         The default is 50.
;  ZTICKS = Number of zticks to divide the bar into. There will be (zticks + 1) annotations. 
;         The default is 5.
;  CHARSIZE = Select of character size. For example, iug_plot2d_ear_fai, charsize = 1.5.
;         The default is 1.5.
;         
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

pro iug_plot2d_mu_fai, valuename = valuename, $
   stime=stime, $
   minimum=minimum, $
   maximum=maximum, $
   zticks=zticks, $
   charsize=charsize

;*****************
;Value name check:
;*****************
if not keyword_set(valuename) then valuename='ifco16'

;*****************
;Start time check:
;*****************
if not keyword_set(stime) then valuename='2007-01-09/15:00:00'

;*******************
;Min and max check:
;*******************
if not keyword_set(minimum) then minimum=0
if not keyword_set(maximum) then maximum=50

;*******************
;Zticks check:
;*******************
if not keyword_set(zticks) then zticks=5

;*******************
;Charsize check:
;*******************
if not keyword_set(charsize) then charsize=1.5

;Call the color table:
loadct,39

;Definition of azimuth and zenith angles for each observation mode:
if (valuename eq 'ieto16') then begin
   Az=[295.0,295.0,300.0,305.0,310.0,315.0,325.0,335.0,350.0,5.0,15.0,25.0,40.0,50.0,60.0,65.0]
   Ze=[24.0,22.0,20.0,18.0,16.0,14.0,12.0,11.0,10.0,10.0,10.0,10.0,11.0,12.0,14.0,16.0]
endif
if (valuename eq 'ifco16') or (valuename eq 'ifmf16') or (valuename eq 'ifim16') or (valuename eq 'ifmd16') then begin
   Az=[320.0,325.0,330.0,335.0,340.0,345.0,350.0,355.0,0.0,5.0,10.0,15.0,20.0,25.0,30.0,0.0]
   Ze=[40.0,40.0,38.0,38.0,36.0,36.0,36.0,36.0,36.0,36.0,36.0,36.0,38.0,38.0,40.0,38.0]
endif
if (valuename eq 'ifmb16') then begin
   Az=[265.0,265.0,265.0,270.0,275.0,280.0,285.0,310.0,0.0,45.0,70.0,75.0,80.0,85.0,90.0,0.0]
   Ze=[24.0,20.0,16.0,12.0,8.0,6.0,4.0,2.0,1.0,2.0,4.0,6.0,8.0,12.0,18.0,3.0]
endif
if (valuename eq 'ifmc16') then begin
   Az=[320.0,325.0,330.0,335.0,340.0,345.0,350.0,355.0,0.0,5.0,10.0,15.0,20.0,25.0,30.0,0.0]
   Ze=[40.0,40.0,38.0,38.0,36.0,36.0,36.0,36.0,36.0,36.0,36.0,36.0,38.0,38.0,40.0,38.0]
endif

;Get the ionogram data from tplot variable:
result=tnames('iug_mu_fai_'+valuename+'_snr*')
print,result
if strlen(tnames(result[0])) eq 0 then begin
   print, 'Cannot find the tplot vars in argument!'
   return
endif
a=fltarr(n_elements(result))

!P.Multi=[0,4,3,0,0]
;Set up the window size of 2-D plot:
window ,1, xsize=1280,ysize=800,TITLE='IUGONET MUR-FAI data:'

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
  
         a[i,*]=1.0*d.v/tan((90.0-Ze[i])*!pi/180.0)*sin(Az[i]*!pi/180.0)
         b[i,*]=1.0*d.v/tan((90.0-Ze[i])*!pi/180.0)*cos(Az[i]*!pi/180.0)
         c = d.y[idx+j+4*k,*]            
         wbad = where(c le -6,nbad)
         if nbad gt 0 then c[wbad] = !values.f_nan
         snr_new[i,*] =c[0,*]
      endfor
      if (valuename eq 'ieto16') then begin
         contour,snr_new, a, b,/fill,/ISOTROPIC,/CELL_FILL,NLevels=25, xrange=[-100,100],yrange=[0,50],zrange=[minimum,maximum],$
              title=time_string(d.x[idx+j+4*k])+' [UTC]',xtitle='Zonal distance from MUR [km]!CEastward positive',$
              ytitle='Meridional distance!Cfrom MUR [km]!CNorthward positive',$
              charsize=charsize, position = [0.075+k*0.33,(0.84-(j)*0.23),0.3+k*0.33,(0.96-(j)*0.23)]
      endif else begin
         contour,snr_new, a, b,/fill,/ISOTROPIC,/CELL_FILL,NLevels=25, xrange=[-300,300],yrange=[50,350],zrange=[minimum,maximum],$
              title=time_string(d.x[idx+j+4*k])+' [UTC]',xtitle='Zonal distance from MUR [km]!CEastward positive',$
              ytitle='Meridional distance!Cfrom MUR [km]!CNorthward positive',$
              charsize=charsize, position = [0.075+k*0.33,(0.84-(j)*0.23),0.3+k*0.33,(0.96-(j)*0.23)]      
      endelse
   endfor
endfor

colorbar,min=minimum,max=maximum,format='(I4)',charsize=charsize,divisions=zticks,$
         position = [0.1, 0.04, 0.9, 0.05],title='SNR [dB]',/right,/bottom

end