;+
; Deprecated, 2020-04-13, jmm
; 
; NAME: rbsp_mageis_example_crib.pro
; SYNTAX:
; PURPOSE: Crib sheet showing how to load MagEIS data
; INPUT:
; OUTPUT:
; KEYWORDS:
; HISTORY: Created by Aaron Breneman
; VERSION:
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2020-05-21 20:36:46 -0700 (Thu, 21 May 2020) $
;   $LastChangedRevision: 28720 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_mageis_example_crib_old.pro $
;-


probe='a'
timespan,'2013-02-17',1


rbsp_load_mageis_l2,probe=probe,/get_mag_ephem

tplot,'*FEDO'

; switch to line plots
options,'*FEDO','spec',0
ylim,'*FEDO',1,2.e7,1
options,'*FEDO',ysubtitle='[cm!U-2!N s!U-1!N keV!U-1!N]'
options,'*FEDO','labflag',-1

tplot,'*FEDO'

; switch back to spec
options,'*FEDO','spec',1
ylim,'*FEDO',20,4000,1
zlim,'*FEDO',1,2.e7,1
options,'*FEDO',ztitle='[cm!U-2!N s!U-1!N keV!U-1!N]'
options,'*FEDO',ysubtitle='Energy [keV]'

tplot,'*FEDO'


end
