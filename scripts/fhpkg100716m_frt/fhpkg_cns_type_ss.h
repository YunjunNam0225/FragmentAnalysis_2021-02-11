// Compute kernel for an "ss" cell.  Note the specific response function is left to subtypes.

#TEMPLATE

LAYER_PTR z = PZS(0);
int nf0 = THIS_F0;
int nf1 = THIS_F1;
int rfCount = READ_FSIZES(nf0, nf1);
int rfSpace = RFSPACE;
int rfWidth = 1 + (rfCount - 1) * rfSpace;

// Find nearest (rfWidth) input cells in y and x.  If this takes us off an edge, quit.
int y1, x1, dummy;
if (!GET_LAYER_Y_RF_NEAR(z, rfWidth, y1, dummy) || !GET_LAYER_X_RF_NEAR(z, rfWidth, x1, dummy)) {
    WRITE_VAL(CNS_FLTMIN);
    return;
}

FVALS_HANDLE hw = GET_FVALS_HANDLE;
FMAP2_HANDLE hm = GET_FMAP2_HANDLE;
int pCount = READ_FMAP2_HANDLE(hm, 0, nf0, nf1);
VAL_HANDLE hv = GET_LAYER_VAL_HANDLE(z);

float res;

#PART start

for (int p = 0; p < pCount; p++) {

    float w = READ_FVALS_HANDLE(hw, p    , nf0, nf1);
    int   m = READ_FMAP2_HANDLE(hm, p + 1, nf0, nf1);

    int f0 =   m & 0x000000FF;
    int f1 =  (m & 0x0000FF00) >>  8;
    int y  = ((m & 0x00FF0000) >> 16) * rfSpace + y1;
    int x  = ((m & 0xFF000000) >> 24) * rfSpace + x1;

    float v = READ_VAL_HANDLE(hv, f0, f1, y, x);
    if (v == CNS_FLTMIN) {
        res = CNS_FLTMIN;
        goto done;
    }

    #PART middle

}

#PART end

done:
WRITE_VAL(res);
