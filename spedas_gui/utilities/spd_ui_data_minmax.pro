;+
;NAME:
;  spd_ui_data_minmax
;
;PURPOSE:
;  Returns a two-element array containing the mininum and maximum values
;  contained in the loadedData quantity specified by the NAME positional
;  parameter.
;
;CALLING SEQUENCE:
;  minmax = spd_ui_data_minmax(loadedData, options)
;
;INPUT:
;  loadedData: The loadedData object.
;  name: The name of the variable (a string).
;  
;KEYWORDS:
;  none
;
;OUTPUT:
;  [minRange, maxRange]: A two-element array containing the mininum and maximum
;                        values of the quantity specified by the NAME parameter.
;-

function spd_ui_data_minmax, loadedData, name

  compile_opt idl2, hidden

  minRange = !values.d_nan
  maxRange = !values.d_nan
  
  loadedData->getVarData, name=name, data=d
  
  minRange = min(*d, max=maxRange, /nan)
   
  return, [minRange, maxRange]
end
