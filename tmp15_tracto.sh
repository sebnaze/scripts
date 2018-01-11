
# tractography
if [ ! -f $PRD/connectivity/whole_brain.tck ]; then
  if [ "$SIFT" = "sift" ]; then
    # temporarily change number of tracks for sift
    number_tracks=$(($NUMBER_TRACKS*$SIFT_MULTIPLIER))
  fi
  native_voxelsize=$(mrinfo $PRD/connectivity/mask_native.mif -vox \
                   | cut -f 1 -d " " | xargs printf "%.3f")
  stepsize=$( bc -l <<< "scale=2; "$native_voxelsize"/2" )
  angle=$( bc -l <<< "scale=2; 90*"$stepsize"/"$native_voxelsize"" )
  if [ "$ACT" != "none" ]; then
    # when using msmt_csd in conjunction with ACT, the cutoff threshold
    # can be reduced to 0.06
    # see: https://github.com/MRtrix3/mrtrix3/blob/master/docs/quantitative_structural_connectivity/ismrm_hcp_tutorial.rst#connectome-generation
    echo "generating tracks using act"
    if [ "$SEED" = "gmwmi" ]; then
      echo "seeding from gmwmi" 
      5tt2gmwmi $PRD/connectivity/act.mif \
                $PRD/connectivity/gmwmi_mask.mif -force \
                -nthreads "$NB_THREADS"
      # TODO: min length check andreas paper
      tckgen $PRD/connectivity/wm_CSD"$lmax".mif \
             $PRD/connectivity/whole_brain.tck \
             -seed_gmwmi $PRD/connectivity/gmwmi_mask.mif \
             -act $PRD/connectivity/act.mif -select "$NUMBER_TRACKS" \
             -seed_unidirectional -crop_at_gmwmi -backtrack \
             -minlength 4 -maxlength 250 -step "$stepsize" -angle "$angle" \
             -cutoff 0.06 -force -nthreads "$NB_THREADS"
    elif [ "$SEED" = "dynamic" ]; then
       # -dynamic seeding may work slightly better than gmwmi, 
       # see Smith RE Neuroimage. 2015 Oct 1;119:338-51.
      echo "seeding dynamically"   
'''
      # original parameters
      tckgen $PRD/connectivity/wm_CSD"$lmax".mif \
             $PRD/connectivity/whole_brain.tck \
             -seed_dynamic $PRD/connectivity/wm_CSD$lmax.mif \
             -act $PRD/connectivity/act.mif -select "$NUMBER_TRACKS" \
             -crop_at_gmwmi -backtrack -minlength 4 -maxlength 250 \
             -step "$stepsize" -angle "$angle" -cutoff 0.06 -force \
             -nthreads "$NB_THREADS"
'''
      # SN parameters
      tckgen $PRD/connectivity/wm_CSD"$lmax".mif \
             $PRD/connectivity/whole_brain_iFOD2_ACT_minlength04_angle"$angle"_cutoff006_5M.tck \
             -seed_dynamic $PRD/connectivity/wm_CSD$lmax.mif \
             -act $PRD/connectivity/act.mif -select 5000000 -seeds 5000000 \
             -crop_at_gmwmi -backtrack -minlength 4 -maxlength 250 \
             -step "$stepsize" -angle "$angle" -cutoff 0.06 -force \
             -nthreads "$NB_THREADS"
      ln $PRD/connectivity/whole_brain_iFOD2_ACT_minlength04_angle"$angle"_cutoff006_5M.tck \
         $PRD/connectivity/whole_brain.tck
    fi  
  else
    echo "generating tracks without using act" 
    echo "seeding dynamically"
 '''
    # original params
    tckgen $PRD/connectivity/wm_CSD"$lmax".mif \
           $PRD/connectivity/whole_brain.tck \
           -seed_dynamic $PRD/connectivity/wm_CSD"$lmax".mif \
           -mask $PRD/connectivity/mask.mif -select "$NUMBER_TRACKS" \
           -maxlength 250 -step "$stepsize" -angle "$angle" -cutoff 0.1  \
           -force -nthreads "$NB_THREADS" 
'''
    # mix
    tckgen $PRD/connectivity/wm_CSD"$lmax".mif \
           $PRD/connectivity/whole_brain_iFOD2_angle45_cutoff01.tck \
           -seed_dynamic $PRD/connectivity/wm_CSD"$lmax".mif \
           -mask $PRD/connectivity/mask.mif -select 5000000 -seeds 5000000 \
           -maxlength 250 -step "$stepsize" -angle 45 -cutoff 0.1  \
           -minlength 20 -force -nthreads "$NB_THREADS" 

    ln $PRD/connectivity/whole_brain_iFOD2_angle45_cutoff01.tck $PRD/connectivity/whole_brain.tck

'''
    # Selen parameters
    tckgen $PRD/connectivity/dwi.mif \
           $PRD/connectivity/whole_brain_TensorDet_angle30_cutoff02.tck \
           -algorithm Tensor_Det -rk4 \
           -seed_dynamic $PRD/connectivity/wm_CSD"$lmax".mif \
           -mask $PRD/connectivity/mask.mif -select 100000 \
           -maxlength 300 -step "$stepsize" -angle 30 -cutoff 0.2  \
           -minlength 20 -force -nthreads "$NB_THREADS" 
'''

  fi
fi


