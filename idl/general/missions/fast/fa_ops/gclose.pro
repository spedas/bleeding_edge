;+
;PROCEDURE:   gclose
;INPUT:  none
;PURPOSE: Write GIF file named with gopen, and change device back to 
;  default.
;  If common block string 'printer_name' is set, then file is sent to that
;  printer.
;SEE ALSO: 	"print_options"
;		"gopen"
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION:	@(#)gclose.pro	1.5 95/10/06
;-

pro gclose,printer=printer
@gopen_com
print,gif_name

write_gif,gif_name,tvrd()

tvlct,g_old_r,g_old_g,g_old_b

set_plot,g_old_device
;!p.background = g_old_bckgrnd
;!p.color      = g_old_color

return
end



