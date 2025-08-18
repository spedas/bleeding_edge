;+
; NAME:
;     THM_GSM2LMN_WRAP
;
; PURPOSE:
;	Wrapper transforms THEMIS-generated vector field from GSM to LMN (boundary-normal)
;	coordinate system for magnetopause with help of routine gsm2lmn.pro.
;	It gets the necessary solar wind data with help of routine
;	get_sw_data.pro and passes all necessary keywords to it.
;	In distinction of GSM2LMN_WRAP, it finds space-time coordinates using
;	reference to a THEMIS probe.
;
; CATEGORY:
;	Coordinate Transformation
;
; CALLING SEQUENCE:
;	thm_gsm2lmn_wrap,data_in,data_out,probe,SWkeywords
;
; INPUTS:
;	data_in: structure {x:time, y:data}
;	probe: string specify which spacecraft caught data_in.
;
; KEYWORDS: Solarwind_load.pro keywords (Any combination of keywords defining
;           output of solarwind_load.pro)
;
; PARAMETERS: none
;
; OUTPUTS:
;	data_out: structure {x:time, y:transformed_data}
;
; DEPENDENCIES: gsm2lmn.pro, solarwind_load.pro. Intermediate-level part of LMN 
;		transform package.
;
; MODIFICATION HISTORY:
;     Written by: Liu Jiang 09/21/2007
;	Modified for new background routines by: Vladimir Kondratovich 2007/12/28
;	Modified for error handling and changed () to [] for arrays
;	                                     by: Lynn B. Wilson III    2012/10/26
;-
;
; THE CODE BEGINS:

pro thm_gsm2lmn_wrap,data_in,data_out,probe,_Extra=ex

;; Check input
IF (N_PARAMS() EQ 2) THEN BEGIN
  probe = 'all'
ENDIF ELSE probe = STRLOWCASE(probe[0])  ;; make sure it's lowercase
; preparation of data
time  = data_in.X
btgsm = data_in.Y
timer = [time[0],time[N_ELEMENTS(time) - 1L]]
solarwind_load,swdata,dst,timer,_Extra=ex

; get the position of THEMIS
thm_load_state, probe=probe, trange = timer, /GET_SUPP
statname = 'th'+probe+'_state_pos'
get_data, statname, timep, ptgei
IF (SIZE(timep,/TYPE) NE 5 AND N_ELEMENTS(timep) EQ 1) THEN BEGIN
  badmssg = 'No state positions were found...'
  MESSAGE,badmssg,/CONTINUE,/INFORMATIONAL
  RETURN
ENDIF
;; Rotate positions:  GEI -> GSE
cotrans, ptgei, ptgse, timep, /GEI2GSE
;; Rotate positions:  GSE -> GSM
cotrans, ptgse, ptgsm, timep, /GSE2GSM

nout     = N_ELEMENTS(time)
ptgsmout = FLTARR(nout,3)
FOR ii=0L, 2L DO BEGIN
   pti            = REFORM(ptgsm[*,ii])
   ptouti         = INTERPOL(pti,timep,time)
   ptgsmout[*,ii] = ptouti
ENDFOR

txyz = [[time],[ptgsmout]]
bxyz = btgsm
;; Rotate input:  GSM -> LMN
gsm2lmn,txyz,bxyz,blmn,swdata

data_out = {X:time,Y:blmn}

RETURN
END
