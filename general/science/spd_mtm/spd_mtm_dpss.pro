;+
; :Description:
;   Generate the Slepian sequences
;   (or discrete prolate spheroidal sequences, dpss)
;   following the tridiagonal formulation
;   by Percival and Walden (1993) p.386-387.
;
; :Params:
;   INPUTS:
;            N - number of data points
;           NW - time-halfbandwidth product
;         Ktpr - number of tapers to be used (max value is 2*NW - 1)
;   
;   OUTPUTS:
;     dpss.
;         .E     discrete prolate spheroidal sequences (dpss), eigenvectors
;         .V     dpss eigenvalues
;         .N     number of data points
;         .NW    time-halfbandwidth product 
;         .Ktpr  number of tapers to be used (max value is 2*NW - 1)
;
; :Author:
;     Simone Di Matteo, Ph.D.
;     8800 Greenbelt Rd
;     Greenbelt, MD 20771 USA
;     E-mail: simone.dimatteo@nasa.gov
;-
;*****************************************************************************;
;                                                                             ;
;   Copyright (c) 2020, by Simone Di Matteo                                   ;
;                                                                             ;
;   Licensed under the Apache License, Version 2.0 (the "License");           ;
;   you may not use this file except in compliance with the License.          ;
;   See the NOTICE file distributed with this work for additional             ;
;   information regarding copyright ownership.                                ;
;   You may obtain a copy of the License at                                   ;
;                                                                             ;
;       http://www.apache.org/licenses/LICENSE-2.0                            ;
;                                                                             ;
;   Unless required by applicable law or agreed to in writing, software       ;
;   distributed under the License is distributed on an "AS IS" BASIS,         ;
;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  ;
;   See the License for the specific language governing permissions and       ;
;   limitations under the License.                                            ;
;                                                                             ;
;*****************************************************************************;
;
function spd_mtm_dpss, N, NW, Ktpr
;
N = double(N)
W = double(NW)/N
;
; off diagonal elements
toff = dindgen(N-1,1) + 1.0d
offd = [toff*(N - toff)/2.0d]
;
; diagonal terms
tdiag = dindgen(N,1)
diag = ( ((N - 1.0d)/2.0d - tdiag)^2.0d ) * cos(2.0d*!dpi*W)
;
T = dblarr(N,N)
T[tdiag, tdiag] = diag
T[toff,toff-1] = offd
T[toff-1,toff] = offd
;
; eigenvectors of a tridiagonal matrix
; solution via the QL Algorithm, see pag.583-589 of 
; Press, Teukolsky, Vetterling, & Flannery (2007). 
; Numerical recipes in C: the art of scientific computing (3rd ed.).
; New York, NY, USA: Cambridge University Press.
thetak = LA_EIGENQL(T, /double, eigenvectors=eigvec, METHOD=0, $
  range=[N-Ktpr, N-1])
;
; sort eigenvectors
E = transpose(eigvec[*,-1:0:-1])
;
; eigenvector polarization
for i = 0, Ktpr - 1 do begin
  ;
  if i mod 2 then begin ; i is odd
    ;
    ; skew-symmetric tapers, start with a positive lobe
    pol = total((N - 1.0d - 2.0d*tdiag)*E[i,*])
    if pol le 0 then E[i,*] = -E[i,*]
    ;
  endif else begin ; i is even
    ;
    ; symmetric tapers, average is positive
    if total(E[i,*]) le 0 then E[i,*] = -E[i,*]
    ;
  endelse
endfor
;
; eigenvalue from eq. 378
; Percival & Walden (1993). Spectral analysis for physical applications.
; Cambridge, UK: Cambridge University Press.
A = dblarr(N,N)
for k = 0, N - 2 do begin
  ind = [1:N] + k*(N + 1.0d)
  ij = array_indices(A, ind)
  j = ij[0,*]
  i = ij[1,*]
  A[j,i] = sin(2.0d*!dpi*W*(j - i))/(!dpi*(j - i))
endfor
A[tdiag, tdiag] = 2.0d*W
;
V = diag_matrix(transpose(E) ## A ## E)
;
; make values suitible for spd_mtm
dpss = create_struct('E',E, 'V',V, 'N',N, 'NW',NW, 'K',Ktpr)
;
return, dpss
;
end