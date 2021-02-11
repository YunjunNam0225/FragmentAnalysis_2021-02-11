@echo off

set CUDA=1
set SETUP_COMPILER=call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcvarsall.bat"
set NVCC_OPTIONS=-D_CRT_SECURE_NO_DEPRECATE
set CUDA_LINK_LIB="C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v4.2\lib\x64\cudart.lib"
