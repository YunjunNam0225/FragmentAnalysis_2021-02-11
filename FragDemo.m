clear;close all;
load('Exam_Frag_Stim.mat');

FR_OPTION=init_fr();

% FR_OPTION.CNS.platform='cpu'; 
    % If you cannot use GPU, you may change it to 'cpu' with slower speed.

%% predict responses for the stimuli (in the third Param.) from the
%  feature candidate (in the second Param.)
nFrag=size(cFRAG,2);
nStim=size(cSTIM,2);
dRes=zeros(nFrag,nStim);
for iFrag=1:nFrag
    dRes(iFrag,:)=calculate_fragment_response(FR_OPTION,cFRAG{iFrag},cSTIM);
end

%% Visualize the sub-region of one stimulus (in the third Param.) captured
%  by the feature candidate (in the second Param.)
iFrag=1;iStim=1279;  % example No. to draw Stim. 1 in Sup. Fig. 4
explain_fragment_response(FR_OPTION,cFRAG{iFrag},cSTIM{iStim});

