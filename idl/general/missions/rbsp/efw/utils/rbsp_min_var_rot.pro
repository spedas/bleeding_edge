;+
;*****************************************************************************************
;
;  FUNCTION :  rbsp_min_var_rot.pro
;  PURPOSE  :  Calculates the minimum variance matrix of some vector array of a 
;               particular input field along with uncertainties and angular 
;               rotation from original coordinate system.
;
;==-----------------------------------------------------------------------------
;*******************************************************************************
; Error Analysis from: A.V. Khrabrov and B.U.O. Sonnerup, JGR Vol. 103, 1998.
;
;
;avsra = WHERE(tsall LE timesta+30.d0 AND tsall GE timesta-30.d0,avsa)
;myrotma = MIN_VAR(myavgmax[avsra],myavgmay[avsra],myavgmaz[avsra],EIG_VALS=myeiga)
;
; dphi[i,j] = +/- SQRT(lam_3*(lam_[i]+lam_[j]-lam_3)/((K-1)*(lam_[i] - lam_[j])^2))
;
; dphi = angular standard deviation (radians) of vector x[i] toward/away from 
;         vector x[j]
;*******************************************************************************
;  Hoppe et. al. [1981] :
;      lam_3 : Max Variance
;      lam_2 : Intermediate Variance
;      lam_1 : MInimum Variance
;
;        [Assume isotropic "noise" in signals]
;      Variance due to signal (along MAX VARIANCE) : lam_1 - lam_3
;      Variance due to signal (along INT VARIANCE) : lam_2 - lam_3
;
;      Maximum Angular Change (along MIN VARIANCE) : th_min = ATAN(lam_3/(lam_2 - lam_3))
;      Maximum Angular Change (along MAX VARIANCE) : th_max = ATAN(lam_3/(lam_1 - lam_2))
;
;  -The direction of maximum variance in the plane of maximum variance is determined
;    by the size of the difference between the two variances in this plane compared
;    to noise.
;
;  -EXAMPLES/ARGUMENTS
;    IF lam_2 = lam_3   => th_min is NOT DEFINED AND th_max is NOT DEFINED
;    IF lam_2 = 2*lam_3 => th_min = !PI/4
;    IF lam_2 = 2*lam_3 => th_min = !PI/30
;
;    IF lam_1 = lam_2 >> lam_3 => Minimum Variance Direction is still well defined!
;
;
;*******************************************************************************
;  Mazelle et. al. [2003] :
;        Same Min. Var. variable definitions
;
;       th_min = SQRT((lam_3*lam_2)/(N-1)/(lam_2 - lam_3)^2)
;        {where : N = # of vectors measured, or # of data samples}
;*******************************************************************************
;==-----------------------------------------------------------------------------
;
;  CALLS:  
;               rbsp_min_var.pro
;
;  INPUT:
;               FIELD  :  some [n,3] or [3,n] array of vectors
;
;  EXAMPLES:
;
;  KEYWORDS:  
;               RANGE      :  2-element array defining the start and end point elements
;                               to use for calculating the min. var.
;               NOMSSG     :  If set, TPLOT will NOT print out the index and TPLOT handle
;                               of the variables being plotted
;               BKG_FIELD  :  [3]-Element vector for the background field to dot with
;                               MV-Vector produced in program
;                               [Default = DC(smoothed) value of input FIELD]
;
;   CHANGED:  1)  Changed calculation for angle of prop. w/ respect to B-field
;                   to the method defined directly above     [09/29/2008   v1.0.2]
;             2)  Corrected theta_{kB} calculation           [10/05/2008   v1.0.3]
;             3)  Changed theta_{kB} calculation, added calculation of minimum variance
;                   eigenvector error, and changed return structure 
;                                                            [01/20/2009   v1.1.0]
;             4)  Fixed theta_kB calc. (forgot to normalize B-field) 
;                                                            [01/22/2009   v1.1.1]
;             5)  Added keywords:  NOMSSG and BKG_FIELD      [12/04/2009   v1.2.0]
;             4)  Fixed a typo in definition of GN variable  [12/08/2009   v1.2.1]
;
;   CREATED:  06/29/2008
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  12/08/2009   v1.2.1
;    MODIFIED BY: Lynn B. Wilson III
;				  Aaron Breneman - changed name to rbsp_min_var_rot.pro. This version
;									is unchanged from original aside from name change
;
;*****************************************************************************************
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2016-09-02 10:42:46 -0700 (Fri, 02 Sep 2016) $
;   $LastChangedRevision: 21790 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/rbsp_min_var_rot.pro $
;-

