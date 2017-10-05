function sweap3,olddet,scale=scale,deflector=deflector,limits=lim,print=print

mirror=0
det=define_det(n_potent=8,olddet=olddet,scale=scale, r_range = [-7d,7d], z_range = [-2d,8d],limits=lim)

if not keyword_set(olddet) and not keyword_set(deflector) then deflector = 0
if n_elements(deflector) ne 0 then det.potents = double(indgen(8) eq deflector)
pot = det.potents

det.name='sweap3'


;basic structure definitions

nan = !values.d_nan
arc = {arc_def0,n:-1, cr0:0.d, cz0:0.d, rr:0.d, th1:0.d, th2:0.d}
pnt = {point, n:-1, r:nan, z:nan }


;basic parameters

r1 = 3.34		;inner (base dimension)

r2 = r1*1.03		;outer
r3 = r1*1.639		;spherical section
r4 = r3*1.06		;top cap

theta_open = 13 
theta_cap = 12

zdel = (r3-r1)*cos(theta_open*!pi/180)	;center of spherical section

r0 = zdel*tan(theta_open*!pi/180)	;delta radius

print,r0,zdel

thickness = 0.063d
thickness2 = 0.159d

r1minus = r1-thickness2
r3minus = r3-thickness2
r2plus = r2+thickness

thetamax = 90

rdef0 = 2.5
zdef0 = 0.575
rdefin = 3.8
rdefout = rdefin+thickness
rdefang1 = 10
rdefang2 = 60

routergrid = 6.7
rinnergrid = routergrid-0.3

toftoprflange = 6.7
toftopr = 6.2

cantop = 7.5

;deflector arcs

arc1  = {arc_def0, 0, r0, 0.d, r1, theta_open,49.5}  ;  inner toroidal
arc1sp  = {arc_def0, 0,     r0, 0.d, r1, 50, thetamax}  ;  inner spoiler
arc2  = {arc_def0, 3, r0, 0.d, r2, theta_open,49.5}  ; outer toroidal
arc2sp  = {arc_def0, 7,     r0, 0.d, r2, 50, thetamax}  ; outer spoiler
arc3  = {arc_def0, 0, 0.d, -zdel, r3,  0.d, theta_open}   ;  inner spherical
arc4  = {arc_def0, 3, 0.d, -zdel, r4,  0.d, theta_cap}   ; outer spherical cap
arc5 = {arc_def0, 1, rdef0, -zdef0, rdefin, rdefang1, rdefang2} ; lower deflector inside

arc1minus  = {arc_def0, 0, r0, 0.d, r1minus, theta_open, 49.5}  ; inner toroidal inside
arc2plus = {arc_def0, 3, r0, 0.d, r2plus, theta_open, 49.5} ; outer toroidal outside
arc2plus.th1 = asin(r2/r2plus*sin(arc2.th1*!pi/180))*180/!pi

arc1spminus  = {arc_def0, 0,     r0, 0.d, r1minus, 50, thetamax}  ;  inner spoiler
arc2spplus  = {arc_def0, 7,     r0, 0.d, r2plus, 50, thetamax}  ; outer spoiler

arc3minus  = {arc_def0, 0, 0.d, -zdel, r3minus,  0.d, theta_open} ; inner spherical inside

arc5plus = {arc_def0, 1, rdef0, -zdef0, rdefout, rdefang1, rdefang2} ; lower deflector outside

;individual points of arcs, and endpoints

pc1 = arc_pts(arc1)
pc1sp = arc_pts(arc1sp)
pc2 = arc_pts(arc2)
pc2sp = arc_pts(arc2sp)
pc3 = arc_pts(arc3)
pc4 = arc_pts(arc4)
pc5 = arc_pts(arc5)
pc1minus = arc_pts(arc1minus,/rev)
pc2plus = arc_pts(arc2plus,/rev)
pc1spminus = arc_pts(arc1spminus,/rev)
pc2spplus = arc_pts(arc2spplus,/rev)
pc3minus = arc_pts(arc3minus,/rev)
pc5plus = arc_pts(arc5plus,/rev)

