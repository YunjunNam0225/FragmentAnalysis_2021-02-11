/***********************************************************************************************************************
*
* Copyright (C) 2009 by Jim Mutch (www.jimmutch.com).
*
* This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later
* version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
* warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License along with this program.  If not, see
* <http://www.gnu.org/licenses/>.
*
***********************************************************************************************************************/

void _CudaExit(const char *format, ...) {

    _Dealloc();

    char errMsg[_ERRMSG_LEN];

    va_list argList;
    va_start(argList, format);
    vsprintf(errMsg, format, argList);
    va_end(argList);

    sprintf(errMsg + strlen(errMsg), " (cuda error: %s)", cudaGetErrorString(_g_cudaErr));

    mexErrMsgTxt(errMsg);

}

/**********************************************************************************************************************/

void _ClaimDevice(int desiredDeviceNo, bool nice, _DeviceProps &props) {

    if (desiredDeviceNo >= 0) {
        if ((_g_cudaErr = cudaSetDevice(desiredDeviceNo)) != cudaSuccess) {
            _CudaExit("unable to select device %i", desiredDeviceNo);
        }
    }

    int flags = nice ? cudaDeviceBlockingSync : cudaDeviceScheduleSpin;
    if ((_g_cudaErr = cudaSetDeviceFlags(flags)) != cudaSuccess) {
        _CudaExit("unable to set device flags");
    }

    void *ptr;
    if ((_g_cudaErr = cudaMalloc(&ptr, 16)) != cudaSuccess) {
        _CudaExit("device not available");
    }
    cudaFree(ptr);

    int deviceNo;
    if ((_g_cudaErr = cudaGetDevice(&deviceNo)) != cudaSuccess) {
        _CudaExit("unable to determine which device was activated");
    }

    if ((desiredDeviceNo >= 0) && (deviceNo != desiredDeviceNo)) {
        _Exit("wrong device activated (desired=%i, activated=%i)", desiredDeviceNo, deviceNo);
    }

    props.deviceNo = (unsigned int)deviceNo;

    // TODO: query device for this (the warp size).
    props.blockSizeAlign = 32;

    // Note: half the warp size.  Would like to query the device in case this is not appropriate, but don't know how.
    props.blockYSizeAlign = props.blockSizeAlign >> 1;

    // Note: would like to query the device for these properties, but don't know how.
    props.maxTexYSize = 1 << 16;
    props.maxTexXSize = 1 << 15;

}

/**********************************************************************************************************************/

void _ReleaseDevice() {

    cudaThreadExit();

}

/**********************************************************************************************************************/

void _ClearTex(_TexPtrA &ta, texture<float, 2> &tb) {

    ta.linear = false;
    ta.arr    = NULL;

}

/**********************************************************************************************************************/

void _AllocTexLinear(_TexPtrA &ta, texture<float, 2> &tb, const float *sBuf, unsigned int ySize, unsigned int xCount,
    const char *desc) {

    _ClearTex(ta, tb);

    if ((ySize == 0) || (xCount == 0)) return;

    ta.linear = true;

    tb.addressMode[0] = cudaAddressModeClamp;
    tb.addressMode[1] = cudaAddressModeClamp;
    tb.filterMode     = cudaFilterModePoint;
    tb.normalized     = false;
    cudaChannelFormatDesc channels = cudaCreateChannelDesc<float>();
    size_t offset;
    if ((_g_cudaErr = cudaBindTexture2D(&offset, tb, sBuf, channels,
        ySize, xCount, ySize * sizeof(float))) != cudaSuccess) {
        ta.linear = false;
        _CudaExit("unable to bind to %s buffer", desc);
    }
    if (offset != 0) {
        ta.linear = false;
        _Exit("nonzero offset returned while binding to %s buffer", desc);
    }

}

/**********************************************************************************************************************/

