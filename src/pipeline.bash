#!bin/bash
mkdir -p data
gleam run
python src/convert_to_stl.py
