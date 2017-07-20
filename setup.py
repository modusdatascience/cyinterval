from setuptools import setup, find_packages, Extension
import versioneer
import sys
import os



# Determine whether to use Cython
if '--cythonize' in sys.argv:
    from Cython.Build.Dependencies import cythonize
    from Cython.Distutils import build_ext
    cythonize_switch = True
    del sys.argv[sys.argv.index('--cythonize')]
    ext = 'pyx'
    directives = {}
    directives['linetrace'] = False
    directives['binding'] = False
    directives['profile'] = False
    cmdclass = {'build_ext': build_ext}
else:
    from setuptools.command.build_ext import build_ext  # @NoMove @Reimport
    cythonize_switch = False
    ext = 'c'
    cmdclass = {'build_ext': build_ext}

ext_modules = [Extension('cyinterval.cyinterval', 
                         [os.path.join('cyinterval', 
                                       'cyinterval.%s' % ext)])]


setup(name='cyinterval',
      version=versioneer.get_version(),
      cmdclass=versioneer.get_cmdclass(cmdclass),
      author='Jason Rudy',
      author_email='jcrudy@gmail.com',
      url='https://github.com/jcrudy/cyinterval',
      packages=find_packages(),
      ext_modules = cythonize(ext_modules, compiler_directives=directives) if cythonize_switch else ext_modules,
      install_requires=[]
     )