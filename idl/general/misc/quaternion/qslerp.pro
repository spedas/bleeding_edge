;+
;Function: qslerp,q,x1,x2
;
;Purpose: uses spherical linear interpolation to interpolate
;quaternions between elements of q
;
;Inputs: q: an Nx4 element array, representing a list of quaternions
;with N > 1, all quaternions must be unit quaternions(ie length/norm = 1)
;        x1: The input abscissa values of the quaternions,an array of
;        length N, abscissa values must also be monotonic
;
;        x2: The output abscissa values for the quaternions, can have
;        as many elements as wanted but must fall on the interval
;        [x[0],x[N-1]], an M element array, abscissa values must also
;        be monotonic
;
;        geometric(optional): this keyword allows you to specify that
;        it use the geometric formula for the slerp. The default
;        formula is probably faster and more numerically stable, the 
;        geometric option is just available for testing
;        Testing of the geometric method indicates that the norm of
;        the interpolated quaternions strays easily from unit length,
;        when it renormalizes results may be destabilized
;
;        eq_tolerance: Set to specify the tolerance used when determining
;        whether two numbers are equal (default: 1e-12). This tolerance
;        will be used in checking equivalence of:
;                -quaternion lengths
;                -input vs. output abscissae
;                -quaternion direction (inner product)  
;       
;
;Returns: an Mx4 element array of interpolated quaternions or -1L on
;failure
;
;
;;Notes: 
;Represention has q[0] = scalar component
;                 q[1] = vector x
;                 q[2] = vector y
;                 q[3] = vector z
;
;The vector component of the quaternion can also be thought of as
;an eigenvalue of the rotation the quaterion performs
;
;The scalar component can be thought of as the amount of rotation that
;the quaternion performs
;
;While the code may seem a little esoteric, it is vectorized and
;provides the most accurate results it can get
;
;Written by: Patrick Cruce(pcruce@igpp.ucla.edu)
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2016-04-05 12:33:56 -0700 (Tue, 05 Apr 2016) $
; $LastChangedRevision: 20724 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qslerp.pro $
;-

function qslerp,q,x1, x2,geometric=geometric, eq_tolerance=eq_tolerance_in

compile_opt idl2

EQ_TOLERANCE = 1e-12 ;how close two numbers have to be to be considered equal
                     ;error in calculations can be assumed
                     ;to be at least as high as this number

if n_elements(eq_tolerance_in) eq 1 && is_num(eq_tolerance_in,/floating) then begin
  eq_tolerance = eq_tolerance_in
endif

;this is to avoid mutating the input variables
qi = q
x2i = x2
x1i = x1

;validate the inputs

;check that quaternions are consistent with generic quaternion invariants
qi = qvalidate(qi,'qi','qslerp')

if(size(qi,/n_dim) eq 0 && qi[0] eq -1) then return,qi

;check that input quaternions are unit length
qn = qnorm(qi)

if(size(qn,/n_dim) eq 0 && qn[0] eq -1) then begin

  dprint, 'Unable to calculate norm of input quaternions'

  return, -1

endif

idx = where(abs(qn - 1.0D) gt EQ_TOLERANCE)

if(idx[0] ne -1) then begin

  dprint, 'At least one input quaternion is not unit length'

  return, -1

endif

;guarantee correct number of input quaternions
qdims = size(qi, /dimensions)

if(qdims[0] ne n_elements(x1i)) then begin

  dprint, 'Number of input abscissa values does not match the number of input quaternions'

  return, -1

endif

;check that input abscissa values are monotonic

if(n_elements(x1i) gt 1) then begin 
   idx = where((x1i[1:n_elements(x1i)-1]-x1i[0:n_elements(x1i)-2]) lt 0)

   if(idx[0] ne -1) then begin

      dprint, 'input abscissa values not monotonic'

      return, -1

   endif
endif

if(n_elements(x2i) gt 1) then begin
;check that output abscissa values are strictly monotonic
   idx = where((x2i[1:n_elements(x2i)-1]-x2i[0:n_elements(x2i)-2]) le 0)

   if(idx[0] ne -1) then begin

      dprint, 'output abscissa values not monotonic'

      return, -1

   endif
endif
;construct the output array

q_out = make_array(n_elements(x2i), 4, /double)

;if output abscissa values are outside of the range of input abscissa
;values constant extrapolation is used

idx = where(x2i lt x1i[0])

if(idx[0] ne -1) then q_out[idx,*] = rebin(qi[0,*],n_elements(idx),4)

idx = where(x2i gt x1i[n_elements(x1i)-1])

if(idx[0] ne -1) then q_out[idx,*] = rebin(qi[n_elements(x1i)-1,*],n_elements(idx),4)

