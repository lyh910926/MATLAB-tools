%% Copyright (C) 2006 Arno Onken
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program; if not, write to the Free Software
%% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

%% -*- texinfo -*-
%% @deftypefn {Function File} {[@var{m}, @var{v}] =} tstat (@var{n})
%% Returns mean and variance of the t (Student) distribution
%%
%% @subheading Arguments
%%
%% @itemize @bullet
%% @item
%% @var{n} is the parameter of the t (Student) distribution. The elements
%% of @var{n} must be positive
%% @end itemize
%%
%% @subheading Return values
%%
%% @itemize @bullet
%% @item
%% @var{m} is the mean of the t (Student) distribution
%%
%% @item
%% @var{v} is the variance of the t (Student) distribution
%% @end itemize
%%
%% @subheading Example
%%
%% @example
%% @group
%% n = 3:8;
%% [m, v] = tstat (n)
%% @end group
%% @end example
%%
%% @subheading References
%%
%% @enumerate
%% @item
%% Wendy L. Martinez and Angel R. Martinez. @cite{Computational Statistics
%% Handbook with MATLAB}. Appendix E, pages 547-557, Chapman & Hall/CRC,
%% 2001.
%%
%% @item
%% Athanasios Papoulis. @cite{Probability, Random Variables, and Stochastic
%% Processes}. McGraw-Hill, New York, second edition, 1984.
%% @end enumerate
%% @end deftypefn

%% Author: Arno Onken <whyly@whyly.org>
%% Description: Moments of the t (Student) distribution

function [m, v] = tstat (n)

  % Check arguments
  if (nargin ~= 1)
    error("[m, v] = tstat (n)");
  end

  if (~isempty (n) && ~ismatrix (n))
    error("tstat: n must be a numeric matrix");
  end

  % Calculate moments
  m = zeros (size (n));
  v = n ./ (n - 2);

  % Continue argument check
  k = find (~(n > 1) | ~(n < Inf));
  if (any (k))
    m (k) = NaN;
    v (k) = NaN;
  end
  k = find (~(n > 2) & (n < Inf));
  if (any (k))
    v (k) = Inf;
  end

end