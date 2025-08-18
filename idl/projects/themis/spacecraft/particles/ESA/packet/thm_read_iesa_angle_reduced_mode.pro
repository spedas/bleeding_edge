;+
;PROCEDURE:	thm_read_iesa_angle_reduced_mode
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
function thm_read_iesa_angle_reduced_mode

; I've assumed that the reduced distributions never have more than 88 angle bins.

maxbins=88
max_imode=8

; Ion Angle modes

;	ion angle mode 0 : 1 angle distribution - I&T mode

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
		anodes0=[replicate(1.,nrg0),replicate(0.,32-nrg0)]#[16.,replicate(0.,maxbins-nbins0)]
		map=fltarr(8,maxbins) & map(*,0)=.125 
		map0=map

; 	ion angle mode 1 : 1 angle distribution - Msph SS mode

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
		anodes1=[replicate(1.,nrg1)]#[16.,replicate(0.,maxbins-nbins1)]
		map=fltarr(8,maxbins) & map(*,0)=.125 
		map1=map

; 	ion angle mode 2 : 50 angle distribution - Msph FS mode

		nbins2=50
		nrg2=24
		nrg_wt2=[replicate(1.,16),replicate(2.,8),replicate(0.,32-nrg2)]#[replicate(1.,nbins2),replicate(0.,maxbins-nbins2)]
		theta2=[replicate(-1.,nrg2),replicate(0.,32-nrg2)]#[78.75,-78.75,replicate(45.,8),replicate(-45.,8),replicate(11.25,16),replicate(-11.25,16),replicate(0.,maxbins-nbins2)]
		dtheta2=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[22.5,22.5,replicate(45.,16),replicate(22.5,32),replicate(0.,maxbins-nbins2)]
		phi=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[0.,0.,22.5+45.*findgen(8),22.5+45.*findgen(8),11.25+22.5*findgen(16),11.25+22.5*findgen(16),replicate(0.,maxbins-nbins2)]
		phi_offset=90.-5.625
		phi2=phi+phi_offset+[(5.625*findgen(16)/16),(5.625+5.625*findgen(8)/8),replicate(0.,8)]#[replicate(1.,nbins2),replicate(0.,maxbins-nbins2)]
		dphi2=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[360.,360.,replicate(45.,16),replicate(22.5,32),replicate(0.,maxbins-nbins2)]
		p0=theta2+dtheta2/2.
		p1=theta2-dtheta2/2.
		domega2=2*!pi*dphi2/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes2=[replicate(1.,nrg2),replicate(0.,32-nrg2)]#[1.,1.,replicate(3.,16),replicate(4.,32),replicate(0.,maxbins-nbins2)]
		map=fltarr(8,maxbins) & map(0,0)=1. & map(7,1)=1. & map(1:2,2:9)=.5 & map(5:6,10:17)=.5 & map(3,18:33)=1. & map(4,34:49)=1.
		map2=map

; 	ion angle mode 3 : 1 angle distribution - Solar Wind SS mode 

		nbins3=1
		nrg3=16
		nrg_wt3=[replicate(2.,nrg3),replicate(0.,32-nrg3)]#[replicate(1.,nbins3),replicate(0.,maxbins-nbins3)]
		theta3=[replicate(-1.,nrg3),replicate(0.,32-nrg3)]#[0.,replicate(0.,maxbins-nbins3)]
		dtheta3=[replicate(1.,nrg3),replicate(0.,32-nrg3)]#[180.,replicate(0.,maxbins-nbins3)]
		phi=[replicate(1.,nrg3),replicate(0.,32-nrg3)]#[0.,replicate(0.,maxbins-nbins3)]
		phi_offset=0.
		phi3=phi
		dphi3=[replicate(1.,nrg3),replicate(0.,32-nrg3)]#[360.,replicate(0.,maxbins-nbins3)]
		p0=theta3+dtheta3/2.
		p1=theta3-dtheta3/2.
		domega3=2*!pi*dphi3/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes3=[replicate(1.,nrg3),replicate(0.,32-nrg3)]#[16.,replicate(0.,maxbins-nbins3)]
		map=fltarr(8,maxbins) & map(*,0)=.125 
		map3=map

