# export white matter surface into text file
mkdir -p $PRD/surface
if [ ! -f $PRD/surface/rh.white.asc ]; then
  echo "importing right white matter surfaces from freesurfer"
  mris_convert "$FS"/"$SUBJ_ID"/surf/rh.white "$PRD"/surface/rh.white.asc
fi

# triangles and vertices high
if [ ! -f $PRD/surface/rh_white_vertices_high.txt ]; then
  echo "extracting right vertices and triangles for white matter surface"
  python extract_white_high.py rh
fi

# decimation using remesher
if [ ! -f $PRD/surface/rh_white_vertices_low.txt ]; then
  echo "right white matter decimation using remesher"
  # -> to mesh
  python txt2off.py $PRD/surface/rh_white_vertices_high.txt $PRD/surface/rh_white_triangles_high.txt $PRD/surface/rh_white_high.off
  #  decimation
  ./remesher/cmdremesher/cmdremesher $PRD/surface/rh_white_high.off $PRD/surface/rh_white_low.off
  # export to list vertices triangles
  python off2txt.py $PRD/surface/rh_white_low.off $PRD/surface/rh_white_vertices_low.txt $PRD/surface/rh_white_triangles_low.txt
fi

# create the right region mapping
if [ ! -f $PRD/surface/rh_white_region_mapping_low_not_corrected.txt ]; then
  echo "generating the right white matter region mapping on the decimated white matter surface"
  python region_mapping_white.py rh
fi

# correct
if [ ! -f $PRD/surface/rh_white_region_mapping_low.txt ]; then
    echo "correct the right white matter region mapping"
    python correct_region_mapping_white.py rh
    echo "check right white matter region mapping"
    python check_region_mapping_white.py rh
fi


