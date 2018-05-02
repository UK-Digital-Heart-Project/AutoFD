function pft_FractalDimensionCalculationOnTopLevelFolder(TopLevelFolder, SubFolders, BatchNumber)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pft_FractalDimensionCalculationOnTopLevelFolder                                                                               %
%                                                                                                                               %
% A function to process all the sub-folders within a top-level folder.                                                          %
%                                                                                                                               %
% PFT - 01. 05. 2016.                                                                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Locate all the folders beneath the top-level folder
if isempty(SubFolders)
  return;
end

NDIRS = length(SubFolders);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Fetch the acquisition slice order (as implemented in the segmentation files)
% AcquisitionOrder = pft_GetAcquisitionOrder;
  AcquisitionOrder = 'Base to Apex';

% Select the type of interpolation
% InterpolationType = pft_GetInterpolationType;
  InterpolationType = 'Imresize - 0.25 mm pixels - cubic';

% Set the default perimeter type - there is no choice here, and if the default cannot be created, then the brute-force Ansatz is applied
  PerimeterType = 'Out from blood pool';

% Fetch the blood pool threshold parameters - 60-65 (64) pixels is optimum for Genscan, 38 for UKBB, according to TJWD's balanced/maximum probability study
% [ MinimumPixelCount, ConnectedPercentage ] = pft_GetBloodPoolThresholdParameters;
  MinimumPixelCount   = 38;
  ConnectedPercentage = 50.0;

% Ask whether to trim data for summary FD statistics
% Ans = questdlg('Discard end slices for summary statistics ?', 'Processing decision', 'Yes', 'No', 'No');
  Ans = 'No';

switch Ans
  case { '', 'No' }
    DiscardEndSlices = 'No';
  case 'Yes'
    DiscardEndSlices = 'Yes';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Select the output Excel sheet, and back it up straightaway if it already exists from a previous run
SummaryFile       = fullfile(TopLevelFolder, sprintf('Data-%1d.csv', BatchNumber));
SummaryBackupFile = fullfile(TopLevelFolder, sprintf('Backup-%1d.csv', BatchNumber));

if (exist(SummaryFile, 'file') == 2)
  copyfile(SummaryFile, SummaryBackupFile);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% These are signalling error conditions for the o/p CSV file