void _AllocTexArray(_TexPtrA &ta, texture<float, 2> &tb, const mxArray *array, unsigned int ySize, unsigned int xCount,
    const char *desc) {

    _ClearTex(ta, tb);

    if ((ySize == 0) || (xCount == 0)) return;

    cudaChannelFormatDesc channels = cudaCreateChannelDesc<float>();
    if ((_g_cudaErr = cudaMallocArray(&ta.arr, &channels, ySize, xCount)) != cudaSuccess) {
        ta.arr = NULL;
        _CudaExit("unable to allocate %s array", desc);
    }

    tb.addressMode[0] = cudaAddressModeClamp;
    tb.addressMode[1] = cudaAddressModeClamp;
    tb.filterMode     = cudaFilterModePoint;
    tb.normalized     = false;
    if ((_g_cudaErr = cudaBindTextureToArray(tb, ta.arr)) != cudaSuccess) {
        cudaFreeArray(ta.arr);
        ta.arr = NULL;
        _CudaExit("unable to bind to %s array", desc);
    }

    if (array != NULL) {
        if ((_g_cudaErr = cudaMemcpy2DToArray(
            ta.arr,
            0, 0,
            (float *)mxGetData(array), ySize * sizeof(float),
            ySize * sizeof(float), xCount,
            cudaMemcpyHostToDevice)) != cudaSuccess) {
            _DeallocTex(ta, tb);
            _CudaExit("unable to copy to %s array", desc);
        }
    }

}

/**********************************************************************************************************************/

void _DeallocTex(_TexPtrA &ta, texture<float, 2> &tb) {

    if (ta.linear) {

        cudaUnbindTexture(tb);

    } else if (ta.arr != NULL) {

        cudaUnbindTexture(tb);
        cudaFreeArray(ta.arr);

    }

    _ClearTex(ta, tb);

}

/**********************************************************************************************************************/

void _PublishTex(_TexPtrA &ta, texture<float, 2> &tb, const float *sBuf, unsigned int ySize, unsigned int xCount,
    const char *desc) {

    if (ta.linear) {
        _Exit("_PublishTex not implemented for linear memory textures");
    }

    if ((ySize == 0) || (xCount == 0)) return;

    if ((_g_cudaErr = cudaMemcpy2DToArray(
        ta.arr,
        0, 0,
        sBuf, ySize * sizeof(float),
        ySize * sizeof(float), xCount,
        cudaMemcpyDeviceToDevice)) != cudaSuccess) {
        _CudaExit("unable to copy to %s array", desc);
    }

}

/**********************************************************************************************************************/

void _CopyTex(float *dBuf, unsigned int dHeight, char dest, _TexPtrA &ta, texture<float, 2> &tb, unsigned int yOff,
    unsigned int xOff, unsigned int yCount, unsigned int xCount, const char *desc) {

    if (ta.linear) {
        _Exit("_CopyTex not implemented for linear memory textures");
    }

    if ((yCount == 0) || (xCount == 0)) return;

    enum cudaMemcpyKind kind = (dest == 'd') ? cudaMemcpyDeviceToDevice : cudaMemcpyDeviceToHost;

    if ((_g_cudaErr = cudaMemcpy2DFromArray(
        dBuf, dHeight * sizeof(float),
        ta.arr, yOff * sizeof(float), xOff,
        yCount * sizeof(float), xCount,
        kind)) != cudaSuccess) {
        _CudaExit("unable to copy %s array", desc);
    }

}

/**********************************************************************************************************************/

void _UpdateTex(_TexPtrA &ta, texture<float, 2> &tb, unsigned int yOff, unsigned int xOff, const float *sBuf,
    unsigned int sHeight, char src, unsigned int yCount, unsigned int xCount, const char *desc) {

    if (ta.linear) {
        _Exit("_UpdateTex not implemented for linear memory textures");
    }

    if ((yCount == 0) || (xCount == 0)) return;

    enum cudaMemcpyKind kind = (src == 'd') ? cudaMemcpyDeviceToDevice : cudaMemcpyHostToDevice;

    if ((_g_cudaErr = cudaMemcpy2DToArray(
        ta.arr, yOff * sizeof(float), xOff,
        sBuf, sHeight * sizeof(float),
        yCount * sizeof(float), xCount,
        kind)) != cudaSuccess) {
        _CudaExit("unable to copy to %s array", desc);
    }

}

/**********************************************************************************************************************/

template<class T> void _ClearBuf(T *&buf) {

    buf = NULL;

}

/**********************************************************************************************************************/

template<class T> void _AllocBufA(T *&buf, const mxArray *array, unsigned int numComponents, const char *desc) {

    _AllocBufB(buf, (T *)mxGetData(array), mxGetNumberOfElements(array) / numComponents, desc);

}

