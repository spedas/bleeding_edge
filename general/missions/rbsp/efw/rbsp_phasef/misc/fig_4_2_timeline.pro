;+
; Plot the data timeline.
;
; Adopted from EFW_dataproduct_timeline.py.
;-

timeline = dictionary($
    'a', dictionary(), $
    'b', dictionary() )


b2_color = sgcolor('pale_turquoise')
timeline.a['vb2'] = list()
timeline.a.vb2.add, dictionary($
    'color', b2_color, $
    'label', 'V[1-6]AC', $
    'time_range', time_double(['2012-09-05','2019-10-14']) )
timeline.b['vb2'] = list()
timeline.b.vb2.add, dictionary($
    'color', b2_color, $
    'label', 'V[1-6]AC', $
    'time_range', time_double(['2012-09-05','2019-07-16']) )

timeline.a['eb2'] = list()
timeline.a.eb2.add, dictionary($
    'color', b2_color, $
    'label', 'E[12,34,56]AC', $
    'time_range', time_double(['2013-04-25','2019-10-14']) )
timeline.b['eb2'] = list()
timeline.b.eb2.add, dictionary($
    'color', b2_color, $
    'label', 'E[12,34,56]AC', $
    'time_range', time_double(['2013-04-25','2019-07-16']) )

timeline.a['mscb2'] = list()
timeline.a.mscb2.add, dictionary($
    'color', b2_color, $
    'label', 'SCM[u,v,w]', $
    'time_range', time_double(['2012-09-05','2019-10-14']) )
timeline.b['mscb2'] = list()
timeline.b.mscb2.add, dictionary($
    'color', b2_color, $
    'label', 'SCM[u,v,w]', $
    'time_range', time_double(['2012-09-05','2019-07-16']) )

b1_color = sgcolor('light_coral')
timeline.a['eb1'] = list()
timeline.a.eb1.add, dictionary($
    'color', b1_color, $
    'label', 'E[12,34,56]DC', $
    'time_range', time_double(['2012-09-05','2013-10-09']) )
timeline.b['eb1'] = list()
timeline.b.eb1.add, dictionary($
    'color', b1_color, $
    'label', 'E[12,34,56]DC', $
    'time_range', time_double(['2012-09-06','2013-12-20']) )

timeline.a['vb1'] = list()
timeline.a.vb1.add, dictionary($
    'color', b1_color, $
    'label', 'V[1-6]DC', $
    'time_range', time_double(['2012-09-05','2019-10-14']) )
timeline.b['vb1'] = list()
timeline.b.vb1.add, dictionary($
    'color', b1_color, $
    'label', 'V[1-6]DC', $
    'time_range', time_double(['2012-09-06','2019-07-16']) )

timeline.a['mscb1'] = list()
timeline.a.mscb1.add, dictionary($
    'color', b1_color, $
    'label', 'SCM[u,v,w]', $
    'time_range', time_double(['2012-09-05','2019-10-14']) )
timeline.b['mscb1'] = list()
timeline.b.mscb1.add, dictionary($
    'color', b1_color, $
    'label', 'SCM[u,v,w]', $
    'time_range', time_double(['2012-09-06','2019-07-16']) )

l2_color = sgcolor('light_pink')
timeline.a['esvy'] = list()
timeline.a.esvy.add, dictionary($
    'color', l2_color, $
    'label', 'mGSE E[x,y,z]DC', $
    'time_range', time_double(['2012-09-23','2019-02-23']) )
timeline.b['esvy'] = list()
timeline.b.esvy.add, dictionary($
    'color', l2_color, $
    'label', 'mGSE E[x,y,z]DC', $
    'time_range', time_double(['2012-09-23','2019-07-16']) )

timeline.a['vsvy'] = list()
timeline.a.vsvy.add, dictionary($
    'color', l2_color, $
    'label', 'V[1-6]DC', $
    'time_range', time_double(['2012-09-05','2019-10-14']) )
