function extractAffordanceResFn_cd(model, outData, dirSaveRes)
% Run affordance SRF detection over dataset, and saves results to file for
% evaluation. 
%
% USAGE
%  extractAffordanceResFn_cd(model, outData, dirSaveRes)
%
% INPUT
%  model                - trained SRF affordance model (see script_trainSRFAff.m)
%  outData              - filepaths of data to be tested (see getDataFP_cd.m)
%  dirSaveRes           - directory where all results are to be saved
% 
% OUTPUT
%
% Copyright (c) 2015 Ching L. Teo, University of Maryland College Park [cteo-at-cs.umd.edu]
% Licensed under the Simplified BSD License [see license.txt]
% Please email me if you find bugs, or have suggestions or questions!

[nImgsP, nImgsN, imgP_fp, gtP_fp,...
    rgbP_fp, normP_fp, curveP_fp, imgN_fp, gtN_fp, rgbN_fp, normN_fp, curveN_fp]=deal(outData.nImgsP, outData.nImgsN,outData.imgP_fp,outData.gtP_fp,...
    outData.rgbP_fp, outData.normP_fp, outData.curveP_fp, outData.imgN_fp,...
    outData.gtN_fp,outData.rgbN_fp,outData.normN_fp,outData.curveN_fp);

% extract positives first
disp('processing positives...');
if ~exist(fullfile(dirSaveRes, 'WFb_scores.mat'), 'file')
WFbS_Pv=nan(nImgsP,1);
parfor i=1:nImgsP
    I=[];
    [~,name,~]=fileparts(imgP_fp{i,1}); nameF=name(1:end-9); nameS=name;
    if ~exist(imgP_fp{i,1},'file'), continue; end;
    D=load(imgP_fp{i,1}); 
    D=D.depth_clean; 
    RGB=imread(rgbP_fp{i,1}); 
    GT=load(gtP_fp{i,1}); GT=GT.gt_label; 
    normT=load(normP_fp{i,1}); DN=normT.normals;
    if ~exist(curveP_fp{i,1},'file'), continue; end;
    CV=load(curveP_fp{i,1}); 
    CV=CV.curvature;
    % resize RGB, GT
    GT=imresize(uint8(GT(model.opts.cropD{1}, model.opts.cropD{2})),0.5, 'nearest');  % crop labels
    BB_F=getBBF(GT);
    RGB=im2uint8(imresize(RGB(model.opts.cropD{1}, model.opts.cropD{2},:),0.5));
    
    % eval on cropped data
    D=imcrop(D,BB_F); DMask=D>0; DMask=imcrop(DMask,BB_F); RGB=imcrop(RGB,BB_F);
    DN = imcrop(DN, BB_F); GT=imcrop(GT,BB_F);  GT=GT==model.opts.targetID;
    CV1=imcrop(CV(:,:,1),BB_F); CV2=imcrop(CV(:,:,2),BB_F); CV=cat(3,CV1,CV2);
    
    D=single(D); RGB=im2single(RGB); CV=single(CV);
    if model.opts.rgbd == 0, I=RGB; end % {RGB}
    if model.opts.rgbd == 1, I=D; end %{Depth}
    if model.opts.rgbd == 2, I=cat(3,D,DN,CV); end %{Depth,Normal,Curvature}
    if model.opts.rgbd == 3, I=cat(3,D,RGB,DN,CV); end %{Depth,RGB,Normal}
    E=affDetect_norm(I,model);
    
    if sum(GT(:)>0),WFbS_Pv(i,1)=WFb(double(E),GT); end
    % write out detections
    dirSS=fullfile(dirSaveRes, nameF); if ~exist(dirSS,'dir'), mkdir(dirSS); end
    imwrite(E,fullfile(dirSS, [nameS '_resRF.png']));
end
% save scores
dlmwrite(fullfile(dirSaveRes, 'WFb_scores.mat'), WFbS_Pv);
end

if 1 
disp('processing negatives...');
if ~exist(fullfile(dirSaveRes, 'WFb_scores_neg.mat'), 'file')
WFbS_Nv=nan(nImgsN,1);
parfor i=1:nImgsN
    I=[];
    [~,name,~]=fileparts(imgN_fp{i,1}); nameF=name(1:end-9); nameS=name;
    if ~exist(imgN_fp{i,1},'file'), continue; end;
    D=load(imgN_fp{i,1}); 
    D=D.depth_clean; 
    RGB=imread(rgbN_fp{i,1}); 
    GT=load(gtN_fp{i,1}); GT=GT.gt_label; 
    normT=load(normN_fp{i,1}); DN=normT.normals;
    if ~exist(curveN_fp{i,1},'file'), continue; end;
    CV=load(curveN_fp{i,1}); 
    CV=CV.curvature;
    % resize RGB, GT
    GT=imresize(uint8(GT(model.opts.cropD{1}, model.opts.cropD{2})),0.5, 'nearest');  % crop labels
    BB_F=getBBF(GT);
    RGB=im2uint8(imresize(RGB(model.opts.cropD{1}, model.opts.cropD{2},:),0.5));
    
    % eval on cropped data
    D=imcrop(D,BB_F); DMask=D>0; DMask=imcrop(DMask,BB_F); RGB=imcrop(RGB,BB_F);
    DN = imcrop(DN, BB_F); GT=imcrop(GT,BB_F);  GT=GT==model.opts.targetID;
    CV1=imcrop(CV(:,:,1),BB_F); CV2=imcrop(CV(:,:,2),BB_F); CV=cat(3,CV1,CV2);
    
    D=single(D); RGB=im2single(RGB); CV=single(CV);
    if model.opts.rgbd == 0, I=RGB; end % {RGB}
    if model.opts.rgbd == 1, I=D; end %{Depth}
    if model.opts.rgbd == 2, I=cat(3,D,DN,CV); end %{Depth,Normal,Curvature}
    if model.opts.rgbd == 3, I=cat(3,D,RGB,DN,CV); end %{Depth,RGB,Normal}
    E=affDetect_norm(I,model);
    
    if sum(GT(:)>0),WFbS_Nv(i,1)=WFb(double(E),GT); end
    % write out detections
    dirSS=fullfile(dirSaveRes, nameF); if ~exist(dirSS,'dir'), mkdir(dirSS); end
    imwrite(E,fullfile(dirSS, [nameS '_resRF.png']));     
end
% save scores
dlmwrite(fullfile(dirSaveRes, 'WFb_scores_neg.mat'), WFbS_Nv);
end

end

end