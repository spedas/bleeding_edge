; b1_status_crib.pro
;
; NOTES:
;   - run with IDL> .run b1_status_crib
;
; Created by Kris Kersten, kris.kersten@gmail.com
;
;
;$LastChangedBy: aaronbreneman $
;$LastChangedDate: 2014-01-31 13:21:37 -0800 (Fri, 31 Jan 2014) $
;$LastChangedRevision: 14107 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/b1_status_crib.pro $


output_dir='~/Desktop/'

rbsp_efw_init,remote_data_dir='http://rbsp.space.umn.edu/data/rbsp/'

tnow=systime(1)
tstart=tnow-30.*86400 ; run previous 30 days

timespan,tstart,30

probe='a b'

; burst times update daily at ~10:15 Central time
rbsp_load_efw_burst_times
rbsp_load_efw_b1,probe=probe

options,'rbsp?_efw_b1_fmt_B1_available','labels','B1 onboard'
options,'rbsp?_efw_vb1_available','labels','B1 playback'
options,'rbsp?_efw_vb1_available','thick',4


store_data,'rbspa_b1_status',$
	data=['rbspa_efw_b1_fmt_B1_available','rbspa_efw_vb1_available']
store_data,'rbspb_b1_status',$
	data=['rbspb_efw_b1_fmt_B1_available','rbspb_efw_vb1_available']
ylim,'rbsp?_b1_status',0,1.1


copy_data,'rbspa_efw_b1_fmt_block_index','rbspa_efw_b1_fmt_block_index2'
options,'rbspa_efw_b1_fmt_block_index','psym',0
options,'rbspa_efw_b1_fmt_block_index2','psym',4


get_data,'rbspa_efw_b1_fmt_block_index',data=bi
nbi=n_elements(bi.y)
bi_cutoff=bi.y[nbi-1]
store_data,'rbspa_efw_b1_fmt_block_index_cutoff',$
	data={x:[bi.x[0],bi.x[nbi-1]],y:[bi_cutoff,bi_cutoff]}
options,'rbspa_efw_b1_fmt_block_index_cutoff','linestyle',1

; get the time range for A
;tmaxa=bi.x[nbi-1]+14400.
goodbi=where(bi.y gt bi_cutoff)
tmina=bi.x[goodbi[50]]-14400. ; use the 50th goodbi to avoid old block index at the beginning of the array



;----------------

copy_data,'rbspb_efw_b1_fmt_block_index','rbspb_efw_b1_fmt_block_index2'
options,'rbspb_efw_b1_fmt_block_index','psym',0
options,'rbspb_efw_b1_fmt_block_index2','psym',4


get_data,'rbspb_efw_b1_fmt_block_index',data=bi
nbi=n_elements(bi.y)
bi_cutoff=bi.y[nbi-1]
store_data,'rbspb_efw_b1_fmt_block_index_cutoff',$
	data={x:[bi.x[0],bi.x[nbi-1]],y:[bi_cutoff,bi_cutoff]}
options,'rbspb_efw_b1_fmt_block_index_cutoff','linestyle',1

; get the time range for B
;tmaxb=bi.x[nbi-1]+14400.
goodbi=where(bi.y gt bi_cutoff)
tminb=bi.x[goodbi[50]]-14400.

tmin=min([tmina,tminb])
tmax=tnow

store_data,'rbspa_b1_block_index',$
	data=['rbspa_efw_b1_fmt_block_index_cutoff','rbspa_efw_b1_fmt_block_index','rbspa_efw_b1_fmt_block_index2']
store_data,'rbspb_b1_block_index',$
	data=['rbspb_efw_b1_fmt_block_index_cutoff','rbspb_efw_b1_fmt_block_index','rbspb_efw_b1_fmt_block_index2']

ylim,'rbsp?_b1_block_index',0,262143





options,['rbsp?_b1_block_index','rbspa_efw_b1_fmt_block_index',$
	'rbspa_efw_b1_fmt_block_index_cutoff'],'panel_size',.5


tplot_options,'title','RBSP B1 STATUS - '+systime(/utc)+' UTC'
tplot,['rbspa_b1_block_index','rbspa_b1_status',$
	'rbspb_b1_block_index','rbspb_b1_status']
tlimit,[tmin,tmax]


pcharsize_saved=!p.charsize
pfont_saved=!p.font
pcharthick_saved=!p.charthick
pthick_saved=!p.thick

set_plot,'Z'
rbsp_efw_init,/reset ; try to get decent colors in the Z buffer

;device,set_pixel_depth=24,set_resolution=[800,600],decomposed=0
;!p.charsize=.9
;!p.charthick=3.
;!p.font=3


;write_png,output_dir+'b1_status.png',tvrd(true=1)


device,set_resolution=[3200,2400],set_font='helvetica',/tt_font,set_character_size=[28,35]

!p.thick=4.
!p.charthick=4.

tplot_options,'xmargin',[14,12]
tplot


; take snapshot of z buffer
snapshot=tvrd()
device,/close

; convert snapshot from index colors to true colors
tvlct,r,g,b,/get

sz=size(snapshot,/dimensions)
snapshot3=bytarr(3,sz[0],sz[1])
snapshot3[0,*,*]=r[snapshot]
snapshot3[1,*,*]=g[snapshot]
snapshot3[2,*,*]=b[snapshot]

; shrink snapshot
xsize=800
ysize=600
snapshot3=rebin(snapshot3,3,xsize,ysize)

; write a png
write_png,output_dir+'b1_status.png',snapshot3

set_plot,'X'
rbsp_efw_init,/reset
!p.charsize=pcharsize_saved
!p.font=pfont_saved
!p.charthick=pcharthick_saved
!p.thick=pthick_saved


end