; 	ion angle mode 4 : 50 angle distribution - Shock FS mode

		nbins4=50
		nrg4=24
		nrg_wt4=[replicate(2.,4),replicate(1.,16),replicate(2.,4),replicate(0.,32-nrg4)]#[replicate(1.,nbins4),replicate(0.,maxbins-nbins4)]
		theta4= [replicate(-1.,nrg4),replicate(0.,32-nrg4)]#[replicate(5.625,6),replicate(-5.625,6),replicate(16.875,6),replicate(-16.875,6),replicate(0.,8),replicate(45.,8),replicate(-45.,8),78.75,-78.75,replicate(0.,maxbins-nbins4)]
		dtheta4=[replicate(1.,nrg4),replicate(0.,32-nrg4)]#[replicate(11.25,24),replicate(45.,24),22.5,22.5,replicate(0.,maxbins-nbins4)]
		phi=    [replicate(1.,nrg4),replicate(0.,32-nrg4)]#[61.875+11.25*findgen(6),61.875+11.25*findgen(6),61.875+11.25*findgen(6),61.875+11.25*findgen(6),50.625,129.375,22.5,157.5+45.*findgen(5),22.5+45.*findgen(8),22.5+45.*findgen(8),0.,0.,replicate(0.,maxbins-nbins4)]
		phi_offset=90.-5.625
		phi4=phi+phi_offset+[(2.8125*findgen(4)/4),(2.8125+5.625*findgen(16)/16),(8.4375+2.8125*findgen(4)/4),replicate(0.,32-nrg4)]#[replicate(1.,nbins4),replicate(0.,maxbins-nbins4)]
		dphi4=[replicate(1.,nrg4),replicate(0.,32-nrg4)]#[replicate(11.25,26),replicate(45.,22),360.,360.,replicate(0.,maxbins-nbins4)]
		p0=theta4+dtheta4/2.
		p1=theta4-dtheta4/2.
		domega4=2*!pi*dphi4/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes4=[replicate(1.,nrg4),replicate(0.,32-nrg4)]#[replicate(2.,24),replicate(8.,8),replicate(3.,16),1.,1.,replicate(0.,maxbins-nbins4)]
		map=fltarr(8,maxbins) & map(3,0:5)=1. & map(4,6:11)=1. & map(3,12:17)=1. & map(4,18:23)=1. & map(3:4,24:31)=0.5 
		map(1:2,32:39)=0.5 & map(5:6,40:47)=0.5 & map(0,48)=1. & map(7,49)=1. 
		map4=map

; 	ion angle mode 5 : 72 angle distribution - Solar Wind FS mode

		nbins5=72
		nrg5=16
		nrg_wt5=[replicate(2.,16),replicate(0.,32-nrg5)]#[replicate(1.,nbins5),replicate(0.,maxbins-nbins5)]
		theta5= [replicate(-1.,nrg5),replicate(0.,32-nrg5)]#[replicate(5.625,6),replicate(-5.625,6),replicate(16.875,6),replicate(-16.875,6),replicate(11.25,7),replicate(-11.25,7),replicate(33.75,8),replicate(-33.75,8),replicate(56.25,8),replicate(-56.25,8),78.75,-78.75,replicate(0.,maxbins-nbins5)]
		dtheta5=[replicate(1.,nrg5),replicate(0.,32-nrg5)]#[replicate(11.25,24),replicate(22.5,48),replicate(0.,maxbins-nbins5)]
		phi=    [replicate(1.,nrg5),replicate(0.,32-nrg5)]#[61.875+11.25*findgen(6),61.875+11.25*findgen(6),61.875+11.25*findgen(6),61.875+11.25*findgen(6),39.375,140.625,180.+45.*findgen(5),39.375,140.625,180.+45.*findgen(5),45.+45.*findgen(8),45.+45.*findgen(8),45.+45.*findgen(8),45.+45.*findgen(8),0.,0.,replicate(0.,maxbins-nbins5)]
		phi_offset=90.-5.625
		phi5=phi+phi_offset+[(2.8125+5.625*findgen(16)/16),replicate(0.,32-nrg5)]#[replicate(1.,nbins5),replicate(0.,maxbins-nbins5)]
		dphi5=[replicate(1.,nrg5),replicate(0.,32-nrg5)]#[replicate(11.25,24),37.5,37.5,replicate(45.,5),37.5,37.5,replicate(45.,5),replicate(45.,32),360.,360.,replicate(0.,maxbins-nbins5)]
		p0=theta5+dtheta5/2.
		p1=theta5-dtheta5/2.
		domega5=2*!pi*dphi5/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes5=[replicate(1.,nrg5),replicate(0.,32-nrg5)]#[replicate(2.,24),replicate(4.,14),replicate(2.,16),replicate(1.,18),replicate(0.,maxbins-nbins5)]
		map=fltarr(8,maxbins) & map(3,0:5)=1. & map(4,6:11)=1. & map(3,12:17)=1. & map(4,18:23)=1. & map(3,24:30)=1. & map(4,31:37)=1.
 		map(2,38:45)=1. & map(5,46:53)=1. & map(1,54:61)=1. & map(6,62:69)=1. & map(0,70)=1. & map(7,71)=1.
		map5=map

