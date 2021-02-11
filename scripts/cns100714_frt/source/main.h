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

#include "common_dec.h"

/**********************************************************************************************************************/

#include "util_dec.h"

/**********************************************************************************************************************/

class _T_BASE {
public:
    int z;
};

INLINE _T_BASE _P_BASE(int z) {
    _T_BASE p;
    p.z = z;
    return p;
}

INLINE int _Z_BASE(_T_BASE p) {
    return p.z;
}

/**********************************************************************************************************************/

#include _USER_GLOBAL

/**********************************************************************************************************************/

// Use all available constant memory, currently limited to 64K bytes.  It would be nice to query the device for the
// amount of constant memory available.

const unsigned int _MAX_CDATA = 8192;
const unsigned int _MAX_CMETA = 16384;

// These are fairly arbitrary limits governing the size of statically allocated arrays in host memory.  There would not
// be much penalty for increasing them, and they could be removed altogether if we were willing to make the code a bit
// more complicated (i.e. use dynamic allocation and deallocation).

const unsigned int _MAX_KERNELS = 100;
const unsigned int _MAX_RESULTS = 100;
const unsigned int _NAME_LEN    = 32;

/**********************************************************************************************************************/

class _OutTable {
public:

    float        *m_ptr[_NUM_CV_NZ];
    unsigned int  m_h  [_NUM_CV_NZ];
    unsigned int  m_w  [_NUM_CV_NZ];

};

/**********************************************************************************************************************/

// We put this structure in union with an array of uints so that the structure can be read in by multiple threads in
// parallel using a single coalesced read.  The structure must be exactly 256 bytes so that each structure in an array
// of structures will be correctly aligned for coalesced reading.

const unsigned int _LAYERDATA_UINTS = 64;

class _LayerData {
public:

    union {

        struct {

            unsigned int        m_yCount0;
            unsigned int        m_ySize0;
            unsigned int        m_yCount;
            unsigned int        m_ySize;
            unsigned int        m_xCount;
            unsigned int        m_sSize;

            unsigned int        m_gmvOff;
            unsigned int        m_mvOff;
            unsigned int        m_gcOff;
            unsigned int        m_cOff;

            unsigned int        m_tOff;

            unsigned int        m_blockYSize;

            float              *m_ndPtr;
            float              *m_nwPtr;
            float              *m_nwOut;
            const unsigned int *m_nmPtr;
            float              *m_sdPtr;
            const ushort4      *m_smPtr;

            unsigned short      m_entry[_LT_LEN];

        };

        unsigned int m_array[_LAYERDATA_UINTS];

    };

};

/**********************************************************************************************************************/

class _Layer : private _LayerData {
public:

    void LInit(const mxArray *layers, unsigned int z);

    float *GetNDPtr();
    float *GetNWOut();
    float *GetSDPtr();

    #ifndef _GPU
        void LRun(unsigned int phase);
    #endif

private:

    // We rely on these members being at the end of the structure.

    unsigned int m_z;
    unsigned int m_typeNo;

};

/**********************************************************************************************************************/

class _Kernel {
public:

    void KInit(const mxArray *kernels, unsigned int k);

    unsigned int StepNo();

    void KRun();

private:

    char                m_type[_NAME_LEN];
    unsigned int        m_typeNo;

    unsigned int        m_stepNo;
    unsigned int        m_phase;

    unsigned int        m_blockSize;

    unsigned int        m_bCount;
    const ushort4      *m_bPtr;

    unsigned int        m_zCount;
    const unsigned int *m_zPtr;

    unsigned int        m_gridYSize;
    unsigned int        m_gridXSize;
    unsigned int        m_blockYSize;
    unsigned int        m_blockXSize;

};

/**********************************************************************************************************************/

class _Result {
public:

    void RInit(const mxArray *p, unsigned int resultNo, const mxArray *res);
    void RAlloc(unsigned int resultNo, unsigned int totalSamples, mxArray *&res, bool needHold);

    void SampleToHold(unsigned int sampleNo);
    void HoldToResult(unsigned int totalSamples);
    void SampleToResult();
    void Update();

private:

    unsigned int  m_varType;

    unsigned int  m_pos;

    float        *m_sBuf;
    unsigned int  m_sBufH;
    unsigned int  m_sBufW;

