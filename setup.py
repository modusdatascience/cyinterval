from setuptools import setup, find_packages
import versioneer
setup(name='cyinterval',
      version=versioneer.get_version(),
      cmdclass=versioneer.get_cmdclass(),
      author='Jason Rudy',
      author_email='jcrudy@gmail.com',
      url='https://github.com/jcrudy/cyinterval',
      packages=find_packages(),
      install_requires=[]
     )