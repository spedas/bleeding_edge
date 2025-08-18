;+
;PROCEDURE:	thm_read_eesa_angle_reduced_mode
;PURPOSE:	
;	Returns data structure with angle maps
;INPUT:		
;
;KEYWORDS:
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  07/03/22
;MOD HISTORY:
;
;NOTES:	  
;	Used by thm_load_esa_pkt.pro
;-
function thm_read_eesa_angle_reduced_mode
		  
; I've assumed that the reduced distributions never have more than 88 angle bins.

maxbins=88
max_emode=3

; Electron Angle modes

;	electron angle mode 0 : 1 angle distribution - I&T mode 

		nbins0=1
		nrg0=16
		nrg_wt0=[replicate(2.,nrg0),replicate(0.,32-nrg0)]#[replicate(1.,nbins0),replicate(0.,maxbins-nbins0)]
		theta0=[replicate(-1.,nrg0),replicate(0.,32-nrg0)]#[0.,replicate(0.,maxbins-nbins0)]
		dtheta0=[replicate(1.,nrg0),replicate(0.,32-nrg0)]#[180.,replicate(0.,maxbins-nbins0)]
		phi=[replicate(1.,nrg0),replicate(0.,32-nrg0)]#[0.,replicate(0.,maxbins-nbins0)]
		phi_offset=0.
		phi0=phi
		dphi0=[replicate(1.,nrg0),replicate(0.,32-nrg0)]#[360.,replicate(0.,maxbins-nbins0)]
		p0=theta0+dtheta0/2.
		p1=theta0-dtheta0/2.
		domega0=2*!pi*dphi0/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes0=[replicate(1.,nrg0),replicate(0.,32-nrg0)]#[8.,replicate(0.,maxbins-nbins0)]
		map=fltarr(8,maxbins) & map(*,0)=.125 
		map0=map

; 	electron angle mode 1 : 1 angle distribution - Msph SS mode

		nbins1=1
		nrg1=32
		nrg_wt1=replicate(1.,nrg1)#[replicate(1.,nbins1),replicate(0.,maxbins-nbins1)]
		theta1=replicate(-1.,32)#[0.,replicate(0.,maxbins-nbins1)]
		dtheta1=replicate(1.,32)#[180.,replicate(0.,maxbins-nbins1)]
		phi=replicate(1.,32)#[0.,replicate(0.,maxbins-nbins1)]
		phi_offset=0.
		phi1=phi
		dphi1=replicate(1.,32)#[360.,replicate(0.,maxbins-nbins1)]
		p0=theta1+dtheta1/2.
		p1=theta1-dtheta1/2.
		domega1=2*!pi*dphi1/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes1=[replicate(1.,nrg1)]#[8.,replicate(0.,maxbins-nbins1)]
		map=fltarr(8,maxbins) & map(*,0)=.125 
		map1=map


;	electron angle mode 2 : 6 angle distribution - Msph FS mode 

		nbins2=6
		nrg2=32
		nrg_wt2= replicate(1.,nrg2)#[replicate(1.,nbins2),replicate(0.,maxbins-nbins2)]
		theta2=  replicate(-1.,nrg2)#[67.5,-67.5,0.,0.,0.,0.,replicate(0.,maxbins-nbins2)]
		dtheta2= replicate(1.,nrg2)#[45.,45.,90.,90.,90.,90.,replicate(0.,maxbins-nbins2)]
		phi=     replicate(1.,nrg2)#[0.,0.,0.,90.,180.,270.,replicate(0.,maxbins-nbins2)]
		phi_offset=90.-5.625
		phi2=phi+phi_offset+(11.25*findgen(nrg2)/nrg2)#[replicate(1.,6),replicate(0.,maxbins-nbins2)]
		dphi2=   replicate(1.,nrg2)#[360.,360.,90.,90.,90.,90.,replicate(0.,maxbins-nbins2)]
		p0=theta2+dtheta2/2.
		p1=theta2-dtheta2/2.
		domega2=2*!pi*dphi2/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes2=[replicate(1.,nrg2)]#[2.,2.,4.,4.,4.,4.,replicate(0.,maxbins-nbins2)]
		map=fltarr(8,maxbins) & map(0:1,0)=.5 & map(6:7,1)=.5 & map(2:5,2:5)=.25 
		map2=map

;  Electron Angle tables

	e_theta=reform([[theta0],[theta1],[theta2]],32,maxbins,max_emode)
	e_dtheta=reform([[dtheta0],[dtheta1],[dtheta2]],32,maxbins,max_emode)	
	e_phi=reform([[phi0],[phi1],[phi2]],32,maxbins,max_emode)
	e_dphi=reform([[dphi0],[dphi1],[dphi2]],32,maxbins,max_emode)
	e_domega=reform([[domega0],[domega1],[domega2]],32,maxbins,max_emode)	
	e_nbins=[nbins0,nbins1,nbins2]
	e_nrg=[nrg0,nrg1,nrg2]
	e_nrg_wt=reform([[nrg_wt0],[nrg_wt1],[nrg_wt2]],32,maxbins,max_emode)	
	e_anodes=reform([[anodes0],[anodes1],[anodes2]],32,maxbins,max_emode)
	e_an_map=reform([[map0],[map1],[map2]],8,maxbins,max_emode)

mode={e_theta:e_theta,e_dtheta:e_dtheta,e_phi:e_phi,e_dphi:e_dphi,e_domega:e_domega,$
	e_nbins:e_nbins,e_nrg:e_nrg,e_nrg_wt:e_nrg_wt,e_anodes:e_anodes,e_an_map:e_an_map}

return,mode

end