timeline.b['vsvy'] = list()
timeline.b.vsvy.add, dictionary($
    'color', l2_color, $
    'label', 'V[1-6]DC', $
    'time_range', time_double(['2012-09-05','2019-07-16']) )

timeline.a['spec'] = list()
timeline.a.spec.add, dictionary($
    'color', l2_color, $
    'label', 'V[1,2]AC, E[12,34]AC, SCM[u,v,w]', $
    'time_range', time_double(['2012-09-05','2019-10-12']) )
timeline.b['spec'] = list()
timeline.b.spec.add, dictionary($
    'color', l2_color, $
    'label', 'V[1,2]AC, E[12,34]AC, SCM[u,v,w]', $
    'time_range', time_double(['2012-09-05','2019-07-14']) )


fbk_colors = sgcolor(['orchid','plum','light_pink'])
timeline.a['fbk'] = list()
timeline.a.fbk.add, dictionary($
    'label', 'FBK13!CE12DC', $
    'time_range', time_double(['2012-09-05','2013-03-16']) )
timeline.a.fbk.add, dictionary($
    'label', 'FBK7!CE12DC, SCMw', $
    'time_range', time_double(['2013-03-17','2018-04-13']) )
timeline.a.fbk.add, dictionary($
    'label', 'FBK13!CE34DC, SCMw', $
    'time_range', time_double(['2018-04-14','2019-10-14']) )
timeline.b['fbk'] = list()
timeline.b.fbk.add, dictionary($
    'label', 'FBK13!CE12DC', $
    'time_range', time_double(['2012-09-05','2013-03-16']) )
timeline.b.fbk.add, dictionary($
    'label', 'FBK7!CE12DC, SCMw', $
    'time_range', time_double(['2013-03-17','2018-04-13']) )
timeline.b.fbk.add, dictionary($
    'label', 'FBK13!CE34DC, SCMw', $
    'time_range', time_double(['2018-04-14','2019-07-14']) )
foreach probe, ['a','b'] do begin
    foreach fbk_color, fbk_colors, id do $
        (((timeline[probe]).fbk)[id])['color'] = fbk_color
endforeach

l3_color = sgcolor('pale_turquoise')
timeline.a['spinfit'] = list()
timeline.a.spinfit.add, dictionary($
    'color', l3_color, $
    'label', 'mGSE E[x,y,z]DC using V12', $
    'time_range', time_double(['2012-09-23','2014-12-31']) )
timeline.a.spinfit.add, dictionary($
    'color', sgcolor('aquamarine'), $
    'label', 'mGSE E[x,y,z]DC using V24', $
    'time_range', time_double(['2015-01-01','2019-02-23']) )
timeline.b['spinfit'] = list()
timeline.b.spinfit.add, dictionary($
    'color', l3_color, $
    'label', 'mGSE E[x,y,z]DC using V12', $
    'time_range', time_double(['2012-09-23','2019-07-16']) )


types = ['spinfit','fbk','spec','vsvy','esvy',$
    'vb2','mscb2','eb2','vb1','mscb1','eb1']
ntype = n_elements(types)
probes = ['a','b']
nprobe = n_elements(probes)

xrange = time_double(['2012-08','2020'])
xtickn = string(make_bins([2013,2019],1),format='(I4)')
xtickv = time_double(xtickn)
xticks = n_elements(xtickv)-1

vals = list()
foreach type, types, type_id do begin
    ystep = 0
    foreach probe, probes, probe_id do begin
        ystep += (timeline[probe])[type].length
    endforeach
    vals.add, ystep
endforeach
nval = total(vals.toarray())
yrange = [0,nval-1]+[-1,1]*1
ytickv = findgen(nval)
yticks = n_elements(ytickv)-1
ytickn = strarr(nval)+' '


margins = [8,3,1,1]

