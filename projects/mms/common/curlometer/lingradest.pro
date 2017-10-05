;+
; PROCEDURE:
;       lingradest
; 
; PURPOSE:
;       IDL subroutine to calculate magnetic field gradients, divergence, curl, and field line
;       curvature from 4-point observations
; 
; Input: 
;       B-field components from the four probes
;       Coordinates from the four probes
;       Length of vectors (all variables should be interpolated to the same length)
; 
; Method used:
;       Linear Gradient/Curl Estimator technique
;       see Chanteur, ISSI, 1998, Ch. 11
; 
; Originally designed for Cluster by A. Runov (2003)
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-10-04 11:13:23 -0700 (Tue, 04 Oct 2016) $
; $LastChangedRevision: 22016 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/curlometer/lingradest.pro $
;-
pro lingradest, Bx1, Bx2, Bx3, Bx4,                            $
                By1, By2, By3, By4,                            $
                Bz1, Bz2, Bz3, Bz4,                            $
                R1,  R2,  R3,  R4,                             $
                datarrLength,                                  $
                bxbc, bybc, bzbc, bbc,                         $
                LGBx, LGBy, LGBz,                              $
                LCxB, LCyB, LCzB, LD,                          $
                curv_x_B, curv_y_B, curv_z_B, RcurvB
                
                
                
              ; Inizialisation
              Rb=replicate(0., datarrLength, 3) & dR1=Rb & dR2=Rb & dR3=Rb & dR4=Rb
              k1=Rb & k2=Rb & k3=Rb & k4=Rb
              mu1=replicate(0., datarrLength) & mu2=mu1 & mu3=mu1 & mu4=mu1
              Bxbc=replicate(0., datarrLength) & Bybc=Bxbc & Bzbc=Bxbc & Bbc =Bxbc
              LGBx=replicate(0., datarrlength, 3) ; Linear Gradient B estimator
              LGBy=LGBx & LGBz=LGBx
              LCxB=replicate(0., datarrlength)  ; Linear Curl B estimator
              LCyB=LCxB & LCzB=LCxB
              LD      =replicate(0., datarrlength)
              curv_x_B=replicate(0., datarrlength)
              curv_y_B=curv_x_B & curv_z_B=curv_x_B & curvB=curv_x_B
              RcurvB  =replicate(0., datarrlength)
              B_cross_R_x=replicate(0., datarrlength)
              B_cross_R_y=B_cross_R_x & B_cross_R_z=B_cross_R_x & B_cross_R=B_cross_R_x
              Ncurv_x=B_cross_R_x & Ncurv_y=B_cross_R_x & Ncurv_z=B_cross_R_x
              
              ;...calculations
              
              r12=(R2-R1)/1000. & r13=(R3-R1)/1000. & r14=(R4-R1)/1000. ; distances in 1000 km!
              r21=(R1-R2)/1000. & r23=(R3-R2)/1000. & r24=(R4-R2)/1000.
              r31=(R1-R3)/1000. & r32=(R2-R3)/1000. & r34=(R4-R3)/1000.
              r41=(R1-R4)/1000. & r42=(R2-R4)/1000. & r43=(R3-R4)/1000.
              
              for i=0L,datarrLength-1 do begin
                ; if   (Bx1[i] NE 999.999) $
                ;  AND (Bx2[i] NE 999.999) $
                ;  AND (Bx3[i] NE 999.999) $
                ;  AND (Bx4[i] NE 999.999) then begin
                Rb[i,0]=0.25*(r1[i,0]+r2[i,0]+r3[i,0]+r4[i,0]) ; Tetrahedrom mesocentre coordinates
                Rb[i,1]=0.25*(r1[i,1]+r2[i,1]+r3[i,1]+r4[i,1])
                Rb[i,2]=0.25*(r1[i,2]+r2[i,2]+r3[i,2]+r4[i,2])
                
                dR1[i,0:2]=(Rb[i,0:2]-r1[i,0:2])/1000 ; Difference in 1000 km!
                dR2[i,0:2]=(Rb[i,0:2]-r2[i,0:2])/1000
                dR3[i,0:2]=(Rb[i,0:2]-r3[i,0:2])/1000
                dR4[i,0:2]=(Rb[i,0:2]-r4[i,0:2])/1000
                
                k1[i,0:2]=crossp(r23[i,0:2],r24[i,0:2])
                k1[i,0:2]=k1[i,0:2]/(r21[i,0]*k1[i,0]+r21[i,1]*k1[i,1]+r21[i,2]*k1[i,2])
                k2[i,0:2]=crossp(r34[i,0:2],r31[i,0:2])
                k2[i,0:2]=k2[i,0:2]/(r32[i,0]*k2[i,0]+r32[i,1]*k2[i,1]+r32[i,2]*k2[i,2])
                k3[i,0:2]=crossp(r41[i,0:2],r42[i,0:2])
                k3[i,0:2]=k3[i,0:2]/(r43[i,0]*k3[i,0]+r43[i,1]*k3[i,1]+r43[i,2]*k3[i,2])
                k4[i,0:2]=crossp(r12[i,0:2],r13[i,0:2])
                k4[i,0:2]=k4[i,0:2]/(r14[i,0]*k4[i,0]+r14[i,1]*k4[i,1]+r14[i,2]*k4[i,2])
                
                mu1[i]=1.+(k1[i,0]*dR1[i,0]+k1[i,1]*dR1[i,1]+k1[i,2]*dR1[i,2])
                mu2[i]=1.+(k2[i,0]*dR2[i,0]+k2[i,1]*dR2[i,1]+k2[i,2]*dR2[i,2])
                mu3[i]=1.+(k3[i,0]*dR3[i,0]+k3[i,1]*dR3[i,1]+k3[i,2]*dR3[i,2])
                mu4[i]=1.+(k4[i,0]*dR4[i,0]+k4[i,1]*dR4[i,1]+k4[i,2]*dR4[i,2])
                
                Bxbc[i]=mu1[i]*Bx1[i]+mu2[i]*Bx2[i]+mu3[i]*Bx3[i]+mu4[i]*Bx4[i]; Magnetic field in the barycentre
                Bybc[i]=mu1[i]*By1[i]+mu2[i]*By2[i]+mu3[i]*By3[i]+mu4[i]*By4[i];
                Bzbc[i]=mu1[i]*Bz1[i]+mu2[i]*Bz2[i]+mu3[i]*Bz3[i]+mu4[i]*Bz4[i];
                Bbc[i]=sqrt(Bxbc[i]^2+Bybc[i]^2+Bzbc[i]^2);
                
                LGBx[i,0:2]=Bx1[i]*k1[i,0:2]+Bx2[i]*k2[i,0:2]+Bx3[i]*k3[i,0:2]+Bx4[i]*k4[i,0:2];
                LGBy[i,0:2]=By1[i]*k1[i,0:2]+By2[i]*k2[i,0:2]+By3[i]*k3[i,0:2]+By4[i]*k4[i,0:2];
                LGBz[i,0:2]=Bz1[i]*k1[i,0:2]+Bz2[i]*k2[i,0:2]+Bz3[i]*k3[i,0:2]+Bz4[i]*k4[i,0:2];
                
                LD[i]=Bx1[i]*k1[i,0]+By1[i]*k1[i,1]+Bz1[i]*k1[i,2] $
                  +Bx2[i]*k2[i,0]+By2[i]*k2[i,1]+Bz2[i]*k2[i,2] $
                  +Bx3[i]*k3[i,0]+By3[i]*k3[i,1]+Bz3[i]*k3[i,2] $
                  +Bx4[i]*k4[i,0]+By4[i]*k4[i,1]+Bz4[i]*k4[i,2] ; Divergence B
                  
                LCxB[i]=(k1[i,1]*Bz1[i]-k1[i,2]*By1[i])+(k2[i,1]*Bz2[i]-k2[i,2]*By2[i]) $
                  +(k3[i,1]*Bz3[i]-k3[i,2]*By3[i])+(k4[i,1]*Bz4[i]-k4[i,2]*By4[i])
                LCyB[i]=(k1[i,2]*Bx1[i]-k1[i,0]*Bz1[i])+(k2[i,2]*Bx2[i]-k2[i,0]*Bz2[i]) $
                  +(k3[i,2]*Bx3[i]-k3[i,0]*Bz3[i])+(k4[i,2]*Bx4[i]-k4[i,0]*Bz4[i])
                LCzB[i]=(k1[i,0]*By1[i]-k1[i,1]*Bx1[i])+(k2[i,0]*By2[i]-k2[i,1]*Bx2[i]) $
                  +(k3[i,0]*By3[i]-k3[i,1]*Bx3[i])+(k4[i,0]*By4[i]-k4[i,1]*Bx4[i])
                  
                  
                  
                curv_x_B[i]=(Bxbc[i]*LGBx[i,0]+Bybc[i]*LGBx[i,1]+Bzbc[i]*LGBx[i,2])/(Bbc[i]*Bbc[i]);
                curv_y_B[i]=(Bxbc[i]*LGBy[i,0]+Bybc[i]*LGBy[i,1]+Bzbc[i]*LGBy[i,2])/(Bbc[i]*Bbc[i]);
                curv_z_B[i]=(Bxbc[i]*LGBz[i,0]+Bybc[i]*LGBz[i,1]+Bzbc[i]*LGBz[i,2])/(Bbc[i]*Bbc[i]);
                
                curvB[i]=sqrt(curv_x_B[i]*curv_x_B[i]+curv_y_B[i]*curv_y_B[i]+curv_z_B[i]*curv_z_B[i]);
                
                RcurvB[i]=curvB[i]^(-1);
                
              endfor
              print, 'Calculations completed'
              
end

                              
