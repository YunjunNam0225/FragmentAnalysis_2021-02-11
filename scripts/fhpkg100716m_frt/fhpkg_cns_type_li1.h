// Compute kernel for an "li1" cell.

LAYER_PTR z = PZS(0);
VAL_HANDLE h = GET_LAYER_VAL_HANDLE(z);
int fCount0 = LAYER_F0_SIZE(z);
int fCount1 = LAYER_F1_SIZE(z);
int y = THIS_Y;
int x = THIS_X;

int   vCount = 0;
float vMin   = 1.0f;
float vMax   = 0.0f;

for (int f1 = 0; f1 < fCount1; f1++) {
    for (int f0 = 0; f0 < fCount0; f0++) {

        float v = READ_VAL_HANDLE(h, f0, f1, y, x);

        if (v != CNS_FLTMIN) {
            vCount++;
            vMin = fminf(vMin, v);
            vMax = fmaxf(vMax, v);
        }

    }
}

float res;
if (vCount < 2) {
    res = CNS_FLTMIN;
} else {
    res = vMin + INHIBIT * (vMax - vMin);
}

WRITE_VAL(res);
