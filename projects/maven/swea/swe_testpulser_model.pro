;+
;PROCEDURE:   swe_testpulser_model
;PURPOSE:
;  Creates SWEA Test Pulser Model and generates test pulser signatures
;  in the three main data products (APID's A0, A2, A4).  The model is
;  an analytic approximation to the measured test pulser signal.
;
;USAGE:
;  swe_testpulser_model
;
;INPUTS:
;
;KEYWORDS:
;
;       GROUP:        Group parameter (g) that controls energy bin
;                     averaging for A0 and A2 products.  Does not
;                     affect A4.
;
;                     g = 0,1,2 corresponds to averaging 1, 2, or 4 
;                     adjacent energy channels.
;
;       PAM:          Pitch angle map structure specifying the anode and deflector
;                     bins comprising the PAD.  0 < andx < 15 ; 0 < dndx < 5.
;
;                       pam = {andx:intarr(16), dndx:intarr(16)}
;
;       RESULT:       Structure to hold A0, A2, and A4 test pulser
;                     models.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-04-07 20:05:19 -0700 (Mon, 07 Apr 2014) $
; $LastChangedRevision: 14775 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_testpulser_model.pro $
;
;CREATED BY:    David L. Mitchell  05-28-13
;FILE: swe_testpulser_model.pro
;VERSION:   1.0
;-
pro swe_testpulser_model, group=group, pam=pam, result=result

  if not keyword_set(group) then group = 0
  if not keyword_set(pam) then pam = {andx:indgen(16), dndx:replicate(3,16)}

; Test Pulser (M54HC4040D)
; FPGA generates 448 samples per 2-sec interval.  Samples are obtained over 1.95 sec, 
; followed by a 50-msec gap.

  dt = 1.95D/448D      ; 448 samples over 1.95 seconds
  t = dindgen(448)*dt  ; time relative to start of cycle

; Analytic approximation to measured test pulser data

  y = 20D*exp(-t/1.5D) + 30D*tan(t*!dpi/(1.956D*2D))

; Package into an array organized by deflector, energy, and anode bins

  tpmod = fltarr(448,16)                     ; 448 steps X 16 anode bins
  tpmod[*,0] = y                             ; anode 0
  for i=1,7 do tpmod[*,i] = tpmod[*,i-1]/2.  ; anodes 1-7 scale by factors of 2
  tpmod[*,8:15] = tpmod[*,0:7]               ; anodes 8-15 duplicate anodes 0-7

  tpmod = reform(tpmod,7,64,16)  ; model TP vs. deflector bin, energy bin, anode bin

; Reverse deflector indices 1-6 on odd numbered energy steps to correspond with 
; deflector sweep pattern.  (Deflector index 0 always occurs at the beginning of
; each energy step, and is discarded.)

  for i=1,63,2 do for j=0,15 do tpmod[1:6,i,j] = reverse(tpmod[1:6,i,j])

; The three data products are built up by summing and/or sampling tpmod.

; 3D data product (A0)
;
; The 3D data product has 80 (4*16 + 2*8) solid angle bins for each of 64 energy
; bins.
;
;     Deflector Bin	     Anode Bins
;    -----------------------------------------------------------------
;           0		no data while voltages stabilize
;           1		 8 bins (anodes averaged in groups of 2)
;           2		16 bins
;           3		16 bins
;           4		16 bins
;           5		16 bins
;           6		 8 bins (anodes averaged in groups of 2)
;    -----------------------------------------------------------------

; According to the FSW CTM, deflector bins 1 and 6 are stored first, followed
; by deflector bins 2-5

  a0 = fltarr(80,64)  ; 80A x 64E

  for k=0,63 do begin

    for i=0,7 do begin
      a0[i,  k] = tpmod[1,k,2*i] + tpmod[1,k,2*i+1]
      a0[i+8,k] = tpmod[6,k,2*i] + tpmod[6,k,2*i+1]
    endfor
  
    for j=1,4 do a0[(j*16):(j*16+15),k] = tpmod[j+1,k,*]

  endfor

; Now average over energy according to the group parameter

  if (group gt 0) then begin
    a0avg = fltarr(80,32)
    for i=0,31 do a0avg[*,i] = a0[*,2*i] + a0[*,2*i+1]
    a0 = a0avg

    if (group gt 1) then begin
      a0avg = fltarr(80,16)
      for i=0,15 do a0avg[*,i] = a0[*,2*i] + a0[*,2*i+1]
      a0 = a0avg
    endif
  endif

; PAD data product (A2)
;
; The PAD data product has 16 pitch angles for each of 64 energy bins.
;
; idef shall be a 16-element array, where each element gives the optimal
; deflector bin (1-6) for each anode bin (0-15).

  idef = pam.dndx + 1  ; indexing definition is different in mvn_swe_padmap

  a2 = fltarr(16,64)
  
  for i=0,15 do a2[i,*] = tpmod[idef[i],*,i]
  
; Shift array to correspond with definition in A2: PADs start with
; pitch angle of zero.

  a2 = shift(a2,-pam.andx[0],0)

; Now average over energy according to the group parameter

  if (group gt 0) then begin
    a2avg = fltarr(16,32)
    for i=0,31 do a2avg[*,i] = a2[*,2*i] + a2[*,2*i+1]
    a2 = a2avg

    if (group gt 1) then begin
      a2avg = fltarr(16,16)
      for i=0,15 do a2avg[*,i] = a2[*,2*i] + a2[*,2*i+1]
      a2 = a2avg
    endif
  endif

; Energy spectrum data product (A4)
;
; The ENGY data product has 64 energy bins (never averaged).
;
  a4 = total(tpmod[1:6,*,*],1)  ; sum over deflections
  a4 = total(a4,2)              ; sum over anodes

; Package the result

  result = {a0:a0, a2:a2, a4:a4}

  return

end
