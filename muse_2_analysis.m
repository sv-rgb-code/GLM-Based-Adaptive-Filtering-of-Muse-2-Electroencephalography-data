%% ------------------------------------------------------------------------
%  EEG Processing and Feature Extraction Script
%
%  This script:
%   - Loads raw Muse EEG CSV files
%   - Detects and removes bad EEG segments (ocular, movement, muscular)
%   - Computes band power (theta, alpha, beta, gamma) and alpha peak frequency
%   - Saves results to Excel and performs outlier detection
%% ------------------------------------------------------------------------

clear all; clc;

%% -------------------- Paths and File Definitions -------------------------

data_folder='';
% Define path to folder containing raw EEG CSV files

output_folder='';
% Define path where output Excel files are stored

% Excel output files (grouped by recording runs)
excel_files{1}=[output_folder filesep 'eeg_results_run_01_04_05_06.xlsx'];
excel_files{2}=[output_folder filesep 'eeg_results_run_02a.xlsx'];
excel_files{3}=[output_folder filesep 'eeg_results_run_02b.xlsx'];
excel_files{4}=[output_folder filesep 'eeg_results_run_03.xlsx'];
excel_files{5}=[output_folder filesep 'eeg_results_run_07.xlsx'];

% Sheet names corresponding to EEG metrics
sheet_names{1}='theta';
sheet_names{2}='alpha';
sheet_names{3}='beta';
sheet_names{4}='gamma';
sheet_names{5}='APF';

%% -------------------- Global Parameters ----------------------------------

k=1.5;  
Fs=256; 
addpath(genpath(pwd)); 
study_code='54';   
nsub=50;           

sess_label={'A','B','C'}; 

%% -------------------- Generate Subject Codes -----------------------------

for k=1:length(sess_label)
    for i=1:nsub
        str=['0' num2str(i)];
        str=str(end-1:end);
        codes{(i-1)*3+k}=[study_code str '_' sess_label{k}];
    end
end

%% -------------------- Session Definitions --------------------------------

sessions{1}='1';
sessions{2}='2a';
sessions{3}='2b';
sessions{4}='3';
sessions{5}='4';
sessions{6}='5';
sessions{7}='6';
sessions{8}='7';

block_duration = 60; 
% Length of analysis blocks in seconds

%% ==================== Main Processing Loop ===============================

