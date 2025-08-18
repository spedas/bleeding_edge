;+
; Name: crib_plotxyvec
;
; Purpose:crib to demonstrate capabilities of plotxyvec
;
; Notes: run it by compiling in idl and then typing ".go"
;        or copy and paste.
;
; The options:  hsize,color,hthick,solid, & thick from the arrow
;    routine are usable in this routine.
;
;;Warning: this crib uses some data from the THEMIS branch.  You'll require those routines to run this crib
;
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-12-16 17:46:48 -0800 (Mon, 16 Dec 2013) $
; $LastChangedRevision: 13689 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_plotxyvec.pro $
;-

;set the colors correctly
init_crib_colors

timespan,'2008-03-24'

thm_load_state,probe='a',coord='gsm'

;put state data in RE
tkm2re,'tha_state_pos',/replace

time_clip,'tha_state*','2008-03-24/03:00:00','2008-03-24/05:00:00',/replace

tplotxy,'tha_state_pos',title="THEMIS A Position & Velocity"

get_data,'tha_state_pos',data=d_state
get_data,'tha_state_vel',data=d_vel

;select x,y dimension
xy = d_state.y[*,0:1]
dxy = d_vel.y[*,0:1]

dim = dimen(d_state.y)

;look at only 1/5 of points(so it won't be too cluttered)
idx = indgen(dim[0]/5) * 5

xy = xy[idx,*]

dxy = dxy[idx,*]

;plot
;This example decreases the size of the arrow head with hsize
;and decrease the apparent size of the arrow with arrowscale
;NOTE: you can also use uarrowdatasize if you want the unit
;arrow to represent a different number of units.
plotxyvec,xy,dxy,/over,hsize=.2,arrowscale=.25,uarrowtext="[km/s] THEMIS A Velocity"

stop

;basic call

;these are the arrow start positions
xy = [[indgen(11)],[indgen(11)]]

;these are the arrow offsets
uv = [[intarr(11)-1],[intarr(11)+1]]

plotxyvec,xy,uv,uarrowdatasize=1.0

stop

;by default plots are isotropic

xy = [[indgen(5*7) mod 5],[indgen(5*7) / 5]]
uv = [[intarr(5*7)+.5],[intarr(5*7)-.5]]

plotxyvec,xy,uv

stop

;you can disable isotropic plotting
;note that a unit arrow is not automatically drawn
;for non-isotropic plots.  This is because the
;different axes scale differently.

plotxyvec,xy,uv,/noisotropic

stop


;you can plot multiple plots on a panel

plotxyvec,xy,uv,multi='2 1'

plotxyvec,xy+uv,-1*uv,/add,uarrowoffset=.05

stop

;you can set colors with numbers or letters

plotxyvec,xy,uv,multi='2 1',color="b"

plotxyvec,xy+uv,-1*uv,/add,color=2

stop

;you can control the margins of the plots

plotxyvec,xy,uv,multi='2 1',xmargin=[.2,.3]

plotxyvec,xy+uv,-1*uv,/add,ymargin=[.01,.1]

stop

;you can interleave these plots with others
;and plot arrows on top of other plots

plotxyvec,xy,uv,multi='3,1',xsize=900,ysize=300

plotxy,xy,/add

plotxyz,indgen(5),indgen(7),indgen(5,7),/add

plotxyvec,xy,uv,/over

stop

; you can add an overall title to a multi plot
; and adjust overall margins ([bottom, left, top, right])

plotxyvec,xy,uv,multi='3,1',xsize=900,ysize=300, mtitle='The title', mmargin=[0.1,0.1,0.1,0.1]

plotxy,xy,/add

plotxyz,indgen(5),indgen(7),indgen(5,7),/add

plotxyvec,xy,uv,/over

stop

; you can create nonsymmetrical layouts using mpanel

plotxyvec,xy,uv,multi='2,2',xsize=500,ysize=500, mtitle='The title', mmargin=[0.1,0.15,0.1,0.1]

plotxy,xy,/add

plotxyz,indgen(5),indgen(7),indgen(5,7),/add, mpanel='0:1,1', xmargin=[0.3,0.3]

plotxyvec,xy,uv,/over

stop

;you can automatically replot plots

window,xsize=600,ysize=200

plotxyvec

stop

;you can set windowing options

plotxyvec,xy,uv,window=1,xsize=700,ysize=700,wtitle="Im a new window"

stop


;you can set the range of the plot with x,y range
;/clip will clip arrows that are outside of the range
plotxyvec,xy,uv,xrange=[0,3],yrange=[2,5],/clip

stop

;you can generate a grid on the plot

plotxyvec,xy,uv,/grid,xticks=4,yticks=6

stop

;you can control the side of the plot that
;the unit arrow is placed

plotxyvec,xy,uv,uarrowside="left"

stop

;you can move the unit arrow further or closer to the plot
;you can add text
;you can change the size and color of the arrows

plotxyvec,xy,uv,uarrowside="left",uarrowoffset=.2,uarrowtext="hello",$
  hsize=.5

stop

;you can use normal plot options like xtitle, ytitle, & title

plotxyvec,xy,uv,xtitle="hello",ytitle="world",title="title demo"

stop

end