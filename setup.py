# cython: linetrace=True

from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from Cython.Compiler.Options import get_directive_defaults

# ext_modules = [
#     Extension("*",
#               sources=["players/Player.pyx", "utilities/constants.pyx", "utilities/helper.pyx", "Projector.pyx", "Lineup.pyx"]
#     ),
    
# ]
ext_modules = [
    Extension("*",
              sources=["*.pyx"],
              define_macros=[('CYTHON_TRACE', '1')]
    ),
    
]

directive_defaults = get_directive_defaults()
directive_defaults['linetrace'] = True
directive_defaults['binding'] = True

setup(name=".",
      ext_modules=cythonize(ext_modules, annotate=True))