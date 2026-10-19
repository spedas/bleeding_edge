;+
;NAME:
;   srscan_read_config
;
;PURPOSE:
;   Reads the srs_canada configuration file (srscan_config.txt) from the
;   directory given by srscan_config_filedir.
;
;CALLING SEQUENCE:
;   cfg = srscan_read_config()
;
;OUTPUT:
;   A structure with the changeable fields of the !srs_canada structure,
;   or -1 if no config file exists.
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-10-14 09:44:38 -0700 (Wed, 14 Oct 2026) $
;$LastChangedRevision: 34972 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/srs_canada/srscan_read_config.pro $
;-
function srscan_config_template

  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {VERSION: 1.00000, $
         DATASTART: 3l, $
         DELIMITER: 61b, $
         MISSINGVALUE: anan[0], $
         COMMENTSYMBOL: ';', $
         FIELDCOUNT: 2l, $
         FIELDTYPES: [7l, 7l], $
         FIELDNAMES: ['FIELD1', 'FIELD2'], $
         FIELDLOCATIONS: [0l, 15l], $
         FIELDGROUPS: [0l, 1l]}

  return, ppp
end

function srscan_read_config, header=hhh
  otp = -1

  dir = srscan_config_filedir(/app_query)
  if dir[0] ne '' then begin
    ll = strmid(dir, strlen(dir)-1, 1)
    if (ll eq '/' or ll eq '\') then filex = dir + 'srscan_config.txt' $
    else filex = dir + '/' + 'srscan_config.txt'

    if file_search(filex) ne '' then begin
      template = srscan_config_template()
      strfx = read_ascii(filex, template=template, header=hhh)
      if size(strfx, /type) eq 8 then begin
        otp = create_struct(strtrim(strfx.field1[0], 2), $
                            strtrim(strfx.field2[0], 2), $
                            strtrim(strfx.field1[1], 2), $
                            strtrim(strfx.field2[1], 2))
        for j = 2, n_elements(strfx.field1)-1 do begin
          if is_numeric(strfx.field2[j]) then begin
            str_element, otp, strtrim(strfx.field1[j], 2), $
                         fix(strfx.field2[j]), /add
          endif else str_element, otp, strtrim(strfx.field1[j], 2), $
                                  strtrim(strfx.field2[j], 2), /add
        endfor
      endif
    endif
  endif

  return, otp
end
