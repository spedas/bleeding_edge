; read ascii template for parameter set file
Function eva_data_template
  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {VERSION:1.00000, $
    DATASTART:0L, $
    DELIMITER:32b, $
    MISSINGVALUE:anan[0], $
    COMMENTSYMBOL:';', $
    FIELDCOUNT:1, $
    FIELDTYPES:[7L], $
    FIELDNAMES:['param'], $
    FIELDLOCATIONS:0, $
    FIELDGROUPS:0}
  return, ppp
End