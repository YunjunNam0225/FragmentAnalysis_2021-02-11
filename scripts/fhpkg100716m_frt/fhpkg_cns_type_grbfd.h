// Response function for a "grbfd" cell.

#PART start

    res = 0.0f;
    float rfRatio = (float)rfCount / (float)RFCOUNTMIN;

#PART middle

    float diff = v - w;
    res -= diff * diff;

#PART end

    res = expf(res / (2.0f * SIGMA * SIGMA * rfRatio * rfRatio));
