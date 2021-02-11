// Response function for an "ncc" cell.

#PART start

    res = 0.0f;
    float len = 0.0f;
    float len2 = 0.0f;
    float num = 0.0f;
    float eps = 0.025f;
    float stdv = 0.0f;

#PART middle

    res += w * v;
    len += v;
    len2 += v * v;
    num++;

#PART end

    //res = fabsf(res);
    //stdv = sqrtf(len2-len*len/num)*num/(num-1.0f);
    stdv = sqrtf(fabsf(len2*num-len*len));
    if (stdv < eps) res = 0.0f;
    else res /= stdv;
