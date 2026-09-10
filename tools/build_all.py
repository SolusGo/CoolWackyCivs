"""Build every standalone civilization package in this repository."""
from build_mod import build as build_rouls
from build_luna_mod import build as build_luna
from build_terra_mod import build as build_terra
from build_capano_mod import build as build_capano

for builder in (build_rouls, build_luna, build_terra, build_capano):
    for output in builder():
        print(output)