end1 = arc_endpoints(arc1)
end1sp = arc_endpoints(arc1sp)
end1minus = arc_endpoints(arc1minus)
end1spminus = arc_endpoints(arc1spminus)
end2 = arc_endpoints(arc2)
end2sp = arc_endpoints(arc2sp)
end2plus = arc_endpoints(arc2plus)
end2spplus = arc_endpoints(arc2spplus)
end4 = arc_endpoints(arc4)
end5 = arc_endpoints(arc5)
end5plus = arc_endpoints(arc5plus)


deltadef1 = end2plus(0).z-end5plus(0).z			;delta Z between outer hemisphere and lower deflector
zdef1 = end4(1).z+deltadef1+rdefout*cos(rdefang1*!pi/180)	;center of upper deflector

print,zdef1

arc6 = {arc_def0, 2, rdef0, zdef1, rdefin, 180-rdefang1, 180-rdefang2}	;upper deflector inner side
arc6plus = {arc_def0, 2, rdef0, zdef1, rdefout, 180-rdefang1, 180-rdefang2} ; upper deflector outer side

end6 = arc_endpoints(arc6)
end6plus = arc_endpoints(arc6plus)
pc6 = arc_pts(arc6)
pc6plus = arc_pts(arc6plus,/rev)


;exit grids and mcp

p1 = end2sp(1) & p1.z = p1.z-0.02 & p1.n = 3
p2 = p1 & p2.r = 4.35+thickness
p3 = p2 & p3.z = p2.z - 0.6d
p4 = p3 & p4.r = 3.3-thickness
p5 = p4 & p5.z = p1.z-0.2d
p6 = p5 & p6.r = p6.r+0.3d
p7 = p6 & p7.z = p6.z -0.1d
p8 = p7 & p8.r = p7.r-0.3d +thickness
p9 = p8 & p9.z = p8.z-0.1d
p10 = p9 & p10.r = p2.r-thickness
p11 = p10 & p11.z = p10.z+0.1d
p12 = p11 & p12.r = p2.r-0.2d
p13 = p12 & p13.z = p1.z-0.2d

box = [p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p1]
p6a = p13
exit_grid = [p6,p6a]
mcp = [p3,p4,p9,p10,p3]


;box around simulation

pl0 = p3 & pl0.n = 5 & pl0.r =pl0.r+0.3 & pl0.z = -1.5
pl1 = pl0 & pl1.r = 7.0
pl2 = pl1 & pl2.z = 7.9
pl3 = pl2 & pl3.r = pl0.r
pl4 = pl3 & pl4.z = pl3.z-thickness2
pl5 = pl4 & pl5.r = 7.0-thickness2
pl6 = pl5 & pl6.z = pl0.z+thickness2
pl7 = pl6 & pl7.r = pl0.r
plate = [pl0,pl1,pl2,pl3,pl4,pl5,pl6,pl7,pl0]


;notch where top cap meets outer deflector when closed

wm = min(abs(pc2plus.r - (end2plus[0].r+0.2)),mini)
wm2 = min(abs(pc2plus.r - (end2plus[0].r+0.3)),mini2)

pn0 = pc2plus(mini)
pn1 = pn0 & pn1.z = end2plus[0].z
pn2 = pn1 & pn2.r = pc2plus(mini2).r
pn3 = pc2plus(mini2)
notch = [pn0,pn1,pn2,pn3,pn0]


;top cap

del = (end4[1].z-end2plus[0].z)+0.1
del2 = (pn1.z-pn0.z)
ptc0 = end4[1]
ptc1 = ptc0 & ptc1.z = ptc0.z+0.1
ptc2 = ptc1 & ptc2.r = pn0.r-0.1 & ptc2.z = pn0.z+del+0.05
ptc3 = ptc2 & ptc3.z = ptc2.z+del2 & ptc3.r = pn0.r-0.03
ptc4 = ptc3 & ptc4.r = pn2.r+0.03
;ptc5 = ptc4 & ptc5.r = ptc4.r+0.28 & ptc5.z = ptc0.z+0.05
ptc5 = ptc4 & ptc5.r = 1.8 & ptc5.z = ptc0.z
ptc6 = ptc5 & ptc6.z = ptc5.z+0.5
ptc7 = ptc6 & ptc7.r = 0
topcap = [pc4,ptc0,ptc1,ptc2,ptc3,ptc4,ptc5,ptc6,ptc7]


