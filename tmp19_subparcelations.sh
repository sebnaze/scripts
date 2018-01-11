
################### subparcellations
# compute sub parcellations connectivity if asked
if [ -n "$K_LIST" ]; then
  for K in $K_LIST; do
    export curr_K=$(( 2**K ))
    mkdir -p $PRD/$SUBJ_ID/connectivity_"$curr_K"
    if [ -n "$MATLAB" ]; then
      if [ ! -f $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii.gz ]; then
        echo "compute subparcellations for $curr_K"
        $MATLAB -r "run subparcel.m; quit;" -nodesktop -nodisplay 
        gzip $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii
      fi
    else
      if [ ! -f $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii.gz ]; then
        echo "compute subparcellations for subparcellation $curr_K"
        sh subparcel/distrib/run_subparcel.sh $MCR  
        gzip $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii
      fi
    fi
    if [ ! -f $PRD/$SUBJ_ID/region_mapping_"$curr_K".txt ]; then
      echo "generate region mapping for subparcellation "$curr_K""
      python2.7 region_mapping_other_parcellations.py
    fi
    if [ ! -f $PRD/connectivity/aparcaseg_2_diff_"$curr_K".mif ]; then
      mrconvert $PRD/connectivity/aparcaseg_2_diff_"$curr_K".nii.gz \
                   $PRD/connectivity/aparcaseg_2_diff_"$curr_K".mif \
                   -datatype float32 -force
    fi
    if [ ! -f $PRD/connectivity/weights_"$curr_K".csv ]; then
      echo "compute connectivity matrix using act for subparcellation "$curr_K""
      if [ "$SIFT" = "sift2" ]; then
      # -tck_weights_in flag only needed for sift2 but not for sift/no processing
      tck2connectome $PRD/connectivity/whole_brain_post.tck \
                     $PRD/connectivity/aparcaseg_2_diff_"$curr_K".mif \
                     $PRD/connectivity/weights_"$curr_K".csv -assignment_radial_search 2 \
                     -out_assignments $PRD/connectivity/edges_2_nodes_"$curr_K".csv \
                     -tck_weights_in $PRD/connectivity/streamline_weights.csv \
                     -force -nthreads "$NB_THREADS"
      else
      tck2connectome $PRD/connectivity/whole_brain_post.tck \
                     $PRD/connectivity/aparcaseg_2_diff_"$curr_K".mif \
                     $PRD/connectivity/weights.csv -assignment_radial_search 2 \
                     -out_assignments $PRD/connectivity/edges_2_nodes_"$curr_K".csv \
                     -force -nthreads "$NB_THREADS"
      fi
    fi
    if [ ! -f $PRD/connectivity/tract_lengths_"$curr_K".csv ]; then
      echo "compute connectivity matrix edge lengths subparcellation "$curr_K""
      view_step=1
      # mean length result: weight by the length, then average
      # see: http://community.mrtrix.org/t/tck2connectome-edge-statistic-sift2-questions/1059/2 
      # Not applying sift2, as here the mean is \
      # sum(streamline length * streamline weight)/no streamlines, does not make sense
      tck2connectome $PRD/connectivity/whole_brain_post.tck \
                     $PRD/connectivity/aparcaseg_2_diff_"$curr_K".mif \
                     $PRD/connectivity/tract_lengths_"$curr_K".csv \
                     -assignment_radial_search 2 -zero_diagonal -scale_length \
                     -stat_edge mean -force -nthreads "$NB_THREADS"
      #fi
    fi
    if [ ! -f $PRD/$SUBJ_ID/connectivity_"$curr_K"/weights.txt ]; then
      echo "generate files for TVB subparcellation "$curr_K""
      python2.7 compute_connectivity_sub.py $PRD/connectivity/weights_"$curr_K".csv $PRD/connectivity/tract_lengths_"$curr_K".csv $PRD/$SUBJ_ID/connectivity_"$curr_K"/weights.txt $PRD/$SUBJ_ID/connectivity_"$curr_K"/tract_lengths.txt
    fi
    pushd . > /dev/null
    cd $PRD/$SUBJ_ID/connectivity_"$curr_K" > /dev/null
    zip $PRD/$SUBJ_ID/connectivity_"$curr_K".zip weights.txt tract_lengths.txt centres.txt average_orientations.txt -q 
    popd > /dev/null
  done
fi


