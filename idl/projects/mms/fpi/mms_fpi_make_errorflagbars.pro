;+
; PROCEDURE:
;         mms_fpi_make_errorflagbars
;
; PURPOSE:
;         Make error flag bars
;         
;         For DES/DIS moments
;          tname+'_flagbars_full': Detailed flag bars (all bars)
;          tname+'_flagbars_main': Standard flag bars (4 bars)
;          tname+'_flagbars_mini': Smallest flag bar (1 bars)
;
;         For DES/DIS distribution function
;          tname+'_flagbars_dist': Standard flag bars (2 bars)
;
; INPUT:
;         tname:   tplot variable name of dis or des errorflag 
;
; KEYWORDS:
;         level:   level of the data to create the errorflags bar for
;                 (default is l2 - this only needs to be set for QL data)
; 
; EXAMPLES:
;     MMS>  mms_fpi_make_errorflagbars,'mms1_des_errorflags_fast'
;     MMS>  mms_fpi_make_errorflagbars,'mms1_dis_errorflags_fast'
;     MMS>  mms_fpi_make_errorflagbars,'mms1_des_errorflags_brst'
;     MMS>  mms_fpi_make_errorflagbars,'mms1_dis_errorflags_brst'
;
;   For DES/DIS distribution function (Brst and Fast):
;     bit 0 = manually flagged interval --> contact the FPI team for direction when utilizing this data; further correction is required
;     bit 1 = overcounting/saturation effects likely present in skymap
;      
;   For DES/DIS moments (Brst):
;     bit 0 = manually flagged interval  --> contact the FPI team for direction when utilizing this data; further correction is required
;     bit 1 = overcounting/saturation effects likely present in skymap
;     bit 2 = reported spacecraft potential above 20V
;     bit 3 = invalid/unavailable spacecraft potential
;     bit 4 = significant (>10%) cold plasma (<10eV) component
;     bit 5 = significant (>25%) hot plasma (>30keV) component
;     bit 6 = high sonic Mach number (v/vth > 2.5)
;     bit 7 = low calculated density (n_DES < 0.05 cm^-3)
;     bit 8 = onboard magnetic field used instead of brst l2pre magnetic field
;     bit 9 = srvy l2pre magnetic field used instead of brst l2pre magnetic field
;     bit 10 = no internally generated photoelectron correction applied
;     bit 11 = compression pipeline error
;     Bit 12 = spintone calculation error (DBCS only)
;     Bit 13 = significant (>=20%) penetrating radiation (DIS only)
;     Bit 14 = high MMS3 spintone due to DIS008 anomaly (DIS only)
;      
;   For DES/DIS moments (Fast):
;     bit 0 = manually flagged interval --> contact the FPI team for direction when utilizing this data; further correction is required
;     bit 1 = overcounting/saturation effects likely present in skymap
;     bit 2 = reported spacecraft potential above 20V
;     bit 3 = invalid/unavailable spacecraft potential
;     bit 4 = significant (>10%) cold plasma (<10eV) component
;     bit 5 = significant (>25%) hot plasma (>30keV) component
;     bit 6 = high sonic Mach number (v/vth > 2.5)
;     bit 7 = low calculated density (n_DES < 0.05 cm^-3)
;     bit 8 = onboard magnetic field used instead of srvy l2pre magnetic field
;     bit 9 = not used
;     bit 10 = no internally generated photoelectron correction applied
;     bit 11 = compression pipeline error
;     Bit 12 = spintone calculation error (DBCS only)
;     Bit 13 = significant (>=20%) penetrating radiation (DIS only)
;     Bit 14 = high MMS3 spintone due to DIS008 anomaly (DIS only)
;
;     Original by Naritoshi Kitamura
;     
;     June 2016: minor updates by egrimes
;     
; $LastChangedBy: jwl $
; $LastChangedDate: 2024-09-12 11:27:33 -0700 (Thu, 12 Sep 2024) $
; $LastChangedRevision: 32829 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_make_errorflagbars.pro $
;-

