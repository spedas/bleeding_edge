;+
;PROCEDURE: THM_SST_FIND_MASKING
;Purpose:
;  This routine is designed to find the indices of the masking in the SST Full distribution data.
;  It directly checks the common block and then returns it for use by the remove_sunpulse routine
;  While it is the function that actually takes the mask_fill argument, it should not ever be
;  directly called by a user.   It was written so that it can identify the mask locations
;  efficiently using a total, prior to the point at which thm_part_moments and thm_part_moments2
;  begin to iterate over time.
;
;  The majority of the documentation can be found in thm_remove_sunpulse.pro and thm_crib_sst_contamination.pro
;
; Arguments:
;    thx:  a string storing the satellite prefix(ie 'tha')
;    instrument:  a string identifying the instrument(ie 'psif')
;    index:  a list of indices which specify the times that were requested
; Keywords:
;    mask_remove: Set this keyword to the proportion of values that must be 0 at all energies to determine that a mask is present.
;             Generally .99 or 1.0 is a good value.   The mask is a set of points that are set to 0 on-board the spacecraft.  By default they will
;             be filled by linear interpolation across phi.  This keyword should be passed down via _extra from the parent
;             routine.  If this keyword is not set, this routine will always return -1.
;SEE ALSO:
;  thm_part_moments.pro, thm_part_moments2.pro, thm_part_getspec.pro
;  thm_part_dist.pro, thm_sst_psif.pro, thm_sst_psef.pro, thm_crib_sst_contamination.pro
;  thm_sst_remove_sunpulse.pro
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-01-10 16:45:16 -0800 (Thu, 10 Jan 2013) $
; $LastChangedRevision: 11423 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_find_masking.pro $
;-

function thm_sst_find_masking,thx,instrument,index,mask_remove=mask_remove,sst_cal=sst_cal

  compile_opt idl2
  
  if ~keyword_set(thx) || ~keyword_set(instrument) || ~keyword_set(index) then begin
    return,-1 ;keywords not set
  endif

  if (strmatch(instrument,'ps?f') || strmatch(instrument,'pseb')) && keyword_set(mask_remove) then begin
  
    if ~keyword_set(sst_cal) then begin
      data_cache,thx+'_sst_raw_data',data_str,/get
    endif else begin
      message,'ERROR: Find masking not yet compatible with /sst_cal"
    endelse
    
    if ~keyword_set(data_str) then begin
      return,-1   ;no data
    endif
    
    if strmatch(instrument,'psif') then begin
      dat=thm_part_decomp16((*data_str.sif_064_data)[index,*,*])
    endif else if strmatch(instrument,'psef') then begin
      dat=thm_part_decomp16((*data_str.sef_064_data)[index,*,*])
    endif else if strmatch(instrument,'pseb') then begin
      dat=thm_part_decomp16((*data_str.seb_064_data)[index,*,*])
    endif else begin
      return, -1 ;invalid instrument type
    endelse
    
    if mask_remove eq 1.0 then begin
    
      dat_t = total(dat,1)  ;check whether the data is always zero at a given angle
    
      idx = where(dat_t eq 0) ;find 0s
    
    endif else begin
    
      idx1 = where(dat eq 0)  ;check whether the data has more than a certain percentage of zeros in the data
      idx2 = where(dat ne 0)
      
      dim = dimen(dat)
      
      dat_cnt = dindgen(dim)
      
      dat_cnt[idx1] = 1
      dat_cnt[idx2] = 0
      
      dat_t = total(dat_cnt,1)
      
      idx = where(dat_t / dim[0] gt mask_remove)
      ;idx2 = where(dat_t / dim[0] le mask_remove)
      
    endelse
    
    ;This finds the 0s that occur at all energies and times
    ;note that this sequence will actually constitute a contiguous sequence of indexes,as well
    if idx[0] ne -1 then begin
    
      mask_arr = dblarr(16,64)
      
      mask_arr[*] = 1
      mask_arr[idx] = 0
      
      mask_arr_t = total(mask_arr,1)
      
      idx_mask = where(mask_arr_t eq 0)
    
      if idx_mask[0] ne -1 then begin
      
        mask_out = dblarr(16,64)
        
        mask_out[*] = 1
        
        mask_out[*,idx_mask] = 0
      
        return,mask_out
        
      endif
      
    endif
    
  endif
    
    return,-1    
      
end
;      idx_hist = where(histogram(idx/16,binsize=1,min=0) eq 16) ;find the value of any 0s that are at all energies
;    
;      if idx_hist[0] ne -1 then begin
;      
;        idx_mask = where(idx/16 eq idx_hist[0])  ; find where the 0s at all energies are
;        
;        if idx_mask[0] ne -1 then begin
;        
;          idx_invalid = ssl_set_complement(idx_mask,indgen(n_elements(idx))) ;0s that are not at all energies
;          
;          if idx_invalid[0] ne -1 then begin
;          
;            idx = idx[idx_invalid]                      
;            dat_t[idx] = 1 ;set invalid 0's equal to non-zero value
;            
;          endif
;          
;          return,dat_t ; at least some 0s exist at all energies
;          
;        endif else begin
;        
;          return,-1 ; no 0s exist at all energies
;          
;        endelse
;         
;      endif
;    
;    endif
;    
;  endif
;  
;  return,-1
