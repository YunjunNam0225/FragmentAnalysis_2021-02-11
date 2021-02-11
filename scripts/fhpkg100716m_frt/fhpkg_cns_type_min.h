// Pooling function for a "min" cell.

#PART start

    res = CNS_FLTMAX;

#PART middle

//    res = fminf(res, v);
    res = -fmaxf(-res, -v);

#PART end