FUNCTION rbsp_min_var_rot,field,RANGE=range,NOMSSG=nom,BKG_FIELD=bkg_field

;-----------------------------------------------------------------------------------------
; => Define dummy variables
;-----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
tags           = ['FIELD','MV_FIELD','THETA_Kb','DTHETA','EIGENVALUES','DEIG_VALS',$
                  'EIGENVECTORS','DMIN_VEC']
dumf           = REPLICATE(f,10L,3L)
dumth          = f
dumeig         = REPLICATE(f,3L)
dumrot         = REPLICATE(f,3L,3L)
dum            = CREATE_STRUCT(tags,dumf,dumf,dumth,dumth,dumeig,dumeig,dumrot,dumeig)
;-----------------------------------------------------------------------------------------
; -Make sure data is an [n,3]-element array
;-----------------------------------------------------------------------------------------
d1    = REFORM(field)           ; -Prevent any [1,n] or [n,1] array from going on
mdime = SIZE(d1,/DIMENSIONS)     ; -# of elements in each dimension of data
ndime = SIZE(mdime,/N_ELEMENTS) ; - determine if 2D array or 1D array
gs1   = WHERE(mdime EQ 3L,g1,COMPLEMENT=bn1)
CASE gs1[0] OF
  0L   : BEGIN
    IF (ndime[0] GT 1L) THEN BEGIN
      d  = TRANSPOSE(d1)
      gn = mdime[1]
    ENDIF ELSE BEGIN
      d  = REFORM(d1)
      gn = mdime[0]
    ENDELSE
  END
  1L   : BEGIN
    d  = REFORM(d1)
    gn = mdime[0]
  END
  ELSE : BEGIN
    MESSAGE,'Incorrect input format: V1 (Must be [N,3] or [3,N] element array)',/INFORMATIONAL,/CONTINUE
    RETURN,dum
  END
ENDCASE
;-----------------------------------------------------------------------------------------
; -Determine data range
;-----------------------------------------------------------------------------------------
IF KEYWORD_SET(range) THEN BEGIN
  myn = range[1] - range[0]  ; -number of elements used for min. var. calc.
  IF (myn LE gn AND range[0] GE 0 AND range[1] LE gn) THEN BEGIN
    s = range[0]
    e = range[1]
  ENDIF ELSE BEGIN
    print,'Too many elements demanded in keyword: RANGE (mmvr)'
    s   = 0
    e   = gn - 1L
    myn = gn
  ENDELSE
ENDIF ELSE BEGIN
  s   = 0
  e   = gn - 1L
  myn = gn
ENDELSE
;-----------------------------------------------------------------------------------------
; -Find the minimum variance rotation matrix
;-----------------------------------------------------------------------------------------

tmpp = size(d)
if tmpp[0] ne 1 then rotmat = rbsp_min_var(d[s:e,0],d[s:e,1],d[s:e,2],EIG_VALS=myeiga)

lb_a1 = myeiga[2]         ; -Max Variance eigenvalue for STA
lb_a2 = myeiga[1]
lb_a3 = myeiga[0]         ; -Minimum Variance eigenvalue for STA

lams  = [lb_a1,lb_a2,lb_a3]

dlb_a1 = 0d0         ; -uncertainty in lb_a1
dlb_a2 = 0d0         ; -uncertainty in lb_a2
dlb_a3 = 0d0         ; -uncertainty in lb_a3
dphi   = DBLARR(3,3) ; -matrix of angles (rad) between relative eigenvectors
dlb_a1 = SQRT(2d0*lb_a3*(2d0*lb_a1 - lb_a3)/(myn-1))
dlb_a2 = SQRT(2d0*lb_a3*(2d0*lb_a2 - lb_a3)/(myn-1))
dlb_a3 = SQRT(2d0*lb_a3*(2d0*lb_a3 - lb_a3)/(myn-1))

dlams  = [dlb_a1,dlb_a2,dlb_a3]

FOR i=0L, 2L DO BEGIN
  FOR j=0L, 2L DO BEGIN
    dphi[i,j] = SQRT(lams[2]*(lams[i]+lams[j]-lams[2])/((myn-1L)*(lams[i]-lams[j])^2 ))
  ENDFOR
