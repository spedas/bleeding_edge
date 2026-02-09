pro swfo_mag_decom,magda,maghr_da = maghr_da,mag1s_da = mag1s_da,clear=clear


  mag = magda.array

  if ~isa(mag) then begin
    dprint,'No data'
    return
  endif

  case mag[0].apid of
    1253:  ns = 8
    1254:  ns = 64
    else:  ns = 0
  endcase

  if ~keyword_set(ns) then begin
    dprint,'Invalid MAG apid'
    return
  endif

  compressed_packet_size = (ns+1)*6 + 2 + 20

  result_format = {time:0d  $
    ,  B0:fltarr(3)  $
    ,  B1: fltarr(3) $
    ,  packet_size:0 $
    ,  rate: ns $
    ,  replay: 0 $
    ,  station: 0 $
    ,  gap:0 }

  nd = n_elements(mag)

  mag_hr = replicate(result_format, ns, nd)
  mag_hr.packet_size = replicate(1,ns) # mag.packet_size
  mag_hr.replay = replicate(1,ns) # mag.replay
  mag_hr.station = replicate(1,ns) # mag.station


  dtime =  dindgen(ns) / ns
  mag_hr.time =  replicate(1,ns) # mag.time  + dtime # replicate(1,nd)



  raw = mag.raw_data


  for i=0,5 do  begin    ;assume all packets are fully compressed (faster)
    j = i*(ns+1)
    mag_data = reform( ishft( fix( raw[j,*] * 256 + raw[j+1,*] ), 1) / 2 ) ; convert first value to signed int
    mag.mag_data[i] = mag_data   ; delete this?
    raw_ns = raw[j+1+indgen(ns),*]
    raw_ns[0,*] = 0
    raw_int = ishft( fix( raw_ns ), 8 ) / 256   ; convert to signed value
    raw_int[0,*] = mag_data
    raw_int = total(/cumulative,/preserve,raw_int,1)   ; Sum then increments to get full value
    if (i / 3) then begin
      mag_hr.b1[i mod 3] = raw_int
    endif else begin
      mag_hr.b0[i mod 3] = raw_int
    endelse

    dprint,dlevel=3,i
  endfor
  magda.array = mag             ; delete this?

  wnotcomp = where( mag.packet_size ne compressed_packet_size, /null)   ; at least one the 6 components is not compressed
  if isa(wnotcomp) then begin
    dprint,dlevel=2,'Correcting non compressed mag data: ',n_elements(wnotcomp)
    foreach w,wnotcomp do begin
      m = mag[w]
      ndat = m.packet_size - 20
      raw= m.raw_data[0:ndat-1]
      j =0
      vals = intarr(ns,6)
      for i= 0,5 do begin
        if (raw[j] and 0x80) ne 0 then begin  ; compressed
          mag_data = reform( ishft( fix( raw[j] * 256 + raw[j+1] ), 1) / 2 ) ; convert first value to signed int
          raw_ns = raw[j+1:j+ns]
          raw_ns[0] = 0
          raw_int = ishft( fix(raw_ns), 8 ) / 256
          raw_int[0] = mag_data
          raw_int = total(/preserve,/cumulative,raw_int)
          j = j+ns+1
        endif else begin   ; not compressed
          raw_ns = reform ( raw[ j : j+ns*2-1] ,2,ns )
          raw_int =  ishft( fix( raw_ns[0,*] * 256 + raw_ns[1,* ] ), 1) / 2  ; convert values to signed int
          j=j+ns*2
        endelse
        vals[*,i] = raw_int
      endfor
      mag_hr[*,w].b0[0] = vals[*,0]
      mag_hr[*,w].b0[1] = vals[*,1]
      mag_hr[*,w].b0[2] = vals[*,2]
      mag_hr[*,w].b1[0] = vals[*,3]
      mag_hr[*,w].b1[1] = vals[*,4]
      mag_hr[*,w].b1[2] = vals[*,5]
    endforeach

  endif




  if arg_present(mag1s_da) then begin
    if ~isa(mag1s_da,'dynamicarray') then begin
      mag1s_da = dynamicarray(name='mag1s')
    endif
    mag1s =  reform(mag_hr[0,*])
    mag1s.b0 = average(mag_hr.b0, 2)
    mag1s.b1 = average(mag_hr.b1, 2)
    mag1s.time = average(mag_hr.time, 1)
    mag1s_da.append,mag1s
  endif

  mag_hr = reform(mag_hr,ns*nd,/over)

  if arg_present(maghr_da) then begin
    if ~isa(maghr_da,'dynamicarray') then begin
      maghr_da = dynamicarray(name='maghr')
    endif
    if keyword_set(clear) then maghr_da.size =0
    maghr_da.append,mag_hr
  endif


  dprint,dlevel=3,'done'

end
