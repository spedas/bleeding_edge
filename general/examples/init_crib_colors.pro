;+
;NAME: init_crib_colors
;
;PURPOSE: Sets default plotting colors.
;
;        *This is not a crib sheet*
;        
;        Defaults to black pen on white background, rainbow color scheme.
;
;ARGUMENTS:   
;   color_table: Index specifying the desired color table to be passed to LOADCT2
;
;-

pro init_crib_colors, color_table
    compile_opt idl2, hidden
    
    if n_elements(color_table) eq 0 then color_table = 43 ; default color table
    
    ; Color table for ordinary windows
    loadct2,color_table
    
    ; Make black on white background
    !p.background = !d.table_size-1                   ; White background
    !p.color=0                                        ; Black Pen
    !p.font = -1                                      ; Use default fonts
    
    if !d.name eq 'WIN' then begin
        device,decomposed = 0
    endif

    if !d.name eq 'X' then begin
        device,decomposed = 0
        if !version.os_family eq 'unix' then device,retain=2  ; Unix family does not provide backing store by default
    endif
end  