    unsigned int  m_hOff;
    unsigned int  m_wOff;
    unsigned int  m_dOff;

    unsigned int  m_hCount;
    unsigned int  m_wCount;
    unsigned int  m_dCount;

    float        *m_rBuf;
    unsigned int  m_rBufH;
    unsigned int  m_rBufW;

    unsigned int  m_rCount;

    float        *m_hBuf;

};

/**********************************************************************************************************************/

static void _Claim  (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static void _Release(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static void _Init   (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static void _Done   (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static void _Run    (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static void _Get    (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static void _Set    (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

static void _AtExit();
static void _Dealloc();
static void _Exit(const char *format, ...);

#include _USER_ALLKERNELS_DEC

static void _NeuronExit(unsigned int z, unsigned int y, unsigned int x, const char *format, ...);
static void _NeuronInfo(unsigned int z, unsigned int y, unsigned int x, const char *format, ...);

/**********************************************************************************************************************/

unsigned int _g_initLevel = 0;
unsigned int _g_exitLevel = 0;

_DeviceProps _g_props;

bool         _g_independent;

unsigned int _g_mvOff;
unsigned int _g_cOff;

#ifdef _GPU
    __constant__ float          _g_cData[_MAX_CDATA];
    __constant__ unsigned short _g_cMeta[_MAX_CMETA];
#else
    float          _g_cData[_MAX_CDATA];
    unsigned short _g_cMeta[_MAX_CMETA];
#endif

_OutTable     _g_tOut;

unsigned int  _g_wCount;

float        *_g_dData;
float        *_g_dWData;
float        *_g_dWOut;
unsigned int *_g_dNeurons;
ushort4      *_g_dSynapses;
ushort4      *_g_dBlocks;
_LayerData   *_g_dLayers;

unsigned int *_g_hKernelZs;

unsigned int  _g_lCount;
_Layer       *_g_layers[_MAX_LAYERS];

unsigned int  _g_kCount;
_Kernel      *_g_kernels[_MAX_KERNELS];

unsigned int  _g_iterNo;

unsigned int  _g_holdBufferCount;
float        *_g_holdBuffers[_MAX_RESULTS];

/**********************************************************************************************************************/

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    _g_CB = prhs[0];

    unsigned int mode = (unsigned int)mxGetScalar(prhs[1]);

    switch (mode) {
    case 0: _Claim  (nlhs, plhs, nrhs - 2, prhs + 2); break;
    case 1: _Release(nlhs, plhs, nrhs - 2, prhs + 2); break;
    case 2: _Init   (nlhs, plhs, nrhs - 2, prhs + 2); break;
    case 3: _Done   (nlhs, plhs, nrhs - 2, prhs + 2); break;
    case 4: _Run    (nlhs, plhs, nrhs - 2, prhs + 2); break;
    case 5: _Get    (nlhs, plhs, nrhs - 2, prhs + 2); break;
    case 6: _Set    (nlhs, plhs, nrhs - 2, prhs + 2); break;
    }

}

/**********************************************************************************************************************/

void _Claim(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    _g_initLevel = 1;
    _g_exitLevel = 0;

    int desiredDeviceNo = (int)mxGetScalar(prhs[0]);
    bool nice = ((int)mxGetScalar(prhs[1]) > 0);

    _ClaimDevice(desiredDeviceNo, nice, _g_props);

    mxArray *p = mxCreateStructMatrix(1, 1, 0, NULL);

    mxSetFieldByNumber(p, 0, mxAddField(p, "deviceNo"       ), mxCreateDoubleScalar(_g_props.deviceNo       ));
    mxSetFieldByNumber(p, 0, mxAddField(p, "blockSizeAlign" ), mxCreateDoubleScalar(_g_props.blockSizeAlign ));
    mxSetFieldByNumber(p, 0, mxAddField(p, "blockYSizeAlign"), mxCreateDoubleScalar(_g_props.blockYSizeAlign));
    mxSetFieldByNumber(p, 0, mxAddField(p, "maxTexYSize"    ), mxCreateDoubleScalar(_g_props.maxTexYSize    ));
    mxSetFieldByNumber(p, 0, mxAddField(p, "maxTexXSize"    ), mxCreateDoubleScalar(_g_props.maxTexXSize    ));
    mxSetFieldByNumber(p, 0, mxAddField(p, "maxCData"       ), mxCreateDoubleScalar(_MAX_CDATA              ));
    mxSetFieldByNumber(p, 0, mxAddField(p, "maxCMeta"       ), mxCreateDoubleScalar(_MAX_CMETA              ));
    mxSetFieldByNumber(p, 0, mxAddField(p, "minBlockSize"   ), mxCreateDoubleScalar(_LAYERDATA_UINTS        ));

    plhs[0] = p;

    mexLock();
    mexAtExit(_AtExit);

}

/**********************************************************************************************************************/

void _Release(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    _g_exitLevel = 0;

    _Dealloc();

}

/**********************************************************************************************************************/

void _AtExit() {

    _g_exitLevel = 0;

    _Dealloc();

}

/**********************************************************************************************************************/

void _Init(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    _g_initLevel = 2;
    _g_exitLevel = 1;

    _ClearConst("_g_cData", _g_cData);
    _ClearConst("_g_cMeta", _g_cMeta);

    for (int f = 0; f < _NUM_T; f++) {
        _ClearTex(*_GetTTexA(f), *_GetTTexB(f));
    }

    for (int f = 0; f < _NUM_CC; f++) {
        _ClearTex(*_GetCTexA(f), *_GetCTexB(f));
    }

    for (int f = 0; f < _NUM_CV; f++) {
        _ClearTex(*_GetVTexA(f), *_GetVTexB(f));
        _ClearBuf(_g_tOut.m_ptr[f]);
    }

    _ClearBuf(_g_dData    );
    _ClearBuf(_g_dWData   );
    _ClearBuf(_g_dWOut    );
    _ClearBuf(_g_dNeurons );
    _ClearBuf(_g_dSynapses);
    _ClearBuf(_g_dBlocks  );
    _ClearBuf(_g_dLayers  );

    _ClearHostBuf(_g_hKernelZs);

    _g_lCount = 0;
    _g_kCount = 0;

    const mxArray *s = prhs[0];
    const mxArray *h = prhs[1];

    _g_independent = ((int)mxGetScalar(mxGetField(s, 0, "independent")) > 0);

    _g_mvOff = (unsigned int)mxGetScalar(mxGetField(s, 0, "mvOff"));
    _g_cOff  = (unsigned int)mxGetScalar(mxGetField(s, 0, "cOff" ));

    const mxArray *tTData = mxGetField(h, 0, "tTData");
    for (int f = 0; f < _NUM_T; f++) {
        const mxArray *tex = mxGetCell(tTData, f);
        unsigned int yCount = mxGetM(tex);
        unsigned int xCount = mxGetN(tex);
        _AllocTexArray(*_GetTTexA(f), *_GetTTexB(f), tex, yCount, xCount, "texture constants");
    }

    const mxArray *tCData = mxGetField(h, 0, "tCData");
    for (int f = 0; f < _NUM_CC; f++) {
        const mxArray *tex = mxGetCell(tCData, f);
        unsigned int ySize  = mxGetM(tex);
        unsigned int xCount = mxGetN(tex);
        _AllocTexArray(*_GetCTexA(f), *_GetCTexB(f), tex, ySize, xCount, "common constants");
    }

    const mxArray *tVData = mxGetField(h, 0, "tVData");
    for (int f = 0; f < _NUM_CV; f++) {
        const mxArray *tex = mxGetCell(tVData, f);
        unsigned int ySize  = mxGetM(tex);
        unsigned int xCount = mxGetN(tex);
        _AllocBufA(_g_tOut.m_ptr[f], tex, 1, "common variables output");
        _g_tOut.m_h[f] = ySize;
        _g_tOut.m_w[f] = xCount;
        if (_g_independent) {
            _AllocTexLinear(*_GetVTexA(f), *_GetVTexB(f), _g_tOut.m_ptr[f], ySize, xCount, "common variables");
        } else {
            _AllocTexArray (*_GetVTexA(f), *_GetVTexB(f), NULL            , ySize, xCount, "common variables");
        }
    }

    _g_wCount = mxGetNumberOfElements(mxGetField(h, 0, "dWData"));

    _AllocBufA(_g_dData    , mxGetField(h, 0, "dData"    ), 1, "device memory");
    _AllocBufA(_g_dWOut    , mxGetField(h, 0, "dWData"   ), 1, "cell variables output");
    _AllocBufA(_g_dNeurons , mxGetField(h, 0, "dNeurons" ), 1, "neurons");
    _AllocBufA(_g_dSynapses, mxGetField(h, 0, "dSynapses"), 4, "synapses");
    _AllocBufA(_g_dBlocks  , mxGetField(h, 0, "dBlocks"  ), 4, "blocks");

    if (_g_independent) {
        _g_dWData = _g_dWOut;
    } else {
        _AllocBufB(_g_dWData, (float *)NULL, _g_wCount, "cell variables");
    }

    _AllocHostBufA(_g_hKernelZs, mxGetField(h, 0, "hKernelZs"), 1, "kernel zs");

    const mxArray *layers = mxGetField(s, 0, "layers");
    unsigned int lCount = mxGetNumberOfElements(layers);
    if (lCount > _MAX_LAYERS) {
        _Exit("maximum number of layers (%u) exceeded", _MAX_LAYERS);
    }
    for (unsigned int z = 0; z < lCount; z++) {
        _g_layers[z] = new _Layer();
        _g_lCount = z + 1;
        _g_layers[z]->LInit(layers, z);
    }

    if (sizeof(_LayerData) != _LAYERDATA_UINTS * sizeof(unsigned int)) {
        _Exit("size of LayerData structure is not %u bytes", _LAYERDATA_UINTS * sizeof(unsigned int));
    }
    _LayerData layerData[_MAX_LAYERS];
    for (unsigned int z = 0; z < lCount; z++) {
        layerData[z] = *(_LayerData *)_g_layers[z];
    }
    _AllocBufB(_g_dLayers, layerData, lCount, "layer data");

    const mxArray *kernels = mxGetField(s, 0, "kernels");
    unsigned int kCount = mxGetNumberOfElements(kernels);
    if (kCount > _MAX_KERNELS) {
        _Exit("maximum number of kernels (%u) exceeded", _MAX_KERNELS);
    }
    for (unsigned int k = 0; k < kCount; k++) {
        _g_kernels[k] = new _Kernel();
        _g_kCount = k + 1;
        _g_kernels[k]->KInit(kernels, k);
    }

    _g_iterNo = 0;

    const mxArray *cData = mxGetField(h, 0, "cData");
    const mxArray *cMeta = mxGetField(h, 0, "cMeta");
    _AllocConst("_g_cData", _g_cData, (float          *)mxGetData(cData), mxGetNumberOfElements(cData));
    _AllocConst("_g_cMeta", _g_cMeta, (unsigned short *)mxGetData(cMeta), mxGetNumberOfElements(cMeta));

}

/**********************************************************************************************************************/

void _Done(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    _g_exitLevel = 1;

    _Dealloc();

}

/**********************************************************************************************************************/

void _Dealloc() {

    if ((_g_initLevel >= 3) && (_g_exitLevel < 3)) {

        for (unsigned int i = 0; i < _g_holdBufferCount; i++) {
            _DeallocBuf(_g_holdBuffers[i]);
        }
        _g_holdBufferCount = 0;

        _g_initLevel = 2;

    }

    if ((_g_initLevel >= 2) && (_g_exitLevel < 2)) {

        _DeallocConst("_g_cData", _g_cData);
        _DeallocConst("_g_cMeta", _g_cMeta);

        for (int f = 0; f < _NUM_T; f++) {
            _DeallocTex(*_GetTTexA(f), *_GetTTexB(f));
        }

        for (int f = 0; f < _NUM_CC; f++) {
            _DeallocTex(*_GetCTexA(f), *_GetCTexB(f));
        }

        for (int f = 0; f < _NUM_CV; f++) {
            _DeallocTex(*_GetVTexA(f), *_GetVTexB(f));
            _DeallocBuf(_g_tOut.m_ptr[f]);
        }

        _DeallocBuf(_g_dData    );
        _DeallocBuf(_g_dWOut    );
        _DeallocBuf(_g_dNeurons );
        _DeallocBuf(_g_dSynapses);
        _DeallocBuf(_g_dBlocks  );
        _DeallocBuf(_g_dLayers  );

        if (_g_independent) {
            _ClearBuf(_g_dWData);
        } else {
            _DeallocBuf(_g_dWData);
        }

        _DeallocHostBuf(_g_hKernelZs);

        for (unsigned int z = 0; z < _g_lCount; z++) {
            delete _g_layers[z];
        }
        _g_lCount = 0;

        for (unsigned int k = 0; k < _g_kCount; k++) {
            delete _g_kernels[k];
        }
        _g_kCount = 0;

        _g_initLevel = 1;

    }

    if ((_g_initLevel >= 1) && (_g_exitLevel < 1)) {

        _ReleaseDevice();

        mexUnlock();

        _g_initLevel = 0;

    }

}

/**********************************************************************************************************************/

void _Exit(const char *format, ...) {

    _Dealloc();

    char msg[_ERRMSG_LEN];

    va_list argList;
    va_start(argList, format);
    vsprintf(msg, format, argList);
    va_end(argList);

    mexErrMsgTxt(msg);

}

/**********************************************************************************************************************/

void _Layer::LInit(const mxArray *layers, unsigned int z) {

    m_yCount0    = (unsigned int)mxGetScalar(mxGetField(layers, z, "yCount0"   ));
    m_ySize0     = (unsigned int)mxGetScalar(mxGetField(layers, z, "ySize0"    ));
    m_yCount     = (unsigned int)mxGetScalar(mxGetField(layers, z, "yCount"    ));
    m_ySize      = (unsigned int)mxGetScalar(mxGetField(layers, z, "ySize"     ));
    m_xCount     = (unsigned int)mxGetScalar(mxGetField(layers, z, "xCount"    ));
    m_sSize      = (unsigned int)mxGetScalar(mxGetField(layers, z, "sSize"     ));
    m_gmvOff     = (unsigned int)mxGetScalar(mxGetField(layers, z, "gmvOff"    ));
    m_mvOff      = (unsigned int)mxGetScalar(mxGetField(layers, z, "mvOff"     ));
    m_gcOff      = (unsigned int)mxGetScalar(mxGetField(layers, z, "gcOff"     ));
    m_cOff       = (unsigned int)mxGetScalar(mxGetField(layers, z, "cOff"      ));
    m_tOff       = (unsigned int)mxGetScalar(mxGetField(layers, z, "tOff"      ));
    m_blockYSize = (unsigned int)mxGetScalar(mxGetField(layers, z, "blockYSize"));

    m_ndPtr = _g_dData     + (unsigned int)mxGetScalar(mxGetField(layers, z, "ndOff"));
    m_nwPtr = _g_dWData    + (unsigned int)mxGetScalar(mxGetField(layers, z, "nwOff"));
    m_nwOut = _g_dWOut     + (unsigned int)mxGetScalar(mxGetField(layers, z, "nwOff"));
    m_nmPtr = _g_dNeurons  + (unsigned int)mxGetScalar(mxGetField(layers, z, "nmOff"));
    m_sdPtr = _g_dData     + (unsigned int)mxGetScalar(mxGetField(layers, z, "sdOff"));
    m_smPtr = _g_dSynapses + (unsigned int)mxGetScalar(mxGetField(layers, z, "smOff"));

    const double *entry = mxGetPr(mxGetField(layers, z, "entry"));
    for (unsigned int i = 0; i < _LT_LEN; i++) {
        m_entry[i] = (unsigned short)entry[i];
    }

    m_z      = z;
    m_typeNo = (unsigned int)mxGetScalar(mxGetField(layers, z, "typeNo")) - 1;

}

/**********************************************************************************************************************/

float *_Layer::GetNDPtr() {

    return m_ndPtr;

}

/**********************************************************************************************************************/

float *_Layer::GetNWOut() {

    return m_nwOut;

}

/**********************************************************************************************************************/

float *_Layer::GetSDPtr() {

    return m_sdPtr;

}

/**********************************************************************************************************************/

void _Kernel::KInit(const mxArray *kernels, unsigned int k) {

    mxGetString(mxGetField(kernels, k, "type"), m_type, _NAME_LEN);

    m_typeNo    = (unsigned int)mxGetScalar(mxGetField(kernels, k, "typeNo"   )) - 1;
    m_stepNo    = (unsigned int)mxGetScalar(mxGetField(kernels, k, "stepNo"   )) - 1;
    m_phase     = (unsigned int)mxGetScalar(mxGetField(kernels, k, "phase"    )) - 1;
    m_blockSize = (unsigned int)mxGetScalar(mxGetField(kernels, k, "blockSize"));
    m_bCount    = (unsigned int)mxGetScalar(mxGetField(kernels, k, "bCount"   ));
    m_zCount    = (unsigned int)mxGetScalar(mxGetField(kernels, k, "zCount"   ));

    m_bPtr = _g_dBlocks   + (unsigned int)mxGetScalar(mxGetField(kernels, k, "bOff"));
    m_zPtr = _g_hKernelZs + (unsigned int)mxGetScalar(mxGetField(kernels, k, "zOff"));

    // We use both dimensions to avoid exceeding limits.  The particular 2D shapes of the grid and blocks are
    // irrelevant.

    if (m_bCount <= 65535) {
        m_gridXSize = 1;
        m_gridYSize = m_bCount;
    } else {
        m_gridXSize = (unsigned int)sqrt((double)m_bCount);
        m_gridYSize = (unsigned int)ceil((double)m_bCount / (double)m_gridXSize);
    }

    m_blockXSize = _g_props.blockSizeAlign;
    m_blockYSize = m_blockSize / _g_props.blockSizeAlign;

}

/**********************************************************************************************************************/

unsigned int _Kernel::StepNo() {

    return m_stepNo;

}

/**********************************************************************************************************************/

void _Run(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    _g_initLevel = 3;
    _g_exitLevel = 2;

    _g_holdBufferCount = 0;

    unsigned int iters      = (unsigned int)mxGetScalar(prhs[0]);
    unsigned int sampleRate = (unsigned int)mxGetScalar(prhs[1]);

    unsigned int step1;
    unsigned int step2;
    bool         increment;
    if ((unsigned int)mxGetScalar(prhs[2]) == 0) {
        step1     = 0;
        step2     = _g_kCount; // Essentially, infinity.  Will never be less than the number of steps.
        increment = true;
    } else {
        step1     = (unsigned int)mxGetScalar(prhs[2]) - 1;
        step2     = (unsigned int)mxGetScalar(prhs[3]) - 1;
        increment = false;
    }

    unsigned int totalSamples = iters / sampleRate;

    unsigned int numResults = mxGetNumberOfElements(prhs[4]);
    if (numResults > _MAX_RESULTS) {
        _Exit("maximum number of results (%u) exceeded", _MAX_RESULTS);
    }

    _Result results[_MAX_RESULTS];

    for (unsigned int i = 0; i < numResults; i++) {
        results[i].RInit(prhs[4], i, NULL);
        results[i].RAlloc(i, totalSamples, plhs[i], true);
    }

    unsigned int itersUntilSample = sampleRate;
    unsigned int sampleNo         = 0;

    for (unsigned int i = 0; i < iters; i++) {

        unsigned int prevStep = _g_kCount; // Infinity.

        for (unsigned int k = 0; k < _g_kCount; k++) {

            unsigned int thisStep = _g_kernels[k]->StepNo();

            if ((step1 <= thisStep) && (thisStep <= step2)) {

                if (!_g_independent && (prevStep != thisStep)) {
                    for (int f = 0; f < _NUM_CV; f++) {
                        _PublishTex(*_GetVTexA(f), *_GetVTexB(f), _g_tOut.m_ptr[f], _g_tOut.m_h[f], _g_tOut.m_w[f], "common variables");
                    }
                    _CopyBuf1D(_g_dWData, 'd', _g_dWOut, _g_wCount, "cell variables output");
                }

                _g_kernels[k]->KRun();

            }

            prevStep = thisStep;

        }

        if (--itersUntilSample == 0) {
            for (unsigned int j = 0; j < numResults; j++) {
                results[j].SampleToHold(sampleNo);
            }
            itersUntilSample = sampleRate;
            sampleNo++;
        }

        if (increment) {
            if (_g_iterNo < (unsigned int)CNS_INTMAX - 1) {
                _g_iterNo++;
            } else {
                _g_iterNo = 0;
            }
        }

    }

    for (unsigned int i = 0; i < numResults; i++) {
        results[i].HoldToResult(totalSamples);
    }

    _Dealloc();

}

/**********************************************************************************************************************/

void _Get(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    _g_exitLevel = 2;

    _Result result;

    result.RInit(prhs[0], 0, NULL);
    result.RAlloc(0, 1, plhs[0], false);

    result.SampleToResult();

}

/**********************************************************************************************************************/

void _Set(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    _g_exitLevel = 2;

    _Result result;

    result.RInit(prhs[0], 0, prhs[1]);

    result.Update();

}

/**********************************************************************************************************************/

void _Result::RInit(const mxArray *p, unsigned int resultNo, const mxArray *res) {

    m_varType = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "varType"));
    m_pos     = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "pos"    ));

    switch (m_varType) {
    case 0: m_sBuf = NULL                        ; break; // *p
    case 1: m_sBuf = _g_dData + m_pos            ; break; // *a
    case 2: m_sBuf = NULL                        ; break; // *t
    case 3: m_sBuf = NULL                        ; break; // cc
    case 4: m_sBuf = _g_tOut.m_ptr[m_pos]        ; break; // cv
    case 5: m_sBuf = _g_layers[m_pos]->GetNDPtr(); break; // nc, nv
    case 6: m_sBuf = _g_layers[m_pos]->GetNWOut(); break; // nw
    case 7: m_sBuf = _g_layers[m_pos]->GetSDPtr(); break; // s*
    case 8: m_sBuf = NULL                        ; break; // sp
    }

    m_sBufH = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "height"));
    m_sBufW = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "width" ));

    m_hOff = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "hOff"));
    m_wOff = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "wOff"));
    m_dOff = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "dOff"));

    m_hCount = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "hCount"));
    m_wCount = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "wCount"));
    m_dCount = (unsigned int)mxGetScalar(mxGetField(p, resultNo, "dCount"));

    if (res == NULL) {
        m_rBuf = NULL;
    } else {
        m_rBuf = (float *)mxGetData(res);
    }

    double *siz4b = mxGetPr(mxGetField(mxGetField(p, resultNo, "t"), 0, "siz4b"));
    m_rBufH = (unsigned int)siz4b[0];
    m_rBufW = (unsigned int)siz4b[1];

    m_rCount = m_rBufH * m_rBufW * m_dCount;

    m_hBuf = NULL;

}