for p=1:length(codes)
    for l=1:length(sessions)

        % Construct filename and display progress
        filename=[codes{p} '_' sessions{l}];
        disp(filename);

        dataset=filename(1:6);      
        session=filename(8:end);    
        folder=[data_folder filesep dataset];

        % Locate EEG CSV file
        dx=dir([data_folder filesep filename '*.csv']);

        if not(isempty(dx))

            %% -------------------- Load Raw Data --------------------------

            load_file=[dx.folder filesep dx.name];
            [museData, museElements]=mmImport(load_file);

            timestamp=museData.TimeStamp;

            % EEG channels
            clear eeg_data;
            eeg_data(:,1)=museData.RAW_TP9;
            eeg_data(:,2)=museData.RAW_TP10;
            eeg_data(:,3)=museData.RAW_AF7;
            eeg_data(:,4)=museData.RAW_AF8;

            % Motion sensors
            clear accelerometer_data;
            accelerometer_data(:,1)=museData.Accelerometer_X;
            accelerometer_data(:,2)=museData.Accelerometer_Y;
            accelerometer_data(:,3)=museData.Accelerometer_Z;

            clear gyroscope_data;
            gyroscope_data(:,1)=museData.Gyro_X;
            gyroscope_data(:,2)=museData.Gyro_Y;
            gyroscope_data(:,3)=museData.Gyro_Z;

            %% -------------------- Preprocessing --------------------------

            [ntp,nchan]=size(eeg_data);
            tn=1/Fs*[1:ntp]';

            eeg_data = detrend(eeg_data);
            eeg_data = filter50(eeg_data,Fs);
            eeg_data = filterband(eeg_data,Fs,1,50);

            accelerometer_data = detrend(accelerometer_data);
            accelerometer_data = filterband(accelerometer_data,Fs,1,50);

            gyroscope_data = detrend(gyroscope_data);
            gyroscope_data = filterband(gyroscope_data,Fs,1,50);

            %% -------------------- Artifact Regression --------------------

            corr_eeg=corr(eeg_data);
            corr_art=corr(eeg_data,[accelerometer_data gyroscope_data]);

            eeg_data_clean=zeros(size(eeg_data));
            for j=1:nchan
                B=glmfit([accelerometer_data gyroscope_data], ...
                         eeg_data(:,j),'normal','constant','off');
                eeg_data_clean(:,j)=eeg_data(:,j)- ...
                                     [accelerometer_data gyroscope_data]*B;
            end

            corr_art_check=corr(eeg_data_clean, ...
                                [accelerometer_data gyroscope_data]);

            %% -------------------- Artifact Detection ----------------------

            nwin=fix(ntp/Fs);

            kurt=zeros(nwin,nchan);
            power=zeros(nwin,nchan);
            gamma_alpha=zeros(nwin,nchan);

            for j=1:nchan
                for i=1:nwin
                    sig=eeg_data_clean((i-1)*Fs+1:i*Fs,j);
                    kurt(i,j)=kurtosis(sig,0);
                    power(i,j)=mean(sig.^2);
                    spectrum=abs(fft(sig)).^2;
                    fx=[1:length(spectrum)]/length(spectrum)*Fs;
                    gamma_alpha(i,j)= ...
                        mean(spectrum(fx>30 & fx<50)) / ...
                        mean(spectrum(fx>7 & fx<14));
                end
            end

            ocular=zeros(nwin,nchan);
            ocular(kurt>6)=1;

            movement=zeros(nwin,nchan);
            for j=1:nchan
                movement(power(:,j)>5*mean(power(:,j)),j)=1;
            end

            muscular=zeros(nwin,nchan);
            muscular(gamma_alpha>1.5)=1;

            clean_eeg_blocks=ones(nwin,nchan);
            clean_eeg_blocks(ocular==1)=0;
            clean_eeg_blocks(movement==1)=0;
            clean_eeg_blocks(muscular==1)=0;

            %% -------------------- Spectral Analysis -----------------------

            for chan=1:4

                [S,F,T,P]=spectrogram(eeg_data_clean(:,chan), ...
                                      hamming(256),0,256,Fs);

                P=P(F>0 & F<50,:);
                F=F(F>0 & F<50);

                Px=P;
                Px(:,clean_eeg_blocks(:,chan)==0)=NaN;

                nb=5*round(nwin/(5*block_duration));

                if chan==1
                    theta=zeros(4,nb);
                    alpha=zeros(4,nb);
                    beta=zeros(4,nb);
                    gamma=zeros(4,nb);
                    apf=zeros(4,nb);
                end

                for j=1:nb
                    start=(j-1)*block_duration+1;
                    stop=j*block_duration;
                    if stop>nwin
                        stop=nwin;
                    end

                    theta(chan,j)=nanmean(Px(F>=4  & F<8 ,start:stop),'all');
                    alpha(chan,j)=nanmean(Px(F>=8  & F<13,start:stop),'all');
                    beta(chan,j) =nanmean(Px(F>=13 & F<30,start:stop),'all');
                    gamma(chan,j)=nanmean(Px(F>=30 & F<50,start:stop),'all');
                end

                %% ---------------- Alpha Peak Frequency --------------------

                eeg_data_resampled=resample(eeg_data_clean(:,chan),1000,Fs);
                eeg_data_filtered=filteralpha(eeg_data_resampled,1000,7,14);

                landmark_points=find(eeg_data_filtered(1:end-1)<0 & ...
                                     eeg_data_filtered(2:end)>=0);

                for j=1:nb
                    start=1000*(j-1)*block_duration+1;
                    stop=1000*j*block_duration;
                    if stop>length(eeg_data_filtered)
                        stop=length(eeg_data_filtered);
                    end
                    vx=find(landmark_points>start & landmark_points>stop);
                    abc=mean(diff(landmark_points(vx)));
                    apf(chan,j)=1000/abc;
                end
            end

            %% -------------------- Channel Averaging -----------------------

            theta=mean(theta,1);
            alpha=mean(alpha,1);
            beta =mean(beta ,1);
            gamma=mean(gamma,1);
            apf  =mean(apf  ,1);

            %% -------------------- Save to Excel ---------------------------

            if l==1 || l==5 || l==6 || l==7
                output_file=excel_files{1};
            elseif l==2
                output_file=excel_files{2};
            elseif l==3
                output_file=excel_files{3};
            elseif l==4
                output_file=excel_files{4};
            elseif l==8
                output_file=excel_files{5};
            end

            for s=1:5
                A=readtable(output_file,'Sheet',sheet_names{s});
                X=A.dataset;
                val=strmatch(dataset,X);

               for j=1:nb
                eval(['x=A.run' session '_' num2str(j) ';']);
                if not(isempty(val))
                    x(val)=apf(j);
                    eval(['A.run' session '_' num2str(j) '=x;']);
                end
            end

                writetable(A,output_file,'Sheet',sheet_names{s});
            end
        end
    end
end

%% ==================== Outlier Detection ==================================

for k=1:5
    for i=1:5
        output_file=excel_files{i};
        X=readtable(output_file,'Sheet',sheet_names{k});
        dataset=X.dataset;
        vars=X.Properties.VariableNames;

        for q=2:length(vars)
            data=X.(vars{q});
            datastr=cellstr(num2str(data));

            for p=1:3
                a=strfind(dataset,['_' sess_label{p}]);
                s=find(~cellfun(@isempty,a'));
                datax=data(s,:);

                try
                    Q1=prctile(datax,25);
                    Q3=prctile(datax,75);
                    range=Q3-Q1;
                    vect=find(datax>Q3+k*range);

                    for x=1:length(vect)
                        datastr{s(vect(x))}=['*' datastr{s(vect(x))}];
                    end
                end
            end

            vect2=find(isnan(data));
            for x=1:length(vect2)
                datastr{vect2(x)}=NaN;
            end

            X.(vars{q})=datastr;
        end

        writetable(X,[output_file(1:end-5) '_outlier.xlsx'], ...
                   'Sheet',sheet_names{k});
    end
end
