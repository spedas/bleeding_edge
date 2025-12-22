pro pfcgui_event, e

if widget_info(e.id, /NAME) NE 'DROPLIST' then begin
    widget_control, e.id, get_value=v, get_uvalue=u
endif else begin
    widget_control, e.id, get_uvalue=u
endelse

case u.name of
    'orbit': begin
        ;; Store orbit epoch in tmin, tmax fields.  Remember last
        ;; edited field.
        widget_control, /hourglass
        epoch_start = get_orbfile_epoch(v, orbit_file=orbit_file)
        epoch_end = get_orbfile_epoch(v+1, orbit_file=orbit_file)
        epoch_strings = time_to_str([epoch_start, epoch_end])
        widget_control, u.tmin, set_value=epoch_strings(0)
        widget_control, u.tmax, set_value=epoch_strings(1)
        widget_control, u.ts, set_uvalue='orbit'
    end
    'tmin': begin
        ;; Recalculate orbit
        widget_control, /hourglass
        new_tmin_dbl = str_to_time(v)
        widget_control, u.orbit, set_value=what_orbit_is(new_tmin_dbl+10d)
        ;;widget_control, u.tmax, set_value=time_to_str(new_tmin_dbl + 7990d)
        widget_control, u.ts, set_uvalue='tmin'
    end
    'tmax': widget_control, u.ts, set_uvalue='tmax'
    'xmark': begin
        ;; Set tmin, tmax to either side of Xmark
        ;; Recalculate orbit at Xmark
        widget_control, /hourglass
        widget_control, u.orbit, set_value=what_orbit_is(v)
        new_xmark_dbl = str_to_time(v)
        epoch_strings = time_to_str([new_xmark_dbl-3995d, new_xmark_dbl+3995d])
        widget_control, u.tmin, set_value=epoch_strings(0)
        widget_control, u.tmax, set_value=epoch_strings(1)
        widget_control, u.ts, set_uvalue='xmark'
    end
    'station': begin
        ;; Update lat, lng fields to station coordinates
        widget_control, u.view, get_uvalue=view_uvalue
        new_lat = view_uvalue.citylat(e.index)
        new_lng = view_uvalue.citylng(e.index)
        widget_control, view_uvalue.lat, set_value=new_lat
        widget_control, view_uvalue.lng, set_value=new_lng
    end
    'lat': begin
        widget_control, u.view, get_uvalue=view_uvalue
        widget_control, view_uvalue.station, set_droplist_select=9
    end
    'lng': begin
        widget_control, u.view, get_uvalue=view_uvalue
        widget_control, view_uvalue.station, set_droplist_select=9
    end
    'rot': begin
        widget_control, u.view, get_uvalue=view_uvalue
        widget_control, view_uvalue.station, set_droplist_select=9
    end
    'output': begin
        ;; Save PS name if selected
        if e.select EQ 1 AND e.value EQ 1 then begin
            widget_control, u.disp, get_uvalue=post
            post = dialog_pickfile(file=post, $
                                   filter='*.ps', $
                                   group=e.id, $
                                   title='Select Postscript File to Write')
            post_ext = str_sep(post, '.')
            post_sect = n_elements(post_ext)
            if post_sect GT 1 then begin
                if post_ext(n_elements(post_ext)-1) EQ 'ps' then $
                  post = (reform(post_ext[0:post_sect-2], 1))(0)
            endif
            print, 'POST: ' + post
            widget_control, u.disp, set_uvalue=post
        endif
    end
    'gif': begin
        ;; Capture
        set_plot, 'X'
        @startup
        widget_control, u.draw, get_value=win_num
        old_window = !d.window
        wset, win_num
        tvlct, /get, red, green, blue
        giffile = dialog_pickfile(file='cross.gif', $
                                  filter='*.gif', $
                                  group=e.id, $
                                  title='Select GIF File to Write')
        widget_control, /hourglass
        if giffile NE '' then begin
            wshow
            write_gif, giffile, tvrd(), red, green, blue
        endif
        wset, old_window
    end
    'plot': begin
        ;; Collect info for all keyword settings
        ;; Timespan setting
        widget_control, u.ts, get_uvalue=tset
        case tset of
            'orbit': begin
                widget_control, u.orbit, get_value=plot_orbit
                plot_tmin = ''
                plot_tmax = ''
                plot_xmark = ''
            end
            'tmin': begin
                widget_control, u.tmin, get_value=plot_tmin
                widget_control, u.tmax, get_value=plot_tmax
                plot_xmark = ''
                plot_orbit = 0
            end
            'tmax': begin
                widget_control, u.tmin, get_value=plot_tmin
                widget_control, u.tmax, get_value=plot_tmax
                plot_xmark = ''
                plot_orbit = 0
            end
            'xmark': begin
                widget_control, u.xmark, get_value=plot_xmark
                plot_orbit = 0
                plot_tmin = ''
                plot_tmax = ''
            end
        endcase
        ;; Viewpoint
        plot_station = widget_info(u.station, /droplist_select)
        if plot_station EQ 0 then plot_north=1 $
        else if plot_station EQ 1 then plot_south=1 $
        else begin
            widget_control, u.lat, get_value=plot_lat
            widget_control, u.lng, get_value=plot_lng
            widget_control, u.rot, get_value=plot_rot
            plot_coord = [plot_lat, plot_lng, plot_rot]
        endelse
        ;; Display
        widget_control, u.color, get_value=plot_color
        plot_fill = plot_color(0)
        plot_grey = plot_color(1)
        if NOT plot_grey then begin
            @startup
        endif
        ;; Special settings
        widget_control, u.special, get_value=plot_special
        plot_drag = plot_special(0)
        plot_polar = plot_special(1)
        ;; Auroral activity
        plot_activity = widget_info(u.activity, /droplist_select)
        ;; Output
        widget_control, u.output, get_value=plot_is_post
        old_window = !d.window
        if (plot_is_post) then begin
            widget_control, u.disp, get_uvalue=plot_post
        endif else begin
            plot_post=''
            set_plot, 'X'
            widget_control, u.draw, get_value=win_num
            wset, win_num
        endelse
        ;; Now make the plot
        widget_control, /hourglass
        plot_fa_crossing, $
          orbit=plot_orbit, $
          tmin=plot_tmin, $
          tmax=plot_tmax, $
          xmark=plot_xmark, $
          south=plot_south, $
          view=plot_coord, $
          fill=plot_fill, $
          grey=plot_grey, $
          post=plot_post, $
          drag=plot_drag, $
          polar=plot_polar, $
          activity=plot_activity
        ;; Reset Window
        if !d.name EQ 'X' then wset, old_window
    end
    'quit': widget_control, e.top, /destroy
    else:
