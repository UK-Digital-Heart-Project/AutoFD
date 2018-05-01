# AutoFD
Matlab script for automated fractal analysis of segmented cardiac images.

## Prerequisites
- Matlab.
- Windows or Linux.
- GhostScript.
- Possibly XPDF.

## Input data

Compressed NIfTI files (NII.GZ) of end-diastolic left ventricular short axis stacks.

## Method

The approach is based on our [FracAnalyse](https://github.com/UK-Digital-Heart-Project/fracAnalyse) software, 
but uses pre-exisiting image segmentations to determine a region of interest within the myocardium for fractal analysis.  

![FD images](https://github.com/UK-Digital-Heart-Project/AutoFD/blob/master/FDworkflow.png)

## Installation
Clone this repo to a folder in your MATLAB workspace then add all directories to the path:

```addpath(genpath('folder')); savepath;```

## Usage
Put the input data into a top-level folder with sub-folders for each subject containing:
  * Grayscale main image  ```sa_ED.nii.gz```
  * Segmentation ```seg_sa_ED.nii.gz``` or ```seg_sa_ED.gipl```.

The labels are Background  = 0, Blood Pool  = 1, Myocardium  = 2, Other = 3 or 4.

Run the script ```pft_UKBBParallelDriverScript```

Only one input is required: a top-level folder, with subject folders within it, each containing the grayscale and segmentation source images. The following parameters have been hard-coded: 

  * Minimum blood pool pixel count (default = 38, optimised according to a balanced probability calculation comparing manual and automated workflows) and percentage of blood pool connected to myocardium (default = 50%). Refer to the [Processing Flowchart](https://github.com/UK-Digital-Heart-Project/AutoFD/blob/master/Processing%20Flowchart.pdf) for details.
  * Keep or discard the end slices in the calculation of the summary statistics (this is now set to keep).
  
## Outputs
Outputs are written to a new sub-folder ```Automated FD Calculation Results - 0.25 mm pixels```.  Each subject's folder will contain intermediate images (see figure) and box-counting results.

Fractal dimension values are output to several files called ```Summary-Auto-FD-v0-N.csv```, where N is an integer >= 1. These files contain all the FD results between them, and need to been combined manually once the FD processing is complete. If you run the script more than once, new results will be appended to the CSV files, but the audit images will be overwritten; for that reason, it is best to move these files (as well as the o/p summary folder) if you intend to execute the script more than once.
