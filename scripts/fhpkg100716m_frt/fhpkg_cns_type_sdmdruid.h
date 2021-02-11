// Compute kernel for an "sdm" cell.  Note the specific response function is left to subtypes.

// Less optimized version.  Does not use internal indices.

#TEMPLATE

LAYER_PTR z = PZS(0);
int nf0 = THIS_F0;
int nf1 = THIS_F1;
//int rfCountH = MPOS(2);//READ_FSIZES(nf0, nf1);
//int rfCountW = MPOS(3);//READ_FSIZES(nf0, nf1);
int rfCount = READ_FSIZES(nf0, nf1);
int rfSpace = RFSPACE;
int rfWidth = 1 + (rfCount - 1) * rfSpace;
//int rfWidth = 1 + (MPOS(1) - MPOS(0)) * rfSpace; //int rfWidth = 1 + (rfCount - 1) * rfSpace;

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

        int iFragPStart, iFragPEnd, iFragQStart, iFragQEnd;
        int iImageQStart, iImageP, iImageQ;
        // P: vertical 1 (up), N (down), Q: HORIZONTAL
        GET_FVALS_HANDLE_IPOS(hw, f0, f1, 0 , 0 , nf0, nf1, iFragPStart, iFragQStart);
        GET_VAL_HANDLE_IPOS  (hv, f0, f1, y1, x1,           iImageP, iImageQStart);

        
        iFragPEnd   = iFragPStart+MPOS(1);
        iFragPStart = iFragPStart+MPOS(0);
        iFragQEnd   = iFragQStart+MPOS(3);
        iFragQStart = iFragQStart+MPOS(2);
        
        iImageP = iImageP+MPOS(0);
        iImageQStart = iImageQStart+MPOS(2);
        #UNROLL_START 4 %iFragP iFragPStart <= iFragPEnd
            iImageQ=iImageQStart;            
            #UNROLL_START 4 %iFragQ iFragQStart <= iFragQEnd
                float w = READ_FVALS_IPOS(%iFragP , %iFragQ );
                float v = READ_VAL_IPOS  (iImageP, iImageQ);
                if (v == CNS_FLTMIN) {
                    res = CNS_FLTMIN;
                    goto done;
                }
                #PART middle

                iImageQ ++;
            #UNROLL_END
            iImageP ++;
        #UNROLL_END

    }
}


#PART end

done:
WRITE_VAL(res);
