clc;
clear;
close all;

% Read Huffman DC, AC table and encoded values %
fileID1 = fopen('../python/output/DC_HuffTable_Index0.txt', 'r');
fileID2 = fopen('../python/output/DC_HuffTable_Index1.txt', 'r');
fileID3 = fopen('../python/output/AC_HuffTable_Index0.txt', 'r');
fileID4 = fopen('../python/output/AC_HuffTable_Index1.txt', 'r');
fileID5 = fopen('../python/output/bitStream.txt', 'r');
formatSpec = '%s %d';
DC0 = textscan(fileID1, formatSpec);
DC1 = textscan(fileID2, formatSpec);
AC0 = textscan(fileID3, formatSpec);
AC1 = textscan(fileID4, formatSpec);

huff_dc0_codes  = DC0{1};
huff_dc0_values = DC0{2};
huff_dc1_codes  = DC1{1};
huff_dc1_values = DC1{2};

huff_ac0_codes  = AC0{1};
huff_ac0_values = AC0{2};
huff_ac1_codes  = AC1{1};
huff_ac1_values = AC1{2};

huffman_dc0_map = containers.Map(huff_dc0_codes, huff_dc0_values);
huffman_dc1_map = containers.Map(huff_dc1_codes, huff_dc1_values);
huffman_ac0_map = containers.Map(huff_ac0_codes, huff_ac0_values);
huffman_ac1_map = containers.Map(huff_ac1_codes, huff_ac1_values);

values_in = fscanf(fileID5, '%s');

decoded_values = [];
dc_flag = 1;
cnt = 0;
cnt_block = 0;

while (~isempty(values_in))
    % Determine table (4Y 1Cb 1Cr)
    if mod(cnt_block, 6) >= 0 && mod(cnt_block, 6) <= 1     % Y
        huffman_dc_map = huffman_dc0_map;
        huffman_ac_map = huffman_ac0_map;
    else
        huffman_dc_map = huffman_dc1_map;
        huffman_ac_map = huffman_ac1_map;
    end

    if dc_flag == 1 % DC
        [values_out, b_size] = decode_huffman_dc(values_in, huffman_dc_map);
        if b_size == 0
            decoded_values = [decoded_values, 0];
            values_in = values_out(b_size+1:end);
            dc_flag = 0;
            cnt = cnt + 1;
        else
            decoded_values = [decoded_values, vli(values_out(1:b_size))];
            values_in = values_out(b_size+1:end);
            dc_flag = 0;
            cnt = cnt + 1;
        end
    else % AC
        [values_out, run_length, b_size] = decode_huffman_ac(values_in, huffman_ac_map);
        if run_length == 0 && b_size == 0  % EOB
            zeros_to_append = zeros(1, 64-cnt);
            decoded_values = [decoded_values, zeros_to_append];
            values_in = values_out(b_size+1:end);
            dc_flag = 1;
            cnt = 0;
            cnt_block = cnt_block + 1;
            display(cnt_block)
        elseif run_length == 15 && b_size == 0  % append 16 zeros (15,0)
            zeros_to_append = zeros(1, 16);
            decoded_values = [decoded_values, zeros_to_append];   % adding zeros
            values_in = values_out(b_size+1:end);
            cnt = cnt + size(zeros_to_append,2);
        else
            zeros_to_append = zeros(1, run_length);
            decoded_values = [decoded_values, zeros_to_append];   % adding zeros
            decoded_values = [decoded_values, vli(values_out(1:b_size))]; 
            values_in = values_out(b_size+1:end);
            cnt = cnt + size(zeros_to_append,2) + 1;
        end

        if cnt == 64 % case when there is no EOB
            dc_flag = 1;
            cnt = 0;
            cnt_block = cnt_block + 1;
            display(cnt_block)
        end
    end
end

% Inverse Zigzag scan
% result = inv_zigzag(decoded_values, 8);

fileID1 = fclose(fileID1);
fileID2 = fclose(fileID2);
fileID3 = fclose(fileID3);
fileID4 = fclose(fileID4);
fileID5 = fclose(fileID5);

function [values_out, b_size] = decode_huffman_dc(values_in, huffman_dc_map)
    current_str = "";
    
    for i=1:length(values_in)
        current_str = strcat(current_str, values_in(i));
        if isKey(huffman_dc_map, current_str)
            b_size = huffman_dc_map(current_str);
            break;
        end
    end
    values_out = values_in(i+1:end);
end

function [values_out, run_length, b_size] = decode_huffman_ac(values_in, huffman_ac_map)
    current_str = "";
    
    for i=1:length(values_in)
        current_str = strcat(current_str, values_in(i));
        if isKey(huffman_ac_map, current_str)
            bit8 = dec2bin(huffman_ac_map(current_str), 8);
            run_length = bin2dec(bit8(1:4));
            b_size = bin2dec(bit8(5:8));
            break;
        end
    end
    values_out = values_in(i+1:end);
end

% Variable Length Integer (VLI)
function int4 = vli(binStr) 
    if binStr(1) == '1'  % Positive value
        int4 = bin2dec(binStr);
    else  % Negative value
        for i=1:length(binStr)
            if binStr(i) == '0'
                binStr(i) = '1';
            else
                binStr(i) = '0';
            end
        end
        int4 = -1*bin2dec(binStr);
    end 
end

function [A] = inv_zigzag(B,dim)
v = ones(1,dim); k = 1;
A = zeros(dim,dim);
for i = 1:2*dim-1
    C1 = diag(v,dim-i);
    C2 = flip(C1(1:dim,1:dim),2);
    C3 = B(k:k+sum(C2(:))-1);
    k = k + sum(C2(:));
    if mod(i,2) == 0
       C3 = flip(C3);
    end
        C4 = zeros(1,dim-size(C3,2));
    if i >= dim
       C5 = cat(2,C4, C3); 
    else       
        C5 = cat(2,C3,C4);
    end
    C6 = C2*diag(C5);
    A = C6 + A;
end
end