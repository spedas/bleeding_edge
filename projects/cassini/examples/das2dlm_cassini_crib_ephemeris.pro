;+
; das2dlm_cassini_crib_ephemeris.pro
;
; Description:
;   A crib sheet loads all possible ephemiris Cassini data;   
;   Note, it requres das2dlm library
;   Note, this is rather a test case than practical example
;
; CREATED BY:
;   Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-07-27 13:04:34 -0700 (Mon, 27 Jul 2020) $
; $Revision: 28941 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/examples/das2dlm_cassini_crib_ephemeris.pro $
;-


dataset = ['Dione', 'Dione_CoRotation', 'Earth', 'Enceladus', 'Enceladus_CoRotation', $
  'Hyperion', 'Iapetus', 'Mimas', 'Phoebe','Rhea','Rhea_CoRotation', 'Jupiter', $
  'Saturn','Saturn_Equatorial','Saturn_KSM','Saturn_SLS2','Saturn_SLS3',$
  'Sun','Tethys','Tethys_CoRotation','Titan','Titan_CoRotation','Venus']

for i=0,size(dataset,/N_ELEMENTS)-1 do begin
  das2dlm_load_cassini_ephemeris, trange=['2013-01-01', '2013-01-02'],source=dataset[i] 
endfor

tplot_names



end