
# prepare file for act
if [ "$ACT" = "freesurfer" ] && [ ! -f $PRD/connectivity/act.mif ]; then
  echo "prepare files for act using freesurfer"
  view_step=1
  5ttgen freesurfer $PRD/connectivity/aparcaseg_2_diff.nii.gz $PRD/connectivity/act.mif \
         -nthreads "$NB_THREADS" -force 
  5tt2vis $PRD/connectivity/act.mif $PRD/connectivity/act_vis.mif -force \
        -nthreads "$NB_THREADS"

elif [ "$ACT" = "fsl" ] && [ ! -f $PRD/connectivity/act.mif ]; then
  echo "prepare files for act using fsl"
  view_step=1
  5ttgen fsl $PRD/connectivity/brain_2_diff.nii.gz $PRD/connectivity/act.mif \
         -premasked -force  -nthreads "$NB_THREADS"
  5tt2vis $PRD/connectivity/act.mif $PRD/connectivity/act_vis.mif -force \
        -nthreads "$NB_THREADS"
fi
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
    echo "check tissue segmented image"
    view_step=0
    mrview $PRD/connectivity/act_vis.mif -colourmap 4
fi

