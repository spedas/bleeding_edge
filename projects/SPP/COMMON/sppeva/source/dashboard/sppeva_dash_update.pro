PRO sppeva_dash_update, activate
  compile_opt idl2
  common com_dash, com_dash

  widget_control, com_dash.drDash, GET_VALUE=mywindow
  ;======================================================
  
  ;--------------
  ; Current Time
  ;--------------
  cst = time_string(systime(/seconds,/utc));................. current time
  css = ' current time: '+strmid(cst, 5,2)+'/'+strmid(cst, 8,2)+' '+strmid(cst, 11,5) + ' UTC'
  com_dash.oTime ->SetProperty,STRING=css

  ;--------------
  ; FOMstr
  ;--------------
  strHH = '0'
  strMM = '0'
  strBL = '0'
  strGb = '0'
  var = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr')
  tn=tnames(var, n)
  if n gt 0 then begin
    get_data,var,data=D,dl=dl,lim=lim
    if n_tags(dl) gt 0 then begin
      s=dl.FOMstr
      if s.Nsegs eq 0 then begin
        strHH = '0'
        strMM = '0'
        strBL = '0'
      endif else begin
        ; HH and MM
        dt = total(s.STOP - s.START)/60.d0; seconds --> minutes
        hh = floor(dt/60.d0)
        mm = floor(dt - hh*60.d0)
        strHH = strtrim(string(hh),2)
        strMM = strtrim(string(mm),2)
        ; BL
        BL = 0
        if strmatch(!SPPEVA.COM.MODE,'FLD') then begin
          tnptr = !SPPEVA.COM.FIELDPTR
        endif else begin
          tnptr = !SPPEVA.COM.SWEAPPTR
        endelse
        tn=tnames(tnptr,ct)
        if ct eq 1 then begin
          get_data,tnptr,data=DD
          mmax = max(DD.y,/nan)
          lst = lonarr(mmax)
          for n=0,s.Nsegs-1 do begin
            PTR = sppeva_sitl_get_block(s.START[n], s.STOP[n])
            if PTR.ERROR eq 0 then begin
              lst[PTR.start:PTR.stop] = 1L
            endif
          endfor
          BL = total(lst)
        endif
        strBL = strtrim(string(floor(BL)),2)
        strGb = string(BL/512.2,format='(F6.3)')
      endelse
    endif
  endif
  
  ;-------------------
  ; Background Color
  ;-------------------
  if strmatch(!SPPEVA.COM.MODE,'FLD') then begin
    com_dash.myview ->SetProperty,COLOR=com_dash.color.lightblue
    com_dash.oMode -> SetProperty,STRING=' FIELDS'
  endif else begin
    com_dash.myview ->SetProperty,COLOR=com_dash.color.lightred
    com_dash.oMode -> SetProperty,STRING=' SWEAP'
  endelse
  com_dash.oHH -> SetProperty,STRING=' '+strHH+' hrs'
  com_dash.oMM -> SetProperty,STRING=' '+strMM+' min'
  com_dash.oBL -> SetProperty,STRING=' '+strBL+' blocks'
  com_dash.oGb -> SetProperty,STRING=' '+strGb+' Gbit'
  
  ;======================================================
  mywindow->Draw, com_dash.myview
END
