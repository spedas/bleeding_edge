;+
;PROCEDURE:	thm_read_esa_angle_full_mode
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
;		corrected a small error in the ion phi angle map for solar wind mode
;NOTES:	  
;	Used by thm_load_esa_pkt.pro
;-
function thm_read_esa_angle_full_mode
		  
; default modes 1,2,3

maxbins=176

; Full and Burst Ion Angle maps

; 	I&T ion angle distribution - no iesa anode mixing
		nbins0=88
		nrg0=32
		nrg_wt0=[replicate(1.,nrg0)]#[replicate(1.,nbins0),replicate(0.,maxbins-nbins0)]
		theta=[replicate(78.75,2),replicate(-78.75,2),replicate(56.25,2),replicate(-56.25,2),$
		replicate(39.375,4),replicate(28.125,4),replicate(-39.375,4),replicate(-28.125,4),$
		replicate(19.6875,8),replicate(14.0625,8),replicate(8.4375,8),replicate(2.8125,8),$
		replicate(-2.8125,8),replicate(-8.4375,8),replicate(-14.0625,8),replicate(-19.6875,8),$
		replicate(0.,maxbins-nbins0)]
		theta0=replicate(-1.,32)#theta
		dtheta=[replicate(22.5,8),replicate(11.25,16),replicate(5.625,64),replicate(0.,maxbins-nbins0)]	
		dtheta0=replicate(1.,32)#dtheta
		phi=[90.+180.*findgen(2),90.+180.*findgen(2),90.+180.*findgen(2),90.+180.*findgen(2),$
		45.+90.*findgen(4),45.+90.*findgen(4),45.+90.*findgen(4),45.+90.*findgen(4),$
		22.5+45.*findgen(8),22.5+45.*findgen(8),22.5+45.*findgen(8),22.5+45.*findgen(8),$
		22.5+45.*findgen(8),22.5+45.*findgen(8),22.5+45.*findgen(8),22.5+45.*findgen(8),replicate(0.,maxbins-nbins0)]
		phi_offset=90.-5.625
		phi0=replicate(1.,32)#phi+phi_offset+(11.25*findgen(32)/32.)#replicate(1.,maxbins)
		dphi0=replicate(1.,32)#[replicate(180.,8),replicate(90.,16),replicate(45.,64),replicate(0.,maxbins-nbins0)]
		p0=theta0+dtheta0/2.
		p1=theta0-dtheta0/2.
		domega0=2*!pi*dphi0/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes0=fltarr(32,maxbins) & anodes0(*,0:maxbins-1)=1.
		map=fltarr(8,maxbins) & map(0,0:1)=1. & map(7,2:3)=1. & map(1,4:5)=1. & map(6,6:7)=1. & map(2,8:15)=1. & map(5,16:23)=1. & map(3,24:55)=1. & map(4,56:87)=1.
		map0=map

;	Msph ion angle distribution - normal 88 angle map
		nbins1=88
		nrg1=32
		nrg_wt1=[replicate(1.,nrg1)]#[replicate(1.,nbins1),replicate(0.,maxbins-nbins1)]
		theta=[replicate(78.75,4),replicate(-78.75,4),replicate(56.25,8),replicate(-56.25,8),$
		replicate(33.75,16),replicate(-33.75,16),replicate(11.25,16),replicate(-11.25,16),replicate(0.,maxbins-nbins1)]
		theta1=replicate(-1.,32)#theta
		dtheta=[replicate(22.5,nbins1),replicate(0.,maxbins-nbins1)]
		dtheta1=replicate(1.,32)#dtheta
		phi=[45.+90.*findgen(4),45.+90.*findgen(4),22.5+45.*findgen(8),22.5+45.*findgen(8),$
		11.25+22.5*findgen(16),11.25+22.5*findgen(16),11.25+22.5*findgen(16),11.25+22.5*findgen(16),replicate(0.,maxbins-nbins1)]
		phi_offset=90.-5.625
		phi1=replicate(1.,32)#phi+phi_offset+(11.25*findgen(32)/32.)#replicate(1.,maxbins)
		dphi1=replicate(1.,32)#[replicate(90.,8),replicate(45.,16),replicate(22.5,64),replicate(0.,maxbins-nbins1)]
		p0=theta1+dtheta1/2.
		p1=theta1-dtheta1/2.
		domega1=2*!pi*dphi1/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes1=replicate(1.,32)#[replicate(1.,24),replicate(2.,32),replicate(4.,32),replicate(0.,maxbins-nbins1)]
		map=fltarr(8,maxbins) & map(0,0:3)=1. & map(7,4:7)=1. & map(1,8:15)=1. & map(6,16:23)=1. & map(2,24:39)=1. & map(5,40:55)=1. & map(3,56:71)=1. & map(4,72:87)=1.
		map1=map

; 	SW ion angle distribution - narrow angle bin in Solar Wind direction
		nbins2=176
		nrg2=16
