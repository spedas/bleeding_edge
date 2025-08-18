;+
;Procedure:
;  spd_slice2d_const
;
;Purpose:
;  Store constants in a single place for consistency
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_const.pro $
;-
pro spd_slice2d_const, q=q, mconv=mconv, c=c

    compile_opt idl2, hidden
    
  q = 1.602176d-19 ;J/eV
  
  c = 299792458d ;m/s
  
  mconv = 6.2508206d24 ; convert distrubution mass from eV/(km/s)^2 to kg

  return
end