;Filled regions

add_bndry_reg,det,[pc3,pc1,pc1minus,pc3minus],1,pot=pot[arc1.n],mirror=mirror
add_bndry_reg,det,[pc1sp,pc1spminus],1,pot=pot[arc1sp.n],mirror=mirror
add_bndry_reg,det,[pc2sp,pc2spplus],1,pot=pot[arc2sp.n],mirror=mirror
add_bndry_reg,det,[pc2,pc2plus],1,pot=pot[arc2.n],mirror=mirror
add_bndry_reg,det,[pc5,pc5plus],1,pot=pot[arc5.n],mirror=mirror
add_bndry_reg,det,[end5(1),end5plus(1)],1,pot = pot[arc5.n],mirror=mirror
add_bndry_reg,det,[pc6,pc6plus],1,pot=pot[arc6.n],mirror=mirror
add_bndry_reg,det,[end6(1),end6plus(1)],1,pot = pot[arc6.n],mirror=mirror
add_bndry_reg,det,topcap,1,pot=pot[arc4.n],mirror=mirror
add_bndry_reg,det,box,1,pot=pot[p1.n],mirror=mirror
add_bndry_reg,det,mcp,3,mirror=mirror
add_bndry_reg,det,plate,-1,mirror=mirror,pot=pot(pl0.n)
add_bndry_reg,det,notch,1,pot=pot[arc2.n],mirror=mirror


;Ends of deflectors

add_bndry_curve,det,[end1[1],end1minus[1]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end1sp[1],end1spminus[1]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end1sp[0],end1spminus[0]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end2[1],end2plus[1]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end2sp[1],end2spplus[1]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end2sp[0],end2spplus[0]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end2[0],end2plus[0]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end5[1],end5plus[1]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end5[0],end5plus[0]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end6[1],end6plus[1]],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[end6[0],end6plus[0]],mirror=mirror,accum=apts,print=print


;Parallel deflector arcs (w/ voltage correction for parallel arcs)

add_bndry_arc,det,arc3,arc4,mirror=mirror,accum=apts,print=print,curvature=+1
add_bndry_arc,det,arc4,arc3,mirror=mirror,accum=apts,print=print,curvature=-1
add_bndry_arc,det,arc1,arc2,mirror=mirror,accum=apts,print=print,curvature=+1
add_bndry_arc,det,arc2,arc1,mirror=mirror,accum=apts,print=print,curvature=-1
add_bndry_arc,det,arc1sp,arc2sp,mirror=mirror,accum=apts,print=print,curvature=+1
add_bndry_arc,det,arc2sp,arc1sp,mirror=mirror,accum=apts,print=print,curvature=-1


;voltage correction for pixelized arcs 

dv_corr= (det.scale ge .05) ? 0.d : 2.5d
add_bndry_arc,det,arc2plus,dv_corr=+dv_corr,mirror=mirror,accum=apts,print=print
add_bndry_arc,det,arc2spplus,dv_corr=+dv_corr,mirror=mirror,accum=apts,print=print
add_bndry_arc,det,arc1minus,dv_corr=-dv_corr,mirror=mirror,accum=apts,print=print
add_bndry_arc,det,arc1spminus,dv_corr=-dv_corr,mirror=mirror,accum=apts,print=print
add_bndry_arc,det,arc3minus,dv_corr=-dv_corr,mirror=mirror,accum=apts,print=print
add_bndry_arc,det,arc5plus,dv_corr=+dv_corr,mirror=mirror,accum=apts,print=print
add_bndry_arc,det,arc5,dv_corr=-dv_corr,mirror=mirror,accum=apts,print=print
add_bndry_arc,det,arc6plus,dv_corr=+dv_corr,mirror=mirror,accum=apts,print=print
add_bndry_arc,det,arc6,dv_corr=-dv_corr,mirror=mirror,accum=apts,print=print