endcase


END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro pfcgui

;; Base widget layout

pfc = widget_base(title='FAST Crossing', /row)
form = widget_base(pfc, /col)
label = widget_label(form, /align_center, value='Hit Enter in fields after editing.')
ts = widget_base(form, /col, /frame, uvalue='orbit')
view = widget_base(form, /col, /frame)
locations = ['North','South','Poker','Kiruna','Santiago','Wallops','Mcmurdo','Canberra','Berkeley','-']
station = widget_droplist(view, value=locations, title='STATION:')
point = widget_base(view, /col, /align_right)
disp = widget_base(form, /col, /frame, uvalue='plot.ps')
adv = widget_base(form, /col, /frame)
ctrl = widget_base(form, /row)

;; Timespan widgets

orbit = cw_field(ts, /long, /return_events, title='ORBIT:', xsize=5)
tmm = widget_base(ts, /col, /frame)
tmin = cw_field(tmm, /string, /return_events, title='Tmin:', xsize=19)
tmax = cw_field(tmm, /string, /return_events, title='Tmax:', xsize=19)
xmark = cw_field(ts, /string, /return_events, title='Xmark', xsize=19)

;; Viewpoint widgets

lng = cw_field(point, /float, /return_events, title='Lat:', xsize=9)
lat = cw_field(point, /float, /return_events, title='Lng:', xsize=9)
rot = cw_field(point, /float, /return_events, title='Rot:', xsize=9)

