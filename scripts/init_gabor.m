function [fSiz,filters,c1OL,numSimpleFilters] = init_gabor(rot, RF_siz, Div)
% function init_gabor(rot, RF_siz, Div)
% rot: [90 -45 0 45], RF_siz: [7:2:39], Div = [4:-.05:3.2]
% Thomas R. Serre
% Feb. 2003

c1OL             = 2;
numFilterSizes   = length(RF_siz); % 17
numSimpleFilters = length(rot); % 4
numFilters       = numFilterSizes*numSimpleFilters; % 17*4=68
fSiz             = zeros(numFilters,1);	% vector with filter sizes 68x1
filters          = zeros(max(RF_siz)^2,numFilters); % 39^2x68=1521x68

lambda = RF_siz*2./Div; % [7:2:39]*2./[4:-.05:3.2]=[7*2/4,...,39*2/3.2]
sigma  = lambda.*0.8;
G      = 0.3;   % spatial aspect ratio: 0.23 < gamma < 0.92

for k = 1:numFilterSizes % 1:17
    for r = 1:numSimpleFilters % 1:4
        theta     = rot(r)*pi/180;        % {90,-45,0,45}*pi/180
        filtSize  = RF_siz(k);            % {7,9,...,39}
        center    = ceil(filtSize/2);     % {4,5,...,20}
        filtSizeL = center-1;             % {3,4,...,19}
        filtSizeR = filtSize-filtSizeL-1; % {3,4,...,19}
        sigmaq    = sigma(k)^2;
        
        for i = -filtSizeL:filtSizeR % {-3:3,-4:4,...,-19:19}
            for j = -filtSizeL:filtSizeR % {-3:3,-4:4,...,-19:19}
                
                if ( sqrt(i^2+j^2)>filtSize/2 )
                    E = 0;
                else
                    x = i*cos(theta) - j*sin(theta);
                    y = i*sin(theta) + j*cos(theta);
                    E = exp(-(x^2+G^2*y^2)/(2*sigmaq))*cos(2*pi*x/lambda(k));
                end
                f(j+center,i+center) = E;
            end
        end
       
        f = f - mean(mean(f));
        f = f ./ sqrt(sum(sum(f.^2)));
        p = numSimpleFilters*(k-1) + r; % 4*{1:17-1}+{1:4}
        filters(1:filtSize^2,p)=reshape(f,filtSize^2,1); % filters(1:{7,9,...,39}^2,p)=reshape(,{7,9,...,39}^2,1)
        fSiz(p)=filtSize; % {7,9,...,39}
        clear f;
    end
end