/**********************************************************************************************************************/

void _Result::RAlloc(unsigned int resultNo, unsigned int totalSamples, mxArray *&res, bool needHold) {

    res = mxCreateNumericMatrix(m_rCount, totalSamples, mxSINGLE_CLASS, mxREAL);
    m_rBuf = (float *)mxGetData(res);

    if (needHold) {

        #ifdef _GPU
            _AllocBufB(m_hBuf, (float *)NULL, m_rCount * totalSamples, "result");
            _g_holdBufferCount = resultNo + 1;
            _g_holdBuffers[resultNo] = m_hBuf;
        #else
            m_hBuf = m_rBuf;
        #endif

    } else {

        m_hBuf = NULL;

    }

}

/**********************************************************************************************************************/

#ifdef _GPU

    void _Kernel::KRun() {

        if (m_bCount == 0) return;

        dim3 gridDim;
        dim3 blockDim;
        gridDim.x  = m_gridYSize;
        gridDim.y  = m_gridXSize;
        gridDim.z  = 1;
        blockDim.x = m_blockYSize;
        blockDim.y = m_blockXSize;
        blockDim.z = 1;

        switch (m_typeNo) {
        #include _USER_ALLKERNELS_RUN
        default:
            _Exit("invalid type number (%u)", m_typeNo + 1);
            break;
        }

    }

