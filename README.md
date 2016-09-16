# A collection of shell script functions.

## algorithms.lib.sh
* _foreach_cluster: group items based on a portion of it's name
* ext_cluster: cluster a list of files by extension

## datetime.lib.sh
* tz_calc: do timezone conversions

## file.lib.sh
* make_shar_ball: package a dir with a shell script entry point into a shell executable
* remove_aged_files: finds empty dirs and files that are older than maxdays and removes them
* watch_file: monitor a file until it changes or is deleted and execute an action

## math.lib.sh
* random: get a random number within limits
* bitfactory: create bit strings

## media.lib.sh
* encode_avi2divx: compress/encode a raw avi file into divx

## shell.lib.sh
* gkill: kill a whole process group
* file_data_age: check how many days since the data last changed
* pid_is_alive: check if a pid is alive
* die: exit a script with verbose output to stder
* assert_single_instance: returns 0 on success, 1 on failure
* color_print: print something in color (first arg indicates color)

## torrents.lib.sh
* push_torrents: search local download dirs for torrent files and push them to blacksmith
* push_subdivx_subtitles: search for subtitles in local dirs and ship them to blacksmith