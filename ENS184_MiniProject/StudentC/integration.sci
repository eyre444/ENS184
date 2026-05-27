// ============================================================
// integration.sci  —  Student C Skeleton
// Goodness-of-Fit Metrics and Failure-Hour Prediction
//
// NAME: _Carlo Jane A. Branggan_______________________________
// ID:   __2024-0413______________________________
//
// You must implement TWO functions in this file.
// Do NOT change the function signatures.
//
// FORBIDDEN: Do NOT use Scilab's built-in fsolve(), roots(), or any
// root-finding builtin for find_threshold_hour.  Implement bisection
// from scratch as described in the manual.
// ============================================================

funcprot(0);   // suppress redefinition warnings when re-running

// ------------------------------------------------------------
// Function 1: goodness_of_fit
//
// Computes two model-accuracy metrics: RMSE and R².
//
// Input:
//   y_actual - vector of observed (measured) values    (n)
//   y_pred   - vector of model-predicted values        (n)
//
// Output:
//   rmse - Root-Mean-Square Error  (scalar, lower = better)
//   r2   - Coefficient of Determination  (scalar, closer to 1 = better)
//
// Hints:
//   - RMSE measures the typical size of prediction errors.  Start by
//     computing each residual (actual minus predicted), then build the
//     "root mean square" from those residuals.
//   - R² compares your model's total squared error against the baseline
//     error of simply predicting the mean of y_actual.  Write out both
//     sums explicitly before coding them.
//   - Consider what R² should equal when all observed values are identical
//     (SS_tot = 0) and handle that case explicitly.
// ------------------------------------------------------------
function [rmse, r2] = goodness_of_fit(y_actual, y_pred)

   // TODO: validate that y_actual and y_pred have the same length
    if length(y_actual) <> length(y_pred) then
        error("Input vectors y_actual and y_pred must have the same length.");
    end

    // TODO: ensure column vectors
    y_actual = y_actual(:);
    y_pred = y_pred(:);
    
    n = length(y_actual);

    // TODO: compute residuals
    residuals = y_actual - y_pred;

    // TODO: compute RMSE
    // RMSE = sqrt( (1/n) * sum( (y_actual - y_pred)^2 ) )
    rmse = sqrt(mean(residuals.^2));

    // TODO: compute SS_res and SS_tot
    // SS_res is the sum of squared residuals
    SS_res = sum(residuals.^2);
    
    // SS_tot is the total sum of squares (variance around the mean)
    mean_actual = mean(y_actual);
    SS_tot = sum((y_actual - mean_actual).^2);

    // TODO: compute r2 = 1 - SS_res / SS_tot  (handle SS_tot == 0)
    if SS_tot == 0 then
        // If all actual values are identical, SS_tot is 0. 
        // If the model predicts perfectly (SS_res == 0), R2 is 1. Otherwise, it's 0.
        if SS_res == 0 then
            r2 = 1.0;
        else
            r2 = 0.0;
        end
    else
        r2 = 1.0 - (SS_res / SS_tot);
    end

endfunction
// ------------------------------------------------------------
// Function 2: find_threshold_hour
//
// Uses bisection to find the hour h* at which the fitted
// vibration curve first crosses the failure threshold.
//
// Input:
//   hours     - sorted hour vector (from load_data)           (n)
//   vib_fit   - fitted vibration vector (from predict_vibration) (n)
//   threshold - failure vibration level (scalar, e.g. 9.5)
//
// Output:
//   h_star - predicted failure hour (scalar)
//            Returns Inf if vibration never reaches threshold.
//
// Hints:
//   - First handle the edge case: what should the function return if
//     vibration never reaches the threshold?
//   - Scan vib_fit to find a consecutive pair of points that "straddle"
//     the threshold (one below, the next at or above).  This gives your
//     starting bracket [h_lo, h_hi].
//   - Apply bisection: halve the bracket repeatedly, keeping whichever
//     half still contains the crossing.  Stop when the bracket width
//     is less than 0.5 h.
//   - Inside the bracket you have only the two endpoint values of
//     vib_fit.  How can you estimate vib_fit at any interior hour
//     without calling predict_vibration again?
//   - A for-loop with up to 100 iterations is plenty for convergence.
// ------------------------------------------------------------
function [h_star] = find_threshold_hour(hours, vib_fit, threshold)

    // TODO: force column vectors;  n = length(hours);
    hours = hours(:);
    vib_fit = vib_fit(:);
    n = length(hours);

    // ---- Step 1: find the bracket ----
    // Scan consecutive pairs (vib_fit(i), vib_fit(i+1)).
    // A bracket exists when one value is below threshold and the next is
    // at or above it, i.e. (vib_fit(i)-threshold)*(vib_fit(i+1)-threshold) <= 0.
    // TODO: initialise i_lo = 0, then loop i = 1:n-1:
    //       if (vib_fit(i)-threshold)*(vib_fit(i+1)-threshold) <= 0
    //           i_lo = i; break;
    //       end
    i_lo = 0;
    for i = 1:(n - 1)
        if (vib_fit(i) - threshold) * (vib_fit(i + 1) - threshold) <= 0 then
            i_lo = i;
            break;
        end
    end

    // ---- Step 2: handle no-crossing case ----
    // TODO: if i_lo == 0, no crossing was found.
    //       if vib_fit(n) < threshold: h_star = %inf; return;
    //       else: h_star = hours(1); return; // already exceeded at start
    if i_lo == 0 then
        if vib_fit(n) < threshold then
            h_star = %inf;
            return;
        else
            h_star = hours(1);
            return; // already exceeded at start
        end
    end

    // ---- Step 3: set up bracket endpoints ----
    // Define g(h) = (vib_fit value at h) - threshold.
    // TODO: extract the hour values and g-values at index i_lo and i_lo+1.
    h_lo = hours(i_lo);
    h_hi = hours(i_lo + 1);
    
    g_lo = vib_fit(i_lo) - threshold;
    g_hi = vib_fit(i_lo + 1) - threshold;

    // ---- Step 4: bisection loop ----
    // TODO: repeat up to 100 times:
    //   Compute the midpoint hour h_mid = (h_lo + h_hi) / 2.
    //   You have only g at the two bracket endpoints — estimate g at h_mid
    //   by linear interpolation between those two known g-values.
    //   Based on the sign of g at h_mid, shrink the bracket to the half
    //   that still contains the sign change.
    //   Stop when the bracket width is less than 0.5 h.
    for iter = 1:100
        // Stop if the physical window width drops below 0.5 hours
        if (h_hi - h_lo) < 0.5 then
            break;
        end
        
        h_mid = (h_lo + h_hi) / 2;
        
        // Linear interpolation weight (fractional distance of h_mid between h_lo and h_hi)
        // Since h_mid is the exact midpoint, weight is 0.5, but we write it out 
        // to clearly match the explicit linear interpolation requirement:
        weight = (h_mid - h_lo) / (h_hi - h_lo);
        g_mid = g_lo + weight * (g_hi - g_lo);
        
        // Shrink the interval to the half that preserves the zero-crossing (opposite signs)
        if (g_lo * g_mid) <= 0 then
            // Root is in the lower half
            h_hi = h_mid;
            g_hi = g_mid;
        else
            // Root is in the upper half
            h_lo = h_mid;
            g_lo = g_mid;
        end
    end

    // TODO: return h_star as the midpoint of the final bracket.
    h_star = (h_lo + h_hi) / 2;

endfunction