#else

    void _Kernel::KRun() {

        for (unsigned int i = 0; i < m_zCount; i++) {
            _g_layers[m_zPtr[i]]->LRun(m_phase);
        }

    }

    void _Layer::LRun(unsigned int phase) {

        switch (m_typeNo) {
        #include _USER_ALLKERNELS_RUN
        default:
            _Exit("invalid type number (%u)", m_typeNo + 1);
            break;
        }

    }

#endif

/**********************************************************************************************************************/

#include "kernel_macros.h"

#include _USER_ALLKERNELS_DEF

/**********************************************************************************************************************/

void _NeuronExit(unsigned int z, unsigned int y, unsigned int x, const char *format, ...) {

    _Dealloc();

    char msg[_ERRMSG_LEN];

    sprintf(msg, "iter_no=%u z=%u i=%u: ", _g_iterNo, z + 1, _CBYX2E(z, y, x) + 1);

    va_list argList;
    va_start(argList, format);
    vsprintf(msg + strlen(msg), format, argList);
    va_end(argList);

    mexErrMsgTxt(msg);

}

/**********************************************************************************************************************/

void _NeuronInfo(unsigned int z, unsigned int y, unsigned int x, const char *format, ...) {

    char msg[_ERRMSG_LEN];

    sprintf(msg, "iter_no=%u z=%u i=%u: ", _g_iterNo, z + 1, _CBYX2E(z, y, x) + 1);

    va_list argList;
    va_start(argList, format);
    vsprintf(msg + strlen(msg), format, argList);
    va_end(argList);

    mexPrintf("%s\n", msg);
    mexEvalString("drawnow");

}