out_idx = where(x2i ge x1i[0] and x2i le x1i[n_elements(x1i)-1])

if(out_idx[0] eq -1) then return,reform(q_out)

x2i = x2i[out_idx]

;construct arguments to the slerp function, this includes the source
;quaternion list, the target quaternions list, and the proportion of
;interpolation list for each quaternion pair.  They should all have
;the same number of elements as the output abscissa value list

t_temp = interpol(dindgen(qdims[0]), x1i, x2i)

t_list = t_temp mod 1.0D

q_idx = long(floor(t_temp))

;if the last abscissa values are identical,the indexing scheme to
;generate the q_list could generate an overflow, the two conditionals
;below prevent this

idx = where(abs(t_list) le EQ_TOLERANCE) ;where t_list =~ 0.0

;put everything that requires no interpolation directly into the output
if(idx[0] ne -1) then begin

  q_out[out_idx[idx],*] = qi[q_idx[idx],*] 

endif

slerp_idx = where(abs(t_list) gt EQ_TOLERANCE) ;where t_list !=~ 0.0

;if there is nothing left, then we're done
if(slerp_idx[0] eq -1) then return, reform(q_out)

q_idx = q_idx[slerp_idx]
out_idx = out_idx[slerp_idx]
t_list = t_list[slerp_idx]

q1_list = qi[q_idx,*]

q2_list = qi[q_idx+1,*]

;calculate the dot product which is needed to to flip the
;appropriate quaternions to guarantee interpolation is done along the
;shortest path 
dotp = qdotp(q1_list, q2_list)

if(size(dotp, /n_dim) eq 0 && dotp eq -1) then return, -1

;the following code flips quaternions in q2_list to ensure the
;shortest path is followed 
idx = where(dotp lt 0.0D)

if(idx[0] ne -1) then q2_list[idx,*] = -q2_list[idx,*]

;interpolation cannot be performed on colinear quaternions
;it is assumed that colinear quaternions will be returned unchanged
;since dotp(q1,q2) = cos(angle between q1,q2) if dotp = 1.0 the
;quaternions are colinear
idx = where(abs(dotp - 1.0D) le EQ_TOLERANCE) ;where dotp = 1.0

;store colinear quaternions into output array
if(idx[0] ne -1) then q_out[out_idx[idx],*] = q1_list[idx,*]

;copy non-colinear quaternions for processing
idx = where(abs(dotp - 1.0D) gt EQ_TOLERANCE)

if(idx[0] eq -1) then return, reform(q_out)  ;if no non-colinear quaternions are left, we are done

dotp = dotp[idx]
t_list = t_list[idx]
q1_list = q1_list[idx,*]
q2_list = q2_list[idx,*]
out_idx = out_idx[idx]

;now the actual processing begins

;testing both methods to verify results
if keyword_set(geometric) then begin 

theta = acos(dotp)

sin_theta = sin(theta)

theta_t = theta*t_list

co1 = sin(theta - theta_t)/sin_theta
co2 = sin(theta_t)/sin_theta

q_out[out_idx,0] = co1*q1_list[*,0]+co2*q2_list[*,0]
q_out[out_idx,1] = co1*q1_list[*,1]+co2*q2_list[*,1]
q_out[out_idx,2] = co1*q1_list[*,2]+co2*q2_list[*,2]
q_out[out_idx,3] = co1*q1_list[*,3]+co2*q2_list[*,3]

endif else begin

;slerp will be performed by calculating: 
;((q2*(q1^-1))^t)*q1
;since the quaternions are unit q1^-1 = conjugate(q1)
;exponentiation can be calculated by transforming to 
;polar form cos(theta*t)+v*sin(theta*t)
;theta = acos(q[0])
;NOTE: this potentially more numerically stable implementation needs
;to be verified by comparison to the geometric slerp

q1_conj = qconj(q1_list)

q2_q1_prod = qdecompose(qmult(q2_list, q1_conj))

if(size(q2_q1_prod, /n_dim) eq 0 && q2_q1_prod[0] eq -1) then return, -1

;sometimes a dimension disappears.
if ndimen(q2_q1_prod) eq 1 && n_elements(q2_q1_prod) eq 4 then begin
  q2_q1_prod = reform(q2_q1_prod,1,4)
endif

theta_scale = q2_q1_prod[*,0]*t_list

q_total = qmult(qcompose(q2_q1_prod[*,1:3],theta_scale), q1_list)

if(size(q_total, /n_dim) eq 0 && q_total[0] eq -1) then return, -1

q_out[out_idx,*] = q_total

endelse

return, qnormalize(q_out)

end
