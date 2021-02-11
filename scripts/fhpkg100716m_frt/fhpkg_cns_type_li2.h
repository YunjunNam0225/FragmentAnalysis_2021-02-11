// Compute kernel for an "li2" cell.

int y = THIS_Y;
int x = THIS_X;

float v      = READ_LAYER_VAL(PZS(0), THIS_F0, THIS_F1, y, x);
float cutoff = READ_LAYER_VAL(PZS(1), 0      , 0      , y, x);

float res = (v < cutoff) ? 0.0f : v;

WRITE_VAL(res);
