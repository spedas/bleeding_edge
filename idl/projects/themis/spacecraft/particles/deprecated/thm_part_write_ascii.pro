;+
;Procedure:
;  thm_part_write_ascii
;
;Purpose:
;  Write standard 3D distribution structure to ascii file for 
;  use with geotail tool stel3d.pro.
;
;Calling Sequence:
;  thm_part_write_ascii, dist [filename=filename]
;
;Input:
;  dist: Pointer to standard 3D distribution structure array
;  filename: String specifying the filename, path may be included
;
;Output:
;  none/writes file
;
;Notes:
;  Ideally this is a temporary solution for using themis 
;  data with stel3d
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-23 18:52:50 -0700 (Mon, 23 May 2016) $
;$LastChangedRevision: 21180 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/deprecated/thm_part_write_ascii.pro $
;-

pro thm_part_write_ascii, dist, filename=filename

    compile_opt idl2, hidden




if ~ptr_valid(dist) || ~is_struct(*dist[0]) then begin
  dprint, dlevel=0, 'Invalid input'
  return
endif


;perform sanitization and unit conversion
;  -stel3d requires data in counts and df
thm_part_process, dist, dist_counts, units='counts'
thm_part_process, dist, dist_df, units='df'


;for velocity calculation later
c = 299792458d ;m/s
erest = (*dist[0])[0].mass * c^2 / 1e6 ;convert mass from eV/(km/s)^2 to eV/c^2


;get/create file name
if is_string(filename) then begin
  file = filename
endif else begin
  file = time_string( (*dist[0])[0].time, format=2 ) + '_'+ $
         strlowcase(strjoin( [(*dist[0])[0].project_name, $
                              (*dist[0])[0].spacecraft, $
                              (*dist[0])[0].data_name ], '_' ))
endelse

if ~stregex(file, '\.[^.]+$', /bool) then begin
  file += '.txt'
endif


;open file
;  -width required for lines to not wrap after 80 characters
openw, unit, file, /get_lun, width=110


;loop over modes
for mode=0, n_elements(dist_df)-1 do begin
  ;loop over distributions
  for i=0, n_elements(*dist_df[mode])-1 do begin

    ;write start time for this distribution
    printf, unit, time_string( (*dist_df[mode])[i].time, tformat='YYYYMMDD hh:mm:ss' )

    ;calculate velocities in km/s
    v = c * sqrt( 1 - 1/(((*dist_df[mode])[i].energy/erest + 1)^2) )  /  1000.

    ;write data line by line
    for j=0, n_elements( (*dist_df[mode])[i].data )-1 do begin  

      printf, unit, string( [ ((*dist_df[mode])[i].energy)[j], $
                              v[j], $
                              ((*dist_df[mode])[i].phi)[j], $
                              90-((*dist_df[mode])[i].theta)[j] , $ ;needs co-lat
                              ((*dist_counts[mode])[i].data)[j], $
                              ((*dist_df[mode])[i].data)[j] ] )

    endfor

    printf, unit, '' ;might be unnecessary

  endfor
endfor


;close file
free_lun, unit

dprint, dlevel=2, 'Data written to "'+file+'"'


;clear data copies
ptr_free, dist_counts
ptr_free, dist_df


end