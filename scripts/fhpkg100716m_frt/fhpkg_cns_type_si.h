// Compute kernel for an "si" cell.  A port of MATLAB's imresize using bicubic interpolation.

LAYER_PTR z = PZS(0);

float pySpace = LAYER_Y_SPACE(z);
float pxSpace = LAYER_X_SPACE(z);
float yFactor = pySpace / Y_SPACE;
float xFactor = pxSpace / X_SPACE;

int   yWidth  = (yFactor < 1) ? (int)ceilf(4.0f / yFactor) : 4;
int   xWidth  = (xFactor < 1) ? (int)ceilf(4.0f / xFactor) : 4;
float yAdjust = (yFactor < 1) ? yFactor : 1.0f;
float xAdjust = (xFactor < 1) ? xFactor : 1.0f;

int vy1, vy2, y1, y2;
int vx1, vx2, x1, x2;
GET_LAYER_Y_RF_NEAR(z, yWidth, vy1, vy2, y1, y2);
GET_LAYER_X_RF_NEAR(z, xWidth, vx1, vx2, x1, x2);
vy2 = min(vy2, PY_COUNT - 1);
vx2 = min(vx2, PX_COUNT - 1);
if ((2 * (vy2 - vy1 + 1) < yWidth) || (2 * (vx2 - vx1 + 1) < xWidth)) {
    WRITE_VAL(CNS_FLTMIN);
    return;
}

float yPixStart = (LAYER_Y_CENTER(z, y1) - THIS_Y_CENTER) / pySpace;
float xPixStart = (LAYER_X_CENTER(z, x1) - THIS_X_CENTER) / pxSpace;
VAL_HANDLE h = GET_LAYER_VAL_HANDLE(z);
float num = 0.0f;
float den = 0.0f;

float xPix = xPixStart;
for (int x = x1; x <= x2; x++, xPix += 1.0f) {

    int vx = (x < vx1) ? vx1 : (x > vx2) ? vx2 : x;
    float absx = xAdjust * fabsf(xPix);

    float wx;
    if (absx <= 1.0f) {
        wx = (1.5f * absx - 2.5f) * absx * absx + 1.0f;
    } else if (absx <= 2.0f) {
        wx = ((-0.5f * absx + 2.5f) * absx - 4.0f) * absx + 2.0f;
    } else {
        wx = 0.0f;
    }

    float yPix = yPixStart;
    for (int y = y1; y <= y2; y++, yPix += 1.0f) {

        int vy = (y < vy1) ? vy1 : (y > vy2) ? vy2 : y;
        float absy = yAdjust * fabsf(yPix);

        float wy;
        if (absy <= 1.0f) {
            wy = (1.5f * absy - 2.5f) * absy * absy + 1.0f;
        } else if (absy <= 2.0f) {
            wy = ((-0.5f * absy + 2.5f) * absy - 4.0f) * absy + 2.0f;
        } else {
            wy = 0.0f;
        }

        num += wy * wx * READ_VAL_HANDLE(h, 0, 0, vy, vx);
        den += wy * wx;

    }
}

WRITE_VAL(fminf(fmaxf(num / den, 0.0f), 1.0f));
