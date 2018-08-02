;+
;NAME:
;iug_gmag_wdc_xyz
;
;PURPOSE:
;  Transformation of geomagnetic field into XYZ (geographical) coordinates.
;  X:North, Y:East, Z:Vertical (downward is positive)
;
;SYNTAX:
;  iug_gmag_wdc_xyz [ ,SITE = string ]
;  
;KEYWORDS:
;  site  = Station ABB code or name of geomagnetic index.
;          Ex1) iug_gmag_wdc_xyz, site = 'kak', ...
;          Ex2) iug_gmag_wdc_xyz, site = ['gua', 'kak'], ...
;  reolution = Time resolution of the data: 'min' or 'hour'.
;  
;EXAMPLE:
;   iug_gmag_wdc_xyz, site = 'kak',resolution='min'
;
;CODE:
;A. Shinbori, 28/11/2012.
;A. Shinbori, 30/11/2017.
;
;MODIFICATIONS:
;
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_gmag_wdc_xyz,site=site,resolution=resolution

;****************
;site code check:
;****************
if (not keyword_set(site)) then site='*'

;****************
;resolution check:
;****************
if (not keyword_set(resolution)) then resolution='min'

;tplot colors
colors=[3,5,6]

;Search the tplot variables:
result=''
if site[0] ne '*' then begin
   for i=0, n_elements(site)-1 do begin
      res=tnames('wdc_mag_'+site[i]+'_1'+resolution)
      if res ne '' then append_array,result,res 
   endfor
endif else begin
      result = tnames('wdc_mag_*_1'+resolution)
endelse

if result[0] ne '' then begin
   for j=0, n_elements(result)-1 do begin
     ;Get the data from the tplot varables:
      get_data,result[j], data=d,LIMITS=str
      if size(d.x,/N_ELEMENTS) ne 0 then y=fltarr(n_elements(d.x),3)
     ;Obtain the geomagnetic field data of each component corresponding to the labels: 
      for i=0,n_elements(str.LABELS)-1 do begin
         if str.LABELS[i] eq 'D [deg]' then d_comp=d.y[*,i]
         if str.LABELS[i] eq 'H [nT]' then h_comp=d.y[*,i]
         if str.LABELS[i] eq 'X [nT]' then x_comp=d.y[*,i]
         if str.LABELS[i] eq 'Y [nT]' then y_comp=d.y[*,i]
         if str.LABELS[i] eq 'Z [nT]' then z_comp=d.y[*,i]
         if str.LABELS[i] eq 'F [nT]' then f_comp=d.y[*,i]
      endfor

     ;Reform the data array of geomagnetic field corresponding to the data labels (HDZF coordinates) 
     ;and replace the HDZF components by the XYZF ones.
      if size(h_comp,/N_ELEMENTS) ne 0 and size(d_comp,/N_ELEMENTS) ne 0 and size(z_comp,/N_ELEMENTS) ne 0 then begin
         y[*,0]=h_comp*cos(d_comp*!pi/180.0)
         y[*,1]=h_comp*sin(d_comp*!pi/180.0)
         if size(z_comp,/N_ELEMENTS) eq 0 then z_comp = h_comp + !values.f_nan
         y[*,2]=z_comp
        ;Store the tplot variables:
         store_data,result[j]+'_xyz',data ={x:d.x,y:y}
         options,result[j]+'_xyz',ytitle = str.ytitle,labels = ['X [nT]', 'Y [nT]','Z [nT]'], colors = colors
         print, 'Created '+ result[j]+'_xyz'
      endif

     ;Reform the data array of geomagnetic field corresponding to the data labels (XYZF coordinates)
      if size(h_comp,/N_ELEMENTS) eq 0 and size(d_comp,/N_ELEMENTS) eq 0 and size(x_comp,/N_ELEMENTS) ne 0 and size(y_comp,/N_ELEMENTS) ne 0 and size(z_comp,/N_ELEMENTS) ne 0 then begin
         y[*,0]=x_comp
         y[*,1]=y_comp
         y[*,2]=z_comp
        ;d.y[*,3]=f_comp
        ;Store the tplot variables:
         store_data,result[j]+'_xyz',data ={x:d.x,y:y}
         options,result[j]+'_xyz',ytitle = str.ytitle,labels = ['X [nT]', 'Y [nT]','Z [nT]'], colors = colors
         print, 'Created '+ result[j]+'_xyz'
      endif
   endfor
endif
end