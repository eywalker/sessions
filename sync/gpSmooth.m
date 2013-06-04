
function [f,v_f,lp] = gpSmooth(x,y,x_test)
% runs a gp smoothing on input data
% 
% JC 2010-06-05

if nargin < 3
    x_test = x;
end

sigma_obs = 1; %std(diff(y));
sigma_kernel = 10;
y_bias = mean(y);


K = cov_kernel(x,x,1/sigma_kernel^2);
K_test = cov_kernel(x_test, x, 1/sigma_kernel^2);

L = chol(K + sigma_obs^2 * eye(size(K,1)),'lower');
alpha = L' \ (L \ (y-y_bias));
f = K_test * alpha;

f = f+y_bias;
v=L\K_test';
v_f=cov_kernel(x_test,x_test,1/sigma_kernel^2)-v'*v;

%f = K*(K+eye(size(K))/sigma_obs^2)^-1*y;

% return;
% 
% for i = 1:size(K,2)
%     v = L \ K(:,i);
%     Var(i) = K(i,i) - v' * v;
% end

%calculate log marginal likelihood of y
lp = -1/2 * (y-y_bias)' * alpha - sum(log(diag(K))) - size(K,1)/2 * log(2 * pi);

%cla
%patch([x; flipud(x)],[(f+2*sqrt(Var)'); flipud(f - 2*sqrt(Var)')],[.9 .9 .9],'EdgeColor','none')
%hold on
%plot(x,y,x,f)

function K = cov_kernel(x1,x2,prec)

K = zeros(size(x1,1),size(x2,1));
for i = 1:size(x1,1)
    d = bsxfun(@minus,x1(i,:),x2);
    K(i,:) =  sum(exp(- 1/2 * (d * prec) .* d),2)';
end

