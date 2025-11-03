; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-10-27 11:02:52 -0700 (Mon, 27 Oct 2025) $
; $LastChangedRevision: 33797 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_nse_apdat__define.pro $


function swfo_stis_nse_apdat::decom,ccsds,source_dict=source_dict      ;,header,ptp_header=ptp_header,apdat=apdat
  ;common swfo_stis_nse_com4, lastdat, last_str
  ccsds_data = swfo_ccsds_data(ccsds)

  if debug(5) then begin
    dprint,dlevel=4,'SST',ccsds.pkt_size, n_elements(ccsds_data), ccsds.apid
    hexprint,ccsds_data[0:31]
    hexprint,swfo_data_select(ccsds_data,80,8)
  endif

  flt=1.
  hs= 24

  nseraw = swap_endian( uint(ccsds_data,hs,60) ,/swap_if_little_endian)

  ; if ptr_valid(self.last_data_p) && keyword_set(*self.last_data_p) then nse_diff2 = nseraw - *self.last_data_p else nse_diff2 = 0*nseraw

  ;help,self.last_data
  
  last_str = *self.last_data_p        ; last structure

;  if n_elements(last_str) eq 0 || (abs(last_str.time-ccsds.time) gt 300) then lastdat = nseraw
;  if n_elements(last_str) eq 0 || (abs(last_str.time-ccsds.time) gt 300) then lastdat = nseraw
  if ~isa(last_str) || (abs( last_str.time - ccsds.time) gt 300) then lastraw = nseraw else lastraw = last_str.raw
  nse_diff = nseraw - lastraw    ; subtracting two uints will produce a uint which is the correct method to use

  ;dprint,reform(nse_diff,10,6)

  str1=swfo_stis_ccsds_header_decom(ccsds)

  str2 = {$
    raw: nseraw, $
    histogram:float(nse_diff),$    ; The UINT gets cast into a float here. This allows the value to be made into a NAN  (for example the very first instance)
 ;   total: fltarr(6), $
 ;   sigma: fltarr(6), $
 ;   baseline: fltarr(6), $
    gap:ccsds.gap}

  str=create_struct(str1,str2)

  ; str2 = {$
  ;   histogram:float(nse_diff),$
  ;   total:total(nse_diff),$
  ;   total6:total(reform(nse_diff,[10,6]),1),$
  ;   gap:ccsds.gap}

  ; str3=create_struct(str1,str2)
  ; str4=swfo_stis_nse_level_1(str3)
  ; rate=str2.total/str1.duration
  ; rate6=str2.total6/str1.duration
  ; str5={rate:rate,scaled_rate6:rate6/str1.pulser_frequency[1],rate_div_six:rate/6.,baseline:str4.baseline,sigma:str4.sigma}

  ; str=create_struct(str3,str5)

  if debug(5) then begin
    dprint,dlevel=5,str
    printdat,time_string(str.time,/local)
  endif

 ; last_str =str

  return,str

end


pro swfo_stis_nse_apdat::handler2,strct,source_dict=source_dict

  ;printdat,self
  if ~obj_valid(self.level_1a) then begin
    dprint,'Creating Level_1a for ',self.name
    self.level_1a = dynamicarray(name=self.prefix+'Noise_L1a')
  endif
  da =   self.level_1a
  strct_1 = swfo_stis_nse_level_1(strct)   ;this portio of code is no longer in use i think
  ;printdat,strct
  da.append, strct_1
end



pro swfo_stis_nse_apdat::sort ,uniq=uniq

  if isa(self.data,'dynamicarray') then begin
    self.data.sort,uniq=uniq
    raw = (*self.data.ptr).raw
    time = (*self.data.ptr).time
    dtime = time - shift(time,1)
    w = where(dtime lt 0 or dtime gt 290.,/null)
    dtime[w] = !values.d_nan
    (*self.data.ptr).histogram = (raw - shift(raw,0,1)) / ( replicate(1,60) # dtime )
    ;self.process_time = systime(1)
  endif
end




PRO swfo_stis_nse_apdat__define

  void = {swfo_stis_nse_apdat, $
    inherits swfo_gen_apdat, $    ; superclass
    level_1a: obj_new(),  $
    level_1b: obj_new(),  $
    level_2b: obj_new(),  $
    flag: 0 $
  }
END
