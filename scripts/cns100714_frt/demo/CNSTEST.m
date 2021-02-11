bLoop=true;iCount=0;
while(bLoop)
    try
    m = struct;

    m.package = 'demopkg';

    m.layers{1}.type    = 'input';
    m.layers{1}.pz      = 0;
    m.layers{1}.size{1} = 1;
    m = cns_mapdim(m, 1, 'y', 'pixels', 256);
    m = cns_mapdim(m, 1, 'x', 'pixels', 256);

    m.layers{2}.type    = 'scale';
    m.layers{2}.pz      = 1;
    m.layers{2}.size{1} = 1;
    m = cns_mapdim(m, 2, 'y', 'scaledpixels', 256, 2);
    m = cns_mapdim(m, 2, 'x', 'scaledpixels', 256, 2);

    platform = 'gpu';
    %platform = 'cpu'; % use this instead if you don't have a GPU

    fprintf(1,'gpu%d Check...    ',iCount);    
    cns('init', m,['gpu',num2str(iCount)]);    
    cns('done');    
    iCount=iCount+1;
    fprintf(1,'OK.\n');
    catch
        fprintf(1,'Failed.\n');
        k=1;
    end

end