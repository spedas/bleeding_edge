;+
;
;  Procedure: THM_SST_PSIF
;
;  For documentation on sun contamination correction keywords that
;  may be passed in through the _extra keyword please see:
;  thm_sst_remove_sunpulse.pro or thm_crib_sst_contamination.pro
;
;
;VERSION:
;  $LastChangedBy: aaflores $
;  $LastChangedDate: 2016-02-05 14:02:49 -0800 (Fri, 05 Feb 2016) $
;  $LastChangedRevision: 19904 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_psif.pro $
;-

function thm_sst_psif,time,index=index,probe=probe,times=times,$
                      badbins2mask=badbins2mask, $
                      err_msg=err_msg, msg_suppress=msg_suppress, $
                      _extra=ex


data_cache,'th'+probe+'_sst_raw_data',data,/get

if not keyword_set(data) then begin
   err_msg = 'No data loaded for probe '+probe
   dprint,dlevel=1, err_msg
   return,0
endif

if keyword_set(times) then return, *data.sif_064_time

dptr = data.sif_064_data
dim = size(/dimension,*dptr)
dist = thm_sst_dist3d_16x64(/ion,probe=probe)

dist.project_name = 'THEMIS'
dist.spacecraft = strlowcase(probe)
dist.data_name = 'SST Ion Full distribution'
dist.apid = '45a'x

dist.magf = !values.f_nan

if n_elements(index) eq 0 then begin
    if n_elements(time) eq 0 then begin
       ctime,time
    endif
    index=round( interp(dindgen(dim[0]),*data.sif_064_time,time) ,/l64)
    
    if index lt 0 || index ge dim[0] then begin 
      dprint,dlevel=0,'No valid data for the requested time'
      return,0
    endif
endif
dprint,dlevel=5,index
dist.index = index
if index lt 0 or index ge n_elements(*data.sif_064_time) then return,dist
;Note SST L1 data has been corrected to be mid time interval, jmm, 2-oct-2012
dist.time = (*data.sif_064_time)[index]-1.5
dist.end_time = dist.time+3.0
dist.data= thm_part_decomp16((*data.sif_064_data)[index,*,*])
dist.cnfg= (*data.sif_064_cnfg)[index]
dist.nspins= (*data.sif_064_nspins)[index]
dist.eclipse_dphi = (*data.sif_064_edphi)[index]
;dist.cnfg= (*data.sif_064_hed)[index,13]
;
;There seems to be a timing error in the sst attenuator flags.  This leaves a short interval
;of data that is not corrected using the correct factor, creating a spike in the data.
;Shifting the attenuator flags by one sample seems to remove most of these errors.
;dist.atten = (*data.sif_064_atten)[index]
dist.atten = (*data.sif_064_atten)[index-1>0]
dist.units_name = 'Counts'
dist.valid=1
dist.mass = 1836.*0.511e6/(2.9979e5)^2
dist.bins[12:15,*] = 0

if keyword_set(badbins2mask) then begin
   if array_equal(badbins2mask,1) then begin
      bad_ang = [0,16,32,48] ; default masking created by Davin
      badbins2mask = intarr(64)+1
      badbins2mask[bad_ang] = 0
   endif
endif

dist = thm_sst_remove_sunpulse(badbins2mask=badbins2mask,dist,err_msg=err_msg,msg_suppress=msg_suppress,_extra=ex)

return,dist
end
