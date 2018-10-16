# profile.py

import pstats, cProfile

import pyximport

import main

cProfile.runctx("main.main()", globals(), locals(), "Profile.prof")

s = pstats.Stats("Profile.prof")
s.strip_dirs().sort_stats("time").print_stats()