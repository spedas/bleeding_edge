;+
; This is a routine that needs further testing, development, and enhancements.
; PROCEDURE:  cdf_partial_epoch_finder, cdf_id, epoch_names
; Purpose:  Supports partial loading of cdf files by determining which range of indices
; to load based on time_span and the epoch variables in a cdf file.
;
; INPUT:
;    cdf_id: File ID of an opened CDF file
;    epoch_names: Names of the epoch variables for which to find indices
; OUTPUT:
;    epoch_indices: Indices corresponding to start/stop of timespan for each
;    epoch variable (LONARR(number of epoch names, 2))
; Written by Peter Schroeder
;
; $LastChangedBy: peters $
; $LastChangedDate: 2013-12-11 12:20:54 -0800 (Wed, 11 Dec 2013) $
; $LastChangedRevision: 13659 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/cdf_partial_load/cdf_partial_epoch_finder.pro $
;-
pro cdf_partial_epoch_finder,cdf_id,epoch_names,epoch_indices

get_timespan,tspan

number_of_epochs = n_elements(epoch_names)

epoch_indices = lonarr(number_of_epochs,2)

info = cdf_info(cdf_id)

for i = 0, number_of_epochs - 1 do begin
   found_start = 0
   found_end = 0
   this_var = where(info.vars.name eq epoch_names[i])
   epoch_type = info.vars[this_var].datatype
   epoch_nrecs = info.vars[this_var].numrec
   cdf_varget, cdf_id, epoch_names[i], start_epoch, rec_start=0
   if epoch_type eq 'CDF_TIME_TT2000' then start_time = time_double(start_epoch,/tt2000) $
      else start_time = time_double(start_epoch,/epoch)
   cdf_varget,cdf_id, epoch_names[i], end_epoch, rec_start=epoch_nrecs-1
   if epoch_type eq 'CDF_TIME_TT2000' then end_time = time_double(end_epoch,/tt2000) $
      else end_time = time_double(end_epoch,/epoch)
   if (tspan[1] lt start_time) or (tspan[0] gt end_time) then begin
      epoch_indices[i,0] = -1
      epoch_indices[i,1] = -1
      found_start = 1
      found_end = 1
   endif
   if tspan[0] le start_time then begin
      start_index = 0
      epoch_indices[i,0] = 0
      found_start = 1
   endif
   if tspan[1] ge end_time then begin
      end_index = epoch_nrecs-1
      epoch_indices[i,1] = end_index
      found_end = 1
   endif
   print,'First time in file: ',time_string(start_time)
   print,'Last time in file: ',time_string(end_time)
   search_start = 0
   search_end = epoch_nrecs-1
   new_time = end_time
   while (found_start eq 0) do begin
      if search_start eq search_end then begin
         start_index = search_start
         epoch_indices[i,0] = start_index
         found_start = 1
      endif else if (search_end - search_start) eq 1 then begin
         if tspan[0] lt new_time then begin
            start_index = search_start
            epoch_indices[i,0] = start_index
            found_start = 1
         endif else begin
            start_index = search_end
            epoch_indices[i,0] = start_index
            found_start = 1
         endelse
      endif else begin
         new_index = (search_end - search_start) / 2l + search_start
         cdf_varget,cdf_id, epoch_names[i], end_epoch, rec_start=new_index
         if epoch_type eq 'CDF_TIME_TT2000' then new_time = time_double(end_epoch,/tt2000) $
            else new_time = time_double(end_epoch,/epoch)
         if new_time eq tspan[0] then begin
            start_index = new_index
            epoch_indices[i,0] = new_index
            found_start = 1
         endif else begin
            if new_time lt tspan[0] then $
               search_start = new_index else $
               search_end = new_index
         endelse
      endelse
   endwhile
   search_start = start_index
   search_end = epoch_nrecs-1
   while (found_end eq 0) do begin
      if search_start eq search_end then begin
         end_index = search_start
         epoch_indices[i,1] = end_index
         found_end = 1
      endif else if (search_end - search_start) eq 1 then begin
         if tspan[1] gt new_time then begin
            end_index = search_start
            epoch_indices[i,1] = end_index
            found_end = 1
         endif else begin
            end_index = search_end
            epoch_indices[i,1] = end_index
            found_end = 1
         endelse
      endif else begin
         new_index = (search_end - search_start) / 2l + search_start
         cdf_varget,cdf_id, epoch_names[i], end_epoch, rec_start=new_index
         if epoch_type eq 'CDF_TIME_TT2000' then new_time = time_double(end_epoch,/tt2000) $
            else new_time = time_double(end_epoch,/epoch)
         if new_time eq tspan[1] then begin
            end_index = new_index
            epoch_indices[i,1] = new_index
            found_end = 1
         endif else begin
            if new_time lt tspan[1] then $
               search_start = new_index else $
               search_end = new_index
         endelse
      endelse
   endwhile
endfor
return
end

