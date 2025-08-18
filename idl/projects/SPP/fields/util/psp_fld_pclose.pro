;+
; psp_fld_pclose
;
; :Purpose:
;   Wrapper for the SPEDAS 'pclose' function, used to close the
;   encapsulated PostScript file and convert it to PDF/PNG format. Used
;   for creating plots in PSP/FIELDS SOC routines.
;
;   This function requires the 'gs' command-line utility to be
;   installed and accessible in the system's PATH for converting EPS
;   to PDF, and the "pdftoppm" or "sips" utility for converting PDF to PNG/JPEG.
;   The function currently only works on Linux and macOS systems due to
;   the above dependencies.
;
; :Keywords:
;   keep_eps: in, optional, boolean
;     If true, keep the original EPS file after conversion. By default,
;     the EPS file is deleted.
;   png: in, optional, boolean
;     If true, convert the EPS file to PNG format. By default,
;     the PNG file is not created.
;   round_eps: in, optional, boolean
;     If true, edit the EPS file before conversion to use rounded
;     line caps and joins. True by default.
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-07-24 13:40:33 -0700 (Thu, 24 Jul 2025) $
; $LastChangedRevision: 33495 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/psp_fld_pclose.pro $
;
;-

pro psp_fld_pclose, png = png, keep_eps = keep_eps, $
  round_eps = round_eps
  compile_opt idl2

  @popen_com.pro

  if n_elements(round_eps) eq 0 then round_eps = 1

  pclose

  !p = old_plot
  !x.thick = !p.thick
  !y.thick = !p.thick
  !z.thick = !p.thick

  filename = old_fname.replace('\', '')

  gs_eps = file_search(filename, /expand_env)

  gs_pdf = gs_eps.replace('.eps', '.pdf')
  gs_png = gs_eps.replace('.eps', '')

  gs_jpg = gs_eps.replace('.eps', '')

  spawn, 'which gs', gs_found

  if strmid(gs_found, 0, 1) eq '/' then begin
    cd, file_dirname(filename), current = old_dir

    if getenv('HOSTNAME') eq 'spfdata2' then begin
      spawn, "sed -i '/Helvetica/d' " + gs_eps
    end

    if n_elements(round_eps) eq 1 then begin
      spawn, "sed -i '' 's/setlinewidth 1 setlinecap/setlinewidth/g' '" + gs_eps + "'"
      spawn, "sed -i '' 's/setlinewidth/setlinewidth 1 setlinecap 1 setlinejoin/g' '" + gs_eps + "'"
    end

    spawn, 'gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dEPSCrop -dSAFER -dNoOutputFonts -sOutputFile="' + gs_pdf + '" "' + gs_eps + '"'

    ; note: gs as above is much better than epstopdf or ps2pdf
    ; spawn, 'epstopdf ' + filename + '.eps '
    ; spawn, 'ps2pdf -dPDFSETTINGS=/prepress -dEPSCrop -dNOPAUSE ' + gs_eps

    if n_elements(png) eq 1 then begin
      ; Using sips + convert is faster on a Mac

      ; spawn, 'sips -Z 3000 -s format png ' + filename + '.pdf --out ' + filename + '.png'
      ; spawn, 'sips -Z 1000 -s format jpeg -s formatOptions high ' + filename + '.pdf --out ' + filename + '.jpg'
      ;
      ; spawn, 'convert -background white -alpha remove ' + filename + '.png ' + filename + '.png

      ; trying for a better mix of quality vs. file size, and an option that works on Linux:
      ; spawn, 'convert -background white -alpha off ' + convert_str + ' ' + gs_pdf + ' ' + gs_png

      ; pdftoppm conversion to jpeg and png seems to be faster and gives
      ; smaller file sizes at similar quality

      ; making jpegs for quicklook (because they are smaller) but for
      ; files where small size is not a priority, stick with png

      if getenv('HOSTNAME') eq 'spfdata2' then begin
        spawn, 'pdftoppm -singlefile -f 1 -r 200 "' + gs_pdf + '" "' + gs_png + '" -jpeg'
      endif else if getenv('USER') eq 'spfuser' then begin
        spawn, 'sips -Z 3000 -s format png "' + gs_pdf + '" --out "' + gs_png + '.png"'
      endif else begin
        spawn, 'pdftoppm -singlefile -f 1 -r 200 "' + gs_pdf + '" "' + gs_png + '" -png'
      endelse
    end

    if n_elements(keep_eps) eq 0 then file_delete, filename, /allow_nonexistent

    cd, old_dir
  end
end
