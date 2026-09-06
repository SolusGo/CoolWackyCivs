"""Build every standalone civilization package in this repository."""
from build_mod import build as build_rouls
from build_luna_mod import build as build_luna

for builder in (build_rouls, build_luna):
    for output in builder():
        print(output)
