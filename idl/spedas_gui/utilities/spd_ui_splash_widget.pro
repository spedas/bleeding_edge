;+  
;NAME:
;         spd_ui_splash_widget
;
;PURPOSE:
;         Widget for the SPEDAS GUI splash screen
;
;OUTPUT:
;         ID of the widget, so it can be destroyed by the GUI 
;         on load
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-07-20 14:44:54 -0700 (Mon, 20 Jul 2015) $
;$LastChangedRevision: 18181 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_splash_widget.pro $
;-

function spd_ui_splash_widget
    base = widget_base(/col, xsize=400, ysize=150, /base_align_center, $
            title='Loading SPEDAS...')

    splash_label = widget_label(base, value='SPEDAS!', /align_center, font='Helvetica*72')
    loading_label = widget_label(base, value='Loading...', /align_center, font='Helvetica*24')
    widget_control, base, /realize
    centertlb, base
    xmanager, 'spd_ui_splash_widget', base, /no_block
    return, base
end