/**********************************************************************************************************************/

template<class T> void _AllocBufB(T *&buf, const T *sBuf, unsigned int numElements, const char *desc) {

    if (numElements == 0) {
        buf = NULL;
        return;
    }

    if ((_g_cudaErr = cudaMalloc((void **)&buf, numElements * sizeof(T))) != cudaSuccess) {
        buf = NULL;
        _CudaExit("unable to allocate %s buffer", desc);
    }

    if (sBuf != NULL) {
        if ((_g_cudaErr = cudaMemcpy(
            buf, sBuf, numElements * sizeof(T), 
            cudaMemcpyHostToDevice)) != cudaSuccess) {
            _CudaExit("unable to copy to %s buffer", desc);
        }
    }

}

/**********************************************************************************************************************/

template<class T> void _DeallocBuf(T *&buf) {

    if (buf != NULL) {
        cudaFree(buf);
        buf = NULL;
    }

}

/**********************************************************************************************************************/

template<class T> void _CopyBuf1D(T *dBuf, char dest, const T *buf, unsigned int count, const char *desc) {

    if (count == 0) return;

    enum cudaMemcpyKind kind = (dest == 'd') ? cudaMemcpyDeviceToDevice : cudaMemcpyDeviceToHost;

    if ((_g_cudaErr = cudaMemcpy(
        dBuf, buf, count * sizeof(T), 
        kind)) != cudaSuccess) {
        _CudaExit("unable to copy %s buffer", desc);
    }

}

/**********************************************************************************************************************/

template<class T> void _CopyBuf2D(T *dBuf, unsigned int dHeight, char dest, const T *buf, unsigned int height,
    unsigned int yCount, unsigned int xCount, const char *desc) {

    if ((yCount == 0) || (xCount == 0)) return;

    enum cudaMemcpyKind kind = (dest == 'd') ? cudaMemcpyDeviceToDevice : cudaMemcpyDeviceToHost;

    if ((_g_cudaErr = cudaMemcpy2D(
        dBuf, dHeight * sizeof(T),
        buf, height * sizeof(T),
        yCount * sizeof(T), xCount,
        kind)) != cudaSuccess) {
        _CudaExit("unable to copy %s buffer", desc);
    }

}

/**********************************************************************************************************************/

template<class T> void _CopyBuf3D(T *dBuf, unsigned int dHeight, unsigned int dWidth, char dest, const T *buf,
    unsigned int height, unsigned int width, unsigned int yOff, unsigned int xOff, unsigned int zOff,
    unsigned int yCount, unsigned int xCount, unsigned int zCount, const char *desc) {

    if (zCount == 1) {
        buf += (zOff * width + xOff) * height + yOff;
        _CopyBuf2D(dBuf, dHeight, dest, buf, height, yCount, xCount, desc);
        return;
    }

    if ((yCount == 0) || (xCount == 0) || (zCount == 0)) return;

    cudaMemcpy3DParms p = {0};

    p.srcPtr.ptr    = (T *)buf;
    p.srcPtr.pitch  = height * sizeof(T);
    p.srcPtr.xsize  = height * sizeof(T);
    p.srcPtr.ysize  = width;
    p.srcPos.x      = yOff;
    p.srcPos.y      = xOff;
    p.srcPos.z      = zOff;
    p.dstPtr.ptr    = dBuf;
    p.dstPtr.pitch  = dHeight * sizeof(T);
    p.dstPtr.xsize  = dHeight * sizeof(T);
    p.dstPtr.ysize  = dWidth;
    p.extent.width  = yCount * sizeof(T);
    p.extent.height = xCount;
    p.extent.depth  = zCount;
    p.kind          = (dest == 'd') ? cudaMemcpyDeviceToDevice : cudaMemcpyDeviceToHost;

    if ((_g_cudaErr = cudaMemcpy3D(&p)) != cudaSuccess) {
        _CudaExit("unable to copy %s buffer", desc);
    }

}

/**********************************************************************************************************************/

template<class T> void _UpdateBuf1D(T *buf, const T *sBuf, char src, unsigned int count, const char *desc) {

    if (count == 0) return;

    enum cudaMemcpyKind kind = (src == 'd') ? cudaMemcpyDeviceToDevice : cudaMemcpyHostToDevice;

    if ((_g_cudaErr = cudaMemcpy(
        buf, sBuf, count * sizeof(T), 
        kind)) != cudaSuccess) {
        _CudaExit("unable to update %s buffer", desc);
    }

}

