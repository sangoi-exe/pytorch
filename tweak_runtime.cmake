# # Força o runtime de DLL em toda a build, anulando qualquer decisão do setup.py
# # Isso garante que CMAKE_CXX_FLAGS, CMAKE_C_FLAGS etc. usem /MD ou /MDd.
# set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /NODEFAULTLIB:LIBCMT" CACHE STRING "" FORCE)
# set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /NODEFAULTLIB:LIBCMT" CACHE STRING "" FORCE)
# set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /NODEFAULTLIB:LIBCMT" CACHE STRING "" FORCE)
# set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL" CACHE STRING "" FORCE)

# # set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xptxas -O3 -use_fast_math -lineinfo -DCUDA_MEMORY_OPTIMIZATION=1 -DOPTIMIZE_MEMORY_BANDWIDTH=1 -DCOALESCED_MEMORY_ACCESS=1 -DMAX_SHARED_MEMORY_PER_BLOCK=49152 -DMAX_REGISTERS_PER_BLOCK=65536 -DMAX_THREADS_PER_BLOCK=1024 -DUSE_TENSOR_CORES=1 -DUSE_AMPERE_TENSOR_CORES=1 -DUSE_CUTLASS=1 -DUSE_NATIVE_FP16=1 -DUSE_NATIVE_BF16=1 -DUSE_ASYNC_MEMORY_COPY=1"	CACHE STRING "" FORCE)
# link_directories("C:/Program Files (x86)/Windows Kits/10/Lib/10.0.22621.0/ucrt/x64")
# link_directories("C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/VC/Tools/MSVC/14.43.34808/lib/x64")
# #set(CMAKE_STATIC_LINKER_FLAGS "/machine:x64 /VERBOSE /LTCG /LIBPATH:\"C:/Program Files (x86)/Windows Kits/10/Lib/10.0.22621.0/ucrt/x64\" /LIBPATH:\"C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/VC/Tools/MSVC/14.43.34808/lib/x64\" /LIBPATH:\"C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/lib/x64\"" CACHE STRING "" FORCE)

# # set(CUDA_SEPARABLE_COMPILATION ON CACHE BOOL "" FORCE)
# #string(REPLACE "/MT" "" CMAKE_CUDA_FLAGS_RELEASE "${CMAKE_CUDA_FLAGS_RELEASE}")
# set(CUDA_SDK_ROOT_DIR "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8" CACHE PATH "" FORCE)
# set(CUDNN_ROOT "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8" CACHE PATH "" FORCE)
# set(CUDNN_LIBRARY "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/lib/x64/cudnn.lib" CACHE PATH "" FORCE)
# set(CUDNN_LIBRARY_PATH "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/lib/x64/cudnn.lib" CACHE FILEPATH "" FORCE)
# set(CUDNN_INCLUDE_DIR "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/include" CACHE PATH "" FORCE)
# set(CUDNN_INCLUDE_PATH "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/include" CACHE PATH "" FORCE)

# set(INTEL_COMPILER_DIR "C:/Program Files (x86)/Intel/oneAPI/compiler" CACHE PATH "" FORCE)
# set(MKL_OPENMP_LIBRARY "C:/Program Files (x86)/Intel/oneAPI/compiler/2025.2/lib/libiomp5md.lib" CACHE PATH "" FORCE)
# set(INTEL_OMP_DIR "C:/Program Files (x86)/Intel/oneAPI/compiler/2025.2/lib" CACHE PATH "" FORCE)
# set(MKL_LIBRARIES
#   "C:/Program Files (x86)/Intel/oneAPI/mkl/2025.2/lib/mkl_core.lib"
#   "C:/Program Files (x86)/Intel/oneAPI/mkl/2025.2/lib/mkl_intel_lp64.lib"
#   "C:/Program Files (x86)/Intel/oneAPI/mkl/2025.2/lib/mkl_sequential.lib"
#   CACHE FILEPATH "" FORCE
# )
# set(MKL_INCLUDE_DIR
#   "C:/Program Files (x86)/Intel/oneAPI/mkl/2025.2/include"
#   CACHE PATH "" FORCE
# )

# set(BUILD_TEST OFF CACHE BOOL "" FORCE)
# set(CMAKE_POLICY_DEFAULT_CMP0074 NEW CACHE STRING "" FORCE)
# set(CMAKE_POLICY_DEFAULT_CMP0077 NEW CACHE STRING "" FORCE)
# # set(CMAKE_POLICY_DEFAULT_CMP0148 NEW CACHE STRING "" FORCE)

# set(CMAKE_CXX_FLAGS "/openmp" CACHE STRING "" FORCE)
# set(CMAKE_C_FLAGS "/openmp" CACHE STRING "" FORCE)

set(CUDA_SDK_ROOT_DIR "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8" CACHE PATH "" FORCE)
set(CUDNN_ROOT "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8" CACHE PATH "" FORCE)
set(CUDNN_LIBRARY "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/lib/x64/cudnn.lib" CACHE PATH "" FORCE)
set(CUDNN_LIBRARY_PATH "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/lib/x64/cudnn.lib" CACHE FILEPATH "" FORCE)
set(CUDNN_INCLUDE_DIR "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/include" CACHE PATH "" FORCE)
set(CUDNN_INCLUDE_PATH "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/include" CACHE PATH "" FORCE)

# Intel OpenMP + MKL (corrigido)
set(INTEL_OMP_DIR "C:/Program Files (x86)/Intel/oneAPI/compiler/2025.2/lib" CACHE PATH "" FORCE)
set(MKL_OPENMP_LIBRARY "C:/Program Files (x86)/Intel/oneAPI/compiler/2025.2/lib/libiomp5md.lib" CACHE FILEPATH "" FORCE)

set(MKL_INCLUDE_DIR "C:/Program Files (x86)/Intel/oneAPI/mkl/2025.2/include" CACHE PATH "" FORCE)
set(MKL_LIBRARIES
  "C:/Program Files (x86)/Intel/oneAPI/mkl/2025.2/lib/mkl_core.lib"
  "C:/Program Files (x86)/Intel/oneAPI/mkl/2025.2/lib/mkl_intel_lp64.lib"
  "C:/Program Files (x86)/Intel/oneAPI/mkl/2025.2/lib/mkl_intel_thread.lib"
  CACHE STRING "" FORCE
)

# Build options / policies
set(BUILD_TEST OFF CACHE BOOL "" FORCE)
set(DC10_BUILD_MAIN_LIB ON CACHE BOOL "" FORCE)
set(CMAKE_POLICY_DEFAULT_CMP0074 NEW CACHE STRING "" FORCE)
set(CMAKE_POLICY_DEFAULT_CMP0077 NEW CACHE STRING "" FORCE)
set(CMAKE_POLICY_DEFAULT_CMP0148 OLD CACHE STRING "" FORCE)  # silencia FindPython warnings