ENDFOR
;-----------------------------------------------------------------------------------------
; -Determine the uncertainty in the minimum variance eigenvector
;-----------------------------------------------------------------------------------------
dmin_eig = 0d0  ; -Uncertainty in the minimum variance eigenvector
factor1  = 0d0
factor2  = 0d0
factor3  = 0d0
factor1  = ((2d0*lb_a3^2)/(myn - 1L))^(1d0/4d0)
factor2  = 1d0/ SQRT(lb_a1 - lb_a3)
factor3  = 1d0/ SQRT(lb_a2 - lb_a3)

dmin_eig = factor1*(rotmat[*,2]*factor2 + rotmat[*,1]*factor3)
;-----------------------------------------------------------------------------------------
; -Rotate data
;-----------------------------------------------------------------------------------------
mvmfi = d # rotmat                 ; DBLARR(npoints,3)
bxmv  = mvmfi[*,0]                 ; rotated X B-field
bymv  = mvmfi[*,1]                 ; rotated Y B-field
bzmv  = mvmfi[*,2]                 ; rotated Z B-field
;-----------------------------------------------------------------------------------------
; -Calc. \theta_{kB} angle of MV B-field from original GSE
;-----------------------------------------------------------------------------------------
khat    = REFORM(rotmat[*,0])
; => Renormalize k-vector just in case
khat    = khat/(SQRT(TOTAL(khat^2,/NAN)))[0]

IF KEYWORD_SET(bkg_field) THEN BEGIN
  dcmag   = REFORM(bkg_field)
  avmag   = SQRT(TOTAL(dcmag^2,/NAN))
  dcmag   = dcmag/avmag[0]
ENDIF ELSE BEGIN
  avbx    = MEAN(d[s:e,0],/NAN,/DOUBLE)
  avby    = MEAN(d[s:e,1],/NAN,/DOUBLE)
  avbz    = MEAN(d[s:e,2],/NAN,/DOUBLE)
  avmag   = SQRT(avbx^2 + avby^2 + avbz^2)
  dcmag   = [avbx[0]/avmag[0],avby[0]/avmag[0],avbz[0]/avmag[0]]
ENDELSE
bdots   = (khat[0]*dcmag[0] + khat[1]*dcmag[1] + khat[2]*dcmag[2])
; => Calculate the angle between the two vectors
theta_kb_0 = ACOS(bdots)*18d1/!DPI
theta_kbs  = 18d1 - theta_kb_0         ; -Supplemental angle
; => Calculate the uncertainty in the angle between the two vectors
dthetakb   = SQRT((lb_a3*lb_a2)/(myn - 1L)/(lb_a2 - lb_a3)^2)*18d1/!DPI 

theta_kb   = theta_kb_0 < theta_kbs     ; -Only print the value < 90 degrees
;-----------------------------------------------------------------------------------------
; -Print relevant values
;-----------------------------------------------------------------------------------------
IF KEYWORD_SET(nom) THEN GOTO,JUMP_SKIP
mineigf = '("<",f8.5,",",f8.5,",",f8.5,"> +/- <",f8.5,",",f8.5,",",f8.5,">")'
PRINT, 'The eigenvalues (usual routine) are:'
PRINT,STRTRIM(lb_a1,2)+' +/- '+STRTRIM(dlb_a1,2)
PRINT,STRTRIM(lb_a2,2)+' +/- '+STRTRIM(dlb_a2,2)
PRINT,STRTRIM(lb_a3,2)+' +/- '+STRTRIM(dlb_a3,2)
PRINT,''
PRINT,'The angle between B[GSE] and \theta_{kB} is :'
PRINT,theta_kb,' degrees with a standard deviation of:'
PRINT,dthetakb,' degrees and standard deviation of the mean of:'
PRINT,''
PRINT, 'The eigenvalues ratios are:'
PRINT,myeiga[1]/myeiga[0],myeiga[2]/myeiga[1]
PRINT, 'The Minimum Variance eigenvector is:'
PRINT, rotmat[*,0],dmin_eig,format=mineigf
PRINT,''
;=========================================================================================
JUMP_SKIP:
;=========================================================================================
mymin = CREATE_STRUCT('FIELD',field,'MV_FIELD',mvmfi,'THETA_Kb',theta_kb,     $
                      'DTHETA',dthetakb,'EIGENVALUES',lams,'DEIG_VALS',dlams, $
                      'EIGENVECTORS',rotmat,'DMIN_VEC',dmin_eig,'K_HAT',khat)

RETURN,mymin
END
