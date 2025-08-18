;+
; PRO:  das2dlm_cassini_init, ...
;
; Description:
;   Setup graphics. Using when Cassini data is loading
;   
; Keywords:
;   no_color_setup: Set to avoid doing the default graphic settings
;
; CREATED BY:
;  Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-06-01 17:27:59 -0700 (Mon, 01 Jun 2020) $
; $Revision: 28753 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_cassini_init.pro $
;-

pro das2dlm_cassini_init, no_color_setup=no_color_setup 
  
  ;Set the defalut color table
  if ~keyword_set(no_color_setup) then spd_graphics_config, colortable=colortable
  
  ; Some other useful tplot options (from erg_init):
  tplot_options,window=0            ; Forces tplot to use only window 0 for all time plots
  tplot_options,'wshow',1           ; Raises tplot window when tplot is called  
  tplot_options,'no_interp',1       ; prevents interpolation in spectrograms (recommended)
  ;tplot_options,'lazy_ytitle',1     ; breaks "_" into carriage returns on ytitles
  
  return
end
  