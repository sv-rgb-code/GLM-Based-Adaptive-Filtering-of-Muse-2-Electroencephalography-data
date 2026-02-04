function data_out = filteralpha(data_in,Fs,lowfq,highfq)
% Filtra i dati tra lowfq e highfq con ordine ordfilt e passo di campionamento smpfq

if nargin<3
    lowfq = 7;
end

if nargin<4
    highfq = 14;
end


if size(data_in,2)>size(data_in,1)
    data_out=data_in';
else
    data_out=data_in;
end


[b,a]=cheby2(6,40,lowfq*2/Fs,'high');

data_out=filtfilt(b,a,data_out);

[b,a]=cheby2(10,40,highfq*2/Fs,'low');

data_out=filtfilt(b,a,data_out);


if size(data_in,2)>size(data_in,1)
    data_out=data_out';
end


