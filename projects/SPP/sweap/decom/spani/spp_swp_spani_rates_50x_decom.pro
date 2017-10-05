function spp_swp_spanai_rates_50x_decom,ccsds, ptp_header=ptp_header, apdat=apdat

  b = ccsds.data
  psize = 84
  if n_elements(b) ne psize then begin
     dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
     return,0
  endif
  
  sf0 = ccsds.data[11] and 3
  ;print,sf0
  ;hexprint,ccsds.data[0:29]
  rates = float( reform( spp_sweap_log_decomp( ccsds.data[20:83] , 0 ) ,4,16))
  ;rates = float( reform( float( ccsds.data[20:83] ) ,4,16))
  time = ccsds.time


  ;; Cluge to correct times
  if 0 then begin               
     if keyword_set(apdat) && size(/type,*apdat.last_ccsds) eq 8 then begin
        ltime =  (*apdat.last_ccsds).time
        dt = time - ltime
        if dt le 0 then begin
           time += .86/4 - dt
           ccsds.time = time
        endif else rates=rates/2
     endif
  endif else if 1 then begin
     if sf0 eq 1 then  rates=rates/2
  endif
  
  rates_str = { $
              time: time, $
              met: ccsds.met,  $
              seq_cntr: ccsds.seq_cntr, $
              valid_cnts: reform( rates[0,*]) , $
              multi_cnts: reform( rates[1,*]), $
              start_cnts: reform( rates[2,*] ), $
              stop_cnts:  reform( rates[3,*]) }

  return,rates_str

end


