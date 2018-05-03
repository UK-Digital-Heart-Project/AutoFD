function Suffix = pft_NumberedSuffix(Digits, N)

S = sprintf('%1d', N);
N = length(S);
P = Digits - N;
Z = repmat('0', [1, P]);

Suffix = strcat(Z, S);

end
