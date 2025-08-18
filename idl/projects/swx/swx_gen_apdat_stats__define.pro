 
 
pro swx_gen_apdat_stats::handler,ccsds, source_dict=source_dict ;,ptp_header

;print_struct,ccsds
self.increment_counters, ccsds
strct =ccsds  ;{time: ccsds.time,  apid: ccsds.apid ,pkt_size: ccsds.pkt_size,  gap:ccsds.gap }
strct.pdata = ptr_new()
self.data.append, strct
if self.rt_flag then begin
  store_data,'APIDS_ALL',ccsds.time,ccsds.apid, /append,dlimit={psym:3,symsize:.2 ,ynozero:1}
  if ccsds.gap ne 0 then  store_data,'APIDS_GAP',ccsds.time,ccsds.apid,  /append,  dlimit={psym:4,symsize:.4 ,ynozero:1, colors:'r'}  
endif
end
 
 
 
pro swx_gen_apdat_stats::finish,append=append,tres=tres
   dprint,dlevel=3,'Executing finish for stats'
   store_data,'APID',data='APIDS_ALL APIDS_GAP',  dlimit={ynozero:1}
   d = self.data.array
   if n_elements(d) le 1 then return
   if not keyword_set(tres) then tres=120d
   if size(/type,d) eq 8 then begin
     store_data,'APIDS_ALL', d.time, d.apid, append=append ,dlimit={psym:3,symsize:.2 ,ynozero:1}
     w = where(d.gap ne 0)
     store_data,'APIDS_GAP', d[w].time, d[w].apid, append=append , dlimit={psym:4,symsize:.4 ,ynozero:1, colors:'r'}
     if 1 then begin
       s = sort(d.apid)
       apids = d[s[uniq(d[s].apid)]].apid
       nbytes = average_hist(/ret_total,d.pkt_size,d.time,binval=ibins,xbins=tbins,binsize=double(tres),/shift)
       wnz = where((nbytes + shift(nbytes,1) + shift(nbytes,-1)) ne 0,nwnz)
       if nwnz gt 0 then    store_data,'spp_swp_data_rate_TOT',tbins[wnz],float(nbytes[wnz])/tres
       if debug(3,msg='debug') then    printdat,d,d.pkt_size,d.time,ibins,nbytes,tbins,wnz
       ibins_c = replicate(-1L,n_elements(nbytes))
       ibins_c[wnz] = lindgen(nwnz)
       
       i_2d = ibins_c[ibins] + d.apid * nwnz
       nbytes2 = average_hist(/ret_total,d.pkt_size,i_2d,range=[0,2048*nwnz],xbins=xbins,binsize=1L,/shift)
       if debug(3) then printdat,minmax(i_2d),xbins
       nbytes2 = reform(nbytes2,nwnz,2048)
       if debug(3) then printdat, i_2d,nbytes2
       store_data,'swx_stis_data_rate_PKT',data={x:tbins[wnz],Y:nbytes2/float(tres),v:indgen(2048)}
 ;      store_data,'APIDS_RATE',data={x:tbins[wnz],Y:nbytes2/float(tres),v:indgen(2048)},dlimit={spec:1}
 ;      stop
       
     endif else begin
       s = sort(d.apid)
       apids = d[s[uniq(d[s].apid)]].apid
       for i = 0,n_elements(apids)-1 do begin
           w = where(d.apid eq apids[i],na)
           if na gt 0 then begin
             api = spp_apdat(apids[i])
             da = api.data.array
             nsamps = 14
             num_bytes = total(/cumulative,/integer,da.pkt_size)
             rate_bytes = (num_bytes-shift(num_bytes,nsamps)) / (da.time-shift(da.time,nsamps))
             store_data,'swx_rate_APID_'+string(api.apid,format='(Z3)'),data={x:da.time,y:rate_bytes}
             ;    print,i,apids[i],na,ap.npkts, na - ap.npkts
           endif else dprint,'error'
       endfor

     endelse
   endif
end
 

 
 
PRO swx_gen_apdat_stats__define
void = {swx_gen_apdat_stats, $
  inherits swx_gen_apdat, $    ; superclass
  last_rt: 0d, $
  tres_rt: 300d, $
  sample1: obj_new() , $
  sample2: obj_new()  $
  }
END