ofn = join_path([srootdir(),'fig_4_2_timeline.pdf'])
sgopen, ofn, xsize=5.5, ysize=5
tpos = sgcalcpos(1, margins=margins, xchsz=xchsz, ychsz=ychsz)
xticklen = -0.01
yticklen = -0.005
plot, xrange, yrange, $
    xstyle=1, xrange=xrange, xticks=xticks, xtickv=xtickv, xtickname=xtickn, xticklen=xticklen, $
    ystyle=1, yrange=yrange, yticks=yticks, ytickv=ytickv, ytickname=ytickn, yticklen=yticklen, $
    position=tpos, nodata=1, noerase=1

bar_thick = (size(ofn,/type) eq 7)? 30: 14
ytop = nval-1
foreach type, types, type_id do begin
    bar_coef = (type eq 'fbk')? 1.8:1
    ytop0 = ytop
    if (type eq 'fbk') then ytop0 = ytop0-0.4

    
    ; Print type.
    yy = ytop0-(vals[type_id]-1)*0.5
    tx = tpos[0]-xchsz*2.5
    if type eq 'fbk' then yy = ytop0-(vals[type_id])*0.5*0.5
    tmp = convert_coord(xrange[0],yy, /data, /to_normal)
    ty = tmp[1]-ychsz*0.3
    msg = strupcase(type)
    xyouts, tx,ty,/normal, alignment=1, msg
    
    foreach probe, probes, probe_id do begin
        info_list = (timeline[probe])[type]

        ; Print probe.
        yy = ytop0;-(info_list.length-1)*0.5
        tx = tpos[0]-xchsz*0.8
        tmp = convert_coord(xrange[0],yy, /data, /to_normal)
        ty = tmp[1]-ychsz*0.3
        msg = strupcase(probe)
        xyouts, tx,ty,/normal, alignment=1, msg, charsize=0.8
        
        ; Draw bar.
        foreach info, info_list, info_id do begin
            yy = ytop0-info_id*0.5
            xx = info.time_range
            plots, xx,yy+[0,0], thick=bar_thick*bar_coef, color=info.color
        endforeach
        
        ; Print year.
        foreach info, info_list, info_id do begin
            if info_id eq 0 then continue
            yy = ytop0-info_id*0.5
            time = info.time_range[0]
            tmp = convert_coord(time,yy, /data, /to_normal)
            xx = tmp[0]+xchsz*0.5
            yy = tmp[1]+ychsz*0.55*bar_coef
            plots, tmp[0]+[0,0],yy+[-0.5,0.5]*ychsz, /normal
            xyouts, xx,yy,/normal, alignment=0, $
                time_string(time,tformat='YYYY-MM-DD'), charsize=0.8
        endforeach
        
        ; Print label.
        foreach info, info_list, info_id do begin
            yy = ytop0-info_id*0.5
            xx = info.time_range

            tmp = convert_coord(mean(xx),yy, /data, /to_normal)
            tx = tmp[0]
            ty = tmp[1]-ychsz*0.2
            if type eq 'fbk' then ty = tmp[1]+ychsz*0.15
            xyouts, tx,ty,/normal, alignment=0.5, info.label, charsize=0.8
        endforeach
        
        ; Update ypos.
        ytop0 = ytop0-info_list.length
        ytop = ytop-info_list.length
    endforeach
    
;    ; Print year.
;    if type eq 'fbk' then begin
;        times = list()
;        foreach info, (timeline['a'])[type], info_id do begin
;            if info_id eq 0 then continue
;            times.add, info.time_range[0], /extract
;        endforeach
;        times = times.toarray()
;        tmp_y = ytop0+4
;        foreach time, times, tx_id do begin
;            tmp = convert_coord(time,tmp_y-tx_id*0.8, /data, /to_normal)
;            tx = tmp[0]
;            ty = tmp[1]
;            xyouts, tx,ty,/normal, alignment=0, time_string(time,tformat='YYYY-MM-DD'), charsize=0.8
;        endforeach
;    endif
endforeach
sgclose

end
