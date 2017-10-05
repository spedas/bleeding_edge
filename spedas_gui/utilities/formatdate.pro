function formatReplace,target,in,start,length

  compile_opt idl2,hidden
  
  slen = strlen(target)
  
  if start gt 0 then begin
    front = strmid(target,0,start)
  endif else begin
    front = ''
  endelse
  
  if start + length lt slen then begin
    back = strmid(target,start+length,slen-(start+length))
  endif else begin
    back = ''
  endelse
  
  return,front+in+back
  
end

function formatDate,value,formatString,scaling

  compile_opt idl2

  if scaling eq 1 then begin
    val = 10^(value)
  endif else if scaling eq 2 then begin
    val = exp(value)
  endif else begin
    val = value
  endelse

  ts = time_struct(val)

  ;account for time_struct allowing fractional sec = 1
  ;this should take care of incrimenting other fields 
  ;(sec, min, hour, day, etc)
  if ts.fsec ge 1d then begin
    td = time_double(ts)
    ts = time_struct(td)
  endif

  fs = formatString

  while 1 do begin
  
    if (val = stregex(fs,'%time',/fold_case,length=l)) ne -1 then begin
  
      in = string(ts.hour,format='(I2.2)') + ':' + $
           string(ts.min,format='(I2.2)') + ':' + $
           string(ts.sec,format='(I2.2)')
  
      fs = formatReplace(fs,in,val,l)
  
    endif else if (val = stregex(fs,'%exacttime',/fold_case,length=l)) ne -1 then begin
  
      in = string(ts.hour,format='(I2.2)') + ':' + $
           string(ts.min,format='(I2.2)') + ':' + $
           string(ts.sec,format='(I2.2)') + '.' + $
           string(ts.fsec*1000, format='(I3.3)')
  
      fs = formatReplace(fs,in,val,l)
  
    endif else if (val = stregex(fs,'%date',/fold_case,length=l)) ne -1 then begin
  
      in = string(ts.year,format='(I4.4)') + '-' + $
           string(ts.month,format='(I2.2)') + '-' + $
           string(ts.date,format='(I2.2)')
           
      fs = formatReplace(fs,in,val,l)
  
    endif else if (val = stregex(fs,'%year',/fold_case,length=l)) ne -1 then begin
    
      in = string(ts.year,format='(I4.4)')
      
      fs = formatReplace(fs,in,val,l)
      
    endif else if (val = stregex(fs,'%mon',/fold_case,length=l)) ne -1 then begin
    
      in = string(ts.month,format='(I2.2)')
      
      fs = formatReplace(fs,in,val,l)
      
    endif else if (val = stregex(fs,'%day',/fold_case,length=l)) ne -1 then begin
    
      in = string(ts.date,format='(I2.2)')
      
      fs = formatReplace(fs,in,val,l)
      
    endif else if (val = stregex(fs,'%hours',/fold_case,length=l)) ne -1 then begin
    
      in = string(ts.hour,format='(I2.2)')
      
      fs = formatReplace(fs,in,val,l)
      
    endif else if (val = stregex(fs,'%minutes',/fold_case,length=l)) ne -1 then begin
    
      in = string(ts.min,format='(I2.2)')
      
      fs = formatReplace(fs,in,val,l)
   
    endif else if (val = stregex(fs,'%seconds',/fold_case,length=l)) ne -1 then begin
    
      in = string(ts.sec,format='(I2.2)')
      
      fs = formatReplace(fs,in,val,l)
  
    endif else if (val = stregex(fs,'%doy',/fold_case,length=l)) ne -1 then begin
    
      in = string(ts.doy,format='(I3.3)')
      
      fs = formatReplace(fs,in,val,l)
      
   endif else begin
     break
   endelse ;consider support for DOW,SOD,FSEC
  
  endwhile

  return,fs

end
