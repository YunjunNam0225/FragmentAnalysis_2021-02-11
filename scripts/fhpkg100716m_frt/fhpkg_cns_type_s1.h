// Compute kernel for an "s1" cell.  Note the specific response function is left to subtypes.

#TEMPLATE

LAYER_PTR z = PZS(0);

FVALS_HANDLE hw = GET_FVALS_HANDLE;
int rfCount = FVALS_HANDLE_Y_SIZE(hw);

// Find nearest (rfCount) input cells in y and x.  If this takes us off an edge, quit.
int y1, y2, x1, x2;
if (!GET_LAYER_Y_RF_NEAR(z, rfCount, y1, y2) || !GET_LAYER_X_RF_NEAR(z, rfCount, x1, x2)) {
    WRITE_VAL(CNS_FLTMIN);
    return;
}

VAL_HANDLE hv = GET_LAYER_VAL_HANDLE(z);
int f0 = THIS_F0;
int f1 = THIS_F1;

float res;

#PART start

for (int j = 0, x = x1; x <= x2; j++, x++) {
    for (int i = 0, y = y1; y <= y2; i++, y++) {

        float w = READ_FVALS_HANDLE(hw, i, j, f0, f1);
        float v = READ_VAL_HANDLE(hv, 0, 0, y, x);
        if (v == CNS_FLTMIN) {
            res = CNS_FLTMIN;
            goto done;
        }

        #PART middle

    }
}

#PART end

done:
WRITE_VAL(res);
