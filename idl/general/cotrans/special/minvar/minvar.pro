;+
; Procedure: minvar.pro
; This program computes the principal variance directions and variances of a
; vector quantity (can be 2D or 3D) as well as the associated
; eigenvalues.  This routine is a simple version
; designed to be used by a tplot wrapper with the contrans_var library
; Works with trired and triql (IDL's version of Num. Recipies w/ permission)
;
; Input: Vxyz, an (ndim,npoints) array of data(ie 3xN)
; Output: eigenVijk, an (ndim,ndim) array containing the principal axes vectors
;         Maximum variance direction eigenvector, Vi=eigenVijk(*,0)
;         Intermediate variance direction, Vj=eigenVijk(*,1) (descending order)
;
;         Vrot: if set to a name, that name becomes an array of (ndim,npoints)
;         containing the rotated data in the new coordinate system, ijk.
;         Vi(maximum direction)=Vrot(0,*)
;         Vj(intermediate direction)=Vrot(1,*)
;         Vk(minimum variance direction)=Vrot(2,*)
;
;         lambdas2=if set to a name returns the eigenvalues of the
;         computation
;
;
;Written by: Vassilis Angelopoulos
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-03-15 12:11:20 -0700 (Sat, 15 Mar 2025) $
; $LastChangedRevision: 33186 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/minvar/minvar.pro $
;
;-

pro minvar,Vxyz,eigenVijk,Vrot=Vrot,lambdas2=lambdas2

vec = double(Vxyz)
npnts = n_elements(Vxyz[0,*])
vecavg = vec[*,0] & vecavg[*] = !VALUES.F_NAN
mvamat = make_array(3,3,/double,value=!VALUES.F_NAN)

;;  compute component averages
for i=0L, 2L do vecavg[i] = total(/nan, Vxyz[i,*])/npnts[0]

;;  build matrix
for i=0L, 2L do begin
   mvamat[i,0] = total(/nan, vec[i,*]*vec[0,*])/npnts[0] - vecavg[i]*vecavg[0]
   mvamat[i,1] = total(/nan, vec[i,*]*vec[1,*])/npnts[0] - vecavg[i]*vecavg[1]
   mvamat[i,2] = total(/nan, vec[i,*]*vec[2,*])/npnts[0] - vecavg[i]*vecavg[2]
endfor

;;  TRIRED Input
;;    eigenVijk   = [3,3]-Element real symmetric matrix
;;  TRIRED Output Results
;;    diagonal    = Returned [3]-Element vector of the diagonal elements of eigenVijk
;;    offdiagonal = Returned [3]-Element vector of the off-diagonal " " 
eigenVijk=mvamat
trired,eigenVijk,diagonal,offdiagonal,/double
;;  TRIQL Output Results
;;    diagonal    = Eigenvalues of the input matrix eigenVijk
;;    offdiagonal = Destroyed by TRIQL.PRO
;;    eigenVijk   = Three eigenvectors of input matrix eigenVijk
triql,diagonal,offdiagonal,eigenVijk,/double

;;  Force eigenvalues to be positive
diagonal  = abs(diagonal)

index     = reverse(sort(diagonal)) ; descending order: min var last
diagonal  = diagonal[index]
eigenVijk = eigenVijk[*,index]

; Rotate intermediate var direction if system is not Right Handed
YcrosZdotX = eigenVijk[0,0]*(eigenVijk[1,1]*eigenVijk[2,2] - eigenVijk[2,1]*eigenVijk[1,2])
if (YcrosZdotX lt 0.) then eigenVijk[*,1] = -eigenVijk[*,1]

; Ensure minvar direction is along +Z (for FAC system)
if (eigenVijk[2,2] lt 0) then begin
  eigenVijk[*,2] = -eigenVijk[*,2]
  eigenVijk[*,1] = -eigenVijk[*,1]
endif

; Ensure minvar-Z and intvar-Z are both positive, to ensure matching results between IDL and Python
if (eigenVijk[2,1] lt 0) then begin
  eigenVijk[*,1] = -eigenVijk[*,1]
  eigenVijk[*,0] = -eigenVijk[*,0]
endif


;;  create dummy variable for rotated vectors (output keyword variable)
Vrot = vec & Vrot[*,*] = !VALUES.F_NAN
;;  Rotate data into minvar coords
Vrot(0,*) = eigenVijk[0,0]*vec[0,*] + eigenVijk[1,0]*vec[1,*] + eigenVijk[2,0]*vec[2,*]
Vrot(1,*) = eigenVijk[0,1]*vec[0,*] + eigenVijk[1,1]*vec[1,*] + eigenVijk[2,1]*vec[2,*]
Vrot(2,*) = eigenVijk[0,2]*vec[0,*] + eigenVijk[1,2]*vec[1,*] + eigenVijk[2,2]*vec[2,*]

;;  Define output keyword variable
lambdas2=diagonal

;;  Return to user.c
return
end
