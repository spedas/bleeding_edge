;+
;
;Procedure: thm_part_conv_units
;
;Purpose: Takes the distribution data structure from a call to thm_part_dist_array and calibrates it.
;Uses the ssl_general routine conv_units to perform the operation.  At this time, the operation is not 
;vectorized.
;
;Inputs:
;  dist_data: An array of pointers to arrays of structures.  One pointer for each mode in the time series, structure for each sample within the mode array.
;     Note: this routine modifes the contents of dist_data in place.(ie mutates dist_data) It has no return value. 
;           
;Keywords:
;  units: String specifying units requested for the output data.  If unspecified, units will be "eflux".  
;    If data is already in requested units, identify transform applied.
;    Possible selections(not case sensitive): COUNTS,RATE,EFLUX,FLUX,DF
;  fractional_counts: Flag to keep the ESA unit conversion routine from rounding 
;                     to an even number of counts when removing the dead time 
;                     correction (no effect if input data already in counts, 
;                     no effect on SST data).
;    
;   error: Used to report presence of an error to calling routine.  
;      error==0 means no error
;      error!=0 means error
;      
;   remove_negative_values: If set set negative values for the data
;                           tag of the input structures to zero
;
;Notes:
;  
;  This routine is part of an ongoing process to sanitize, modularize, and simplify the THEMIS particle routines.  
;
;See also: thm_part_dist_array.pro,thm_crib_part_extrapolate.pro
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-10-02 11:24:39 -0700 (Mon, 02 Oct 2017) $
; $LastChangedRevision: 24079 $
; $URL $
;-

pro thm_part_conv_units,dist_data,units=units,error=error,_extra=_extra

  error = 1

  if size(dist_data,/type) ne 10 then begin
    dprint,dlevel=1,"ERROR: dist_data undefined or has wrong type"
    return
  endif
  
  if ~keyword_set(units) then begin
    units='eflux'
  endif

  for i = 0,n_elements(dist_data)-1 do begin
    for j = 0,n_elements(*dist_data[i])-1 do begin
      (*dist_data[i])[j] = conv_units((*dist_data[i])[j],units,_extra=_extra)
    endfor
  endfor
  
  error = 0
end
