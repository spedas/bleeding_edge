;+
;PROCEDURE:   mvn_swe_fovmap
;PURPOSE:
;  Calculates the SWEA FOV in the form of an array of unit vectors pointing to each
;  solid angle resolution element.  This is stored in a common block for later use
;  by mvn_swe_padmap.
;
;USAGE:
;  mvn_swe_fovmap
;
;INPUTS:
;       none
;
;KEYWORDS:
;       RESET:         Initialize the common block, which contains the unit vectors
;                      pointing to each element of the FOV.
;
;       PATCH_SIZE:    Number of resolution elements, N, in azimuth and elevation for
;                      each of the 96 solid angle bins.  This oversamples each solid
;                      angle bin with an N x N grid.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-15 11:27:34 -0700 (Thu, 15 May 2025) $
; $LastChangedRevision: 33312 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_fovmap.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_swe_fovmap.pro
;-
pro mvn_swe_fovmap, patch_size=psz, reset=reset

  @mvn_swe_com

; Update the common block if requested or necessary.

  if (keyword_set(reset) || (size(patch_size,/type) eq 0)) then begin

    k = indgen(96)  ; 96 solid angle bins
    i = k mod 16    ; 16 anode bins
    j = k / 16      ;  6 deflector bins

;   nxn azimuth-elevation patch for each of the 96 solid angle bins

    ddtor = !dpi/180D
    ddtors = replicate(ddtor,64)

    n = (size(psz, /type) gt 0) ? long(psz) : 15L  ; patch size (odd integer)
    patch_size = n
    ones1d = replicate(1D,n)
    ones2d = replicate(1D,n*n)
    Saz3d = dblarr(n*n,96,64,3)
    Sel3d = Saz3d

    daz = double((lindgen(n*n) mod n) - (n-1)/2)/double(n-1) # double(swe_daz[i])
    Saz = reform(ones2d # double(swe_az[i]) + daz, n*n*96) # ddtors
    Saz3d[*,*,*,0] = reform(Saz,n*n,96,64)  ; nxn az-el patch, 96 solid angle angle bins, 64 energies
    for g=1,2 do Saz3d[*,*,*,g] = Saz3d[*,*,*,0]

    Sel = dblarr(n*n*96,64)
    patch = reform(ones1d # double(lindgen(n) - (n-1)/2)/double(n-1), n*n)
    for g=0,2 do begin
      for m=0,8 do begin
        del = patch # double(swe_del[j,m,g])
        Sel[*,m] = reform(ones2d # double(swe_el[j,m,g]) + del, n*n*96)
      endfor
      for m=9,63 do Sel[*,m] = Sel[*,8]  ; elevations are constant below ~2 keV.

      Sel = temporary(Sel)*ddtor
      Sel3d[*,*,*,g] = reform(Sel,n*n,96,64)  ; nxn az-el patch, 96 solid angle bins, 64 energies, 3 groups
    endfor

;   unit vector pointing to each element of the FOV (each component: n*n,96,64,3)

    Sx3d = cos(Saz3d)*cos(Sel3d)
    Sy3d = sin(Saz3d)*cos(Sel3d)
    Sz3d = sin(Sel3d)

  endif

end
