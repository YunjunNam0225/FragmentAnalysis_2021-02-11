// Pooling function for a "gmax" cell.

#PART start

    res = CNS_FLTMIN;

#PART middle

    res = fmaxf(res, v);

#PART end
