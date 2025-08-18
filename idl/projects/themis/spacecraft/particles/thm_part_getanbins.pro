;+
;PROCEDURE: thm_part_getanbins
;PURPOSE:
;   Create 3 arrays used by THM_PART_MOMENTS2 to turn on/off energy/angle bins
;
;	Generates a [number of energy channels]x[number of angle bins] array
;       (en_an_bins), an array [number of angle bins]x1 array (an_bins), and an
;       array [number of energy channels]x1 array (en_bins) of 1's and 0's used
;       by THM_PART_MOMENTS2 to turn on/off energy and angle bins based on the
;       theta/phi/pitch angles, energy ranges, and data types requested by the
;       user in THM_PART_GETSPEC. THM_PART_MOMENTS2 will also call this function
;       if there's a mode change since modes have different angle maps.
;       NOTE: pitch angles not yet implemented
;
;KEYWORDS:
;  phi   = Angle range of interest (2 element array) in degrees relative to
;          probe-sun direction in the probe's spin plane. Specify angles in
;          ascending order (e.g. [270, 450]) to specify the 'daylight'
;          hemisphere in DSL coordinates. Default is all (e.g. [0, 360]).
;  theta = Angle range of interest (2 element array) in degrees relative to
;          spin plane, e.g. [-90, 0] or [-45, 45] in the probe's spin plane.
;          Specify in acending order. Default is all (e.g. [-90, 90]).
;  pitch = NOT IMPLEMENTED YET Angle range of interest (2 element array) in degrees relative to
;          the magnetic field. Default is all (e.g. [0, 180]).
;  erange= Energy range (in eV) of interest (2 element array). Default is all.
;  data_type = The type of data to be loaded. Energy/angle bins are now derived
;              from dat structure in THM_PART_MOMENTS2.
;
;SEE ALSO:
;	THM_PART_MOMENTS2, THM_PART_GETSPEC, THM_CRIB_PART_GETSPEC
;
;CREATED BY:	Bryan Kerr
;HISTORY:
; v0.1	11/21/07: Initial release.
; v0.2	11/28/07: Added ability to handle eESA and *SST data types.
; v0.3  12/04/07: Improved ability to better handle phi input from
;                 THM_PART_GETSPEC.
; v0.4  12/13/07: Added check and warning if no energy bins fall within ERANGE.
; v0.6  01/09/08: Added reduced mode (peir) capability.
; v0.6.01 01/09/08: Corrected peir phi bin map
; v0.6.3 01/15/08: All reduced modes implemented. Generalized to arbitrary angle
;                  maps and energy ranges.
; v0.7  01/31/08: Added en_bins reference
; v0.8.12 02/26/08: Fixed bug that fails to properly handle cases when no phi
;                   bins occur within PHI range.
; v1.0 05/09/08: Ready for Release v4.0.
;
;VERSION: 1.0
;  $LastChangedBy: aaflores $
;  $LastChangedDate: 2012-02-13 09:59:58 -0800 (Mon, 13 Feb 2012) $
;  $LastChangedRevision: 9719 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_getanbins.pro $
;-

pro thm_part_getanbins, theta=theta, phi=phi, erange=erange, $
                        data_type=data_type, en_an_bins=en_an_bins, $
                        an_bins=an_bins, en_bins=en_bins, nrg=nrg, $
                        avgphi=avgphi, avgtheta=avgtheta

erange1 = min(erange)
erange2 = max(erange)
theta1 = min(theta)
theta2 = max(theta)
phi1 = phi[0]
phi2 = phi[1]
aphi = avgphi
nphi = n_elements(aphi)
atheta = avgtheta
ntheta = n_elements(atheta)
ebnd = nrg
nnrg = n_elements(nrg)


; convert any phi's gt 360
gt360_ind = where(aphi gt 360,gt360_count)
if gt360_count ne 0 then aphi[gt360_ind] = aphi[gt360_ind] - 360


if ~ ((phi1 le 360 && phi1 ge 0) && (phi2 le 360 && phi2 ge 0)) then begin
   if phi2 lt (phi2 - phi1) then begin
      phi1_1 = 360 + phi1
      phi1_2 = 360
      phi2_1 = 0
      phi2_2 = phi2
   endif
   if phi2 gt (phi2 - phi1) then begin
      phi1_1 = phi1
      phi1_2 = 360
      phi2_1 = 0
      phi2_2 = phi2 - 360
   endif
endif else begin
   phi1_1 = phi1
   phi1_2 = phi2
   phi2_1 = phi1
   phi2_2 = phi2
endelse

thetabin = intarr(ntheta)
thetabin_ind = where((theta1 le atheta AND theta2 ge atheta),n)
if n gt 0 then thetabin[thetabin_ind] = 1

phibin = intarr(nphi)
phibin_ind = where((aphi ge phi1_1 AND aphi le phi1_2),n)
if n gt 0 then phibin[phibin_ind] = 1
if ~ (phi1_1 eq phi2_1 && phi1_2 eq phi2_2) then begin
    phibin_ind = where((aphi ge phi2_1 AND aphi le phi2_2),n)
    if n gt 0 then phibin[phibin_ind] = 1
endif

anglemap = thetabin * phibin
en_an_binnumsi = where(anglemap ne 0,n)
en_an_bins = intarr(nnrg,nphi)
if n gt 0 then begin
   en_an_bins[*,en_an_binnumsi] = 1 ; turn on angle bins
endif else begin
   en_an_bins[*] = 0 ; no angle bins in phi range
   ;unnecessary message at this point
;   dprint, dlevel=2, 'WARNING: No ',data_type,' angles within specified PHI range.'
endelse

an_bins = anglemap ;used to determine which angles are requested

ebin=intarr(n_elements(ebnd))
ebin_ind = where((ebnd ge erange1 AND ebnd le erange2),n) ; find nrg bins w/in erange
if n gt 0 then begin
   ebin[ebin_ind] = 1 ; turn on nrg bins w/in erange
   en_bins = ebin
endif else begin
   en_bins = ebin
   ;unnecessary message at this point
;   dprint, dlevel=2, 'WARNING: No ',data_type,' energies within specified ERANGE.'
endelse
en_an_bins = en_an_bins * fix(ebin # (intarr(nphi)+1))

end