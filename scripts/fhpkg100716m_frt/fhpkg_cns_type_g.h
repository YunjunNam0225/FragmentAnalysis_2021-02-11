// Compute kernel for a "g" cell.  Note the specific pooling function is left to subtypes.

#TEMPLATE

int f0 = THIS_F0;
int f1 = THIS_F1;

int sPos = READ_FSPOS(f0, f1);
int s1 = max(sPos - STOL, 0          );
int s2 = min(sPos + STOL, NUM_PZS - 1);

// Figure out the RF center and radius in common coordinates.
float ySize = YCOUNT(0) * LAYER_Y_SPACE(PZS(0));
float xSize = XCOUNT(0) * LAYER_X_SPACE(PZS(0));
float yCenter = THIS_Y_CENTER + (READ_FYPOS(f0, f1) - 0.5f) * ySize;
float xCenter = THIS_X_CENTER + (READ_FXPOS(f0, f1) - 0.5f) * xSize;
float yRad = YXTOL * ySize;
float xRad = YXTOL * xSize;

float res;

#PART start

for (int s = s1; s <= s2; s++) {

    LAYER_PTR z = PZS(s);

    // Find all cells within the RF radius of the center at this scale.
    int y1, y2, x1, x2;
    GET_LAYER_Y_RF_DIST_AT(z, yCenter, yRad, y1, y2);
    GET_LAYER_X_RF_DIST_AT(z, xCenter, xRad, x1, x2);

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
