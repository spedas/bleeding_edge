;+
;Procedure: elf_map_state_t96_wrapper
;
;PURPOSE:
;  Routine just wraps elf_map_state_t96(north and south tracing variants). Making separate
;  calls for each type of overview interval. Mainly used to reprocess.
;
;INPUT: 
;  Date: date for plot creation, if not set, assumes current date and duration counts backwards(ie last N days from today)
;
;KEYWORDS:
;  dur:        If set, number of days to process, default is 1
;  south_only: If set, does tracing to southern hemisphere only
;  north_only: If set, does tracing to northern hemisphere only
;              The default value is to plot both north and south
;  pred:       Set this flag to use predicted data and title to predicted
;  sm:         Set this flag to create plots in sm coordinates (default is geo)
;  bfirst:     Set this flag to plot b on top of a (default is a on top of b)
;  do_all:     Set this flag to create all plots (north, south, geo, sm, a on b, and b on a)      
;            
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-07-31 14:50:02 -0700 (Tue, 31 Jul 2012) $
; $LastChangedRevision: 10758 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/thmsoc/asi/map_themis_state_t96_wrapper.pro $
;-
pro elf_map_state_t96_intervals_wrapper,date,dur=dur,south_only=south_only, $
   north_only=north_only, pred=pred, insert_stop=insert_stop, sm=sm, bfirst=bfirst, $
   do_all=do_all

  compile_opt idl2

  ; Initialize variables and parameters if needed
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init
  if ~keyword_set(dur) then begin
    dur = 1
  endif
  if n_params() eq 0 then begin
    ts = time_struct(systime(/seconds)-dur*60.*60.*24)
    ;form time truncated datetime string
    date = num_to_str_pad(ts.year,4) + '-' + num_to_str_pad(ts.month,2) + '-' + num_to_str_pad(ts.date,2)
  endif
  dir_products=!elf.local_data_dir + 'gtrackplots'
  if ~keyword_set(pred) then pred=0 else pred=1

  if undefined(date) then date=systime()
    
  dprint,"Processing start time " + time_string(systime(/seconds)) + ' UT'
  dprint,"Generating ELFIN T96 Maps for date " + date + " with duration " + strtrim(dur,2) + " days."

  in_date = time_double(date)
  elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/one_hour_only
  ; create plots for each day
  for j = 0,dur-1 do begin
    in_date = time_double(date)+j*60.*60.*24.
    if keyword_set(north_only) then begin
      elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace
      elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/no_trace,/hires
      elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/sm
      elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/sm,/no_trace,/hires
    endif
    if keyword_set(south_only) then begin
     elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace
     elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/no_trace,/hires
    endif
    if ~keyword_set(north_only) AND ~keyword_set(south_only) then begin
      if keyword_set(do_all) then begin
        ; handle north first
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/no_trace,/hires
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/sm
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/no_trace,/sm,/hires
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/no_trace,/sm,/bfirst
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/no_trace,/sm,/bfirst,/hires
       ; now south
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/no_trace,/hires
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/sm
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/no_trace,/sm,/hires
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/no_trace,/sm,/bfirst
        elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/no_trace,/sm,/bfirst,/hires        
        ; now mercator
        elf_map_state_t96_intervals_mercator,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace
        elf_map_state_t96_intervals_mercator,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/no_trace,/hires        
      endif else begin
        if ~keyword_set(sm) then begin
          elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace
          elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/no_trace,/hires
          elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace
          elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/no_trace,/hires
        endif else begin
          if ~keyword_set(bfirst) then begin
            elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/sm
            elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/no_trace,/hires,/sm
            elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/sm
            elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/no_trace,/hires,/sm
          endif else begin
            elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/sm,/bfirst
            elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/quick_trace,/no_trace,/hires,/sm,/bfirst
            elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/sm,/bfirst
            elf_map_state_t96_intervals,time_string(in_date),/gif,/tstep,/noview,dir_move=dir_products,/south,/quick_trace,/no_trace,/hires,/sm,/bfirst          
          endelse
        endelse
      endelse
    endif
  endfor

end
