;+
; PROCEDURE:
;         mms_fpi_make_compressionlossbars
;
; PURPOSE:
;         Make compressionloss flag bars
;         
; KEYWORDS:
;         tname:   tplot variable name of dis or des compressionloss
;         lossy:   the value for lossy compression (use this keyword only for special case)
;
; EXAMPLES:
;     MMS>  mms_fpi_make_compressionlossbars,'mms1_des_compressionloss_brst'
;     MMS>  mms_fpi_make_compressionlossbars,'mms1_dis_compressionloss_brst'
;
; FLAG:
;     0: Lossless compression
;     1: Lossy compression
;   In old files (v2.1.0 or older until the end of Phase 1A)
;     1: Lossless compression
;     3: Lossy compression
;
; In cases when data had been lossy compressed, some artifacts may appear in the data due to the compression.
; Since all of fast survey data are lossy compressed, it is not nesessary to make this bar for fast survey data.
;      
;     Original by Naritoshi Kitamura
;     
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-08-30 07:29:09 -0700 (Tue, 30 Aug 2016) $
;$LastChangedRevision: 21768 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_make_compressionlossbars.pro $
;-

PRO mms_fpi_make_compressionlossbars,tname,lossy=lossy

  if strmatch(tname,'mms?_dis*') eq 1 then inst='DIS' else if strmatch(tname,'mms?_des*') eq 1 then inst='DES' else return
  if inst eq 'DES' then col=6 else col=2
  if strmatch(tname,'*_fast*') eq 1 then rate='Fast' else if strmatch(tname,'*_brst*') eq 1 then rate='Brst' else return
  if rate eq 'Fast' then gap=4.6d else if inst eq 'DIS' then gap=0.16d else gap=0.032d
  get_data,tname,data=d,dlimit=dl
  
  ; check for valid data before continuing on
  if ~is_struct(dl) then return
  if ~is_struct(d) then return else flags=d.y
  flagline=fltarr(n_elements(d.x))
  
  if rate eq 'Brst' then begin
    if undefined(lossy) then begin
      fpi_ver=stregex(dl.cdf.gatt.logical_file_id,'v([0-9]+)\.([0-9]+)\.([0-9])',/subexpr,/extract)
      if fix(fpi_ver[1]) eq 2 then begin
        if fix(fpi_ver[2]) eq 1 then begin
          if d.x[0] lt time_double('2016-04-01') then lossy=3 else lossy=1
        endif else begin
          if fix(fpi_ver[2]) gt 1 then lossy=1 else lossy=3
        endelse
      endif else begin
        if fix(fpi_ver[1]) gt 2 then lossy=1 else lossy=3
      endelse
    endif
    for j=0l,n_elements(d.x)-1l do if d.y[j] ne lossy then flagline[j]=!values.f_nan else flagline[j]=0.5
    store_data,tname+'_flagbars',data={x:d.x,y:flagline}
    ylim,tname+'_flagbars',0.0,1.0,0
    options,tname+'_flagbars',colors=col,labels=inst+' '+rate+'!C  Lossy',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.2,labflag=-1,psym=-6,symsize=0.2,datagap=gap
  endif else begin
    for j=0l,n_elements(d.x)-1l do if flags eq 0 then flagline[j]=!values.f_nan else flagline[j]=0.5
    store_data,tname+'_flagbars',data={x:d.x,y:flagline}
    ylim,tname+'_flagbars',0.0,1.0,0
    options,tname+'_flagbars',colors=col,labels=inst+' '+rate+'!C  Lossy',xstyle=4,ystyle=4,ticklen=0,thick=4,panel_size=0.2,labflag=-1,psym=-6,symsize=0.2,datagap=gap
  endelse

END