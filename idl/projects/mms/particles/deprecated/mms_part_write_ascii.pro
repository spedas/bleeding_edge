;+
;Procedure:
;  mms_part_write_ascii
;
;Purpose:
;  Write standard 3D distribution structure to ascii file for 
;  use with geotail tool stel3d.pro.
;
;Calling Sequence:
;  mms_part_write_ascii, dist [filename=filename]
;
;Input:
;  dist: Pointer to standard 3D distribution structure array
;  filename: String specifying the filename, path may be included
;
;Output:
;  none/writes file
;
;Notes:
;  Ideally this is a temporary solution for using MMS 
;  data with stel3d
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-05-13 14:40:51 -0700 (Fri, 13 May 2016) $
;$LastChangedRevision: 21082 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/deprecated/mms_part_write_ascii.pro $
;-

pro mms_part_write_ascii, dist, filename=filename

    compile_opt idl2, hidden




if ~ptr_valid(dist) || ~is_struct(*dist[0]) then begin
  dprint, dlevel=0, 'Invalid input'
  return
endif


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
for mode=0, n_elements(dist)-1 do begin
  ;loop over distributions
  for i=0, n_elements(*dist[mode])-1 do begin

    ;write start time for this distribution
    printf, unit, time_string( (*dist[mode])[i].time, tformat='YYYYMMDD hh:mm:ss' )

    ;calculate velocities in km/s
    v = c * sqrt( 1 - 1/(((*dist[mode])[i].energy/erest + 1)^2) )  /  1000.

    ;stel3d requires data in psd and counts
    ;since we have no count data or conversion replace with eflux as a placeholder
    mms_convert_flux_units, (*dist[mode])[i], output=counts, units='eflux'

    ;write data line by line
    for j=0, n_elements( (*dist[mode])[i].data )-1 do begin  

      printf, unit, string( [ ((*dist[mode])[i].energy)[j], $
                              v[j], $
                              ((*dist[mode])[i].phi)[j], $
                              90-((*dist[mode])[i].theta)[j] , $ ;needs co-lat
                              (counts.data)[j], $
                              ((*dist[mode])[i].data)[j] ] )

    endfor

    printf, unit, '' ;might be unnecessary

  endfor
endfor


;close file
free_lun, unit

dprint, dlevel=2, 'Data written to "'+file+'"'


end