MeagreBloodPool  = -111;
SparseMyocardium = -222;
NoROICreated     = -333;
FDMeasureFailed  =  0.0;    % Signal that an attempt was made, but failed - this will be excluded from the FD statistics

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Process all the suitable folders
for n = 1:NDIRS
    
  switch InterpolationType    
    case 'Imresize - (x4 x4) - cubic'
      if (exist(fullfile(TopLevelFolder, 'Automated FD Calculation Results - x4', SubFolders{n}), 'dir') ~= 7)
        mkdir(fullfile(TopLevelFolder, 'Automated FD Calculation Results - x4'), SubFolders{n});
      end
    case 'Imresize - 0.25 mm pixels - cubic'
      if (exist(fullfile(TopLevelFolder, 'Automated FD Calculation Results - 0.25 mm pixels', SubFolders{n}), 'dir') ~= 7)
        mkdir(fullfile(TopLevelFolder, 'Automated FD Calculation Results - 0.25 mm pixels'), SubFolders{n});
      end
  end      
  
  SourceFolder = fullfile(TopLevelFolder, SubFolders{n});
  
  switch InterpolationType    
    case 'Imresize - (x4 x4) - cubic'
      TargetFolder = fullfile(TopLevelFolder, 'Automated FD Calculation Results - x4', SubFolders{n});
    case 'Imresize - 0.25 mm pixels - cubic'
      TargetFolder = fullfile(TopLevelFolder, 'Automated FD Calculation Results - 0.25 mm pixels', SubFolders{n});
  end
  
  [ ImageStack, SegmentationStack, BinaryMask, PerimeterStack, Conditions, OriginalResolution ] = ...
  pft_ExtractMatchedAndShiftedImages(SourceFolder, AcquisitionOrder, MinimumPixelCount, ConnectedPercentage);

  if isempty(ImageStack)
    rmdir(TargetFolder, 's');
    Data = sprintf('%s, %s %s', SubFolders{n}, repmat('  ,', [1, 35]), '  ');
    fid = fopen(SummaryFile, 'at');
    fprintf(fid, '%s\n', Data);
    fclose(fid);    
    continue;
  end

  [ NR, NC, NP ] = size(ImageStack);
  
  switch InterpolationType    
    case 'Imresize - (x4 x4) - cubic'
      OutputResolution = OriginalResolution/4.0;
    case 'Imresize - 0.25 mm pixels - cubic'
      OutputResolution = 0.25;
  end
  
  FD = NaN(1, 20);
  FractalDimensions = repmat({ 'NaN' }, [1, 20]);
  
  for p = 1:NP
      
    switch Conditions{p}
        
      case 'Meagre blood pool'
        Wzor = ImageStack(:, :, p);        
        Segmentation = SegmentationStack(:, :, p); 
        
        pft_WriteOriginallySizedImages(Wzor, Segmentation, p, TargetFolder);
          
        FD(p) = MeagreBloodPool;
        FractalDimensions{p} = 'Meagre blood pool';  
        pft_WriteAllBlankImages(p, TargetFolder, 'Meagre blood pool');
        
      case 'Sparse myocardium' 
        Wzor = ImageStack(:, :, p);        
        Segmentation = SegmentationStack(:, :, p); 
        
        pft_WriteOriginallySizedImages(Wzor, Segmentation, p, TargetFolder);
          
        FD(p) = SparseMyocardium;
        FractalDimensions{p} = 'Sparse myocardium';  
        pft_WriteAllBlankImages(p, TargetFolder, 'Sparse myocardium');
        
      case 'No ROI created' 
        Wzor = ImageStack(:, :, p);        
        Segmentation = SegmentationStack(:, :, p); 
        
        pft_WriteOriginallySizedImages(Wzor, Segmentation, p, TargetFolder);
          
        FD(p) = NoROICreated;
        FractalDimensions{p} = 'No ROI created';
        pft_WriteAllBlankImages(p, TargetFolder, 'No ROI created');        
        
      case 'OK'  
        Wzor = ImageStack(:, :, p);        
        Mask = BinaryMask(:, :, p);
        Segmentation = SegmentationStack(:, :, p);        
        Perimeter = PerimeterStack(:, :, p);
        
        pft_WriteOriginallySizedImages(Wzor, Segmentation, p, TargetFolder);
        pft_WriteOriginallySizedMask(Mask, p, TargetFolder);
    
        s = regionprops(Mask, 'BoundingBox');
        
        Wzor = imcrop(Wzor, s(1).BoundingBox);
        Mask = imcrop(Mask, s(1).BoundingBox);
        Segmentation = imcrop(Segmentation, s(1).BoundingBox);
        Perimeter = imcrop(Perimeter, s(1).BoundingBox);
        
        [ Wzor, Mask, Segmentation, Perimeter ] = ...
        pft_InterpolateImages(Wzor, Mask, Segmentation, Perimeter, OriginalResolution, InterpolationType);  
    
        pft_WriteInputImages(Wzor, Mask, Segmentation, Perimeter, p, TargetFolder);
    
        try
          FD(p) = pft_JC_FractalDimensionCalculation(Wzor, Mask, p, TargetFolder);
          FractalDimensions{p} = sprintf('%.9f', FD(p));
        catch
          FD(p) = FDMeasureFailed;
          Conditions{p} = 'FD measure failed';
          FractalDimensions{p} = 'FD measure failed';
          pft_WriteBlankOutputImages(p, TargetFolder, 'FD measure failed');
        end       
 
    end       
     
  end
  
  % Extract and process the FD values for the current stack, trimmed to the number of slices present
  StackFD = FD(1:NP);
    
  switch DiscardEndSlices
    case 'No'
      S = pft_JC_FDStatistics(StackFD, false);
    case 'Yes'
      S = pft_JC_FDStatistics(StackFD, true);
  end  
  
  % Write out the formatted o/p as text 
  FormattedFDOutput = '';
  
  for c = 1:19
    switch Conditions{c}
      case { 'Meagre blood pool', 'Sparse myocardium', 'No ROI created', 'FD measure failed' }
        FormattedFDOutput = [ FormattedFDOutput sprintf('%s,', FractalDimensions{c}) ];
      case 'OK'
        if isnan(FD(c))
          FormattedFDOutput = [ FormattedFDOutput 'NaN,' ];
        else
          FormattedFDOutput = [ FormattedFDOutput sprintf('%s,', FractalDimensions{c}) ];
        end
    end
  end  
  
  switch Conditions{20}
    case { 'Meagre blood pool', 'Sparse myocardium', 'No ROI created', 'FD measure failed' }
      FormattedFDOutput = [ FormattedFDOutput sprintf('%s', FractalDimensions{20}) ];
    case 'OK'
      if isnan(FD(20))
        FormattedFDOutput = [ FormattedFDOutput 'NaN' ];
      else
        FormattedFDOutput = [ FormattedFDOutput sprintf('%s', FractalDimensions{20}) ];
      end
  end
        
  Data = sprintf('%s,%s,%s,%s,%1d,%.2f,%.9f,%.9f,%1d,%s,%s,%1d,%1d,%.9f,%.9f,%.9f,%.9f,%.9f', ...
                 SubFolders{n}, ...
                 AcquisitionOrder, InterpolationType, PerimeterType, ...                 
                 MinimumPixelCount, ConnectedPercentage, ...             
                 OriginalResolution, OutputResolution, ...
                 NP, ...
                 FormattedFDOutput, ...
                 DiscardEndSlices, S.SlicesEvaluated, S.SlicesUsed, ...
                 S.MeanGlobalFD, ...
                 S.MeanBasalFD, S.MeanApicalFD, ...
                 S.MaxBasalFD, S.MaxApicalFD);
             
  fid = fopen(SummaryFile, 'at');
  fprintf(fid, '%s\n', Data);
  fclose(fid);
            
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Signal completion of a single thread
fprintf('Thread number %1d completed.\n', BatchNumber);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end




