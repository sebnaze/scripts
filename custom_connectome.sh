# SCript to create custom connectivity matrix

#export PRD=/usr/local/freesurfer/subjects/S123456789

# export tracts to tmp txt file
if [ ! -f $PRD/connectivity/sparse_custom_connectivity.mtx ]; then
  mkdir -p $PRD/connectivity/tmp_ascii_tck
  echo "exporting tracts in ascii..."
  tckconvert $PRD/connectivity/whole_brain_post.tck \
             $PRD/connectivity/tmp_ascii_tck/output-[].txt \
             -scanner2voxel $PRD/connectivity/brain_2_diff.nii.gz \
             -nthreads "$NB_THREADS"

  # create and export the custom connectivity matrix
  mkdir -p $PRD/connectivity/img_"$SUBJ_ID"
  python2.7 custom_connectivity_matrix.py 

  # delete temporary ascii tracts folder
#  rm -r $PRD/connectivity/tmp_ascii_tck
fi



# export image of 1000 streamlines for visualization
if [ ! -f $PRD/connectivity/whole_brain_post_decimated_1000.tck ]; then
  tckedit $PRD/connectivity/whole_brain_post.tck \
        $PRD/connectivity/whole_brain_post_decimated_1000.tck \
        -number 1000 -minlength 40 -force -nthreads "$NB_THREADS"

  echo "exporting axial, sagital and coronal images of decimated streamlines"
  export slice="0 1 2"
  for S in $slice; do 
    #export curr_S=$S
    mrview $PRD/connectivity/brain_2_diff.nii.gz \
         -tractography.load $PRD/connectivity/whole_brain_post_decimated_1000.tck \
         -capture.folder $PRD/connectivity/img_"$SUBJ_ID"/ -focus 0 -mode 3 -plane $S \
         -noannotations -colourbar 0 -comments 0 -size 800,800 -autoscale \
         -capture.prefix tracts_"$S" -imagevisible 0 -capture.grab -exit  
  done
fi
