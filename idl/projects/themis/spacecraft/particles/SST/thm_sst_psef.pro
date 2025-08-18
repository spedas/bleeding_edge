;+
;
; Procedure: THM_SST_PSEF
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
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_psef.pro $
;-

function thm_sst_psef,time,index=index,probe=probe,times=times,$
                      err_msg=err_msg, msg_suppress=msg_suppress, $
                      badbins2mask=badbins2mask,_extra=ex

data_cache,'th'+probe+'_sst_raw_data',data,/get

if not keyword_set(data) then begin
   err_msg = 'No data loaded for probe '+probe
   if ~keyword_set(msg_suppress) then dprint,dlevel=1, err_msg
   return,0
endif

if keyword_set(times) then return, *data.sef_064_time

dptr = data.sef_064_data
dim = size(/dimension,*dptr)
dist = thm_sst_dist3d_16x64(/elec,probe=probe)

dist.project_name = 'THEMIS'
dist.spacecraft = strlowcase(probe)
dist.data_name = 'SST Electron Full distribution'
dist.apid = '45d'x

dist.magf = !values.f_nan

if n_elements(index) eq 0 then begin
    if n_elements(time) eq 0 then   ctime,time,npoints=1
    index=round( interp(dindgen(dim[0]),*data.sef_064_time,time) )
    
    if index lt 0 || index ge dim[0] then begin 
      dprint,dlevel=0,'No valid data for the requested time'
      return,0
    endif
endif

dprint,dlevel=5,index

dist.index = index
;Note SST L1 data has been corrected to be mid time interval, jmm, 2-oct-2012
dist.time = (*data.sef_064_time)[index]-1.5
dist.end_time = dist.time+3.0
dist.data= thm_part_decomp16((*data.sef_064_data)[index,*,*])
dist.cnfg= (*data.sef_064_cnfg)[index]
dist.eclipse_dphi = (*data.sef_064_edphi)[index]

;There seems to be a timing error in the sst attenuator flags.  This leaves a short interval
;of data that is not corrected using the correct factor, creating a spike in the data.
;Shifting the attenuator flags by one sample seems to remove most of these errors.
;dist.atten = (*data.sef_064_atten)[index]
dist.atten = (*data.sef_064_atten)[index-1>0]
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

dist = thm_sst_remove_sunpulse(dist, badbins2mask=badbins2mask, msg_suppress=msg_suppress, _extra=ex)

return,dist
end
