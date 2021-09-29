FUNCTION sppeva_load_events_template
  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {$
    VERSION:1.00, $
    DATASTART:5L, $
    DELIMITER:0b, $;
    MISSINGVALUE:anan[0], $
    COMMENTSYMBOL:'', $
    FIELDCOUNT: 1L, $
    FIELDTYPES:7L, $
    FIELDNAMES:'FIELD', $
    FIELDLOCATIONS:0L, $
    FIELDGROUPS:lonarr(1)}
  return, ppp
End

FUNCTION sppeva_load_mde, filename=filename
  compile_opt idl2
  
  if undefined(filename) then begin
    filename = ProgramRootDir()+'spp.mde.txt'
  endif 
  result = read_ascii(filename, count=count, data_start=6, template=sppeva_load_events_template())
  
  print, 'count=',count
  return, result.FIELD
END