;		nrg_wt=[replicate(2.,52),replicate(1.,36)]
		nrg_wt=replicate(2.,88)			; this is required by double sweep to compensate for the (phi/11.25) term in eff
		nrg_wt2=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[nrg_wt,nrg_wt]
		theta=[replicate(19.6875,6),replicate(14.0625,6),replicate(8.4375,6),replicate(2.8125,6),$
		replicate(-2.8125,6),replicate(-8.4375,6),replicate(-14.0625,6),replicate(-19.6875,6),$
		replicate(11.25,2),replicate(-11.25,2),replicate(33.75,4),replicate(-33.75,4),$
		replicate(22.5,6),replicate(-22.5,6),replicate(67.5,8),replicate(-67.5,8)]
		theta2=[replicate(-1.,nrg2),replicate(0.,32-nrg2)]#[theta,theta]
		dtheta=[replicate(5.625,48),replicate(22.5,12),replicate(45.0,28)]	
		dtheta2=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[dtheta,dtheta]

; the following code was discovered to be incorrect on 090922 causing a ~3 degree error in Vy
		phi=[59.0625+11.25*findgen(6),59.0625+11.25*findgen(6),59.0625+11.25*findgen(6),59.0625+11.25*findgen(6),$
		59.0625+11.25*findgen(6),59.0625+11.25*findgen(6),59.0625+11.25*findgen(6),59.0625+11.25*findgen(6),$
;		47.8125,126.5625,47.8125,126.5625,56.25+22.5*findgen(4),56.25+22.5*findgen(4),22.5,157.5+45.*findgen(5),$
;		22.5,157.5+45.*findgen(5),22.5+45.*findgen(8),22.5+45.*findgen(8)]
		47.8125,126.5625,47.8125,126.5625,50.625+22.5*findgen(4),50.625+22.5*findgen(4),$
		11.25,146.25+45.*findgen(5),11.25,146.25+45.*findgen(5),11.25+45.*findgen(8),11.25+45.*findgen(8)]		
		phi_offset=90.-5.625
;		phi2=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[phi,phi+5.625]+phi_offset+[5.625*findgen(16)/16.,replicate(0.,32-nrg2)]#replicate(1.,nbins2)
;		dphi=[replicate(5.625,52),replicate(22.5,8),replicate(45.,28)]

; the following code fixes the mistake 090922
		phi=[56.25+11.25*findgen(6),56.25+11.25*findgen(6),56.25+11.25*findgen(6),56.25+11.25*findgen(6),56.25+11.25*findgen(6),$
		56.25+11.25*findgen(6),56.25+11.25*findgen(6),56.25+11.25*findgen(6),45.,123.75,45.,123.75,50.625+22.5*findgen(4),$
		50.625+22.5*findgen(4),16.875,151.875+45.*findgen(5),16.875,151.875+45.*findgen(5),16.875+45.*findgen(8),16.875+45.*findgen(8)]
		phi_offset=90.

		dphi=[replicate(5.625,52),replicate(11.25,8),replicate(22.5,28)]
		dphi2=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[dphi,dphi]
		phi2=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[phi,phi+dphi]+phi_offset+[5.625*findgen(16)/16.,replicate(0.,32-nrg2)]#replicate(1.,nbins2)

		p0=theta2+dtheta2/2.
		p1=theta2-dtheta2/2.
		domega2=2*!pi*dphi2/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes=[replicate(1.,48),replicate(4.,4),replicate(2.,8),replicate(6.,12),replicate(2.,16)]
		anodes2=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[anodes,anodes] 
		map=fltarr(8,maxbins) & map(3,0:23)=1. & map(4,24:47)=1. & map(3,48:49)=1. & map(4,50:51)=1. & map(2,52:55)=1. & map(5,56:59)=1. 
		map(2,60:65)=.5 & map(3,60:65)=.5 & map(4,66:71)=.5 & map(5,66:71)=.5 & map(0,72:79)=.5 & map(1,72:79)=.5 & map(6,80:87)=.5 & map(7,80:87)=.5
		map(*,88:175)=map(*,0:87)
		map2=map
	
; Angle modes

	i_theta=reform([[theta0],[theta1],[theta2]],32,maxbins,3)
	i_dtheta=reform([[dtheta0],[dtheta1],[dtheta2]],32,maxbins,3)	
	i_phi=reform([[phi0],[phi1],[phi2]],32,maxbins,3)
	i_dphi=reform([[dphi0],[dphi1],[dphi2]],32,maxbins,3)
	i_domega=reform([[domega0],[domega1],[domega2]],32,maxbins,3)	
	i_nbins=[nbins0,nbins1,nbins2]
	i_nrg=[nrg0,nrg1,nrg2]
	i_nrg_wt=reform([[nrg_wt0],[nrg_wt1],[nrg_wt2]],32,maxbins,3)	
	i_anodes=reform([[anodes0],[anodes1],[anodes2]],32,maxbins,3)
	i_an_map=reform([[map0],[map1],[map2]],8,maxbins,3)

maxbins=88


