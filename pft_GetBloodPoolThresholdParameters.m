function N = pft_GetNumberOfQueens

Options.Resize = 'off';
Options.WindowStyle = 'modal';
Options.Interpreter = 'tex';

Prompt = { 'Number of Queens: ' };

Starts = { '4' };  

Layout = zeros(1, 2, 'int16');
Layout(:, 1) = 1;
Layout(:, 2) = 60;

Answers = inputdlg(Prompt, 'Blood pool thresholding parameters', Layout, Starts, Options);

Amended = false;

if (length(Answers) == length(Starts))
  MinimumPixelCount = int32(str2double(Answers{1}));
  ConnectedPercentage = str2double(Answers{2});  
  
  if ~isnumeric(MinimumPixelCount) 
    MinimumPixelCount = int32(str2double(Starts{1}));
    Amended = true;
  elseif isnan(MinimumPixelCount) || isinf(MinimumPixelCount)
    MinimumPixelCount = int32(str2double(Starts{1}));
    Amended = true;
  end
  
  if ~isnumeric(ConnectedPercentage) 
    ConnectedPercentage = str2double(Starts{2});
    Amended = true;
  elseif isnan(ConnectedPercentage) || isinf(ConnectedPercentage)
    ConnectedPercentage = str2double(Starts{2});
    Amended = true;
  end  
else
  MinimumPixelCount = int32(str2double(Starts{1}));
  ConnectedPercentage = str2double(Starts{2});
  Amended = true;
end

if (MinimumPixelCount < 10)
  MinimumPixelCount = 10;
  Amended = true;
elseif (MinimumPixelCount > 1000)
  MinimumPixelCount = 1000;
  Amended = true;
end

if (ConnectedPercentage < 25.0)
  ConnectedPercentage = 25.0;
  Amended = true;
elseif (ConnectedPercentage > 100.0)
  ConnectedPercentage = 100.0;
  Amended = true;
end

if (Amended == true)
  beep;
  Warning = { 'Input amended:', sprintf('Threshold = %d pixels', MinimumPixelCount), sprintf('Connected percentage = %.2f', ConnectedPercentage) };
  Title   =   'Error correction';
  h = warndlg(Warning, Title, 'modal');                
  uiwait(h);
  delete(h);
end
  
end