;edges of various pieces

add_bndry_curve,det,box,mirror=mirror,accum=apts,print=print
add_bndry_curve,det,plate,mirror=mirror,accum=apts,print=print
add_bndry_curve,det,exit_grid,mirror=mirror,accum=apts,print=print
;add_bndry_curve,det,exit_grid2,mirror=mirror,accum=apts,print=print
add_bndry_curve,det,notch,mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[ptc0,ptc1,ptc2,ptc3,ptc4,ptc5,ptc6,ptc7],mirror=mirror,accum=apts,print=print


;outer grids
grid10 = {point, 3, rinnergrid, 0.0}
grid10m = grid10 & grid10m.z = -0.25
grid11 = grid10 & grid11.z = cantop
grid20 = {point, 3, routergrid, 0.0}
gridm = grid10 & gridm.r = (grid10.r+grid20.r)/2. 
gridm2 = gridm & gridm2.z = 0.0
gridm3 = gridm & gridm3.z = cantop
grid20p = grid20 & grid20p.z = -0.25
p2p1 = p2 & p2p1.z = -0.25 & p2p2 = p2p1 & p2p2.z = -1.0
grid21 = grid20 & grid21.z = cantop
grid21p = grid21 & grid21p.z = grid21.z+thickness2
cancenter = grid21 & cancenter.r = 0.0
cancenterp = cancenter & cancenterp.z = cancenter.z+thickness2
toftop = grid10 & toftop.r = toftoprflange & toftop.z = -0.25-thickness2
toftop2 = toftop & toftop2.z = toftop.z-thickness2
toftop3 = toftop2 & toftop3.r = toftopr
toftop4 = toftop3 & toftop4.z = -1.0
p2p1m = p2p1 & p2p1m.z = p2p1.z-thickness2
grid20pm = grid20p & grid20pm.z = grid20p.z-thickness2

add_bndry_curve,det,[grid10,grid11],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[grid20,grid21],mirror=mirror,accum=apts,print=print
;add_bndry_curve,det,[gridm,gridm3],mirror=mirror,accum=apts,print=print

add_bndry_curve,det,[p2p1,grid10m,grid10,gridm,gridm2,grid20,grid20p,toftop,toftop2,toftop3,toftop4,p2p2],mirror=mirror,accum=apts,print=print
add_bndry_curve,det,[p2p1m,grid20pm],mirror=mirror,accum=apts,print=print
add_bndry_reg,det,[p2p1,grid10m,grid10,gridm,gridm2,grid20,grid20p,toftop,toftop2,toftop3,toftop4,p2p2],1,pot=pot[arc2.n],mirror=mirror
add_bndry_curve,det,[cancenter,grid21,grid21p,cancenterp],mirror=mirror,accum=apts,print=print
add_bndry_reg,det,[cancenter,grid21,grid21p,cancenterp],1,pot=pot[arc2.n],mirror=mirror


;Element points

rapts = apts
rapts.r = -rapts.r
str_element,/add,det,'pts',[apts,rapts]


;symmetrize

r0 = det.origin[0]
det.phi[0:r0-1,*] = rotate(det.phi[r0+1:*,*],5)
det.reg[0:r0-1,*] = rotate(det.reg[r0+1:*,*],5)
det.bndb[0:r0-1,*] = rotate(det.bndb[r0+1:*,*],5)
det.roi[0:r0-1,*] = rotate(det.roi[r0+1:*,*],5)


;calculate for all but the edge rows

det.roi = det.roi*0.+1
det.roi(0,*) = 0
det.roi(*,0) = 0
det.roi(n_elements(det.rv)-1,*) = 0
det.roi(*,n_elements(det.zv)-1) = 0

return,det

end

