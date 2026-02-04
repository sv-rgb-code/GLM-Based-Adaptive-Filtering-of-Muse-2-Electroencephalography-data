# GLM-Based-Adaptive-Filtering-of-Muse-2-Electroencephalography-data
---

## Purpose of the Processing Script

The MATLAB script implements a preprocessing and feature extraction pipeline for Muse 2 EEG data.

The script:
- Cleans raw EEG signals
- Removes motion-related artifacts using accelerometer and gyroscope data
- Identifies and excludes artifactual segments
- Computes spectral features
- Exports summarized results to structured Excel files with automated outlier detection

---

## Software Requirements

### MATLAB Toolboxes

The following MATLAB toolboxes are required:

- Signal Processing Toolbox  
- Statistics and Machine Learning Toolbox  

### Custom MATLAB Functions

The following custom functions must be available on the MATLAB path:

- `mmImport.m`  
- `filter50.m`  
- `filterband.m`  
- `filteralpha.m`  
- `dfa.m`  

These functions are typically stored in a `tools/` directory.  
All subfolders should be added to the MATLAB path before execution.

---

## Expected Inputs

- **Raw EEG data files** in CSV format  
- **One file per recording session**
- **Sampling frequency:** 256 Hz  

### EEG Channels
- TP9  
- TP10  
- AF7  
- AF8  

### Motion Signals
- Accelerometer: X, Y, Z  
- Gyroscope: X, Y, Z  

The script automatically searches for input files using the filename structure described below.

---

## Data Input

### EEG and Motion Data (CSV Files)

Typical columns include:

- **TP9, TP10, AF7, AF8** – EEG channel signals  
- **ACC_X, ACC_Y, ACC_Z** – Accelerometer signals  
- **GYRO_X, GYRO_Y, GYRO_Z** – Gyroscope signals  
- **Timestamp** – Time reference for each sample  

### Units of Measurement

- **EEG signals:** microvolts (µV)  
- **Accelerometer:** device-specific acceleration units  
- **Gyroscope:** device-specific rotational units  

### Data Formats

- **Time values:** numeric sample index or timestamp  
- **Sampling frequency:** 256 Hz  

### Structure

`Dataset_session_block.csv`

### Attributes

- **dataset** – Numeric or alphanumeric subject or dataset identifier  
- **session** – Recording session identifier (e.g., A, B, C)  
- **block** – Recording block or run number  

### Codes / Abbreviations

- **A, B, C** – Session identifiers  
- **CSV** – Comma-Separated Values  

### Examples

- `6301_A_1.csv`  
- `6301_B_2.csv`  

---

## Expected Outputs

- **Excel (.xlsx) files** containing processed EEG features  

Each output file includes separate sheets for:
- Theta
- Alpha
- Beta
- Gamma
- Alpha Peak Frequency (APF)

Additional output characteristics:
- Band power values expressed in **µV²**
- Alpha peak frequency expressed in **Hz**
- Statistical outliers flagged using **Tukey’s method**
- Outlier-marked files saved with an `_outlier.xlsx` suffix

---

## File Formats

The dataset includes the following file formats:

- **CSV** – Raw EEG and motion sensor data  
- **XLSX** – Processed results and derived features  

If files are converted to other formats, validation should be performed to minimize data loss or corruption.

---

## Minimal Usage Example

1. Install all required MATLAB toolboxes  
2. Place custom functions in the `tools/` directory  
3. Ensure all subfolders are added to the MATLAB path  
4. Verify that input CSV files follow the defined filename structure  
5. Set the MATLAB working directory to the project root  
6. Run the main MATLAB script  

---

## Name / Institution / Contact Information

### Principal Investigators

- **Names:** Prof. Dr. Dante Mantini<sup>1</sup>, Nathan Vermaerke<sup>1,2,3</sup> and Siemon Vermeiren<sup>1,2</sup>
- **Affiliations:** 
<sup>1</sup> Department of Movement Sciences, KU Leuven

<sup>2</sup> Faculty of Rehabilitation Sciences, Hasselt University

<sup>3</sup> Department of Physical and Rehabilitation Medicine and Sports Traumatology, University of Liège
- **Contact information:** 

dante.mantini@kuleuven.be

nathan.vermaerke@uhasselt.be

siemon.vermeiren@uhasselt.be

---

## Version

- **Date of change:** 03/02/2026  
