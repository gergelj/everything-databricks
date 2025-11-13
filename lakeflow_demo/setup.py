from setuptools import setup, find_packages

import src

setup(
  name = "hello_wheel",
  version = "0.0.1",
  author = "<AUTHOR>",
  url = "https://<my-url>",
  author_email = "<AUTHOR_EMAIL>",
  description = "Hello Wheel package",
  packages=find_packages(where='./src'),
  package_dir={'': 'src'},
  entry_points={
    "packages": [
      "main=hello_wheel.main:main"
    ]
  },
  install_requires=[
    "setuptools"
  ]
)