#!/bin/bash
dmd -debug -unittest java_to_d.d
rm java_to_d.obj
mkdir -p ../model
mkdir -p ../docs
./java_to_d
patch ../model/world.d world.d.diff
unix2dos ../model/world.d
pushd ..
for f in model/*.d ; do
	dmd -o- -c -D -Dddocs $f
done
popd