/**********************************************************************************************************************/

void _Result::SampleToHold(unsigned int sampleNo) {

    _CopyBuf3D(
        m_hBuf + sampleNo * m_rCount, m_rBufH, m_rBufW, 'd',
        m_sBuf, m_sBufH, m_sBufW, m_hOff, m_wOff, m_dOff,
        m_hCount, m_wCount, m_dCount,
        "variables");

}

/**********************************************************************************************************************/

void _Result::HoldToResult(unsigned int totalSamples) {

    #ifdef _GPU
        _CopyBuf1D(m_rBuf, 'h', m_hBuf, m_rCount * totalSamples, "hold");
    #endif

}

/**********************************************************************************************************************/

void _Result::SampleToResult() {

    switch (m_varType) {
    case 0:
        _CopyConst(m_rBuf, "_g_cData", _g_cData, m_hOff, m_hCount);
        break;
    case 1:
    case 4:
    case 5:
    case 6:
    case 7:
        _CopyBuf3D(
            m_rBuf, m_rBufH, m_rBufW, 'h',
            m_sBuf, m_sBufH, m_sBufW, m_hOff, m_wOff, m_dOff,
            m_hCount, m_wCount, m_dCount,
            "variables");
        break;
    case 2:
        _CopyTex(
            m_rBuf, m_rBufH, 'h',
            *_GetTTexA(m_pos), *_GetTTexB(m_pos), m_hOff, m_wOff,
            m_hCount, m_wCount,
            "texture constants");
        break;
    case 3:
        _CopyTex(
            m_rBuf, m_rBufH, 'h',
            *_GetCTexA(m_pos), *_GetCTexB(m_pos), m_hOff, m_wOff,
            m_hCount, m_wCount,
            "common constants");
        break;
    case 8:
        *m_rBuf = _IntAsFloat((int)_g_iterNo);
        break;
    }

}

