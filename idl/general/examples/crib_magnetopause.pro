;+
; Magnetopause crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to clrussell@igpp.ucla.edu
;
;
; $LastChangedBy: clrussell $
; $LastChangedDate: 2016-05-25 14:40:54 -0700 (Wed, 25 May 2016) $
; $LastChangedRevision: 21203 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/examples/basic/mms_load_state_crib.pro $
;-
pro crib_magnetopause

; Initialize themis settings
thm_init

;; =========
;; mpause_2
;; =========
;This magnetopause subroutine calculates the magnetopause (X,Y) locations based on 
;    the Fairfield model (JGR, 1971).  Aberation of 4 degrees is assumed
;    The output is the location of the magnetopause down to a very large distance (xmp_max=-300 Re)
mpause_2,xmp,ymp
xrange=[100, -300]
plot, xmp, ymp, xrange=xrange

stop
;; ============
;; mpause_t96
;; ============
;This magnetopause subroutine the pressure-dependent magnetopause that is 
;used in the T96_01 MODEL
;  (TSYGANENKO, JGR, V.100, P.5599, 1995; ESA SP-389, P.181, O;T. 1996)
;   AUTHOR:  N.A. TSYGANENKO
;   INPUT:  PD -  THE SOLAR WIND RAM PRESSURE IN NANOPAS
;           XGSM, YGSM, ZGSM  - position of points in re for flagging
;
;   OUTPUT: XMGNP, YMGNP, ZMGNP - location of magnetopause in re
;           ID - flag, whether XGSM, YGSM, ZGSM are inside or outside mp
;           DISTAN - distance between XGSM, YGSM, ZGSM and Xmp0, Ymp0, Zmp0 in re
;                    Xmp0, Ymp0, Zmp0 is the boundary point, having the same value of TAU
;
;  RATIO OF PD TO THE AVERAGE PRESSURE, ASSUMED EQUAL TO 2 nPa:

; set date and time
; download data for 8/2/2015
date = '2019-01-05/00:00:00'
timespan,date,1,/day
tr=timerange()
dynp=2.
re=6378.
thm_load_state, probe='d', trange=tr, datatype='pos'
cotrans,'thd_state_pos','thd_state_pos_gse',/gei2gse
cotrans,'thd_state_pos_gse','thd_state_pos_gsm',/gse2gsm 
get_data, 'thd_state_pos_gsm', data=pos_gsm
mpause_t96,dynp,xmgnp=xmgnp,ymgnp=ymgnp,xgsm=pos_gsm.y[*,0]/re,ygsm=pos_gsm.y[*,1]/re,zgsm=pos_gsm.y[*,2]/re,id=id,distan=distan
help, id
help, distan
xrange=[20,-60]
plot, xmgnp, ymgnp, xrange=xrange

end