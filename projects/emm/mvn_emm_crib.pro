;=================================
; MAVEN-EMM DATA SHARING AGREEMENT

; Please note the following conditions for working with MAVEN and EMM
;data jointly, if you are a team member of EITHER mission:
;
;- all press and communications (press releases, social media, interviews, etc...) must be approved by the PIs- Shannon Curry, Hessa Al Moutrishi
;- co-authorship must be offered the the instrument teams, leads and PIs of any instrument dataset used
;==================================

; This crib sheet gives examples of loading and examining MAVEN in
; situ particles and fields data and Emirates Mars Mission disk images
; together

; first choose start and ending times

start_time = '2021-12-16'
Finish_time = '2021-12-17'
time_range = [start_time, finish_time]

; Set the local path. Note this directory must have the same structure
; as the file source kept on AWS:
;      https://mdhkq4bfae.execute-api.eu-west-1.amazonaws.com/prod/science-files-metadata?"
;
;      NOTE for SSL FOLKS: The default will work fine for people working on the UC
;      Berkeley SSL network, i.e. no need to set the keyword
;      'local_path'

;      NOTE for LASP FOLKS: A similar copy of the directory exists at
;      LASP. Please contact Justin Deighan
;      (Justin.Deighan@lasp.Colorado.edu) for the location of the
;      directory.
;      
;      FOR OTHER MAVEN FOLKS: please contact Justin Deighan for information on how to
;      install the EMUS data on your local machine

; This is where the files are kept on the SSL Berkeley network
local_path = '/disks/hope/home2/rlillis/emm/data/'

; choose the emission features you'd like to examine. A full
; list of them is found in the source code emm_emus_examine_disk.pro
emission = ['O I 130.4 triplet', 'O I 135.6 doublet']

; if you want to save JPEG's of the disk images or save files
; of the disk information, need to define an output directory
Output_directory = '~/work/emm/emus/data/figures/'
;output_directory = '~/'

; The routine below MUST be run before anything else becaus
; the data from the EMUS data files and saves it into a structure
; called 'disk', which is then used for further plotting later.

; If you don't need to make  disk images, then the following is
; fine just to load the data.
emm_emus_examine_disk, time_range, emission = emission,$
                       local_path = local_path, disk = disk, $
                       Output_directory = output_directory

; Note that 'disk' is a Nx3 array of structures, where N is the number
; of disc observations between start_time and finish_time. 3 is the
; maximum number of swaths comprising each observation (1, 2, or 3 swaths).

; if you want to make standalone images of the disk emission, the
; following keywords should be used:
; SATELLITE or HAMMER: projection to be drawn
; JPEG: set if you want to save a JPEG
; OUTPUT_DIRECTORY: the directory to place the JPEGs
; The following can be set (defaults exist already)
; BRIGHTNESS, RANGE
; ZLOG
; COLOR_TABLE
emm_emus_examine_disk, time_range, /satellite, emission = emission,$
                       color_table= [8,3], local_path = local_path, $
                       output_directory = output_directory, $
                       disk = disk,/JPEG

; NOTE: you can save the 'disk' structure in an IDL save-restore file
; using the 'save' procedure to avoid having to rerun emm_emus_examine_disk

;=============================================================
; this routine loads several MAVEN particles and fields routines and
; also EMUS data, into tplot variables
 emm_emus_maven_ql, time_range, disk = disk

;===================================================
; EMM DISK IMAGE JOINED PLOTTING WITH MAVEN
; The code below will make plots of the EMUS disk image painted on a
; sphere with the MAVEN orbit flying around it and MAVEN data plotted
; in a stack of tplots

;The first index is the observation number
OBS_index = 4
; the second index is the swath within that observation
swath_index = 0

; choose which emission band will be plotted. In this case, band_index
; = 0 means the 130.4 nm oxygen emission
band_index = 0

; choose the midpoint of the EMUS observation as the time to center
; the orbit plots.  You can choose something else.
good = where (finite ( disk [OBS_index, swath_index].SC_POS [0,*]))
pos = mean (reform (disk [OBS_index, swath_index].SC_POS [*,good]), dim = 2)
time = mean (reform (disk [OBS_index, swath_index].time [good]))
file = strsplit (disk [OBS_index, swath_index].files, '/',/extract)
file = file [-1]

; this structure is required to make the combined MAVEN-EMM geometry
; plots. Info on these tags is contained within the
; emm_emu_maven_orbit_plot routine below
overlay = {elon: disk [OBS_index, swath_index].maplon, $
           lat: disk [OBS_index, swath_index].maplat, $
           data: reform (disk [OBS_index, swath_index].brightness_map [band_index,*,*]), $
           Log: 1, range: [2, 50], color_table:8, $
           obspos: pos, description:disk [0, 0].bands[band_index], $
          Filename:file, time: time}

; the routine below makes images of MAVEN  orbital trajectories and
; EMUS disk images together. Replace the path below with your own path.
path = '~/work/emm/emus/data/'
fileroot = 'test'
emm_emu_maven_orbit_plot, overlay.time,path +fileroot,overlay = overlay, traj_ct = 70, $
                          sun_view = 'night'



