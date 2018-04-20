;+
; PROCEDURE:  
;       mms_add_cdf_versions
;       
; PURPOSE:
;       Adds MMS CDF version #s to plots (for version tracking)
;       
; INPUT:
;       instrument: name of the instrument that we're adding the version #s for
;       versions: [n, 3] array of CDF version #s - returned by 'versions' keyword 
;           in load routines; where n is the number of CDF files loaded
; 
; KEYWORDS:
;       data_rate: include a data rate on the plot
;       right_align: start placing version #s strings to the bottom right of the 
;           plot instead of the bottom left
;       top_align:  start placing version #s strings on the top of the figure
;           instead of the bottom
;       charsize: character size; default is 1
;       
; EXAMPLE:
;       MMS> mms_load_fpi, versions=fpi_versions
;       MMS> tplot, 'mms3_des_energyspectr_par_fast'
;       MMS> mms_add_cdf_versions, 'fpi', fpi_versions
;
; NOTES:
;       1) Requires IDL 8.0+ to work
;       
;       2) the default location of the version #s is the bottom left; 
;          you can change this using the /right and /top keywords
;      
;       3) does not include duplicate version #s for the same instrument
;          e.g., if you load FPI data from 7 v2.1.0 files, only one 'FPI v2.1.0'
;          will be included
;       
;       
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-04-19 11:41:45 -0700 (Thu, 19 Apr 2018) $
; $LastChangedRevision: 25080 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cdf/mms_add_cdf_versions.pro $
;-

pro mms_add_cdf_versions, instrument, versions, data_rate = data_rate, right_align=right_align, $
    top_align=top_align, charsize=charsize
    ; so we don't overplot the version #s for different instruments
    common plotcdfversions, top_right_versionnum_loc, top_left_versionnum_loc, bot_right_versionnum_loc, bot_left_versionnum_loc
    if undefined(charsize) then chsize = 1 else chsize = charsize
    
    if undefined(instrument) then begin
        dprint, dlevel = 0, 'Instrument name required to add version #s to a plot'
        return
    endif
    if undefined(versions) then begin
      dprint, dlevel = 0, instrument + ': Array of version #s required'
      return
    endif
    
    ; make sure versions isn't full of 0s (occurs when no data were loaded)
    where_not_zeroes = where(versions ne 0, nonzerocount)
    if nonzerocount eq 0 then return

    ; we won't include duplicate version #s
    dupekill = hash()
    for version_idx = 0, n_elements(versions[*, 0])-1 do begin
        version_str = strcompress(string(versions[version_idx, 0]), /rem) + '.' + $
          strcompress(string(versions[version_idx, 1]), /rem) + '.' + $
          strcompress(string(versions[version_idx, 2]), /rem)
        dupekill[version_str] = 1
    endfor
    versions_nodupes = (dupekill.keys()).toArray()
    
    plot_pos = plot_positions()
    
    yp = keyword_set(top_align) ? !y.window[0] + 0.02 : !y.window[0] + 0.01

    ; x-location to start printing the version # at
    if keyword_set(top_align) and keyword_set(right_align) then begin ; top right
      top_right_versionnum_loc = undefined(top_right_versionnum_loc) ? 0.01 : top_right_versionnum_loc + 0.01
      versionnum_loc = top_right_versionnum_loc
    endif else if keyword_set(top_align) and ~keyword_set(right_align) then begin ; top left
      top_left_versionnum_loc = undefined(top_left_versionnum_loc) ? 0.01 : top_left_versionnum_loc + 0.01
      versionnum_loc = top_left_versionnum_loc
    endif else if ~keyword_set(top_algin) and keyword_set(right_align) then begin ; bottom right
      bot_right_versionnum_loc = undefined(bot_right_versionnum_loc) ? 0.01 : bot_right_versionnum_loc + 0.01
      versionnum_loc = bot_right_versionnum_loc
    endif else begin ; bottom left
      bot_left_versionnum_loc = undefined(bot_left_versionnum_loc) ? 0.01 : bot_left_versionnum_loc
      versionnum_loc = bot_left_versionnum_loc
    endelse

    ; create an array of version strings for this instrument
    for version_idx = 0, n_elements(versions_nodupes)-1 do append_array, version_strs, 'v' + versions_nodupes[version_idx]
    
    version_strs = version_strs[sort(version_strs)]
    plot_str = ''

    for vi=0, n_elements(version_strs)-1 do begin
      if vi eq n_elements(version_strs)-1 then plot_str = plot_str + version_strs[vi] else $
       plot_str = plot_str + version_strs[vi] + ', '
    endfor

    plot_str = undefined(data_rate) ? strupcase(instrument) + ' ' + plot_str : strupcase(instrument) + ' ' + data_rate + ' ' + plot_str
    
    len_in_px = strlen(plot_str)*!d.x_ch_size

    xyouts,abs(keyword_set(right_align)-versionnum_loc),abs(keyword_set(top_align)-yp), plot_str, charsize=chsize, /norm, alignment=keyword_set(right_align)
    
    if keyword_set(top_align) and keyword_set(right_align) then begin ; top right
      top_right_versionnum_loc += len_in_px/float(!d.x_size)
    endif else if keyword_set(top_align) and ~keyword_set(right_align) then begin ; top left
      top_left_versionnum_loc += len_in_px/float(!d.x_size)
    endif else if ~keyword_set(top_algin) and keyword_set(right_align) then begin ; bottom right
      bot_right_versionnum_loc += len_in_px/float(!d.x_size)
    endif else begin ; bottom left
      bot_left_versionnum_loc += len_in_px/float(!d.x_size)
    endelse
end