/**********************************************************************************************************************/

void _Result::Update() {

    switch (m_varType) {
    case 0:
        _UpdateConst("_g_cData", _g_cData, m_hOff, m_rBuf, m_hCount);
        break;
    case 1:
    case 4:
    case 5:
    case 6:
    case 7:
        _UpdateBuf3D(
            m_sBuf, m_sBufH, m_sBufW, m_hOff, m_wOff, m_dOff,
            m_rBuf, m_rBufH, m_rBufW, 'h',
            m_hCount, m_wCount, m_dCount,
            "variables");
        break;
    case 2:
        _UpdateTex(
            *_GetTTexA(m_pos), *_GetTTexB(m_pos), m_hOff, m_wOff,
            m_rBuf, m_rBufH, 'h',
            m_hCount, m_wCount,
            "texture constants");
        break;
    case 3:
        _UpdateTex(
            *_GetCTexA(m_pos), *_GetCTexB(m_pos), m_hOff, m_wOff,
            m_rBuf, m_rBufH, 'h',
            m_hCount, m_wCount,
            "common constants");
        break;
    case 8:
        _g_iterNo = (unsigned int)_FloatAsInt(*m_rBuf);
        break;
    }

}

/**********************************************************************************************************************/

#include "common_def.h"

#include "util_def.h"
