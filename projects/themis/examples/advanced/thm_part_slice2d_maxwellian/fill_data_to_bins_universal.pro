;+
;Procedure:
;  fill_data_to_bins_universal
;
;Purpose:
; 
; Fill the satellite data with the user input
;
;Notes:
;  
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2018-04-27 18:30:20 -0700 (Fri, 27 Apr 2018) $
;$LastChangedRevision: 25133 $
;$URL: 
;-

pro fill_data_to_bins_universal,data_energy,data_theta,data_phi,thm_data,new_data=new_data

energy=thm_data[0].energy[*,0]
denergy=thm_data[0].denergy[*,0]/2

phi=thm_data[0].phi[0,*]
; Convert phi range into the [0, 360] 
phi = phi mod 360       ; confine phi within [-360, 360] (e.g. remove additional rotations)
phi += 360              ; make phi positive, phi in [0, 720]
phi = phi mod 360       ; confine phi within [0, 360]  
dphi=thm_data[0].dphi[0,*]/2 

; Convert data_phi range into the [0, 360] ; same as above
data_phi = data_phi mod 360 
data_phi += 360

;phi = phi mod 360          ; bug??
data_phi = data_phi mod 360 ; bug?? 

; Theta is always in the range [-90, 90];
theta=thm_data[0].theta[0,*]
dtheta=thm_data[0].dtheta[0,*]/2

new_data=thm_data
new_data.data[*]=0.0
new_data.units_name='counts'

num_rec   = n_elements(data_energy) ; number of test data
num_angle = n_elements(theta) ; number of angles in data

for i=0, num_rec-1 do begin  
  ; get energy index
  idxe=where((data_energy[i] gt (energy - denergy)) and (data_energy[i] lt (energy + denergy)))
  if idxe[0] eq -1 then begin ; if nothing found, maybe it is an integral channel?
     tmp=min(denergy, idxb) ; find integral channel. We assume that there is only one with 0 energy width
     if idxb[0] ne -1 and data_energy[i] gt energy[idxb[0]] then idxe = idxb   
  endif
  energy_idx = idxe[0] 
  
  ; get the angle index
  target_theta = data_theta[i]
  target_phi   = data_phi[i] - phi + dphi; rotate data angle to the phi frame, 
                                         ; and then rotate to the right phi window                                    
  target_phi = (target_phi+360) mod 360 ; make sure that angle is positive and in the range [0, 360]
  
  ; now we just need to make sure that target_phi is in the correct bin width                                        
  idx = where( ((target_theta gt theta - dtheta) and (target_theta lt theta + dtheta)) $
           and (target_phi lt dphi*2))
  angle_idx = idx[0]   

  if (energy_idx ne -1) and (angle_idx ne -1) then new_data.data[energy_idx, angle_idx]++ ; increase the count rate
endfor
end 
