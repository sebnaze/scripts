
## now compute connectivity and length matrix
if [ ! -f $PRD/connectivity/aparcaseg_2_diff_"$ASEG".mif ]; then
  echo "compute FS labels"
  labelconvert $PRD/connectivity/aparcaseg_2_diff.nii.gz \
               $FREESURFER_HOME/FreeSurferColorLUT.txt \
               fs_region.txt $PRD/connectivity/aparcaseg_2_diff_fs.mif \
               -force -nthreads "$NB_THREADS"
  echo "$ASEG"
  if [ "$ASEG" = "fsl" ]; then
    # FS derived subcortical parcellation is too variable and prone to 
    # errors => labelsgmfix) was generated, 
    # see Smith RE Neuroimage. 2015 Jan 1;104:253-65.
    # TODO: check effect on region mapping
    # TODO; -sgm_amyg_hipp option to consider
    echo "fix FS subcortical labels to generate FSL labels"
    labelsgmfix $PRD/connectivity/aparcaseg_2_diff_fs.mif \
                $PRD/connectivity/brain_2_diff.nii.gz fs_region.txt \
                $PRD/connectivity/aparcaseg_2_diff_fsl.mif -premasked \
                -force -nthreads "$NB_THREADS"   
  fi 
fi

if [ ! -f $PRD/connectivity/weights.csv ]; then
  echo "compute connectivity matrix weights"
  if [ "$SIFT" = "sift2" ]; then
    # -tck_weights_in flag only needed for sift2 but not for sift/no processing
    tck2connectome $PRD/connectivity/whole_brain_post.tck \
                   $PRD/connectivity/aparcaseg_2_diff_"$ASEG".mif \
                   $PRD/connectivity/weights.csv -assignment_radial_search 2 \
                   -out_assignments $PRD/connectivity/edges_2_nodes.csv \
                   -tck_weights_in $PRD/connectivity/streamline_weights.csv \
                   -force -nthreads "$NB_THREADS"
  else
    tck2connectome $PRD/connectivity/whole_brain_post.tck \
                   $PRD/connectivity/aparcaseg_2_diff_"$ASEG".mif \
                   $PRD/connectivity/weights.csv -assignment_radial_search 2 \
                   -out_assignments $PRD/connectivity/edges_2_nodes.csv \
                   -force -nthreads "$NB_THREADS"
  fi
fi

if [ ! -f $PRD/connectivity/tract_lengths.csv ]; then
  echo "compute connectivity matrix edge lengths"
  view_step=1
  # mean length result: weight by the length, then average
  # see: http://community.mrtrix.org/t/tck2connectome-edge-statistic-sift2-questions/1059/2 
  # Not applying sift2, as here the mean is \
  # sum(streamline length * streamline weight)/no streamlines, does not make sense
  tck2connectome $PRD/connectivity/whole_brain_post.tck \
                 $PRD/connectivity/aparcaseg_2_diff_"$ASEG".mif \
                 $PRD/connectivity/tract_lengths.csv \
                 -assignment_radial_search 2 -zero_diagonal -scale_length \
                 -stat_edge mean -force -nthreads "$NB_THREADS"
fi

# view connectome
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  echo "view connectome edges as lines or streamlines"
  if [ ! -f $PRD/connectivity/exemplars.tck ]; then
    if [ "$SIFT" = "sift2" ]; then
        connectome2tck $PRD/connectivity/whole_brain_post.tck \
                       $PRD/connectivity/edges_2_nodes.csv \
                       $PRD/connectivity/exemplars.tck \
                       -exemplars $PRD/connectivity/aparcaseg_2_diff_"$ASEG".mif \
                       -tck_weights_in $PRD/connectivity/streamline_weights.csv \
                       -files single -nthreads "$NB_THREADS"
    else 
        connectome2tck $PRD/connectivity/whole_brain_post.tck \
                       $PRD/connectivity/edges_2_nodes.csv \
                       $PRD/connectivity/exemplars.tck \
                       -exemplars $PRD/connectivity/aparcaseg_2_diff_"$ASEG".mif \
                       -files single -nthreads "$NB_THREADS"
    fi
  fi
  # TOCHECK: in mrview, load the lut table (fs_region.txt) for node correspondence, 
  # and exemplars.tck if wanting to see edges as streamlines 
  mrview $PRD/connectivity/aparcaseg_2_diff_$ASEG.mif \
         -connectome.init $PRD/connectivity/aparcaseg_2_diff_$ASEG.mif \
         -connectome.load $PRD/connectivity/weights.csv 
fi

# view tractogram and tdi
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  echo "view tractogram and tdi image"
  view_step=0
  if [ ! -f $PRD/connectivity/whole_brain_post_decimated.tck ]; then
    # $(( number_tracks/100)) this follows some recommendations by 
    # JD Tournier to avoid mrview to be to slow
    # (for visualization no more than 100-200K streamlines)
    # => min(100k, number_tracks/100)
    if [ "$SIFT" = "sift2" ]; then
        tckedit $PRD/connectivity/whole_brain_post.tck \
                $PRD/connectivity/whole_brain_post_decimated.tck \
                -tck_weights_in $PRD/connectivity/streamline_weights.csv \
                -number $(($NUMBER_TRACKS<100000?$NUMBER_TRACKS:100000)) \
                -minweight 1 -force -nthreads "$NB_THREADS"
    else 
        tckedit $PRD/connectivity/whole_brain_post.tck \
                $PRD/connectivity/whole_brain_post_decimated.tck \
                -number $(($NUMBER_TRACKS<100000?$NUMBER_TRACKS:100000)) \
                -force -nthreads "$NB_THREADS"
    fi  
  fi
  if [ ! -f $PRD/connectivity/whole_brain_post_tdi.mif ]; then
      if [ "$SIFT" = "sift2" ]; then
          tckmap $PRD/connectivity/whole_brain_post.tck \
                 $PRD/connectivity/whole_brain_post_tdi.mif \
                 -tck_weights_in $PRD/connectivity/streamline_weights.csv \
                 -dec -vox 1 -force -nthreads "$NB_THREADS"
      else
          tckmap $PRD/connectivity/whole_brain_post.tck \
                 $PRD/connectivity/whole_brain_post_tdi.mif \
                 -dec -vox 1 -force -nthreads "$NB_THREADS"
      fi 
  fi
  mrview $PRD/connectivity/aparcaseg_2_diff_$ASEG.mif \
         -overlay.load $PRD/connectivity/whole_brain_post_tdi.mif \
         -overlay.opacity 0.5 -overlay.interpolation_off \
         -tractography.load $PRD/connectivity/whole_brain_post_decimated.tck 
fi


