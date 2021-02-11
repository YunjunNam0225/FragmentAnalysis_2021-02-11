// Compute kernel for an "sd" cell.  Note the specific response function is left to subtypes.

// Heavily optimized version.  Uses internal indices.

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
VAL_HANDLE   hv = GET_LAYER_VAL_HANDLE(z);
int fCount0 = FVALS_HANDLE_F0_SIZE(hw);
int fCount1 = FVALS_HANDLE_F1_SIZE(hw);

float res;

#PART start

for (int f1 = 0; f1 < fCount1; f1++) {
    for (int f0 = 0; f0 < fCount0; f0++) {

        int wp1, wq, vp1, vq;
        GET_FVALS_HANDLE_IPOS(hw, f0, f1, 0 , 0 , nf0, nf1, wp1, wq);
        GET_VAL_HANDLE_IPOS  (hv, f0, f1, y1, x1,           vp1, vq);

        #UNROLL_START 4 %j rfCount
            int wp = wp1;
            int vp = vp1;
            #UNROLL_START 4 %i rfCount

                float w = READ_FVALS_IPOS(wp, wq);
                float v = READ_VAL_IPOS  (vp, vq);
                if (v == CNS_FLTMIN) {
                    res = CNS_FLTMIN;
                    goto done;
                }

                #PART middle

                wp ++;
                vp += rfSpace;
            #UNROLL_END
            wq ++;
            vq += rfSpace;
        #UNROLL_END

    }
}

#PART end

done:
WRITE_VAL(res);
