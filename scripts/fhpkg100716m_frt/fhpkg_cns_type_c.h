// Compute kernel for a "c" cell.  Note the specific pooling function is left to subtypes.

#TEMPLATE

int f0 = THIS_F0;
int f1 = THIS_F1;

// Figure out the RF radius in common coordinates.
int psize;
if (NUM_YCOUNT == 1) {
    psize = 0;
} else {
    int oldf0 = f0;
    f0    = oldf0 / NUM_YCOUNT;
    psize = oldf0 - f0 * NUM_YCOUNT;
}
float yRad = LAYER_Y_SPACE(PZS(0)) * 0.5f * YCOUNT(psize);
float xRad = LAYER_X_SPACE(PZS(0)) * 0.5f * XCOUNT(psize);

float res;

#PART start

for (int s = 0; s < NUM_PZS; s++) {

    LAYER_PTR z = PZS(s);

    // Find all cells within the RF radius at this scale.
    int y1, y2, x1, x2;
    GET_LAYER_Y_RF_DIST(z, yRad, y1, y2);
    GET_LAYER_X_RF_DIST(z, xRad, x1, x2);

    VAL_HANDLE h = GET_LAYER_VAL_HANDLE(z);

    for (int x = x1; x <= x2; x++) {
        for (int y = y1; y <= y2; y++) {

            float v = READ_VAL_HANDLE(h, f0, f1, y, x);

            #PART middle

        }
    }

}

#PART end

WRITE_VAL(res);