/**********************************************************************************************************************/

template<class T> void _UpdateBuf2D(T *buf, unsigned int height, const T *sBuf, unsigned int sHeight, char src,
    unsigned int yCount, unsigned int xCount, const char *desc) {

    if ((yCount == 0) || (xCount == 0)) return;

    enum cudaMemcpyKind kind = (src == 'd') ? cudaMemcpyDeviceToDevice : cudaMemcpyHostToDevice;

    if ((_g_cudaErr = cudaMemcpy2D(
        buf, height * sizeof(T),
        sBuf, sHeight * sizeof(T),
        yCount * sizeof(T), xCount,
        kind)) != cudaSuccess) {
        _CudaExit("unable to update %s buffer", desc);
    }

}

/**********************************************************************************************************************/

template<class T> void _UpdateBuf3D(T *buf, unsigned int height, unsigned int width, unsigned int yOff,
    unsigned int xOff, unsigned int zOff, const T *sBuf, unsigned int sHeight, unsigned int sWidth, char src,
    unsigned int yCount, unsigned int xCount, unsigned int zCount, const char *desc) {

    if (zCount == 1) {
        buf += (zOff * width + xOff) * height + yOff;
        _UpdateBuf2D(buf, height, sBuf, sHeight, src, yCount, xCount, desc);
        return;
    }

    if ((yCount == 0) || (xCount == 0) || (zCount == 0)) return;

    cudaMemcpy3DParms p = {0};

    p.srcPtr.ptr    = (T *)sBuf;
    p.srcPtr.pitch  = sHeight * sizeof(T);
    p.srcPtr.xsize  = sHeight * sizeof(T);
    p.srcPtr.ysize  = sWidth;
    p.dstPtr.ptr    = buf;
    p.dstPtr.pitch  = height * sizeof(T);
    p.dstPtr.xsize  = height * sizeof(T);
    p.dstPtr.ysize  = width;
    p.dstPos.x      = yOff;
    p.dstPos.y      = xOff;
    p.dstPos.z      = zOff;
    p.extent.width  = yCount * sizeof(T);
    p.extent.height = xCount;
    p.extent.depth  = zCount;
    p.kind          = (src == 'd') ? cudaMemcpyDeviceToDevice : cudaMemcpyHostToDevice;

    if ((_g_cudaErr = cudaMemcpy3D(&p)) != cudaSuccess) {
        _CudaExit("unable to update %s buffer", desc);
    }

}

/**********************************************************************************************************************/

template<class T> void _ClearConst(const char *constName, T *cPtr) {

}

/**********************************************************************************************************************/

template<class T> void _AllocConst(const char *constName, T *cPtr, const T *sPtr, unsigned int numElements) {

    if (numElements == 0) return;

    if ((_g_cudaErr = cudaMemcpyToSymbol(
        constName,
        sPtr,
        numElements * sizeof(T), 0,
        cudaMemcpyHostToDevice)) != cudaSuccess) {
        _CudaExit("unable to set constant %s", constName);
    }

}

/**********************************************************************************************************************/

template<class T> void _DeallocConst(const char *constName, T *cPtr) {

}

/**********************************************************************************************************************/

template<class T> void _CopyConst(T *dPtr, const char *constName, const T *cPtr, unsigned int off,
    unsigned int count) {

    if (count == 0) return;

    if ((_g_cudaErr = cudaMemcpyFromSymbol(
        dPtr,
        constName,
        count * sizeof(T), off * sizeof(T),
        cudaMemcpyDeviceToHost)) != cudaSuccess) {
        _CudaExit("unable to copy constant %s", constName);
    }

}

/**********************************************************************************************************************/

template<class T> void _UpdateConst(const char *constName, T *cPtr, unsigned int off, const T *sPtr,
    unsigned int count) {

    if (count == 0) return;

    if ((_g_cudaErr = cudaMemcpyToSymbol(
        constName,
        sPtr,
        count * sizeof(T), off * sizeof(T),
        cudaMemcpyHostToDevice)) != cudaSuccess) {
        _CudaExit("unable to update constant %s", constName);
    }

}
