
;+
;NAME:
; thm_sst_energy_cal2
;PURPOSE:
;  This routine performs bin energy boundary calibrations.  Transforming DAP values into eV
;  The routine directly modifies the dat struct according to parameters stored in the struct
;  But results can be returned for reference.
;  
;Inputs:
;  dat
;  
;Outputs:
;  energy:  The midpoint of each energy bin
;  denergy: The width of each energy bin
;
;SEE ALSO:
;  thm_sst_convert_units2
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-03-07 19:17:56 -0800 (Thu, 07 Mar 2013) $
;$LastChangedRevision: 11751 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_energy_cal2.pro $
;-


pro thm_sst_energy_cal2,dat,energy=energy,denergy=denergy,ft_ot=ft_ot,fto=fto,f_o=f_o

  if strmid(dat.data_name,2,1) eq 'i' then begin
    if keyword_set(ft_ot) then begin
      channel_mask = [0,0,0,0,0,0,0,0,0,0,0,0,1,1,!VALUES.D_NAN,!VALUES.D_NAN] ;OT is in bins 12-13
    endif else if keyword_set(fto) then begin
      channel_mask = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1] ;FTO(high) is in bin 15
    endif else begin
      channel_mask = [1,1,1,1,1,1,1,1,1,1,1,1,!VALUES.D_NAN,!VALUES.D_NAN,!VALUES.D_NAN,!VALUES.D_NAN] ;O is in bins 0-11
    endelse
  endif else begin
    if keyword_set(ft_ot) then begin
      channel_mask = [0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,!VALUES.D_NAN] ;FT is in bins 12,13,14
    endif else if keyword_set(fto) then begin
      channel_mask = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1] ;FTO(low) is in bin 15
    endif else if keyword_set(f_o) then begin
      channel_mask = [1,1,1,1,1,1,1,1,1,1,1,1,!VALUES.D_NAN,!VALUES.D_NAN,!VALUES.D_NAN,!VALUES.D_NAN] ;F is in bins 0-11
    endif else begin
      channel_mask = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,!VALUES.D_NAN] ;combined distribution uses data from 0-14
    endelse
  endelse
  
  e_start=dat.en_low
  e_end=dat.en_high
  
  ;ones = replicate(1.,16)

  denergy    = 1000*channel_mask*(e_end - e_start)
  energy   = 1000*channel_mask*(e_end + e_start)/2
  detectors = [replicate(0,16),replicate(1,16),replicate(2,16),replicate(3,16)]
 
  idx = where(channel_mask eq 0,c,complement=nidx,ncomplement=nc)
  if (c gt 0) then begin
    denergy[idx] = 0
    energy[idx] = 0
    
    if (nc eq 0) then begin
      energy[idx] = 0
    endif else begin
      energy[idx] = min(energy[nidx],/nan) ;make min greater than zero so that data range plots correctly
    endelse
  endif
  
  idx = where(~finite(channel_mask),c)
  if (c gt 0) then begin
    energy[idx] = max(energy*channel_mask,/nan)
    denergy[idx] = 0 
  endif
 
  dead_layer_offsets=replicate(1,16)#dat.dead_layer_offsets[detectors]*1000e ;convert from 4 element array to the standard 16x64 and convert units to keV
 
  dat.energy = energy[*,detectors]+dead_layer_offsets
  dat.denergy = denergy[*,detectors]
  
end
