;+
;  $Id: thm_sst_psir.pro 19904 2016-02-05 22:02:49Z aaflores $
;-
function thm_sst_psir,time,index=index,probe=probe,times=times,$
                      err_msg=err_msg, msg_suppress=msg_suppress,$ 
                      badbins2mask=badbins2mask

data_cache,'th'+probe+'_sst_raw_data',data,/get

if not keyword_set(data) then begin
   err_msg = 'No data loaded for probe '+probe
   if ~keyword_set(msg_suppress) then dprint,dlevel=1, err_msg
   return,0
endif


if keyword_set(times) then  return, *data.sir_mix_time

if n_elements(index) eq 0 then begin
    if n_elements(time) eq 0 then begin
        ctime,time
    endif
    index=round( interp(dindgen(n_elements(*data.sir_mix_time)),*data.sir_mix_time,time) )
    
    if index lt 0 || index ge n_elements(*data.sir_mix_time) then begin 
      dprint,dlevel=0,'No valid data for the requested time'
      return,0
    endif
endif

if n_elements(index) ne 1 then message,'time/index ranges not allowed yet'

mode = (*data.sir_mix_mode)[index]
ind  = (*data.sir_mix_index)[index]

case  mode of
  0:  begin          ; 6 angle mode
      dptr = { data: data.sir_006_data, $
               time: data.sir_006_time, $
               cnfg: data.sir_006_cnfg, $
               attn: data.sir_006_atten,$
               edphi: data.sir_006_edphi }
      dist = thm_sst_dist3d_16x6(/elec,probe=probe)
      end
  1:  begin          ; 1 angle mode
      dptr = { data: data.sir_001_data, $
               time: data.sir_001_time, $
               cnfg: data.sir_001_cnfg, $
               attn: data.sir_001_atten,$
               edphi: data.sir_001_edphi }
      dist = thm_sst_dist3d_16x1(/elec,probe=probe)
      end
endcase


;dim = size(/dimension,*dptr)
;dist = dst.d3d
dist.project_name = 'THEMIS'
dist.spacecraft = strlowcase(probe)
dist.data_name  = 'SST Ion Reduced Distribution'
dist.apid = '45b'x

dist.magf = !values.f_nan


dprint,dlevel=4,'index=',index,'ind=',ind

dist.index = ind
;Note SST L1 data has been corrected to be mid time interval, jmm, 2-oct-2012
dist.time = (*dptr.time)[ind]-1.5
dist.end_time = dist.time+3.0
dist.data= thm_part_decomp16((*dptr.data)[ind,*,*])
dist.cnfg= (*dptr.cnfg)[ind]
dist.atten = (*dptr.attn)[ind]
dist.eclipse_dphi = (*dptr.edphi)[ind]
dist.units_name = 'Counts'
dist.valid=1
dist.mass = 0.511e6/(2.9979e5)^2

;disable uncalibrated OT/T/FTO bins
if ndimen(dist.bins) ge 2 then begin
  dist.bins[12:15,*] = 0
endif else begin
  dist.bins[12:15] = 0
endelse

if keyword_set(badbins2mask) then begin
   bad_ang = badbins2mask
   if array_equal(badbins2mask, -1) then begin
      err_msg = 'WARNING: BADBINS2MASK array is empty. No bins '+ $
                'masked for th'+probe+'_psir data.'
      if ~keyword_set(msg_suppress) then dprint, dlevel=1, err_msg
   endif else begin
     if ndimen(dist.bins) ge 2 then begin
       dist.bins[*,bad_ang]=0
     endif
   endelse
endif

return,dist
end
