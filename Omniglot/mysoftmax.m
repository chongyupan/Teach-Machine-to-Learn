function y = softmax( x )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
 x_exp=exp(x);
 sum_x_exp=sum(x_exp);
 y=x_exp/sum_x_exp;

end

