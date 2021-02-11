// Response function for an "ndp" cell.

#PART start

    res = 0.0f;
    float len = 0.0f;

#PART middle

    res += w * v;
    len += v * v;

#PART end

    res = fabsf(res);
    if (len > 0.0f) res /= sqrtf(len);
