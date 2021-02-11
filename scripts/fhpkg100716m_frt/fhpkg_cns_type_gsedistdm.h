// Response function for a "gsedistd" cell.

#PART start

    res = 0.0f;

#PART middle

    float diff = v - w;
    res += diff * diff * m;
    //res += diff * diff;

#PART end