PRO mms_fpi_make_errorflagbars, tname, level = level
  if undefined(level) then level = 'l2'

  if strmatch(tname,'mms?_dis*') eq 1 then inst='DIS' else if strmatch(tname,'mms?_des*') eq 1 then inst='DES' else return
  if strmatch(tname,'*_fast*') eq 1 then rate='Fast' else if strmatch(tname,'*_brst*') eq 1 then rate='Brst' else return
  if rate eq 'Fast' then gap=5.d else if inst eq 'DIS' then gap=0.16d else gap=0.032d
  get_data,tname,data=d,dlimit=dl

  ; check for valid data before continuing on
  if ~is_struct(d) then return
  if ~is_struct(dl) then return
  
  if strmid(dl.cdf.gatt.data_type,3,4,/rev) eq 'moms' or level eq 'ql' then begin
    flags=string(d.y,format='(b015)')
    flagline=fltarr(n_elements(d.x),15)
    flagline_others=fltarr(n_elements(d.x))
    flagline_all=fltarr(n_elements(d.x))
    for j=0l,n_elements(flags)-1l do begin
      for i=0,14 do begin
        if fix(strmid(flags[j],14-i,1)) eq 0 then begin
          flagline[j,i]=!values.f_nan
          if flagline_all[j] ne 1.0 then flagline_all[j]=!values.f_nan else flagline_all[j]=1.0
          if inst eq 'DES' then begin
            if i ne 1 and i ne 4 and i ne 5 then if flagline_others[j] ne 1.0 then flagline_others[j]=!values.f_nan else flagline_others[j]=1.0
          endif else begin
            if i ne 1 and i ne 5 and i ne 13 then if flagline_others[j] ne 1.0 then flagline_others[j]=!values.f_nan else flagline_others[j]=1.0
          endelse
        endif else begin
          if inst eq 'DES' then begin
            if i ne 1 and i ne 4 and i ne 5 then flagline_others[j]=1.0
          endif else begin
            if i ne 1 and i ne 5 and i ne 13 then flagline_others[j]=1.0
          endelse
          flagline_all[j]=1.0
          flagline[j,i]=1.0
        endelse
      endfor
    endfor
    labels_full=['Contact FPI team','Saturation','SCpot>20V','no SCpot','>10% Cold','>25% Hot','High Mach#','Low Density','Onboard Mag','L2pre Mag','Photoelectrons','Compression', 'Spintones', 'Radiation','MMS3 Spintones']
    if inst eq 'DES' then begin
      store_data,tname+'_flagbars_full',data={x:d.x,y:[[flagline[*,0]],[flagline[*,1]-0.1],[flagline[*,2]-0.2],[flagline[*,3]-0.3],[flagline[*,4]-0.4],[flagline[*,5]-0.5],[flagline[*,6]-0.6],[flagline[*,7]-0.7],[flagline[*,8]-0.8],[flagline[*,9]-0.9],[flagline[*,10]-1.0],[flagline[*,11]-1.1],[flagline[*,12]-1.2]]}
      ylim,tname+'_flagbars_full',-0.15,1.25,0
      options,tname+'_flagbars_full',colors=[0,6,4,3,2,1,3,0,2,4,6,0,2],labels=labels_full[0:12],ytitle=inst+'!C'+rate,thick=3,panel_size=0.8,xstyle=4,ystyle=4,ticklen=0,labflag=-1,psym=-6,symsize=0.3,datagap=gap
      store_data,tname+'_flagbars_main',data={x:d.x,y:[[flagline[*,1]-0.2],[flagline[*,4]-0.4],[flagline[*,5]-0.6],[flagline_others-0.8]]}
      ylim,tname+'_flagbars_main',0.1,0.9,0
      options,tname+'_flagbars_main',colors=[6,2,1,0],labels=['Saturation','Cold (>10%)','Hot (>25%)','Others'],ytitle=inst+'!C'+rate,xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.5,labflag=-1,psym=-6,symsize=0.2,datagap=gap
      store_data,tname+'_flagbars_others',data={x:d.x,y:[[flagline[*,11]-0.8],[flagline[*,12]-0.8],[flagline[*,7]-0.8],[flagline[*,6]-0.8],[flagline[*,8]-0.8],[flagline[*,9]-0.8],[flagline[*,2]-0.8],[flagline[*,3]-0.8],[flagline[*,10]-0.8],[flagline[*,0]-0.8]]}
      options,tname+'_flagbars_others',colors=[254,160,40,3,255,5,2,1,4,6],xstyle=4,ystyle=4,ticklen=0,thick=3,labflag=-1,psym=-6,symsize=0.15,datagap=gap
      store_data,tname+'_flagbars',data=[tname+'_flagbars_main',tname+'_flagbars_others']
      ylim,tname+'_flagbars',0.1,0.9,0
      options,tname+'_flagbars',xstyle=4,ystyle=4,ticklen=0,panel_size=0.5,labsize=1
      store_data,tname+'_flagbars_mini',data={x:d.x,y:flagline_all}
      ylim,tname+'_flagbars_mini',0.9,1.1,0
      options,tname+'_flagbars_mini',colors=0,labels='Flagged',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.1,labflag=-1,psym=-6,symsize=0.2,datagap=gap,labsize=1
    endif else begin
      store_data,tname+'_flagbars_full',data={x:d.x,y:[[flagline[*,0]],[flagline[*,1]-0.1],[flagline[*,2]-0.2],[flagline[*,3]-0.3],[flagline[*,4]-0.4],[flagline[*,5]-0.5],[flagline[*,6]-0.6],[flagline[*,7]-0.7],$
        [flagline[*,8]-0.8],[flagline[*,9]-0.9],[flagline[*,10]-1.0],[flagline[*,11]-1.1],[flagline[*,12]-1.2],[flagline[*,13]-1.3],[flagline[*,14]-1.4]]}
      ylim,tname+'_flagbars_full',-0.16,1.35,0
      options,tname+'_flagbars_full',colors=[0,6,4,3,2,1,3,0,2,4,6,0,2,200,6],labels=labels_full,ytitle=inst+'!C'+rate,thick=3,panel_size=0.8,xstyle=4,ystyle=4,ticklen=0,labflag=-1,psym=-6,symsize=0.3,datagap=gap
      store_data,tname+'_flagbars_main',data={x:d.x,y:[[flagline[*,1]-0.2],[flagline[*,13]-0.4],[flagline[*,5]-0.6],[flagline_others-0.8]]}
      ylim,tname+'_flagbars_main',0.1,0.9,0
      options,tname+'_flagbars_main',colors=[6,200,1,0],labels=['Saturation','Radiation','Hot (>25%)','Others'],ytitle=inst+'!C'+rate,xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.5,labflag=-1,psym=-6,symsize=0.2,datagap=gap
      store_data,tname+'_flagbars_others',data={x:d.x,y:[[flagline[*,11]-0.8],[flagline[*,12]-0.8],[flagline[*,7]-0.8],[flagline[*,6]-0.8],[flagline[*,8]-0.8],[flagline[*,9]-0.8],[flagline[*,2]-0.8],[flagline[*,3]-0.8],[flagline[*,10]-0.8],[flagline[*,0]-0.8]]}
      options,tname+'_flagbars_others',colors=[254,160,40,3,255,5,2,1,4,6],xstyle=4,ystyle=4,ticklen=0,thick=3,labflag=-1,psym=-6,symsize=0.15,datagap=gap
      store_data,tname+'_flagbars',data=[tname+'_flagbars_main',tname+'_flagbars_others']
      ylim,tname+'_flagbars',0.1,0.9,0
      options,tname+'_flagbars',xstyle=4,ystyle=4,ticklen=0,panel_size=0.5,labsize=1
      store_data,tname+'_flagbars_mini',data={x:d.x,y:flagline_all}
      ylim,tname+'_flagbars_mini',0.9,1.1,0
      options,tname+'_flagbars_mini',colors=0,labels='Flagged',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.1,labflag=-1,psym=-6,symsize=0.2,datagap=gap,labsize=1
    endelse

    ; kludge for the titles to show up on the y axes
    options, tname+'_flagbars_full', axis={yaxis: 0, ytitle: inst+'!C'+rate, yticks: 1, yminor: 1, ystyle: 0, yticklayout: 1, ytickv: [-1, 2]}
    options, tname+'_flagbars', axis={yaxis: 0, ytitle: inst+'!C'+rate, yticks: 1, yminor: 1, ystyle: 0, yticklayout: 1, ytickv: [-1, 2]}
    options, tname+'_flagbars_mini', axis={yaxis: 0, ytitle: inst, yticks: 1, yminor: 1, ystyle: 0, yticklayout: 1, ytickv: [-1, 2]}
  endif else begin
    if strmid(dl.cdf.gatt.data_type,3,4,/rev) eq 'dist' then begin
      flags=string(d.y,format='(b014)')
      flagline=fltarr(n_elements(d.x),2)
      for i=0,1 do begin
        for j=0l,n_elements(flags)-1l do begin
          if fix(strmid(flags[j],13-i,1)) eq 0 then flagline[j,i]=!values.f_nan else flagline[j,i]=1.0
        endfor
      endfor
      store_data,tname+'_flagbars_dist',data={x:d.x,y:[[flagline[*,0]-0.25],[flagline[*,1]-0.75]]}
      ylim,tname+'_flagbars_dist',0.0,1.0,0
      options,tname+'_flagbars_dist',colors=[0,6],labels=['Manually flagged','Saturation'],xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.25,labflag=-1,psym=-6,symsize=0.2,datagap=gap
    endif else begin
      return  
    endelse
  endelse
  

END