;	ion angle mode 6 : 6 angle distribution - Msph FS mode 

		nbins6=6
		nrg6=32
		nrg_wt6= replicate(1.,nrg6)#[replicate(1.,nbins6),replicate(0.,maxbins-nbins6)]
		theta6=  replicate(-1.,nrg6)#[67.5,-67.5,0.,0.,0.,0.,replicate(0.,maxbins-nbins6)]
		dtheta6= replicate(1.,nrg6)#[45.,45.,90.,90.,90.,90.,replicate(0.,maxbins-nbins6)]
		phi=     replicate(1.,nrg6)#[0.,0.,0.,90.,180.,270.,replicate(0.,maxbins-nbins6)]
		phi_offset=90.-5.625
		phi6=phi+phi_offset+(11.25*findgen(nrg6)/nrg6)#[replicate(1.,nbins6),replicate(0.,maxbins-nbins6)]
		dphi6=   replicate(1.,nrg6)#[360.,360.,90.,90.,90.,90.,replicate(0.,maxbins-nbins6)]
		p0=theta6+dtheta6/2.
		p1=theta6-dtheta6/2.
		domega6=2*!pi*dphi6/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes6=[replicate(1.,nrg6)]#[2.,2.,12.,12.,12.,12.,replicate(0.,maxbins-nbins6)]
		map=fltarr(8,maxbins) & map(0:1,0)=.5 & map(6:7,1)=.5 & map(2:5,2:5)=.25 
		map6=map

;	ion angle mode 7 : 6 angle distribution - Solar Wind FS mode 

		nbins7=6
		nrg7=16
		nrg_wt7=[replicate(2.,16),replicate(0.,32-nrg7)]#[replicate(1.,nbins7),replicate(0.,maxbins-nbins7)]
		theta7=  [replicate(-1.,16),replicate(0.,32-nrg7)]#[67.5,-67.5,0.,0.,0.,0.,replicate(0.,maxbins-nbins7)]
		dtheta7= [replicate(1.,16),replicate(0.,32-nrg7)]#[45.,45.,90.,90.,90.,90.,replicate(0.,maxbins-nbins7)]
		phi=     [replicate(1.,16),replicate(0.,32-nrg7)]#[0.,0.,0.,90.,180.,270.,replicate(0.,maxbins-nbins7)]
		phi_offset=90.-5.625
		phi7=phi+phi_offset+[(2.8125+5.625*findgen(16)/16),replicate(0.,32-nrg7)]#[replicate(1.,nbins7),replicate(0.,maxbins-nbins7)]
		dphi7=   [replicate(1.,16),replicate(0.,32-nrg7)]#[360.,360.,90.,90.,90.,90.,replicate(0.,maxbins-nbins7)]
		p0=theta7+dtheta7/2.
		p1=theta7-dtheta7/2.
		domega7=2*!pi*dphi7/360.*(sin(p0/!radeg)-sin(p1/!radeg))
		anodes7=[replicate(1.,nrg7),replicate(0.,32-nrg7)]#[2.,2.,12.,12.,12.,12.,replicate(0.,maxbins-nbins7)]
		map=fltarr(8,maxbins) & map(0:1,0)=.5 & map(6:7,1)=.5 & map(2:5,2:5)=.25 
		map7=map

;  Ion Angle tables

	i_theta=reform([[theta0],[theta1],[theta2],[theta3],[theta4],[theta5],[theta6],[theta7]],32,maxbins,max_imode)
	i_dtheta=reform([[dtheta0],[dtheta1],[dtheta2],[dtheta3],[dtheta4],[dtheta5],[dtheta6],[dtheta7]],32,maxbins,max_imode)	
	i_phi=reform([[phi0],[phi1],[phi2],[phi3],[phi4],[phi5],[phi6],[phi7]],32,maxbins,max_imode)
	i_dphi=reform([[dphi0],[dphi1],[dphi2],[dphi3],[dphi4],[dphi5],[dphi6],[dphi7]],32,maxbins,max_imode)
	i_domega=reform([[domega0],[domega1],[domega2],[domega3],[domega4],[domega5],[domega6],[domega7]],32,maxbins,max_imode)	
	i_nbins=[nbins0,nbins1,nbins2,nbins3,nbins4,nbins5,nbins6,nbins7]
	i_nrg=[nrg0,nrg1,nrg2,nrg3,nrg4,nrg5,nrg6,nrg7]
	i_nrg_wt=reform([[nrg_wt0],[nrg_wt1],[nrg_wt2],[nrg_wt3],[nrg_wt4],[nrg_wt5],[nrg_wt6],[nrg_wt7]],32,maxbins,max_imode)	
	i_anodes=reform([[anodes0],[anodes1],[anodes2],[anodes3],[anodes4],[anodes5],[anodes6],[anodes7]],32,maxbins,max_imode)
	i_an_map=reform([[map0],[map1],[map2],[map3],[map4],[map5],[map6],[map7]],8,maxbins,max_imode)


mode={i_theta:i_theta,i_dtheta:i_dtheta,i_phi:i_phi,i_dphi:i_dphi,i_domega:i_domega,$
	i_nbins:i_nbins,i_nrg:i_nrg,i_nrg_wt:i_nrg_wt,i_anodes:i_anodes,i_an_map:i_an_map}

return,mode

end

