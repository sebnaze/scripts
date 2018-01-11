# export white matter surface into text file
mkdir -p $PRD/surface
if [ ! -f $PRD/surface/lh.white.asc ]; then
  echo "importing left white matter surfaces from freesurfer"
  mris_convert "$FS"/"$SUBJ_ID"/surf/lh.white "$PRD"/surface/lh.white.asc
fi

# triangles and vertices high
if [ ! -f $PRD/surface/lh_white_vertices_high.txt ]; then
  echo "extracting left vertices and triangles for white matter surface"
  python extract_white_high.py lh
fi

# decimation using remesher
if [ ! -f $PRD/surface/lh_white_vertices_low.txt ]; then
  echo "left white matter decimation using remesher"
  # -> to mesh
  python txt2off.py $PRD/surface/lh_white_vertices_high.txt $PRD/surface/lh_white_triangles_high.txt $PRD/surface/lh_white_high.off
  #  decimation
  ./remesher/cmdremesher/cmdremesher $PRD/surface/lh_white_high.off $PRD/surface/lh_white_low.off
  # export to list vertices triangles
  python off2txt.py $PRD/surface/lh_white_low.off $PRD/surface/lh_white_vertices_low.txt $PRD/surface/lh_white_triangles_low.txt
fi

# create the left region mapping
if [ ! -f $PRD/surface/lh_white_region_mapping_low_not_corrected.txt ]; then
  echo "generating the left white matter region mapping on the decimated white matter surface"
  python region_mapping_white.py lh
fi

# correct
if [ ! -f $PRD/surface/lh_white_region_mapping_low.txt ]; then
    echo "correct the left white matter region mapping"
    python correct_region_mapping_white.py lh
    echo "check left white matter region mapping"
    python check_region_mapping_white.py lh
fi