;	Msph electron angle distribution - normal 88 angle map
		nbins7=88
		nrg7=32
		nrg_wt7=[replicate(1.,nrg7)]#[replicate(1.,nbins7)]
		theta=[replicate(78.75,4),replicate(-78.75,4),replicate(56.25,8),replicate(-56.25,8),$
		replicate(33.75,16),replicate(11.25,16),replicate(-11.25,16),replicate(-33.75,16)]
		theta7=replicate(-1.,nrg7)#theta
		dtheta=replicate(22.5,nbins7)
		dtheta7=replicate(1.,32)#dtheta
		phi=[45.+90.*findgen(4),45.+90.*findgen(4),22.5+45.*findgen(8),22.5+45.*findgen(8),$
		11.25+22.5*findgen(16),11.25+22.5*findgen(16),11.25+22.5*findgen(16),11.25+22.5*findgen(16)]
		phi_offset=90.-5.625
		phi7=replicate(1.,32)#phi+phi_offset+(11.25*findgen(32)/32.)#replicate(1.,88)
		dphi7=replicate(1.,32)#[replicate(90.,8),replicate(45.,16),replicate(22.5,64)]
		p0=theta7+dtheta7/2.
		p1=theta7-dtheta7/2.
		domega7=2*!pi*dphi7/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes7=fltarr(32,88) & anodes7(*)=1.
		map=fltarr(8,maxbins) & map(0,0:3)=1. & map(7,4:7)=1. & map(1,8:15)=1. & map(6,16:23)=1. & map(2,24:39)=1. & map(3,40:55)=1. & map(4,56:71)=1. & map(5,72:87)=1.
		map7=map

;	Msph electron angle distribution - 15 energy x 88 angle map
		nbins8=88
		nrg8=15
		nrg_wt8=[replicate(2.,nrg8),replicate(0.,32-nrg8)]#[replicate(1.,nbins8)]
		theta=[replicate(78.75,4),replicate(-78.75,4),replicate(56.25,8),replicate(-56.25,8),$
		replicate(33.75,16),replicate(11.25,16),replicate(-11.25,16),replicate(-33.75,16)]
		theta8=[replicate(-1.,nrg8),replicate(0.,32-nrg8)]#theta
		dtheta=replicate(22.5,nbins8)
		dtheta8=[replicate(1.,nrg8),replicate(0.,32-nrg8)]#dtheta
		phi=[45.+90.*findgen(4),45.+90.*findgen(4),22.5+45.*findgen(8),22.5+45.*findgen(8),$
		11.25+22.5*findgen(16),11.25+22.5*findgen(16),11.25+22.5*findgen(16),11.25+22.5*findgen(16)]
		phi_offset=90.-5.625
		phi8= [replicate(1.,nrg8),replicate(0.,32-nrg8)]#phi+phi_offset+(11.25*(2.*[findgen(nrg8),replicate(0.,32-nrg8)]+1.5)/32.)#replicate(1.,nbins8)
		dphi8=[replicate(1.,nrg8),replicate(0.,32-nrg8)]#[replicate(90.,8),replicate(45.,16),replicate(22.5,64)]
		p0=theta8+dtheta8/2.
		p1=theta8-dtheta8/2.
		domega8=2*!pi*dphi8/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes8=[replicate(1.,nrg8),replicate(0.,32-nrg8)]#[replicate(1.,nbins8)]
		map=fltarr(8,maxbins) & map(0,0:3)=1. & map(7,4:7)=1. & map(1,8:15)=1. & map(6,16:23)=1. 
		map(2,24:39)=1. & map(3,40:55)=1. & map(4,56:71)=1. & map(5,72:87)=1.
		map8=map

	e_theta=reform([[theta7],[theta8]],32,maxbins,2)
	e_dtheta=reform([[dtheta7],[dtheta8]],32,maxbins,2)	
	e_phi=reform([[phi7],[phi8]],32,maxbins,2)
	e_dphi=reform([[dphi7],[dphi8]],32,maxbins,2)
	e_domega=reform([[domega7],[domega8]],32,maxbins,2)	
	e_nbins=[nbins7,nbins8]
	e_nrg=[nrg7,nrg8]
	e_nrg_wt=reform([[nrg_wt7],[nrg_wt8]],32,maxbins,2)
	e_anodes=reform([[anodes7],[anodes8]],32,maxbins,2)
	e_an_map=reform([[map7],[map8]],8,maxbins,2)

mode={i_theta:i_theta,i_dtheta:i_dtheta,i_phi:i_phi,i_dphi:i_dphi,i_domega:i_domega,$
	i_nbins:i_nbins,i_nrg:i_nrg,i_nrg_wt:i_nrg_wt,i_anodes:i_anodes,i_an_map:i_an_map,$
	e_theta:e_theta,e_dtheta:e_dtheta,e_phi:e_phi,e_dphi:e_dphi,e_domega:e_domega,$
	e_nbins:e_nbins,e_nrg:e_nrg,e_nrg_wt:e_nrg_wt,e_anodes:e_anodes,e_an_map:e_an_map}

return,mode

end
