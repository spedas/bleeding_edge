
pro emm_emus_mvn_joint_images, start_time, finish_time, brightness_range = brightness_range
; first choose start and ending times
  time_range = [start_time, finish_time]

; Set the local path. Note this directory must have the same structure
; as the file source kept on AWS:
;      https://mdhkq4bfae.execute-api.eu-west-1.amazonaws.com/prod/science-files-metadata?"
;      NOTE: The default will work fine for people working on the UC
;      Berkeley SSL network. A similar copy of the directory exists at
;      LASP. Please contact Justin Deighan
;      (Justin.Deighan@lasp.Colorado.edu) for information on how to
;      install the EMUS data on your local machine
  local_path = '/disks/hope/data/emm/data/'

  path = '~/work/emm/emus/data/MAVEN_EMM_joint_plots/'
; choose the emission features you'd like to examine. A full
; list of them is found in the source code emm_emus_examine_disk.pro
  emission = ['O I 130.4 triplet', 'O I 135.6 doublet']

; if you want to save JPEG's of the disk images or save files
; of the disk information, need to define an output directory
  Output_directory = '~/work/emm/emus/data/figures/'
  output_directory = '~/'
; The routine below MUST be run before anything else becaus
; the data from the EMUS data files and saves it into a structure
; called 'disk', which is then used for further plotting later.

; If you don't need to make  disk images, then the following is fine:
  emm_emus_examine_disk, time_range, emission = emission,$
                         local_path = local_path, disk = disk, $
                         Output_directory = output_directory, /l2b,plot = [0,1]
 
;  specmap, disk [0, 0].maplon, disk [0, 0].maplat, reform (disk [0, 0].brightness_map [0,*,*]), limit = {no_interp:1}

 
  if size(disk, /type) ne 8 then return
  
  loadct2, 39
 ; emm_emus_image_bar, trange =time_range, disk = disk
; NOTE: you can save the 'disk' structure to avoid having to rerun emm_emus_examine_disk

;=============================================================
; this routine loads several MAVEN particles and fields routines and
; also EMUS data, into tplot variables
  extended_time_range = Time_double (time_range) + [-7200, 7200]
   emm_emus_maven_ql, extended_time_range, disk = disk,/load_only

;===================================================
; EMM-MAVEN ORBIT JOINT  PLOTTING
; The code below will make plots of the EMUS disk image painted on a
; sphere with the MAVEN orbit flying around it


;.r mvn_orbproj_panel
;.r emm_emu_maven_orbit_plot


; choose which emission band will be plotted. In this case, band_index
; = 0 means the 130.4 nms oxygen emission
  band_index = 0

if not keyword_set (brightness_range) then  brightness_range = [2, 50]

  nobs = n_elements (disk [*, 0])
  nswath = 3
  for i = 0, nobs-1 do begin
     nsw = n_elements (where (disk [i,*].date_string ne ''))
     for j = 0, nsw-1 do begin
        if disk [i, j].date_string eq '' then continue
; choose the midpoint of the EMUS observation
        good = where (finite ( disk [i, j].SC_POS [0,*]))
        pos = mean (reform (disk [i, j].SC_POS [*,good]), dim = 2)
        time = mean (reform (disk [i, j].time [good]))
        file = strsplit (disk [i, j].files, '/',/extract)
        file = file [-1]

; this structure is required to make the plots
        overlay = {elon: disk [i, j].maplon, $
                   lat: disk [i, j].maplat, $
                   data: reform (disk [i, j].brightness_map [band_index,*,*]), $
                   Log: 1, range: brightness_range, color_table:8, $
                   obspos: pos, description:disk [0, 0].bands[band_index], $
                   Filename:file, time: time}

        
        ;specmap, overlay.elon, overlay.lat, overlay.data, limit = $
        ;         {no_Interp: 1}
       
; the routine below makes images of MAVEN  orbital trajectories and
; EMUS disk images together. Replace the path below with your own
; path.
        filename = 'EMUS_MAVEN_orbit_plot_' + $
                   disk [i, j].date_string+ '_'+ disk [i, j].mode + '_sw' + $
                   roundst (j+1) + 'of' +roundst (nsw)
        print, disk [i, j].mode
        
        emm_emu_maven_orbit_plot, overlay.time,$
                                  path +filename,overlay = overlay, traj_ct = 70, $
                                  sun_view = 'night';,/screen
     endfor
  endfor
end




