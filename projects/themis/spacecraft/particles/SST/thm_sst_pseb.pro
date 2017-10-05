;+
;
; Procedure: THM_SST_PSEB
;
;
;
;VERSION:
;  $LastChangedBy: $
;  $LastChangedDate: $
;  $LastChangedRevision:  $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/spacecraft/particles/SST/thm_sst_psef.pro $
;-

function thm_sst_pseb,time,index=index,probe=probe,times=times,$
                      err_msg=err_msg, msg_suppress=msg_suppress,$
                      badbins2mask=badbins2mask,_extra=ex

data_cache,'th'+probe+'_sst_raw_data',data,/get

if not keyword_set(data) then begin
   err_msg = 'No data loaded for probe '+probe
   if ~keyword_set(msg_suppress) then dprint,dlevel=1, err_msg
   return,0
endif

if ~ptr_valid(data.seb_064_time) then begin
   err_msg = 'No valid data of requested type for probe: '+probe
   if ~keyword_set(msg_suppress) then dprint,dlevel=1, err_msg
   return,0
end

if keyword_set(times) then return, *data.seb_064_time

dptr = data.seb_064_data
dim = size(/dimension,*dptr)
dist = thm_sst_dist3d_16x64(/elec,probe=probe)

dist.project_name = 'THEMIS'
dist.spacecraft = strlowcase(probe)
dist.data_name = 'SST Electron Full Burst distribution'
dist.apid = '45f'x

dist.magf = !values.f_nan

if n_elements(index) eq 0 then begin
    if n_elements(time) eq 0 then   ctime,time,npoints=1
    index=round( interp(dindgen(dim[0]),*data.seb_064_time,time) )
    
    if index lt 0 || index ge dim[0] then begin 
      dprint,dlevel=0,'No valid data for the requested time'
      return,0
    endif
endif

dprint,dlevel=5,index

dist.index = index
;Note SST L1 data has been corrected to be mid time interval, jmm, 2-oct-2012
dist.time = (*data.seb_064_time)[index]-1.5
dist.end_time = dist.time+3.0
dist.data= thm_part_decomp16((*data.seb_064_data)[index,*,*])
dist.cnfg= (*data.seb_064_cnfg)[index]
dist.atten = (*data.seb_064_atten)[index]
dist.eclipse_dphi = (*data.seb_064_edphi)[index]
dist.units_name='Counts'
dist.valid=1
dist.mass = 0.511e6/(2.9979e5)^2
dist.bins[12:15,*] = 0

if keyword_set(badbins2mask) then begin
   if array_equal(badbins2mask,1) then begin
      bad_ang = [0,16,32,48] ; default masking created by Davin
      badbins2mask = intarr(64)+1
      badbins2mask[bad_ang] = 0
   endif
endif


dist = thm_sst_remove_sunpulse(dist,badbins2mask=badbins2mask,msg_suppress=msg_suppress,_extra=ex)

return,dist
end
