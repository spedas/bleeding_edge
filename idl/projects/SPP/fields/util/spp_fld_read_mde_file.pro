;+
;
; Load MDE file for PSP into an IDL hash
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-11-04 11:26:44 -0800 (Tue, 04 Nov 2025) $
; $LastChangedRevision: 33821 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/spp_fld_read_mde_file.pro $
;-

function spp_fld_read_mde_file, mde_file
  compile_opt idl2

  openr, lun, mde_file, /get_lun

  line = ''

  lines = []

  while not eof(lun) do begin
    readf, lun, line

    lines = [lines, line]
  endwhile

  free_lun, lun

  mde = orderedhash()

  orb = 0
  orb_line_i = 0

  foreach line, lines, line_i do begin
    if (line.split(' '))[0] eq 'Orbit' then begin
      orb += 1

      orb_line_i = 0

      orb_key = 'Orbit' + string(orb, format = '(I02)')

      mde[orb_key] = orderedhash()
    endif else begin
      orb_line_i += 1
    endelse

    if orb eq 0 and line ne '' then begin
      line_split = line.split(': ')

      mde[line_split[0]] = line_split[1]
    endif

    if orb gt 0 and orb_line_i eq 2 then begin
      line_split = line.split(' +')

      (mde[orb_key])['start_day'] = line_split[0]
      (mde[orb_key])['start_time'] = line_split[1]

      (mde[orb_key])['start_t'] = time_double(line_split[0] + '/' + line_split[1], $
        tformat = 'MM-DD-YYYY/hh:mm:ss')

      (mde[orb_key])['stop_day'] = line_split[2]
      (mde[orb_key])['stop_time'] = line_split[3]

      (mde[orb_key])['stop_t'] = time_double(line_split[2] + '/' + line_split[3], $
        tformat = 'MM-DD-YYYY/hh:mm:ss')
    endif

    if orb gt 0 and orb_line_i ge 5 and line ne '' then begin
      line_split = line.split('( +){2}')

      (mde[orb_key])[line_split[1]] = time_double(line_split[0], tformat = 'MM-DD-YYYY hh:mm:ss')
    endif
  endforeach

  mde['filename'] = mde_file

  return, mde
end
