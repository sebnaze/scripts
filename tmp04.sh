
# prepare final directory
mkdir -p $PRD/$SUBJ_ID
mkdir -p $PRD/$SUBJ_ID/surface

# reunify both region_mapping, vertices and triangles
if [ ! -f $PRD/$SUBJ_ID/surface/region_mapping.txt ]; then
  echo "reunify both region mappings"
  python reunify_both_regions.py
fi

# zip to put in final format
pushd . > /dev/null
cd $PRD/$SUBJ_ID/surface > /dev/null
zip $PRD/$SUBJ_ID/surface.zip vertices.txt triangles.txt -q
cp region_mapping.txt ..
popd > /dev/null