citylng = [0.0,0.0,-147.85,21.067,-70.667,-75.4,166.62,149.167,-122.2,0.0]
citylat = [90.0,-90.0,64.8,67.883,-33.433,37.9,-77.85,-35.35,37.9,0.0]
widget_control, view, set_uvalue={lat:lat, $
                                  lng:lng, $
                                  station:station, $
                                  citylat:citylat, $
                                  citylng:citylng}

;; Display widgets

color = cw_bgroup(disp, ['Filled', 'Grey'], /nonexclusive, /row, label_left='COLOR:')
output = cw_bgroup(disp, ['Screen', 'PS file'], /exclusive, /row, label_left='OUTPUT:')

;; Advanced section

special = cw_bgroup(adv, ['Drag', 'POLAR'], /nonexclusive, /row, label_left='ADVANCED:')
activity = widget_droplist(adv, value=strtrim(indgen(7), 2), title='Auroral Activity:')

;; Draw widget

draw = widget_draw(pfc, xsize=640, ysize=fix(640*1.031))

;; Control widgets

plot = widget_button(ctrl, value='PLOT', uvalue={name:'plot', $
                                                 ts:ts, $
                                                 orbit:orbit, $
                                                 tmin:tmin, $
                                                 tmax:tmax, $
                                                 xmark:xmark, $
                                                 station:station, $
                                                 lat:lat, $
                                                 lng:lng, $
                                                 rot:rot, $
                                                 color:color, $
                                                 output:output, $
                                                 disp:disp, $
                                                 special:special, $
                                                 activity:activity, $
                                                 draw:draw})
gif = widget_button(ctrl, value='GIF', uvalue={name:'gif', draw:draw})
quit = widget_button(ctrl, value='QUIT', uvalue={name:'quit'})

;; Realize the widgets

widget_control, pfc, /realize

;; Fill form with default values and set user values.
;; Timespan

current_orbit=strtrim(what_orbit_is(systime(1)), 2)
orbit_file = fa_almanac_dir() + '/orbit/predicted'
if (findfile(orbit_file))(0) EQ '' then message, 'File not found: '+orbit_file

widget_control, orbit, set_value=current_orbit, $
  set_uvalue={name:'orbit', $
              tmin:tmin, $
              tmax:tmax, $
              xmark:xmark, $
              ts:ts}
widget_control, tmin, $
  set_value=time_to_str(get_orbfile_epoch(current_orbit, orbit_file=orbit_file)), $
  set_uvalue={name:'tmin', $
              orbit:orbit, $
              tmax:tmax, $
              xmark:xmark, $
              ts:ts}
widget_control, tmax, $
  set_value=time_to_str(get_orbfile_epoch(current_orbit + 1, orbit_file=orbit_file)), $
  set_uvalue={name:'tmax', $
              orbit:orbit, $
              tmin:tmin, $
              xmark:xmark, $
              ts:ts}
widget_control, xmark, set_uvalue={name:'xmark', $
                                   orbit:orbit, $
                                   tmin:tmin, $
                                   tmax:tmax, $
                                   ts:ts}

;; Viewpoint


widget_control, lat, set_value=citylat(0), set_uvalue={name:'lat', view:view}
widget_control, lng, set_value=citylng(0), set_uvalue={name:'lng', view:view}
widget_control, rot, set_value=0.0, set_uvalue={name:'rot', view:view}
widget_control, station, set_droplist_select=0, set_uvalue={name:'station', view:view}

;; Color scheme and output

widget_control, color, set_value=[1,0], set_uvalue={name:'color'}
widget_control, output, set_value=0, set_uvalue={name:'output', disp:disp}

;; Advanced settings

widget_control, special, set_value=[1,0], set_uvalue={name:'special'}
widget_control, activity, set_droplist_select=3, set_uvalue={name:'activity'}

;; Vivify widget

xmanager, 'pfcgui', pfc, /no_block

END
